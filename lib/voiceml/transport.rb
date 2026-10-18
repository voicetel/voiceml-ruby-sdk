# frozen_string_literal: true

require 'date'
require 'json'
require 'net/http'
require 'openssl'
require 'time'
require 'uri'

require_relative 'errors'
require_relative 'version'

module VoiceML
  # HTTP transport with exclusive connection use, per-host keep-alive, and
  # method-aware retries. Caller-supplied connections remain caller-owned.
  # @api private
  class Transport
    DEFAULT_BASE_URL = 'https://voiceml.voicetel.com'
    DEFAULT_TIMEOUT = 30
    DEFAULT_MAX_RETRIES = 2
    RETRYABLE_STATUSES = [429, 500, 502, 503, 504].freeze
    IDEMPOTENT_METHODS = %w[GET HEAD DELETE PUT].freeze
    RETRY_AFTER_CAP = 60.0
    MAX_REDIRECTS = 5

    # Carries the phase separately from the exception type: an SSL error or
    # ETIMEDOUT during a response is not proof that a POST was never sent.
    class NetworkFailure < StandardError
      attr_reader :original, :connecting

      def initialize(original, connecting)
        super(original.message)
        @original = original
        @connecting = connecting
      end
    end
    private_constant :NetworkFailure

    def self.strip_trailing_slashes(value)
      i = value.length
      i -= 1 while i.positive? && value.getbyte(i - 1) == 47
      value[0, i]
    end

    attr_reader :account_sid, :base_url, :max_retries, :timeout, :user_agent

    # `http_client:` is a Net::HTTP for one origin, or a factory
    # `->(host, port) { Net::HTTP.new(host, port) }` for multiple origins.
    # A one-argument factory receiving a URI is also accepted.
    def initialize(account_sid: nil, api_key: nil, base_url: DEFAULT_BASE_URL,
                   timeout: DEFAULT_TIMEOUT, max_retries: DEFAULT_MAX_RETRIES,
                   user_agent: nil, http_client: nil)
      if !account_sid.nil? && (!account_sid.is_a?(String) || account_sid.empty?)
        raise ConfigurationError, 'account_sid must not be empty'
      end
      if !api_key.nil? && (!api_key.is_a?(String) || api_key.empty?)
        raise ConfigurationError, 'api_key must not be empty'
      end
      unless max_retries.is_a?(Integer) && max_retries >= 0
        raise ConfigurationError, 'max_retries must be an integer >= 0'
      end
      unless timeout.is_a?(Numeric) && timeout.positive? && timeout.finite?
        raise ConfigurationError, 'timeout must be positive and finite'
      end
      unless http_client.nil? || http_client.is_a?(Net::HTTP) || http_client.respond_to?(:call)
        raise ConfigurationError, 'http_client must be a Net::HTTP or a callable'
      end

      @account_sid = account_sid
      @credential = -> { api_key }
      begin
        uri = URI.parse(base_url)
        unless uri.is_a?(URI::HTTP) && uri.host && !uri.userinfo && !uri.query && !uri.fragment
          raise ArgumentError, 'expected an HTTP(S) base URL without credentials, query, or fragment'
        end
        @base_url = self.class.strip_trailing_slashes(base_url)
      rescue URI::Error, ArgumentError, TypeError => e
        raise ConfigurationError, "invalid base_url: #{e.message}"
      end
      @timeout = timeout
      @max_retries = max_retries
      @user_agent = user_agent || "voiceml-ruby/#{VoiceML::VERSION}"
      @http_client = http_client
      @connections = {}
      @mutex = Mutex.new
    end

    # Release SDK-owned sockets. In-flight requests finish before close runs;
    # caller-owned clients are retained and never finished by this method.
    def close
      @mutex.synchronize do
        @connections.delete_if do |_origin, (http, owned)|
          finish(http) if owned
          owned
        end
      end
    end

    def request(method, path, params: nil, form: nil, json: nil, base_url: nil, auth: true)
      uri = build_uri(path, base_url, params)
      parse_response(send_with_retries(method, uri, form: form, json: json, auth: auth))
    end

    # Raw text and JSON use the same client, timeout, auth and retry policy.
    def request_raw(method, path, params: nil, base_url: nil, auth: true)
      uri = build_uri(path, base_url, params)
      response = send_with_retries(method, uri, auth: auth, accept: '*/*')
      raise_for_response(response) unless response.is_a?(Net::HTTPSuccess)

      [response.code.to_i, response.body.to_s, response.each_header.to_h]
    end

    # Authenticated binary GET with manual, origin-aware redirect handling.
    def fetch_bytes(path, base_url: nil)
      origin = build_uri(path, base_url, nil)
      uri = origin
      redirects = 0
      loop do
        response = send_with_retries(:get, uri, auth: same_origin?(origin, uri), accept: '*/*')
        unless response.is_a?(Net::HTTPRedirection)
          raise_for_response(response) unless response.is_a?(Net::HTTPSuccess)

          return [response.code.to_i, response.body.to_s, response.each_header.to_h]
        end
        raise ConnectionError.new('too many redirects', status_code: 0) if redirects >= MAX_REDIRECTS

        target = resolve_redirect(uri, response['location'])
        if uri.scheme == 'https' && target.scheme == 'http'
          raise ConnectionError.new('refusing an https -> http redirect', status_code: 0)
        end
        uri = target
        redirects += 1
      end
    end

    def inspect
      "#<#{self.class.name} account_sid=#{@account_sid} base_url=#{@base_url}>"
    end
    alias to_s inspect

    private

    def build_uri(path, override, params)
      base = override || @base_url
      uri = URI.parse(path)
      uri = URI.join("#{base}/", path) unless uri.absolute?
      unless uri.is_a?(URI::HTTP) && uri.host && !uri.userinfo
        raise ArgumentError, 'expected an HTTP(S) request URL without userinfo'
      end
      uri.query = encode_values(params) if params && !params.empty?
      uri
    rescue URI::Error, ArgumentError, TypeError => e
      raise ConnectionError.new("invalid request URI: #{e.message}", status_code: 0)
    end

    def send_with_retries(method, uri, form: nil, json: nil, auth: true, accept: 'application/json')
      verb = method.to_s.upcase
      idempotent = IDEMPOTENT_METHODS.include?(verb)
      attempt = 0
      loop do
        req = build_net_request(verb, uri)
        req['Accept'] = accept
        req['User-Agent'] = @user_agent
        if auth
          key = @credential.call
          unless @account_sid && key
            raise ConfigurationError, 'account_sid and api_key are required for authenticated requests'
          end
          req.basic_auth(@account_sid, key)
        end
        if json
          req['Content-Type'] = 'application/json'
          req.body = JSON.generate(json)
        elsif form
          req['Content-Type'] = 'application/x-www-form-urlencoded'
          req.body = encode_values(form)
        end

        response = exchange(uri, req)
        status = response.code.to_i
        retry_after = retry_after_seconds(response)
        if status == 429 && retry_after && retry_after > RETRY_AFTER_CAP
          raise_for_response(response)
        end
        if attempt < @max_retries && (status == 429 || (idempotent && RETRYABLE_STATUSES.include?(status)))
          response.body # Net::HTTP buffers the complete body before releasing the connection.
          delay = retry_after || backoff_delay(attempt)
          sleep_for(delay) if delay.positive?
          attempt += 1
          next
        end
        return response
      rescue NetworkFailure => e
        # These failures can only occur while establishing the connection
        # (DNS, routing, TCP connect, TLS handshake), so the request was
        # provably never sent — safe to retry even for POST.
        safe_connect = [SocketError, Net::OpenTimeout, OpenSSL::SSL::SSLError,
                        Errno::ECONNREFUSED, Errno::ETIMEDOUT,
                        Errno::ENETUNREACH, Errno::EHOSTUNREACH].any? { |c| e.original.is_a?(c) }
        if attempt < @max_retries && (idempotent || safe_connect)
          sleep_for(backoff_delay(attempt))
          attempt += 1
          next
        end
        raise ConnectionError.new("transport error after #{attempt + 1} attempt(s): #{e.original.message}",
                                  status_code: 0), cause: e.original
      end
    end

    # The lock covers both connection selection and the entire response read.
    # Host changes do not finish connections belonging to another origin.
    def exchange(uri, req)
      @mutex.synchronize do
        origin = [uri.scheme, uri.host, uri.port]
        connecting = true
        http, owned = @connections[origin] ||= connection_for(uri)
        http.max_retries = 0 # Only the counted SDK retry loop may resend a request.
        http.start unless http.started?
        connecting = false
        http.request(req)
      rescue Error
        raise
      rescue StandardError => e
        @connections.delete(origin)
        finish(http) if http && owned
        raise NetworkFailure.new(e, connecting), cause: e
      end
    end

    def connection_for(uri)
      owned = @http_client.nil?
      http = if owned
               Net::HTTP.new(uri.host, uri.port)
             elsif @http_client.is_a?(Net::HTTP)
               @http_client
             elsif @http_client.method(:call).arity == 1 || (@http_client.respond_to?(:arity) && @http_client.arity == 1)
               @http_client.call(uri)
             else
               @http_client.call(uri.host, uri.port)
             end
      unless http.is_a?(Net::HTTP) && http.address == uri.host && http.port == uri.port
        raise ConfigurationError, 'http_client must match the requested host/port; use a factory for multiple hosts'
      end
      if !http.started?
        http.use_ssl = uri.scheme == 'https'
      elsif http.use_ssl? != (uri.scheme == 'https')
        raise ConfigurationError, 'http_client TLS scheme does not match the requested origin'
      end
      if owned
        http.open_timeout = @timeout
        http.read_timeout = @timeout
        http.write_timeout = @timeout
        http.keep_alive_timeout = 30
      end
      [http, owned]
    end

    def finish(http)
      http.finish if http.started?
    rescue IOError, SystemCallError
      nil # A closed socket already satisfies close's postcondition.
    end

    def build_net_request(verb, uri)
      klass = { 'GET' => Net::HTTP::Get, 'HEAD' => Net::HTTP::Head, 'POST' => Net::HTTP::Post,
                'PUT' => Net::HTTP::Put, 'PATCH' => Net::HTTP::Patch, 'DELETE' => Net::HTTP::Delete }[verb]
      raise ArgumentError, "unsupported HTTP method: #{verb}" unless klass

      klass.new(uri)
    end

    def encode_values(values)
      pairs = []
      values.each do |key, value|
        next if value.nil?

        (value.is_a?(Array) ? value : [value]).each { |v| pairs << [key.to_s, format_scalar(v)] }
      end
      URI.encode_www_form(pairs)
    end

    def format_scalar(value)
      case value
      when Time then value.getutc.iso8601
      when DateTime then value.new_offset(0).iso8601
      when Date then value.iso8601
      when Hash then JSON.generate(value)
      else value.to_s
      end
    end

    def retry_after_seconds(response)
      text = response['retry-after']
      return nil unless text
      return text.to_f if text.match?(/\A\d+(?:\.\d+)?\z/)

      [Time.httpdate(text) - Time.now, 0.0].max
    rescue ArgumentError
      nil
    end

    def backoff_delay(attempt)
      rand * [8.0, 0.5 * (2**[attempt, 5].min)].min
    end

    def sleep_for(seconds)
      sleep(seconds)
    end

    def resolve_redirect(uri, location)
      raise ArgumentError, 'redirect missing Location' if location.nil? || location.empty?

      target = URI.join(uri.to_s, location)
      raise ArgumentError, 'redirect must use HTTP(S) without userinfo' unless target.is_a?(URI::HTTP) && target.host && !target.userinfo

      target
    rescue URI::Error, ArgumentError => e
      raise ConnectionError.new("invalid redirect: #{e.message}", status_code: 0)
    end

    def same_origin?(a, b)
      a.scheme == b.scheme && a.host == b.host && a.port == b.port
    end

    def parse_response(response)
      raise_for_response(response) unless response.is_a?(Net::HTTPSuccess)
      return nil if response.body.nil? || response.body.empty?

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ApiError.new("could not decode success response as JSON: #{e.message}",
                         status_code: response.code.to_i, body: response.body)
    end

    def raise_for_response(response)
      raw = response.body
      body = begin
        raw.nil? || raw.empty? ? raw : JSON.parse(raw)
      rescue JSON::ParserError
        raw
      end
      data = body.is_a?(Hash) ? body : {}
      code = data['code']
      code = code.to_i if code.is_a?(String) && code.match?(/\A\d+\z/)
      error = VoiceML.error_from_response(response.code.to_i, data['message'] || "HTTP #{response.code}",
                                          code: code, body: body, more_info: data['more_info'])
      error.retry_after = retry_after_seconds(response) if error.is_a?(RateLimitError)
      raise error
    end
  end

  # A redacting transport view pinned to one product origin.
  # @api private
  class ScopedTransport
    attr_reader :base_url

    def initialize(inner, base_url)
      @inner = inner
      @base_url = Transport.strip_trailing_slashes(base_url)
    end

    def account_sid
      @inner.account_sid
    end

    def request(method, path, **options)
      @inner.request(method, path, **options, base_url: @base_url)
    end

    def request_raw(method, path, **options)
      @inner.request_raw(method, path, **options, base_url: @base_url)
    end

    def fetch_bytes(path)
      @inner.fetch_bytes(path, base_url: @base_url)
    end

    def inspect
      "#<#{self.class.name} base_url=#{@base_url}>"
    end
    alias to_s inspect
  end
end

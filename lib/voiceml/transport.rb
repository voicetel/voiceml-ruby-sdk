# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

require_relative 'errors'
require_relative 'version'

module VoiceML
  # HTTP transport for the VoiceML REST API.
  #
  # - Auth: HTTP Basic with `account_sid` (Twilio-format `AC` + 32 hex) as the username and the
  #   per-tenant API key as the password. Drop-in compatible with the Twilio SDK constructor.
  # - Wire format: requests are form-urlencoded by default (Twilio convention). The server also
  #   accepts JSON; pass `json: <hash>` to send JSON instead. Responses are always JSON.
  # - Retries: 429 + 5xx are retried up to `max_retries` times with exponential backoff,
  #   honoring the `Retry-After` header when the server emits one.
  # - Binary fetch: `fetch_bytes` follows the 302 -> S3 redirect that
  #   `GET /Recordings/{sid}.wav` issues when audio has been archived. Callers usually only
  #   care about the final bytes.
  #
  # @api private
  class Transport
    DEFAULT_BASE_URL    = 'https://voiceml.voicetel.com'
    DEFAULT_TIMEOUT     = 30
    DEFAULT_MAX_RETRIES = 2
    RETRYABLE_STATUSES  = [429, 500, 502, 503, 504].freeze

    attr_reader :account_sid, :base_url, :max_retries, :timeout, :user_agent

    def initialize(account_sid:, api_key:, base_url: DEFAULT_BASE_URL,
                   timeout: DEFAULT_TIMEOUT, max_retries: DEFAULT_MAX_RETRIES,
                   user_agent: nil, http_client: nil)
      raise ConfigurationError, 'account_sid is required' if account_sid.nil? || account_sid.empty?
      raise ConfigurationError, 'api_key is required'     if api_key.nil? || api_key.empty?
      raise ConfigurationError, 'max_retries must be >= 0' if max_retries.negative?

      @account_sid = account_sid
      @api_key     = api_key
      @base_url    = base_url.sub(%r{/+\z}, '')
      @timeout     = timeout
      @max_retries = max_retries
      @user_agent  = user_agent || "voiceml-ruby/#{VoiceML::VERSION}"
      @uri_base    = URI.parse(@base_url)
      @conn_mutex  = Mutex.new
      @owns_client = http_client.nil?
      @persistent  = http_client
    end

    # Close the persistent connection, releasing the underlying socket.
    # Safe to call multiple times. The transport remains usable — the next
    # request will transparently open a fresh connection.
    def close
      @conn_mutex.synchronize { finish_connection } if @owns_client
    end

    # Perform a request. Pass `form:` for a form-urlencoded POST body, `json:` for a JSON body,
    # or neither for a plain GET/DELETE. `params:` are query-string params.
    #
    # @return [Hash, Array, nil] the parsed JSON body (or `nil` for empty 2xx).
    # @raise [VoiceML::ApiError] for non-2xx responses (subclasses by status family).
    def request(method, path, params: nil, form: nil, json: nil)
      uri = build_uri(path, params)

      attempt = 0
      loop do
        response = perform_request(method, uri, form: form, json: json)

        if RETRYABLE_STATUSES.include?(response.code.to_i) && attempt < @max_retries
          sleep(backoff_delay(attempt, response))
          attempt += 1
          next
        end

        return parse_response(response)
      rescue *transport_errors => e
        raise ApiError.new("transport error after #{attempt + 1} attempts: #{e.message}",
                           status_code: 0) if attempt >= @max_retries

        sleep(backoff_delay(attempt))
        attempt += 1
      end
    end

    # Fetch a binary payload (audio/wav recordings). Follows the single 302 -> presigned S3
    # redirect that `GET /Recordings/{sid}.wav` issues when audio has been archived.
    #
    # @return [Array(Integer, String, Hash)] status code, response body bytes, header hash.
    def fetch_bytes(path)
      uri = build_uri(path, nil)
      visited = []
      loop do
        raise ApiError.new('too many redirects', status_code: 0) if visited.length > 5

        req = Net::HTTP::Get.new(uri)
        apply_common_headers(req, auth: !visited.any? { |u| u.host != uri.host })
        response = send_on_persistent(uri, req)

        case response
        when Net::HTTPRedirection
          visited << uri
          uri = URI.parse(response['location'])
          next
        when Net::HTTPSuccess
          headers = response.each_header.to_h
          return [response.code.to_i, response.body || '', headers]
        else
          raise_for_response(response)
        end
      end
    end

    private

    def transport_errors
      [Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET,
       Errno::EHOSTUNREACH, SocketError, EOFError]
    end

    def build_uri(path, params)
      uri = if path.start_with?('http://', 'https://')
              URI.parse(path)
            else
              URI.parse("#{@base_url}#{path}")
            end
      if params && !params.empty?
        encoded = encode_query(params)
        uri.query = encoded unless encoded.empty?
      end
      uri
    end

    def encode_query(params)
      pairs = []
      params.each do |k, v|
        next if v.nil?

        if v.is_a?(Array)
          v.each { |entry| pairs << [k.to_s, format_scalar(entry)] }
        else
          pairs << [k.to_s, format_scalar(v)]
        end
      end
      URI.encode_www_form(pairs)
    end

    def encode_form(form)
      pairs = []
      form.each do |k, v|
        next if v.nil?

        if v.is_a?(Array)
          v.each { |entry| pairs << [k.to_s, format_scalar(entry)] }
        else
          pairs << [k.to_s, format_scalar(v)]
        end
      end
      URI.encode_www_form(pairs)
    end

    def format_scalar(value)
      case value
      when true  then 'true'
      when false then 'false'
      else value.to_s
      end
    end

    def perform_request(method, uri, form:, json:)
      req = build_net_request(method, uri)
      apply_common_headers(req, auth: true)

      if !json.nil?
        req['Content-Type'] = 'application/json'
        req.body = JSON.generate(json)
      elsif !form.nil? && method.to_s.upcase != 'GET' && method.to_s.upcase != 'DELETE'
        req['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = encode_form(form)
      end

      send_on_persistent(uri, req)
    end

    def build_net_request(method, uri)
      case method.to_s.upcase
      when 'GET'    then Net::HTTP::Get.new(uri)
      when 'POST'   then Net::HTTP::Post.new(uri)
      when 'PUT'    then Net::HTTP::Put.new(uri)
      when 'DELETE' then Net::HTTP::Delete.new(uri)
      when 'PATCH'  then Net::HTTP::Patch.new(uri)
      else
        raise ArgumentError, "unsupported HTTP method: #{method}"
      end
    end

    def apply_common_headers(req, auth:)
      req['Accept']     = 'application/json'
      req['User-Agent'] = @user_agent
      req.basic_auth(@account_sid, @api_key) if auth
    end

    def send_on_persistent(uri, req)
      conn = persistent_connection(uri)
      conn.request(req)
    rescue IOError, Errno::EPIPE, Errno::ECONNRESET
      @conn_mutex.synchronize { finish_connection }
      persistent_connection(uri).request(req)
    end

    def persistent_connection(uri)
      @conn_mutex.synchronize do
        if @persistent&.started? &&
           @persistent.address == uri.host &&
           @persistent.port == uri.port
          return @persistent
        end
        finish_connection
        h = Net::HTTP.new(uri.host, uri.port)
        h.use_ssl = uri.scheme == 'https'
        h.open_timeout = @timeout
        h.read_timeout = @timeout
        h.keep_alive_timeout = 30
        h.start
        @persistent = h
      end
    end

    def finish_connection
      @persistent&.finish rescue nil
      @persistent = nil
    end

    def parse_response(response)
      status = response.code.to_i
      return nil if status >= 200 && status < 300 && (response.body.nil? || response.body.empty?)

      if status >= 200 && status < 300
        begin
          return JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise ApiError.new("non-JSON success response: #{response.body.to_s[0, 200]}",
                             status_code: status, body: response.body)
        end
      end

      raise_for_response(response)
    end

    def raise_for_response(response)
      status = response.code.to_i
      raw_body = response.body
      body = begin
        raw_body && !raw_body.empty? ? JSON.parse(raw_body) : raw_body
      rescue JSON::ParserError
        raw_body
      end

      code = nil
      message = "HTTP #{status}"
      more_info = nil
      if body.is_a?(Hash)
        rc = body['code']
        code = rc if rc.is_a?(Integer) || rc.is_a?(String)
        m = body['message']
        message = m if m.is_a?(String) && !m.empty?
        mi = body['more_info']
        more_info = mi if mi.is_a?(String) && !mi.empty?
      end

      raise VoiceML.error_from_response(status, message, code: code, body: body, more_info: more_info)
    end

    def backoff_delay(attempt, response = nil)
      if response
        ra = response['retry-after']
        if ra
          begin
            return [Float(ra), 0.0].max
          rescue ArgumentError, TypeError
            # fall through
          end
        end
      end
      [8.0, 0.5 * (2**attempt)].min
    end
  end
end

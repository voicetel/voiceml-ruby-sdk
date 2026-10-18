# frozen_string_literal: true

require 'base64'
require 'openssl'

module VoiceML
  # Validates the `X-Twilio-Signature` header on inbound VoiceML webhooks, and
  # computes signatures for testing server-side handlers.
  #
  # The algorithm (matching the VoiceML server):
  #
  # 1. Take the full request URL with any `#fragment` stripped.
  # 2. For a POST, append `key + value` for every form pair, sorted ascending
  #    by key in byte order; repeated keys keep their received value order.
  #    For a GET, the URL alone is signed.
  # 3. HMAC-SHA1 with the account API key as the key, then standard Base64
  #    (padded).
  #
  # Comparison is constant-time. Like Twilio's validators, a URL that differs
  # only by an explicit default port (`:443` for https, `:80` for http) also
  # validates, in both directions.
  #
  # @example
  #   validator = VoiceML::RequestValidator.new(api_key)
  #   valid = validator.valid?(request.url, request.params, request.headers['X-Twilio-Signature'])
  class RequestValidator
    # @param api_key [String] the account API key the server signs with.
    def initialize(api_key)
      @credential = -> { api_key }
    end

    # Compute the signature for a URL and params. `params` may be a Hash (use
    # an Array value for repeated keys) or an Array of `[key, value]` pairs in
    # their received order.
    #
    # @return [String] Base64 HMAC-SHA1 digest.
    def signature(url, params = {}, method: 'POST')
      data = signature_base(url, method.to_s.upcase == 'POST' ? params : nil)
      digest = OpenSSL::HMAC.digest('SHA1', @credential.call, data)
      Base64.strict_encode64(digest)
    end

    # Validate an incoming webhook. `params` may be a Hash (Array value for
    # repeated keys) or an Array of `[key, value]` pairs in received order.
    #
    # @return [Boolean]
    def valid?(url, params, signature, method: 'POST')
      given = signature.to_s
      candidates = [signature(url, params, method: method)]
      variant = port_variant(url)
      candidates << signature(variant, params, method: method) unless variant.nil?

      candidates.map { |expected| constant_time_equal?(expected, given) }.any?
    end
    alias validate valid?

    private

    # The string that gets HMAC'd: URL (fragment stripped) plus, for POSTs,
    # `key + value` per pair sorted by key byte order, repeated keys keeping
    # their received value order.
    def signature_base(url, params)
      base = url.to_s.sub(/#.*\z/, '')
      return base if params.nil?

      pairs = pairs_from(params)
      return base if pairs.empty?

      sorted = pairs.each_with_index.to_a
                    .sort_by { |(pair, index)| [pair.first.b, index] }
                    .map(&:first)
      base + sorted.map { |key, value| "#{key}#{value}" }.join
    end

    def pairs_from(params)
      case params
      when Array then params.map { |key, value| [key.to_s, value.to_s] }
      else
        pairs = []
        params.each do |key, value|
          if value.is_a?(Array)
            value.each { |entry| pairs << [key.to_s, entry.to_s] }
          else
            pairs << [key.to_s, value.to_s]
          end
        end
        pairs
      end
    end

    # The same URL with the default port added or removed (`:443` for https,
    # `:80` for http), or nil when the URL has no such variant. String-based:
    # URI round-trips normalise an explicit default port away.
    def port_variant(url)
      s = url.to_s
      match = s.match(%r{\Ahttps?://[^/?#]*})
      return nil if match.nil?

      prefix = match[0]
      rest = s[prefix.length..] || ''
      if prefix =~ %r{\Ahttps://[^/?#]+:443\z}
        prefix.sub(/:443\z/, '') + rest
      elsif prefix =~ %r{\Ahttps://[^/?#:]+\z}
        "#{prefix}:443#{rest}"
      elsif prefix =~ %r{\Ahttp://[^/?#]+:80\z}
        prefix.sub(/:80\z/, '') + rest
      elsif prefix =~ %r{\Ahttp://[^/?#:]+\z}
        "#{prefix}:80#{rest}"
      end
    end

    def constant_time_equal?(a, b)
      return false unless a.bytesize == b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    end
  end

  # Convenience wrapper: validate one webhook without instantiating a
  # {RequestValidator}.
  #
  # @return [Boolean]
  def self.validate_request(api_key, url, params, signature, method: 'POST')
    RequestValidator.new(api_key).valid?(url, params, signature, method: method)
  end
end

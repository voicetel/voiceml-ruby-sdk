# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

require_relative '../models/diagnostics'

module VoiceML
  # Diagnostic surfaces — `/health` and the OpenAPI doc endpoints.
  #
  # These don't sit under `/2010-04-01/Accounts/{AccountSid}/...`; they're mounted at the
  # server root and don't require auth (the spec marks them `security: []`).
  class DiagnosticsResource
    def initialize(transport)
      @transport = transport
    end

    # Hit `GET /health`. 200 = all hard checks pass; 503 raises `VoiceML::ServerError`
    # with the failure list on `error.body`.
    #
    # @return [VoiceML::HealthStatus]
    def health
      HealthStatus.from_hash(unauth_request('/health'))
    end

    # Fetch the OpenAPI spec as parsed JSON.
    #
    # @return [Hash]
    def openapi_json
      unauth_request('/openapi.json')
    end

    private

    def unauth_request(path)
      uri = URI.parse("#{@transport.base_url}#{path}")
      req = Net::HTTP::Get.new(uri)
      req['Accept']     = 'application/json'
      req['User-Agent'] = @transport.user_agent
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = uri.scheme == 'https'
      http.open_timeout = 10
      http.read_timeout = 10
      response = http.start { |h| h.request(req) }

      status = response.code.to_i
      unless status >= 200 && status < 300
        body = begin
          response.body && !response.body.empty? ? JSON.parse(response.body) : response.body
        rescue JSON::ParserError
          response.body
        end
        message = body.is_a?(Hash) && body['message'].is_a?(String) ? body['message'] : "HTTP #{status}"
        raise VoiceML.error_from_response(status, message, body: body)
      end

      return nil if response.body.nil? || response.body.empty?

      JSON.parse(response.body)
    end
  end
end

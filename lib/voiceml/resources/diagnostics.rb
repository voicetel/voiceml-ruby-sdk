# frozen_string_literal: true

require_relative '../models/diagnostics'

module VoiceML
  # Diagnostic surfaces — `/health` and the OpenAPI doc endpoints.
  #
  # These don't sit under `/2010-04-01/Accounts/{AccountSid}/...`; they're mounted at the
  # server root and require no credentials (the spec marks them `security: []`), so every
  # call routes through the normal transport — the configured HTTP client, timeout, proxy
  # and User-Agent apply — with auth omitted.
  class DiagnosticsResource
    def initialize(transport)
      @transport = transport
    end

    # Hit `GET /health`. 200 = all hard checks pass; 503 raises `VoiceML::ServerError`
    # with the failure list on `error.body`. `warnings`/`failures` are optional in the
    # response body.
    #
    # @return [VoiceML::HealthStatus]
    def health
      HealthStatus.from_hash(@transport.request(:get, '/health', auth: false))
    end

    # Fetch the OpenAPI spec as parsed JSON.
    #
    # @return [Hash]
    def openapi_json
      @transport.request(:get, '/openapi.json', auth: false)
    end

    # Fetch the OpenAPI spec as raw YAML (`/openapi.yaml`).
    #
    # @return [String]
    def openapi_yaml
      _status, body, _headers = @transport.request_raw(:get, '/openapi.yaml', auth: false)
      body
    end

    # Fetch the OpenAPI spec as raw YAML (`/openapi.yml`).
    #
    # @return [String]
    def openapi_yml
      _status, body, _headers = @transport.request_raw(:get, '/openapi.yml', auth: false)
      body
    end
  end
end

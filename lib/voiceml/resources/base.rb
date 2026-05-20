# frozen_string_literal: true

module VoiceML
  # @api private
  # Mixin holding a `Transport` reference and helpers for AccountSid-scoped pathing.
  class BaseResource
    def initialize(transport)
      @transport = transport
    end

    private

    # Build a URL under `/2010-04-01/Accounts/{AccountSid}/...`. Caller passes path segments
    # (e.g. `"Calls"`, sid, `"Recordings"`). Empty segments are skipped; nothing is
    # URL-encoded — sids and slugs never need escaping.
    #
    # As of v0.5.0 every REST endpoint resolves under its `.json` form (Twilio drop-in
    # compatibility). Pass `suffix: ''` to opt out — used by `.wav` audio fetches and any
    # caller that needs to append a different extension.
    def path(*parts, suffix: '.json')
      tail = parts.compact.reject { |p| p.to_s.empty? }.join('/')
      "/2010-04-01/Accounts/#{@transport.account_sid}/#{tail}#{suffix}"
    end

    # Translate snake_case Ruby kwargs to the form/query field names the server expects.
    # `nil` values are dropped; booleans become "true"/"false" inside Transport.
    def form_params(map, kwargs)
      out = {}
      map.each do |wire_name, ruby_key|
        value = kwargs[ruby_key]
        next if value.nil?

        out[wire_name] = value
      end
      out
    end
  end
end

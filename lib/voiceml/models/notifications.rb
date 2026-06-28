# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Twilio-compatible Notification resource — a log row for a specific webhook /
  # TwiML invocation failure (HTTP non-2xx, parse error, etc.).
  #
  # VoiceML treats `/Notifications` and `/Calls/{Sid}/Notifications` as compat
  # stubs (always-empty list, fetch-by-sid returns 404), so this model decodes
  # Twilio's documented shape for migration tooling and conformance checks
  # without implying voiceml emits notification rows.
  #
  # The same resource shape backs both account-scoped and call-scoped fetches.
  class Notification
    ATTRIBUTES = %w[
      sid account_sid call_sid api_version
      error_code more_info message_date message_text log
      request_method request_url request_variables
      response_body response_headers
      date_created date_updated uri
    ].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
      ATTRIBUTES.each do |field|
        value = attrs.key?(field) ? attrs[field] : attrs[field.to_sym]
        instance_variable_set("@#{field}", value)
      end
    end

    def self.from_hash(hash)
      return nil if hash.nil?

      new(hash)
    end
  end
end

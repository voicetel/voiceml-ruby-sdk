# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Twilio-compatible UserDefinedMessage resource — out-of-band messages a
  # caller can attach to an in-progress call, delivered via the SDK 2.x
  # WebSocket. VoiceML doesn't surface this as a first-class resource yet;
  # the model exists to decode the response shape (KX-prefixed sid +
  # account/call sids) for conformance and round-trip tooling.
  class UserDefinedMessage
    ATTRIBUTES = %w[
      sid account_sid call_sid date_created
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

# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Twilio-compatible OutgoingCallerId resource. The `sid` is `PN`-prefixed
  # to mirror Twilio (caller-id resources share the IncomingPhoneNumber SID
  # space upstream); `phone_number` carries the verified E.164 number.
  class OutgoingCallerId
    ATTRIBUTES = %w[
      sid account_sid friendly_name phone_number
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

  # Paginated `GET /OutgoingCallerIds` response.
  class OutgoingCallerIdList
    include Pageable

    attr_reader :outgoing_caller_ids

    def initialize(hash = {})
      assign_page_fields(hash)
      @outgoing_caller_ids =
        (hash['outgoing_caller_ids'] || []).map { |o| OutgoingCallerId.from_hash(o) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end

  # `POST /OutgoingCallerIds` response — the verify-by-callback flow used to
  # provision a new outgoing caller id. No `sid` on the wire (the resource
  # doesn't exist until the validation_code is dialled back); the
  # `validation_code` is what the user is prompted to enter on the live call.
  class ValidationRequest
    ATTRIBUTES = %w[account_sid call_sid friendly_name phone_number validation_code].freeze

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

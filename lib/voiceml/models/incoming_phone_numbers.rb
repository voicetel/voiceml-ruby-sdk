# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # A Twilio-compatible IncomingPhoneNumber — a DID assigned to the tenant.
  #
  # `sid` is the canonical `PN`-prefixed identifier (34 chars); `phone_number` carries the
  # E.164 form. These are distinct fields — twilio-ruby callers that lookup-by-number then
  # fetch-by-sid work unchanged.
  #
  # Twilio-compat fields VoiceML doesn't track (regulatory, SMS, emergency, trunking) are
  # surfaced verbatim so strict-binding consumers can read e.g. `.capabilities['voice']`.
  class IncomingPhoneNumber
    ATTRIBUTES = %w[
      sid account_sid phone_number friendly_name api_version uri
      voice_url voice_method voice_fallback_url voice_fallback_method
      voice_application_sid voice_caller_id_lookup voice_receive_mode
      origin beta capabilities type
      sms_url sms_method sms_fallback_url sms_fallback_method sms_application_sid
      status_callback status_callback_method
      trunk_sid address_sid address_requirements identity_sid bundle_sid
      emergency_status emergency_address_sid emergency_address_status
      status date_created date_updated
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

  # Paginated `GET /IncomingPhoneNumbers` response. Same envelope shape as `CallList`.
  class IncomingPhoneNumberList
    include Pageable

    attr_reader :incoming_phone_numbers

    def initialize(hash = {})
      assign_page_fields(hash)
      @incoming_phone_numbers =
        (hash['incoming_phone_numbers'] || []).map { |n| IncomingPhoneNumber.from_hash(n) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

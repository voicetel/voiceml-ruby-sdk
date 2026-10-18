# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Persistent TwiML+callback bundle dispatched by `<Dial><Application>`.
  class Application
    include RawAttributes
    ATTRIBUTES = %w[
      sid account_sid friendly_name api_version voice_url voice_method
      voice_fallback_url voice_fallback_method voice_caller_id_lookup
      status_callback status_callback_method status_callback_event
      message_status_callback sms_status_callback
      sms_url sms_method sms_fallback_url sms_fallback_method
      date_created date_updated uri
    ].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
      @raw_attributes = attrs
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

  # Paginated `GET /Applications` response.
  class ApplicationList
    include RawAttributes
    include Pageable

    attr_reader :applications

    def initialize(hash = {})
      @raw_attributes = hash
      assign_page_fields(hash)
      @applications = (hash['applications'] || []).map { |a| Application.from_hash(a) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

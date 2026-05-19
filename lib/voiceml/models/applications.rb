# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Persistent TwiML+callback bundle dispatched by `<Dial><Application>`.
  class Application
    ATTRIBUTES = %w[
      sid account_sid friendly_name api_version voice_url voice_method
      voice_fallback_url voice_fallback_method voice_caller_id_lookup
      status_callback status_callback_method status_callback_event
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

  # Paginated `GET /Applications` response.
  class ApplicationList
    include Pageable

    attr_reader :applications

    def initialize(hash = {})
      assign_page_fields(hash)
      @applications = (hash['applications'] || []).map { |a| Application.from_hash(a) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

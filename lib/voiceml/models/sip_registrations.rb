# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # One live SIP registration on a `SIP/Domains` ingress —
  # `GET /SIP/Registrations`.
  class SipRegistration
    include RawAttributes
    ATTRIBUTES = %w[
      aor username domain domain_sid status caller_id user_agent
      last_registered contacts active_call
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

  # Paginated `GET /SIP/Registrations` response.
  class SipRegistrationList
    include Pageable
    include RawAttributes

    attr_reader :registrations

    def initialize(hash = {})
      @raw_attributes = hash
      assign_page_fields(hash)
      @registrations = (hash['registrations'] || []).map { |r| SipRegistration.from_hash(r) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

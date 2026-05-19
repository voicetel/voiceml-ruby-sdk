# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # SIPREC-session resource (REST equivalent of `<Start><Siprec>`).
  class SiprecSession
    ATTRIBUTES = %w[
      sid account_sid call_sid name connector_name status api_version uri
      date_created date_updated
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

  # Paginated `GET /Calls/{Sid}/Siprec` response.
  class SiprecList
    include Pageable

    attr_reader :siprec

    def initialize(hash = {})
      assign_page_fields(hash)
      @siprec = (hash['siprec'] || []).map { |s| SiprecSession.from_hash(s) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

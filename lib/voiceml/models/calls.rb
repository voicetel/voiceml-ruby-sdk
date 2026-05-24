# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # A Twilio-compatible Call resource. Returned by `client.calls.create`, `client.calls.get`,
  # `client.calls.update`, and listed in `CallList#calls`.
  class Call
    ATTRIBUTES = %w[
      sid account_sid api_version to to_formatted from from_formatted
      parent_call_sid caller_name forwarded_from status direction
      answered_by start_time end_time duration price price_unit
      phone_number_sid annotation group_sid queue_time trunk_sid
      date_created date_updated uri subresource_uris
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

  # Paginated `GET /Calls` response.
  class CallList
    include Pageable

    attr_reader :calls

    def initialize(hash = {})
      assign_page_fields(hash)
      @calls = (hash['calls'] || []).map { |c| Call.from_hash(c) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

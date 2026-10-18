# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # One usage bucket from `GET /Usage/Records[/{Window}]`.
  class UsageRecord
    include RawAttributes
    ATTRIBUTES = %w[
      account_sid api_version as_of category count count_unit description
      end_date price price_unit start_date subresource_uris uri usage usage_unit
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

  # Paginated `GET /Usage/Records...` response.
  class UsageRecordList
    include Pageable
    include RawAttributes

    attr_reader :usage_records

    def initialize(hash = {})
      @raw_attributes = hash
      assign_page_fields(hash)
      @usage_records = (hash['usage_records'] || []).map { |r| UsageRecord.from_hash(r) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

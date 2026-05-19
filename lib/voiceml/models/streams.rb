# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Media-stream session (REST equivalent of `<Connect><Stream>` / `<Start><Stream>`).
  class Stream
    ATTRIBUTES = %w[
      sid account_sid call_sid name status api_version uri
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

  # Paginated `GET /Calls/{Sid}/Streams` response.
  class StreamList
    include Pageable

    attr_reader :streams

    def initialize(hash = {})
      assign_page_fields(hash)
      @streams = (hash['streams'] || []).map { |s| Stream.from_hash(s) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

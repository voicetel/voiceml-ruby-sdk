# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Media-stream session (REST equivalent of `<Connect><Stream>` / `<Start><Stream>`).
  # Start (`POST /Calls/{Sid}/Streams`) and stop (`POST /Calls/{Sid}/Streams/{Sid}`)
  # are the live operations; the list/fetch GETs were removed from the API.
  class Stream
    include RawAttributes
    ATTRIBUTES = %w[
      sid account_sid call_sid name status api_version uri
      date_created date_updated
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
end

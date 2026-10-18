# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Real-time per-call transcription (REST equivalent of `<Start><Transcription>`).
  class CallTranscription
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

  # Stored transcription of a Recording — `GET /Recordings/{Sid}/Transcriptions`
  # and the account-wide `GET /Transcriptions`.
  class Transcription
    include RawAttributes
    ATTRIBUTES = %w[
      sid account_sid status recording_sid duration transcription_text type
      price price_unit api_version uri date_created date_updated
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

  # Paginated Transcription response (`GET /Transcriptions`,
  # `GET /Recordings/{RecordingSid}/Transcriptions`).
  class TranscriptionList
    include Pageable
    include RawAttributes

    attr_reader :transcriptions

    def initialize(hash = {})
      @raw_attributes = hash
      assign_page_fields(hash)
      @transcriptions = (hash['transcriptions'] || []).map { |t| Transcription.from_hash(t) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

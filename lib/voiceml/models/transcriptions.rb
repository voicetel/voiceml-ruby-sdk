# frozen_string_literal: true

require_relative 'common'

module VoiceML
  # Real-time per-call transcription (REST equivalent of `<Start><Transcription>`).
  class CallTranscription
    ATTRIBUTES = %w[
      sid account_sid call_sid name language_code transcription_engine
      status api_version uri date_created date_updated
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

  # Paginated `GET /Calls/{Sid}/Transcriptions` response.
  class TranscriptionList
    include Pageable

    attr_reader :transcriptions

    def initialize(hash = {})
      assign_page_fields(hash)
      @transcriptions = (hash['transcriptions'] || []).map { |t| CallTranscription.from_hash(t) }
    end

    def self.from_hash(hash)
      new(hash || {})
    end
  end
end

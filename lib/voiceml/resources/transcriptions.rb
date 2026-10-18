# frozen_string_literal: true

require_relative 'base'
require_relative '../models/transcriptions'

module VoiceML
  # Operations on the account-wide `/Transcriptions` — stored transcriptions
  # across all recordings. Per-recording access lives on
  # {VoiceML::RecordingsResource}; live-call start/stop on
  # {VoiceML::CallsResource}.
  class TranscriptionsResource < BaseResource
    LIST_FIELDS = {
      'DateCreated'  => :date_created,
      'DateCreated<' => :date_created_lt,
      'DateCreated>' => :date_created_gt,
      'Page'         => :page,
      'PageSize'     => :page_size,
      'PageToken'    => :page_token
    }.freeze

    # @return [VoiceML::TranscriptionList]
    def list(**kwargs)
      TranscriptionList.from_hash(
        @transport.request(:get, path('Transcriptions'),
                           params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::Transcription]
    def fetch(sid)
      Transcription.from_hash(@transport.request(:get, path('Transcriptions', sid)))
    end

    # @return [nil]
    def delete(sid)
      @transport.request(:delete, path('Transcriptions', sid))
      nil
    end
  end
end

# frozen_string_literal: true

require_relative 'base'
require_relative '../models/recordings'

module VoiceML
  # Account-scoped `/Recordings` operations.
  #
  # Per-call recording start/stop/list lives on {VoiceML::CallsResource} — this resource
  # handles the account-wide list, single-recording fetch (both metadata and audio),
  # and delete.
  class RecordingsResource < BaseResource
    LIST_FIELDS = {
      'Page'     => :page,
      'PageSize' => :page_size
    }.freeze

    # @return [VoiceML::RecordingList]
    def list(**kwargs)
      RecordingList.from_hash(
        @transport.request(:get, path('Recordings'), params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # Fetch the metadata JSON for a recording.
    # @return [VoiceML::Recording]
    def get(recording_sid)
      Recording.from_hash(@transport.request(:get, path('Recordings', recording_sid)))
    end

    # Fetch the WAV audio for a recording.
    #
    # Three server delivery shapes are flattened into one result by following any 302
    # redirect to S3:
    # - `200 OK` — local file present.
    # - `302 Found` — archived to S3; the SDK follows the presigned URL.
    # - `410 Gone` — local file gone AND no S3 key. Raises `VoiceML::GoneError`.
    #
    # @return [VoiceML::RecordingAudio]
    def get_audio(recording_sid)
      status, content, headers = @transport.fetch_bytes(
        "#{path('Recordings', recording_sid)}.wav"
      )
      content_type = headers['content-type']
      content_type = content_type.first if content_type.is_a?(Array)
      x_amz_id = headers['x-amz-id-2']
      RecordingAudio.new(
        sid: recording_sid,
        content: content,
        content_type: content_type || 'application/octet-stream',
        via_redirect: status == 200 && !x_amz_id.nil?
      )
    end

    # @return [nil]
    def delete(recording_sid)
      @transport.request(:delete, path('Recordings', recording_sid))
      nil
    end
  end
end

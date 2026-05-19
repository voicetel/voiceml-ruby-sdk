# frozen_string_literal: true

require_relative 'base'
require_relative '../models/conferences'
require_relative '../models/recordings'

module VoiceML
  # Operations on `/Conferences` and their participants/recordings.
  class ConferencesResource < BaseResource
    UPDATE_PARTICIPANT_FIELDS = {
      'Muted' => :muted,
      'Hold'  => :hold
    }.freeze

    # @return [VoiceML::ConferenceList]
    def list
      ConferenceList.from_hash(@transport.request(:get, path('Conferences')))
    end

    # @return [VoiceML::Conference]
    def get(conference_sid)
      Conference.from_hash(@transport.request(:get, path('Conferences', conference_sid)))
    end

    # End a live conference. v1 supports only `status: "completed"`.
    # @return [VoiceML::Conference]
    def end_conference(conference_sid, status: 'completed')
      data = @transport.request(:post, path('Conferences', conference_sid),
                                form: { 'Status' => status })
      Conference.from_hash(data)
    end

    # --- Participants ---

    # @return [VoiceML::ParticipantList]
    def list_participants(conference_sid)
      ParticipantList.from_hash(
        @transport.request(:get, path('Conferences', conference_sid, 'Participants'))
      )
    end

    # @return [VoiceML::Participant]
    def get_participant(conference_sid, call_sid)
      Participant.from_hash(
        @transport.request(:get, path('Conferences', conference_sid, 'Participants', call_sid))
      )
    end

    # Mute/unmute or hold/unhold a participant. At least one of `muted:` / `hold:` must be set.
    # @return [VoiceML::Participant]
    def update_participant(conference_sid, call_sid, **kwargs)
      data = @transport.request(
        :post,
        path('Conferences', conference_sid, 'Participants', call_sid),
        form: form_params(UPDATE_PARTICIPANT_FIELDS, kwargs)
      )
      Participant.from_hash(data)
    end

    # @return [nil]
    def kick_participant(conference_sid, call_sid)
      @transport.request(:delete,
                         path('Conferences', conference_sid, 'Participants', call_sid))
      nil
    end

    # --- Recordings ---

    # @return [VoiceML::RecordingList]
    def list_recordings(conference_sid)
      RecordingList.from_hash(
        @transport.request(:get, path('Conferences', conference_sid, 'Recordings'))
      )
    end
  end
end

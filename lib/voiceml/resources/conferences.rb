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

    LIST_FIELDS = {
      'FriendlyName' => :friendly_name,
      'Status'       => :status,
      'DateCreated'  => :date_created,
      'DateCreated<' => :date_created_lt,
      'DateCreated>' => :date_created_gt,
      'DateUpdated'  => :date_updated,
      'DateUpdated<' => :date_updated_lt,
      'DateUpdated>' => :date_updated_gt,
      'Page'         => :page,
      'PageSize'     => :page_size,
      'PageToken'    => :page_token
    }.freeze

    CREATE_PARTICIPANT_FIELDS = {
      'From'                   => :from,
      'To'                     => :to,
      'Label'                  => :label,
      'Muted'                  => :muted,
      'StartConferenceOnEnter' => :start_conference_on_enter,
      'EndConferenceOnExit'    => :end_conference_on_exit,
      'Timeout'                => :timeout,
      'StatusCallback'         => :status_callback,
      'StatusCallbackMethod'   => :status_callback_method,
      'StatusCallbackEvent'    => :status_callback_event
    }.freeze

    UPDATE_RECORDING_FIELDS = {
      'Status' => :status
    }.freeze

    LIST_PARTICIPANTS_FIELDS = {
      'Muted'    => :muted,
      'Hold'     => :hold,
      'Coaching' => :coaching,
      'Page'     => :page,
      'PageSize' => :page_size,
      'PageToken' => :page_token
    }.freeze

    LIST_CALL_RECORDINGS_FIELDS = {
      'DateCreated'   => :date_created,
      'DateCreated<'  => :date_created_lt,
      'DateCreated>'  => :date_created_gt,
      'Page'          => :page,
      'PageSize'      => :page_size,
      'PageToken'     => :page_token
    }.freeze

    # @return [VoiceML::ConferenceList]
    def list(**kwargs)
      ConferenceList.from_hash(
        @transport.request(:get, path('Conferences'), params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # @yield [VoiceML::Conference]
    # @return [Enumerator<VoiceML::Conference>] when no block given
    def each(**kwargs, &block)
      return enum_for(:each, **kwargs) unless block

      page_num = kwargs.delete(:page) || 0
      loop do
        chunk = list(**kwargs, page: page_num)
        chunk.conferences.each(&block)
        break if chunk.next_page_uri.nil? || chunk.next_page_uri.empty? || chunk.conferences.empty?
        page_num += 1
      end
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
    def list_participants(conference_sid, **kwargs)
      ParticipantList.from_hash(
        @transport.request(:get, path('Conferences', conference_sid, 'Participants'),
                           params: form_params(LIST_PARTICIPANTS_FIELDS, kwargs))
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

    # Dial a leg into a conference.
    # @return [VoiceML::Participant]
    def create_participant(conference_sid, from:, to:, **kwargs)
      kwargs = kwargs.merge(from: from, to: to)
      data = @transport.request(
        :post,
        path('Conferences', conference_sid, 'Participants'),
        form: form_params(CREATE_PARTICIPANT_FIELDS, kwargs)
      )
      Participant.from_hash(data)
    end

    # --- Recordings ---

    # @return [VoiceML::RecordingList]
    def list_recordings(conference_sid, **kwargs)
      RecordingList.from_hash(
        @transport.request(:get, path('Conferences', conference_sid, 'Recordings'),
                           params: form_params(LIST_CALL_RECORDINGS_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::Recording]
    def get_recording(conference_sid, recording_sid)
      Recording.from_hash(
        @transport.request(:get, path('Conferences', conference_sid, 'Recordings', recording_sid))
      )
    end

    # @return [VoiceML::Recording]
    def update_recording(conference_sid, recording_sid, **kwargs)
      data = @transport.request(
        :post,
        path('Conferences', conference_sid, 'Recordings', recording_sid),
        form: form_params(UPDATE_RECORDING_FIELDS, kwargs)
      )
      Recording.from_hash(data)
    end

    # @return [nil]
    def delete_recording(conference_sid, recording_sid)
      @transport.request(:delete, path('Conferences', conference_sid, 'Recordings', recording_sid))
      nil
    end
  end
end

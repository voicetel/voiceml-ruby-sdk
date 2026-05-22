# frozen_string_literal: true

require_relative 'base'
require_relative '../models/calls'
require_relative '../models/recordings'
require_relative '../models/streams'
require_relative '../models/siprec'
require_relative '../models/transcriptions'
require_relative '../models/diagnostics'

module VoiceML
  # Operations on `/Calls` and call-scoped sub-resources (Recordings, Streams, Siprec,
  # Transcriptions, Notifications, Events, UserDefinedMessages).
  #
  # All methods accept idiomatic snake_case keyword arguments — they're translated to
  # Twilio's PascalCase wire names internally.
  class CallsResource < BaseResource
    # Create-call form-field map (snake_case kwarg -> Twilio wire name).
    CREATE_FIELDS = {
      'To'                                    => :to,
      'From'                                  => :from,
      'Url'                                   => :url,
      'Method'                                => :method,
      'Twiml'                                 => :twiml,
      'ApplicationSid'                        => :application_sid,
      'FallbackUrl'                           => :fallback_url,
      'FallbackMethod'                        => :fallback_method,
      'StatusCallback'                        => :status_callback,
      'StatusCallbackMethod'                  => :status_callback_method,
      'StatusCallbackEvent'                   => :status_callback_event,
      'MachineDetection'                      => :machine_detection,
      'MachineDetectionTimeout'               => :machine_detection_timeout,
      'MachineDetectionSpeechThreshold'       => :machine_detection_speech_threshold,
      'MachineDetectionSpeechEndThreshold'    => :machine_detection_speech_end_threshold,
      'MachineDetectionSilenceTimeout'        => :machine_detection_silence_timeout,
      'AsyncAmdStatusCallback'                => :async_amd_status_callback,
      'AsyncAmdStatusCallbackMethod'          => :async_amd_status_callback_method,
      'Record'                                => :record,
      'RecordingStatusCallback'               => :recording_status_callback,
      'RecordingStatusCallbackMethod'         => :recording_status_callback_method,
      'RecordingStatusCallbackEvent'          => :recording_status_callback_event,
      'RecordingChannels'                     => :recording_channels,
      'RecordingTrack'                        => :recording_track,
      'Trim'                                  => :trim,
      'Timeout'                               => :timeout,
      'SendDigits'                            => :send_digits,
      'CallerId'                              => :caller_id,
      'CallReason'                            => :call_reason,
      'SipAuthUsername'                       => :sip_auth_username,
      'SipAuthPassword'                       => :sip_auth_password,
      'Byoc'                                  => :byoc,
      'AsyncAmd'                              => :async_amd,
      'CallToken'                             => :call_token
    }.freeze

    UPDATE_FIELDS = {
      'Status'                => :status,
      'Twiml'                 => :twiml,
      'Url'                   => :url,
      'Method'                => :method,
      'FallbackUrl'           => :fallback_url,
      'FallbackMethod'        => :fallback_method,
      'StatusCallback'        => :status_callback,
      'StatusCallbackMethod'  => :status_callback_method,
      'StatusCallbackEvent'   => :status_callback_event
    }.freeze

    LIST_FIELDS = {
      'To'             => :to,
      'From'           => :from,
      'Status'         => :status,
      'ParentCallSid'  => :parent_call_sid,
      'StartTime'      => :start_time,
      'StartTime<'     => :start_time_lt,
      'StartTime>'     => :start_time_gt,
      # Note: spec defines `StartTime>=` and `StartTime<=` as the literal query names.
      'StartTime>='    => :start_time_gte,
      'StartTime<='    => :start_time_lte,
      'EndTime'        => :end_time,
      'EndTime<'       => :end_time_lt,
      'EndTime>'       => :end_time_gt,
      'Page'           => :page,
      'PageSize'       => :page_size,
      'PageToken'      => :page_token
    }.freeze

    LIST_RECORDINGS_FIELDS = {
      'DateCreated'   => :date_created,
      'DateCreated<'  => :date_created_lt,
      'DateCreated>'  => :date_created_gt,
      'Page'          => :page,
      'PageSize'      => :page_size,
      'PageToken'     => :page_token
    }.freeze

    LIST_STUB_PAGE_FIELDS = {
      'Page'      => :page,
      'PageSize'  => :page_size,
      'PageToken' => :page_token
    }.freeze

    START_RECORDING_FIELDS = {
      'RecordingMaxDuration'           => :recording_max_duration,
      'RecordingChannels'              => :recording_channels,
      'PlayBeep'                       => :play_beep,
      'RecordingStatusCallback'        => :recording_status_callback,
      'RecordingStatusCallbackMethod'  => :recording_status_callback_method,
      'RecordingStatusCallbackEvent'   => :recording_status_callback_event
    }.freeze

    START_STREAM_FIELDS = {
      'Url'                  => :url,
      'Track'                => :track,
      'Name'                 => :name,
      'StatusCallback'       => :status_callback,
      'StatusCallbackMethod' => :status_callback_method
    }.freeze

    START_SIPREC_FIELDS = {
      'Name'                 => :name,
      'ConnectorName'        => :connector_name,
      'Track'                => :track,
      'StatusCallback'       => :status_callback,
      'StatusCallbackMethod' => :status_callback_method
    }.freeze

    START_TRANSCRIPTION_FIELDS = {
      'Name'                 => :name,
      'Track'                => :track,
      'LanguageCode'         => :language_code,
      'TranscriptionEngine'  => :transcription_engine,
      'ProfanityFilter'      => :profanity_filter,
      'PartialResults'       => :partial_results,
      'Hints'                => :hints,
      'StatusCallback'       => :status_callback,
      'StatusCallbackMethod' => :status_callback_method,
      'StatusCallbackEvents' => :status_callback_events
    }.freeze

    # @return [VoiceML::CallList]
    def list(**kwargs)
      data = @transport.request(:get, path('Calls'), params: form_params(LIST_FIELDS, kwargs))
      CallList.from_hash(data)
    end

    # Create a new outbound call.
    #
    # Pass at most one of `url:` / `twiml:` / `application_sid:` (Twiml wins if multiple are set
    # — Twilio's documented precedence).
    #
    # @return [VoiceML::Call]
    def create(**kwargs)
      data = @transport.request(:post, path('Calls'), form: form_params(CREATE_FIELDS, kwargs))
      Call.from_hash(data)
    end

    # @return [VoiceML::Call]
    def get(call_sid)
      data = @transport.request(:get, path('Calls', call_sid))
      Call.from_hash(data)
    end

    # @return [VoiceML::Call]
    def update(call_sid, **kwargs)
      data = @transport.request(:post, path('Calls', call_sid),
                                form: form_params(UPDATE_FIELDS, kwargs))
      Call.from_hash(data)
    end

    # @return [nil]
    def delete(call_sid)
      @transport.request(:delete, path('Calls', call_sid))
      nil
    end

    # --- Call-scoped Recordings ---

    # @return [VoiceML::RecordingList]
    def list_recordings(call_sid, **kwargs)
      RecordingList.from_hash(
        @transport.request(:get, path('Calls', call_sid, 'Recordings'),
                           params: form_params(LIST_RECORDINGS_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::Recording]
    def start_recording(call_sid, **kwargs)
      data = @transport.request(:post, path('Calls', call_sid, 'Recordings'),
                                form: form_params(START_RECORDING_FIELDS, kwargs))
      Recording.from_hash(data)
    end

    # @return [VoiceML::Recording]
    def get_recording(call_sid, recording_sid)
      Recording.from_hash(
        @transport.request(:get, path('Calls', call_sid, 'Recordings', recording_sid))
      )
    end

    # @param status [String] one of "in-progress", "paused", "stopped".
    # @return [VoiceML::Recording]
    def update_recording(call_sid, recording_sid, status:)
      data = @transport.request(:post, path('Calls', call_sid, 'Recordings', recording_sid),
                                form: { 'Status' => status })
      Recording.from_hash(data)
    end

    # @return [nil]
    def delete_recording(call_sid, recording_sid)
      @transport.request(:delete, path('Calls', call_sid, 'Recordings', recording_sid))
      nil
    end

    # --- Streams ---

    # @return [VoiceML::StreamList]
    def list_streams(call_sid)
      StreamList.from_hash(@transport.request(:get, path('Calls', call_sid, 'Streams')))
    end

    # @return [VoiceML::Stream]
    def start_stream(call_sid, **kwargs)
      data = @transport.request(:post, path('Calls', call_sid, 'Streams'),
                                form: form_params(START_STREAM_FIELDS, kwargs))
      Stream.from_hash(data)
    end

    # @return [VoiceML::Stream]
    def get_stream(call_sid, stream_sid)
      Stream.from_hash(@transport.request(:get, path('Calls', call_sid, 'Streams', stream_sid)))
    end

    # @return [VoiceML::Stream]
    def stop_stream(call_sid, stream_sid)
      data = @transport.request(:post, path('Calls', call_sid, 'Streams', stream_sid),
                                form: { 'Status' => 'stopped' })
      Stream.from_hash(data)
    end

    # --- SIPREC ---

    # @return [VoiceML::SiprecList]
    def list_siprec(call_sid)
      SiprecList.from_hash(@transport.request(:get, path('Calls', call_sid, 'Siprec')))
    end

    # @return [VoiceML::SiprecSession]
    def start_siprec(call_sid, **kwargs)
      data = @transport.request(:post, path('Calls', call_sid, 'Siprec'),
                                form: form_params(START_SIPREC_FIELDS, kwargs))
      SiprecSession.from_hash(data)
    end

    # @return [VoiceML::SiprecSession]
    def get_siprec(call_sid, siprec_sid)
      SiprecSession.from_hash(
        @transport.request(:get, path('Calls', call_sid, 'Siprec', siprec_sid))
      )
    end

    # @return [VoiceML::SiprecSession]
    def stop_siprec(call_sid, siprec_sid)
      data = @transport.request(:post, path('Calls', call_sid, 'Siprec', siprec_sid),
                                form: { 'Status' => 'stopped' })
      SiprecSession.from_hash(data)
    end

    # --- Transcriptions ---

    # @return [VoiceML::TranscriptionList]
    def list_transcriptions(call_sid)
      TranscriptionList.from_hash(
        @transport.request(:get, path('Calls', call_sid, 'Transcriptions'))
      )
    end

    # @return [VoiceML::CallTranscription]
    def start_transcription(call_sid, **kwargs)
      data = @transport.request(:post, path('Calls', call_sid, 'Transcriptions'),
                                form: form_params(START_TRANSCRIPTION_FIELDS, kwargs))
      CallTranscription.from_hash(data)
    end

    # @return [VoiceML::CallTranscription]
    def get_transcription(call_sid, transcription_sid)
      CallTranscription.from_hash(
        @transport.request(:get, path('Calls', call_sid, 'Transcriptions', transcription_sid))
      )
    end

    # @return [VoiceML::CallTranscription]
    def stop_transcription(call_sid, transcription_sid)
      data = @transport.request(:post,
                                path('Calls', call_sid, 'Transcriptions', transcription_sid),
                                form: { 'Status' => 'stopped' })
      CallTranscription.from_hash(data)
    end

    # --- Notifications / Events (compat stubs) ---

    # @return [VoiceML::NotificationsList]
    def list_notifications(call_sid, **kwargs)
      NotificationsList.from_hash(
        @transport.request(:get, path('Calls', call_sid, 'Notifications'),
                           params: form_params(LIST_STUB_PAGE_FIELDS, kwargs))
      )
    end

    # @return [VoiceML::EventsList]
    def list_events(call_sid, **kwargs)
      EventsList.from_hash(
        @transport.request(:get, path('Calls', call_sid, 'Events'),
                           params: form_params(LIST_STUB_PAGE_FIELDS, kwargs))
      )
    end

    # `POST /Calls/{sid}/UserDefinedMessages` — always raises `NotImplementedAPIError`.
    # Mounted on the server only as a 501 stub. The SDK forwards the call so callers get a
    # clean exception rather than discovering at runtime that the endpoint doesn't exist.
    def send_user_defined_message(call_sid, payload = nil)
      @transport.request(:post, path('Calls', call_sid, 'UserDefinedMessages'),
                         form: payload)
    end
  end
end

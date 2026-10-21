# frozen_string_literal: true

require 'spec_helper'

# Wire-shape tests for the spec 0.9.4 request fields the server already honored
# but the SDK lacked:
#
#   * Calls create — TimeLimit
#   * Conferences participants create — ConferenceStatusCallback{,Method,Event}
#   * Conferences recordings update — PauseBehavior (mirrors the call-scoped update)
#   * Applications create/update — SmsUrl/SmsMethod/SmsFallbackUrl/SmsFallbackMethod
#     and PublicApplicationConnectEnabled
#   * Messages create — SendAt + ScheduleType
#   * Calls transcriptions start — StatusCallback renamed to StatusCallbackUrl
#     (the old wire name was never read by the server), plus SpeechModel,
#     EnableAutomaticPunctuation and IntelligenceService
RSpec.describe 'VoiceML v0.9.5 — spec 0.9.4 request fields' do
  let(:account_sid) { 'AC' + ('f' * 32) }
  let(:api_key)     { 'secret-key-1234' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key, base_url: base_url) }
  let(:base_url)    { 'https://voiceml.example.test' }

  def api_path(*parts)
    "/2010-04-01/Accounts/#{account_sid}/#{parts.join('/')}.json"
  end

  # ===========================================================================
  # Calls create — TimeLimit
  # ===========================================================================
  describe '#calls.create' do
    it 'sends time_limit as the integer-to-string TimeLimit form field' do
      call_sid = 'CA' + ('a' * 32)
      stub = stub_request(:post, "#{base_url}#{api_path('Calls')}")
             .with(body: hash_including(
               'To' => '+14155550100', 'From' => '+14155550101',
               'Url' => 'https://example.com/twiml', 'TimeLimit' => '3600'
             ))
             .to_return(status: 201,
                        body: { sid: call_sid, account_sid: account_sid,
                                api_version: '2010-04-01', to: '+14155550100',
                                from: '+14155550101', status: 'queued',
                                direction: 'outbound-api',
                                date_created: '2026-10-21T10:00:00Z',
                                date_updated: '2026-10-21T10:00:00Z',
                                uri: api_path('Calls', call_sid) }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      call = client.calls.create(
        to: '+14155550100', from: '+14155550101',
        url: 'https://example.com/twiml', time_limit: 3600
      )

      expect(stub).to have_been_requested
      expect(call.sid).to eq(call_sid)
    end
  end

  # ===========================================================================
  # Conferences participants create — ConferenceStatusCallback*
  # ===========================================================================
  describe '#conferences.create_participant' do
    it 'sends the conference-level status callback triple as PascalCase form keys' do
      conf_sid = 'CF' + ('f' * 32)
      stub = stub_request(:post, "#{base_url}#{api_path('Conferences', conf_sid, 'Participants')}")
             .with(body: hash_including(
               'From' => '+14155550101', 'To' => '+14155550100',
               'ConferenceStatusCallback' => 'https://example.com/conf-events',
               'ConferenceStatusCallbackMethod' => 'POST',
               'ConferenceStatusCallbackEvent' => 'start,end'
             ))
             .to_return(status: 201,
                        body: { call_sid: 'CA' + ('f' * 32), conference_sid: conf_sid,
                                account_sid: account_sid, status: 'queued',
                                api_version: '2010-04-01', uri: '/x' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      participant = client.conferences.create_participant(
        conf_sid,
        from: '+14155550101', to: '+14155550100',
        conference_status_callback: 'https://example.com/conf-events',
        conference_status_callback_method: 'POST',
        conference_status_callback_event: 'start,end'
      )

      expect(stub).to have_been_requested
      expect(participant).to be_a(VoiceML::Participant)
    end
  end

  # ===========================================================================
  # Conferences recordings update — PauseBehavior
  # ===========================================================================
  describe '#conferences.update_recording' do
    it 'sends Status and PauseBehavior like the call-scoped recording update' do
      conf_sid = 'CF' + ('e' * 32)
      rec_sid  = 'RE' + ('e' * 32)
      stub = stub_request(:post, "#{base_url}#{api_path('Conferences', conf_sid, 'Recordings', rec_sid)}")
             .with(body: hash_including('Status' => 'paused', 'PauseBehavior' => 'skip'))
             .to_return(status: 200,
                        body: { sid: rec_sid, account_sid: account_sid,
                                conference_sid: conf_sid, status: 'paused',
                                api_version: '2010-04-01', uri: '/x' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      recording = client.conferences.update_recording(conf_sid, rec_sid,
                                                      status: 'paused', pause_behavior: 'skip')

      expect(stub).to have_been_requested
      expect(recording).to be_a(VoiceML::Recording)
      expect(recording.status).to eq('paused')
    end
  end

  # ===========================================================================
  # Applications create + update — SMS handler set + PublicApplicationConnectEnabled
  # ===========================================================================
  describe '#applications.create' do
    it 'sends the Sms* fields and PublicApplicationConnectEnabled as form keys' do
      app_sid = 'AP' + ('a' * 32)
      stub = stub_request(:post, "#{base_url}#{api_path('Applications')}")
             .with(body: hash_including(
               'FriendlyName' => 'alerts',
               'SmsUrl' => 'https://example.com/sms',
               'SmsMethod' => 'POST',
               'SmsFallbackUrl' => 'https://example.com/sms-fallback',
               'SmsFallbackMethod' => 'GET',
               'PublicApplicationConnectEnabled' => 'true'
             ))
             .to_return(status: 201,
                        body: { sid: app_sid, account_sid: account_sid,
                                friendly_name: 'alerts', api_version: '2010-04-01',
                                sms_url: 'https://example.com/sms', sms_method: 'POST',
                                date_created: '2026-10-21T10:00:00Z',
                                date_updated: '2026-10-21T10:00:00Z',
                                uri: api_path('Applications', app_sid) }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      app = client.applications.create(
        friendly_name: 'alerts',
        sms_url: 'https://example.com/sms',
        sms_method: 'POST',
        sms_fallback_url: 'https://example.com/sms-fallback',
        sms_fallback_method: 'GET',
        public_application_connect_enabled: true
      )

      expect(stub).to have_been_requested
      expect(app).to be_a(VoiceML::Application)
      expect(app.sms_url).to eq('https://example.com/sms')
    end
  end

  describe '#applications.update' do
    it 'sends the same Sms* set on the sid-scoped POST' do
      app_sid = 'AP' + ('b' * 32)
      stub = stub_request(:post, "#{base_url}#{api_path('Applications', app_sid)}")
             .with(body: hash_including(
               'SmsUrl' => 'https://example.com/sms-v2',
               'SmsMethod' => 'GET',
               'SmsFallbackUrl' => 'https://example.com/sms-fallback-v2',
               'SmsFallbackMethod' => 'POST',
               'PublicApplicationConnectEnabled' => 'false'
             ))
             .to_return(status: 200,
                        body: { sid: app_sid, account_sid: account_sid,
                                friendly_name: 'alerts', api_version: '2010-04-01',
                                sms_url: 'https://example.com/sms-v2', sms_method: 'GET',
                                date_created: '2026-10-21T10:00:00Z',
                                date_updated: '2026-10-21T11:00:00Z',
                                uri: api_path('Applications', app_sid) }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      app = client.applications.update(
        app_sid,
        sms_url: 'https://example.com/sms-v2',
        sms_method: 'GET',
        sms_fallback_url: 'https://example.com/sms-fallback-v2',
        sms_fallback_method: 'POST',
        public_application_connect_enabled: false
      )

      expect(stub).to have_been_requested
      expect(app.sid).to eq(app_sid)
    end
  end

  # ===========================================================================
  # Messages create — SendAt + ScheduleType
  # ===========================================================================
  describe '#messages.create' do
    it 'serialises send_at (Time) as ISO 8601 UTC and schedule_type as "fixed"' do
      msg_sid = 'SM' + ('a' * 32)
      stub = stub_request(:post, "#{base_url}#{api_path('Messages')}")
             .with(body: hash_including(
               'To' => '+14155550100', 'Body' => 'hello',
               'SendAt' => '2026-10-22T14:30:00Z', 'ScheduleType' => 'fixed'
             ))
             .to_return(status: 201,
                        body: { sid: msg_sid, account_sid: account_sid,
                                api_version: '2010-04-01', to: '+14155550100',
                                from: '+14155550101', body: 'hello', status: 'scheduled',
                                num_segments: '1', num_media: '0', direction: 'outbound-api',
                                date_created: '2026-10-21T10:00:00Z',
                                date_updated: '2026-10-21T10:00:00Z', uri: '/x' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      msg = client.messages.create(
        to: '+14155550100', body: 'hello',
        send_at: Time.utc(2026, 10, 22, 14, 30, 0), schedule_type: 'fixed'
      )

      expect(stub).to have_been_requested
      expect(msg).to be_a(VoiceML::Message)
      expect(msg.status).to eq('scheduled')
    end
  end

  # ===========================================================================
  # Calls transcriptions start — StatusCallbackUrl rename + engine fields
  # ===========================================================================
  describe '#calls.start_transcription' do
    let(:call_sid) { 'CA' + ('c' * 32) }
    let(:transcription_body) do
      { sid: 'GT' + ('c' * 32), account_sid: account_sid, call_sid: call_sid,
        status: 'in-progress', api_version: '2010-04-01', uri: '/x' }.to_json
    end

    it 'sends StatusCallbackUrl plus SpeechModel, EnableAutomaticPunctuation and IntelligenceService' do
      stub = stub_request(:post, "#{base_url}#{api_path('Calls', call_sid, 'Transcriptions')}")
             .with(body: hash_including(
               'Track' => 'both_tracks',
               'StatusCallbackUrl' => 'https://example.com/transcription-events',
               'StatusCallbackMethod' => 'POST',
               'StatusCallbackEvents' => 'completed',
               'SpeechModel' => 'telephony',
               'EnableAutomaticPunctuation' => 'true',
               'IntelligenceService' => 'default'
             ))
             .to_return(status: 201, body: transcription_body,
                        headers: { 'Content-Type' => 'application/json' })

      transcription = client.calls.start_transcription(
        call_sid,
        track: 'both_tracks',
        status_callback_url: 'https://example.com/transcription-events',
        status_callback_method: 'POST',
        status_callback_events: 'completed',
        speech_model: 'telephony',
        enable_automatic_punctuation: true,
        intelligence_service: 'default'
      )

      expect(stub).to have_been_requested
      expect(transcription).to be_a(VoiceML::CallTranscription)
      expect(transcription.status).to eq('in-progress')
    end

    it 'rejects the renamed-away status_callback kwarg' do
      expect do
        client.calls.start_transcription(call_sid, status_callback: 'https://example.com/old')
      end.to raise_error(ArgumentError, /status_callback/)
    end
  end
end

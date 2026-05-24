# frozen_string_literal: true

require 'spec_helper'

# v0.6.3 spec-sync changes:
#   * Participant: coaching, call_sid_to_coach, queue_time; status complete/failed
#   * Recording: error_code (nullable), StartConferenceRecordingAPI source
#   * Queue create/update: max_size minimum 0 (unlimited)
#   * LIST filter params on resource methods (Twilio wire names)
RSpec.describe 'voiceml-ruby v0.6.3' do
  let(:conf_sid) { 'CF00000000000000000000000000000001' }
  let(:rec_sid) { 'RE00000000000000000000000000000001' }

  describe 'Participant coaching fields' do
    let(:base_attrs) do
      {
        'call_sid' => 'CA00000000000000000000000000000001',
        'conference_sid' => conf_sid,
        'account_sid' => ACCOUNT_SID,
        'muted' => false,
        'hold' => false,
        'coaching' => true,
        'call_sid_to_coach' => 'CA00000000000000000000000000000002',
        'queue_time' => '12',
        'start_conference_on_enter' => true,
        'end_conference_on_exit' => false,
        'status' => 'complete',
        'api_version' => '2010-04-01',
        'uri' => "/2010-04-01/Accounts/#{ACCOUNT_SID}/Conferences/#{conf_sid}/Participants/CA1.json"
      }
    end

    it 'populates coaching fields from the response body' do
      participant = VoiceML::Participant.from_hash(base_attrs)

      expect(participant.coaching).to be(true)
      expect(participant.call_sid_to_coach).to eq('CA00000000000000000000000000000002')
      expect(participant.queue_time).to eq('12')
      expect(participant.status).to eq('complete')
    end

    it 'accepts failed status' do
      participant = VoiceML::Participant.from_hash(base_attrs.merge('status' => 'failed'))
      expect(participant.status).to eq('failed')
    end
  end

  describe 'Recording#error_code' do
    let(:base_attrs) do
      {
        'sid' => rec_sid,
        'account_sid' => ACCOUNT_SID,
        'call_sid' => 'CA00000000000000000000000000000001',
        'status' => 'completed',
        'source' => 'StartConferenceRecordingAPI',
        'api_version' => '2010-04-01',
        'uri' => "/2010-04-01/Accounts/#{ACCOUNT_SID}/Recordings/#{rec_sid}.json"
      }
    end

    it 'populates error_code when present' do
      recording = VoiceML::Recording.from_hash(base_attrs.merge('error_code' => 13_227))

      expect(recording.source).to eq('StartConferenceRecordingAPI')
      expect(recording.error_code).to eq(13_227)
    end

    it 'leaves error_code nil when absent' do
      recording = VoiceML::Recording.from_hash(base_attrs)
      expect(recording.error_code).to be_nil
    end
  end

  describe 'Calls.list filter params' do
    it 'sends StartTime/EndTime Twilio wire names' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY)

      stub_request(:get, %r{#{Regexp.escape(base_url)}#{Regexp.escape(accounts_path('Calls'))}})
        .with(query: hash_including(
          'StartTime' => '2025-06-01',
          'StartTime<' => '2025-06-15',
          'StartTime>' => '2025-05-01',
          'EndTime' => '2025-06-30',
          'EndTime<' => '2025-07-01',
          'EndTime>' => '2025-06-01'
        ))
        .to_return(
          status: 200,
          body: { calls: [], page: 0, page_size: 50 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      client.calls.list(
        start_time: '2025-06-01',
        start_time_lt: '2025-06-15',
        start_time_gt: '2025-05-01',
        end_time: '2025-06-30',
        end_time_lt: '2025-07-01',
        end_time_gt: '2025-06-01'
      )
    end
  end

  describe 'Recordings.list filter params' do
    it 'sends DateCreated filters and call_sid' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY)

      stub_request(:get, "#{base_url}#{accounts_path('Recordings')}")
        .with(query: hash_including(
          'DateCreated' => '2025-06-01',
          'DateCreated<' => '2025-06-15',
          'DateCreated>' => '2025-05-01',
          'CallSid' => 'CA00000000000000000000000000000001'
        ))
        .to_return(
          status: 200,
          body: { recordings: [], page: 0, page_size: 50, total: 0 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      client.recordings.list(
        date_created: '2025-06-01',
        date_created_lt: '2025-06-15',
        date_created_gt: '2025-05-01',
        call_sid: 'CA00000000000000000000000000000001'
      )
    end
  end

  describe 'Queues.create max_size 0' do
    it 'allows unlimited queue size on the wire' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY)

      stub_request(:post, "#{base_url}#{accounts_path('Queues')}")
        .with(body: hash_including('MaxSize' => '0'))
        .to_return(
          status: 201,
          body: {
            sid: 'QU00000000000000000000000000000001',
            account_sid: ACCOUNT_SID,
            friendly_name: 'support',
            current_size: 0,
            max_size: 0,
            average_wait_time: 0,
            date_created: '2026-05-21T10:00:00Z',
            date_updated: '2026-05-21T10:00:00Z',
            uri: '/x'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      queue = client.queues.create(friendly_name: 'support', max_size: 0)
      expect(queue.max_size).to eq(0)
    end
  end

  describe 'VoiceML::VERSION' do
    it 'reports 0.6.6' do
      expect(VoiceML::VERSION).to eq('0.6.6')
    end
  end
end

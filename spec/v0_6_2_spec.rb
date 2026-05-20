# frozen_string_literal: true

require 'spec_helper'

# v0.6.2 spec-sync changes:
#   * D5: Recording.media_url surfaced verbatim from the response body
#   * D6: IncomingPhoneNumber.type surfaced verbatim from the response body
RSpec.describe 'voiceml-ruby v0.6.2' do
  describe 'Recording#media_url (D5)' do
    let(:rec_sid) { 'RE00000000000000000000000000000001' }
    let(:base_attrs) do
      {
        'sid' => rec_sid,
        'account_sid' => ACCOUNT_SID,
        'call_sid' => 'CA00000000000000000000000000000001',
        'status' => 'completed',
        'duration' => '12',
        'api_version' => '2010-04-01',
        'uri' => "/2010-04-01/Accounts/#{ACCOUNT_SID}/Recordings/#{rec_sid}.json",
        'date_created' => '2026-05-20T10:00:00Z',
        'date_updated' => '2026-05-20T10:00:00Z'
      }
    end

    it 'populates media_url when the response body carries it' do
      url = "https://voiceml.voicetel.com/2010-04-01/Accounts/#{ACCOUNT_SID}/Recordings/#{rec_sid}.wav"
      recording = VoiceML::Recording.from_hash(base_attrs.merge('media_url' => url))

      expect(recording).to be_a(VoiceML::Recording)
      expect(recording.media_url).to eq(url)
      expect(recording.sid).to eq(rec_sid)
    end

    it 'leaves media_url nil when the response body omits it' do
      recording = VoiceML::Recording.from_hash(base_attrs)

      expect(recording.media_url).to be_nil
      expect(recording.sid).to eq(rec_sid)
    end

    it 'flows media_url through the recordings.list envelope' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY)
      url = "https://voiceml.voicetel.com/2010-04-01/Accounts/#{ACCOUNT_SID}/Recordings/#{rec_sid}.wav"

      stub_request(:get, "#{base_url}#{accounts_path('Recordings')}")
        .to_return(
          status: 200,
          body: {
            recordings: [base_attrs.merge('media_url' => url)],
            page: 0, page_size: 50, total: 1
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.recordings.list
      expect(result.recordings.length).to eq(1)
      expect(result.recordings.first.media_url).to eq(url)
    end
  end

  describe 'IncomingPhoneNumber#type (D6)' do
    let(:pn_sid) { 'PN0123456789abcdef0123456789abcdef' }
    let(:base_attrs) do
      {
        'sid' => pn_sid,
        'account_sid' => ACCOUNT_SID,
        'phone_number' => '+18005551234',
        'friendly_name' => '',
        'api_version' => '2010-04-01',
        'uri' => "/2010-04-01/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers/#{pn_sid}.json",
        'capabilities' => { 'voice' => true, 'sms' => false, 'mms' => false, 'fax' => false },
        'date_created' => '2026-05-20T10:00:00Z',
        'date_updated' => '2026-05-20T10:00:00Z'
      }
    end

    it 'populates type when the response body carries it' do
      number = VoiceML::IncomingPhoneNumber.from_hash(base_attrs.merge('type' => 'local'))

      expect(number).to be_a(VoiceML::IncomingPhoneNumber)
      expect(number.type).to eq('local')
      expect(number.sid).to eq(pn_sid)
    end

    it 'leaves type nil when the response body omits it' do
      number = VoiceML::IncomingPhoneNumber.from_hash(base_attrs)

      expect(number.type).to be_nil
    end

    it 'flows type through an incoming_phone_numbers.get response' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY)

      stub_request(:get, "#{base_url}#{accounts_path('IncomingPhoneNumbers', pn_sid)}")
        .to_return(
          status: 200,
          body: base_attrs.merge('type' => 'toll-free').to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      number = client.incoming_phone_numbers.get(pn_sid)
      expect(number.type).to eq('toll-free')
    end
  end

  describe 'VoiceML::VERSION' do
    it 'reports 0.6.2' do
      expect(VoiceML::VERSION).to eq('0.6.2')
    end
  end
end

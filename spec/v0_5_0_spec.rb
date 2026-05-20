# frozen_string_literal: true

require 'spec_helper'

# v0.5.0 cross-cutting changes:
#   * `.json` URL suffix on every account-scoped REST path
#   * `auth_token:` kwarg alias for `api_key:`
#   * `more_info` accessor on `ApiError`
RSpec.describe 'voiceml-ruby v0.5.0' do
  describe 'auth_token alias' do
    it 'accepts api_key: by itself' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY)
      expect(client.account_sid).to eq(ACCOUNT_SID)
    end

    it 'accepts auth_token: by itself' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, auth_token: API_KEY)
      expect(client.account_sid).to eq(ACCOUNT_SID)
    end

    it 'uses auth_token: as the basic-auth password when only it is set' do
      client = VoiceML::Client.new(account_sid: ACCOUNT_SID, auth_token: 'twilio-shape-token')

      stub = stub_request(:get, "#{base_url}#{accounts_path('Conferences')}")
             .with(headers: {
                     'Authorization' =>
                       "Basic #{Base64.strict_encode64("#{ACCOUNT_SID}:twilio-shape-token")}"
                   })
             .to_return(status: 200, body: { conferences: [] }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.conferences.list
      expect(stub).to have_been_requested
    end

    it 'raises ArgumentError when both kwargs are passed' do
      expect do
        VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: 'a', auth_token: 'b')
      end.to raise_error(ArgumentError, /api_key.*auth_token/)
    end

    it 'still rejects empty credentials via ConfigurationError' do
      expect do
        VoiceML::Client.new(account_sid: ACCOUNT_SID)
      end.to raise_error(VoiceML::ConfigurationError, /api_key/)
    end
  end

  describe '.json URL suffix on account-scoped paths' do
    let(:client) { VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY) }

    it 'appends .json to /Calls/{sid}' do
      call_sid = 'CA00000000000000000000000000000010'
      stub = stub_request(:get, "#{base_url}/2010-04-01/Accounts/#{ACCOUNT_SID}/Calls/#{call_sid}.json")
             .to_return(status: 200,
                        body: {
                          sid: call_sid, account_sid: ACCOUNT_SID, api_version: '2010-04-01',
                          status: 'completed', direction: 'outbound-api',
                          date_created: '2026-05-20T10:00:00Z',
                          date_updated: '2026-05-20T10:00:00Z',
                          uri: "/2010-04-01/Accounts/#{ACCOUNT_SID}/Calls/#{call_sid}.json"
                        }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.calls.get(call_sid)
      expect(stub).to have_been_requested
    end

    it 'appends .json to /Queues' do
      stub = stub_request(:get, "#{base_url}/2010-04-01/Accounts/#{ACCOUNT_SID}/Queues.json")
             .to_return(status: 200, body: { queues: [] }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.queues.list
      expect(stub).to have_been_requested
    end

    it 'appends .json to /Applications' do
      stub = stub_request(:get, "#{base_url}/2010-04-01/Accounts/#{ACCOUNT_SID}/Applications.json")
             .to_return(status: 200, body: { applications: [] }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.applications.list
      expect(stub).to have_been_requested
    end

    it 'leaves the .wav audio fetch unchanged (no .json.wav)' do
      rec_sid = 'RE00000000000000000000000000000001'
      stub = stub_request(:get, "#{base_url}/2010-04-01/Accounts/#{ACCOUNT_SID}/Recordings/#{rec_sid}.wav")
             .to_return(status: 200, body: 'RIFF....fakewav',
                        headers: { 'Content-Type' => 'audio/wav' })

      client.recordings.get_audio(rec_sid)
      expect(stub).to have_been_requested
    end
  end

  describe 'ApiError#more_info' do
    let(:client) { VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY) }

    it 'populates more_info from the response body when present' do
      call_sid = 'CA00000000000000000000000000000404'
      stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
        .to_return(
          status: 404,
          body: {
            code: 20_404,
            message: 'Call not found',
            more_info: 'https://www.twilio.com/docs/errors/20404',
            status: 404
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.calls.get(call_sid) }.to raise_error(VoiceML::NotFoundError) do |err|
        expect(err.more_info).to eq('https://www.twilio.com/docs/errors/20404')
        expect(err.code).to eq(20_404)
        expect(err.status_code).to eq(404)
      end
    end

    it 'leaves more_info nil when the body omits it' do
      call_sid = 'CA00000000000000000000000000000405'
      stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
        .to_return(status: 404,
                   body: { code: 20_404, message: 'gone' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.calls.get(call_sid) }.to raise_error(VoiceML::NotFoundError) do |err|
        expect(err.more_info).to be_nil
      end
    end
  end
end

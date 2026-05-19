# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VoiceML::Client do
  let(:client) { VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY) }

  describe 'construction' do
    it 'requires account_sid' do
      expect do
        VoiceML::Client.new(account_sid: '', api_key: 'k')
      end.to raise_error(VoiceML::ConfigurationError, /account_sid/)
    end

    it 'requires api_key' do
      expect do
        VoiceML::Client.new(account_sid: 'AC1', api_key: '')
      end.to raise_error(VoiceML::ConfigurationError, /api_key/)
    end

    it 'rejects negative max_retries' do
      expect do
        VoiceML::Client.new(account_sid: 'AC1', api_key: 'k', max_retries: -1)
      end.to raise_error(VoiceML::ConfigurationError, /max_retries/)
    end

    it 'defaults to the production base URL' do
      expect(client.base_url).to eq('https://voiceml.voicetel.com')
    end

    it 'exposes account_sid' do
      expect(client.account_sid).to eq(ACCOUNT_SID)
    end
  end

  describe 'calls.create' do
    let(:call_sid) { 'CA00000000000000000000000000000001' }
    let(:response_body) do
      {
        sid: call_sid,
        account_sid: ACCOUNT_SID,
        api_version: '2010-04-01',
        to: '+18005551234',
        from: '+18005550000',
        status: 'queued',
        direction: 'outbound-api',
        date_created: '2026-05-19T10:00:00Z',
        date_updated: '2026-05-19T10:00:00Z',
        uri: "/2010-04-01/Accounts/#{ACCOUNT_SID}/Calls/#{call_sid}.json"
      }.to_json
    end

    it 'sends a form-encoded POST with Basic auth and translated field names' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('Calls')}")
             .with(
               headers: {
                 'Authorization' => basic_auth_header,
                 'Accept' => 'application/json',
                 'Content-Type' => 'application/x-www-form-urlencoded'
               },
               body: hash_including(
                 'To' => '+18005551234',
                 'From' => '+18005550000',
                 'Url' => 'https://example.com/twiml',
                 'MachineDetection' => 'DetectMessageEnd'
               )
             )
             .to_return(status: 201, body: response_body,
                        headers: { 'Content-Type' => 'application/json' })

      call = client.calls.create(
        to: '+18005551234',
        from: '+18005550000',
        url: 'https://example.com/twiml',
        machine_detection: 'DetectMessageEnd'
      )

      expect(stub).to have_been_requested
      expect(call.sid).to eq(call_sid)
      expect(call.status).to eq('queued')
      expect(call.direction).to eq('outbound-api')
    end
  end

  describe 'calls.list' do
    it 'serialises StartTime>= and StartTime<= as literal query names' do
      stub = stub_request(:get, "#{base_url}#{accounts_path('Calls')}")
             .with(query: {
                     'StartTime>=' => '2026-05-01T00:00:00Z',
                     'StartTime<=' => '2026-05-19T00:00:00Z',
                     'PageSize' => '50'
                   })
             .to_return(status: 200, body: { calls: [], page: 0, page_size: 50 }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      result = client.calls.list(
        start_time_gte: '2026-05-01T00:00:00Z',
        start_time_lte: '2026-05-19T00:00:00Z',
        page_size: 50
      )

      expect(stub).to have_been_requested
      expect(result).to be_a(VoiceML::CallList)
      expect(result.calls).to eq([])
      expect(result.page_size).to eq(50)
    end
  end

  describe 'boolean encoding' do
    let(:conference_sid) { 'CF00000000000000000000000000000001' }
    let(:participant_call_sid) { 'CA00000000000000000000000000000002' }

    it 'encodes muted: true and hold: false as the strings "true" and "false"' do
      stub = stub_request(
        :post,
        "#{base_url}#{accounts_path('Conferences', conference_sid, 'Participants', participant_call_sid)}"
      ).with(body: 'Muted=true&Hold=false')
       .to_return(status: 200, body: {
         call_sid: participant_call_sid,
         conference_sid: conference_sid,
         account_sid: ACCOUNT_SID,
         muted: true, hold: false,
         start_conference_on_enter: true,
         end_conference_on_exit: false,
         status: 'connected',
         api_version: '2010-04-01',
         uri: 'placeholder'
       }.to_json,
                  headers: { 'Content-Type' => 'application/json' })

      result = client.conferences.update_participant(
        conference_sid, participant_call_sid,
        muted: true, hold: false
      )

      expect(stub).to have_been_requested
      expect(result.muted).to be(true)
      expect(result.hold).to be(false)
    end
  end

  describe 'error mapping' do
    let(:call_sid) { 'CA00000000000000000000000000000099' }

    {
      401 => VoiceML::AuthenticationError,
      404 => VoiceML::NotFoundError,
      409 => VoiceML::ConflictError,
      429 => VoiceML::RateLimitError,
      501 => VoiceML::NotImplementedAPIError
    }.each do |status, klass|
      it "raises #{klass} on HTTP #{status}" do
        stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
          .to_return(status: status,
                     body: { code: 20_404, message: "HTTP #{status} from server" }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        expect { client.calls.get(call_sid) }.to raise_error(klass) do |err|
          expect(err.status_code).to eq(status)
          expect(err.code).to eq(20_404)
        end
      end
    end
  end

  describe 'retries' do
    let(:client) do
      VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY, max_retries: 1)
    end

    it 'retries a 503 once then returns the 200 body' do
      call_sid = 'CA00000000000000000000000000000077'
      stub = stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
             .to_return(
               { status: 503, body: { code: 20_500, message: 'temporary' }.to_json,
                 headers: { 'Content-Type' => 'application/json' } },
               { status: 200,
                 body: {
                   sid: call_sid,
                   account_sid: ACCOUNT_SID,
                   api_version: '2010-04-01',
                   status: 'completed',
                   direction: 'outbound-api',
                   date_created: '2026-05-19T10:00:00Z',
                   date_updated: '2026-05-19T10:00:00Z',
                   uri: "/2010-04-01/Accounts/#{ACCOUNT_SID}/Calls/#{call_sid}.json"
                 }.to_json,
                 headers: { 'Content-Type' => 'application/json' } }
             )

      call = nil
      # Stub out Kernel#sleep to keep the test fast.
      allow_any_instance_of(VoiceML::Transport).to receive(:sleep)
      call = client.calls.get(call_sid)

      expect(stub).to have_been_requested.times(2)
      expect(call.sid).to eq(call_sid)
      expect(call.status).to eq('completed')
    end
  end
end

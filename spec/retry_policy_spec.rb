# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'retry policy' do
  let(:call_sid) { 'CA00000000000000000000000000000041' }
  let(:message_sid) { 'SM00000000000000000000000000000041' }

  def client(max_retries: 2)
    @client ||= {}
    @client[max_retries] ||= begin
      c = VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY, max_retries: max_retries)
      allow(c.instance_variable_get(:@transport)).to receive(:sleep_for)
      c
    end
  end

  def stub_sequence(url, responses)
    stub_request(:post, url).to_return(*responses)
  end

  describe 'POST is never duplicated' do
    it 'does not retry a POST on 500 (exactly one request)' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('Messages')}")
             .to_return(status: 500,
                        body: { code: 20_500, message: 'boom' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      expect do
        client.messages.create(to: '+14155550100', body: 'hi')
      end.to raise_error(VoiceML::ServerError)

      expect(stub).to have_been_requested.once
    end

    it 'does not retry a POST on a read timeout (exactly one request)' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('Messages')}")
             .to_raise(Net::ReadTimeout.new('read timeout'))

      expect do
        client.messages.create(to: '+14155550100', body: 'hi')
      end.to raise_error(VoiceML::ConnectionError)

      expect(stub).to have_been_requested.once
    end

    it 'does not retry a POST on connection reset (request may have been sent)' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('Calls')}")
             .to_raise(Errno::ECONNRESET.new('Connection reset by peer'))

      expect do
        client.calls.create(to: '+14155550100', from: '+14155550101', url: 'https://example.com/h')
      end.to raise_error(VoiceML::ConnectionError)

      expect(stub).to have_been_requested.once
    end

    it 'retries a POST on a connect-phase failure (request provably not sent)' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('Messages')}")
             .to_raise(Errno::ECONNREFUSED.new('Connection refused')).then
             .to_return(status: 201,
                        body: { sid: message_sid, status: 'sent' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      message = client.messages.create(to: '+14155550100', body: 'hi')

      expect(stub).to have_been_requested.times(2)
      expect(message.sid).to eq(message_sid)
    end

    it 'retries a POST on 429 and succeeds' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('Messages')}")
             .to_return({ status: 429,
                          body: { code: 20_429, message: 'slow down' }.to_json,
                          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '0' } },
                        { status: 201,
                          body: { sid: message_sid, status: 'sent' }.to_json,
                          headers: { 'Content-Type' => 'application/json' } })

      message = client.messages.create(to: '+14155550100', body: 'hi')

      expect(stub).to have_been_requested.times(2)
      expect(message.sid).to eq(message_sid)
    end
  end

  describe 'GET retries' do
    it 'retries a GET on 503 and returns the 200 body' do
      stub = stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
             .to_return({ status: 503, body: { code: 20_503, message: 'unavailable' }.to_json,
                          headers: { 'Content-Type' => 'application/json' } },
                        { status: 200,
                          body: { sid: call_sid, status: 'completed' }.to_json,
                          headers: { 'Content-Type' => 'application/json' } })

      call = client(max_retries: 2).calls.get(call_sid)
      expect(stub).to have_been_requested.times(2)
      expect(call.sid).to eq(call_sid)
    end

    it 'retries a GET on a read-phase transport error' do
      stub = stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
             .to_raise(EOFError.new('end of file reached')).then
             .to_return(status: 200,
                        body: { sid: call_sid, status: 'completed' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      call = client.calls.get(call_sid)
      expect(stub).to have_been_requested.times(2)
      expect(call.sid).to eq(call_sid)
    end

    it 'gives up after max_retries attempts and wraps the error' do
      stub = stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
             .to_raise(Errno::ECONNREFUSED.new('Connection refused'))

      expect do
        client(max_retries: 1).calls.get(call_sid)
      end.to raise_error(VoiceML::ConnectionError) do |error|
        expect(error.status_code).to eq(0)
        expect(error.cause).to be_a(Errno::ECONNREFUSED)
      end

      expect(stub).to have_been_requested.times(2)
    end
  end

  describe 'Retry-After handling' do
    let(:url) { "#{base_url}#{accounts_path('Calls', call_sid)}" }

    it 'honours delta-seconds on a 429 GET' do
      stub = stub_request(:get, url)
             .to_return({ status: 429,
                          body: { code: 20_429, message: 'slow' }.to_json,
                          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '0' } },
                        { status: 200,
                          body: { sid: call_sid, status: 'completed' }.to_json,
                          headers: { 'Content-Type' => 'application/json' } })

      expect(client.calls.get(call_sid).sid).to eq(call_sid)
      expect(stub).to have_been_requested.times(2)
    end

    it 'parses an HTTP-date Retry-After' do
      stub = stub_request(:get, url)
             .to_return({ status: 429,
                          body: { code: 20_429, message: 'slow' }.to_json,
                          headers: { 'Content-Type' => 'application/json',
                                     'Retry-After' => (Time.now - 5).httpdate } },
                        { status: 200,
                          body: { sid: call_sid, status: 'completed' }.to_json,
                          headers: { 'Content-Type' => 'application/json' } })

      expect(client.calls.get(call_sid).sid).to eq(call_sid)
      expect(stub).to have_been_requested.times(2)
    end

    it 'raises RateLimitError immediately (no sleep, one request) when Retry-After exceeds the cap' do
      stub = stub_request(:get, url)
             .to_return(status: 429,
                        body: { code: 20_429, message: 'slow' }.to_json,
                        headers: { 'Content-Type' => 'application/json', 'Retry-After' => '3600' })

      expect do
        client.calls.get(call_sid)
      end.to raise_error(VoiceML::RateLimitError) do |error|
        expect(error.retry_after).to eq(3600)
      end

      expect(stub).to have_been_requested.once
    end
  end

  describe 'exponential backoff with full jitter' do
    it 'sleeps a jittered value between 0 and the capped exponential delay' do
      stub_request(:get, "#{base_url}#{accounts_path('Calls', call_sid)}")
        .to_return({ status: 503, body: {}.to_json, headers: { 'Content-Type' => 'application/json' } },
                   { status: 503, body: {}.to_json, headers: { 'Content-Type' => 'application/json' } },
                   { status: 200, body: { sid: call_sid, status: 'completed' }.to_json,
                     headers: { 'Content-Type' => 'application/json' } })

      transport = client(max_retries: 2).instance_variable_get(:@transport)
      allow(transport).to receive(:sleep_for) { |secs| transport.instance_variable_set(:@last_sleep, secs) }
      client(max_retries: 2).calls.get(call_sid)

      expect(transport.instance_variable_get(:@last_sleep)).to be_between(0, 1.0)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VoiceML::IncomingPhoneNumbersResource do
  let(:client) { VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY) }
  let(:pn_sid) { 'PN0123456789abcdef0123456789abcdef' }

  def make_number_body(extra = {})
    {
      sid: pn_sid,
      account_sid: ACCOUNT_SID,
      phone_number: '+18005551234',
      friendly_name: '',
      api_version: '2010-04-01',
      uri: "/2010-04-01/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers/#{pn_sid}.json",
      voice_url: 'https://example.com/voice',
      voice_method: 'POST',
      voice_fallback_url: '',
      voice_fallback_method: 'POST',
      date_created: '2026-05-20T10:00:00Z',
      date_updated: '2026-05-20T10:00:00Z',
      capabilities: { voice: true, sms: false, mms: false, fax: false }
    }.merge(extra).to_json
  end

  describe '#list' do
    it 'GETs the .json-suffixed path and parses the envelope' do
      stub = stub_request(:get, "#{base_url}#{accounts_path('IncomingPhoneNumbers')}")
             .with(query: { 'PhoneNumber' => '+18005551234', 'PageSize' => '50' })
             .to_return(
               status: 200,
               body: {
                 incoming_phone_numbers: [JSON.parse(make_number_body)],
                 page: 0, page_size: 50, total: 1,
                 first_page_uri: "/2010-04-01/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers.json?Page=0",
                 next_page_uri: nil, previous_page_uri: nil,
                 uri: "/2010-04-01/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers.json"
               }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      result = client.incoming_phone_numbers.list(phone_number: '+18005551234', page_size: 50)

      expect(stub).to have_been_requested
      expect(result).to be_a(VoiceML::IncomingPhoneNumberList)
      expect(result.incoming_phone_numbers.length).to eq(1)
      number = result.incoming_phone_numbers.first
      expect(number).to be_a(VoiceML::IncomingPhoneNumber)
      expect(number.sid).to eq(pn_sid)
      expect(number.sid).to match(/\APN[a-f0-9]{32}\z/)
      expect(number.phone_number).to eq('+18005551234')
      expect(result.page).to eq(0)
      expect(result.page_size).to eq(50)
    end

    it 'targets a path that ends in .json' do
      stub = stub_request(:get, %r{/IncomingPhoneNumbers\.json(\?|$)})
             .to_return(status: 200,
                        body: { incoming_phone_numbers: [], page: 0, page_size: 50, total: 0 }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.incoming_phone_numbers.list
      expect(stub).to have_been_requested
    end
  end

  describe '#create' do
    it 'POSTs a form body and returns an IncomingPhoneNumber' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('IncomingPhoneNumbers')}")
             .with(
               headers: {
                 'Authorization' => basic_auth_header,
                 'Content-Type' => 'application/x-www-form-urlencoded'
               },
               body: hash_including(
                 'PhoneNumber' => '+18005551234',
                 'VoiceUrl' => 'https://example.com/voice',
                 'VoiceMethod' => 'POST'
               )
             )
             .to_return(status: 201, body: make_number_body,
                        headers: { 'Content-Type' => 'application/json' })

      number = client.incoming_phone_numbers.create(
        phone_number: '+18005551234',
        voice_url: 'https://example.com/voice',
        voice_method: 'POST'
      )

      expect(stub).to have_been_requested
      expect(number.sid).to start_with('PN')
      expect(number.phone_number).to eq('+18005551234')
      expect(number.voice_url).to eq('https://example.com/voice')
    end
  end

  describe '#get' do
    it 'GETs the sid path with .json suffix' do
      stub = stub_request(:get, "#{base_url}#{accounts_path('IncomingPhoneNumbers', pn_sid)}")
             .to_return(status: 200, body: make_number_body,
                        headers: { 'Content-Type' => 'application/json' })

      number = client.incoming_phone_numbers.get(pn_sid)

      expect(stub).to have_been_requested
      expect(number).to be_a(VoiceML::IncomingPhoneNumber)
      expect(number.sid).to eq(pn_sid)
      expect(number.capabilities).to eq('voice' => true, 'sms' => false, 'mms' => false, 'fax' => false)
    end
  end

  describe '#update' do
    it 'POSTs only the supplied routing fields' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('IncomingPhoneNumbers', pn_sid)}")
             .with(body: hash_including('VoiceUrl' => 'https://example.com/v2'))
             .to_return(
               status: 200,
               body: make_number_body(voice_url: 'https://example.com/v2'),
               headers: { 'Content-Type' => 'application/json' }
             )

      number = client.incoming_phone_numbers.update(pn_sid, voice_url: 'https://example.com/v2')

      expect(stub).to have_been_requested
      expect(number.voice_url).to eq('https://example.com/v2')
    end
  end

  describe '#delete' do
    it 'DELETEs the sid path with .json suffix and returns nil' do
      stub = stub_request(:delete, "#{base_url}#{accounts_path('IncomingPhoneNumbers', pn_sid)}")
             .to_return(status: 204, body: '', headers: {})

      result = client.incoming_phone_numbers.delete(pn_sid)

      expect(stub).to have_been_requested
      expect(result).to be_nil
    end
  end
end

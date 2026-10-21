# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VoiceML::OutgoingCallerIdsResource do
  let(:client) { VoiceML::Client.new(account_sid: ACCOUNT_SID, api_key: API_KEY) }

  def make_validation_body(extra = {})
    {
      account_sid: ACCOUNT_SID,
      phone_number: '+14155550100',
      friendly_name: 'Desk',
      validation_code: '123456',
      call_sid: 'CA0123456789abcdef0123456789abcdef'
    }.merge(extra).to_json
  end

  describe '#create' do
    it 'POSTs a form body and returns a ValidationRequest' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('OutgoingCallerIds')}")
             .with(
               headers: {
                 'Authorization' => basic_auth_header,
                 'Content-Type' => 'application/x-www-form-urlencoded'
               },
               body: hash_including(
                 'PhoneNumber' => '+14155550100',
                 'FriendlyName' => 'Desk'
               )
             )
             .to_return(status: 200, body: make_validation_body,
                        headers: { 'Content-Type' => 'application/json' })

      request = client.outgoing_caller_ids.create(phone_number: '+14155550100', friendly_name: 'Desk')

      expect(stub).to have_been_requested
      expect(request).to be_a(VoiceML::ValidationRequest)
      expect(request.account_sid).to eq(ACCOUNT_SID)
      expect(request.phone_number).to eq('+14155550100')
      expect(request.friendly_name).to eq('Desk')
      expect(request.validation_code).to eq('123456')
      expect(request.call_sid).to eq('CA0123456789abcdef0123456789abcdef')
    end

    it 'sends CallDelay, Extension, StatusCallback and StatusCallbackMethod as PascalCase form keys' do
      stub = stub_request(:post, "#{base_url}#{accounts_path('OutgoingCallerIds')}")
             .with(
               body: hash_including(
                 'PhoneNumber' => '+14155550100',
                 'CallDelay' => '5',
                 'Extension' => '1234',
                 'StatusCallback' => 'https://example.com/validated',
                 'StatusCallbackMethod' => 'GET'
               )
             )
             .to_return(status: 200, body: make_validation_body,
                        headers: { 'Content-Type' => 'application/json' })

      client.outgoing_caller_ids.create(
        phone_number: '+14155550100',
        call_delay: 5,
        extension: '1234',
        status_callback: 'https://example.com/validated',
        status_callback_method: 'GET'
      )

      expect(stub).to have_been_requested
    end
  end
end

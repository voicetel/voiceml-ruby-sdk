# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'VoiceML v0.6.6' do
  let(:account_sid) { 'AC' + ('f' * 32) }
  let(:api_key)     { 'secret-key-1234' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key, base_url: base_url) }
  let(:base_url)    { 'https://voiceml.example.test' }

  describe 'VoiceML::VERSION' do
    it 'reports 0.6.6' do
      expect(VoiceML::VERSION).to eq('0.6.6')
    end
  end

  describe '#create_participant' do
    it 'sends From and To on the wire' do
      conf_sid = 'CF' + ('f' * 32)
      stub_request(:post, "#{base_url}/2010-04-01/Accounts/#{account_sid}/Conferences/#{conf_sid}/Participants.json")
        .with(body: hash_including('From' => '+18005550000', 'To' => '+18005551234'))
        .to_return(
          status: 201,
          body: {
            call_sid: 'CA' + ('f' * 32),
            conference_sid: conf_sid,
            account_sid: account_sid,
            status: 'queued',
            api_version: '2010-04-01',
            uri: '/x'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      client.conferences.create_participant(conf_sid, from: '+18005550000', to: '+18005551234')
    end
  end

  describe '#list_notifications' do
    it 'sends Log and MessageDate filters' do
      call_sid = 'CA' + ('f' * 32)
      stub_request(:get, %r{/Calls/#{call_sid}/Notifications\.json})
        .with(query: hash_including(
          'Log' => '1',
          'MessageDate' => '2026-05-01',
          'MessageDate<' => '2026-05-02',
          'MessageDate>' => '2026-04-30'
        ))
        .to_return(
          status: 200,
          body: { notifications: [], page: 0, page_size: 50, total: 0 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      client.calls.list_notifications(
        call_sid,
        log: 1,
        message_date: '2026-05-01',
        message_date_lt: '2026-05-02',
        message_date_gt: '2026-04-30'
      )
    end
  end
end

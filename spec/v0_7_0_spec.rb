# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'VoiceML v0.7.0' do
  let(:account_sid) { 'AC' + ('f' * 32) }
  let(:api_key)     { 'secret-key-1234' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key, base_url: base_url) }
  let(:base_url)    { 'https://voiceml.example.test' }

  def messages_path(*parts)
    "/2010-04-01/Accounts/#{account_sid}/Messages#{parts.empty? ? '' : '/' + parts.join('/')}.json"
  end

  def payments_path(call_sid, *parts)
    "/2010-04-01/Accounts/#{account_sid}/Calls/#{call_sid}/Payments#{parts.empty? ? '' : '/' + parts.join('/')}.json"
  end

  describe 'VoiceML::VERSION' do
    it 'reports 0.9.2' do
      expect(VoiceML::VERSION).to eq('0.9.2')
    end
  end

  # ---------------------------------------------------------------------------
  # Messages — create / fetch / list / update / delete
  # ---------------------------------------------------------------------------
  describe '#messages.create' do
    it 'POSTs To, Body, and From as form fields' do
      stub_request(:post, "#{base_url}#{messages_path}")
        .with(
          body: hash_including('To' => '+18005551234', 'Body' => 'hello',
                               'From' => '+18005550000'),
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
        )
        .to_return(
          status: 201,
          body: {
            sid: 'SM' + ('a' * 32),
            account_sid: account_sid,
            api_version: '2010-04-01',
            to: '+18005551234',
            from: '+18005550000',
            body: 'hello',
            status: 'sent',
            num_segments: '1',
            num_media: '0',
            direction: 'outbound-api',
            date_created: 'Mon, 01 Jun 2026 12:00:00 +0000',
            date_updated: 'Mon, 01 Jun 2026 12:00:00 +0000',
            uri: '/x'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      msg = client.messages.create(to: '+18005551234', body: 'hello', from: '+18005550000')
      expect(msg).to be_a(VoiceML::Message)
      expect(msg.sid).to start_with('SM')
      expect(msg.status).to eq('sent')
      expect(msg.num_segments).to eq('1')
      expect(msg.num_media).to eq('0')
      expect(msg.direction).to eq('outbound-api')
    end
  end

  describe '#messages.fetch' do
    it 'GETs /Messages/{Sid}.json' do
      sid = 'SM' + ('b' * 32)
      stub_request(:get, "#{base_url}#{messages_path(sid)}")
        .to_return(
          status: 200,
          body: {
            sid: sid,
            account_sid: account_sid,
            api_version: '2010-04-01',
            to: '+18005551234',
            from: '+18005550000',
            body: 'hi',
            status: 'sent',
            num_segments: '1',
            num_media: '0',
            direction: 'outbound-api',
            date_created: 'Mon, 01 Jun 2026 12:00:00 +0000',
            date_updated: 'Mon, 01 Jun 2026 12:00:00 +0000',
            uri: '/x'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      msg = client.messages.fetch(sid)
      expect(msg.sid).to eq(sid)
      expect(msg.body).to eq('hi')
    end
  end

  describe '#messages.list' do
    it 'sends To and DateSent</> filters as query parameters' do
      stub_request(:get, "#{base_url}#{messages_path}")
        .with(query: hash_including(
          'To'         => '+18005551234',
          'DateSent<'  => '2026-06-02',
          'DateSent>'  => '2026-05-30'
        ))
        .to_return(
          status: 200,
          body: {
            messages: [
              {
                sid: 'SM' + ('c' * 32),
                account_sid: account_sid,
                api_version: '2010-04-01',
                to: '+18005551234',
                from: '+18005550000',
                body: 'one',
                status: 'sent',
                num_segments: '1',
                num_media: '0',
                direction: 'outbound-api',
                date_created: 'x', date_updated: 'x', uri: '/x'
              }
            ],
            page: 0, page_size: 50, total: 1, next_page_uri: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      list = client.messages.list(
        to: '+18005551234',
        date_sent_lt: '2026-06-02',
        date_sent_gt: '2026-05-30'
      )
      expect(list).to be_a(VoiceML::MessageList)
      expect(list.messages.length).to eq(1)
      expect(list.messages.first.body).to eq('one')
    end
  end

  describe '#messages.update' do
    it 'POSTs Body= for redaction' do
      sid = 'SM' + ('d' * 32)
      stub_request(:post, "#{base_url}#{messages_path(sid)}")
        .with(body: hash_including('Body' => ''))
        .to_return(
          status: 200,
          body: {
            sid: sid,
            account_sid: account_sid,
            api_version: '2010-04-01',
            to: '+18005551234',
            from: '+18005550000',
            body: '',
            status: 'sent',
            num_segments: '1',
            num_media: '0',
            direction: 'outbound-api',
            date_created: 'x', date_updated: 'x', uri: '/x'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      msg = client.messages.update(sid, body: '')
      expect(msg.body).to eq('')
    end
  end

  describe '#messages.delete' do
    it 'DELETEs /Messages/{Sid}.json and returns nil' do
      sid = 'SM' + ('e' * 32)
      stub_request(:delete, "#{base_url}#{messages_path(sid)}")
        .to_return(status: 204, body: '')

      expect(client.messages.delete(sid)).to be_nil
    end
  end

  describe '#messages.each' do
    it 'walks pages and yields every Message' do
      page0 = {
        messages: [
          { 'sid' => 'SM' + ('1' * 32), 'account_sid' => account_sid,
            'status' => 'sent', 'num_segments' => '1', 'num_media' => '0',
            'direction' => 'outbound-api' },
          { 'sid' => 'SM' + ('2' * 32), 'account_sid' => account_sid,
            'status' => 'sent', 'num_segments' => '1', 'num_media' => '0',
            'direction' => 'outbound-api' }
        ],
        page: 0, page_size: 2,
        next_page_uri: "#{messages_path}?Page=1"
      }
      page1 = {
        messages: [
          { 'sid' => 'SM' + ('3' * 32), 'account_sid' => account_sid,
            'status' => 'sent', 'num_segments' => '1', 'num_media' => '0',
            'direction' => 'outbound-api' }
        ],
        page: 1, page_size: 2, next_page_uri: nil
      }

      stub_request(:get, "#{base_url}#{messages_path}")
        .with(query: { 'Page' => '0' })
        .to_return(status: 200, body: page0.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "#{base_url}#{messages_path}")
        .with(query: { 'Page' => '1' })
        .to_return(status: 200, body: page1.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      collected = []
      client.messages.each { |m| collected << m }

      expect(collected.length).to eq(3)
      expect(collected.map(&:sid)).to eq(%W[
        SM#{'1' * 32}
        SM#{'2' * 32}
        SM#{'3' * 32}
      ])
    end
  end

  # ---------------------------------------------------------------------------
  # Calls.start_payment / update_payment
  # ---------------------------------------------------------------------------
  describe '#calls.start_payment' do
    it 'POSTs the form body with multiple Pay fields' do
      call_sid = 'CA' + ('a' * 32)
      payment_sid = 'PY' + ('a' * 32)

      stub_request(:post, "#{base_url}#{payments_path(call_sid)}")
        .with(
          body: hash_including(
            'IdempotencyKey'  => 'idem-1',
            'StatusCallback'  => 'https://example.com/cb',
            'ChargeAmount'    => '9.99',
            'Currency'        => 'USD',
            'PaymentMethod'   => 'credit-card',
            'TokenType'       => 'one-time',
            'PostalCode'      => 'true',
            'SecurityCode'    => 'true',
            'Timeout'         => '5',
            'Confirmation'    => 'false'
          ),
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
        )
        .to_return(
          status: 201,
          body: {
            sid: payment_sid,
            account_sid: account_sid,
            call_sid: call_sid,
            api_version: '2010-04-01',
            date_created: 'Mon, 01 Jun 2026 12:00:00 +0000',
            date_updated: 'Mon, 01 Jun 2026 12:00:00 +0000',
            uri: "/Calls/#{call_sid}/Payments/#{payment_sid}"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      payment = client.calls.start_payment(
        call_sid,
        idempotency_key:  'idem-1',
        status_callback:  'https://example.com/cb',
        charge_amount:    '9.99',
        currency:         'USD',
        payment_method:   VoiceML::PaymentMethod::CREDIT_CARD,
        token_type:       VoiceML::PaymentTokenType::ONE_TIME,
        postal_code:      true,
        security_code:    true,
        timeout:          5,
        confirmation:     false
      )

      expect(payment).to be_a(VoiceML::CallPayment)
      expect(payment.sid).to eq(payment_sid)
      expect(payment.call_sid).to eq(call_sid)
    end
  end

  describe '#calls.update_payment' do
    let(:call_sid)    { 'CA' + ('b' * 32) }
    let(:payment_sid) { 'PY' + ('b' * 32) }
    let(:response_body) do
      {
        sid: payment_sid,
        account_sid: account_sid,
        call_sid: call_sid,
        api_version: '2010-04-01',
        date_created: 'x',
        date_updated: 'y',
        uri: "/Calls/#{call_sid}/Payments/#{payment_sid}"
      }.to_json
    end

    it 'POSTs Status=complete to finalize the session' do
      stub_request(:post, "#{base_url}#{payments_path(call_sid, payment_sid)}")
        .with(body: hash_including('Status' => 'complete'))
        .to_return(status: 200, body: response_body,
                   headers: { 'Content-Type' => 'application/json' })

      payment = client.calls.update_payment(
        call_sid, payment_sid,
        status: VoiceML::PaymentSessionStatus::COMPLETE
      )
      expect(payment.sid).to eq(payment_sid)
    end

    it 'POSTs Capture=security-code to advance the session' do
      stub_request(:post, "#{base_url}#{payments_path(call_sid, payment_sid)}")
        .with(body: hash_including('Capture' => 'security-code'))
        .to_return(status: 200, body: response_body,
                   headers: { 'Content-Type' => 'application/json' })

      payment = client.calls.update_payment(
        call_sid, payment_sid,
        capture: VoiceML::PaymentCapture::SECURITY_CODE
      )
      expect(payment.sid).to eq(payment_sid)
    end
  end

  # ---------------------------------------------------------------------------
  # Payment enum modules
  # ---------------------------------------------------------------------------
  describe 'payment wire-enum modules' do
    it 'exposes the documented values' do
      expect(VoiceML::PaymentBankAccountType::ALL).to contain_exactly(
        'consumer-checking', 'consumer-savings', 'commercial-checking'
      )
      expect(VoiceML::PaymentInput::ALL).to eq(['dtmf'])
      expect(VoiceML::PaymentMethod::ALL).to contain_exactly('credit-card', 'ach-debit')
      expect(VoiceML::PaymentTokenType::ALL).to contain_exactly(
        'one-time', 'reusable', 'payment-method'
      )
      expect(VoiceML::PaymentCapture::ALL.length).to eq(10)
      expect(VoiceML::PaymentSessionStatus::ALL).to contain_exactly('complete', 'cancel')
    end
  end
end

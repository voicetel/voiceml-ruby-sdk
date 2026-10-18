# frozen_string_literal: true

require 'spec_helper'

# Wire-shape tests for the final-spec additions: Monitor v1 Alerts
# (`/v1/Alerts`), message delivery feedback, and account key rotation.
RSpec.describe 'VoiceML final-spec surface — Monitor Alerts, feedback, key rotation' do
  let(:account_sid) { 'AC' + ('f' * 32) }
  let(:api_key)     { 'secret-key-1234' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key) }

  base = 'https://voiceml.voicetel.com'

  def meta(url: nil, next_page_url: nil, page_size: 25)
    { first_page_url: url, next_page_url: next_page_url, previous_page_url: nil,
      url: url, page: 0, page_size: page_size, key: 'alerts' }
  end

  let(:alert_sid) { 'NO' + ('a' * 32) }
  let(:alert_body) do
    { sid: alert_sid, account_sid: account_sid, alert_text: 'HTTP retrieval failed',
      api_version: nil, error_code: '11200', log_level: 'error',
      more_info: 'https://voicetel.com/docs/errors/11200',
      request_method: 'POST', request_url: 'https://example.com/hook',
      resource_sid: 'CA' + ('1' * 32), service_sid: nil,
      date_created: '2026-10-17T12:00:00Z', date_generated: '2026-10-17T12:00:00Z',
      date_updated: '2026-10-17T12:00:00Z', url: "#{base}/v1/Alerts/#{alert_sid}" }
  end

  describe 'Monitor Alerts list' do
    it 'sends the declared filters on the default host with auth' do
      stub = stub_request(:get, "#{base}/v1/Alerts")
             .with(query: { 'LogLevel' => 'error', 'StartDate' => '2026-10-01',
                            'EndDate' => '2026-10-02', 'PageSize' => '25' })
             .with(basic_auth: [account_sid, api_key])
             .to_return(status: 200,
                        body: { alerts: [alert_body],
                                meta: meta(url: "#{base}/v1/Alerts?PageSize=25") }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      listed = client.monitor_alerts.list(log_level: 'error', start_date: '2026-10-01',
                                          end_date: '2026-10-02', page_size: 25)

      expect(listed).to be_a(VoiceML::MonitorAlertList)
      expect(listed.alerts.length).to eq(1)
      alert = listed.alerts.first
      expect(alert).to be_a(VoiceML::MonitorAlert)
      expect(alert.sid).to eq(alert_sid)
      expect(alert.error_code).to eq('11200')
      expect(alert.log_level).to eq('error')
      expect(alert.resource_sid).to eq('CA' + ('1' * 32))
      expect(alert.api_version).to be_nil
      expect(listed.page_size).to eq(25)
      expect(stub).to have_been_requested
    end

    it 'omits unset filters entirely' do
      stub = stub_request(:get, "#{base}/v1/Alerts")
             .with(query: { 'LogLevel' => 'warning' })
             .to_return(status: 200,
                        body: { alerts: [], meta: meta(url: "#{base}/v1/Alerts") }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.monitor_alerts.list(log_level: 'warning')
      expect(stub).to have_been_requested
    end

    it 'rejects unknown filters' do
      expect { client.monitor_alerts.list(log_levels: 'error') }
        .to raise_error(ArgumentError, /unknown keyword/)
    end
  end

  describe 'Monitor Alerts fetch' do
    it 'fetches one alert with the stored request/response detail' do
      detailed = alert_body.merge(
        request_headers: 'Accept: application/json',
        request_variables: 'Digits=1234',
        response_body: '500 Internal Server Error',
        response_headers: 'Content-Type: text/plain'
      )
      stub = stub_request(:get, "#{base}/v1/Alerts/#{alert_sid}")
             .to_return(status: 200, body: detailed.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      alert = client.monitor_alerts.fetch(alert_sid)

      expect(alert.response_body).to eq('500 Internal Server Error')
      expect(alert.request_variables).to eq('Digits=1234')
      expect(stub).to have_been_requested
    end

    it 'percent-encodes the sid as one path segment' do
      stub = stub_request(:get, "#{base}/v1/Alerts/NO%2Ba%20b")
             .to_return(status: 200, body: alert_body.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.monitor_alerts.fetch('NO+a b')
      expect(stub).to have_been_requested
    end
  end

  describe 'Monitor Alerts pagination' do
    it 'returns nil when meta.next_page_url is null' do
      stub_request(:get, "#{base}/v1/Alerts")
        .to_return(status: 200,
                   body: { alerts: [alert_body], meta: meta(url: "#{base}/v1/Alerts") }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      page = client.monitor_alerts.list
      expect(client.monitor_alerts.next_page(page)).to be_nil
    end

    it 'follows a same-host next_page_url verbatim and stops after the last page' do
      second_sid = 'NO' + ('b' * 32)
      second_body = alert_body.merge(sid: second_sid)
      link = "#{base}/v1/Alerts?PageSize=1&PageToken=PTabc"
      page_one = stub_request(:get, "#{base}/v1/Alerts")
                 .with(query: { 'PageSize' => '1' })
                 .to_return(status: 200,
                            body: { alerts: [alert_body], meta: meta(url: "#{base}/v1/Alerts?PageSize=1", next_page_url: link, page_size: 1) }.to_json,
                            headers: { 'Content-Type' => 'application/json' })
      page_two = stub_request(:get, link)
                 .to_return(status: 200,
                            body: { alerts: [second_body], meta: meta(url: link, page_size: 1) }.to_json,
                            headers: { 'Content-Type' => 'application/json' })

      collected = []
      client.monitor_alerts.each(page_size: 1) { |alert| collected << alert.sid }

      expect(collected).to eq([alert_sid, second_sid])
      expect(page_one).to have_been_requested
      expect(page_two).to have_been_requested
    end

    it 'refuses a next_page_url that leaves the configured host' do
      stub_request(:get, "#{base}/v1/Alerts")
        .to_return(status: 200,
                   body: { alerts: [alert_body],
                           meta: meta(url: "#{base}/v1/Alerts", next_page_url: 'https://evil.example.com/v1/Alerts') }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      page = client.monitor_alerts.list
      expect { client.monitor_alerts.next_page(page) }
        .to raise_error(VoiceML::ConnectionError, /configured product origin/)
    end
  end

  describe 'Message delivery feedback' do
    let(:message_sid) { 'SM' + ('2' * 32) }

    it 'posts Outcome as an exact form pair and decodes the echo' do
      feedback_url = "#{base}/2010-04-01/Accounts/#{account_sid}/Messages/#{message_sid}/Feedback.json"
      stub = stub_request(:post, feedback_url)
             .with(body: 'Outcome=confirmed')
             .with(basic_auth: [account_sid, api_key])
             .to_return(status: 201,
                        body: { account_sid: account_sid, message_sid: message_sid,
                                outcome: 'confirmed',
                                date_created: 'Mon, 17 Oct 2026 12:00:00 +0000',
                                date_updated: 'Mon, 17 Oct 2026 12:00:00 +0000',
                                uri: "/2010-04-01/Accounts/#{account_sid}/Messages/#{message_sid}/Feedback.json" }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      feedback = client.messages.create_feedback(message_sid, outcome: 'confirmed')

      expect(feedback).to be_a(VoiceML::MessageFeedback)
      expect(feedback.message_sid).to eq(message_sid)
      expect(feedback.outcome).to eq('confirmed')
      expect(stub).to have_been_requested
    end

    it 'requires an outcome' do
      expect { client.messages.create_feedback(message_sid) }
        .to raise_error(ArgumentError, /missing keyword/)
    end
  end

  describe 'Account key rotation' do
    let(:rotate_url) { "#{base}/2010-04-01/Accounts/#{account_sid}/RotateKey.json" }
    let(:key_body) do
      { sid: account_sid, api_key: 'fresh-rotated-key-9876', sip_username: 'sip-acme',
        phone_regions: ['US'], allow_cidr: [], disabled: false,
        stt_http_token_set: false, tts_http_token_set: false,
        stripe_secret_key_set: false, pay_enabled: false,
        sms_allowed_providers: ['twilio'], stt_allowed_providers: [],
        aws_secret_access_key_set: false,
        created_at: '2026-10-17T12:00:00Z', updated_at: '2026-10-17T12:00:00Z' }
    end

    it 'posts without a body and decodes the account-with-key view' do
      stub = stub_request(:post, rotate_url)
             .with(basic_auth: [account_sid, api_key])
             .to_return(status: 200, body: key_body.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      account = client.accounts.rotate_key

      expect(account).to be_a(VoiceML::AccountWithKey)
      expect(account.sid).to eq(account_sid)
      expect(account.api_key).to eq('fresh-rotated-key-9876')
      expect(account.sms_allowed_providers).to eq(['twilio'])
      expect(stub).to have_been_requested
    end

    it 'never shows the api_key in inspect or to_s' do
      stub_request(:post, rotate_url)
        .to_return(status: 200, body: key_body.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      account = client.accounts.rotate_key
      expect(account.inspect).not_to include('fresh-rotated-key-9876')
      expect(account.to_s).not_to include('fresh-rotated-key-9876')
      expect(account.inspect).to include(account_sid)
    end
  end
end

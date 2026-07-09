# frozen_string_literal: true

require 'spec_helper'

# Wire-shape tests for the v0.9.2 surface: per-product host routing, Messaging
# Service (#16), and Pricing v1/v2 (#18).
#
# Messaging Service must ride `messaging.voicetel.com` (that host is what
# disambiguates it from Conversation Service on the shared `/v1/Services` path).
# Pricing rides the default host. Host derivation is unit-tested directly.
RSpec.describe 'VoiceML v0.9.2 — per-product hosts, Messaging Service, Pricing' do
  let(:account_sid) { 'AC' + ('f' * 32) }
  let(:api_key)     { 'secret-key-1234' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key) }

  base = 'https://voiceml.voicetel.com'
  msg  = 'https://messaging.voicetel.com'
  conv = 'https://conversations.voicetel.com'

  def meta(url: nil)
    { first_page_url: url, next_page_url: nil, previous_page_url: nil,
      url: url, page: 0, page_size: 50, key: 'services' }
  end

  # ===========================================================================
  # Version
  # ===========================================================================
  describe 'version' do
    it 'is 0.9.2' do
      expect(VoiceML::VERSION).to eq('0.9.2')
    end
  end

  # ===========================================================================
  # Host resolution
  # ===========================================================================
  describe 'host derivation' do
    it 'derives product hosts from the default base' do
      default, messaging, conversations = VoiceML::Hosts.resolve_product_base_urls(base)
      expect(default).to eq(base)
      expect(messaging).to eq(msg)
      expect(conversations).to eq(conv)
    end

    it 'derives regional product hosts' do
      default, messaging, conversations =
        VoiceML::Hosts.resolve_product_base_urls('https://east-1.us.voiceml.voicetel.com')
      expect(default).to eq('https://east-1.us.voiceml.voicetel.com')
      expect(messaging).to eq('https://east-1.us.messaging.voicetel.com')
      expect(conversations).to eq('https://east-1.us.conversations.voicetel.com')
    end

    it 'falls back to a single host for a self-hosted base URL' do
      # A custom host has no `voiceml` label to swap — every product stays on it,
      # so a single-host deployment keeps working.
      default, messaging, conversations =
        VoiceML::Hosts.resolve_product_base_urls('https://pbx.acme.com')
      expect(default).to eq('https://pbx.acme.com')
      expect(messaging).to eq('https://pbx.acme.com')
      expect(conversations).to eq('https://pbx.acme.com')
    end

    it 'lets explicit overrides win over derivation' do
      default, messaging, conversations = VoiceML::Hosts.resolve_product_base_urls(
        'https://pbx.acme.com',
        messaging_base_url: 'https://msg.acme.com',
        conversations_base_url: 'https://conv.acme.com/'
      )
      expect(default).to eq('https://pbx.acme.com')
      expect(messaging).to eq('https://msg.acme.com')
      expect(conversations).to eq('https://conv.acme.com')
    end
  end

  describe 'resource wiring' do
    it 'wires messaging_v1 and pricing on the client' do
      expect(client.messaging_v1).to be_a(VoiceML::MessagingV1Resource)
      expect(client.messaging_v1.services).to be_a(VoiceML::MessagingV1ServicesResource)
      expect(client.pricing).to be_a(VoiceML::PricingResource)
      expect(client.pricing.v1.voice.countries).to be_a(VoiceML::PricingCountriesResource)
      expect(client.pricing.v1.voice.numbers).to be_a(VoiceML::PricingV1VoiceNumbersResource)
      expect(client.pricing.v1.messaging.countries).to be_a(VoiceML::PricingCountriesResource)
      expect(client.pricing.v1.phone_numbers.countries).to be_a(VoiceML::PricingCountriesResource)
      expect(client.pricing.v2.voice.countries).to be_a(VoiceML::PricingCountriesResource)
      expect(client.pricing.v2.voice.numbers).to be_a(VoiceML::PricingV2VoiceNumbersResource)
      expect(client.pricing.v2.trunking.countries).to be_a(VoiceML::PricingCountriesResource)
      expect(client.pricing.v2.trunking.numbers).to be_a(VoiceML::PricingV2TrunkingNumbersResource)
    end
  end

  # ===========================================================================
  # Messaging Service — CRUD on the messaging host
  # ===========================================================================
  describe 'Messaging Service CRUD on the messaging host' do
    let(:sid) { 'MG' + ('1' * 32) }
    let(:service_body) do
      { sid: sid, account_sid: account_sid, friendly_name: 'alerts',
        inbound_request_url: 'https://example.com/in', sticky_sender: true,
        date_created: '2026-07-08T00:00:00Z', date_updated: '2026-07-08T00:00:00Z',
        url: "#{msg}/v1/Services/#{sid}" }.to_json
    end

    it 'routes create/list/fetch/update/delete to messaging.voicetel.com' do
      create_stub = stub_request(:post, "#{msg}/v1/Services")
                    .with(body: hash_including('FriendlyName' => 'alerts',
                                               'InboundRequestUrl' => 'https://example.com/in',
                                               'StickySender' => 'true'))
                    .to_return(status: 201, body: service_body, headers: { 'Content-Type' => 'application/json' })

      list_body = { services: [JSON.parse(service_body)], meta: meta(url: "#{msg}/v1/Services") }.to_json
      list_stub = stub_request(:get, "#{msg}/v1/Services")
                  .with(query: hash_including('PageSize' => '25'))
                  .to_return(status: 200, body: list_body, headers: { 'Content-Type' => 'application/json' })

      fetch_stub = stub_request(:get, "#{msg}/v1/Services/#{sid}")
                   .to_return(status: 200, body: service_body, headers: { 'Content-Type' => 'application/json' })

      update_stub = stub_request(:post, "#{msg}/v1/Services/#{sid}")
                    .with(body: { 'FriendlyName' => 'renamed' })
                    .to_return(status: 200, body: service_body, headers: { 'Content-Type' => 'application/json' })

      delete_stub = stub_request(:delete, "#{msg}/v1/Services/#{sid}").to_return(status: 204)

      created = client.messaging_v1.services.create(
        friendly_name: 'alerts', inbound_request_url: 'https://example.com/in', sticky_sender: true
      )
      listed  = client.messaging_v1.services.list(page_size: 25)
      fetched = client.messaging_v1.services.fetch(sid)
      updated = client.messaging_v1.services.update(sid, friendly_name: 'renamed')
      deleted = client.messaging_v1.services.delete(sid)

      expect(created).to be_a(VoiceML::MessagingService)
      expect(created.sid).to eq(sid)
      expect(created.sid).to start_with('MG')
      expect(created.sticky_sender).to be true
      expect(listed.services.length).to eq(1)
      expect(fetched.sid).to eq(sid)
      expect(updated.sid).to eq(sid)
      expect(deleted).to be_nil

      expect(create_stub).to have_been_requested
      expect(list_stub).to have_been_requested
      expect(fetch_stub).to have_been_requested
      expect(update_stub).to have_been_requested
      expect(delete_stub).to have_been_requested
    end

    it 'honors an explicit messaging_base_url override' do
      custom = VoiceML::Client.new(
        account_sid: account_sid, api_key: api_key,
        base_url: 'https://pbx.acme.com', messaging_base_url: 'https://msg.acme.com'
      )
      stub = stub_request(:get, 'https://msg.acme.com/v1/Services')
             .to_return(status: 200,
                        body: { services: [], meta: meta(url: 'https://msg.acme.com/v1/Services') }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      custom.messaging_v1.services.list
      expect(stub).to have_been_requested
    end
  end

  # ===========================================================================
  # Conversations v1 rides the conversations host under the default base
  # ===========================================================================
  describe 'Conversations v1 host routing' do
    it 'sends conversations_v1 requests to conversations.voicetel.com' do
      stub = stub_request(:get, "#{conv}/v1/Conversations")
             .to_return(status: 200,
                        body: { conversations: [], meta: meta(url: "#{conv}/v1/Conversations") }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      client.conversations_v1.conversations.list
      expect(stub).to have_been_requested
    end
  end

  # ===========================================================================
  # Pricing v1/v2 — read-only on the default host
  # ===========================================================================
  describe 'Pricing v1 voice countries + number on the default host' do
    it 'lists countries, fetches a country, and fetches a number (E.164 url-encoded)' do
      countries = { countries: [{ country: 'United States', iso_country: 'US',
                                  url: "#{base}/v1/Voice/Countries/US" }],
                    meta: { page: 0, page_size: 50 } }.to_json
      country = { country: 'United States', iso_country: 'US',
                  outbound_prefix_prices: [{ prefixes: ['1'], base_price: '0.013',
                                             current_price: '0.013', friendly_name: 'United States & Canada' }],
                  inbound_call_prices: [{ base_price: '0.0085', current_price: '0.0085',
                                          number_type: 'local' }],
                  price_unit: 'USD', url: "#{base}/v1/Voice/Countries/US" }.to_json
      number = { number: '+18005551234', country: 'United States', iso_country: 'US',
                 outbound_call_price: { base_price: '0.013', current_price: '0.013' },
                 inbound_call_price: { base_price: '0.0085', current_price: '0.0085',
                                       number_type: 'toll free' },
                 price_unit: 'USD', url: "#{base}/v1/Voice/Numbers/+18005551234" }.to_json

      countries_stub = stub_request(:get, "#{base}/v1/Voice/Countries")
                       .to_return(status: 200, body: countries, headers: { 'Content-Type' => 'application/json' })
      country_stub = stub_request(:get, "#{base}/v1/Voice/Countries/US")
                     .to_return(status: 200, body: country, headers: { 'Content-Type' => 'application/json' })
      number_stub = stub_request(:get, "#{base}/v1/Voice/Numbers/%2B18005551234")
                    .to_return(status: 200, body: number, headers: { 'Content-Type' => 'application/json' })

      listed  = client.pricing.v1.voice.countries.list
      fetched = client.pricing.v1.voice.countries.fetch('US')
      num     = client.pricing.v1.voice.numbers.fetch('+18005551234')

      expect(listed).to be_a(VoiceML::PricingCountriesList)
      expect(listed.countries.first.iso_country).to eq('US')
      expect(fetched.outbound_prefix_prices.first.prefixes).to eq(['1'])
      expect(num.inbound_call_price.number_type).to eq('toll free')

      expect(countries_stub).to have_been_requested
      expect(country_stub).to have_been_requested
      expect(number_stub).to have_been_requested
    end
  end

  describe 'Pricing v2 voice number with origination' do
    it 'passes OriginationNumber as an (encoded) query param' do
      payload = { destination_number: '+18005551234', origination_number: '+15551112222',
                  country: 'United States', iso_country: 'US',
                  outbound_call_prices: [{ origination_prefixes: ['1'], base_price: '0.013',
                                           current_price: '0.013' }],
                  inbound_call_price: { base_price: '0.0085', current_price: '0.0085',
                                        number_type: 'local' },
                  price_unit: 'USD', url: "#{base}/v2/Voice/Numbers/+18005551234" }.to_json
      stub = stub_request(:get, "#{base}/v2/Voice/Numbers/%2B18005551234")
             .with(query: { 'OriginationNumber' => '+15551112222' })
             .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      got = client.pricing.v2.voice.numbers.fetch('+18005551234', origination_number: '+15551112222')
      expect(got).to be_a(VoiceML::PricingVoiceNumberV2)
      expect(got.origination_number).to eq('+15551112222')
      expect(got.outbound_call_prices.first.origination_prefixes).to eq(['1'])
      expect(stub).to have_been_requested
    end
  end

  describe 'Pricing v2 trunking country' do
    it 'fetches a trunking country on the default host' do
      payload = { country: 'United States', iso_country: 'US',
                  terminating_prefix_prices: [{ origination_prefixes: ['1'], destination_prefixes: ['1'],
                                                base_price: '0.013', current_price: '0.013',
                                                friendly_name: 'US' }],
                  originating_call_prices: [{ base_price: '0.0085', current_price: '0.0085',
                                              number_type: 'local' }],
                  price_unit: 'USD', url: "#{base}/v2/Trunking/Countries/US" }.to_json
      stub = stub_request(:get, "#{base}/v2/Trunking/Countries/US")
             .to_return(status: 200, body: payload, headers: { 'Content-Type' => 'application/json' })

      got = client.pricing.v2.trunking.countries.fetch('US')
      expect(got).to be_a(VoiceML::PricingTrunkingCountry)
      expect(got.terminating_prefix_prices.first.friendly_name).to eq('US')
      expect(stub).to have_been_requested
    end
  end

  describe 'Pricing v1 messaging countries list' do
    it 'lists on the default host and returns an empty envelope' do
      stub = stub_request(:get, "#{base}/v1/Messaging/Countries")
             .to_return(status: 200, body: { countries: [], meta: { page: 0 } }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      listed = client.pricing.v1.messaging.countries.list
      expect(listed.countries).to eq([])
      expect(stub).to have_been_requested
    end
  end
end

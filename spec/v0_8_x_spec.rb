# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'VoiceML v0.8.x — SIP Trunking + Routes V2' do
  let(:account_sid) { 'AC' + ('f' * 32) }
  let(:api_key)     { 'secret-key-1234' }
  let(:client)      { VoiceML::Client.new(account_sid: account_sid, api_key: api_key, base_url: base_url) }
  let(:base_url)    { 'https://voiceml.example.test' }

  let(:domain_sid)  { 'SD' + ('1' * 32) }
  let(:cl_sid)      { 'CL' + ('2' * 32) }
  let(:cr_sid)      { 'CR' + ('3' * 32) }
  let(:acl_sid)     { 'AL' + ('4' * 32) }
  let(:ip_sid)      { 'IP' + ('5' * 32) }
  let(:mapping_sid) { 'CL' + ('9' * 32) }
  let(:domain_name) { 'ingress.example.com' }
  let(:qq_sid)      { 'QQ' + ('0' * 32) }

  def sip_path(*parts)
    "/2010-04-01/Accounts/#{account_sid}/SIP/#{parts.join('/')}.json"
  end

  def domain_body
    { sid: domain_sid, account_sid: account_sid, domain_name: domain_name,
      api_version: '2010-04-01', friendly_name: 'ingress', secure: true,
      date_created: 'Mon, 17 Jun 2026 12:00:00 +0000',
      date_updated: 'Mon, 17 Jun 2026 12:00:00 +0000',
      uri: "/2010-04-01/Accounts/#{account_sid}/SIP/Domains/#{domain_sid}.json" }.to_json
  end

  def cl_body
    { sid: cl_sid, account_sid: account_sid, friendly_name: 'office-handsets',
      date_created: 'x', date_updated: 'x', uri: 'x' }.to_json
  end

  def cr_body
    { sid: cr_sid, account_sid: account_sid, credential_list_sid: cl_sid, username: 'alice',
      date_created: 'x', date_updated: 'x', uri: 'x' }.to_json
  end

  def acl_body
    { sid: acl_sid, account_sid: account_sid, friendly_name: 'carrier-allowlist',
      date_created: 'x', date_updated: 'x', uri: 'x' }.to_json
  end

  def ip_body
    { sid: ip_sid, account_sid: account_sid, ip_access_control_list_sid: acl_sid,
      friendly_name: 'carrier-edge-1', ip_address: '203.0.113.10', cidr_prefix_length: 32,
      date_created: 'x', date_updated: 'x', uri: 'x' }.to_json
  end

  def mapping_body
    { sid: mapping_sid, account_sid: account_sid, domain_sid: domain_sid,
      date_created: 'x', date_updated: 'x', uri: 'x' }.to_json
  end

  describe 'VoiceML::VERSION' do
    it 'reports 0.8.1' do
      expect(VoiceML::VERSION).to eq('0.8.1')
    end
  end

  describe '#sip wired on client' do
    it 'exposes sip + routes_v2 namespaces' do
      expect(client.sip).to be_a(VoiceML::SipResource)
      expect(client.sip.domains).to be_a(VoiceML::SipDomainsResource)
      expect(client.sip.credential_lists).to be_a(VoiceML::SipCredentialListsResource)
      expect(client.sip.ip_access_control_lists).to be_a(VoiceML::SipIpAccessControlListsResource)
      expect(client.routes_v2).to be_a(VoiceML::RoutesV2Resource)
      expect(client.routes_v2.sip_domains).to be_a(VoiceML::RoutesV2SipDomainsResource)
    end
  end

  describe 'SIP Domains' do
    it 'create POSTs DomainName + voice fields' do
      stub_request(:post, "#{base_url}#{sip_path('Domains')}")
        .with(body: hash_including('DomainName' => domain_name, 'VoiceUrl' => 'https://hooks/voice',
                                    'SipRegistration' => 'false'))
        .to_return(status: 200, body: domain_body, headers: { 'Content-Type' => 'application/json' })
      d = client.sip.domains.create(domain_name: domain_name, voice_url: 'https://hooks/voice',
                                     sip_registration: false)
      expect(d.sid).to eq(domain_sid)
    end

    it 'list, fetch, update, delete' do
      stub_request(:get, "#{base_url}#{sip_path('Domains')}")
        .to_return(status: 200, body: { domains: [JSON.parse(domain_body)], page: 0, page_size: 50, total: 1 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}#{sip_path('Domains', domain_sid)}")
        .to_return(status: 200, body: domain_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}#{sip_path('Domains', domain_sid)}")
        .with(body: hash_including('FriendlyName' => 'renamed'))
        .to_return(status: 200, body: domain_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}#{sip_path('Domains', domain_sid)}")
        .to_return(status: 204)

      expect(client.sip.domains.list.domains.first.sid).to eq(domain_sid)
      expect(client.sip.domains.fetch(domain_sid).sid).to eq(domain_sid)
      expect(client.sip.domains.update(domain_sid, friendly_name: 'renamed').sid).to eq(domain_sid)
      expect(client.sip.domains.delete(domain_sid)).to be_nil
    end
  end

  describe 'SIP CredentialLists + Credentials' do
    it 'create credential list' do
      stub_request(:post, "#{base_url}#{sip_path('CredentialLists')}")
        .with(body: hash_including('FriendlyName' => 'office-handsets'))
        .to_return(status: 200, body: cl_body, headers: { 'Content-Type' => 'application/json' })
      expect(client.sip.credential_lists.create(friendly_name: 'office-handsets').sid).to eq(cl_sid)
    end

    it 'nested credentials create + fetch + update + delete' do
      base = sip_path('CredentialLists', cl_sid, 'Credentials')
      stub_request(:post, "#{base_url}#{base}")
        .with(body: hash_including('Username' => 'alice', 'Password' => 'hunter2'))
        .to_return(status: 200, body: cr_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}#{sip_path('CredentialLists', cl_sid, 'Credentials', cr_sid)}")
        .to_return(status: 200, body: cr_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{base_url}#{sip_path('CredentialLists', cl_sid, 'Credentials', cr_sid)}")
        .with(body: hash_including('Password' => 'newpwd'))
        .to_return(status: 200, body: cr_body, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, "#{base_url}#{sip_path('CredentialLists', cl_sid, 'Credentials', cr_sid)}")
        .to_return(status: 204)

      expect(client.sip.credential_lists.create_credential(cl_sid, username: 'alice', password: 'hunter2').username).to eq('alice')
      expect(client.sip.credential_lists.fetch_credential(cl_sid, cr_sid).sid).to eq(cr_sid)
      client.sip.credential_lists.update_credential(cl_sid, cr_sid, password: 'newpwd')
      expect(client.sip.credential_lists.delete_credential(cl_sid, cr_sid)).to be_nil
    end
  end

  describe 'SIP IpAccessControlLists + IpAddresses' do
    it 'nested ip addresses create' do
      base = sip_path('IpAccessControlLists', acl_sid, 'IpAddresses')
      stub_request(:post, "#{base_url}#{base}")
        .with(body: hash_including('FriendlyName' => 'carrier-edge-1', 'IpAddress' => '203.0.113.10',
                                    'CidrPrefixLength' => '32'))
        .to_return(status: 200, body: ip_body, headers: { 'Content-Type' => 'application/json' })
      ip = client.sip.ip_access_control_lists.create_ip_address(acl_sid,
              friendly_name: 'carrier-edge-1', ip_address: '203.0.113.10', cidr_prefix_length: 32)
      expect(ip.sid).to eq(ip_sid)
    end
  end

  describe 'SIP Domain Auth namespaces routing' do
    it 'auth/calls/credential_list_mappings POSTs to /Auth/Calls/' do
      stub_request(:post, "#{base_url}#{sip_path('Domains', domain_sid, 'Auth', 'Calls', 'CredentialListMappings')}")
        .with(body: hash_including('CredentialListSid' => cl_sid))
        .to_return(status: 200, body: mapping_body, headers: { 'Content-Type' => 'application/json' })
      m = client.sip.domains.create_auth_calls_credential_list_mapping(domain_sid, credential_list_sid: cl_sid)
      expect(m.sid).to eq(mapping_sid)
    end

    it 'auth/registrations/credential_list_mappings POSTs to /Auth/Registrations/' do
      stub_request(:post, "#{base_url}#{sip_path('Domains', domain_sid, 'Auth', 'Registrations', 'CredentialListMappings')}")
        .with(body: hash_including('CredentialListSid' => cl_sid))
        .to_return(status: 200, body: mapping_body, headers: { 'Content-Type' => 'application/json' })
      m = client.sip.domains.create_auth_registrations_credential_list_mapping(domain_sid, credential_list_sid: cl_sid)
      expect(m.sid).to eq(mapping_sid)
    end

    it 'historical credential_list_mappings POSTs to /CredentialListMappings (no /Auth/)' do
      stub_request(:post, "#{base_url}#{sip_path('Domains', domain_sid, 'CredentialListMappings')}")
        .with(body: hash_including('CredentialListSid' => cl_sid))
        .to_return(status: 200, body: mapping_body, headers: { 'Content-Type' => 'application/json' })
      m = client.sip.domains.create_credential_list_mapping(domain_sid, credential_list_sid: cl_sid)
      expect(m.sid).to eq(mapping_sid)
    end
  end

  describe 'Routes V2 SIP Domains' do
    let(:rv_payload) do
      { sid: qq_sid, sip_domain: domain_name, account_sid: account_sid,
        friendly_name: 'ingress', voice_region: 'us1',
        url: "#{base_url}/v2/SipDomains/#{domain_name}",
        date_created: '2026-06-17T20:00:00Z', date_updated: '2026-06-17T20:00:00Z' }.to_json
    end

    it 'fetch GETs /v2/SipDomains/{name} with no account prefix' do
      stub_request(:get, "#{base_url}/v2/SipDomains/#{domain_name}")
        .to_return(status: 200, body: rv_payload, headers: { 'Content-Type' => 'application/json' })
      rv = client.routes_v2.sip_domains.fetch(domain_name)
      expect(rv.sid).to eq(qq_sid)
      expect(rv.voice_region).to eq('us1')
    end

    it 'update POSTs VoiceRegion + FriendlyName as form' do
      stub_request(:post, "#{base_url}/v2/SipDomains/#{domain_name}")
        .with(body: hash_including('VoiceRegion' => 'ie1', 'FriendlyName' => 'renamed'))
        .to_return(status: 200, body: rv_payload, headers: { 'Content-Type' => 'application/json' })
      client.routes_v2.sip_domains.update(domain_name, voice_region: 'ie1', friendly_name: 'renamed')
    end

    it 'update partial sends only VoiceRegion' do
      stub_request(:post, "#{base_url}/v2/SipDomains/#{domain_name}")
        .with(body: { 'VoiceRegion' => 'us1' })
        .to_return(status: 200, body: rv_payload, headers: { 'Content-Type' => 'application/json' })
      client.routes_v2.sip_domains.update(domain_name, voice_region: 'us1')
    end
  end
end

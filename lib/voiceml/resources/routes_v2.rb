# frozen_string_literal: true

require_relative '../models/routes_v2'

module VoiceML
  # `client.routes_v2` — Twilio routes/v2 Inbound Processing Region API.
  # Sits outside the /2010-04-01/Accounts/... namespace.
  class RoutesV2Resource
    attr_reader :sip_domains, :phone_numbers
    def initialize(transport)
      @sip_domains   = RoutesV2SipDomainsResource.new(transport)
      @phone_numbers = RoutesV2PhoneNumbersResource.new(transport)
    end
  end

  # Operations on /v2/SipDomains/{SipDomain}. Keyed by domain name; account
  # is resolved from HTTP Basic auth.
  class RoutesV2SipDomainsResource
    def initialize(transport)
      @transport = transport
    end

    def fetch(domain_name)
      RoutesV2SipDomain.from_hash(@transport.request(:get, "/v2/SipDomains/#{domain_name}"))
    end

    def update(domain_name, voice_region: nil, friendly_name: nil)
      form = {}
      form['VoiceRegion'] = voice_region unless voice_region.nil?
      form['FriendlyName'] = friendly_name unless friendly_name.nil?
      RoutesV2SipDomain.from_hash(@transport.request(:post, "/v2/SipDomains/#{domain_name}", form: form))
    end
  end

  # Operations on /v2/PhoneNumbers/{PhoneNumber}. Keyed by E.164 phone number or
  # its PN sid; account resolved from HTTP Basic auth.
  class RoutesV2PhoneNumbersResource
    def initialize(transport)
      @transport = transport
    end

    def fetch(phone_number)
      RoutesV2PhoneNumber.from_hash(@transport.request(:get, "/v2/PhoneNumbers/#{phone_number}"))
    end

    def update(phone_number, voice_region: nil, friendly_name: nil)
      form = {}
      form['VoiceRegion'] = voice_region unless voice_region.nil?
      form['FriendlyName'] = friendly_name unless friendly_name.nil?
      RoutesV2PhoneNumber.from_hash(@transport.request(:post, "/v2/PhoneNumbers/#{phone_number}", form: form))
    end
  end
end

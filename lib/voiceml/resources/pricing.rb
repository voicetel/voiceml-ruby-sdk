# frozen_string_literal: true

require_relative "base"

require_relative '../models/pricing'

module VoiceML
  # `client.pricing` — Twilio Pricing v1/v2 (pricing.twilio.com) surface.
  #
  # Read-only. Served on the default host (VoiceML has no pricing subdomain). Layout:
  #
  #   client.pricing.v1.voice.countries.list / fetch
  #   client.pricing.v1.voice.numbers.fetch
  #   client.pricing.v1.messaging.countries.list / fetch
  #   client.pricing.v1.phone_numbers.countries.list / fetch
  #   client.pricing.v2.voice.countries.list / fetch
  #   client.pricing.v2.voice.numbers.fetch
  #   client.pricing.v2.trunking.countries.list / fetch
  #   client.pricing.v2.trunking.numbers.fetch
  #
  # Every `countries.list` returns the shared PricingCountriesList envelope; `fetch`
  # returns the product-specific country/number body. Number path segments are
  # URL-encoded (E.164 `+` -> `%2B`).
  class PricingResource
    attr_reader :v1, :v2

    def initialize(transport)
      @v1 = PricingV1Resource.new(transport)
      @v2 = PricingV2Resource.new(transport)
    end
  end

  # A pricing product group exposing `.countries` and optionally `.numbers`.
  class PricingProduct
    attr_reader :countries, :numbers

    def initialize(countries, numbers = nil)
      @countries = countries
      @numbers   = numbers
    end
  end

  # `.../Countries` list + per-country fetch. `model` is the fetch body class.
  class PricingCountriesResource
    include V1Pages
    include FieldMapping
    def initialize(transport, base_path, model)
      @transport = transport
      @base      = base_path
      @model     = model
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      PricingCountriesList.new(@transport.request(:get, @base, params: params))
    end

    def fetch(iso_country)
      @model.from_hash(@transport.request(:get, "#{@base}/#{encode_path_segment(iso_country)}"))
    end
  end

  # `/v1/Voice/Numbers/{Number}` — single-number fetch.
  class PricingV1VoiceNumbersResource
    include V1Pages
    include FieldMapping
    def initialize(transport)
      @transport = transport
    end

    def fetch(number)
      PricingVoiceNumber.from_hash(
        @transport.request(:get, "/v1/Voice/Numbers/#{encode_path_segment(number)}")
      )
    end
  end

  # `/v2/Voice/Numbers/{Destination}` — origin-aware single-number fetch.
  class PricingV2VoiceNumbersResource
    include V1Pages
    include FieldMapping
    def initialize(transport)
      @transport = transport
    end

    def fetch(destination_number, origination_number: nil)
      params = {}
      params['OriginationNumber'] = origination_number unless origination_number.nil?
      PricingVoiceNumberV2.from_hash(
        @transport.request(:get, "/v2/Voice/Numbers/#{encode_path_segment(destination_number)}",
                           params: params)
      )
    end
  end

  # `/v2/Trunking/Numbers/{Destination}` — origin-aware single-number fetch.
  class PricingV2TrunkingNumbersResource
    include V1Pages
    include FieldMapping
    def initialize(transport)
      @transport = transport
    end

    def fetch(destination_number, origination_number: nil)
      params = {}
      params['OriginationNumber'] = origination_number unless origination_number.nil?
      PricingTrunkingNumber.from_hash(
        @transport.request(:get, "/v2/Trunking/Numbers/#{encode_path_segment(destination_number)}",
                           params: params)
      )
    end
  end

  # `client.pricing.v1.*` — Voice, Messaging, PhoneNumbers.
  class PricingV1Resource
    attr_reader :voice, :messaging, :phone_numbers

    def initialize(transport)
      @voice = PricingProduct.new(
        PricingCountriesResource.new(transport, '/v1/Voice/Countries', PricingVoiceCountry),
        PricingV1VoiceNumbersResource.new(transport)
      )
      @messaging = PricingProduct.new(
        PricingCountriesResource.new(transport, '/v1/Messaging/Countries', PricingMessagingCountry)
      )
      @phone_numbers = PricingProduct.new(
        PricingCountriesResource.new(transport, '/v1/PhoneNumbers/Countries', PricingPhoneNumberCountry)
      )
    end
  end

  # `client.pricing.v2.*` — Voice, Trunking.
  class PricingV2Resource
    attr_reader :voice, :trunking

    def initialize(transport)
      @voice = PricingProduct.new(
        PricingCountriesResource.new(transport, '/v2/Voice/Countries', PricingVoiceCountryV2),
        PricingV2VoiceNumbersResource.new(transport)
      )
      @trunking = PricingProduct.new(
        PricingCountriesResource.new(transport, '/v2/Trunking/Countries', PricingTrunkingCountry),
        PricingV2TrunkingNumbersResource.new(transport)
      )
    end
  end
end

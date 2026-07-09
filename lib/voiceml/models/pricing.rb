# frozen_string_literal: true

require_relative 'common'
require_relative 'voice_v1' # V1Pageable lives here; PricingCountriesList reuses the `meta` envelope

module VoiceML
  # Twilio Pricing (pricing.twilio.com) v1/v2 response models.
  #
  # VoiceML has no dedicated pricing subdomain, so these ride the default host
  # (`voiceml.voicetel.com`) under `/v1` and `/v2`. All operations are read-only GETs.
  # Every field is permissive/nullable — VoiceML is NANP-only, so a `Countries` list
  # carries exactly one entry and a `Numbers` fetch 404s for non-NANP destinations.

  # --- Price leaves ---------------------------------------------------------

  class PricingInboundCallPrice
    ATTRIBUTES = %w[base_price current_price number_type].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingOutboundCallPrice
    ATTRIBUTES = %w[base_price current_price].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingOutboundCallPriceWithOrigin
    attr_reader :origination_prefixes, :base_price, :current_price
    def initialize(attrs = {})
      @origination_prefixes = attrs['origination_prefixes'] || attrs[:origination_prefixes] || []
      @base_price    = attrs['base_price'] || attrs[:base_price]
      @current_price = attrs['current_price'] || attrs[:current_price]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingOutboundPrefixPrice
    attr_reader :prefixes, :base_price, :current_price, :friendly_name
    def initialize(attrs = {})
      @prefixes      = attrs['prefixes'] || attrs[:prefixes] || []
      @base_price    = attrs['base_price'] || attrs[:base_price]
      @current_price = attrs['current_price'] || attrs[:current_price]
      @friendly_name = attrs['friendly_name'] || attrs[:friendly_name]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingOutboundPrefixPriceWithOrigin
    attr_reader :origination_prefixes, :destination_prefixes, :base_price, :current_price, :friendly_name
    def initialize(attrs = {})
      @origination_prefixes = attrs['origination_prefixes'] || attrs[:origination_prefixes] || []
      @destination_prefixes = attrs['destination_prefixes'] || attrs[:destination_prefixes] || []
      @base_price    = attrs['base_price'] || attrs[:base_price]
      @current_price = attrs['current_price'] || attrs[:current_price]
      @friendly_name = attrs['friendly_name'] || attrs[:friendly_name]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingOutboundSMSPrice
    attr_reader :carrier, :mcc, :mnc, :prices
    def initialize(attrs = {})
      @carrier = attrs['carrier'] || attrs[:carrier]
      @mcc     = attrs['mcc'] || attrs[:mcc]
      @mnc     = attrs['mnc'] || attrs[:mnc]
      @prices  = (attrs['prices'] || attrs[:prices] || []).map { |h| PricingInboundCallPrice.from_hash(h) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingPhoneNumberPrice
    ATTRIBUTES = %w[number_type base_price current_price].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # --- Countries list envelope ----------------------------------------------

  class PricingCountryRef
    ATTRIBUTES = %w[country iso_country url].freeze
    attr_reader(*ATTRIBUTES.map(&:to_sym))
    def initialize(attrs = {})
      ATTRIBUTES.each { |f| instance_variable_set("@#{f}", attrs[f] || attrs[f.to_sym]) }
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingCountriesList
    include V1Pageable
    attr_reader :countries
    def initialize(hash = {})
      assign_meta_fields(hash)
      @countries = (hash['countries'] || []).map { |h| PricingCountryRef.from_hash(h) }
    end
  end

  # --- Pricing v1 country / number bodies -----------------------------------

  class PricingVoiceCountry
    attr_reader :country, :iso_country, :outbound_prefix_prices, :inbound_call_prices, :price_unit, :url
    def initialize(attrs = {})
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @outbound_prefix_prices =
        (attrs['outbound_prefix_prices'] || []).map { |h| PricingOutboundPrefixPrice.from_hash(h) }
      @inbound_call_prices =
        (attrs['inbound_call_prices'] || []).map { |h| PricingInboundCallPrice.from_hash(h) }
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingVoiceNumber
    attr_reader :number, :country, :iso_country, :outbound_call_price, :inbound_call_price, :price_unit, :url
    def initialize(attrs = {})
      @number      = attrs['number'] || attrs[:number]
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @outbound_call_price = PricingOutboundCallPrice.from_hash(attrs['outbound_call_price'])
      @inbound_call_price  = PricingInboundCallPrice.from_hash(attrs['inbound_call_price'])
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingMessagingCountry
    attr_reader :country, :iso_country, :outbound_sms_prices, :inbound_sms_prices, :price_unit, :url
    def initialize(attrs = {})
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @outbound_sms_prices =
        (attrs['outbound_sms_prices'] || []).map { |h| PricingOutboundSMSPrice.from_hash(h) }
      @inbound_sms_prices =
        (attrs['inbound_sms_prices'] || []).map { |h| PricingInboundCallPrice.from_hash(h) }
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingPhoneNumberCountry
    attr_reader :country, :iso_country, :phone_number_prices, :price_unit, :url
    def initialize(attrs = {})
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @phone_number_prices =
        (attrs['phone_number_prices'] || []).map { |h| PricingPhoneNumberPrice.from_hash(h) }
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  # --- Pricing v2 country / number bodies -----------------------------------

  class PricingVoiceCountryV2
    attr_reader :country, :iso_country, :outbound_prefix_prices, :inbound_call_prices, :price_unit, :url
    def initialize(attrs = {})
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @outbound_prefix_prices =
        (attrs['outbound_prefix_prices'] || []).map { |h| PricingOutboundPrefixPriceWithOrigin.from_hash(h) }
      @inbound_call_prices =
        (attrs['inbound_call_prices'] || []).map { |h| PricingInboundCallPrice.from_hash(h) }
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingVoiceNumberV2
    attr_reader :destination_number, :origination_number, :country, :iso_country,
                :outbound_call_prices, :inbound_call_price, :price_unit, :url
    def initialize(attrs = {})
      @destination_number = attrs['destination_number'] || attrs[:destination_number]
      @origination_number = attrs['origination_number'] || attrs[:origination_number]
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @outbound_call_prices =
        (attrs['outbound_call_prices'] || []).map { |h| PricingOutboundCallPriceWithOrigin.from_hash(h) }
      @inbound_call_price = PricingInboundCallPrice.from_hash(attrs['inbound_call_price'])
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingTrunkingCountry
    attr_reader :country, :iso_country, :terminating_prefix_prices, :originating_call_prices, :price_unit, :url
    def initialize(attrs = {})
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @terminating_prefix_prices =
        (attrs['terminating_prefix_prices'] || []).map { |h| PricingOutboundPrefixPriceWithOrigin.from_hash(h) }
      @originating_call_prices =
        (attrs['originating_call_prices'] || []).map { |h| PricingInboundCallPrice.from_hash(h) }
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end

  class PricingTrunkingNumber
    attr_reader :destination_number, :origination_number, :country, :iso_country,
                :terminating_prefix_prices, :originating_call_price, :price_unit, :url
    def initialize(attrs = {})
      @destination_number = attrs['destination_number'] || attrs[:destination_number]
      @origination_number = attrs['origination_number'] || attrs[:origination_number]
      @country     = attrs['country'] || attrs[:country]
      @iso_country = attrs['iso_country'] || attrs[:iso_country]
      @terminating_prefix_prices =
        (attrs['terminating_prefix_prices'] || []).map { |h| PricingOutboundPrefixPriceWithOrigin.from_hash(h) }
      @originating_call_price = PricingInboundCallPrice.from_hash(attrs['originating_call_price'])
      @price_unit = attrs['price_unit'] || attrs[:price_unit]
      @url        = attrs['url'] || attrs[:url]
    end
    def self.from_hash(h); h.nil? ? nil : new(h); end
  end
end

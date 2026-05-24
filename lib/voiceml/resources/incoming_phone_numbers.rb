# frozen_string_literal: true

require_relative 'base'
require_relative '../models/incoming_phone_numbers'

module VoiceML
  # Operations on `/IncomingPhoneNumbers` — tenant-scoped DID lookup and routing.
  #
  # Twilio-compatible: `sid` is the canonical `PN`-prefixed identifier, `phone_number` is the
  # E.164 form. The standard lookup-by-number pattern (`list(phone_number: '+1...')`
  # returning a 0-or-1-row envelope, then `get(sid)`) is supported.
  class IncomingPhoneNumbersResource < BaseResource
    LIST_FIELDS = {
      'PhoneNumber' => :phone_number,
      'Page'        => :page,
      'PageSize'    => :page_size,
      'PageToken'   => :page_token
    }.freeze

    CREATE_FIELDS = {
      'PhoneNumber'         => :phone_number,
      'VoiceUrl'            => :voice_url,
      'VoiceMethod'         => :voice_method,
      'VoiceFallbackUrl'    => :voice_fallback_url,
      'VoiceFallbackMethod' => :voice_fallback_method,
      'FriendlyName'        => :friendly_name
    }.freeze

    UPDATE_FIELDS = {
      'VoiceUrl'            => :voice_url,
      'VoiceMethod'         => :voice_method,
      'VoiceFallbackUrl'    => :voice_fallback_url,
      'VoiceFallbackMethod' => :voice_fallback_method,
      'FriendlyName'        => :friendly_name
    }.freeze

    LIST_TYPED_FIELDS = {
      'PhoneNumber'  => :phone_number,
      'FriendlyName' => :friendly_name,
      'Beta'         => :beta,
      'Origin'       => :origin,
      'Page'         => :page,
      'PageSize'     => :page_size,
      'PageToken'    => :page_token
    }.freeze

    # List DIDs assigned to the authenticated tenant.
    #
    # @param phone_number [String, nil] exact-match E.164 filter. Returns a 0-or-1-row
    #   envelope when set — the standard twilio-ruby lookup pattern.
    # @param page         [Integer, nil] 0-indexed page number.
    # @param page_size    [Integer, nil] page size (server-bounded).
    # @return [VoiceML::IncomingPhoneNumberList]
    def list(phone_number: nil, page: nil, page_size: nil)
      kwargs = { phone_number: phone_number, page: page, page_size: page_size }
      IncomingPhoneNumberList.from_hash(
        @transport.request(:get, path('IncomingPhoneNumbers'),
                           params: form_params(LIST_FIELDS, kwargs))
      )
    end

    # Assign a DID to the authenticated tenant. Idempotent re-POSTing the same
    # `phone_number:` rebinds the voice routing (matches Twilio update semantics).
    #
    # @param phone_number          [String] required. E.164 — leading `+`, 7-15 digits.
    # @param voice_url             [String, nil] inbound-voice handler URL.
    # @param voice_method          [String, nil] HTTP method for `voice_url` (`GET`/`POST`).
    # @param voice_fallback_url    [String, nil] fallback handler URL.
    # @param voice_fallback_method [String, nil] HTTP method for `voice_fallback_url`.
    # @param friendly_name         [String, nil] display label (server may ignore in v0.5.x).
    # @return [VoiceML::IncomingPhoneNumber]
    def create(phone_number:, voice_url: nil, voice_method: nil,
               voice_fallback_url: nil, voice_fallback_method: nil,
               friendly_name: nil)
      kwargs = {
        phone_number: phone_number,
        voice_url: voice_url, voice_method: voice_method,
        voice_fallback_url: voice_fallback_url,
        voice_fallback_method: voice_fallback_method,
        friendly_name: friendly_name
      }
      IncomingPhoneNumber.from_hash(
        @transport.request(:post, path('IncomingPhoneNumbers'),
                           form: form_params(CREATE_FIELDS, kwargs))
      )
    end

    # Fetch a single DID by its `PN`-prefixed sid.
    # @return [VoiceML::IncomingPhoneNumber]
    def get(sid)
      IncomingPhoneNumber.from_hash(
        @transport.request(:get, path('IncomingPhoneNumbers', sid))
      )
    end

    # Update voice routing on an assigned DID. Only set fields are touched.
    #
    # @param sid [String] the `PN`-prefixed identifier.
    # @param opts [Hash] any of `voice_url:`, `voice_method:`, `voice_fallback_url:`,
    #   `voice_fallback_method:`, `friendly_name:`.
    # @return [VoiceML::IncomingPhoneNumber]
    def update(sid, **opts)
      IncomingPhoneNumber.from_hash(
        @transport.request(:post, path('IncomingPhoneNumbers', sid),
                           form: form_params(UPDATE_FIELDS, opts))
      )
    end

    # Release a DID from the authenticated tenant. Idempotent — 204 even if already gone.
    # @return [nil]
    def delete(sid)
      @transport.request(:delete, path('IncomingPhoneNumbers', sid))
      nil
    end

    # @return [VoiceML::IncomingPhoneNumberList]
    def list_local(**kwargs)
      list_typed('Local', kwargs)
    end

    # @return [VoiceML::IncomingPhoneNumber]
    def create_local(**kwargs)
      create_typed('Local', kwargs)
    end

    # @return [VoiceML::IncomingPhoneNumberList]
    def list_mobile(**kwargs)
      list_typed('Mobile', kwargs)
    end

    # @return [VoiceML::IncomingPhoneNumber]
    def create_mobile(**kwargs)
      create_typed('Mobile', kwargs)
    end

    # @return [VoiceML::IncomingPhoneNumberList]
    def list_toll_free(**kwargs)
      list_typed('TollFree', kwargs)
    end

    # @return [VoiceML::IncomingPhoneNumber]
    def create_toll_free(**kwargs)
      create_typed('TollFree', kwargs)
    end

    private

    def list_typed(kind, kwargs)
      IncomingPhoneNumberList.from_hash(
        @transport.request(:get, path('IncomingPhoneNumbers', kind),
                           params: form_params(LIST_TYPED_FIELDS, kwargs))
      )
    end

    def create_typed(kind, kwargs)
      IncomingPhoneNumber.from_hash(
        @transport.request(:post, path('IncomingPhoneNumbers', kind),
                           form: form_params(CREATE_FIELDS, kwargs))
      )
    end
  end
end

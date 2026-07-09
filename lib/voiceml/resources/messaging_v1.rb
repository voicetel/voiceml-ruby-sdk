# frozen_string_literal: true

require_relative '../models/messaging_v1'

module VoiceML
  # `client.messaging_v1` — Twilio Messaging v1 (messaging.twilio.com/v1).
  # The whole group is routed at the messaging host (`messaging.voicetel.com`) by the
  # client, which is what disambiguates a Messaging Service (`MG...`) from a
  # Conversation Service (`IS...`) — they share the `/v1/Services` path shape.
  class MessagingV1Resource
    attr_reader :services

    def initialize(transport)
      @services = MessagingV1ServicesResource.new(transport)
    end
  end

  # Operations on `/v1/Services` at the messaging host.
  #
  # `create` / `list` / `fetch` / `delete` reuse the shared path; `update`
  # (`POST /v1/Services/{sid}`) is unique to Messaging Service.
  class MessagingV1ServicesResource
    SERVICE_FIELDS = {
      'FriendlyName' => :friendly_name,
      'InboundRequestUrl' => :inbound_request_url,
      'InboundMethod' => :inbound_method,
      'FallbackUrl' => :fallback_url,
      'FallbackMethod' => :fallback_method,
      'StatusCallback' => :status_callback,
      'StickySender' => :sticky_sender,
      'MmsConverter' => :mms_converter,
      'SmartEncoding' => :smart_encoding,
      'ScanMessageContent' => :scan_message_content,
      'FallbackToLongCode' => :fallback_to_long_code,
      'AreaCodeGeomatch' => :area_code_geomatch,
      'SynchronousValidation' => :synchronous_validation,
      'ValidityPeriod' => :validity_period,
      'Usecase' => :usecase,
      'UseInboundWebhookOnNumber' => :use_inbound_webhook_on_number
    }.freeze

    def initialize(transport)
      @transport = transport
    end

    def create(friendly_name:, **kwargs)
      kwargs[:friendly_name] = friendly_name
      MessagingService.from_hash(
        @transport.request(:post, '/v1/Services', form: build_form(kwargs))
      )
    end

    def list(page_size: nil)
      params = {}
      params['PageSize'] = page_size unless page_size.nil?
      MessagingServiceList.new(@transport.request(:get, '/v1/Services', params: params))
    end

    def fetch(sid)
      MessagingService.from_hash(@transport.request(:get, "/v1/Services/#{sid}"))
    end

    def update(sid, **kwargs)
      MessagingService.from_hash(
        @transport.request(:post, "/v1/Services/#{sid}", form: build_form(kwargs))
      )
    end

    def delete(sid)
      @transport.request(:delete, "/v1/Services/#{sid}")
      nil
    end

    private

    def build_form(kwargs)
      out = {}
      SERVICE_FIELDS.each do |wire, k|
        value = kwargs[k]
        next if value.nil?

        out[wire] = value
      end
      out
    end
  end
end

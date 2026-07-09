# frozen_string_literal: true

require 'uri'

require_relative 'transport'

module VoiceML
  # Per-product host resolution for the VoiceML API.
  #
  # Twilio splits its products across dedicated subdomains (`api.twilio.com`,
  # `conversations.twilio.com`, `messaging.twilio.com`, ...). VoiceML mirrors that
  # shape on `voicetel.com`: the Conversations product answers on
  # `conversations.voicetel.com` and the Messaging Service product on
  # `messaging.voicetel.com`, while everything else stays on the default
  # `voiceml.voicetel.com` host. Conversation Service and Messaging Service share
  # the identical `/v1/Services` path shape, so the *host* is what disambiguates
  # them on the wire.
  #
  # Given the configured `base_url` this module derives the two product hosts by
  # swapping the leftmost `voiceml` label — but only for recognised
  # `*.voicetel.com` hosts. For any other base URL (a self-hosted callBroadcast
  # instance, a test stub, a regional override) the product hosts fall back to the
  # configured host unchanged, so a single-host deployment keeps working. A caller
  # who needs Messaging Service against a custom host points `messaging_base_url`
  # (or `conversations_base_url`) at their own subdomain explicitly.
  module Hosts
    module_function

    # Swap the `voiceml` label of a `*.voicetel.com` host for `product`.
    #
    # Returns `base_url` unchanged when the host is not a `voiceml.*.voicetel.com`
    # style host (e.g. a self-hosted instance), so single-host deployments keep
    # working without special-casing.
    def derive_product_host(base_url, product)
      uri = URI.parse(base_url)
      host = uri.host
      return base_url if host.nil? || !host.end_with?('.voicetel.com')

      labels = host.split('.')
      idx = labels.index('voiceml')
      return base_url if idx.nil?

      labels[idx] = product
      uri.host = labels.join('.')
      uri.query = nil
      uri.fragment = nil
      uri.to_s
    end

    # Return `[default, messaging, conversations]` base URLs.
    #
    # Explicit overrides win; otherwise each product host is derived from
    # `base_url` (see module docstring). All three are returned without a
    # trailing slash.
    def resolve_product_base_urls(base_url, messaging_base_url: nil, conversations_base_url: nil)
      default       = Transport.strip_trailing_slashes(base_url)
      messaging     = Transport.strip_trailing_slashes(messaging_base_url || derive_product_host(default, 'messaging'))
      conversations = Transport.strip_trailing_slashes(conversations_base_url || derive_product_host(default, 'conversations'))
      [default, messaging, conversations]
    end
  end
end

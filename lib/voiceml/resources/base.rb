# frozen_string_literal: true

require 'uri'

module VoiceML
  # @api private
  # Kwarg-to-wire-name mapping shared by every resource that takes `**kwargs`.
  # Raises `ArgumentError` for kwargs outside the field map, so a typo
  # (`machine_detecton:`) fails loudly instead of being silently dropped.
  module FieldMapping
    private

    # Translate snake_case Ruby kwargs to the form/query field names the server
    # expects. `nil` values are dropped; booleans and dates are formatted inside
    # Transport.
    def form_params(map, kwargs)
      unknown = kwargs.keys - map.values
      unless unknown.empty?
        raise ArgumentError, "unknown keyword(s): #{unknown.map(&:inspect).sort.join(', ')}; " \
                             "expected one of #{map.values.map(&:inspect).sort.join(', ')}"
      end

      out = {}
      map.each do |wire_name, ruby_key|
        value = kwargs[ruby_key]
        next if value.nil?

        out[wire_name] = value
      end
      out
    end

    # Translate a snake_case kwargs subset for JSON bodies (Assistants v1 keeps
    # snake_case wire names). Same strictness as `form_params`.
    def json_params(keys, kwargs)
      unknown = kwargs.keys - keys
      unless unknown.empty?
        raise ArgumentError, "unknown keyword(s): #{unknown.map(&:inspect).sort.join(', ')}; " \
                             "expected one of #{keys.map(&:inspect).sort.join(', ')}"
      end

      out = {}
      keys.each do |key|
        value = kwargs[key]
        next if value.nil?

        out[key.to_s] = value
      end
      out
    end

    # Percent-encode one caller-supplied path segment per RFC 3986: keep the
    # unreserved set (`A-Z a-z 0-9 - . _ ~`) and encode every other byte as
    # `%XX` (UTF-8), so `+` becomes `%2B`, a space `%20`, `/` `%2F`, `?` `%3F`,
    # `#` `%23` and `%` `%25`. Applied once per segment — never to a full path.
    def encode_path_segment(segment)
      segment.to_s.b.gsub(/[^A-Za-z0-9\-._~]/) { |byte| format('%%%02X', byte.ord) }
    end

    def page_url(link, absolute: false)
      base = URI.parse(@transport.base_url)
      uri = URI.parse(link)
      raise ArgumentError, 'expected an absolute next_page_url' if absolute && !uri.absolute?

      uri = URI.join("#{base.scheme}://#{base.authority}/", link) unless uri.absolute?
      unless uri.scheme == base.scheme && uri.host == base.host && uri.port == base.port && !uri.userinfo
        raise ArgumentError, 'next page must stay on the configured product origin'
      end
      uri.to_s
    rescue URI::Error, ArgumentError => e
      raise ConnectionError.new("invalid next-page link: #{e.message}", status_code: 0)
    end
  end

  # @api private
  # Mixin holding a `Transport` reference and helpers for AccountSid-scoped pathing.
  class BaseResource
    include FieldMapping

    def initialize(transport)
      @transport = transport
    end

    # Fetch the page a list envelope links to via `next_page_uri`, verbatim:
    # the URI (path + query, resolved against the transport's base host) is
    # sent as-is, never re-synthesised from a page counter.
    #
    # @return [Object, nil] the next page's envelope (same class as the given
    #   one), or `nil` when the envelope has no next page.
    def next_page(list)
      uri = list.respond_to?(:next_page_uri) ? list.next_page_uri : nil
      return nil if uri.nil? || uri.empty?

      list.class.new(@transport.request(:get, page_url(uri)))
    end

    # A redacted dump: never includes credentials via the transport.
    def inspect
      "#<#{self.class.name}>"
    end
    alias to_s inspect

    private

    # Build a URL under `/2010-04-01/Accounts/{AccountSid}/...`. Caller passes path segments
    # (e.g. `"Calls"`, sid, `"Recordings"`). Empty segments are skipped; every segment is
    # percent-encoded as one RFC 3986 path segment.
    #
    # Every REST endpoint resolves under its `.json` form. Pass `suffix: ''` to opt out —
    # used by `.wav` audio fetches, export downloads and any caller that needs to append a
    # different extension.
    def path(*parts, suffix: '.json')
      tail = parts.compact.reject { |p| p.to_s.empty? }.map { |p| encode_path_segment(p) }.join('/')
      "/2010-04-01/Accounts/#{encode_path_segment(@transport.account_sid)}/#{tail}#{suffix}"
    end
  end

  # @api private
  # `next_page` / `each_page` support for `/v1` list envelopes, which page via
  # an absolute `meta.next_page_url` instead of a relative `next_page_uri`.
  # The URL is only followed when its scheme and host equal the resource's
  # configured base, so credentials are never sent to a third-party host.
  module V1Pages
    include FieldMapping
    # Follow `meta.next_page_url` from a list envelope.
    #
    # @return [Object, nil] the next page's envelope (same class as the given
    #   one), or `nil` when the envelope has no next page.
    def next_page(list)
      url = list.respond_to?(:next_page_url) ? list.next_page_url : nil
      return nil if url.nil? || url.empty?

      list.class.new(@transport.request(:get, page_url(url, absolute: true)))
    end

    # Yield every item of every page of a `/v1` list envelope, fetching pages
    # lazily. Returns an Enumerator when called without a block; stopping
    # early makes no further requests.
    def each_page(list, &block)
      return enum_for(:each_page, list) unless block

      page = list
      loop do
        items = v1_items(page)
        items.each(&block)
        nxt = next_page(page)
        break if nxt.nil?

        page = nxt
      end
    end

    private

    def v1_items(list)
      key = list.to_h.keys.find { |k| list.to_h[k].is_a?(Array) }
      key && list.respond_to?(key) ? list.public_send(key) : []
    end
  end
end

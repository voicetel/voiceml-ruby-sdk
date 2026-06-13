# 📞 VoiceML Ruby SDK

The official Ruby client for the [VoiceML REST API](https://voicetel.com/docs/api/v0.7/voiceml/) — Twilio-compatible outbound voice and answering-machine-detection from VoiceTel, with idiomatic snake_case kwargs, structured errors, and a Twilio-compatible wire format.

![Version](https://img.shields.io/badge/version-0.7.1.1-blue)
![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red)
![License](https://img.shields.io/badge/license-MIT-green)
![Tests](https://img.shields.io/badge/tests-65%20specs-brightgreen)
![Gem](https://img.shields.io/badge/gem-voiceml-blue)

## 📚 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quickstart](#-quickstart)
- [Authentication](#-authentication)
- [Resource Reference](#-resource-reference)
- [Error Handling](#-error-handling)
- [Pagination](#-pagination)
- [Migration from twilio-ruby](#-migration-from-twilio-ruby)
- [Rate Limits](#-rate-limits)
- [Development](#-development)
- [API Documentation](#-api-documentation)
- [Contributors](#-contributors)
- [Sponsors](#-sponsors)
- [License](#-license)

## ✨ Features

### 🧱 Idiomatic Ruby End-to-End
- **snake_case kwargs everywhere** — `to:`, `from:`, `machine_detection:`, `status_callback:` — automatically translated to Twilio's PascalCase wire field names internally.
- **Resource-style API** — `client.calls.create(...)`, `client.queues.list`, `client.messages.each` — flat, predictable, no `account(sid).calls.create(...)` chain.
- **Twilio-compatible wire shapes** — `AccountSid`, `From`, `To`, status callbacks, pagination envelopes — match what Twilio's Programmable Voice API documents, so existing Twilio client patterns map directly.

### 🔁 Production-Grade Transport
- **Automatic retry** with exponential backoff on 429 / 5xx and transport errors — honors `Retry-After` headers.
- **Configurable timeouts** per client.
- **HTTP Basic auth** with `AccountSid:ApiKey` — exactly what the Twilio Ruby SDK uses, so existing credentials work unchanged. Accepts the `auth_token:` keyword as an alias for migration-compatible drop-in.
- **Structured exception hierarchy** — `RateLimitError`, `AuthenticationError`, `NotFoundError`, etc. all subclasses of `VoiceML::ApiError` you can rescue broadly or narrowly.

### 📞 Complete API Coverage
- **Calls** — originate, fetch, terminate, update + per-call recordings, streams, siprec, transcriptions, notifications, events, and the `/Calls/{sid}/Payments` lifecycle (Pay TwiML companion).
- **Conferences** — list, fetch, end conferences, plus participants (mute / hold / kick) and conference-scoped recordings.
- **Queues** — create, list, update, delete, peek, dequeue (front or specific member).
- **Applications** — CRUD on stored TwiML + callback bundles.
- **Recordings** — account-wide list, metadata fetch, audio fetch (follows S3 redirect), delete.
- **Messages** — create, fetch, list (To/From/DateSent filters + pagination), update (Body redaction; Status=canceled), delete.
- **IncomingPhoneNumbers** — list, fetch, update.
- **Notifications** — fetch, list.
- **Diagnostics** — `/health` deep probe, OpenAPI spec.

### 🧪 Tested
- **65 specs** with mocked HTTP layer (`webmock`) covering every resource and pagination edge cases — spec drift gets caught at parse time.
- Integration smoke spec gated by env vars — safe for CI.

### 📦 Clean Distribution
- Zero codegen footprint — every byte hand-written.
- Pure-Ruby, no native extensions.
- Ships via [RubyGems](https://rubygems.org/gems/voiceml).

## 🚀 Installation

```bash
gem install voiceml
```

Or in your `Gemfile`:

```ruby
gem 'voiceml', '~> 0.7'
```

Requires Ruby 3.0 or later.

## 🏁 Quickstart

```ruby
require 'voiceml'

client = VoiceML::Client.new(
  account_sid: 'AC00000000000000000000000000000001',
  api_key:     ENV.fetch('VOICEML_API_KEY')
)

call = client.calls.create(
  to:                '+18005551234',
  from:              '+18005550000',
  url:               'https://example.com/twiml',
  machine_detection: 'DetectMessageEnd'
)

puts call.sid, call.status

client.queues.list.queues.each do |q|
  puts "#{q.friendly_name}: #{q.current_size}"
end
```

## 🔑 Authentication

Every endpoint uses **HTTP Basic** with your `AccountSid` as the username and your per-tenant API key as the password — identical to Twilio's auth shape, so credentials issued for Twilio code work here unchanged.

- **Username** = your `AccountSid` (Twilio-format `AC` + 32 hex chars).
- **Password** = your per-tenant API key (pass as `api_key:` or, for migration-compatible drop-in, `auth_token:`).

```ruby
client = VoiceML::Client.new(account_sid: 'AC...', api_key: '...')
client.diagnostics.health  # uses your AccountSid + key on every call
```

> Don't have credentials yet? See **[voicetel.com/docs/api/v0.7/voiceml/](https://voicetel.com/docs/api/v0.7/voiceml/)** for issuance and rotation.

## 🗺️ Resource Reference

| Resource | Methods | Covers |
|---|---|---|
| `client.calls` | originate, fetch, list, terminate, update | + per-call recordings, streams, siprec, transcriptions, notifications, events, payments |
| `client.conferences` | list, fetch, end | participants (mute / hold / kick), conference-scoped recordings |
| `client.queues` | create, list, update, delete | peek, dequeue (front or specific member) |
| `client.applications` | CRUD on TwiML + callback bundles | |
| `client.recordings` | account-wide list, metadata, audio fetch, delete | follows S3 redirect for audio |
| `client.messages` | create, fetch, list, update, delete | To/From/DateSent filters; Body redaction; Status=canceled |
| `client.incoming_phone_numbers` | list, fetch, update | |
| `client.notifications` | fetch, list | |
| `client.diagnostics` | `/health`, OpenAPI spec | |

Methods accept idiomatic snake_case keyword arguments — they're translated to Twilio's PascalCase wire field names internally:

```ruby
client = VoiceML::Client.new(account_sid: 'AC...', api_key: '...')

call = client.calls.create(
  to:   '+18005551234',
  from: '+18005550000',
  url:  'https://example.com/twiml'
)

# On a live call, open a Pay session:
session = client.calls.start_payment(
  call.sid,
  idempotency_key: 'order-482917',
  status_callback: 'https://example.com/pay-status'
)
puts session.sid, session.status
```

## 🚨 Error Handling

All errors inherit from `VoiceML::Error`. The `VoiceML::ApiError` family carries the HTTP status, the Twilio-compatible error code, and the parsed response body. Rescue broadly or narrowly:

| Status | Exception |
|--------|-----------|
| 400 | `BadRequestError` |
| 401 | `AuthenticationError` |
| 403 | `PermissionDeniedError` |
| 404 | `NotFoundError` |
| 409 | `ConflictError` |
| 410 | `GoneError` |
| 429 | `RateLimitError` |
| 501 | `NotImplementedAPIError` |
| 5xx | `ServerError` |
| other | `ApiError` |

```ruby
begin
  client.calls.get('CA00000000000000000000000000000aaa')
rescue VoiceML::NotFoundError => e
  warn "That call isn't on your account: #{e.message}"
rescue VoiceML::RateLimitError => e
  warn "Slow down — status #{e.status_code}, code #{e.code}"
rescue VoiceML::ApiError => e
  warn "API error #{e.status_code}: #{e.message}"
end
```

The Twilio-compatible error body (`code`, `message`, `more_info`, `status`) is parsed onto `error.code` / `error.message` with the raw payload on `error.body`.

## 📄 Pagination

List operations return a typed response with a Twilio-compatible pagination envelope (`page`, `page_size`, `next_page_uri`, `previous_page_uri`, …). For `/Calls`, `/Conferences`, `/Queues`, `/Recordings`, and `/Messages`, use the `each` helper to walk every page transparently. Block form yields each item; without a block, returns an `Enumerator`:

```ruby
# Block form — yields each Call across all pages
client.calls.each(status: 'completed', page_size: 200) do |call|
  process(call)
end

# Enumerator form — chain with Enumerable methods
recent = client.messages.each(from: '+18005550000', page_size: 200).first(50)

client.queues.each do |q|
  archive(q) if q.current_size.zero?
end
```

For other resources, page manually with `client.<resource>.list(page: n, page_size: 100)`.

## 🔁 Migration from twilio-ruby

The `account_sid` + auth-token pair `Twilio::REST::Client.new` validates in its constructor works unchanged here. The SDK accepts `auth_token:` as a Twilio-compatible alias for `api_key:`:

```ruby
# Before — twilio-ruby
require 'twilio-ruby'
client = Twilio::REST::Client.new('AC...', '<token>')

# After — voiceml (Twilio-compatible)
require 'voiceml'
client = VoiceML::Client.new(account_sid: 'AC...', auth_token: '<api-key>')
```

Method names follow the resource map above (`client.calls.create(...)`, `client.queues.list`, …) rather than twilio-ruby's `client.api.v2010.accounts(sid).calls.create(...)` chain — flatter, fewer keystrokes, same wire format on the way out.

## ⏱️ Rate Limits

VoiceML applies per-tenant rate limits at the edge. The SDK automatically retries 429 responses with `Retry-After` honored, up to `max_retries` (default `2`). To bump it:

```ruby
client = VoiceML::Client.new(
  account_sid: 'AC...',
  api_key:     '...',
  max_retries: 4,
  timeout:     60
)
```

## 🛠️ Development

```bash
git clone https://github.com/voicetel/voiceml-ruby-sdk
cd voiceml-ruby-sdk
bundle install

# Run the full spec suite (fast, no network)
bundle exec rspec

# Run a single file
bundle exec rspec spec/pagination_spec.rb

# Build the gem
gem build voiceml.gemspec
```

## 📖 API Documentation

- **Reference docs:** [voicetel.com/docs/api/v0.7/voiceml/](https://voicetel.com/docs/api/v0.7/voiceml/)
- **Validator:** [voicetel.com/voiceml/validator/](https://voicetel.com/voiceml/validator/)
- **SDK catalogue:** [voicetel.com/docs/voiceml-sdks/](https://voicetel.com/docs/voiceml-sdks/)
- **YARD comments:** every resource method carries `@param` / `@return` docs — `yard doc lib` builds them locally.

## 🙌 Contributors

- [Michael Mavroudis](https://github.com/mavroudis) — Lead Developer

Contributions welcome. Open an issue describing the change you want to make, or send a pull request against `main`.

## 💖 Sponsors

| Sponsor | Contribution |
|---------|--------------|
| [VoiceTel Communications](https://voicetel.com) | Primary development and production hosting |

## 📄 License

MIT. See [LICENSE](LICENSE) and [voicetel.com/legal/](https://voicetel.com/legal/).

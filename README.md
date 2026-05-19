# VoiceML Ruby SDK

Official Ruby SDK for the [VoiceML REST API](https://voiceml.voicetel.com) —
VoiceTel's outbound voice + AMD service with a Twilio-shaped REST surface.

The wire shape, auth model, error codes, and pagination envelope all match
Twilio's documented behaviour, so existing Twilio client patterns map directly.

## Install

```bash
gem install voiceml
```

Or in your `Gemfile`:

```ruby
gem 'voiceml', '~> 0.4'
```

Ruby 3.0 or newer is required.

## Quick start

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
```

## Authentication

VoiceML uses HTTP Basic auth:

- **Username** = your `AccountSid` (Twilio-format `AC` + 32 hex chars).
- **Password** = your per-tenant API key.

The same pair the Twilio Ruby SDK validates in its constructor — drop-in
compatible.

## Resources

The client exposes these resource groups:

| Accessor             | Endpoints                                                |
|----------------------|----------------------------------------------------------|
| `client.calls`       | `/Calls` and call-scoped sub-resources (Recordings, Streams, Siprec, Transcriptions, Notifications, Events) |
| `client.conferences` | `/Conferences`, `/Participants`, `/Recordings`           |
| `client.queues`      | `/Queues`, `/Members`                                    |
| `client.applications`| `/Applications`                                          |
| `client.recordings`  | `/Recordings` (account-scoped list + audio fetch)        |
| `client.diagnostics` | `/health`, `/openapi.json` (unauthenticated)             |

Methods accept idiomatic snake_case keyword arguments — they're translated to
Twilio's PascalCase wire field names internally.

## Errors

All errors inherit from `VoiceML::Error`. The `VoiceML::ApiError` family carries
the HTTP status, the Twilio-shape error code, and the parsed response body:

```ruby
begin
  client.calls.get('CA...')
rescue VoiceML::NotFoundError => e
  # 404 — call does not exist (or belongs to a different tenant)
  warn e.status_code, e.code, e.message
rescue VoiceML::RateLimitError => e
  # 429 — back off and retry
rescue VoiceML::ApiError => e
  # Any other non-2xx
end
```

Specific subclasses: `BadRequestError` (400), `AuthenticationError` (401),
`PermissionDeniedError` (403), `NotFoundError` (404), `ConflictError` (409),
`GoneError` (410), `RateLimitError` (429),
`NotImplementedAPIError` (501), `ServerError` (5xx).

## Retries

The transport automatically retries `429` and `5xx` responses (plus transport
errors) up to `max_retries` times with exponential backoff, honoring the
`Retry-After` header when present:

```ruby
client = VoiceML::Client.new(
  account_sid: 'AC...',
  api_key:     '...',
  max_retries: 3
)
```

## License

MIT. See `LICENSE`.

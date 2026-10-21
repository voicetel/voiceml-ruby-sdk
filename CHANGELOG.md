# Changelog

## [0.9.4] - 2026-10-21

### Added
- `voice_application_sid` / `status_callback` / `status_callback_method`
  on IncomingPhoneNumbers create and update: bind the number to an
  Application whose voice config wins over the number's own Voice*
  fields, and set the number-level lifecycle webhook for inbound calls.
- `call_delay` / `extension` / `status_callback` /
  `status_callback_method` on OutgoingCallerIds create: verification-call
  parameters (seconds to wait before placing the call, DTMF extension
  dialed after connect, and the webhook that fires with the verification
  outcome).

## [0.9.3] - 2026-10-18

### Breaking changes
- **Removed methods** for endpoints the API no longer serves (405 / error
  20004): `calls.list_streams`, `calls.get_stream`, `calls.list_siprec`,
  `calls.get_siprec`, `calls.list_transcriptions`,
  `calls.get_transcription`, and their `StreamList` / `SiprecList` /
  `TranscriptionList` models. The `start_*` / `stop_*` POST methods remain.
- **Pagination**: `each` iterators and `paginate` now follow
  `next_page_uri` (with its `PageToken`) verbatim instead of synthesising
  `Page=N`. Page-counting loops never terminated against the current API
  for Calls and Conferences, and Messages/Recordings rejected `Page>0`
  without a token. `total` and `num_pages` were removed from list
  envelopes; `start`, `end`, `first_page_uri` and `previous_page_uri`
  were added.
- **Retry policy**: non-idempotent requests (`POST`, `PATCH`) are no
  longer retried on 5xx responses or read timeouts, which could place
  duplicate calls or send duplicate messages. They are retried only on
  429 and on connection-establishment failures where the request was
  provably not sent. `GET`/`HEAD`/`PUT`/`DELETE` keep the previous
  behaviour.
- **Removed non-spec parameters**: `calls.list` no longer accepts
  `start_time_gte` / `start_time_lte` (`StartTime>=` / `StartTime<=` were
  never spec parameters); the API's documented filters are
  `start_time` / `start_time_lt` / `start_time_gt`.
- **Unknown kwargs are rejected**: resource methods now raise
  `ArgumentError` for keyword arguments outside the endpoint's parameter
  set instead of silently dropping them.
- **IncomingPhoneNumbers**: `create` / `update` no longer send
  `FriendlyName` (not settable per spec); `create_local` /
  `create_mobile` / `create_toll_free` accept only `PhoneNumber`,
  `VoiceUrl` and `VoiceMethod`.
- **Ruby floor** raised from 3.0 to 3.1 (3.0 is EOL and untested).

### Added
- 36 operations previously missing: Accounts fetch/update, Balance,
  OutgoingCallerIds (list/create/fetch/update/delete), Message Media
  (list/fetch/delete), Exports (list/download), account Transcriptions
  (list/fetch/delete), recording Transcriptions (list/fetch/delete),
  conference recording create, Usage Records (list plus the AllTime,
  Daily, LastMonth, Monthly, ThisMonth, Today, Yearly and Yesterday
  windows), SIP Registrations list, Messaging Service sender phone
  numbers (list/create/fetch/delete), and `openapi_yaml` / `openapi_yml`
  diagnostics.
- Monitor v1 Alerts: `client.monitor_alerts.list` (severity and
  date-window filters) and `.fetch`, with `each` / `next_page` over the
  `/v1` `meta` envelope.
- `messages.create_feedback(sid, outcome:)` — delivery-quality feedback
  for a Message.
- `accounts.rotate_key` — rotates the account's API key; the new key is
  returned on `VoiceML::AccountWithKey#api_key` and excluded from
  `inspect` / `to_s`.
- `VoiceML::RequestValidator` and `VoiceML.validate_request` for
  verifying `X-Twilio-Signature` webhook signatures (constant-time
  compare, default-port normalisation), plus `#signature` for computing
  them in tests.
- MMS support on `messages.create` (`media_url` repeated keys, `body`
  now optional when media is present), `ValidityPeriod` and
  `StatusCallbackMethod`.
- `sms_url` / `sms_method` / `sms_fallback_url` / `sms_fallback_method`
  / `sms_application_sid` on IncomingPhoneNumbers create and update;
  `friendly_name` / `beta` / `origin` list filters.
- `message_status_callback` / `sms_status_callback` on Applications;
  `recording_track` on recording create and `pause_behavior` on update;
  `friendly_name` filters on the SIP lists.
- `Client#next_page` / `paginate` helpers; `/v1` lists follow
  `meta.next_page_url` on the configured product host only.
- Typed `Notification` and `CallEvent` models; new response fields
  (`Recording#track`, `MessagingService#advanced_opt_out`,
  IncomingPhoneNumber `sms_*` / `subresource_uris` / `status` / `origin`
  / `emergency_*`, Application `sms_*`).

### Fixed
- **Thread safety**: a shared `Net::HTTP` connection previously served
  concurrent requests while the mutex covered only connection lookup,
  handing threads one another's responses. The whole exchange is now
  serialised per origin, one connection is kept per origin, and injected
  `http_client:` objects are never finished by the SDK.
- `Retry-After` is honoured as delta-seconds or an HTTP-date, capped at
  60 seconds; beyond the cap the rate-limit error is raised immediately
  with `retry_after` set.
- Every caller-supplied path segment is percent-encoded (`+` as `%2B`,
  space as `%20`); `?` can no longer inject a query or `../` traverse
  paths.
- Recording-audio redirects drop the Authorization header when the host
  or scheme changes and refuse https-to-http downgrades.
- `Time` values serialise as UTC ISO-8601 (previously Ruby's
  `"2026-10-17 12:00:00 UTC"` `to_s` form); `Hash` values serialise as
  JSON.
- Boolean `false` no longer decodes as `nil` in Messaging/SIP/Voice
  v1/Conversations/Pricing/Routes models.
- Network failures (`Errno::ETIMEDOUT`, `OpenSSL::SSL::SSLError`,
  `Net::WriteTimeout`, `Errno::ENETUNREACH`, URI errors) now surface as
  `VoiceML::ConnectionError` subclasses instead of leaking through
  `rescue VoiceML::Error`.
- The API key never appears in `inspect` / `to_s` output of the client,
  transport or resources.
- Diagnostics (`/health`, `/openapi*`) route through the transport (no
  credentials required or sent) and raise `ServerError` on 503 instead
  of a raw error; `health` treats `warnings` as optional.
- 2xx decode failures report "could not decode" with the cause attached
  instead of "non-JSON success response".

### Security
- Retry defaults no longer replay non-idempotent requests after
  timeouts or 5xx responses (duplicate call/SMS prevention).
- Credentials are excluded from default object inspections.

### Docs
- README rewritten against the current API: correct operation counts,
  working examples, honest credential wording (VoiceML issues its own
  credentials; Twilio-issued credentials do not work here), current
  pagination and retry descriptions, and fictional `555-0100`-range
  example numbers throughout.
- SECURITY.md supported-versions table updated to 0.9.x.

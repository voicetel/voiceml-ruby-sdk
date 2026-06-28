# frozen_string_literal: true

# Official Ruby SDK for the VoiceML REST API.
#
# VoiceML is VoiceTel's outbound voice + AMD service with a Twilio-compatible REST surface
# (`https://voiceml.voicetel.com`). The wire shape, auth model, error codes, and pagination
# envelope all match Twilio's documented behaviour — so existing Twilio client patterns
# map across.
#
# @example
#   require 'voiceml'
#
#   client = VoiceML::Client.new(account_sid: 'AC...', api_key: '...')
#   call = client.calls.create(
#     to: '+18005551234',
#     from: '+18005550000',
#     url: 'https://example.com/twiml',
#     machine_detection: 'DetectMessageEnd'
#   )
#   puts call.sid, call.status
module VoiceML
end

require_relative 'voiceml/version'
require_relative 'voiceml/errors'
require_relative 'voiceml/transport'
require_relative 'voiceml/client'

# Model-only resources — surfaces that voiceml runs as Twilio-compat stubs
# (no first-class client.* getter yet) but still need decodable Ruby classes
# for response-shape conformance and migration tooling. Resource files
# require their own models; these are the standalone ones.
require_relative 'voiceml/models/accounts'
require_relative 'voiceml/models/outgoing_caller_ids'
require_relative 'voiceml/models/media'
require_relative 'voiceml/models/notifications'
require_relative 'voiceml/models/user_defined_messages'
require_relative 'voiceml/models/assistants_v1'

# frozen_string_literal: true

require 'spec_helper'
require 'json'

# Twilio response-shape conformance tests (#330 Phase C). Mirrors the
# Go (voiceml-go-sdk@d6ac75c), Python (voiceml-python-sdk), TypeScript
# (voiceml-node-sdk@a11b0a1), Java (voiceml-java-sdk@9178659), C#
# (voiceml-csharp-sdk@087679f), and PHP (voiceml-php-sdk@4267511)
# harnesses: load every canonical Twilio response example from
# callBroadcast's cmd/twilio-conformance-fixtures, run each through
# the matching SDK model's `from_hash()` factory, and assert the
# key fields (sid, account_sid, call_sid, or uri envelope) that
# downstream consumers depend on.
#
# SKIPPED unless VOICEML_CONFORMANCE_FIXTURES env points at the corpus.
#
# Ruby has no compile-time types, so the "strictness" here is purely
# the post-decode assertions on the model's attr_reader values. A
# nil/empty sid trips immediately. The cycle is `Klass.from_hash(...)`
# then `instance.sid`; the SDK's exception surface (NoMethodError on
# nil-cascade, KeyError on missing wrapper key) catches model
# structural breakage.
#
# Every operation_id in the corpus must map to a model — there is no
# SKIP_OPS list. Compat-stub resources (notifications/events/UDM) get
# decoded into permissive but typed model classes; their conformance
# proves the wire shape parses cleanly even when voiceml doesn't yet
# emit those resources from runtime endpoints.
#
# Run:
#
#   VOICEML_CONFORMANCE_FIXTURES=/path/to/callBroadcast/cmd/twilio-conformance-fixtures/fixtures \
#     bundle exec rspec spec/conformance_spec.rb

FIXTURES_ENV = 'VOICEML_CONFORMANCE_FIXTURES'

# Operation-id → [model_class, required_field_list].
#
# Singular-resource ops assert sid (+ account_sid where Twilio's shape
# includes it). List ops assert the envelope-level `uri` only — empty
# *Empty fixtures legitimately have a zero-length items array, so
# inner-item checks would false-positive on those.
#
# Some Twilio operations collapse to the same model: e.g. the
# Local/Mobile/TollFree IncomingPhoneNumber variants share the same
# response shape, and FetchTranscription / FetchRecordingTranscription /
# CreateRealtimeTranscription all decode through CallTranscription
# (overlapping sid+account_sid+uri fields; non-overlapping fields land
# as nil via the ATTRIBUTES list). The four `/Auth/*` SIP mapping list
# endpoints share a generic `contents` envelope key, distinct from the
# two legacy mapping list envelopes.
CONFORMANCE_TARGETS = {
  'FetchAccount' => [VoiceML::Account, %w[sid]],
  'UpdateAccount' => [VoiceML::Account, %w[sid]],
  'FetchBalance' => [VoiceML::Balance, %w[account_sid]],

  'CreateCall' => [VoiceML::Call, %w[sid account_sid]],
  'FetchCall' => [VoiceML::Call, %w[sid account_sid]],
  'UpdateCall' => [VoiceML::Call, %w[sid account_sid]],
  'ListCall' => [VoiceML::CallList, %w[uri]],

  'FetchConference' => [VoiceML::Conference, %w[sid account_sid]],
  'UpdateConference' => [VoiceML::Conference, %w[sid account_sid]],
  'ListConference' => [VoiceML::ConferenceList, %w[uri]],

  'CreateParticipant' => [VoiceML::Participant, %w[call_sid conference_sid]],
  'FetchParticipant' => [VoiceML::Participant, %w[call_sid conference_sid]],
  'UpdateParticipant' => [VoiceML::Participant, %w[call_sid conference_sid]],
  'ListParticipant' => [VoiceML::ParticipantList, %w[uri]],

  'CreateQueue' => [VoiceML::Queue, %w[sid account_sid]],
  'FetchQueue' => [VoiceML::Queue, %w[sid account_sid]],
  'UpdateQueue' => [VoiceML::Queue, %w[sid account_sid]],
  'ListQueue' => [VoiceML::QueueList, %w[uri]],
  'FetchMember' => [VoiceML::QueueMember, %w[call_sid]],
  'UpdateMember' => [VoiceML::QueueMember, %w[call_sid]],
  'ListMember' => [VoiceML::QueueMemberList, %w[uri]],

  'CreateApplication' => [VoiceML::Application, %w[sid account_sid]],
  'FetchApplication' => [VoiceML::Application, %w[sid account_sid]],
  'UpdateApplication' => [VoiceML::Application, %w[sid account_sid]],
  'ListApplication' => [VoiceML::ApplicationList, %w[uri]],

  'CreateCallRecording' => [VoiceML::Recording, %w[sid account_sid]],
  'FetchCallRecording' => [VoiceML::Recording, %w[sid account_sid]],
  'UpdateCallRecording' => [VoiceML::Recording, %w[sid account_sid]],
  'FetchRecording' => [VoiceML::Recording, %w[sid account_sid]],
  'FetchConferenceRecording' => [VoiceML::Recording, %w[sid account_sid]],
  'UpdateConferenceRecording' => [VoiceML::Recording, %w[sid account_sid]],
  'ListCallRecording' => [VoiceML::RecordingList, %w[uri]],
  'ListRecording' => [VoiceML::RecordingList, %w[uri]],
  'ListConferenceRecording' => [VoiceML::RecordingList, %w[uri]],

  'FetchTranscription' => [VoiceML::CallTranscription, %w[sid account_sid]],
  'FetchRecordingTranscription' => [VoiceML::CallTranscription, %w[sid account_sid]],
  'CreateRealtimeTranscription' => [VoiceML::CallTranscription, %w[sid account_sid]],
  'UpdateRealtimeTranscription' => [VoiceML::CallTranscription, %w[sid account_sid]],
  'ListTranscription' => [VoiceML::TranscriptionList, %w[uri]],
  'ListRecordingTranscription' => [VoiceML::TranscriptionList, %w[uri]],

  'CreateIncomingPhoneNumber' => [VoiceML::IncomingPhoneNumber, %w[sid account_sid]],
  'CreateIncomingPhoneNumberLocal' => [VoiceML::IncomingPhoneNumber, %w[sid account_sid]],
  'CreateIncomingPhoneNumberMobile' => [VoiceML::IncomingPhoneNumber, %w[sid account_sid]],
  'CreateIncomingPhoneNumberTollFree' => [VoiceML::IncomingPhoneNumber, %w[sid account_sid]],
  'FetchIncomingPhoneNumber' => [VoiceML::IncomingPhoneNumber, %w[sid account_sid]],
  'UpdateIncomingPhoneNumber' => [VoiceML::IncomingPhoneNumber, %w[sid account_sid]],
  'ListIncomingPhoneNumber' => [VoiceML::IncomingPhoneNumberList, %w[uri]],
  'ListIncomingPhoneNumberLocal' => [VoiceML::IncomingPhoneNumberList, %w[uri]],
  'ListIncomingPhoneNumberMobile' => [VoiceML::IncomingPhoneNumberList, %w[uri]],
  'ListIncomingPhoneNumberTollFree' => [VoiceML::IncomingPhoneNumberList, %w[uri]],

  'FetchOutgoingCallerId' => [VoiceML::OutgoingCallerId, %w[sid account_sid]],
  'UpdateOutgoingCallerId' => [VoiceML::OutgoingCallerId, %w[sid account_sid]],
  'ListOutgoingCallerId' => [VoiceML::OutgoingCallerIdList, %w[uri]],
  'CreateValidationRequest' => [VoiceML::ValidationRequest, %w[account_sid call_sid]],

  'CreateMessage' => [VoiceML::Message, %w[sid account_sid]],
  'FetchMessage' => [VoiceML::Message, %w[sid account_sid]],
  'UpdateMessage' => [VoiceML::Message, %w[sid account_sid]],
  'ListMessage' => [VoiceML::MessageList, %w[uri]],
  'FetchMedia' => [VoiceML::Media, %w[sid account_sid]],
  'ListMedia' => [VoiceML::MediaList, %w[uri]],

  # Stream / SiprecSession Create/Update fixtures don't emit api_version
  # — same drift the TS harness fixed-forward — so sid/account_sid/call_sid
  # are asserted but api_version is not.
  'CreateStream' => [VoiceML::Stream, %w[sid account_sid call_sid]],
  'UpdateStream' => [VoiceML::Stream, %w[sid account_sid call_sid]],
  'CreateSiprec' => [VoiceML::SiprecSession, %w[sid account_sid call_sid]],
  'UpdateSiprec' => [VoiceML::SiprecSession, %w[sid account_sid call_sid]],

  'CreatePayments' => [VoiceML::CallPayment, %w[sid account_sid call_sid]],
  'UpdatePayments' => [VoiceML::CallPayment, %w[sid account_sid call_sid]],

  # voiceml runs these as compat stubs; the model still decodes Twilio's
  # documented shape for round-trip migration tooling.
  'FetchCallNotification' => [VoiceML::Notification, %w[sid account_sid]],
  'FetchNotification' => [VoiceML::Notification, %w[sid account_sid]],
  'ListCallNotification' => [VoiceML::NotificationsList, %w[uri]],
  'ListNotification' => [VoiceML::NotificationsList, %w[uri]],
  'ListCallEvent' => [VoiceML::EventsList, %w[uri]],
  'CreateUserDefinedMessage' => [VoiceML::UserDefinedMessage, %w[sid account_sid]],

  # SIP Trunking — Domains, CredentialLists, Credentials, IpAccessControlLists,
  # IpAddresses, and the four mapping endpoints (legacy + /Auth/Calls/ +
  # /Auth/Registrations/). The two legacy mapping lists use distinct envelope
  # keys (`credential_list_mappings`, `ip_access_control_list_mappings`); the
  # three `/Auth/*` mapping lists share a generic `contents` envelope
  # (SipAuthMappingList).
  'CreateSipDomain' => [VoiceML::SipDomain, %w[sid account_sid]],
  'FetchSipDomain' => [VoiceML::SipDomain, %w[sid account_sid]],
  'UpdateSipDomain' => [VoiceML::SipDomain, %w[sid account_sid]],
  'ListSipDomain' => [VoiceML::SipDomainList, %w[uri]],

  'CreateSipCredentialList' => [VoiceML::SipCredentialList, %w[sid account_sid]],
  'FetchSipCredentialList' => [VoiceML::SipCredentialList, %w[sid account_sid]],
  'UpdateSipCredentialList' => [VoiceML::SipCredentialList, %w[sid account_sid]],
  'ListSipCredentialList' => [VoiceML::SipCredentialListList, %w[uri]],

  'CreateSipCredential' => [VoiceML::SipCredential, %w[sid account_sid]],
  'FetchSipCredential' => [VoiceML::SipCredential, %w[sid account_sid]],
  'UpdateSipCredential' => [VoiceML::SipCredential, %w[sid account_sid]],
  'ListSipCredential' => [VoiceML::SipCredentialListPage, %w[uri]],

  'CreateSipIpAccessControlList' => [VoiceML::SipIpAccessControlList, %w[sid account_sid]],
  'FetchSipIpAccessControlList' => [VoiceML::SipIpAccessControlList, %w[sid account_sid]],
  'UpdateSipIpAccessControlList' => [VoiceML::SipIpAccessControlList, %w[sid account_sid]],
  'ListSipIpAccessControlList' => [VoiceML::SipIpAccessControlListList, %w[uri]],

  'CreateSipIpAddress' => [VoiceML::SipIpAddress, %w[sid account_sid]],
  'FetchSipIpAddress' => [VoiceML::SipIpAddress, %w[sid account_sid]],
  'UpdateSipIpAddress' => [VoiceML::SipIpAddress, %w[sid account_sid]],
  'ListSipIpAddress' => [VoiceML::SipIpAddressList, %w[uri]],

  'CreateSipCredentialListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'FetchSipCredentialListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'ListSipCredentialListMapping' => [VoiceML::SipCredentialListMappingList, %w[uri]],

  'CreateSipIpAccessControlListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'FetchSipIpAccessControlListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'ListSipIpAccessControlListMapping' => [VoiceML::SipIpAccessControlListMappingList, %w[uri]],

  'CreateSipAuthCallsCredentialListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'FetchSipAuthCallsCredentialListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'ListSipAuthCallsCredentialListMapping' => [VoiceML::SipAuthMappingList, %w[uri]],

  'CreateSipAuthCallsIpAccessControlListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'FetchSipAuthCallsIpAccessControlListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'ListSipAuthCallsIpAccessControlListMapping' => [VoiceML::SipAuthMappingList, %w[uri]],

  'CreateSipAuthRegistrationsCredentialListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'FetchSipAuthRegistrationsCredentialListMapping' => [VoiceML::SipDomainMapping, %w[sid account_sid]],
  'ListSipAuthRegistrationsCredentialListMapping' => [VoiceML::SipAuthMappingList, %w[uri]]
}.freeze

def load_conformance_entries
  root = ENV[FIXTURES_ENV]
  return [] if root.nil? || root.empty?

  index_path = File.join(root, 'index.json')
  return [] unless File.exist?(index_path)

  entries = JSON.parse(File.read(index_path))
  entries.map do |entry|
    {
      op_id: entry['operation_id'],
      resource: entry['resource'],
      example: entry['example_name'],
      path: File.join(root, entry['file'])
    }
  end
end

RSpec.describe 'Twilio response-shape conformance' do
  entries = load_conformance_entries

  if entries.empty?
    it 'skipped when VOICEML_CONFORMANCE_FIXTURES is not set' do
      skip "#{FIXTURES_ENV} not set or index.json missing"
    end
  else
    entries.each do |entry|
      it "#{entry[:resource]}/#{entry[:op_id]}/#{entry[:example]}" do
        target = CONFORMANCE_TARGETS[entry[:op_id]]
        if target.nil?
          raise "conformance harness: no mapping for operation_id=#{entry[:op_id]} " \
                "(fixture=#{entry[:path]}). Add an entry to CONFORMANCE_TARGETS."
        end

        klass, required_fields = target
        body = JSON.parse(File.read(entry[:path]))
        instance = klass.from_hash(body)

        expect(instance).not_to be_nil, "#{klass}.from_hash returned nil"
        required_fields.each do |field|
          value = instance.public_send(field.to_sym)
          expect(value).not_to be_nil, "#{klass}.#{field} is nil"
          expect(value).not_to(eq(''), "#{klass}.#{field} is empty string")
        end
      end
    end
  end
end

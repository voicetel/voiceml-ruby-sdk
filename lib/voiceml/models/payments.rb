# frozen_string_literal: true

module VoiceML
  # A Twilio-compatible CallPayment resource — the REST companion to the
  # `<Pay>` TwiML verb.
  #
  # The response shape mirrors Twilio's deliberately-minimal payload — runtime
  # configuration (ChargeAmount, PaymentConnector, ValidCardTypes, etc.) is
  # captured server-side and not echoed back. Tenant-side BYO is binding: the
  # account must have `pay_enabled = true` AND a `stripe_secret_key` set, or
  # the call fails 403.
  class CallPayment
    ATTRIBUTES = %w[
      sid account_sid call_sid api_version
      date_created date_updated uri
    ].freeze

    attr_reader(*ATTRIBUTES.map(&:to_sym))

    def initialize(attrs = {})
      ATTRIBUTES.each do |field|
        value = attrs.key?(field) ? attrs[field] : attrs[field.to_sym]
        instance_variable_set("@#{field}", value)
      end
    end

    def self.from_hash(hash)
      return nil if hash.nil?

      new(hash)
    end
  end

  # Narrows the `BankAccountType` field on a Pay session.
  module PaymentBankAccountType
    CONSUMER_CHECKING   = 'consumer-checking'
    CONSUMER_SAVINGS    = 'consumer-savings'
    COMMERCIAL_CHECKING = 'commercial-checking'

    ALL = [CONSUMER_CHECKING, CONSUMER_SAVINGS, COMMERCIAL_CHECKING].freeze
  end

  # Narrows the `Input` field. DTMF is the only supported value today.
  module PaymentInput
    DTMF = 'dtmf'

    ALL = [DTMF].freeze
  end

  # Narrows the `PaymentMethod` field.
  module PaymentMethod
    CREDIT_CARD = 'credit-card'
    ACH_DEBIT   = 'ach-debit'

    ALL = [CREDIT_CARD, ACH_DEBIT].freeze
  end

  # Narrows the `TokenType` field.
  module PaymentTokenType
    ONE_TIME       = 'one-time'
    REUSABLE       = 'reusable'
    PAYMENT_METHOD = 'payment-method'

    ALL = [ONE_TIME, REUSABLE, PAYMENT_METHOD].freeze
  end

  # Narrows the `Capture` field on Pay-session updates — tells the runtime
  # which input the user is about to type next.
  module PaymentCapture
    PAYMENT_CARD_NUMBER         = 'payment-card-number'
    EXPIRATION_DATE             = 'expiration-date'
    SECURITY_CODE               = 'security-code'
    POSTAL_CODE                 = 'postal-code'
    BANK_ROUTING_NUMBER         = 'bank-routing-number'
    BANK_ACCOUNT_NUMBER         = 'bank-account-number'
    PAYMENT_CARD_NUMBER_MATCHER = 'payment-card-number-matcher'
    EXPIRATION_DATE_MATCHER     = 'expiration-date-matcher'
    SECURITY_CODE_MATCHER       = 'security-code-matcher'
    POSTAL_CODE_MATCHER         = 'postal-code-matcher'

    ALL = [
      PAYMENT_CARD_NUMBER, EXPIRATION_DATE, SECURITY_CODE, POSTAL_CODE,
      BANK_ROUTING_NUMBER, BANK_ACCOUNT_NUMBER,
      PAYMENT_CARD_NUMBER_MATCHER, EXPIRATION_DATE_MATCHER,
      SECURITY_CODE_MATCHER, POSTAL_CODE_MATCHER
    ].freeze
  end

  # Narrows the `Status` field on Pay-session updates.
  module PaymentSessionStatus
    COMPLETE = 'complete'
    CANCEL   = 'cancel'

    ALL = [COMPLETE, CANCEL].freeze
  end
end

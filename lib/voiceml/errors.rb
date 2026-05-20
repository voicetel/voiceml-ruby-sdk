# frozen_string_literal: true

module VoiceML
  # Base class for every error raised by this SDK. Catch `VoiceML::Error` to handle them all.
  class Error < StandardError; end

  # Raised when the client is constructed with conflicting or missing config.
  class ConfigurationError < Error; end

  # Raised when the API returns a non-2xx response.
  #
  # The Twilio-shape error body (`{ code, message, more_info, status }`) is parsed into
  # `#code`, `#message`, and `#more_info` when present, with the raw payload exposed on
  # `#body`. `#more_info` is the canonical Twilio docs URL for the error code (e.g.
  # `https://www.twilio.com/docs/errors/20404`).
  class ApiError < Error
    attr_reader :status_code, :code, :body, :more_info

    def initialize(message, status_code:, code: nil, body: nil, more_info: nil)
      super(message)
      @status_code = status_code
      @code        = code
      @body        = body
      @more_info   = more_info
    end
  end

  # HTTP 400 — the request was malformed or failed server-side validation.
  class BadRequestError < ApiError; end

  # HTTP 401 — Basic auth missing, account unknown, key wrong, or source IP not allowed.
  class AuthenticationError < ApiError; end

  # HTTP 403 — authenticated, but not allowed to perform this action.
  class PermissionDeniedError < ApiError; end

  # HTTP 404 — the resource does not exist (or belongs to a different tenant).
  class NotFoundError < ApiError; end

  # HTTP 409 — request conflicts with current resource state.
  class ConflictError < ApiError; end

  # HTTP 410 — recording audio is no longer available (no local file, no S3 key).
  class GoneError < ApiError; end

  # HTTP 429 — per-account rate limit exceeded.
  class RateLimitError < ApiError; end

  # HTTP 501 — endpoint is mounted as a stub (e.g. UserDefinedMessages).
  class NotImplementedAPIError < ApiError; end

  # HTTP 5xx — the server hit an error processing the request.
  class ServerError < ApiError; end

  # @api private
  ERROR_CLASSES = {
    400 => BadRequestError,
    401 => AuthenticationError,
    403 => PermissionDeniedError,
    404 => NotFoundError,
    409 => ConflictError,
    410 => GoneError,
    429 => RateLimitError,
    501 => NotImplementedAPIError
  }.freeze

  # Map an HTTP status to the most specific `ApiError` subclass.
  # @api private
  def self.error_from_response(status_code, message, code: nil, body: nil, more_info: nil)
    klass = ERROR_CLASSES[status_code]
    klass ||= ServerError if status_code >= 500 && status_code < 600
    klass ||= ApiError
    klass.new(message, status_code: status_code, code: code, body: body, more_info: more_info)
  end
end

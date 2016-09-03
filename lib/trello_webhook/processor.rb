require 'openssl'
require 'base64'

module TrelloWebhook::Processor
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_trello_request!, only: :create
  end

  class SignatureError < StandardError; end
  class UnspecifiedWebhookSecretError < StandardError; end
  class CallbackNotImplementedError < StandardError; end

  def create
    if self.respond_to? event
      self.send event, json_body
      head(:ok)
    else
      fail CallbackNotImplementedError, "#{self.class.name}##{event} not implemented"
    end
  end

  def show
    if request.head?
      puts "[TrelloWebhook::Processor] Hook ping received"
      p request_body
      head :ok
    end
  end

  private

  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def authenticate_trello_request!
    raise UnspecifiedWebhookSecretError.new unless respond_to?(:webhook_secret)

    expected = base64digest(base64digest(request_body + request_url))
    actual = base64digest(signature_header)

    if actual != expected
      raise SignatureError.new "Actual: #{actual}, Expected: #{expected}"
    end
  end

  def base64digest(message)
    hash = OpenSSL::HMAC.digest('sha1', webhook_secret, message)
    Base64.strict_encode64(hash)
  end

  def request_body
    @request_body ||= (
      request.body.rewind
      request.body.read
    )
  end

  def request_url
    request.original_url
  end

  def json_body
    @json_body ||= ActiveSupport::HashWithIndifferentAccess.new(JSON.load(request_body))
  end

  def signature_header
    @signature_header ||= request.headers['X-Trello-Webhook']
  end

  def event
    @event ||= json_body["action"]["type"].underscore
  end
end

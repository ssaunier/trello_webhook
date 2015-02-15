module TrelloWebhook::Processor
  extend ActiveSupport::Concern

  included do
    before_filter :authenticate_trello_request!, :only => :create
  end

  class SignatureError < StandardError; end
  class UnspecifiedWebhookSecretError < StandardError; end

  def create
    if self.respond_to? event
      self.send event, json_body
      head(:ok)
    else
      raise NoMethodError.new("TrelloWebhooksController##{event} not implemented")
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

    normalized_payload = "#{request_body}#{request_url}".unpack('U*').pack('c*')
    expected_signature = Base64.strict_encode64(OpenSSL::HMAC.digest(HMAC_DIGEST, webhook_secret, normalized_payload))

    if signature_header != expected_signature
      raise SignatureError.new "Actual: #{signature_header}, Expected: #{expected_signature}"
    end
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

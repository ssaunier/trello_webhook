require 'spec_helper'

module TrelloWebhook
  describe Processor do

    class Request
      attr_accessor :headers, :body

      def initialize
        @headers = {}
        @body = StringIO.new
      end

      def original_url
        "http://foo.com"
      end
    end

    class ControllerWithoutImplementedCallback
      ### Helpers to mock ActionController::Base behavior
      attr_accessor :request, :updated

      def self.skip_before_action(*args); end
      def self.before_action(*args); end
      def head(*args); end
      ###

      include TrelloWebhook::Processor
    end

    class ControllerWithoutSecret < ControllerWithoutImplementedCallback
      def update_card(payload)
        @updated = payload[:foo]
      end
    end

    class Controller < ControllerWithoutSecret
      def webhook_secret
        "secret"
      end
    end

    let(:controller) do
      controller = Controller.new
      controller.request = Request.new
      controller
    end

    let(:controller_without_secret) do
      controller = ControllerWithoutSecret.new
      controller.request = Request.new
      controller
    end

    describe "#create" do
      it "raises an error when secret is not defined" do
        expect { controller_without_secret.send :authenticate_trello_request! }.to raise_error(Processor::UnspecifiedWebhookSecretError)
      end

      it "calls the #update_card method in controller" do
        controller.request.body = StringIO.new({ :foo => "bar", :action => { type: 'updateCard' } }.to_json.to_s)
        controller.request.headers['X-Trello-Webhook'] = "3YUv3UBpzV8IbZrOnIpRC+Cf+Nk="
        controller.send :authenticate_trello_request!  # Manually as we don't have the before_action logic in our Mock object
        controller.create
        expect(controller.updated).to eq "bar"
      end

      it "raises an error when signature does not match" do
        controller.request.body = StringIO.new({ :foo => "bar" }.to_json.to_s)
        controller.request.headers['X-Trello-Webhook'] = "thatsnotrightgeorge"
        expect { controller_without_secret.send :authenticate_trello_request! }.to raise_error(Processor::UnspecifiedWebhookSecretError)
      end

      it "raises an error when the trello event method is not implemented" do
        controller = ControllerWithoutImplementedCallback.new
        controller.request = Request.new
        controller.request.body = StringIO.new({ :foo => "bar", :action => { type: 'updateCard' } }.to_json.to_s)
        expect { controller.create }.to raise_error(Processor::CallbackNotImplementedError)
      end
    end
  end
end

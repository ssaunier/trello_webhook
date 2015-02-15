[![Build Status](https://travis-ci.org/ssaunier/trello_webhook.svg?branch=master)](https://travis-ci.org/ssaunier/trello_webhook)
[![Gem Version](https://badge.fury.io/rb/trello_webhook.svg)](http://badge.fury.io/rb/trello_webhook)


# TrelloWebhook

This gem will help you to quickly setup a route in your Rails application which listens
to a [Trello webhook](https://developer.trello.com/webhooks/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trello_webhook'
```

And then execute:

```bash
$ bundle install
```

## Configuration

First, configure a route to receive the trello webhook POST requests.

```ruby
# config/routes.rb
resource :trello_webhooks, only: :create, defaults: { formats: :json }
```

Then create a new controller:

```ruby
# app/controllers/trello_webhooks_controller.rb
class TrelloWebhooksController < ActionController::Base
  include TrelloWebhook::Processor

  def push(payload)
    # TODO: handle push webhook
  end

  def webhook_secret
    ENV['TRELLO_DEVELOPER_SECRET']  # From https://trello.com/app-key
  end
end
```

Add as many instance methods as events you want to handle in
your controller. You can read the [full list of events](https://developer.trello.com/v3/activity/events/types/) GitHub can notify you about.

## Adding the Webhook to a trello board

TODO


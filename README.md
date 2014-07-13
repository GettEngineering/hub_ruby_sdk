# HubClient

Service hub client

## Installation

Add this line to your application's Gemfile:

    gem 'hub_client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hub_client

## Usage

First let's create initializer file and configure the client:
```ruby
HubClient.configure do |config|
  config.env = "IL" # Optional
  config.endpoint_url = "http://user:pass@hub.com" # scheme://host:port
  config.access_token = "token"
end
```

To publish any message to the hub:
```ruby
HubClient.publish('message', { pay: "load"})
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/hub_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

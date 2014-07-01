module HubClient
  class Configuration
    attr_accessor :env, :access_token, :endpoint_url, :http_auth
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.reset_configuration
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
end
require "hub_client/configuration"
require "hub_client/logger"
require "hub_client/version"
require "rest-client"

module HubClient
  def self.publish(type, content)
    raise ConfigArgumentMissing, "endpoint_url missing" unless HubClient.configuration.endpoint_url
    raise ConfigArgumentMissing, "env missing" unless HubClient.configuration.env

    if HubClient.configuration.http_auth.present?
      opts = HubClient.configuration.http_auth.slice(:user, :password)
    end

    rest_resource = RestClient::Resource.new(HubClient.configuration.endpoint_url, opts)
    payload = { type: type, env: HubClient.configuration.env, content: content }
    rest_resource.post(payload) do |response, request, result|
      handle_response(response, request, result)
    end
  end

  private

  def self.handle_response(response, request, result)
    # When request didn't succeed we log it
    unless result.code.start_with?("2")
      HubClient.logger.info("Code: #{result.code} Response: #{response} Request: #{request.args}")
    end
  end

  class ConfigArgumentMissing < StandardError; end
end

require "hub_client/configuration"
require "hub_client/logger"
require "hub_client/version"
require "rest-client"

module HubClient
  def publish(type, content)
    raise ConfigArgumentMissing, "endpoint_url missing" unless HubClient.configuration.endpoint_url
    raise ConfigArgumentMissing, "env missing" unless HubClient.configuration.env

    payload = { type: type, env: HubClient.configuration.env, content: content }

    RestClient.post(HubClient.configuration.endpoint_url, payload) do |response, request, result|
      handle_response(result, request)
    end
  end

  private

  def handle_response(result, request)
    # When request didn't succeed we log it
    unless result.code.start_with?("2")
      HubClient.logger.info(request.args)
    end
  end

  class ConfigArgumentMissing < StandardError; end
end

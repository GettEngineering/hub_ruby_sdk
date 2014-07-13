require "hub_client/configuration"
require "hub_client/logger"
require "hub_client/version"
require "rest-client"

module HubClient
  def self.publish(type, content)
    raise ConfigArgumentMissing, "endpoint_url missing" unless HubClient.configuration.endpoint_url
    raise ConfigArgumentMissing, "env missing" unless HubClient.configuration.env

    payload = { type: type, env: HubClient.configuration.env, content: content.to_json }
    hub_url = build_hub_url(HubClient.configuration.endpoint_url)

    RestClient.post(hub_url, payload, content_type: :json) do |response, request, result|
      handle_response(response, request, result)
    end
  end

  private

  def self.build_hub_url(endpoint_url)
    endpoint_url = endpoint_url.gsub(/\/$/, '') # remove last '/' if exists
    "#{endpoint_url}/api/#{HUB_VERSION}/messages"
  end

  def self.handle_response(response, request, result)
    # When request didn't succeed we log it
    unless result.code.start_with?("2")
      HubClient.logger.info("HubClient Code: #{result.code} Response: #{response} Request: #{request.args}")
    end
  end

  class ConfigArgumentMissing < StandardError; end
end

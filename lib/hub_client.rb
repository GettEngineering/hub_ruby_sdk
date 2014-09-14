require "hub_client/configuration"
require "hub_client/logger"
require "hub_client/version"
require "rest-client"

module HubClient
  def self.publish(metadata, content, env = nil)
    raise ConfigArgumentMissing, "endpoint_url missing" unless HubClient.configuration.endpoint_url

    payload = (metadata.is_a?(String) || metadata.is_a?(Symbol)) ? { type: metadata.to_s } : metadata
    payload[:content] = content
    payload[:env] ||= env || payload[:env] || payload['env'] || HubClient.configuration.env

    hub_url = build_hub_url(HubClient.configuration.endpoint_url)

    RestClient.post(hub_url, payload.to_json, content_type: :json, accept: :json) do |response, request, result|
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

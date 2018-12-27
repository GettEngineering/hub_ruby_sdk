require "hub_client/exponential_backoff_interval"
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

    retry_intervals = HubClient.configuration.retry_intervals

    retries = 0
    begin
      RestClient.post(hub_url, payload.to_json, content_type: :json, accept: :json)
    rescue RestClient::Exception => e
      HubClient.logger.warn("HubClient Exception #{e.class}: #{e.message} Code: #{e.http_code} Response: #{e.response} Request: #{payload}")

      retries += 1
      sleep_interval = retry_intervals && retry_intervals.next(retries)
      raise unless sleep_interval
      Kernel.sleep(sleep_interval)
      retry
    end
  end

  private

  def self.build_hub_url(endpoint_url)
    endpoint_url = endpoint_url.gsub(/\/$/, '') # remove last '/' if exists
    "#{endpoint_url}/api/#{HUB_VERSION}/messages"
  end

  class ConfigArgumentMissing < StandardError; end
end

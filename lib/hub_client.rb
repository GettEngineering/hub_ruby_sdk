require "hub_client/exponential_backoff_interval"
require "hub_client/configuration"
require "hub_client/logger"
require "hub_client/version"
require "rest-client"

module HubClient
  REQUEST_HEADERS = {
      content_type: :json,
      accept: :json,
  }

  def self.publish(metadata, content, env = nil)
    config = HubClient.configuration
    raise ConfigArgumentMissing, "endpoint_url missing" unless config.endpoint_url

    payload = (metadata.is_a?(String) || metadata.is_a?(Symbol)) ? { type: metadata.to_s } : metadata
    payload[:content] = content
    payload[:env] ||= env || payload[:env] || payload['env'] || config.env

    retry_intervals = config.retry_intervals

    retries = 0
    begin
      RestClient::Request.execute(request_opts(config, payload))
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

  def self.encode_content_if_specified(config, payload)
    (payload[:content] = payload[:content].to_json) if config.double_encode_content && payload[:content]
    payload
  end

  def self.request_opts(config, payload)
    {
        method: :post,
        url: build_hub_url(config.endpoint_url),
        payload: encode_content_if_specified(config, payload).to_json,
        headers: REQUEST_HEADERS,
        timeout: config.timeout,
        open_timeout: config.open_timeout,
    }.reject {|_k,v| v.nil?}
  end

  def self.build_hub_url(endpoint_url)
    endpoint_url = endpoint_url.gsub(/\/$/, '') # remove last '/' if exists
    "#{endpoint_url}/api/#{HUB_VERSION}/messages"
  end

  class ConfigArgumentMissing < StandardError; end
end

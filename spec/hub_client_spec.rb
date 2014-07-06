require 'spec_helper'
require 'hub_client'

describe HubClient do
  describe "#publish" do
    context "not configured" do
      after(:each) { HubClient.reset_configuration }

      it "raises an error when endpoint_url is not configured" do
        HubClient.configure { |config| config.env = "il-qa2" }
        expect { HubClient.publish("order_created", {}) }.to raise_error(HubClient::ConfigArgumentMissing)
      end

      it "raises an error when env is not configured" do
        HubClient.configure { |config| config.endpoint_url = "service-hub.com" }
        expect { HubClient.publish("order_created", {}) }.to raise_error(HubClient::ConfigArgumentMissing)
      end
    end

    context "configured" do
      before(:all) do
        HubClient.configure do |config|
          config.env = "il-qa2"
          config.endpoint_url = "service-hub.com"
        end
      end

      it "publishes a message to hub" do
        stub_request(:post, HubClient.configuration.endpoint_url).
            with(body: { env: "il-qa2", type: "order_created", content: { some: "content" }.to_json }).
            to_return(status: 204)

        HubClient.publish(:order_created, { some: "content" })
        assert_requested :post, HubClient.configuration.endpoint_url
      end

      it "logs the request when hub didn't return success code" do
        stub_request(:post, HubClient.configuration.endpoint_url).
            with(body: { env: "il-qa2", type: "order_created", content: { some: "content" }.to_json }).
            to_return(status: 500)

        expect(HubClient.logger).to receive(:info)
        HubClient.publish(:order_created, { some: "content" })
        assert_requested :post, HubClient.configuration.endpoint_url
      end

      after(:all) { HubClient.reset_configuration }
    end
  end
end
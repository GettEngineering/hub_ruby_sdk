require 'spec_helper'
require 'hub_client'

describe HubClient do
  class DummyClass
    extend HubClient
  end

  describe "#publish" do
    context "not configured" do
      it "raises an error when endpoint_url is not configured" do
        expect { DummyClass.publish("order_created", {}) }.to raise_error(HubClient::ConfigArgumentMissing)
      end

      it "raises an error when env is not configured" do
        expect { DummyClass.publish("order_created", {}) }.to raise_error(HubClient::ConfigArgumentMissing)
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
            with(body: { env: "il-qa2", type: "order_created"}).to_return(status: 204)

        DummyClass.publish("order_created", {})
        assert_requested :post, HubClient.configuration.endpoint_url
      end

      it "logs the request when hub didn't return success code" do
        stub_request(:post, HubClient.configuration.endpoint_url).
            with(body: { env: "il-qa2", type: "order_created"}).to_return(status: 500)

        expect(HubClient.logger).to receive(:info)
        DummyClass.publish("order_created", {})
        assert_requested :post, HubClient.configuration.endpoint_url
      end

      after(:all) { HubClient.reset_configuration }
    end
  end
end
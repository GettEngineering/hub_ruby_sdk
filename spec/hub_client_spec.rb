require 'spec_helper'
require 'hub_client'

describe HubClient do
  before do
    HubClient.configure {|config| config.retry_intervals = nil}
  end

  describe "#publish" do
    context "not configured" do
      after(:each) { HubClient.reset_configuration }

      it "raises an error when endpoint_url is not configured" do
        HubClient.configure { |config| config.env = "il-qa2" }
        expect { HubClient.publish("order_created", {}) }.to raise_error(HubClient::ConfigArgumentMissing)
      end
    end

    context "configured" do
      before(:all) do
        HubClient.configure do |config|
          config.env = "il-qa2"
          config.endpoint_url = "http://service-hub.com"
        end
      end

      it "publishes a message to hub" do
        stub_request(:post, HubClient.build_hub_url(HubClient.configuration.endpoint_url)).
            with(body: { env: "il-qa2", type: "order_created", content: { some: "content" } }).
            to_return(status: 204)

        HubClient.publish(:order_created, { some: "content" })
        assert_requested :post, HubClient.build_hub_url(HubClient.configuration.endpoint_url)
      end

      it "overrides the env when supplied" do
        stub_request(:post, HubClient.build_hub_url(HubClient.configuration.endpoint_url)).
            with(body: { env: "batman-env", type: "order_created", content: { some: "content" } }).
            to_return(status: 204)

        HubClient.publish(:order_created, { some: "content" }, "batman-env")
        assert_requested :post, HubClient.build_hub_url(HubClient.configuration.endpoint_url)
      end

      it 'uses metadata if provided' do
        url = HubClient.build_hub_url(HubClient.configuration.endpoint_url)
        stub_request(:post, url)
          .with(body: {
            type: 'order_created',
            env: 'test-env',
            execute_after_sec: 60,
            content: {some: 'content'}
          }.to_json)
          .to_return(status: 204)
        HubClient.publish({
          type: 'order_created',
          env: 'test-env',
          execute_after_sec: 60
        }, {some: "content"})
        assert_requested :post, url
      end

      after(:all) { HubClient.reset_configuration }

      describe 'exception handling' do
        def action
          HubClient.publish(:order_created, { some: "content" })
        end

        def stub_publish_request
          @net_response = stub_request(:post, HubClient.build_hub_url(HubClient.configuration.endpoint_url)).
              with(body: { env: "il-qa2", type: "order_created", content: { some: "content" } })
        end

        shared_examples_for 'raises the exception' do |exception_class|
          it 'raises the exception' do
            expect {action}.to raise_error(exception_class)
          end

          it 'logs the exception' do
            logger = double('logger', warn: nil)
            allow(HubClient).to receive(:logger).and_return logger
            expect(logger).to receive(:warn).with(/#{exception_class}/)
            action rescue nil
          end
        end

        context 'when no retry_intervals is configured (default)' do
          context 'when a timeout error occurs' do
            before do
              stub_publish_request.to_timeout
            end

            it_behaves_like 'raises the exception', RestClient::RequestTimeout
          end

          context 'when a HTTP errors occurs' do
            before do
              stub_publish_request.to_return(status: 500)
            end

            it_behaves_like 'raises the exception', RestClient::InternalServerError
          end
        end

        context 'when retry_interval is configured' do
          before do
            @my_retry_interval = double('my_retry_interval')

            HubClient.configure do |config|
              config.retry_intervals = @my_retry_interval
            end
          end

          context 'when a timeout error occurs' do
            before do
              stub_publish_request.to_timeout
            end

            context 'when the retry_interval.next method returns nil' do
              before do
                allow(@my_retry_interval).to receive(:next).with(1).and_return(nil)
              end

              it_behaves_like 'raises the exception', RestClient::RequestTimeout

              it 'does not sleep' do
                expect(Kernel).not_to receive(:sleep)
                action rescue nil
              end
            end

            context 'when the retry_interval.next method returns a number' do
              before do
                expect(@my_retry_interval).to receive(:next).with(1).and_return(12)
                allow(Kernel).to receive(:sleep)
              end

              context 'and the next network call succeeds' do
                before do
                  @net_response.then.to_return({body: 'ok'})
                end

                it 'sleeps for the returned number' do
                  action
                  expect(Kernel).to have_received(:sleep).with(12).once
                end

                it 'does not raise an exception' do
                  action
                end
              end

              context 'and the next network call times out again' do
                before do
                  @net_response.then.to_timeout
                end

                context 'and the the retry_interval.next call returns nil' do
                  before do
                    expect(@my_retry_interval).to receive(:next).with(2).and_return(nil)
                  end

                  it_behaves_like 'raises the exception', RestClient::RequestTimeout
                end

                context 'and the the retry_interval.next call returns a number' do
                  before do
                    expect(@my_retry_interval).to receive(:next).with(2).and_return(13)
                  end

                  context 'and the next network call succeeds' do
                    before do
                      @net_response.then.to_return({body: 'ok'})
                    end

                    it 'sleeps for the returned number' do
                      action
                      expect(Kernel).to have_received(:sleep).with(13).once
                    end

                    it 'does not raise an exception' do
                      action
                    end
                  end
                end
              end
            end
          end

          context 'when a HTTP errors occurs' do
            before do
              stub_publish_request.to_return(status: 500)
            end

            context 'when the retry_interval.next method returns nil' do
              before do
                allow(@my_retry_interval).to receive(:next).with(1).and_return(nil)
              end

              it_behaves_like 'raises the exception', RestClient::InternalServerError

              it 'does not sleep' do
                expect(Kernel).not_to receive(:sleep)
                action rescue nil
              end
            end
          end
        end
      end
    end
  end

  describe "#build_hub_url" do
    it "returns url according to the version" do
      stub_const("HubClient::HUB_VERSION", "v10")

      expect(HubClient.send(:build_hub_url, "http://google.com")).to eq("http://google.com/api/v10/messages")
      expect(HubClient.send(:build_hub_url, "http://google.com/")).to eq("http://google.com/api/v10/messages")
    end
  end
end

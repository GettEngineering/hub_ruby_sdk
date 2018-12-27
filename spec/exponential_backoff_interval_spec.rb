require 'spec_helper'
require "hub_client/exponential_backoff_interval"

describe HubClient::ExponentialBackoffInterval do
  let(:default_opts) {described_class.const_get(:DEFAULT_OPTS)}

  describe '#next' do
    subject {described_class.new(initial: 12, max_count: 3)}

    context 'when called with 2' do
      it 'returns a correct value' do
        multiplier = default_opts[:multiplier]
        med = 12 * (multiplier ** 2)
        rand_factor = default_opts[:rand_factor]
        expect(Kernel).to receive(:rand).with(-rand_factor..rand_factor) {0.1}
        expect(subject.next(2)).to eq(med + 0.1*med)
      end
    end
  end
end

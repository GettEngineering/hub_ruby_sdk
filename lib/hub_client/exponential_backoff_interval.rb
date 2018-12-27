module HubClient
  class ExponentialBackoffInterval
    attr_accessor :initial, :multiplier, :rand_factor, :max_count

    DEFAULT_OPTS = {
        initial: 0.5,
        multiplier: 1.5,
        rand_factor: 0.05,
        max_count: 10,
    }

    def initialize(opts = {})
      opts = DEFAULT_OPTS.merge(opts)
      @initial = opts[:initial]
      @multiplier = opts[:multiplier]
      @rand_factor = opts[:rand_factor]
      @max_count = opts[:max_count]
    end

    def next(count)
      return nil if count > max_count
      result = @initial * (@multiplier ** count)
      r = Kernel.rand(-@rand_factor..@rand_factor)
      result + result * r
    end
  end
end
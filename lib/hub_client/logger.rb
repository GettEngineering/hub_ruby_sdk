module HubClient
  class Logger
    def method_missing(method_sym, *args, &block)
      if defined?(Rails)
        Rails.logger.send(method_sym, args)
      end
    end
  end

  def self.logger
    @logger ||= Logger.new
  end
end
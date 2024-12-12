module OpenAISwarm
  class Configuration
    attr_accessor :logger, :log_file

    def initialize
      @log_file = nil
      @logger = nil
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

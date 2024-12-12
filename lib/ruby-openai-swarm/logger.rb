require 'logger'
require 'fileutils'

module OpenAISwarm
  class Logger
    SEVERITY_COLORS = {
      'DEBUG' => "\e[36m", # Cyan
      'INFO'  => "\e[32m", # Green
      'WARN'  => "\e[33m", # Yellow
      'ERROR' => "\e[31m", # Red
      'FATAL' => "\e[35m", # Purple
      'ANY'   => "\e[0m"   # Reset color
    }.freeze

    def self.instance
      @instance ||= new
    end

    def initialize
      @loggers = {}
    end

    def logger(log_path = nil)
      return OpenAISwarm.configuration.logger if OpenAISwarm.configuration.logger
      return @loggers[log_path] if @loggers[log_path]

      path = determine_log_path(log_path)
      ensure_log_directory(path)

      logger = ::Logger.new(path)
      logger.formatter = proc do |severity, datetime, progname, msg|
        color = SEVERITY_COLORS[severity] || SEVERITY_COLORS['ANY']
        reset = SEVERITY_COLORS['ANY']
        "[#{datetime}] #{color}#{severity}#{reset} OpenAISwarm: #{msg}\n"
      end

      @loggers[log_path] = logger
    end

    private

    def determine_log_path(log_path)
      return log_path if log_path
      return OpenAISwarm.configuration.log_file if OpenAISwarm.configuration.log_file

      if defined?(Rails)
        Rails.root.join('log', "#{Rails.env}.log").to_s
      else
        'log/openai_swarm.log'
      end
    end

    def ensure_log_directory(path)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
    end
  end
end

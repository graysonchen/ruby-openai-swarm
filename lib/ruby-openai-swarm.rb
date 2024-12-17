require 'ruby-openai-swarm/version'
require 'ruby-openai-swarm/core_ext'
require 'ruby-openai-swarm/agent'
require 'ruby-openai-swarm/agent_change_tracker'
require 'ruby-openai-swarm/response'
require 'ruby-openai-swarm/result'
require 'ruby-openai-swarm/util'
require 'ruby-openai-swarm/core'
require 'ruby-openai-swarm/function_descriptor'
require 'ruby-openai-swarm/repl'
require 'ruby-openai-swarm/configuration'
require 'ruby-openai-swarm/logger'

module OpenAISwarm
  class Error < StandardError;
    attr_reader :details
    def initialize(message, details = {})
      @details = details
      super(message)
    end
  end

  class << self
    def new(client = nil)
      Core.new(client)
    end
  end
end

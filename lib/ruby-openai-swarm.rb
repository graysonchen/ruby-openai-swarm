require 'ruby-openai-swarm/version'
require 'ruby-openai-swarm/core_ext'
require 'ruby-openai-swarm/agent'
require 'ruby-openai-swarm/agents/change_tracker'
require 'ruby-openai-swarm/agents/strategy_options'
require 'ruby-openai-swarm/response'
require 'ruby-openai-swarm/result'
require 'ruby-openai-swarm/util'
require 'ruby-openai-swarm/core'
require 'ruby-openai-swarm/function_descriptor'
require 'ruby-openai-swarm/repl'
require 'ruby-openai-swarm/configuration'
require 'ruby-openai-swarm/logger'
require 'ruby-openai-swarm/memory'
require 'ruby-openai-swarm/memories/entity_store'
require 'ruby-openai-swarm/memories/core_memory_function'
require 'ruby-openai-swarm/memories/field'


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

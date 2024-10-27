require 'ruby-openai-swarm/version'
require 'ruby-openai-swarm/agent'
require 'ruby-openai-swarm/response'
require 'ruby-openai-swarm/result'
require 'ruby-openai-swarm/util'
require 'ruby-openai-swarm/core'
require 'ruby-openai-swarm/function_descriptor'
require 'ruby-openai-swarm/repl'

module OpenAISwarm
  class Error < StandardError; end

  class << self
    def new(client = nil)
      Core.new(client)
    end
  end
end

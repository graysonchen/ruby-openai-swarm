module OpenAISwarm
  class AgentStrategyOptions
    attr_accessor :switch_agent_reset_message

    def initialize(strategy = {})
      @switch_agent_reset_message = strategy[:switch_agent_reset_message] || false
    end
  end
end

module OpenAISwarm
  module Agents
    class StrategyOptions
      attr_accessor :switch_agent_reset_message,
                    :prevent_agent_reentry

      def initialize(strategy = {})
        @switch_agent_reset_message = strategy[:switch_agent_reset_message] || false
        # INFO:
        # 1. When `prevent_agent_reentry` is false, LLM is used to control the agent's jump.
        #    - In this case, there is a possibility of an infinite loop, so additional mechanisms (e.g., jump count limit) are needed to avoid it.
        # 2. When `prevent_agent_reentry` is true, it prevents the agent from being called again if it has already been called.
        #    - In this case, if an agent has already been called, it will not be called again.
        @prevent_agent_reentry = strategy[:prevent_agent_reentry] || false
      end
    end
  end
end

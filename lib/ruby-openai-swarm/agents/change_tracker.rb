module OpenAISwarm
  module Agents
    class ChangeTracker
      attr_reader :current_agent, :previous_agent

      def initialize(agent)
        update(agent)
      end

      def update(agent)
        @previous_agent = @current_agent
        @current_agent = agent
      end

      def agent_changed?
        previous_agent&.name != current_agent&.name
      end

      def switch_agent_reset_message?
        agent_changed? && current_agent.strategy.switch_agent_reset_message
      end
    end
  end
end

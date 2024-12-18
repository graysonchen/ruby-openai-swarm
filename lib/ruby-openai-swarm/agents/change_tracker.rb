module OpenAISwarm
  module Agents
    class ChangeTracker
      attr_reader :current_agent, :previous_agent, :tracking_agents_tool_name

      def initialize(agent)
        @tracking_agents_tool_name = []
        add_tracking_agents_tool_name(agent.current_tool_name)
        update(agent)
      end

      def update(agent)
        @previous_agent = @current_agent
        @current_agent = agent
      end

      def add_tracking_agents_tool_name(tool_name)
        return if tool_name.nil?

        @tracking_agents_tool_name << tool_name
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

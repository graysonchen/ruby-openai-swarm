module OpenAISwarm
  class AgentChangeTracker
    attr_reader :current_agent, :previous_agent

    def initialize(agent)
      update(agent)
    end

    def update(agent)
      @previous_agent = @current_agent
      @current_agent = agent
    end

    def agent_changed?
      @previous_agent&.name != @current_agent&.name
    end
  end
end

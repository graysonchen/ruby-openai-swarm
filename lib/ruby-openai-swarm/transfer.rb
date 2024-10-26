module OpenAISwarm
  class Transfer
    attr_reader :transfer_agent, :description, :transfer_name

    def initialize(transfer_agent:, description: '', transfer_name:)
      @transfer_agent = Proc.new { transfer_agent }
      @description = description
      @transfer_name = transfer_name
    end
  end
end

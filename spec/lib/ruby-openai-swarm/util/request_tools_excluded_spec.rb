require 'spec_helper'

RSpec.describe OpenAISwarm::Util do
  describe '.request_tools_excluded' do
    let(:tools) do
      [
        {
          type: "function",
          function: {
            name: :custom_analytics_agent,
            description: "Transfer to custom analytics",
            parameters: { type: "object", properties: {}, required: [] }
          }
        },
        {
          type: "function",
          function: {
            name: :conversion_funnel_analytics_agent,
            description: "Transfer to conversion funnel analytics",
            parameters: { type: "object", properties: {}, required: [] }
          }
        }
      ]
    end

    it 'returns original tools array when tool_names is empty' do
      expect(described_class.request_tools_excluded(tools, [])).to eq(tools)
    end

    it 'removes tools with matching names (string)' do
      filtered = described_class.request_tools_excluded(tools, ['custom_analytics_agent'])
      expect(filtered.length).to eq(1)
      expect(filtered[0]['function']['name'].to_s).to eq('conversion_funnel_analytics_agent')
    end

    it 'removes tools with matching names (symbol)' do
      filtered = described_class.request_tools_excluded(tools, ['custom_analytics_agent'])

      expect(filtered.length).to eq(1)
      expect(filtered[0]['function']['name'].to_s).to eq('conversion_funnel_analytics_agent')
    end

    it 'removes multiple tools' do
      filtered = described_class.request_tools_excluded(tools, ['custom_analytics_agent', 'conversion_funnel_analytics_agent'])
      expect(filtered).to eq []
    end

    it 'returns original array when no matches found' do
      filtered = described_class.request_tools_excluded(tools, ['non_existent_tool'])
      expect(filtered).to eq(described_class.symbolize_keys_to_string(tools))
    end
  end
end

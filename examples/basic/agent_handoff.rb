# link: https://github.com/openai/swarm/blob/main/examples/basic/agent_handoff.py

OpenAI.configure do |config|
  config.access_token = ENV['OPENAI_ACCESS_TOKEN']
end

client = OpenAISwarm.new

english_agent = OpenAISwarm::Agent.new(
  name: "English Agent",
  instructions: "You only speak English.",
  model: "gpt-4o-mini"
)

spanish_agent = OpenAISwarm::Agent.new(
  name: "Spanish Agent",
  instructions: "You only speak Spanish.",
  model: "gpt-4o-mini"
)

transfer_to_spanish_agent = OpenAISwarm::Transfer.new(
  transfer_agent: spanish_agent,
  transfer_name: 'transfer_to_spanish_agent',
  description: 'Transfer spanish speaking users immediately.'
)

english_agent.functions.push transfer_to_spanish_agent

messages = [{"role": "user", "content": "Hola. ¿Como estás?"}]
response = client.run(agent: english_agent, messages: messages, debug: true)

p response.messages.last
# => {"role"=>"assistant", "content"=>"¡Hola! Estoy bien, gracias. ¿Y tú?", "refusal"=>nil, :sender=>"Spanish Agent"}

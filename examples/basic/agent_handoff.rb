require_relative "../bootstrap"
# link: https://github.com/openai/swarm/blob/main/examples/basic/agent_handoff.py

client = OpenAISwarm.new

def spanish_agent
  OpenAISwarm::Agent.new(
    name: "Spanish Agent",
    instructions: "You only speak Spanish.",
    model: ENV['SWARM_AGENT_DEFAULT_MODEL']
  )
end

transfer_to_spanish_agent = OpenAISwarm::FunctionDescriptor.new(
  target_method: :spanish_agent,
  description: 'Transfer spanish speaking users immediately.'
)

english_agent = OpenAISwarm::Agent.new(
  name: "English Agent",
  instructions: "You only speak English.",
  model: ENV['SWARM_AGENT_DEFAULT_MODEL'],
  functions: [transfer_to_spanish_agent]
)

messages = [{"role": "user", "content": "Hola. ¿Como estás?"}]
response = client.run(agent: english_agent, messages: messages, debug: true)

p response.messages.last
# => {"role"=>"assistant", "content"=>"¡Hola! Estoy bien, gracias. ¿Y tú?", "refusal"=>nil, :sender=>"Spanish Agent"}

msg = response.messages.last
msg['sender'] == "Spanish Agent"

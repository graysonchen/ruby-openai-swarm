# link: https://github.com/openai/swarm/blob/main/examples/basic/agent_handoff.py

# OpenAI.configure do |config|
#   config.access_token = ENV['OPENAI_ACCESS_TOKEN']
# end

OpenAI.configure do |config|
  config.access_token = ENV['OPEN_ROUTER_ACCESS_TOKEN']
  config.uri_base = "https://openrouter.ai/api/v1"
end

client = OpenAISwarm.new

def spanish_agent
  OpenAISwarm::Agent.new(
    name: "Spanish Agent",
    instructions: "You only speak Spanish.",
    model: "gpt-4o-mini"
  )
end

transfer_to_spanish_agent = OpenAISwarm::FunctionDescriptor.new(
  target_method: :spanish_agent,
  description: 'Transfer spanish speaking users immediately.'
)

english_agent = OpenAISwarm::Agent.new(
  name: "English Agent",
  instructions: "You only speak English.",
  model: "gpt-4o-mini",
  functions: [transfer_to_spanish_agent]
)

messages = [{"role": "user", "content": "Hola. ¿Como estás?"}]
response = client.run(agent: english_agent, messages: messages, debug: true)

p response.messages.last
# => {"role"=>"assistant", "content"=>"¡Hola! Estoy bien, gracias. ¿Y tú?", "refusal"=>nil, :sender=>"Spanish Agent"}

msg = response.messages.last
msg['sender'] == "Spanish Agent"

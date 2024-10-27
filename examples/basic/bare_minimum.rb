require_relative "../bootstrap"
# link: https://github.com/openai/swarm/blob/main/examples/basic/bare_minimum.py

client = OpenAISwarm.new

agent = OpenAISwarm::Agent.new(
  name: "Agent",
  instructions: "You are a helpful agent.",
  model: "gpt-4o-mini"
)
messages = [{"role": "user", "content": "Hi!"}]
response = client.run(agent: agent, messages: messages)
p response.messages.last["content"]
#  => "Hello! How can I assist you today?"
p response.messages
# => [{"role"=>"assistant", "content"=>"Hello! How can I assist you today?", "refusal"=>nil, :sender=>"Agent"}]

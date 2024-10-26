
OpenAI.configure do |config|
  config.access_token = ENV['OPEN_ROUTER_ACCESS_TOKEN']
  config.uri_base = "https://openrouter.ai/api/v1"
end

client = OpenAISwarm.new

agent = OpenAISwarm::Agent.new(
  name: "Agent",
  instructions: "You are a helpful agent.",
  model: "gpt-4o-mini",
)

def pretty_print_messages(messages)
  messages.each do |message|
    next if message["content"].nil?
    puts "#{message["sender"]}: #{message["content"]}"
  end
end

messages = []
agent = my_agent
loop do
  print "> "
  user_input = gets.chomp

  break if user_input.downcase == "exit"

  messages << { "role": "user", "content": user_input }
  response = client.run(agent: agent, messages: messages)

  messages.concat(response.messages)
  agent = response.agent

  pretty_print_messages(response.messages)
end
puts "Goodbye!"

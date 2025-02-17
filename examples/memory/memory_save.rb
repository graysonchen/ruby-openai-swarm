require_relative "../bootstrap"

client = OpenAISwarm.new
model = ENV['SWARM_AGENT_DEFAULT_MODEL'] || "gpt-4o-mini"

memory = OpenAISwarm::Memory.new({ memory_fields: ["language", "grade", "name", "sex"] })
memory.function

def get_weather(location:)
  puts "tool call: get_weather"
  "{'temp':67, 'unit':'F'}"
end

def get_news(category:)
  puts "tool call: get_news"
  [
    "Tech Company A Acquires Startup B",
    "New AI Model Revolutionizes Industry",
    "Breakthrough in Quantum Computing"
  ].sample
end

get_news_instance = OpenAISwarm::FunctionDescriptor.new(
  target_method: :get_news,
  description: 'Get the latest news headlines. The category of news, e.g., world, business, sports.'
)

get_weather_instance = OpenAISwarm::FunctionDescriptor.new(
  target_method: :get_weather,
  description: 'Simulate fetching weather data'
)


system_prompt = "You are a helpful teaching assistant. Remember to save important information about the student using the core_memory_save function. Always greet the student by name if you know it."

chatbot_agent = OpenAISwarm::Agent.new(
  name: "teaching_assistant",
  instructions: system_prompt,
  model: model,
  functions: [
    get_weather_instance,
    get_news_instance
  ],
  memory: memory
)

messages1 = [
  {
    "role": "user",
    "content": "Hi, I'm John. I speak Chinese and I'm in Senior Year. Get the current weather in a given location. Location MUST be a city."
  }
]

puts "first call, set memory"
puts "messages: #{messages1}"

response1 = client.run(agent: chatbot_agent, messages: messages1, debug: env_debug)
puts "memory data: #{memory.entity_store.data}"
puts response1.messages.last['content']

puts ""
messages2 = [
  {"role": "user", "content": "what is my name"},
]
puts "2nd call, get memory"
puts "memory data: #{memory.entity_store.data}"
puts "messages: #{messages2}"

response2 = client.run(agent: chatbot_agent, messages: messages2, debug: env_debug)

puts response2.messages.last['content']

# memory.entity_store.data
# binding.pry

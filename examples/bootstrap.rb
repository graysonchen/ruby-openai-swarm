
def env_debug
  !!ENV['DEBUG']
end

# TODO: refactor it
OpenAI.configure do |config|
  config.access_token = ENV['OPEN_ROUTER_ACCESS_TOKEN']
  config.uri_base = "https://openrouter.ai/api/v1"
end if ENV['OPEN_ROUTER_ACCESS_TOKEN']

OpenAI.configure do |config|
  config.access_token = ENV['OPENAI_ACCESS_TOKEN']
end if ENV['OPENAI_ACCESS_TOKEN']

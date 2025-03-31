require_relative 'lib/ruby-openai-swarm/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-openai-swarm"
  spec.version       = OpenAISwarm::VERSION
  spec.authors       = ["Grayson Chen"]
  spec.email         = ["cgg5207@gmail.com"]

  spec.summary       = " A Ruby implementation of OpenAI function calling swarm"
  spec.description   = "Allows for creating swarms of AI agents that can call functions and interact with each other"
  spec.homepage      = "https://github.com/graysonchen/ruby-openai-swarm"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]
  spec.add_dependency "ruby-openai", ">= 7.3", "< 9.0"
  spec.add_dependency "ostruct"
  spec.add_dependency "activesupport"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry"
end

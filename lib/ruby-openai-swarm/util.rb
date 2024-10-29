module OpenAISwarm
  module Util
    def self.debug_print(debug, *args)
      return unless debug
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      message = args.map(&:to_s).join(' ')
      puts "\e[97m[\e[90m#{timestamp}\e[97m]\e[90m #{message}\e[0m"
    end

    def self.message_template(agent_name)
      {
        "content" => "",
        "sender" => agent_name,
        "role" => "assistant",
        "function_call" => nil,
        "tool_calls" => Hash.new do |hash, key|
          hash[key] = {
            "function" => { "arguments" => "", "name" => "" },
            "id" => "",
            "type" => ""
          }
        end
      }
    end

    def self.merge_fields(target, source)
      semantic_keyword = %W[type]
      source.each do |key, value|
        if value.is_a?(String)
          if semantic_keyword.include?(key)
            target[key] = value
          else
            target[key] += value
          end
        elsif value.is_a?(Hash) && value != nil
          merge_fields(target[key], value)
        end
      end
    end

    def self.merge_chunk(final_response, delta)
      delta.delete("role")
      merge_fields(final_response, delta)

      tool_calls = delta["tool_calls"]
      if tool_calls && !tool_calls.empty?
        index = tool_calls[0].delete("index")
        merge_fields(final_response["tool_calls"][index], tool_calls[0])
      end
    end

    def self.function_to_json(func_instance)
      is_target_method = func_instance.respond_to?(:target_method) || func_instance.is_a?(OpenAISwarm::FunctionDescriptor)
      func = is_target_method ? func_instance.target_method : func_instance

      function_name = func.name
      function_parameters = func.parameters

      type_map = {
        String => "string",
        Integer => "integer",
        Float => "number",
        TrueClass => "boolean",
        FalseClass => "boolean",
        Array => "array",
        Hash => "object",
        NilClass => "null"
      }
      parameters = {}

      function_parameters.each do |type, param_name|
        param_type = type_map[param_name.class] || "string"
        if param_name.to_s == 'context_variables' && type == :opt #type == :keyreq
          param_type = 'object'
        end
        parameters[param_name] = { type: param_type }
      end

      required = function_parameters
        .select { |type, _| [:req, :keyreq].include?(type) }
        .map { |_, name| name.to_s }

      description = func_instance.respond_to?(:description) ? func_instance&.description : nil

      {
        type: "function",
        function: {
          name: function_name,
          description: description || '',
          parameters: {
            type: "object",
            properties: parameters,
            required: required
          }
        }
      }
    end
  end
end

module OpenAISwarm
  module Util
    def self.debug_print(debug, *args)
      return unless debug
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      message = args.map(&:to_s).join(' ')
      puts "\e[97m[\e[90m#{timestamp}\e[97m]\e[90m #{message}\e[0m"
    end

    def self.symbolize_keys_to_string(obj)
      case obj
      when Hash
        obj.transform_keys(&:to_s).transform_values { |v| symbolize_keys_to_string(v) }
      when Array
        obj.map { |v| symbolize_keys_to_string(v) }
      else
        obj
      end
    end

    def self.clean_message_tools(messages, tool_names)
      return messages if tool_names.empty?
      # filtered_messages = Marshal.load(Marshal.dump(messages))

      # filtered_messages = messages.dup.map { |message| message.deep_transform_keys(&:to_s) }
      filtered_messages = symbolize_keys_to_string(messages.dup)
      # Marshal.load(Marshal.dump(messages))

      # binding.pry
      # Collect tool call IDs to be removed
      tool_call_ids_to_remove = filtered_messages
        .select { |msg| msg['tool_calls'] }
        .flat_map { |msg| msg['tool_calls'] }
        .select { |tool_call| tool_names.include?(tool_call['function']['name']) }
        .map { |tool_call| tool_call['id'] }

      # Remove specific messages
      filtered_messages.reject! do |msg|
        # Remove tool call messages for specified tool names
        (msg['role'] == 'assistant' &&
         msg['tool_calls']&.all? { |tool_call| tool_names.include?(tool_call['function']['name']) }) ||
        # Remove tool response messages for specified tool calls
        (msg['role'] == 'tool' && tool_call_ids_to_remove.include?(msg['tool_call_id']))
      end

      # If assistant message's tool_calls becomes empty, modify that message
      filtered_messages.map! do |msg|
        if msg['role'] == 'assistant' && msg['tool_calls']
          msg['tool_calls'].reject! { |tool_call| tool_names.include?(tool_call['function']['name']) }
          msg['tool_calls'] = nil if msg['tool_calls'].empty?
          msg
        else
          msg
        end
      end

      filtered_messages
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
      custom_parameters = is_target_method ? func_instance.parameters : nil

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

      json_parameters = {
        type: "object",
        properties: parameters,
        required: required
      }

      {
        type: "function",
        function: {
          name: function_name,
          description: description || '',
          parameters: custom_parameters || json_parameters
        }
      }
    end
  end
end

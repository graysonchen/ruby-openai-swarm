require 'ruby/openai'
require 'ostruct'
begin
  require 'pry'
rescue LoadError
end

module OpenAISwarm
  class Core
    include Util
    CTX_VARS_NAME = 'context_variables'

    def initialize(client = nil)
      @client = client || OpenAI::Client.new
      @logger = OpenAISwarm::Logger.instance.logger
    end

    # TODO(Grayson)
    # def create_agent(name:, model:, instructions:, **options)
    #   memory = Memory.new(@memory_fields)
    #   Agent.new(
    #     name: name,
    #     model: model,
    #     instructions: instructions,
    #     memory: memory,
    #     functions: functions,
    #     **options
    #   )
    # end

    def get_chat_completion(agent_tracker, history, context_variables, model_override, stream, debug, metadata = nil)
      agent = agent_tracker.current_agent
      context_variables = context_variables.dup
      instructions = agent.instructions.respond_to?(:call) ? agent.instructions.call(context_variables) : agent.instructions

      # Build a message history, including memories
      messages = [{ role: 'system', content: instructions }]
      messages << { role: 'system', content: agent.memory.prompt_content } unless agent&.memory&.prompt_content.nil?
      messages += history

      # Util.debug_print(debug, "Getting chat completion for...:", messages)

      tools = agent.functions.map { |f| Util.function_to_json(f) }
      # hide context_variables from model
      tools.each do |tool|
        params = tool[:function][:parameters]
        params[:properties].delete(CTX_VARS_NAME.to_sym)
        params[:required]&.delete(CTX_VARS_NAME.to_sym)
      end

      cleaned_messages = Util.clean_message_tools(messages, agent.noisy_tool_calls)

      create_params = {
        model: model_override || agent.model,
        messages: cleaned_messages,
        tools: Util.request_tools_excluded(tools, agent_tracker.tracking_agents_tool_name, agent.strategy.prevent_agent_reentry),
      }

      # Add metadata if provided
      # Add support for LiteLLM observability with Langfuse
      # See: https://docs.litellm.ai/docs/observability/langfuse_integration
      if metadata && metadata.is_a?(Hash)
        metadata_hash = metadata.deep_transform_values { |val| val.to_s.to_sym == :agent_name ? agent&.name : val }
        create_params[:metadata] = metadata_hash
      end

      # TODO: https://platform.openai.com/docs/guides/function-calling/how-do-functions-differ-from-tools
      # create_params[:functions] = tools unless tools.empty?
      # create_params[:function_call] = agent.tool_choice if agent.tool_choice

      create_params[:temperature] = agent.temperature if agent.temperature
      create_params[:tool_choice] = agent.tool_choice if agent.tool_choice
      create_params[:parallel_tool_calls] = agent.parallel_tool_calls if tools.any?

      Util.debug_print(debug, "Getting chat completion for...:", create_params)
      log_message(:info, "Getting chat completion for...:", create_params)

      if stream
        return Enumerator.new do |yielder|
          yielder << { 'parameters' => create_params }

          @client.chat(parameters: create_params.merge(
            stream: proc do |chunk, _bytesize|
              yielder << { chunk: chunk }
            end
          ))
        end
      else
        response = @client.chat(parameters: create_params)
      end

      Util.debug_print(debug, "API Response:", response)
      response
    rescue OpenAI::Error, Faraday::BadRequestError => e
      error_message = (e.response || {}).dig(:body) || e.inspect
      log_message(:error, "OpenAI API Error: #{error_message}")
      Util.debug_print(true, "OpenAI API Error:", error_message)
      raise
    end

    def handle_function_result(result, debug)
      case result
      when Result
        result
      when Agent
        Result.new(
          value: JSON.generate({ assistant: result.name }),
          agent: result
        )
      else
        begin
          Result.new(value: result.to_s)
        rescue => e
          error_message = "Failed to cast response to string: #{result}. Make sure agent functions return a string or Result object. Error: #{e}"
          Util.debug_print(debug, error_message)
          raise TypeError, error_message
        end
      end
    end

    def handle_tool_calls(tool_calls, active_agent, context_variables, debug)
      functions = active_agent.functions

      function_map = functions.map do |f|
        if f.is_a?(OpenAISwarm::FunctionDescriptor)
          [f.target_method.name, f.target_method]
        else
          [f.name, f]
        end
      end.to_h.transform_keys(&:to_s)

      partial_response = Response.new(
        messages: [],
        agent: nil,
        context_variables: {}
      )

      tool_calls.each do |tool_call|
        name = tool_call.dig('function', 'name')
        unless function_map.key?(name)
          Util.debug_print(debug, "Tool #{name} not found in function map.")
          log_message(:error, "Tool #{name} not found in function map.")
          partial_response.messages << {
            'role' => 'tool',
            'tool_call_id' => tool_call['id'],
            'tool_name' => name,
            'content' => "Error: Tool #{name} not found."
          }
          next
        end

        args = JSON.parse(tool_call.dig('function', 'arguments') || '{}')
        Util.debug_print(debug, "Processing tool call: #{name} with arguments #{args}")
        log_message(:info, "Processing tool call: #{name} with arguments #{args}")

        func = function_map[name]
        # pass context_variables to agent functions
        args[CTX_VARS_NAME] = context_variables if func.parameters.map(&:last).include?(CTX_VARS_NAME.to_sym)
        is_parameters = func.parameters.any?
        arguments = args.transform_keys(&:to_sym)

        raw_result = is_parameters ? func.call(**arguments) : func.call
        result = handle_function_result(raw_result, debug)

        partial_response.messages << {
          'role' => 'tool',
          'tool_call_id' => tool_call['id'],
          'tool_name' => name,
          'content' => result.value
        }

        partial_response.context_variables.merge!(result.context_variables)
        partial_response.agent = result.agent if result.agent
      end

      partial_response
    end

    def run(agent:, messages:, context_variables: {}, model_override: nil, stream: false, debug: false, max_turns: Float::INFINITY, execute_tools: true, metadata: nil)
      agent_tracker = OpenAISwarm::Agents::ChangeTracker.new(agent)
      if stream
        return run_and_stream(
          agent: agent,
          messages: messages,
          context_variables: context_variables,
          model_override: model_override,
          debug: debug,
          max_turns: max_turns,
          execute_tools: execute_tools,
          metadata: metadata
        )
      end

      active_agent = agent
      context_variables = context_variables.dup
      history = messages.dup
      init_len = messages.length

      while history.length - init_len < max_turns && active_agent
        agent_tracker.update(active_agent)
        history = OpenAISwarm::Util.latest_role_user_message(history) if agent_tracker.switch_agent_reset_message?

        completion = get_chat_completion(
          agent_tracker,
          history,
          context_variables,
          model_override,
          stream,
          debug,
          metadata
        )

        message = completion.dig('choices', 0, 'message') || {}
        Util.debug_print(debug, "Received completion:", message)
        log_message(:info, "Received completion:", message)

        message['sender'] = active_agent&.name
        history << message

        if !message['tool_calls'] || !execute_tools
          log_message(:info, "Ending turn.")
          break
        end

        partial_response = handle_tool_calls(
          message['tool_calls'],
          active_agent,
          context_variables,
          debug
        )

        if partial_response.agent
          agent_tool_name = message['tool_calls'].dig(0, 'function', 'name')
          agent_tracker.add_tracking_agents_tool_name(agent_tool_name)
        end

        history.concat(partial_response.messages)
        context_variables.merge!(partial_response.context_variables)
        active_agent = partial_response.agent if partial_response.agent
      end

      Response.new(
        messages: history[init_len..],
        agent: active_agent,
        context_variables: context_variables
      )
    end

    # TODO(Grayson): a lot of copied code here that will be refactored
    def run_and_stream(agent:, messages:, context_variables: {}, model_override: nil, debug: false, max_turns: Float::INFINITY, execute_tools: true, metadata: nil)
      agent_tracker = OpenAISwarm::Agents::ChangeTracker.new(agent)
      active_agent = agent
      context_variables = context_variables.dup
      history = messages.dup
      init_len = messages.length

      while history.length - init_len < max_turns && active_agent
        agent_tracker.update(active_agent)
        history = OpenAISwarm::Util.latest_role_user_message(history) if agent_tracker.switch_agent_reset_message?

        message = OpenAISwarm::Util.message_template(agent.name)
        completion = get_chat_completion(
          agent_tracker,
          history,
          context_variables,
          model_override,
          true, # stream
          debug,
          metadata
        )

        yield({ delim: "start" }) if block_given?
        completion.each do |stream|

          # TODO(Grayson): will refactor it
          if stream['parameters']
            yield({ 'parameters' => stream['parameters'], 'agent' => active_agent&.name }) if block_given?
          end
          next if stream.key?('parameters')

          chunk = stream[:chunk]
          if chunk['error']
            details = {
              'response' =>
                 Response.new(
                   messages: messages,
                   agent: active_agent,
                   context_variables: context_variables)
            }
            raise OpenAISwarm::Error.new(chunk['error'], details)
          end

          delta = chunk.dig('choices', 0, 'delta')
          if delta['role'] == "assistant"
            delta['sender'] = active_agent.name
          end

          yield({ 'delta' => delta })  if block_given?

          delta.delete('role')
          delta.delete('sender')
          Util.merge_chunk(message, delta)
        end
        yield({ delim: "end" }) if block_given?

        message['tool_calls'] = message['tool_calls'].values
        message['tool_calls'] = nil if message['tool_calls'].empty?
        Util.debug_print(debug, "Received completion:", message)
        log_message(:info, "Received completion:", message)

        history << message


        if !message['tool_calls'] || !execute_tools
          log_message(:info, "Ending turn.")
          break
        end

        # convert tool_calls to objects
        tool_calls = message['tool_calls'].map do |tool_call|
          OpenStruct.new(
            id: tool_call['id'],
            function: OpenStruct.new(
              arguments: tool_call['function']['arguments'],
              name: tool_call['function']['name']
            ),
            type: tool_call['type']
          )
        end

        partial_response = handle_tool_calls(
          tool_calls,
          active_agent,
          context_variables,
          debug
        )

        if partial_response.agent
          agent_tool_name = message['tool_calls'].dig(0, 'function', 'name')
          agent_tracker.add_tracking_agents_tool_name(agent_tool_name)
        end

        history.concat(partial_response.messages)
        context_variables.merge!(partial_response.context_variables)
        active_agent = partial_response.agent if partial_response.agent

        tool_call_messages = (Array.wrap(message) + partial_response.messages)
        yield(
          'tool_call_messages' => Response.new(
            messages: tool_call_messages,
            agent: active_agent,
            context_variables: context_variables)
        ) if block_given?
      end

      yield(
        'response' => Response.new(messages: history[init_len..],
                                   agent: active_agent,
                                   context_variables: context_variables)
      ) if block_given?
    end

    private

    def log_message(level, message, data = nil)
      return unless @logger

      log_text = message
      log_text += "\n#{data.inspect}" if data

      @logger.send(level, log_text)
    end
  end
end

require_relative '../core/client'
module Cfer::Cfn

  class Client < Cfer::Core::Client
    attr_reader :name
    attr_reader :stack

    def initialize(options)
      @name = options[:stack_name]
      options.delete :stack_name
      @cfn = Aws::CloudFormation::Client.new(options)
      flush_cache
    end

    def create_stack(*args)
      begin
        @cfn.create_stack(*args)
      rescue Aws::CloudFormation::Errors::AlreadyExistsException
        raise Cfer::Util::StackExistsError
      end
    end

    def responds_to?(method)
      @cfn.responds_to? method
    end

    def method_missing(method, *args, &block)
      @cfn.send(method, *args, &block)
    end

    def converge(stack, options = {})
      Preconditions.check(@name).is_not_nil
      Preconditions.check(stack) { is_not_nil and has_type(Cfer::Core::Stack) }

      response = validate_template(template_body: stack.to_cfn)

      create_params = []
      update_params = []

      previous_parameters =
        begin
          fetch_parameters
        rescue Cfer::Util::StackDoesNotExistError
          nil
        end

      response.parameters.each do |tmpl_param|
        input_param = stack.input_parameters[tmpl_param.parameter_key]
        old_param = previous_parameters[tmpl_param.parameter_key] if previous_parameters

        Cfer::LOGGER.debug "== Evaluating Parameter '#{tmpl_param.parameter_key.to_s}':"
        Cfer::LOGGER.debug "Input value:    #{input_param.to_s || 'nil'}"
        Cfer::LOGGER.debug "Previous value: #{old_param.to_s || 'nil'}"


        if input_param
          output_val = tmpl_param.no_echo ? '*****' : input_param
          Cfer::LOGGER.debug "Parameter #{tmpl_param.parameter_key}=#{output_val}"
          p = {
            parameter_key: tmpl_param.parameter_key,
            parameter_value: input_param,
            use_previous_value: false
          }

          create_params << p
          update_params << p
        else
          if old_param
            Cfer::LOGGER.debug "Parameter #{tmpl_param.parameter_key} is unspecified (unchanged)"
              update_params << {
              parameter_key: tmpl_param.parameter_key,
              use_previous_value: true
            }
          else
            Cfer::LOGGER.debug "Parameter #{tmpl_param.parameter_key} is unspecified (default)"
          end
        end
      end

      Cfer::LOGGER.debug "==================="

      stack_options = {
        stack_name: name,
        template_body: stack.to_cfn,
        capabilities: response.capabilities
      }

      stack_options[:on_failure] = options[:on_failure] if options[:on_failure]
      stack_options[:timeout_in_minutes] = options[:timeout] if options[:timeout]

      stack_options.merge! parse_stack_policy(:stack_policy, options[:stack_policy])
      stack_options.merge! parse_stack_policy(:stack_policy_during_update, options[:stack_policy_during_update])

      cfn_stack =
        begin
          create_stack stack_options.merge parameters: create_params
        rescue Cfer::Util::StackExistsError
          update_stack stack_options.merge parameters: update_params
        end

      flush_cache
      cfn_stack
    end

    # Yields to the given block for each CloudFormation event that qualifies, given the specified options.
    # @param options [Hash] The options hash
    # @option options [Fixnum] :number The maximum number of already-existing CloudFormation events to yield.
    # @option options [Boolean] :follow Set to true to wait until the stack enters a `COMPLETE` or `FAILED` state, yielding events as they occur.
    def tail(options = {})
      q = []
      event_id_highwater = nil
      counter = 0
      number = options[:number] || 0
      for_each_event name do |fetched_event|
        q.unshift fetched_event if counter < number
        counter = counter + 1
      end

      while q.size > 0
        event = q.shift
        yield event
        event_id_highwater = event.event_id
      end

      running = true
      if options[:follow]
        while running
          stack_status = describe_stacks(stack_name: name).stacks.first.stack_status
          running = running && (/.+_(COMPLETE|FAILED)$/.match(stack_status) == nil)

          yielding = true
          for_each_event name do |fetched_event|
            if event_id_highwater == fetched_event.event_id
              yielding = false
            end

            if yielding
              q.unshift fetched_event
            end
          end

          while q.size > 0
            event = q.shift
            yield event
            event_id_highwater = event.event_id
          end

          sleep 1 if running unless options[:no_sleep]
        end
      end
    end

    def fetch_stack(stack_name = @name)
      raise Cfer::Util::StackDoesNotExistError, 'Stack name must be specified' if stack_name == nil
      begin
        @stack_cache[stack_name] ||= describe_stacks(stack_name: stack_name).stacks.first.to_h
      rescue Aws::CloudFormation::Errors::ValidationError => e
        raise Cfer::Util::StackDoesNotExistError, e.message
      end
    end

    def fetch_parameters(stack_name = @name)
      @stack_parameters[stack_name] ||= cfn_list_to_hash('parameter', fetch_stack(stack_name)[:parameters])
    end

    def fetch_outputs(stack_name = @name)
      @stack_outputs[stack_name] ||= cfn_list_to_hash('output', fetch_stack(stack_name)[:outputs])
    end

    def fetch_output(stack_name, output_name)
      fetch_outputs(stack_name)[output_name] || raise(Cfer::Util::CferError, "Stack #{stack_name} has no output named `#{output_name}`")
    end

    def fetch_parameter(stack_name, param_name)
      fetch_parameters(stack_name)[param_name] || raise(Cfer::Util::CferError, "Stack #{stack_name} has no parameter named `#{param_name}`")
    end

    def to_h
      @stack.to_h
    end

    private

    def cfn_list_to_hash(attribute, list)
      return {} unless list

      key = :"#{attribute}_key"
      value = :"#{attribute}_value"

      HashWithIndifferentAccess[ *list.map { |kv| [ kv[key].to_s, kv[value].to_s ] }.flatten ]
    end

    def flush_cache
      Cfer::LOGGER.debug "*********** FLUSH CACHE ***************"
      Cfer::LOGGER.debug "Stack cache: #{@stack_cache}"
      Cfer::LOGGER.debug "Stack parameters: #{@stack_parameters}"
      Cfer::LOGGER.debug "Stack outputs: #{@stack_outputs}"
      Cfer::LOGGER.debug "***************************************"
      @stack_cache = {}
      @stack_parameters = {}
      @stack_outputs = {}
    end

    def for_each_event(stack_name)
      describe_stack_events(stack_name: stack_name).stack_events.each do |event|
        yield event
      end
    end

    # Validates a string as json
    #
    # @param string [String]
    def is_json?(string)
      JSON.parse(string)
      true
    rescue JSON::ParserError
      false
    end

    # Parses stack-policy-* options as an S3 URL, file to read, or JSON string
    #
    # @param name [String] Name of option: 'stack_policy' or 'stack_policy_during_update'
    # @param value [String] String containing URL, filename or JSON string
    # @return [Hash] Hash suitable for merging into options for create_stack or update_stack
    def parse_stack_policy(name, value)
      Cfer::LOGGER.debug "Using #{name} from: #{value}"
      if value.nil?
        {}
      elsif value.match(/\A#{URI::regexp(%w[http https s3])}\z/) # looks like a URL
        {"#{name}_url".to_sym => value}
      elsif File.exist?(value)                               # looks like a file to read
        {"#{name}_body".to_sym => File.read(value)}
      elsif is_json?(value)                                   # looks like a JSON string
        {"#{name}_body".to_sym => value}
      else                                                    # none of the above
        raise Cfer::Util::CferError, "Stack policy must be an S3 url, a filename, or a valid json string"
      end
    end
  end
end

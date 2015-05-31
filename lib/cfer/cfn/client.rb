module Cfer::Cfn

  class Client < Aws::CloudFormation::Client
    attr_reader :name

    attr_reader :stack_cache

    def initialize(plugins, options)
      @name = options[:stack_name]
      options.delete :stack_name
      super
    end

    def create_stack(*args)
      begin
        super.create_stack(*args)
      rescue Aws::CloudFormation::Errors::AlreadyExistsException
        raise Cfer::Util::StackExistsError
      end
    end

    def converge(stack, options = {})
      @stack_cache = {}

      Preconditions.check(stack) { is_not_nil and has_type(Cfer::Cfn::Stack) }

      response = validate_template(template_body: stack.to_cfn)
      parameters = response.parameters.map do |tmpl_param|
        input_param = stack.parameters[tmpl_param.parameter_key]
        cfn_param = input_param || (Cfer::Util::ParameterValue.new(tmpl_param.default_value) if tmpl_param.default_value)

        p = if cfn_param
          {
            ParameterKey: tmpl_param.parameter_key,
            ParameterValue: cfn_param.evaluate(self),
            UsePreviousValue: false
          }
        else
          {
            ParameterKey: tmpl_param.parameter_key,
            UsePreviousValue: true
          }
        end

        output_val = tmpl_param.no_echo ? '*****' : p[:ParameterValue]
        Cfer::LOGGER.info "Parameter #{p[:ParameterKey]}=#{output_val}"
        p
      end

      options = {
        stack_name: name,
        template_body: stack.to_cfn,
        parameters: parameters,
        capabilities: response.capabilities
      }

      created = false
      cfn_stack = begin
          created = true
          create_stack options
        rescue Cfer::Util::StackExistsError
          update_stack options
        end

      cfn_stack
    end

    def tail(options = {}, &block)
      q = []
      event_id_highwater = nil
      counter = 0
      for_each_event name do |event|
        q.unshift event if counter < options[:number]
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
          for_each_event name do |event|
            if event_id_highwater == event.event_id
              yielding = false
            end

            if yielding
              q.unshift event
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

    def fetch_cfn!
    end

    def to_h
      @stack.to_h
    end

    private

    def for_each_event(stack_name)
      describe_stack_events(stack_name: stack_name).stack_events.each do |event|
        yield event
      end
    end
  end
end


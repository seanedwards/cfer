module Cfer::Cfn
  class Stack < Cfer::Block
    include Cfer::Cfn

    attr_reader :parameters
    attr_reader :git

    def initialize(parameters = {})
      self[:AWSTemplateFormatVersion] = '2010-09-09'
      self[:Description] = ''
      @parameters = Cfer::Util::ParameterValidator.new(parameters)
      @git = Rugged::Repository.discover('.')

      clean_working_dir = false #@git_status.changed.empty? && @git_status.deleted.empty? && @git_status.added.empty?
      self[:Metadata] = { :Git => { :Rev => @git.head.target_id, :Clean => clean_working_dir } }

      self[:Parameters] = {}
      self[:Mappings] = {}
      self[:Conditions] = {}
      self[:Resources] = {}
      self[:Outputs] = {}
    end

    def description(desc)
      self[:Description] = desc
    end

    def parameter(name, options = {})
      options[:Type] ||= 'String'
      param = {}
      options.each do |k, v|
        param[k.to_s.camelize] = v
      end
      self[:Parameters][name] = param
    end

    def mappings(mappings)
      self[:Mappings] = mappings
    end

    def condition(name, expr)
      self[:Conditions][name] = expr
    end

    def resource(name, type, options = {}, &block)
      clazz = "CferExt::#{type}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || Cfer::Cfn::Resource
      rc = clazz.new(name, type, options, &block)

      self[:Resources][name] = rc
      rc
    end

    def output(name, value)
      self[:Outputs][name] = {'Value' => value}
    end

    def to_cfn
      to_h.to_json
    end
  end

  class CfnStack
    attr_reader :name

    def initialize(name, cfn_client = nil)
      @name = name
      @cfn = cfn_client || Aws::CloudFormation::Client.new
    end

    def converge(stack, options = {})
      Preconditions.check(stack) { is_not_nil and has_type(Cfer::Cfn::Stack) }
      Preconditions.check(@cfn) { is_not_nil }

      response = @cfn.validate_template(template_body: stack.to_cfn)
      parameters = response.parameters.map do |tmpl_param|
        input_param = stack.parameters[tmpl_param.parameter_key]
        stack.parameters[tmpl_param.parameter_key] ||= ParameterValidator.new tmpl_param.default_value if input_param

        p = if stack.parameters[tmpl_param.parameter_key]
          {
            ParameterKey: tmpl_param.parameter_key,
            ParameterValue: stack.parameters[tmpl_param.parameter_key].evaluate(@cfn),
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
          @cfn.create_stack options
        rescue Aws::CloudFormation::Errors::AlreadyExistsException
          @cfn.update_stack options
        end

      cfn_stack
    end

    def tail(options = {}, &block)
      @cfn ||= Aws::CloudFormation::Client.new

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
          stack_status = @cfn.describe_stacks(stack_name: name).stacks.first.stack_status
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

          sleep 1 if running
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
      @cfn.describe_stack_events(stack_name: stack_name).each do |event_page|
        event_page.stack_events.each do |event|
          yield event
        end
      end
    end
  end
end

module Cfer::Core

  # Defines the structure of a CloudFormation stack
  class Stack < Cfer::Block
    include Cfer::Core
    include Cfer::Cfn

    # The parameters strictly as passed via command line
    attr_reader :input_parameters

    # The fully resolved parameters, including defaults and parameters fetched from an existing stack during an update
    attr_reader :parameters

    attr_reader :options

    def converge!
      if @options[:client]
        @options[:client].converge self
      end
    end

    def tail!(&block)
      if @options[:client]
        @options[:client].tail self, &block
      end
    end

    def initialize(options = {})
      self[:AWSTemplateFormatVersion] = '2010-09-09'
      self[:Description] = ''

      @options = options

      self[:Parameters] = {}
      self[:Mappings] = {}
      self[:Conditions] = {}
      self[:Resources] = {}
      self[:Outputs] = {}

      @parameters = HashWithIndifferentAccess.new
      @input_parameters = HashWithIndifferentAccess.new

      if options[:client]
        begin
          @parameters.merge! options[:client].fetch_parameters
        rescue Cfer::Util::StackDoesNotExistError
          Cfer::LOGGER.debug "Can't include current stack parameters because the stack doesn't exist yet."
        end
      end

      if options[:parameters]
        options[:parameters].each do |key, val|
          @input_parameters[key] = @parameters[key] = val
        end
      end
    end

    # Sets the description for this CloudFormation stack
    def description(desc)
      self[:Description] = desc
    end

    # Declares a CloudFormation parameter
    #
    # @param name [String] The parameter name
    # @param options [Hash]
    # @option options [String] :type The type for the CloudFormation parameter
    # @option options [String] :default A value of the appropriate type for the template to use if no value is specified when a stack is created. If you define constraints for the parameter, you must specify a value that adheres to those constraints.
    # @option options [String] :no_echo Whether to mask the parameter value whenever anyone makes a call that describes the stack. If you set the value to `true`, the parameter value is masked with asterisks (*****).
    # @option options [String] :allowed_values An array containing the list of values allowed for the parameter.
    # @option options [String] :allowed_pattern A regular expression that represents the patterns you want to allow for String types.
    # @option options [Number] :max_length An integer value that determines the largest number of characters you want to allow for String types.
    # @option options [Number] :min_length An integer value that determines the smallest number of characters you want to allow for String types.
    # @option options [Number] :max_value A numeric value that determines the largest numeric value you want to allow for Number types.
    # @option options [Number] :min_value A numeric value that determines the smallest numeric value you want to allow for Number types.
    # @option options [String] :description A string of up to 4000 characters that describes the parameter.
    # @option options [String] :constraint_description A string that explains the constraint when the constraint is violated. For example, without a constraint description, a parameter that has an allowed pattern of `[A-Za-z0-9]+` displays the following error message when the user specifies an invalid value:
    #
    #     ```Malformed input-Parameter MyParameter must match pattern [A-Za-z0-9]+```
    #
    #     By adding a constraint description, such as must only contain upper- and lowercase letters, and numbers, you can display a customized error message:
    #
    #     ```Malformed input-Parameter MyParameter must only contain upper and lower case letters and numbers```
    def parameter(name, options = {})
      param = {}
      options.each do |key, v|
        k = key.to_s.camelize.to_sym
        param[k] =
          case k
          when :AllowedPattern
            if v.class == Regexp
              v.source
            end
          when :Default
            @parameters[name] ||= v
          end
        param[k] ||= v
      end
      param[:Type] ||= 'String'
      self[:Parameters][name] = param
    end

    # Sets the mappings block for this stack. See [The CloudFormation Documentation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html) for more details
    def mappings(mappings)
      self[:Mappings] = mappings
    end

    # Adds a condition to the template.
    # @param name [String] The name of the condition.
    # @param expr [Hash] The CloudFormation condition to add. See [The Cloudformation Documentation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html) for more details
    def condition(name, expr)
      self[:Conditions][name] = expr
    end

    # Creates a CloudFormation resource
    # @param name [String] The name of the resource (must be alphanumeric)
    # @param type [String] The type of CloudFormation resource to create.
    # @param options [Hash] Additional attributes to add to the resource block (such as the `UpdatePolicy` for an `AWS::AutoScaling::AutoScalingGroup`)
    def resource(name, type, options = {}, &block)
      Preconditions.check_argument(/[[:alnum:]]+/ =~ name, "Resource name must be alphanumeric")

      clazz = "CferExt::#{type}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || Cfer::Cfn::Resource
      Preconditions.check_argument clazz <= Cfer::Cfn::Resource, "#{type} is not a valid resource type because CferExt::#{type} does not inherit from `Cfer::Cfn::Resource`"

      rc = clazz.new(name, type, options, &block)

      self[:Resources][name] = rc
      rc
    end

    # Adds an output to the CloudFormation stack.
    # @param name [String] The Logical ID of the output parameter
    # @param value [String] Value to return
    # @param options [Hash] Extra options for this output parameter
    # @option options [String] :Description Information about the value
    def output(name, value, options = {})
      self[:Outputs][name] = options.merge('Value' => value)
    end

    # Renders the stack into a CloudFormation template.
    # @return [String] The final template
    def to_cfn
      to_h.to_json
    end

    def client
      @options[:client] || raise(Cfer::Util::CferError, "Stack has no associated client.")
    end

    # Includes template code from one or more files, and evals it in the context of this stack.
    # Filenames are relative to the file containing the invocation of this method.
    def include_template(*files)
      include_base = options[:include_base] || File.dirname(caller.first.split(/:\d/,2).first)
      files.each do |file|
        path = File.join(include_base, file)
        instance_eval(File.read(path), path)
      end
    end

    def lookup_output(stack, out)
      client = @options[:client] || raise(Cfer::Util::CferError, "Can not fetch stack outputs without a client")
      client.fetch_output(stack, out)
    end
  end

end

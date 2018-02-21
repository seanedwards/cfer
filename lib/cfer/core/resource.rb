module Cfer::Core
  class Resource < Cfer::BlockHash
    include Cfer::Core::Hooks

    class Handle
      attr_reader :name
      def initialize(name)
        @name = name.to_s
      end

      def ref
        Functions::Fn::ref(name)
      end

      def method_missing(method)
        Functions::Fn::get_att(name, method.to_s.camelize)
      end
    end

    @@types = {}

    attr_reader :stack

    def initialize(name, type, stack, **options, &block)
      @name = name
      @stack = stack

      self[:Type] = type
      self.merge!(options)
      self[:Properties] = HashWithIndifferentAccess.new
      build_from_block(&block)
    end

    def handle
      @handle ||= Handle.new(@name)
    end

    # Sets a tag on this resource. The resource must support the CloudFormation `Tags` property.
    # @param k [String] The name of the tag to set
    # @param v [String] The value for this tag
    # @param options [Hash] An arbitrary set of additional properties to be added to this tag, for example `PropagateOnLaunch` on `AWS::AutoScaling::AutoScalingGroup`
    def tag(k, v, **options)
      self[:Properties][:Tags] ||= []
      self[:Properties][:Tags].delete_if { |kv| kv["Key"] == k }
      self[:Properties][:Tags].unshift({"Key" => k, "Value" => v}.merge(options))
    end

    # Directly sets raw properties in the underlying CloudFormation structure.
    # @param keyvals [Hash] The properties to set on this object.
    def properties(keyvals = {})
      self[:Properties].merge!(keyvals)
    end

    # Gets the current value of a given property
    # @param key [String] The name of the property to fetch
    def get_property(key)
      self[:Properties].fetch key
    end

    class << self
      # Fetches the DSL class for a CloudFormation resource type
      # @param type [String] The type of resource, for example `AWS::EC2::Instance`
      # @return [Class] The DSL class representing this resource type, including all extensions
      def resource_class(type)
        @@types[type] ||= "CferExt::#{type}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || Class.new(Cfer::Core::Resource)
      end

      # Patches code into DSL classes for CloudFormation resources
      # @param type [String] The type of resource, for example `AWS::EC2::Instance`
      def extend_resource(type, &block)
        resource_class(type).class_eval(&block)
      end

      # Registers a hook that will be run before properties are set on a resource
      # @param type [String] The type of resource, for example `AWS::EC2::Instance`
      def before(type, options = {}, &block)
        resource_class(type).pre_hooks << options.merge(block: block)
      end

      # Registers a hook that will be run after properties have been set on a resource
      # @param type [String] The type of resource, for example `AWS::EC2::Instance`
      def after(type, options = {}, &block)
        resource_class(type).post_hooks << options.merge(block: block)
      end
    end
  end
end

module Cfer::Core
  class Resource < Cfer::BlockHash
    include Cfer::Core::Hooks

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


    def tag(k, v, **options)
      self[:Properties][:Tags] ||= []
      self[:Properties][:Tags].unshift({"Key" => k, "Value" => v}.merge(options))
    end

    def properties(keyvals = {})
      self[:Properties].merge!(keyvals)
    end

    def get_property(key)
      self[:Properties].fetch key
    end

    class << self
      def resource_class(type)
        @@types[type] ||= "CferExt::#{type}".split('::').inject(Object) { |o, c| o.const_get c if o && o.const_defined?(c) } || Class.new(Cfer::Core::Resource)
      end

      def extend_resource(type, &block)
        resource_class(type).class_eval(&block)
      end

      def before(type, &block)
        resource_class(type).pre_hooks << block
      end

      def after(type, &block)
        resource_class(type).post_hooks << block
      end
    end
  end
end

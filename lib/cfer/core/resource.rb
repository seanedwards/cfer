module Cfer::Core
  class Resource < Cfer::BlockHash
    @@types = {}

    def initialize(name, type, **options, &block)
      @name = name

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
        resource_class(type).instance_eval(&block)
      end
    end

    private
  end
end

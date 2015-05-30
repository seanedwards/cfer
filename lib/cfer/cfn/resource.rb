module Cfer::Cfn
  class Resource < Cfer::Block
    NON_PROXIED_METHODS = [:parameters]

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

    def properties(**keyvals)
      self[:Properties].merge!(keyvals)
    end

    def respond_to?(method_sym)
      !NON_PROXIED_METHODS.include?(method_sym)
    end

    def get_att(attribute)
      Fn::get_att(name, attribute)
    end

    def method_missing(method_sym, *arguments, &block)
      key = camelize_property(method_sym)
      case arguments.size
      when 0
        Fn::ref(method_sym)
      when 1
        properties key => arguments.first
      else
        properties key => arguments
      end
    end

    private
    def camelize_property(sym)
      sym.to_s.camelize.to_sym
    end
  end
end

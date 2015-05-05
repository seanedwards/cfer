module Cfer::Cfn
  class Resource < Cfer::Block
    def initialize(type, options = {}, &block)
      self[:Type] = type
      self[:Properties] = HashWithIndifferentAccess.new
      build_from_block(&block)
    end

    def tag(k, v, options = {})
      self[:Properties][:Tags] ||= []
      self[:Properties][:Tags].unshift "Key" => k, "Value" => v
    end

    def prop(key, value)
      self[:Properties][key] = value
    end

    def method_missing(method_sym, *arguments, &block)
      key = key_name(method_sym)
      if block
        prop key, Cfer::Block.new(&block)
      else
        case arguments.size
        when 0
          self[:Properties][key]
        when 1
          prop key, arguments.first
        else
          prop key, arguments
        end
      end
    end

    private
    def key_name(sym)
      sym.to_s.camelize.to_sym
    end
  end
end

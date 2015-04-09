module Cfer
  class HashBuilder
    attr_reader :_options

    def []=(k, v)
      @_options[k] = v
    end

    def [](k)
      @_options[k]
    end

    def method_missing(method_sym, *arguments, &block)
      method_sym = method_sym.to_s.camelize
      if block
        @_options[method_sym] = Cfer::build HashBuilder, &block
      else
        case arguments.size
        when 0
          @_options[method_sym] ||= HashWithIndifferentAccess.new
        when 1
          @_options[method_sym] = arguments.first
        else
          @_options[method_sym] = arguments
        end
      end
    end

    def pre_block
    end

    def post_block
    end

    def initialize
      @_options = HashWithIndifferentAccess.new
    end
  end
end

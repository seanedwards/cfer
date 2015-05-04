module Cfer
  class HashBuilder < ActiveSupport::HashWithIndifferentAccess

    def method_missing(method_sym, *arguments, &block)
      method_sym = method_sym.to_s.camelize.to_sym
      if block
        self[method_sym] = Cfer::build HashBuilder.new, &block
      else
        case arguments.size
        when 0
          self[method_sym] ||= HashWithIndifferentAccess.new
        when 1
          self[method_sym] = arguments.first
        else
          self[method_sym] = arguments
        end
      end
    end

    def responds_to?(method_sym)
      true
    end

    def set(options = {})
      options.each do |k, v|
        self[k] = v
      end
    end

    def pre_block
    end

    def post_block
    end

  end
end

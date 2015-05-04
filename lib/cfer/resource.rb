module Cfer
  class Resource < HashBuilder
    def initialize(type)
      self[:Type] = type
      self[:Properties] ||= Cfer::HashBuilder.new
    end

    def tag(k, v, options = {})
      self[:Properties][:Tags] ||= []
      self[:Properties][:Tags].unshift "Key" => k, "Value" => v
    end

    def pre_block
      @tags = []
      super
    end

    def post_block
      merge :Properties => { :Tags => @tags } unless @tags.empty?
      super
    end

    def method_missing(method_sym, *arguments, &block)
      method_sym = method_sym.to_s.camelize.to_sym
      self[:Properties].method_missing(method_sym, *arguments, &block)
    end
  end
end

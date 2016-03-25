module Cfer::Cfn
  class Resource < Cfer::BlockHash

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
      puts self[:Properties]
      self[:Properties].fetch key
    end

  end
end

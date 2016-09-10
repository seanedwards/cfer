module Cfer
  class Config < BlockHash
    def initialize(file = nil, *args, &block)
      build_from_file(file, *args) if File.exists?(file)
      build_from_block(*args, &block) if block
    end

    def camelize_property(sym)
      sym
    end
  end
end

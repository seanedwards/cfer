module Cfer
  class Config < BlockHash
    def initialize(file = nil, *args, &block)
      @config_file = file

      build_from_block(*args) do
        include_file(file) if File.exists?(file)
        instance_eval &block if block
      end
    end

    # Includes config code from one or more files, and evals it in the context of this stack.
    # Filenames are relative to the file containing the invocation of this method.
    def include_config(*files)
      include_base = File.dirname(@config_file)
      files.each do |file|
        path = File.join(include_base, file)
        include_file(path)
      end
    end

    private
    def non_proxied_methods
      []
    end

    def camelize_property(sym)
      sym
    end
  end
end

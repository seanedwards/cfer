module Cfer
  class Config < BlockHash
    def initialize(file = nil, options = nil, &block)
      @config_file = file
      deep_merge! options if options
      instance_eval &block if block
    end

    def method_missing(method_sym, *arguments, &block)
      key = camelize_property(method_sym)
      case arguments.size
      when 0
        if block
          Config.new(@config_file, nil, &block)
        else
          val = self[key]
          val =
            case val
            when Hash, nil
              Config.new(nil, val)
            else
              val
            end
          properties key => val
          val
        end
      else
        super
      end
    end

    # Includes config code from one or more files, and evals it in the context of this stack.
    # Filenames are relative to the file containing the invocation of this method.
    def include_config(*files)
      include_base = File.dirname(@config_file) if @config_file
      files.each do |file|
        path = File.join(include_base, file) if include_base
        include_file(path || file)
      end
    end

    private
    def non_proxied_methods
      []
    end
  end
end

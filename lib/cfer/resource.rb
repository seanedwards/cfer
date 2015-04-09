module Cfer
  class Resource < HashBuilder
    def tag(k, v)
      @tags[k] = v
    end

    def pre_block
      @tags = {}
      super
    end

    def post_block
      properties[:Tags] = @tags.to_a.map do |kv|
        {"Key" => kv[0], "Value" => kv[1]}
      end
      super
    end

    def ref(name)
      Cfer::ref(name)
    end
  end
end

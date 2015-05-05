module Cfer
  class Block < ActiveSupport::HashWithIndifferentAccess


    def build_from_block(&block)
      pre_block
      instance_exec(&block) if block
      post_block
      self
    end

    def build_from_file(file)
      pre_block
      instance_eval File.read(file), file if file
      post_block
      self
    end

    def set(keyvals = {})
      keyvals.each do |k, v|
        self[k] = v
      end
    end

    def pre_block
    end

    def post_block
    end

  end
end

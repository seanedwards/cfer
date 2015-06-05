require 'docile'

module Cfer
  # Represents the base class of a Cfer DSL
  class Block < ActiveSupport::HashWithIndifferentAccess
    # Evaluates a DSL directly from a Ruby block, calling pre- and post- hooks.
    # @param args [Array<Object>] Extra arguments to be passed into the block.
    def build_from_block(*args, &block)
      pre_block
      Docile.dsl_eval(self, *args, &block) if block
      post_block
      self
    end

    # Evaluates a DSL from a Ruby script file
    # @param args [Array<Object>] (see: #build_from_block)
    # @param file [File] The Ruby script to evaluate
    def build_from_file(*args, file)
      build_from_block(*args) do
        instance_eval File.read(file), file
      end
      self
    end

    # Executed just before the DSL is evaluated
    def pre_block
    end

    # Executed just after the DSL is evaluated
    def post_block
    end
  end
end

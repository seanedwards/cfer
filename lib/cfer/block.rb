require 'docile'

module Cfer
  class Block < ActiveSupport::HashWithIndifferentAccess


    def build_from_block(*args, &block)
      pre_block
      Docile.dsl_eval(self, *args, &block)
      post_block
      self
    end

    def build_from_file(*args, file)
      build_from_block(*args) do
        begin
          instance_eval File.read(file), file
        rescue SyntaxError => e
          Cfer::LOGGER.error e.message
        end
      end
      self
    end

    def pre_block
    end

    def post_block
    end

  end
end

require 'docile'
require 'json'
require 'yaml'

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

    # Evaluates a DSL from a Ruby string
    # @param args [Array<Object>] Extra arguments to be passed into the block
    # @param str [String] The Cfer source template to evaluate
    # @param file [File] The file that will be reported in any error messages
    def build_from_string(*args, str, file)
      build_from_block(*args) do
        instance_eval str, file
      end
      self
    end

    # Evaluates a DSL from a Ruby script file
    # @param args [Array<Object>] (see: #build_from_block)
    # @param file [File] The Ruby script to evaluate
    def build_from_file(*args, file)
      build_from_block(*args) do
        include_file(file)
      end
    end

    def include_file(file)
      raise Cfer::Util::FileDoesNotExistError, "#{file} does not exist." unless File.exists?(file)

      case File.extname(file)
      when '.json'
        deep_merge! JSON.parse(IO.read(file))
      when '.yml', '.yaml'
        deep_merge! YAML.load_file(file)
      else
        instance_eval File.read(file)
      end
    end

    # Executed just before the DSL is evaluated
    def pre_block
    end

    # Executed just after the DSL is evaluated
    def post_block
    end
  end

  # BlockHash is a Block that responds to DSL-style properties.
  class BlockHash < Block
    NON_PROXIED_METHODS = [
      :parameters,
      :options,
      :lookup_output,
      :lookup_outputs
    ].freeze

    # Directly sets raw properties in the underlying CloudFormation structure.
    # @param keyvals [Hash] The properties to set on this object.
    def properties(keyvals = {})
      self.merge!(keyvals)
    end

    # Gets the current value of a given property
    # @param key [String] The name of the property to fetch
    def get_property(key)
      self.fetch key
    end

    def respond_to?(method_sym)
      !non_proxied_methods.include?(method_sym)
    end

    def method_missing(method_sym, *arguments, &block)
      key = camelize_property(method_sym)
      properties key =>
        case arguments.size
        when 0
          if block
            BlockHash.new.build_from_block(&block)
          else
            raise "Expected a value or block when setting property #{key}"
          end
        when 1
          arguments.first
        else
          arguments
        end
    end

    private
    def non_proxied_methods
      NON_PROXIED_METHODS
    end

    def camelize_property(sym)
      sym.to_s.camelize.to_sym
    end
  end
end

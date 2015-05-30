require 'active_support/all'
require 'aws-sdk'
require 'logger'
require 'json'
require 'rugged'
require 'preconditions'
require 'rainbow'

module CferExt
  module AWS
  end
end

module Cfer
  module Cfn
  end

  LOGGER = Logger.new(STDERR)
  LOGGER.formatter = proc { |severity, datetime, progname, msg|
    color = case severity
    when 'FATAL'
      :red
    when 'ERROR'
      :red
    when 'WARN'
      :yellow
    else
      nil
    end

    if color
      "#{Rainbow(msg).send(color)}\n"
    else
      "#{msg}\n"
    end
  }

  class << self

    # Builds a Cfer::Cfn::Stack from a Ruby block
    #
    # @param parameters [Hash] The Cloudformation parameter values that this stack will be converged with
    # @param block The block containing the Cfn DSL
    # @return [Cfer::Cfn::Stack] The assembled stack object
    def stack_from_block(parameters = {}, &block)
      s = Cfer::Cfn::Stack.new(parameters)
      templatize_errors('block') do
        s.build_from_block(&block)
      end
      s
    end

    # Builds a Cfer::Cfn::Stack from a ruby script
    #
    # @param file [String] The file containing the Cfn DSL
    # @param parameters [Hash] (see #stack_from_block)
    # @return [Cfer::Cfn::Stack] The assembled stack object
    def stack_from_file(file, parameters = {})
      s = Cfer::Cfn::Stack.new(parameters)
      templatize_errors(file) do
        s.build_from_file file
      end
      s
    end

    private
    def templatize_errors(base_loc)
      begin
        yield
      rescue SyntaxError => e
        raise Cfer::Util::TemplateError.new(e.message, [])
      rescue StandardError => e
        raise Cfer::Util::TemplateError.new(e.message, convert_backtrace(base_loc, e))
      end
    end

    def convert_backtrace(base_loc, exception)
        continue_search = true
        exception.backtrace_locations.take_while { |loc|
          continue_search = false if loc.path == base_loc
          continue_search || loc.path == base_loc
        }
    end
  end
end

Dir["#{File.dirname(__FILE__)}/cfer/**/*.rb"].each { |f| require(f) }
Dir["#{File.dirname(__FILE__)}/cferext/**/*.rb"].each { |f| require(f) }


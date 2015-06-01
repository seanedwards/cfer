require 'active_support/all'
require 'aws-sdk'
require 'logger'
require 'json'
require 'rugged'
require 'preconditions'
require 'rainbow'


# Contains extensions that Cfer will dynamically use
module CferExt
  module AWS
  end
end

# Contains the core Cfer logic
module Cfer
  module Cfn
  end

  module Core
  end

  # The Cfer logger
  LOGGER = Logger.new(STDERR)
  LOGGER.formatter = proc { |severity, datetime, progname, msg|
    msg = case severity
    when 'FATAL'
      Rainbow(msg).red.bright
    when 'ERROR'
      Rainbow(msg).red
    when 'WARN'
      Rainbow(msg).yellow
    when 'DEBUG'
      Rainbow(msg).black.bright
    else
      msg
    end

    "#{msg}\n"
  }

  class << self

    # Builds a Cfer::Core::Stack from a Ruby block
    #
    # @param options [Hash] The stack options
    # @param block The block containing the Cfn DSL
    # @option options [Hash] :parameters The CloudFormation stack parameters
    # @return [Cfer::Core::Stack] The assembled stack object
    def stack_from_block(options = {}, &block)
      s = Cfer::Core::Stack.new(options)
      templatize_errors('block') do
        s.build_from_block(&block)
      end
      s
    end

    # Builds a Cfer::Core::Stack from a ruby script
    #
    # @param file [String] The file containing the Cfn DSL
    # @param options [Hash] (see #stack_from_block)
    # @return [Cfer::Core::Stack] The assembled stack object
    def stack_from_file(file, options = {})
      s = Cfer::Core::Stack.new(options)
      templatize_errors(file) do
        s.build_from_file file
      end
      s
    end

    private
    def templatize_errors(base_loc)
      yield
    rescue SyntaxError => e
      raise Cfer::Util::TemplateError.new([]), e.message
    rescue StandardError => e
      raise Cfer::Util::TemplateError.new(convert_backtrace(base_loc, e)), e.message
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


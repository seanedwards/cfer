require 'active_support/all'
require 'aws-sdk'
require 'logger'
require 'json'
require 'rugged'

module CferExt
  module AWS
  end
end

module Cfer
  LOGGER = Logger.new(STDOUT)

  class << self
    def stack(parameters = {}, &block)
      s = Cfer::Cfn::Stack.new(parameters)
      s.build_from_block(&block)
      s
    end

    def stack_from_file(file, parameters = {})
      s = Cfer::Cfn::Stack.new(parameters)
      s.build_from_file file
      s
    end

    def converge(stack_name, template_file, **options)
      Cfer::Cli.new([], options, {}).invoke(:converge, stack_name, template_file)
    end
  end
end

Dir["#{File.dirname(__FILE__)}/cfer/**/*.rb"].each { |f| require(f) }
Dir["#{File.dirname(__FILE__)}/cferext/**/*.rb"].each { |f| require(f) }


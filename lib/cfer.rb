require 'active_support/all'
require 'aws-sdk'
require 'json'
require "cfer/version"
require 'cfer/block'
require 'cfer/provisioning/provisioner.rb'

module CferExt
  module AWS
  end
end

module Cfer
  def self.stack(parameters = {}, &block)
    stack = Cfer::Cfn::Stack.new(parameters)
    stack.build_from_block &block
    stack
  end

  def self.stack_from_file(file, parameters = {})
    stack = Cfer::Cfn::Stack.new(parameters)
    stack.build_from_file file
    stack
  end
end

Dir["#{File.dirname(__FILE__)}/cfer/cfn/**/*.rb"].each { |f| load(f) }
Dir["#{File.dirname(__FILE__)}/cferext/**/*.rb"].each { |f| load(f) }


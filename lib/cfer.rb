require 'active_support/all'
require 'json'
require "cfer/version"
require 'cfer/block'
require 'cfer/cfn/fn'
require 'cfer/cfn/stack'
require 'cfer/cfn/resource'

module Cfer
  def self.stack(&block)
    stack = Cfer::Cfn::Stack.new
    stack.build_from_block &block
  end

  def self.stack_from_file(file)
    stack = Cfer::Cfn::Stack.new
    stack.build_from_file file
  end
end

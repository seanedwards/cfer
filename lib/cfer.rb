require "cfer/version"
require 'cfer/hasher'
require 'cfer/stack'
require 'cfer/resource'
require 'active_support/all'
require 'json'

module Cfer

  def self.build(clazz = Cfer::HashBuilder,  &block)
    h = clazz.new
    h.pre_block
    h.instance_eval(&block)
    h.post_block
    h._options
  end


  def self.stack(&block)
    Cfer::build(Cfer::Stack, &block)
  end

  # Wrap CFN intrinsic functions
  def self.join(delim, args)
    {"Fn::Join" => [delim, args]}
  end

  def self.ref(r)
    {"Ref" => r.to_s.camelize}
  end

  def self.get_att(r, att)
    {"Fn::GetAtt" => [r.to_s.camelize, att]}
  end
end

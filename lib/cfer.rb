
require 'active_support/all'
require "cfer/version"
require 'cfer/hasher'
require 'cfer/stack'
require 'cfer/resource'
require 'json'
require 'configliere'

module Cfer

  def self.build(h = Cfer::HashBuilder.new, *arguments, &block)
    h.pre_block
    #Docile.dsl_eval(h, *arguments, &block)
    h.instance_exec(*arguments, &block)
    h.post_block
    h.to_h
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

  def self.select(i, o)
    {"Fn::Select" => [i, o]}
  end
end

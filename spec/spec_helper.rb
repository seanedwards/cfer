$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pp'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

def create_stack(options = {}, &block)
  cfn = options[:client] || Cfer::Cfn::Client.new(stack_name: options[:stack_name] || 'test', region: 'us-east-1')
  setup_describe_stacks cfn, cfn.name
  cfn.fetch_stack

  s = Cfer.stack_from_block(options.merge(client: cfn), &block)
  pp s.to_h
  s
end

def setup_describe_stacks(cfn, stack_name = 'test')
  expect(cfn).to receive(:describe_stacks)
    .exactly(1).times
    .with(stack_name: stack_name)
    .and_return(
      double(
        stacks: double(
          first: double(
            to_h: {
              :parameters => [
                {
                  :parameter_key => 'parameter',
                  :parameter_value => 'param_value'
                },
                {
                  :parameter_key => 'unchanged_key',
                  :parameter_value => 'unchanged_value'
                }
              ],
              :outputs => [
                {
                  :output_key => 'value',
                  :output_value => 'remote_value'
                }
              ]
            }
          )
        )
      )
    )
end

module Cfer
  DEBUG = true
end

require 'cfer'

Cfer::LOGGER.level = Logger::DEBUG


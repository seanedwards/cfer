$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'coveralls'
require 'pp'

def create_stack(options = {}, &block)
  s = Cfer.stack_from_block(options, &block)
  setup_describe_stacks options[:client], options[:client].name if options[:client] && options[:mock_describe]
  pp s.to_h
  s
end

def setup_describe_stacks(cfn, stack_name = 'other_stack')
  expect(cfn).to receive(:describe_stacks)
    .exactly(1).times
    .with(stack_name: stack_name)
    .and_return(
      double(
        stacks: double(
          first: double(
            to_h: {
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

Coveralls.wear!
require 'cfer'

Cfer::LOGGER.level = Logger::DEBUG


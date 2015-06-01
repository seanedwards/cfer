$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'coveralls'

def create_stack(options = {}, &block)
  s = Cfer.stack_from_block(options, &block)
  pp s.to_h
  s
end

module Cfer
  DEBUG = true
end

Coveralls.wear!
require 'cfer'

Cfer::LOGGER.level = Logger::DEBUG


$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'coveralls'

def create_stack(params = {}, &block)
  s = Cfer.stack_from_block(params, &block)
  pp s.to_h
  s
end

Coveralls.wear!
require 'cfer'


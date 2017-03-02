require "pry"
require "pry-rescue"

module Cfer
  DEBUG = true
end

require "cfer/cli"

Cfer::LOGGER.level = Logger::DEBUG

Cfer::LOGGER.fatal "Showing FATAL logs"
Cfer::LOGGER.error "Showing ERROR logs"
Cfer::LOGGER.warn "Showing WARN logs"
Cfer::LOGGER.info "Showing INFO logs"
Cfer::LOGGER.debug "Showing DEBUG logs"

def cfer(*args)
  Cfer::Cli::main(args)
end


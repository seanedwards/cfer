require 'git'

module Cfer::Core
  class Client
    attr_reader :git

    def initialize(options)
      @git = Git.open(options[:working_directory] || '.') rescue nil
    end

    def converge
      raise Cfer::Util::CferError, 'converge not implemented on this client'
    end

    def tail(options = {}, &block)
      raise Cfer::Util::CferError, 'tail not implemented on this client'
    end
  end
end

require 'git'

module Cfer::Core
  class Client
    attr_reader :git

    def initialize(options)
      begin
        @git = Git.open(options[:working_directory] || '.')
      rescue Exception
        # git will be null if we can't open the repo
      end
    end

    def converge
      raise Cfer::Util::CferError, 'converge not implemented on this client'
    end

    def tail(options = {}, &block)
      raise Cfer::Util::CferError, 'tail not implemented on this client'
    end
  end
end

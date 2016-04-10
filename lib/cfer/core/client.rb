require 'git'

module Cfer::Core
  class Client
    attr_reader :git

    def initialize(options)
      path = options[:working_directory] || '.'
      if File.exist?("#{path}/.git")
        @git = Git.open(path) rescue nil
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

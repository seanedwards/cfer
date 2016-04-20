module Cfer::Util
  require 'highline/import'
  class CferError < StandardError
  end

  class CferValidationError < CferError
    attr_reader :errors
    def initialize(errors)
      @errors = errors
      super(errors)
    end
  end

  class StackExistsError < CferError
  end

  class StackDoesNotExistError < CferError
  end

  class TemplateError < CferError
    attr_reader :template_backtrace

    def initialize(template_backtrace)
      @template_backtrace = template_backtrace
      super
    end
  end

  def self.bug_report(e)
    gather_report e
    transmit_report if agree('Would you like to send this information in a bug report? (type yes/no)')
  end

  private
  def self.gather_report(e)
    puts e
  end

  def self.transmit_report
    puts "Sending report."
  end
end

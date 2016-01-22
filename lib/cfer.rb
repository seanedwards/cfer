require 'active_support/all'
require 'aws-sdk'
require 'logger'
require 'json'
require 'preconditions'
require 'rainbow'


# Contains extensions that Cfer will dynamically use
module CferExt
  module AWS
  end
end

# Contains the core Cfer logic
module Cfer
  module Cfn
  end

  module Core
  end

  # The Cfer logger
  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::INFO
  LOGGER.formatter = proc { |severity, datetime, progname, msg|
    msg = case severity
    when 'FATAL'
      Rainbow(msg).red.bright
    when 'ERROR'
      Rainbow(msg).red
    when 'WARN'
      Rainbow(msg).yellow
    when 'DEBUG'
      Rainbow(msg).black.bright
    else
      msg
    end

    "#{msg}\n"
  }

  class << self

    def converge!(stack_name, options = {})
      config(options)
      tmpl = options[:template] || "#{stack_name}.rb"
      cfn = options[:aws_options] || {}

      cfn_stack = Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
      stack = Cfer::stack_from_file(tmpl, options.merge(client: cfn_stack))

      begin
        cfn_stack.converge(stack, options)
        if options[:follow]
          tail! stack_name, options
        end
      rescue Aws::CloudFormation::Errors::ValidationError => e
        Cfer::LOGGER.info "CFN validation error: #{e.message}"
      end
      describe! stack_name, options unless options[:follow]
    end

    def describe!(stack_name, options = {})
      config(options)
      cfn = options[:aws_options] || {}
      cfn_stack = Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name)).fetch_stack

      Cfer::LOGGER.debug "Describe stack: #{cfn_stack}"

      case options[:output_format] || 'table'
      when 'json'
        puts render_json(cfn_stack, options)
      when 'table'
        puts "Status: #{cfn_stack[:stack_status]}"
        puts "Description: #{cfn_stack[:description]}" if cfn_stack[:description]
        puts ""
        parameters = (cfn_stack[:parameters] || []).map { |param| {:Type => "Parameter", :Key => param[:parameter_key], :Value => param[:parameter_value]} }
        outputs = (cfn_stack[:outputs] || []).map { |output| {:Type => "Output", :Key => output[:output_key], :Value => output[:output_value]} }
        tp parameters + outputs, :Type, :Key, {:Value => {:width => 80}}
      else
        raise Cfer::Util::CferError, "Invalid output format #{options[:output_format]}."
      end
    end

    def tail!(stack_name, options = {}, &block)
      config(options)
      cfn = options[:aws_options] || {}
      cfn_client = Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
      if block
        cfn_client.tail(options, &block)
      else
        cfn_client.tail(options) do |event|
          Cfer::LOGGER.info "%s %-30s %-40s %-20s %s" % [event.timestamp, color_map(event.resource_status), event.resource_type, event.logical_resource_id, event.resource_status_reason]
        end
      end
      describe! stack_name, options
    end

    def generate!(tmpl, options = {})
      config(options)
      cfn_stack = Cfer::Cfn::Client.new(options[:aws_options] || {})
      stack = Cfer::stack_from_file(tmpl, options.merge(client: cfn_stack)).to_h
      puts render_json(stack, options)
    end

    # Builds a Cfer::Core::Stack from a Ruby block
    #
    # @param options [Hash] The stack options
    # @param block The block containing the Cfn DSL
    # @option options [Hash] :parameters The CloudFormation stack parameters
    # @return [Cfer::Core::Stack] The assembled stack object
    def stack_from_block(options = {}, &block)
      s = Cfer::Core::Stack.new(options)
      templatize_errors('block') do
        s.build_from_block(&block)
      end
      s
    end

    # Builds a Cfer::Core::Stack from a ruby script
    #
    # @param file [String] The file containing the Cfn DSL
    # @param options [Hash] (see #stack_from_block)
    # @return [Cfer::Core::Stack] The assembled stack object
    def stack_from_file(file, options = {})
      s = Cfer::Core::Stack.new(options)
      templatize_errors(file) do
        s.build_from_file file
      end
      s
    end

    private

    def config(options)
      Cfer::LOGGER.debug "Options: #{options}"
      Cfer::LOGGER.level = Logger::DEBUG if options[:verbose]

      Aws.config.update region: options[:region] if options[:region]
      Aws.config.update credentials: Aws::SharedCredentials.new(profile_name: options[:profile]) if options[:profile]
    end

    def render_json(obj, options = {})
      if options[:pretty_print]
        puts JSON.pretty_generate(obj)
      else
        puts obj.to_json
      end
    end

    def templatize_errors(base_loc)
      yield
    rescue SyntaxError => e
      raise Cfer::Util::TemplateError.new([]), e.message
    rescue StandardError => e
      raise Cfer::Util::TemplateError.new(convert_backtrace(base_loc, e)), e.message
    end

    def convert_backtrace(base_loc, exception)
        continue_search = true
        exception.backtrace_locations.take_while { |loc|
          continue_search = false if loc.path == base_loc
          continue_search || loc.path == base_loc
        }
    end


    COLORS_MAP = {
      'CREATE_IN_PROGRESS' => {
        color: :yellow
      },
      'DELETE_IN_PROGRESS' => {
        color: :yellow
      },
      'UPDATE_IN_PROGRESS' => {
        color: :green
      },

      'CREATE_FAILED' => {
        color: :red,
        finished: true
      },
      'DELETE_FAILED' => {
        color: :red,
        finished: true
      },
      'UPDATE_FAILED' => {
        color: :red,
        finished: true
      },

      'CREATE_COMPLETE' => {
        color: :green,
        finished: true
      },
      'DELETE_COMPLETE' => {
        color: :green,
        finished: true
      },
      'UPDATE_COMPLETE' => {
        color: :green,
        finished: true
      },

      'DELETE_SKIPPED' => {
        color: :yellow
      },

      'ROLLBACK_IN_PROGRESS' => {
        color: :red
      },
      'ROLLBACK_COMPLETE' => {
        color: :red,
        finished: true
      }
    }

    def color_map(str)
      if COLORS_MAP.include?(str)
        Rainbow(str).send(COLORS_MAP[str][:color])
      else
        str
      end
    end

    def stopped_state?(str)
      COLORS_MAP[str][:finished] || false
    end
  end
end

Dir["#{File.dirname(__FILE__)}/cfer/*.rb"].each { |f| require(f) }
Dir["#{File.dirname(__FILE__)}/cfer/**/*.rb"].each { |f| require(f) }
Dir["#{File.dirname(__FILE__)}/cferext/**/*.rb"].each { |f| require(f) }


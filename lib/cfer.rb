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

  %w{
    DB
    ASG
  }.each do |acronym|
    ActiveSupport::Inflector.inflections.acronym acronym
  end

  # The Cfer logger
  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::INFO
  LOGGER.formatter = proc { |severity, _datetime, _progname, msg|
    msg =
      case severity
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

      cfn_stack = options[:cfer_client] || Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
      stack = options[:cfer_stack] ||
              Cfer::stack_from_file(tmpl,
                options.merge(
                  client: cfn_stack,
                  parameters: generate_final_parameters(options)
                )
              )

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
      cfn_stack = options[:cfer_client] || Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
      cfn_stack = cfn_stack.fetch_stack

      Cfer::LOGGER.debug "Describe stack: #{cfn_stack}"

      case options[:output_format]
      when 'json'
        puts render_json(cfn_stack, options)
      when 'table', nil
        puts "Status: #{cfn_stack[:stack_status]}"
        puts "Description: #{cfn_stack[:description]}" if cfn_stack[:description]
        puts ""
        def tablify(list, type)
          list ||= []
          list.map { |param|
            {
              :Type => type.to_s.titleize,
              :Key => param[:"#{type}_key"],
              :Value => param[:"#{type}_value"]
            }
          }
        end
        parameters = tablify(cfn_stack[:parameters] || [], 'parameter')
        outputs = tablify(cfn_stack[:outputs] || [], 'output')
        tp parameters + outputs, :Type, :Key, {:Value => {:width => 80}}
      else
        raise Cfer::Util::CferError, "Invalid output format #{options[:output_format]}."
      end
    end

    def tail!(stack_name, options = {}, &block)
      config(options)
      cfn = options[:aws_options] || {}
      cfn_client = options[:cfer_client] || Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
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
      cfn = options[:aws_options] || {}

      cfn_stack = options[:cfer_client] || Cfer::Cfn::Client.new(cfn)
      stack = options[:cfer_stack] || Cfer::stack_from_file(tmpl,
        options.merge(client: cfn_stack, parameters: generate_final_parameters(options))).to_h
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

    def generate_final_parameters(options)
      raise "parameter-environment set but parameter_file not set" \
        if options[:parameter_environment] && options[:parameter_file].nil?

      file_params =
        if options[:parameter_file]
          case File.extname(options[:parameter_file])
          when '.yaml'
            require 'yaml'
            YAML.load_file(options[:parameter_file])
          when '.json'
            JSON.parse(IO.read(options[:parameter_file]))
          else
            raise "Unrecognized parameter file format: #{File.extname(options[:parameter_file])}"
          end
        else
          {}
        end

      if options[:parameter_environment]
        raise "no key '#{options[:parameter_environment]}' found in parameters file." \
          unless file_params.key?(options[:parameter_environment])

        file_params = file_params.deep_merge(file_params[options[:parameter_environment]])
      end

      file_params.deep_merge(options[:parameters])
    end

    def render_json(obj, options = {})
      if options[:pretty_print]
        puts JSON.pretty_generate(obj, options)
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


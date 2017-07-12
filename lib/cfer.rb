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
  DEBUG = false unless defined? DEBUG

  # Code relating to working with Amazon CloudFormation
  module Cfn
  end

  # Code relating to building the CloudFormation document out of the Ruby DSL
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

    # Creates or updates a CloudFormation stack
    # @param stack_name [String] The name of the stack to update
    # @param options [Hash]
    def converge!(stack_name, options = {})
      config(options)
      options[:on_failure].upcase! if options[:on_failure]
      tmpl = options[:template] || "#{stack_name}.rb"
      cfn = options[:aws_options] || {}

      cfn_stack = options[:cfer_client] || Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
      raise Cfer::Util::CferError, "No such template file: #{tmpl}" unless File.exist?(tmpl) || options[:cfer_stack]
      stack =
        options[:cfer_stack] ||
          Cfer::stack_from_file(tmpl,
            options.merge(
              client: cfn_stack,
              parameters: generate_final_parameters(options)
            )
          )

      begin
        operation = stack.converge!(options)
        if options[:follow] && !options[:change]
          begin
            tail! stack_name, options.merge(cfer_client: cfn_stack)
          rescue Interrupt
            puts "Caught interrupt. What would you like to do?"
            case HighLine.new($stdin, $stderr).choose('Continue', 'Quit', 'Rollback')
            when 'Continue'
              retry
            when 'Rollback'
              rollback_opts = {
                stack_name: stack_name
              }

              rollback_opts[:role_arn] = options[:role_arn] if options[:role_arn]

              case operation
              when :created
                cfn_stack.delete_stack rollback_opts
              when :updated
                cfn_stack.cancel_update_stack rollback_opts
              end
              retry
            end
          end
        end
        # This is allowed to fail, particularly if we decided to roll back
        describe! stack_name, options rescue nil
      rescue Aws::CloudFormation::Errors::ValidationError => e
        Cfer::LOGGER.info "CFN validation error: #{e.message}"
      end
      stack
    end

    def describe!(stack_name, options = {})
      config(options)
      cfn = options[:aws_options] || {}
      cfn_stack = options[:cfer_client] || Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
      cfn_metadata = cfn_stack.fetch_metadata
      cfn_stack = cfn_stack.fetch_stack

      cfer_version = cfn_metadata.fetch("Cfer", {}).fetch("Version", nil)
      if cfer_version
        cfer_version_str = [cfer_version["major"], cfer_version["minor"], cfer_version["patch"]].join '.'
        cfer_version_str << '-' << cfer_version["pre"] unless cfer_version["pre"].nil?
        cfer_version_str << '+' << cfer_version["build"] unless cfer_version["build"].nil?
      end

      Cfer::LOGGER.debug "Describe stack: #{cfn_stack}"
      Cfer::LOGGER.debug "Describe metadata: #{cfn_metadata}"

      case options[:output_format]
      when 'json'
        puts render_json(cfn_stack, options)
      when 'table', nil
        puts "Status: #{cfn_stack[:stack_status]}"
        puts "Description: #{cfn_stack[:description]}" if cfn_stack[:description]
        puts "Created with Cfer version: #{Semantic::Version.new(cfer_version_str)} (current: #{Cfer::SEMANTIC_VERSION.to_s})" if cfer_version
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
      cfn_stack
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
    end

    def generate!(tmpl, options = {})
      config(options)
      cfn = options[:aws_options] || {}

      cfn_stack = options[:cfer_client] || Cfer::Cfn::Client.new(cfn)
      raise Cfer::Util::CferError, "No such template file: #{tmpl}" unless File.exist?(tmpl) || options[:cfer_stack]
      stack = options[:cfer_stack] || Cfer::stack_from_file(tmpl,
        options.merge(client: cfn_stack, parameters: generate_final_parameters(options))).to_h
      puts render_json(stack, options)
    end

    def estimate!(tmpl, options = {})
      config(options)
      cfn = options[:aws_options] || {}

      cfn_stack = options[:cfer_client] || Cfer::Cfn::Client.new(cfn)
      stack = options[:cfer_stack] || Cfer::stack_from_file(tmpl,
        options.merge(client: cfn_stack, parameters: generate_final_parameters(options)))
      puts cfn_stack.estimate(stack)
    end

    def delete!(stack_name, options = {})
      config(options)
      cfn = options[:aws_options] || {}
      cfn_stack = options[:cfer_client] || cfn_stack = Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))

      delete_opts = {
        stack_name: stack_name
      }
      delete_opts[:role_arn] = options[:role_arn] if options[:role_arn]
      cfn_stack.delete_stack(delete_opts)

      if options[:follow]
        tail! stack_name, options.merge(cfer_client: cfn_stack)
      end
    rescue Aws::CloudFormation::Errors::ValidationError => e
      if e.message =~ /Stack .* does not exist/
        raise Cfer::Util::StackDoesNotExistError, e.message
      else
        raise e
      end
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
    # @param file [String] The file containing the Cfn DSL or plain JSON
    # @param options [Hash] (see #stack_from_block)
    # @return [Cfer::Core::Stack] The assembled stack object
    def stack_from_file(file, options = {})
      return stack_from_stdin(options) if file == '-'

      s = Cfer::Core::Stack.new(options)
      templatize_errors(file) do
        s.build_from_file file
      end
      s
    end

    # Builds a Cfer::Core::Stack from stdin
    #
    # @param options [Hash] (see #stack_from_block)
    # @return [Cfer::Core::Stack] The assembled stack object
    def stack_from_stdin(options = {})
      s = Cfer::Core::Stack.new(options)
      templatize_errors('STDIN') do
        s.build_from_string STDIN.read, 'STDIN'
      end
      s
    end

    private

    def config(options)
      Cfer::LOGGER.debug "Options: #{options}"
      Cfer::LOGGER.level = Logger::DEBUG if options[:verbose]

      Aws.config.update region: options[:region] if options[:region]
      Aws.config.update credentials: Cfer::Cfn::CferCredentialsProvider.new(profile_name: options[:profile]) if options[:profile]
    end

    def generate_final_parameters(options)
      raise Cfer::Util::CferError, "parameter-environment set but parameter_file not set" \
        if options[:parameter_environment] && options[:parameter_file].nil?

      final_params = HashWithIndifferentAccess.new

      final_params.deep_merge! Cfer::Config.new(cfer: options) \
        .build_from_file(options[:parameter_file]) \
        .to_h if options[:parameter_file]

      if options[:parameter_environment]
        raise Cfer::Util::CferError, "no key '#{options[:parameter_environment]}' found in parameters file." \
          unless final_params.key?(options[:parameter_environment])

        Cfer::LOGGER.debug "Merging in environment key #{options[:parameter_environment]}"

        final_params.deep_merge!(final_params[options[:parameter_environment]])
      end

      final_params.deep_merge!(options[:parameters] || {})

      Cfer::LOGGER.debug "Final parameters: #{final_params}"
      final_params
    end

    def render_json(obj, options = {})
      if options[:pretty_print]
        puts Cfer::Util::Json.format_json(obj)
      else
        puts obj.to_json
      end
    end

    def templatize_errors(base_loc)
      yield
    rescue Cfer::Util::CferError => e
      raise e
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
      'CREATE_IN_PROGRESS' => { color: :yellow },
      'DELETE_IN_PROGRESS' => { color: :yellow },
      'UPDATE_IN_PROGRESS' => { color: :green },

      'CREATE_FAILED' => { color: :red, finished: true },
      'DELETE_FAILED' => { color: :red, finished: true },
      'UPDATE_FAILED' => { color: :red, finished: true },

      'CREATE_COMPLETE' => { color: :green, finished: true },
      'DELETE_COMPLETE' => { color: :green, finished: true },
      'UPDATE_COMPLETE' => { color: :green, finished: true },

      'DELETE_SKIPPED' => { color: :yellow },

      'ROLLBACK_IN_PROGRESS' => { color: :red },

      'UPDATE_ROLLBACK_COMPLETE' => { color: :red, finished: true },
      'ROLLBACK_COMPLETE' => { color: :red, finished: true }
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

%w{
version.rb
block.rb
config.rb

util/error.rb
util/json.rb

core/hooks.rb
core/client.rb
core/functions.rb
core/resource.rb
core/stack.rb

cfn/cfer_credentials_provider.rb
cfn/client.rb
}.each do |f|
  require "#{File.dirname(__FILE__)}/cfer/#{f}"
end
Dir["#{File.dirname(__FILE__)}/cferext/**/*.rb"].each { |f| require(f) }

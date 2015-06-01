require 'thor'
require 'rainbow'

module Cfer
  class Cli < Thor

    namespace 'cfer'
    class_option :verbose, type: :boolean, default: false

    def self.template_options
      method_option :output_file,
        type: :string,
        aliases: :o,
        desc: 'The file that will contain the rendered CloudFormation template (may be an s3:// URL)'

      method_option :pretty_print,
        type: :boolean,
        default: :true,
        desc: 'Render JSON in a more human-friendly format'

      method_option :parameters,
        type: :hash,
        desc: 'The CloudFormation parameters to pass to the stack',
        default: {}
    end

    def self.stack_options
      method_option :profile,
        type: :string,
        aliases: :p,
        desc: 'The AWS profile to use from your credentials file'

      method_option :region,
        type: :string,
        aliases: :r,
        desc: 'The AWS region to use',
        default: 'us-east-1'
    end

    desc 'converge [OPTIONS] <stack-name> <template.rb>', 'Converges a cloudformation stack according to the template'
    #method_option :git_lock,
    #  type: :boolean,
    #  default: true,
    #  desc: 'When enabled, Cfer will not converge a stack in a dirty git tree'

    method_option :on_failure,
      type: :string,
      default: 'DELETE',
      desc: 'The action to take if the stack creation fails'
    method_option :follow,
      aliases: :f,
      type: :boolean,
      default: true,
      desc: 'Follow stack events on standard output while the changes are made.'
    method_option :number,
      type: :numeric,
      default: 1,
      desc: 'Prints the last (n) events.'
    method_option :stack_file,
      aliases: :n,
      type: :string,
      desc: 'Override the stack filename (defaults to <stack-name>.rb)'
    template_options
    stack_options
    def converge(stack_name)
      tmpl = options[:stack_file] || "#{stack_name}.rb"

      config(options)
      stack = Cfer::stack_from_file(tmpl, options)

      cfn_stack = Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name))
      begin
        cfn_stack.converge(stack, options)
        if options[:follow]
          tail stack_name
        end
      rescue Aws::CloudFormation::Errors::ValidationError => e
        Cfer::LOGGER.info "CFN validation error: #{e.message}"
        exit 1
      end
    end

    desc 'tail <stack>', 'Follows stack events on standard output as they occur'
    method_option :follow,
      aliases: :f,
      type: :boolean,
      default: false,
      desc: 'Follow stack events on standard output while the changes are made.'
    method_option :number,
      aliases: :n,
      type: :numeric,
      default: 10,
      desc: 'Prints the last (n) events.'
    stack_options
    def tail(stack_name)
      config(options)
      Cfer::Cfn::Client.new(cfn.merge(stack_name: stack_name)).tail(options) do |event|
        Cfer::LOGGER.info "%s %-30s %-40s %-20s %s" % [event.timestamp, color_map(event.resource_status), event.resource_type, event.logical_resource_id, event.resource_status_reason]
      end
    end

    desc 'generate [OPTIONS] <template.rb>', 'Generates a CloudFormation template by evaluating a Cfer template'
    long_desc <<-LONGDESC
      Generates a CloudFormation template by evaluating a Cfer template.
    LONGDESC
    template_options
    def generate(tmpl)
      stack = Cfer::stack_from_file(tmpl, options).to_h

      if options[:pretty_print]
        puts JSON.pretty_generate(stack)
      else
        puts stack.to_json
      end
    end

    def self.main(args)
      Cfer::LOGGER.debug "Cfer version #{Cfer::VERSION}"
      begin
        Cli.start(args)
      rescue Aws::Errors::NoSuchProfileError => e
        Cfer::LOGGER.error "#{e.message}. Specify a valid profile with the --profile option."
        exit 1
      rescue Interrupt
        Cfer::LOGGER.info 'Caught interrupt. Goodbye.'
      rescue Cfer::Util::TemplateError => e
        Cfer::LOGGER.fatal "Template error: #{e.message}"
        Cfer::LOGGER.fatal Cfer::Cli.format_backtrace(e.template_backtrace) unless e.template_backtrace.empty?
        exit 1
      rescue Cfer::Util::CferError => e
        Cfer::LOGGER.error "#{e.message}"
        exit 1
      rescue  StandardError => e
        Cfer::LOGGER.fatal "#{e.class.name}: #{e.message}"
        Cfer::LOGGER.fatal Cfer::Cli.format_backtrace(e.backtrace) unless e.backtrace.empty?

        if Cfer::DEBUG
          Pry::rescued(e)
        else
          Cfer::Util.bug_report(e)
        end
        exit 1
      end
    end

    private

    def config(options)
      Cfer::LOGGER.level = Logger::DEBUG if options[:verbose]

      Aws.config.update region: options[:region] if options[:region]
      Aws.config.update credentials: Aws::SharedCredentials.new(profile_name: options[:profile]) if options[:profile]

      cfn options[:aws_options] if options[:aws_options]
    end

    def cfn(opts = {})
      @cfn ||= opts
    end

    def self.format_backtrace(bt)
      "Backtrace: #{bt.join("\n   from ")}"
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


  def self.exit_on_failure?
    true
  end
end


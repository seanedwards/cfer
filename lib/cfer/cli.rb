require 'thor'
require 'rainbow'
require 'table_print'

module Cfer
  class Cli < Thor
    map '-v' => :version, '--version' => :version

    namespace 'cfer'
    class_option :verbose, type: :boolean, default: false
    class_option :profile, type: :string, aliases: :p, desc: 'The AWS profile to use from your credentials file'
    class_option :region, type: :string, aliases: :r, desc: 'The AWS region to use'
    class_option :pretty_print, type: :boolean, default: :true, desc: 'Render JSON in a more human-friendly format'

    def self.template_options
      method_option :parameters,
        type: :hash,
        desc: 'The CloudFormation parameters to pass to the stack',
        default: {}
      method_option :parameter_file,
        type: :string,
        desc: 'A YAML or JSON file with CloudFormation parameters to pass to the stack'
      method_option :parameter_environment,
        type: :string,
        desc: 'If parameter_file is set, will merge the subkey of this into the parameter list.'
    end

    def self.stack_options
      method_option :output_format,
        type: :string,
        desc: 'The output format of the stack [table|json]',
        default: 'table'
    end

    desc 'converge [OPTIONS] <stack-name>', 'Create or update a cloudformation stack according to the template'
    #method_option :git_lock,
    #  type: :boolean,
    #  default: true,
    #  desc: 'When enabled, Cfer will not converge a stack in a dirty git tree'

    method_option :on_failure,
      type: :string,
      desc: 'The action to take if the stack creation fails'
    method_option :follow,
      aliases: :f,
      type: :boolean,
      default: true,
      desc: 'Follow stack events on standard output while the changes are made.'
    method_option :number,
      type: :numeric,
      default: 1,
      desc: 'Prints the last (n) stack events.'
    method_option :template,
      aliases: :t,
      type: :string,
      desc: 'Override the stack filename (defaults to <stack-name>.rb)'
    method_option :stack_policy,
      aliases: :s,
      type: :string,
      desc: 'Set a new stack policy on create or update of the stack [file|url|json]'
    method_option :stack_policy_during_update,
      aliases: :u,
      type: :string,
      desc: 'Set a temporary overriding stack policy during an update [file|url|json]'
    method_option :timeout,
      type: :numeric,
      desc: 'The timeout (in minutes) before the stack operation aborts'
    method_option :upgrade,
      type: :boolean,
      default: false,
      desc: 'Allow Cfer to introduce potentially breaking changes, which may replace resources.'
    method_option :s3_path,
      type: :string,
      desc: 'Specifies an S3 path in case the stack is created with a URL.'
    method_option :force_s3,
      type: :boolean,
      default: false,
      desc: 'Forces Cfer to upload the template to S3 and pass CloudFormation a URL.'
    method_option :change,
      type: :string,
      desc: 'Issues updates as a Cfn change set.'
    method_option :change_description,
      type: :string,
      desc: 'The description of this Cfn change'

    template_options
    stack_options
    def converge(stack_name)
      Cfer.converge! stack_name, options
    end

    desc 'describe <stack>', 'Fetches and prints information about a CloudFormation'
    stack_options
    def describe(stack_name)
      Cfer.describe! stack_name, options
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
      desc: 'Prints the last (n) stack events.'
    stack_options
    def tail(stack_name)
      Cfer.tail! stack_name, options
    end

    desc 'generate [OPTIONS] <template.rb>', 'Generates a CloudFormation template by evaluating a Cfer template'
    long_desc <<-LONGDESC
      Generates a CloudFormation template by evaluating a Cfer template.
    LONGDESC
    template_options
    def generate(tmpl)
      Cfer.generate! tmpl, options
    end

    desc 'estimate [OPTIONS] <template.rb>', 'Prints a link to the Amazon cost caculator estimating the cost of the resulting CloudFormation stack'
    long_desc <<-LONGDESC
    LONGDESC
    template_options
    def estimate(tmpl)
      Cfer.estimate! tmpl, options
    end

    def self.main(args)
      Cfer::LOGGER.debug "Cfer version #{Cfer::VERSION}"
      begin
        Cli.start(args)
      rescue Aws::Errors::NoSuchProfileError => e
        Cfer::LOGGER.error "#{e.message}. Specify a valid profile with the --profile option."
        exit 1
      rescue Aws::Errors::MissingRegionError => e
        Cfer::LOGGER.error "Missing region. Specify a valid AWS region with the --region option, or use the AWS_REGION environment variable."
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
          #Cfer::Util.bug_report(e)
        end
        exit 1
      end
    end

    desc 'version', 'Prints the current version of Cfer'
    def version
      puts Cfer::VERSION
    end

    private

    def cfn(opts = {})
      @cfn ||= opts
    end
    private
    def self.format_backtrace(bt)
      "Backtrace: #{bt.join("\n   from ")}"
    end
    def self.exit_on_failure?
      true
    end

  end


end

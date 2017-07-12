require 'cfer'
require 'cri'
require 'rainbow'
require 'table_print'

module Cfer
  module Cli
    CFER_CLI = Cri::Command.define do
      name 'cfer'
      description 'Toolkit and Ruby DSL for automating infrastructure using AWS CloudFormation'
      flag nil, 'verbose', 'Runs Cfer with debug output enabled'

      optional :p, 'profile', 'The AWS profile to use from your credentials file'
      optional :r, 'region', 'The AWS region to use'

      optional nil, 'output-format', 'The output format to use when printing a stack [table|json]'

      optional nil, 'parameter', 'Sets a parameter to pass into the stack (format: `name:value`)', multiple: true
      optional nil, 'parameter-file', 'A YAML or JSON file with CloudFormation parameters to pass to the stack'
      optional nil, 'parameter-environment', 'If parameter_file is set, will merge the subkey of this into the parameter list.'

      flag :v, 'version', 'show the current version of cfer' do |value, cmd|
        puts Cfer::VERSION
        exit 0
      end

      flag  :h, 'help',  'show help for this command' do |value, cmd|
        puts cmd.help
        exit 0
      end
    end

    CFER_CLI.define_command do
      name 'converge'
      usage 'converge [OPTIONS] <stack-name> [param=value ...]'
      summary 'Create or update a cloudformation stack according to the template'

      optional :t,  'template', 'Override the stack filename (defaults to <stack-name>.rb)'
      optional nil, 'on-failure', 'The action to take if the stack creation fails'
      optional nil, 'timeout', 'The timeout (in minutes) before the stack operation aborts'
      #flag   nil, 'git-lock', 'When enabled, Cfer will not converge a stack in a dirty git tree'
      optional nil,
               'notification-arns',
               'SNS topic ARN to publish stack related events. This option can be supplied multiple times.',
               multiple: true

      optional :s,  'stack-policy', 'Set a new stack policy on create or update of the stack [file|url|json]'
      optional :u,  'stack-policy-during-update', 'Set a temporary overriding stack policy during an update [file|url|json]'
      optional nil, 'role-arn', 'Pass a specific role ARN for CloudFormation to use (--role-arn in AWS CLI)'

      optional nil, 'change', 'Issues updates as a Cfn change set.'
      optional nil, 'change-description', 'The description of this Cfn change'

      optional nil, 's3-path', 'Specifies an S3 path in case the stack is created with a URL.'
      flag     nil, 'force-s3', 'Forces Cfer to upload the template to S3 and pass CloudFormation a URL.'

      run do |options, args, cmd|
        Cfer::Cli.fixup_options(options)
        params = {}
        options[:number] = 0
        options[:follow] = true
        #options[:git_lock] = true if options[:git_lock].nil?

        Cfer::Cli.extract_parameters(params, args).each do |arg|
          Cfer.converge! arg, options.merge(parameters: params)
        end
      end
    end

    CFER_CLI.define_command do
      name 'generate'
      usage 'generate [OPTIONS] <template.rb> [param=value ...]'
      summary 'Generates a CloudFormation template by evaluating a Cfer template'

      flag nil, 'minified', 'Minifies the JSON when printing output.'

      run do |options, args, cmd|
        Cfer::Cli.fixup_options(options)
        params = {}
        options[:pretty_print] = !options[:minified]

        Cfer::Cli.extract_parameters(params, args).each do |arg|
          Cfer.generate! arg, options.merge(parameters: params)
        end
      end
    end

    CFER_CLI.define_command do
      name 'tail'
      usage 'tail <stack>'
      summary 'Follows stack events on standard output as they occur'

      flag :f, 'follow', 'Follow stack events on standard output while the changes are made.'
      optional :n, 'number', 'Prints the last (n) stack events.', type: :number

      run do |options, args, cmd|
        Cfer::Cli.fixup_options(options)
        args.each do |arg|
          Cfer.tail! arg, options
        end
      end
    end

    CFER_CLI.define_command do
      name 'estimate'
      usage 'estimate [OPTIONS] <template.rb>'
      summary 'Prints a link to the Amazon cost caculator estimating the cost of the resulting CloudFormation stack'

      run do |options, args, cmd|
        Cfer::Cli.fixup_options(options)
        args.each do |arg|
          Cfer.estimate! arg, options
        end
      end
    end

    CFER_CLI.define_command do
      name 'describe'
      usage 'describe <stack>'
      summary 'Fetches and prints information about a CloudFormation'

      run do |options, args, cmd|
        Cfer::Cli.fixup_options(options)
        options[:pretty_print] ||= true
        args.each do |arg|
          Cfer.describe! arg, options
        end
      end
    end

    CFER_CLI.define_command do
      name 'delete'
      usage 'delete <stack>'
      summary 'Deletes a CloudFormation stack'

      run do |options, args, cmd|
        Cfer::Cli.fixup_options(options)
        options[:number] = 0
        options[:follow] = true
        args.each do |arg|
          Cfer.delete! arg, options
        end
      end
    end

    CFER_CLI.add_command Cri::Command.new_basic_help

    def self.main(args)
      Cfer::LOGGER.debug "Cfer version #{Cfer::VERSION}"
      begin
        CFER_CLI.run(args)
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
      rescue Cfer::Util::CferError, Cfer::Util::StackDoesNotExistError => e
        Cfer::LOGGER.error "#{e.message}"
        exit 1
      rescue StandardError => e
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

    PARAM_REGEX=/(?<name>.+?)=(?<value>.+)/
    def self.extract_parameters(params, args)
      args.reject do |arg|
        if match = PARAM_REGEX.match(arg)
          name = match[:name]
          value = match[:value]
          Cfer::LOGGER.debug "Extracting parameter #{name}: #{value}"
          params[name] = value
        end
      end
    end

    # Convert options of the form `:'some-option'` into `:some_option`.
    # Cfer internally uses the latter format, while Cri options must be specified as the former.
    # This approach is better than changing the names of all the options in the CLI.
    def self.fixup_options(opts)
      opts.keys.map(&:to_s).each do |k|
        old_k = k.to_sym
        new_k = k.gsub('-', '_').to_sym
        val = opts[old_k]
        opts[new_k] = (Integer(val) rescue Float(val) rescue val)
        opts.delete(old_k) if old_k != new_k
      end
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

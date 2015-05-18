require 'thor'
require 'rainbow'

module Cfer
  class Cli < Thor

    class_option :verbose, type: :boolean, default: false
    class_option :debug,   type: :boolean, default: false

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
    method_option :git_lock,
      type: :boolean,
      default: true,
      desc: 'When enabled, Cfer will not converge a stack in a dirty git tree'

    method_option :on_failure,
      type: :string,
      default: 'DELETE',
      desc: 'The action to take if the stack creation fails'

    method_option :async,
      type: :boolean,
      default: false,
      desc: 'Invoke the stack update and quit immediately'

    method_option :follow,
      aliases: :f,
      type: :boolean,
      default: true,
      desc: 'Follow stack events on standard output while the changes are made.'
    method_option :number,
      aliases: :n,
      type: :numeric,
      default: 1,
      desc: 'Prints the last (n) events.'
    template_options
    stack_options
    def converge(stack, tmpl)
      config(options)
      s = Cfer::stack_from_file(tmpl, options[:parameters])

      cfn_stack = Cfer::Cfn::CfnStack.new(stack, s)
      cfn_stack.converge(options)
      if options[:follow]
        tail stack
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
    def tail(stack)
      config(options)
      Cfer::Cfn::CfnStack.new(stack).tail(options.merge(done_states: ['UPDATE_COMPLETE', 'CREATE_FAILED', 'ROLLBACK_COMPLETE'])) do |event|
        puts "%s %-30s %-30s %-10s %s" % [event.timestamp, color_map(event.resource_status), event.resource_type, event.logical_resource_id, event.resource_status_reason]
      end
    end

    desc 'plan [OPTIONS] <template.rb>', 'Describes the changes that will be made to the CloudFormation stack'
    method_option :stack_name, type: :string, aliases: :n
    template_options
    stack_options
    def plan(tmpl)
      config(options)
      raise "Not yet implemented"
    end

    desc 'generate [OPTIONS] <template.rb>', 'Generates a CloudFormation template by evaluating a Cfer template'
    long_desc <<-LONGDESC
      Generates a CloudFormation template by evaluating a Cfer template.
    LONGDESC
    template_options
    def generate(tmpl)
      s = Cfer::stack_from_file(tmpl, options[:parameters]).to_h

      if options[:pretty_print]
        puts JSON.pretty_generate(s)
      else
        puts s.to_json
      end
    end

    def self.main(args)
      begin
        Cli.start(args)
      rescue Aws::Errors::NoSuchProfileError => e
        puts "ERROR: #{e.message}. Specify a valid profile with the --profile option."
      rescue Interrupt
        puts 'Caught interrupt. Goodbye.'
      end
    end

    private

    def config(options)
      if options[:region] || options[:profile]
        Aws.config.update region: options[:region],
          credentials: Aws::SharedCredentials.new(profile_name: options[:profile])
      end
    end

    COLORS_MAP = {
      'CREATE_IN_PROGRESS' => :yellow,
      'DELETE_IN_PROGRESS' => :yellow,
      'UPDATE_IN_PROGRESS' => :green,

      'CREATE_FAILED' => :red,
      'DELETE_FAILED' => :red,
      'UPDATE_FAILED' => :red,

      'CREATE_COMPLETE' => :green,
      'DELETE_COMPLETE' => :green,
      'UPDATE_COMPLETE' => :green,

      'DELETE_SKIPPED' => :yellow,

      'ROLLBACK_IN_PROGRESS' => :red,
      'ROLLBACK_COMPLETE' => :red
    }

    def color_map(str)
      if COLORS_MAP.include?(str)
        Rainbow(str).send(COLORS_MAP[str])
      else
        str
      end
    end
  end
end


require 'thor'

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
    end

    def self.stack_options
      method_option :profile,
        type: :string,
        aliases: :p,
        desc: 'The AWS profile to use from your credentials file'

      method_option :parameters,
        type: :hash,
        desc: 'The CloudFormation parameters to pass to the stack'
    end

    desc 'converge [OPTIONS] <stack-name> <template.rb>', 'Converges a cloudformation stack according to the template'
    method_option :git_lock,
      type: :boolean,
      default: true,
      desc: 'When enabled, Cfer will not converge a stack in a dirty git tree'

    method_option :disable_rollback,
      type: :boolean,
      default: false,
      desc: 'If enabled, the stack will not automatically roll back to its previous working state'

    method_option :async,
      type: :boolean,
      default: false,
      desc: 'Invoke the stack update and quit immediately'
    template_options
    stack_options
    def converge(stack, tmpl)
      s = Cfer::stack_from_file(tmpl)
    end

    desc 'plan [OPTIONS] <template.rb>', 'Describes the changes that will be made to the CloudFormation stack'
    method_option :stack_name, type: :string, aliases: :n
    template_options
    stack_options
    def plan(tmpl)
      s = Cfer::stack_from_file(tmpl)
    end

    desc 'generate [OPTIONS] <template.rb>', 'Generates a CloudFormation template by evaluating a Cfer template'
    long_desc <<-LONGDESC
      Generates a CloudFormation template by evaluating a Cfer template.
    LONGDESC
    template_options
    def generate(tmpl)
      s = Cfer::stack_from_file(tmpl).to_h

      if options[:pretty_print]
        puts JSON.pretty_generate(s)
      else
        puts s.to_json
      end
    end

    def self.main(args)
      Cli.start(args)
    end
  end
end


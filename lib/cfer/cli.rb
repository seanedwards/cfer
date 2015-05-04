require 'cri'

module Cfer
  module Cli
    module GlobalOptions
      def template_options
        # Options for the template generation phase
        required :f,  :"cfer-file", "Cfer template to evaluate." do |value, cmd|
          Settings.finally do |c|
            c[:cfer][:file] = value
          end
        end

        optional :o,  :"output-file", "Path to Cloudformation template output file", default: nil do |value, cmd|
          Settings.finally do |c|
            c[:cfer][:output] = value
          end
        end

        flag    nil, :"pretty-print", "Format human-friendly JSON output"
      end

      def stack_options
        # Options for phases that involve querying AWS
        optional :n, :"stack-name", "CloudFormation stack name", argument: :optional do |value, cmd|
          Settings.finally do |c|
            c[:cloudformation][:stack_name] = value
          end
        end

        optional :p, :profile, "Use a specific profile from your AWS credential file", argument: :optional do |value, cmd|
          Settings.finally do |c|
            c[:aws][:profile] = value
          end
        end

        flag  nil, :"disable-rollback", "Disables stack rollback", default: false do |value, cmd|
          Settings.finally do |c|
            c[:cloudformation][:disable_rollback] = true
          end
        end

        optional nil, :parameter, "Sets a CloudFormation stack parameter", multiple: true do |value, cmd|
          Settings.finally do |c|
            value.each do |kv|
              k, v = kv.split('=', 2)
              c[:cloudformation][:params][k.to_sym] = v
            end
          end
        end
      end
    end

    def self.main(args)
      Settings.use :config_block, :env_var, :prompt

      Settings({
      })

      Settings.read '~/.cfer.yml'
      Settings.read './cfer.yml'

      commands = [
        Cri::Command.define do
          extend GlobalOptions
          name 'converge'
          summary 'Converge a Cloudformation stack according to the Cfer template'

          template_options
          stack_options

          flag  nil, :async, "Execute the CloudFormation stack update and quit immediately", default: false

          run do |opts, args, cmd|
            Settings.resolve!
          end
        end,

        Cri::Command.define do
          extend GlobalOptions

          name 'plan'
          summary 'Describe the action plan that CloudFormation will take'

          template_options
          stack_options

          run do |opts, args, cmd|
            Settings.resolve!
          end
        end,

        Cri::Command.define do
          extend GlobalOptions

          name 'generate'
          summary 'Generates a CloudFormation template from the specified Cfer template'

          template_options

          run do |opts, args, cmd|
            Settings.resolve!
            s = Cfer::build Cfer::Stack.new do
              instance_eval File.read(opts[:file]), opts[:file]
            end
            if opts[:"pretty-print"]
              puts JSON.pretty_generate(s)
            else
              puts s.to_json
            end
          end
        end
      ]

      root = Cri::Command.define do
        extend GlobalOptions

        name 'cfer'
        summary 'Evaluates a Cfer script'
        usage 'cfer [--setting=value ...] <command> [OPTIONS ...]'

        flag nil, :debug, "Enables debug mode", hidden: true
        flag :v,  :verbose, "Run verbosely"
        flag :h,  :help, 'Show help for this command.' do |value, cmd|
          puts cmd.help
          exit 0
        end

        optional :s, :setting, "Overrides a Cfer setting", multiple: true do |value, cmd|
          Settings.finally do |c|
            value.each do |kv|
              k, v = kv.split('=', 2)
              Settings[k.to_sym] = v
            end
          end
        end

        flag nil, :version, "Show version" do |value, cmd|
          puts "Cfer #{Cfer::VERSION}"
          puts "Copyright (C) 2015 Sean Edwards <stedwards87+git@gmail.com>."
          puts "On Github at: https://github.com/seanedwards/cfer"
          exit
        end

        flag nil, :"version-json", "Shows the current application version in machine-readable JSON." do
          puts JSON.pretty_generate({
            :application => "cfer",
            :version => Cfer::VERSION,
            :email => "stedwards87+git@gmail.com",
            :homepage => "https://github.com/seanedwards/cfer",
            :license => "http://www.apache.org/licenses/LICENSE-2.0"
          })

          exit
        end

        run do |opts, args, cmd|
          Settings.resolve!
          puts cmd.help
        end
      end

      commands.each do |c|
        root.add_command c
      end

      root.run(args)
    end
  end
end


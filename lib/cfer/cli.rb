require 'cri'

module Cfer
  module Cli
    def self.main(args)
      root = Cri::Command.define do
        name 'cfer'
        summary 'Evaluates a Cloudformer script'

        option :f, :file, "Cloudformer template to evaluate.", argument: :required

        flag :h, :help, 'Show help for this command.' do |value, cmd|
          puts cmd.help
          exit 0
        end

        flag :p, :"pretty-print", "Pretty-print JSON output"

        run do |opts, args, cmd|
          s = Cfer::build Cfer::Stack do
            instance_eval File.read(opts[:file]), opts[:file]
          end
          if opts[:"pretty-print"]
            puts JSON.pretty_generate(s)
          else
            puts s.to_json
          end
        end
      end

      root.run(args)
    end
  end
end


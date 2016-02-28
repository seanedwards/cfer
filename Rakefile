#require "bundler/gem_tasks"
gem 'cfer'
require 'cfer'
require 'highline'

task :default => [:spec]

task :config_aws, [:profile] do |t, args|
  Aws.config.update region: ENV['AWS_REGION'] || ask('AWS Region?') { |q| q.default = 'us-east-1' },
    credentials: Aws::SharedCredentials.new(profile_name: ENV['AWS_PROFILE'] || ask('AWS Profile?') { |q| q.default = 'default' })
end

task :vpc => :config_aws do |t, args|
  Cfer.converge! 'vpc',
    template: 'examples/vpc.rb',
    follow: true
end

task :describe_vpc => :config_aws do
  Cfer.describe! 'vpc'
end

task :instance => :vpc do |t, args|
  key_pair = ask("Enter your EC2 KeyPair name: ")

  Cfer.converge! 'instance',
    template: 'examples/instance.rb',
    parameters: {
      :KeyName => key_pair
    },
    follow: true
end

task :describe_instance => :config_aws do
  Cfer.describe! 'instance'
end

task :converge => [:vpc, :instance]


########################
##### END OF DEMO ######
########################


# This task isn't really part of Cfer.
# It just makes it easier for me to release new versions.
task :release do
  require_relative 'lib/cfer/version.rb'

  `git checkout master`
  `git merge develop --no-ff -m 'Merge from develop for release v#{Cfer::VERSION}'`
  `git tag -m "Release v#{Cfer::VERSION}" #{Cfer::VERSION}`
end


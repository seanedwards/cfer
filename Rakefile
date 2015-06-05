require "bundler/gem_tasks"
gem 'cfer'
require 'cfer'
require 'highline'

Cfer::LOGGER.level = Logger::DEBUG

task :default => [:spec]

task :config_aws, [:profile] do |t, args|
  Aws.config.update region: ENV['AWS_REGION'] || 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: ENV['AWS_PROFILE'] || 'default')
end

task :vpc => :config_aws do |t, args|
  Cfer.converge! 'vpc',
    template: 'examples/vpc.rb',
    follow: true
end

task :describe_vpc => :config_aws do
  Cfer.describe! 'vpc'
end

task :instance => :config_aws do |t, args|
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


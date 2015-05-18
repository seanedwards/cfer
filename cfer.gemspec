# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cfer/version'

Gem::Specification.new do |spec|
  spec.name          = "cfer"
  spec.version       = Cfer::VERSION
  spec.authors       = ["Sean Edwards"]
  spec.email         = ["stedwards87+git@gmail.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'docile'
  spec.add_runtime_dependency 'thor'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'aws-sdk'
  spec.add_runtime_dependency 'aws-sdk-resources'
  spec.add_runtime_dependency 'preconditions'
  spec.add_runtime_dependency 'semantic'
  spec.add_runtime_dependency 'rainbow'
  spec.add_runtime_dependency 'highline'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
end

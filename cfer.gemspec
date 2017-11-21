# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cfer/version'

Gem::Specification.new do |spec|
  spec.name          = "cfer"
  spec.version       = Cfer::VERSION
  spec.authors       = ["Sean Edwards"]
  spec.email         = ["stedwards87+cfer@gmail.com"]

  spec.summary       = %q{Toolkit for automating infrastructure using AWS CloudFormation}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/seanedwards/cfer"
  spec.license       = "MIT"

  spec.required_ruby_version = ['~> 2.2', '>= 2.2.5']

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = ['cfer', 'json-to-cfer']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'docile', '~> 1.1'
  spec.add_runtime_dependency 'cri', '~> 2.7'
  spec.add_runtime_dependency 'activesupport', '>= 3'
  spec.add_runtime_dependency 'aws-sdk', '~> 2.2'
  spec.add_runtime_dependency 'aws-sdk-resources', '~> 2.2'
  spec.add_runtime_dependency 'preconditions', '~> 0.3.0'
  spec.add_runtime_dependency 'semantic', '~> 1.4'
  spec.add_runtime_dependency 'rainbow', '~> 2.2'
  spec.add_runtime_dependency 'highline', '~> 1.7'
  spec.add_runtime_dependency 'table_print', '~> 1.5'
  spec.add_runtime_dependency "git", '~> 1.3'

  spec.add_development_dependency "yard", '~> 0.8.7.6'
  spec.add_development_dependency "rake"
end

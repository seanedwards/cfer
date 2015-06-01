# Cfer

[![Build Status](https://travis-ci.org/seanedwards/cfer.svg?branch=master)](https://travis-ci.org/seanedwards/cfer)
[![Coverage Status](https://coveralls.io/repos/seanedwards/cfer/badge.svg)](https://coveralls.io/r/seanedwards/cfer)

Cfer is a lightweight toolkit for managing CloudFormation templates.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cfer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cfer

## Usage

### Command line

    Commands:
      cfer converge [OPTIONS] <stack-name> <template.rb>  # Converges a cloudformation stack according to the template
      cfer generate [OPTIONS] <template.rb>               # Generates a CloudFormation template by evaluating a Cfer template
      cfer help [COMMAND]                                 # Describe available commands or one specific command
      cfer tail <stack>                                   # Follows stack events on standard output as they occur

    Options:
      [--verbose], [--no-verbose]  

#### `converge`

Describe converging a template from the command line

#### `tail`

Describe following stack updates from the command line

### Cfer SDK

#### `stack_from_file`

Describe reading a stack from a Ruby template

#### `stack_from_block`

Describe building a stack from an inline Ruby block

### Cfn Client

#### `converge`

Describe programatically converging a stack

#### `tail`

Describe programatically following the Cfn log

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cfer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

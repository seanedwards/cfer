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
      cfer converge [OPTIONS] <stack-name>   # Converges a cloudformation stack according to the template
      cfer generate [OPTIONS] <template.rb>  # Generates a CloudFormation template by evaluating a Cfer template
      cfer help [COMMAND]                    # Describe available commands or one specific command
      cfer tail <stack-name>                 # Follows stack events on standard output as they occur

#### Global options

* `--profile <profile>`: The AWS profile to use (from your `~/.aws/credentials` file)
* `--region <region>`: The AWS region to use
* `--verbose`: Also print debugging messages

#### `generate <template.rb>`

The `generate` subcommand evaluates the given Ruby script and prints the CloudFormation stack JSON to standard output.

The following options may be used with the `generate` command:

* `--no-pretty-print`: Print minified JSON

#### `converge <stack-name>`

Creates or updates a CloudFormation stack according to the specified template.

The following options may be used with the `converge` command:

* `--follow` (`-f`): Follows stack events on standard output as the create/update process takes place. 
* `--stack-file <template.rb>`: Reads this file from the filesystem, rather than the default `<stack-name>.rb`
* `--parameters <Key1>:<Value1> <Key2>:<Value2> ...`: Specifies input parameters, which will be available to Ruby in the `parameters` hash, or to CloudFormation by using the `Fn::ref` function
* `--on-failure <DELETE|ROLLBACK|DO_NOTHING>`: Specifies the action to take when a stack creation fails. Has no effect if the stack already exists and is being updated.

#### `tail <stack-name>`

Prints the latest `n` stack events, and optionally follows events while a stack is converging.

The following options may be used with the `tail` command:

* `--follow` (`-f`): Follows stack events on standard output as the create/update process takes place. 
* `--number` (`-n`): Print the last `n` stack events.

### Template Anatomy

#### Parameters

Parameters may be defined using the `parameter` function:

```ruby
parameter :ParameterName,
  type: 'String',
  default: 'ParameterValue'
```

As with command-line input parameters, a parameter's default value may have the form `@stack.output` to look up output values from other stacks in the same account and region.

Any parameter can be referenced either in Ruby by using the `parameters` hash:

```ruby
parameters[:ParameterName]
```



Parameters can also be used in a CloudFormation reference by using the `Fn::ref` function:

```ruby
Fn::ref(:ParameterName)
```

#### Resources

Resources may be defined using the `resource` function:

```ruby
resource :ResourceName, 'AWS::CloudFormation::CustomResource', AttributeName: {:attribute_key => 'attribute_value'} do
  property_name 'property_value'
end
```

Gets transformed into the corresponding CloudFormation block:

```json
"ResourceName": {
  "Type": "AWS::CloudFormation::CustomResource",
  "AttributeName": {
    "attribute_key": "attribute_value"
  },
  "Properties": {
    "PropertyName": "property_value"
  }
}
```

#### Outputs

Outputs may be defined using the `output` function:

```ruby
output :OutputName, Fn::ref(:ResourceName)
```

## SDK

Describe how to use Cfer as a gem embedded in something else

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

## Contributing

This project uses [git-flow](http://nvie.com/posts/a-successful-git-branching-model/). Please name branches and pull requests according to that convention.

Always use `--no-ff` when merging into `develop` or `master`.

### New features

* Branch from `develop`
* Merge into `develop`
* Name branch `feature/<feature-name>`

### Unreleased bugs

* Branch from `develop`
* Merge into `develop`
* Name branch `bugfix/<issue-id>`

### Bugfixes against releases

* Branch from `master`
* Merge into `develop` and `master`
* Name branch `hotfix/<issue-id>`

### Releases

* Branch from `develop`
* Merge into `develop` and `master`
* Name branch `release/<major.minor>`


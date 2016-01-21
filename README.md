# Cfer

[![Build Status](https://travis-ci.org/seanedwards/cfer.svg?branch=master)](https://travis-ci.org/seanedwards/cfer)
[![Coverage Status](https://coveralls.io/repos/seanedwards/cfer/badge.svg)](https://coveralls.io/r/seanedwards/cfer)
[![Gem Version](https://badge.fury.io/rb/cfer.svg)](http://badge.fury.io/rb/cfer)

Cfer is a lightweight toolkit for managing CloudFormation templates.

Read about Cfer [here](http://tilmonedwards.com/2015/07/28/cfer.html).

If you're interested in hearing more about Cfer, and other DevOps automation projects I'm working on, sign up for the [Impose Mailing List](https://impose.sh/).

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

To quickly see Cfer in action, try converging the example stacks:

```bash
cfer converge vpc -t examples/vpc.rb --profile [YOUR-PROFILE] --region [YOUR-REGION]
cfer converge instance -t examples/instance.rb --profile [YOUR-PROFILE] --region [YOUR-REGION] --parameters KeyName:[YOUR-EC2-SSH-KEY]
```

You should see something like this:

![Demo](cfer-demo.gif)

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

See the `examples` directory for some examples of complete templates.

#### Parameters

Parameters may be defined using the `parameter` function:

```ruby
parameter :ParameterName,
  type: 'String',
  default: 'ParameterValue'
```

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

Outputs may be retireved from other stacks anywhere in a template by using the `lookup_output` function.

```ruby
lookup_output('stack_name', 'output_name')
```

#### Including code from multiple files

Templates can get pretty large, and splitting template code into multiple
files can help keep things more manageable. The `include_template`
function works in a similar way to ruby's `require_relative`, but
within the context of the CloudFormation stack:

```ruby
include_template 'ec2.rb'
```

You can also include multiple files in a single call:

```ruby
include_template(
  'stack/ec2.rb',
  'stack/elb.rb'
)
```

The path to included files is relative to the base template file
(e.g. the `converge` command `-t` option).

## SDK

Embedding the Cfer SDK involves interacting with two components: The `Client` and the `Stack`.
The Cfer `Client` is the interface with the Cloud provider.

### Basic API

The simplest way to use Cfer from Ruby looks similar to the CLI:

```ruby
  Cfer.converge! '<stack-name>', template: '<template-file>'
```

This is identical to running `cfer converge <stack-name> --template <template-file>`, but is better suited to embedding in Rakefiles, chef recipes, or your own Ruby scripts.
See the Rakefile in this repository for how this might look.

### Cfn Client

The Client is a wrapper around Amazon's CloudFormation client from the AWS Ruby SDK.
Its purpose is to interact with the CloudFormation API.

Create a new client:

```ruby
Cfer::Cfn::Client.new(stack_name: <stack_name>)
```

`Cfer::Cfn::Client` also accepts options to be passed into the internal `Aws::CloudFormation::Client` constructor.

#### `converge(stack)`

Creates or updates the CloudFormation stack to match the input `stack` object. See below for how to create Cfer stack objects.

```ruby
client.converge(<stack>)
```

#### `tail(options = {})`

Yields to the specified block for each CloudFormation event that qualifies given the specified options.

```ruby
client.tail number: 1, follow: true do |event|
  # Called for each CloudFormation event, as they occur, until the stack enters a COMPLETE or FAILED state.
end
```

### Cfer Stacks

A Cfer stack represents a baked CloudFormation template, which is ready to be converted to JSON.

Create a new stack:

#### `stack_from_file`

```ruby
stack = Cfer::stack_from_file(<file>, client: <client>)
```

#### `stack_from_block`

```ruby
stack = Cfer::stack_from_block(client: <client>) do
  # Stack definition goes here
end
```

## Contributing

This project uses [git-flow](http://nvie.com/posts/a-successful-git-branching-model/). Please name branches and pull requests according to that convention.

Always use `--no-ff` when merging into `develop` or `master`.

This project also contains a [Code of Conduct](CODE_OF_CONDUCT.md), which should be followed when submitting feedback or contributions to this project.

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

# Release Notes

## 0.3.0

* Removes automatic parameter mapping in favor of an explicit function available to resources. (Fixes Issue #8)

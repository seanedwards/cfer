# Cfer

[![Build Status](https://travis-ci.org/seanedwards/cfer.svg?branch=master)](https://travis-ci.org/seanedwards/cfer)
[![Gem Version](https://badge.fury.io/rb/cfer.svg)](http://badge.fury.io/rb/cfer)
[![Code Climate](https://codeclimate.com/github/seanedwards/cfer/badges/gpa.svg)](https://codeclimate.com/github/seanedwards/cfer)
[![Test Coverage](https://codeclimate.com/github/seanedwards/cfer/badges/coverage.svg)](https://codeclimate.com/github/seanedwards/cfer/coverage)
[![Issue Count](https://codeclimate.com/github/seanedwards/cfer/badges/issue_count.svg)](https://codeclimate.com/github/seanedwards/cfer)


Cfer is a lightweight toolkit for managing CloudFormation templates.

Read about Cfer [here](https://github.com/seanedwards/cfer/blob/master/examples/vpc.md).

## Support

Cfer is pre-1.0 software, and may contain bugs or incomplete features. Please see the [license](https://github.com/seanedwards/cfer/blob/master/LICENSE.txt) for disclaimers.

If you would like support or guidance on Cfer, or CloudFormation in general, I offer DevOps consulting services. Please [Contact me](mailto:stedwards87+cfer@gmail.com) and I'll be happy to discuss your needs.

You can also find me at [@tilmonedwards](https://twitter.com/tilmonedwards). If you use Cfer, or are considering it, I'd love to hear from you.

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
cfer converge instance -t examples/instance.rb --profile [YOUR-PROFILE] --region [YOUR-REGION] KeyName=[YOUR-EC2-SSH-KEY]
```

You should see something like this:

![Demo](https://raw.githubusercontent.com/seanedwards/cfer/master/doc/cfer-demo.gif)

### Command line

    COMMANDS
        converge     Create or update a cloudformation stack according to the template
        delete       Deletes a CloudFormation stack
        describe     Fetches and prints information about a CloudFormation
        estimate     Prints a link to the Amazon cost caculator estimating the cost of the resulting CloudFormation stack
        generate     Generates a CloudFormation template by evaluating a Cfer template
        help         show help
        tail         Follows stack events on standard output as they occur

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

**Note**: using this syntax results in parameter substitution during template generation. In other words a resource that references a parameter using this syntax cannot be changed through the CloudFormation console. Use the syntax below if this is desirable.

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

This project also contains a [Code of Conduct](https://github.com/seanedwards/cfer/blob/master/CODE_OF_CONDUCT.md), which should be followed when submitting feedback or contributions to this project.

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

[Change Log](https://github.com/seanedwards/cfer/blob/master/CHANGELOG.md)


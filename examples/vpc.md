When I first encountered AWS CloudFormation, I was appalled by the format for about ten minutes. This is the criticism of it that I've heard most often: the unwieldy syntax makes it unapproachable. Writing it by hand is worse than lunch meetings. I don't disagree.

However, I think CloudFormation makes a pretty decent intermediate language. Users of Elasic Beanstalk might notice a bunch of CloudFormation stacks in their account, all containing some kind of Amazon-produced EB magic. This is where CloudFormation excels: Machine-generated infrastructure.

To that end, I took a couple weekends and wrote [Cfer](https://github.com/seanedwards/cfer), a DSL for generating CloudFormation templates in Ruby. [I'm](http://chrisfjones.github.io/coffin/) [not](https://github.com/bazaarvoice/cloudformation-ruby-dsl) [the](https://github.com/stevenjack/cfndsl) [only](https://github.com/Optaros/cloud_builder) [one](https://github.com/rapid7/convection) [doing](https://github.com/cloudtools/troposphere) [this](https://cfn-pyplates.readthedocs.org/en/latest/). But I'll run through an example template, which will help you build a basic VPC in AWS, and at the same time, address some of the features of Cfer that might make CloudFormation a little more appealing to you.

If you find the format of this post difficult to follow, you can see this same example as a fully functional template in [examples/vpc.rb](https://github.com/seanedwards/cfer/blob/develop/examples/vpc.rb)


This template creates the following resources for a basic beginning AWS VPC setup:

1. A VPC
2. A route table to control network routing
3. An Internet gateway to route traffic to the public internet
4. 3 subnets, one in each of the account's first 3 availability zones
5. A default network route to the IGW
6. Associated plumbing resources to link it all together

## Template Parameters

Template parameters allow you to use the same template to build multiple similar instances of parts of your infrastructure. Parameters may be defined using the `parameter` function:

```ruby
parameter :VpcName, default: 'Example VPC'
```

Resources are created using the `resource` function, accepting the following arguments:

1. The resource name (string or symbol)
2. The resource type. See the AWS CloudFormation docs for the [available resource types](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html).


## The VPC Resource

The VPC is the foundation of your private network in AWS.

```ruby
resource :vpc, 'AWS::EC2::VPC' do
```

Each line within the resource block sets a single property. These properties are simply camelized using the ActiveSupport gem's `camelize` function. This means that the `cidr_block` function will set the `CidrBlock` property.

```ruby
cidr_block '172.42.0.0/16'
```

Following this pattern, `enable_dns_support` sets the `EnableDnsSupport` property.

```ruby
enable_dns_support true
enable_dns_hostnames true
instance_tenancy 'default'
```

The `tag` function is available on all resources, and adds keys to the resource's `Tags` property. It accepts the following arguments:

1. Tag name (symbol or string)
2. Tag value

```ruby
tag :DefaultVpc, true
```

Parameters are required at template generation time, and therefore may be referenced using the `parameters` hash anywhere in a template. This will render the parameter value as a string constant in the CloudFormation JSON output.

```ruby
tag :Name, parameters[:VpcName]
```

Finally, we can finish this resource by closing the block that we started when we called the `resource` function.

```ruby
end
```

## The Internet Gateway

Instances in your VPC will need to be able to access the internet somehow, and an internet gateway is the mechanism for making this happen. Let's create one.

If there are no properties to set on a resource, the `do..end` block may be omitted entirely

```ruby
resource :defaultigw, 'AWS::EC2::InternetGateway'
```

## Attaching the Gateway

For a gateway to be routable, it needs to be attached to a specific VPC using a "VPC Gateway Attachment" resource.

`Fn::ref` serves the same purpose as CloudFormation's `{"Ref": ""}` intrinsic function.

```ruby
resource :vpcigw, 'AWS::EC2::VPCGatewayAttachment' do
  vpc_id Fn::ref(:vpc)
  internet_gateway_id Fn::ref(:defaultigw)
end
```

## The Route Table

A VPC also needs a route table. Every VPC comes with a default route table, but I like to create my own resources so that they're all expressed in the template.

```ruby
resource :routetable, 'AWS::EC2::RouteTable' do
  vpc_id Fn::ref(:vpc)
end
```

## The Default Route

We also have to set up a default route, so that any traffic that the VPC doesn't recognize gets routed off to the internet gateway.

The `resource` function accepts one additional parameter that was not addressed above: the options hash. Additional options passed here will be placed inside the resource, but outside the `Properties` block. In this case, we've specified that the default route explicitly depends on the VPC Internet Gateway.

As of this writing, this is actually a required workaround for this template. The gateway must be attached to the VPC before a route can be created to it, but since the gateway attachment isn't actually referenced anywhere in this resource, we need to explicitly declare that dependency.

```ruby
resource :defaultroute, 'AWS::EC2::Route', DependsOn: [:vpcigw] do
  route_table_id Fn::ref(:routetable)
  gateway_id Fn::ref(:defaultigw)
  destination_cidr_block '0.0.0.0/0'
end
```

## The Subnets

Naturally, you'll also need networks. Like the route table, I like to create my own so that I have control of their configuration inside the template.

Notice `Fn::select`, `Fn::get_azs` and `AWS::region` in this snippet. These all map to the CloudFormation functions and variables of the same name.

We'll use Ruby to create three identical subnets:

```ruby
(1..3).each do |i|
```

The subnets themselves will be in the first three availability zones of the account. A more sophisticated template might want to handle this differently.

```ruby
resource "subnet#{i}", 'AWS::EC2::Subnet' do
  availability_zone Fn::select(i, Fn::get_azs(AWS::region))
  cidr_block "172.42.#{i}.0/24"
  vpc_id Fn::ref(:vpc)
end
```

Now the subnet needs to be associated with the route table, so that hosts in the subnet are able to access the rest of the network and the internet.

```ruby
resource "srta#{i}".to_sym, 'AWS::EC2::SubnetRouteTableAssociation' do
  subnet_id Fn::ref("subnet#{i}")
  route_table_id Fn::ref(:routetable)
end
```

We can use the `output` function to output the subnet IDs we've just created. We'll go over how Cfer makes this useful in part 2 of this post.

```ruby
output "subnetid#{i}", Fn::ref("subnet#{i}")
```

And of course, end the iteration block.

```ruby
end
```


Finally, let's output the VPC ID too, since we'll probably need that in other templates.

```ruby
output :vpcid, Fn::ref(:vpc)
```

## Converging the Stack

Now that you have your template ready, you'll be able to use Cfer to create or update a CloudFormation stack:

```bash
cfer converge vpc -t examples/vpc.rb --profile ${AWS_PROFILE} --region ${AWS_REGION}
```

Which should produce something like this.

![Cfer Demo]({{ site.url }}/images/cfer/cfer-demo.gif)

Use `cfer help` to get more usage information, or check `README.md` and `Rakefile` in the source repository to see how to embed Cfer into your own projects.

## In Part 2...

In part 2, we'll go over some additional features of Cfer. If you want a preview, you can check out the [instance.rb](https://github.com/seanedwards/cfer/blob/develop/examples/instance.rb) example, which covers how you can use Cfer to create security groups, instances with automated provisioning, and how to automatically look up outputs from other stacks.

Cfer can be found on [GitHub](https://github.com/seanedwards/cfer) and [RubyGems](https://rubygems.org/gems/cfer) and is MIT licensed. Pull requests are welcome.


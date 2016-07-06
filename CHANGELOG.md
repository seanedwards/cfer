# Cfer Change Log

## 0.5.0

### Enhancements
* Adds support for Pre-build and Post-build hooks for resources and stacks.
* Relaxes some version constraints to make it easier to integrate with older Rails projects.
* Pulled stack validation out into an extension using post-build hooks.
* Adds some extension methods to improve usability of certain resources.
* Namespace cleanup.

## 0.4.2

### Bugfixes
* Templates now uploaded to S3 in all cases where they should be.
* Fixes extensions (should be `class_eval`, not `instance_eval`)

## 0.4.0

### **BREAKING CHANGES**
* Provisioning is removed from Cfer core and moved to [cfer-provisioning](https://github.com/seanedwards/cfer-provisioning)

### Enhancements
* Adds support for assume-role authentication with MFA (see: https://docs.aws.amazon.com/cli/latest/userguide/cli-roles.html)
* Adds support for yml-format parameter files with environment-specific sections.
* Adds a DSL for IAM policies.
* Adds `cfer estimate` command to estimate the cost of a template using the AWS CloudFormation cost estimation API.
* Enhancements to chef provisioner to allow for references in chef attributes. (Thanks to @eropple)
* Adds continue/rollback/quit selection when `^C` is caught during a converge.
* Stores Cfer version and Git repo information in the Repo metadata.
* Added support for uploading templates to S3 with the `--s3-path` and `--force-s3` options.
* Added new way of extending resources, making plugins easier.
* Added support for [CloudFormation Change Sets](https://aws.amazon.com/blogs/aws/new-change-sets-for-aws-cloudformation/) via the `--change` option.

### Bugfixes

## 0.3.0

### Enhancements:
* `parameters` hash now includes parameters that are set on the existing stack, but not passed in via CLI during a stack update.
* `parameters` hash now includes defaults for parameters that were not passed on the CLI during a stack creation.
* Adds a `lookup_output` function, for looking up outputs of stacks in the same account+region. (See #8)
* Adds provisioning for cfn-init and chef-solo, including resource signaling.
* Adds support for stack policies.
* Cfer no longer validates parameters itself. CloudFormation will throw an error if something is wrong.
* Adds release notes to the README.

### Bugfixes:
* Removes automatic parameter mapping in favor of an explicit function available to resources. (Fixes Issue #8)
* No more double-printing the stack summary when converging a stack with tailing enabled.
* Update demo to only use 2 AZs, since us-west-1 only has two.
* `AllowedValues` attribute on parameters is now an array, not a CSV string. (Thanks to @rlister)

## 0.2.0

### Enhancements:
* Adds support for including other files via `include_template` function.
* Adds basic Dockerfile


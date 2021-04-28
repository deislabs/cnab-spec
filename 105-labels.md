---
title: Labels
weight: 105
---

# Labels

This section describes the format for labels, which MAY be defined on a bundle or other CNAB documents.

Labels are stored as string key/value pairs, using the same schema as [Kubernetes labels].
The requirements below are taken from the Kubernetes label documentation, with the reserved prefix updated to be specific to CNAB.

Labels are key/value pairs. Valid label keys have two segments: an optional prefix and name, separated by a slash (/).
The name segment is required and MUST be 63 characters or less, beginning and ending with an alphanumeric character ([a-z0-9A-Z]) with dashes (-), underscores (_), dots (.), and alphanumerics between.
The prefix is optional. 
If specified, the prefix MUST be a DNS subdomain: a series of DNS labels separated by dots (.), not longer than 253 characters in total, followed by a slash (/).

If the prefix is omitted, the label key is presumed to be private to the installation.
CNAB tools which add labels to end-user objects MUST specify a prefix.

Valid label keys and values:

* MUST be 63 characters or less (cannot be empty),
* MUST begin and end with an alphanumeric character ([a-z0-9A-Z]),
* MAY contain dashes (-), underscores (_), dots (.), and alphanumerics between.

## Reserved Labels

The **cnab.io/** prefix is reserved for use by this specification.
The following sections define reserved label keys and how they may be applied by a bundle.
CNAB tools MAY use these labels to search for and filter bundles.

### cnab.io/app

The label key `cnab.io/app` MAY be used by a bundle to indicate the name of the application distributed by the bundle.
For example, a bundle that deploys Wordpress could use the label `cnab.io/app=wordpress`.

### cnab.io/appVersion

The label key `cnab.io/appVersion` MAY be used by a bundle to indicate the version of the application distributed by the bundle.
For example a bundle that installs Redis 6.2.1 could use the label `cnab.io/appVersion=6.2.1`.

### cnab.io/executor

The label key `cnab.io/executor` MAY be used by a claim or claim result to indicate the tool that executed the bundle.
For example, Porter could apply the label `cnab.io/executor=porter` to the claim when it executes the bundle.

### cnab.io/executorVersion

The label key `cnab.io/executorVersion` MAY be used by a claim or claim result to indicate the version of the tool that executed the bundle.
For example, Porter could apply the label `cnab.io/executorVersion=v0.36.0` to the claim when it executes the bundle.

### cnab.io/retry

The label `cnab.io/retry` MAY be used on a claim result to indicate that the previous attempt to execute a bundle operation was retried.
For example, the first time the bundle was installed, it failed.
A tool MAY choose to retry the operation using the same claim, and apply the label `cnab.io/retry` to the result of the retried operation.

[Kubernetes labels]: https://github.com/kubernetes/website/blob/18f3eae6efc2d3c209f4fde7a46d93d1c1c396c3/content/en/docs/concepts/overview/working-with-objects/labels.md#syntax-and-character-set

---
title: Namespaces
weight: 106
---

# Namespaces

This section describes the schema for document namespaces, which can be defined on any document stored in the host environment, such as claims.
A document MAY be scoped to a namespace. When a namespace is unset or empty, the document is considered to be global.
Documents in a namespace MAY reference a global document, but global documents MUST NOT reference namespaced documents, and namespaced documents MUST NOT reference documents in a different namespace.

Isolating data in the host environment by namespace allows multiple users to share an environment while isolating installations, so that names can be reused across namespaces. For example, two users can have their own namespaces and both install a bundle in their namespace without worrying over the names colliding.

Namespaces also make it easier to organize environment data. For example by creating a namespace for a "staging" environment, and another for "production" commands can be easily reused between environments and the environment can be targeted by changing the namespace of the operation.

Namespace values:

* MUST be 63 characters or less (cannot be empty),
* MUST begin and end with an alphanumeric character ([a-z0-9A-Z]),
* MAY contain dashes (-), underscores (_), dots (.), and alphanumerics between.

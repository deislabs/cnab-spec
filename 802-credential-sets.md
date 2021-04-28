---
title: Credential Sets
weight: 802
---

# Credential Sets

This is a non-normative section that describes how credentials can be passed into an invocation image. This strategy is implemented by [Duffle] and [Porter].

[Duffle]: https://duffle.sh
[Porter]: https://porter.sh

## Credential Mapping

In the bundle descriptor, credentials are declared like this:

```json
{
  "credentials": {
    "hostkey": {
      "env": "HOST_KEY",
      "path": "/etc/hostkey.txt"
    },
    "image_token": {
      "env": "AZ_IMAGE_TOKEN"
    },
    "kubeconfig": {
      "path": "/home/.kube/config"
    }
  }
}
```

The description above indicates that there are three credentials required to execute this bundle.

The names on each credential are unique within the bundle:

- `kubeconfig`
- `image_token`
- `hostkey`

That name can be used to reference the credential from tooling. Consequently, tooling may choose to construct a map from an external value to the credential name.

Porter, for example, maps local credentials to bundle credentials by _credential sets_. Here is an example:

```json
{
   "name": "test_credentials",
   "namespace": "test",
   "created": "2020-01-20T12:00:00.000Z",
   "modified": "2020-01-28T18:30:00.111Z",
   "labels": {
     "env": "dev"
   },
   "credentials": [
      {
         "name": "kubeconfig",
         "source": {
            "path": "$HOME/.kube/config"
         }
      },
      {
         "name": "image_token",
         "source": {
            "value": "1234aaaaa"
         }
      },
      {
         "name": "hostkey",
         "source": {
            "env": "HOSTKEY"
         }
      }
   ]
}
```

This credential set tells the client application (`porter`) to map CNAB bundle credential sections to certain local values:

- When a bundle requests `kubeconfig`, a file will be loaded from the local file system and injected into the container at `/home/.kube/config`
- When a bundle requests `image_token`, the literal value `1234aaaaa` will be loaded into the environment variable `AZ_IMAGE_TOKEN`
- When a bundle requests `hostkey`, the local environment variable `$HOSTKEY` will be dereferenced, and its value injected into the container's `HOST_KEY` variable as well as the container's filesystem path `/etc/hostkey.txt`.

Similar tooling could choose to load the values by name from a database, vault, or file.

The created and modified timestamps are in [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) format.

### Namespaces

Credential Sets MAY be scoped to a namespace.
The combination of namespace and name must be unique.
When a namespace is unset or empty, the document is considered to be global.
Documents in a namespace MAY reference a global document, but global documents MUST NOT reference namespaced documents and namespaced documents MUST NOT reference documents in a different namespace.

### Labels

Credential Sets MAY define labels which can be used by storage providers to query for the document.
For example, retrieving credential sets that were generated from a given bundle.

How labels are used for querying is out-of-scope of this spec and is up to the implementing storage provider.

## Credential Injection

Credentials must be injected into the runtime of the invocation image. The following strategies are known to work:

- Environment Variables:
  - Injected via environment variable services (Docker and Kubernetes)
  - Loaded into VMs via cloud-init
- Paths:
  - Mounted as volumes (or wrappers, such as Kubernetes secrets)
  - Injected at runtime into the top layer of the container
  - Loaded into VMs via cloud-init

Next section: [Well known custom actions](804-well-known-custom-actions.md)

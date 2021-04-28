---
title: Representing CNAB bundles in OCI Registries
weight: 201
---

# Representing CNAB bundles in OCI Registries

This section describes how the bundle file and the information contained in the bundle MUST be represented when distributing bundles using OCI registries.

A CNAB is made up of a descriptor file (`bundle.json`), one or more invocation images, and a list of zero or more component images. Each of these objects can be individually packaged into an [OCI manifest][oci-manifest] or [OCI index][oci-index]. An OCI index can then be used to combine these all into a single object.

Runtimes and registries MAY choose to _relocate_ the images and invocation images referenced in the bundle to the registry where the bundle is pushed, but in its simplest form, a CNAB bundle MAY be represented in an OCI registry by the canonical `bundle.json` file descriptor, referenced in an OCI index (or manifest list).

![](https://i.imgur.com/PfTcKOm.png)

### `bundle.json` manifest

The `bundle.json` MUST be serialized as canonical JSON and MUST be stored in the registry as a blob. This blob MUST be referenced by its digest in an OCI manifest. The manifest media type SHOULD be `application/vnd.cnab.bundle.config.v1+json` but MAY be a standard container image config type (`application/vnd.oci.image.config.v1+json`) if the target registry does not support the CNAB media type.

### Example

The following non-canonical `bundle.json` file will be used as an example:

```json
{
  "schemaVersion": "v1.0.0",
  "name": "helloworld",
  "version": "0.1.1",
  "description": "A short description of your bundle",
  "keywords": ["helloworld", "cnab", "tutorial"],
  "maintainers": [
    {
      "name": "Jane Doe",
      "email": "jane.doe@example.com",
      "url": "https://example.com"
    }
  ],
  "invocationImages": [
    {
      "imageType": "docker",
      "image": "cnab/helloworld:0.1.1",
      "size": 942,
      "contentDigest": "sha256:a59a4e74d9cc89e4e75dfb2cc7ea5c108e4236ba6231b53081a9e2506d1197b6",
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json"
    }
  ],
  "images": null,
  "parameters": null,
  "credentials": null
}
```

The `bundle.json` is serialized into canonical JSON and is pushed as a blob to the registry. This blob is then referenced by its digest (for example `sha256:e91b9dfcbbb3b88bac94726f276b89de46e4460b55f6e6d6f876e666b150ec5b`) as the object config.

The bundle is encapsulated in an OCI manifest which is then referenced as part of an OCI index (or manifest list):

```json
{
  "schemaVersion": 2,
  "config": {
    "mediaType": "application/vnd.cnab.bundle.config.v1+json",
    "digest": "sha256:e91b9dfcbbb3b88bac94726f276b89de46e4460b55f6e6d6f876e666b150ec5b",
    "size": 498
  },
  "layers": null
}
```

The bundle file MUST be stored in the OCI registry, as it is the canonical representation of a CNAB bundle, and is the object that is used to compute the signature for a thin bundle.
While implementations MAY choose to surface information from the bundle as top-level annotations in the OCI representations, they MUST store the unmodified bundle file as a blob.

The bundle file and registry location MAY be used by implementations to generate relocation maps at runtime.

### Invocation images

Each invocation image SHOULD be packaged as an OCI image but MAY be packaged as a Docker v2 image. If there are multiple invocation images, these SHOULD be referenced by an OCI index but MAY be referenced by a Docker manifest list.

### Component images

Each component image SHOULD be packaged as an OCI image but MAY be packaged as a Docker v2 image. In the case that a component has multiple equivalent forms, such as a multiarch container image, each component MUST be packaged and then SHOULD be referenced by an OCI index but MAY be referenced by a Docker manifest list.

## Top-level representation

The top-level representation of the CNAB SHOULD be an OCI index but may be a Docker manifest list.

The `manifests` list MUST be filled in the following order:

- A reference to packaged `bundle.json` manifest
- References to the invocation images
- References to the component images

### Example

```json
{
  "schemaVersion": 2,
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:6ec4fd695cace0e3d4305838fdf9fcd646798d3fea42b3abb28c117f903a6a5f",
      "size": 188,
      "annotations": {
        "io.cnab.manifest.type": "config"
      }
    },
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "digest": "sha256:a59a4e74d9cc89e4e75dfb2cc7ea5c108e4236ba6231b53081a9e2506d1197b6",
      "size": 942,
      "annotations": {
        "io.cnab.manifest.type": "invocation"
      }
    }
  ],
  "annotations": {
    "io.cnab.keywords": "[\"helloworld\",\"cnab\",\"tutorial\"]",
    "io.cnab.labels": "{\"cnab.io/app\":\"helloworld\",\"cnab.io/appVersion\":\"1.2.3\"}",
    "io.cnab.runtime_version": "v1.0.0",
    "org.opencontainers.artifactType": "application/vnd.cnab.manifest.v1",
    "org.opencontainers.image.authors": "[{\"name\":\"Jane Doe\",\"email\":\"jane.doe@example.com\",\"url\":\"https://example.com\"}]",
    "org.opencontainers.image.description": "A short description of your bundle",
    "org.opencontainers.image.title": "helloworld",
    "org.opencontainers.image.version": "0.1.1"
  }
}
```

[oci-index]: https://github.com/opencontainers/image-spec/blob/master/image-index.md
[oci-manifest]: https://github.com/opencontainers/image-spec/blob/master/manifest.md

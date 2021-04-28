---
title: The bundle.json File
weight: 101
---

# The bundle.json File

This section describes the format and function of the `bundle.json` document.

The `bundle.json` file is a representation of bundle metadata. It MUST be represented as [Canonical JSON](http://wiki.laptop.org/go/Canonical_JSON). While Canonical JSON is parseable by any JSON parser, its serialized form is consistent. This is a necessity when comparing two textual representations of the same data (such as when hashing).

> JSON data in this document has been formatted for readability using line breaks and indentation. This is not Canonical JSON. These examples were generated using the UNIX command `canonjson SOURCE.json | jq .` Where appropriate, the Canonical JSON text will also be provided. Small snippets of JSON may be shown in the order in which the fields are described (for clarity) rather than in Canonical JSON order.

A `bundle.json` is broken down into the following categories of information:

- The schema version of the bundle, as a string with a `v` prefix. This schema is to be referenced as `v1` or `v1.1.0`
- The top-level package information (`name` and `version`)
  - `name`: The bundle name, including namespacing. The namespace can have one or more elements separated by a dot (e.g. `acme.tunnels.wordpress`). The left most element of the namespace is the most general moving toward more specific elements on the right.
  - `version`: Semantic version of the bundle
  - `description`: Short description of the bundle
- Information on the invocation images, as an array
- A map of images included with this bundle, as a `component name` to `image definition` map
- A specification of which parameters MAY be overridden, and a reference to a validation schema
- A list of credentials (name and desired location) that the application needs
- An OPTIONAL description of custom actions that this bundle implements
- A list of outputs (name, type and location) that the application produces
- A set of schema definitions used to validate user input

The bundle definition is made accessible from inside the invocation image in order to allow the run tool to reference information in the file. The bundle.json MUST be mounted to /cnab/bundle.json.

The `bundle.json` is also known as a _thin bundle_. Bundles come in two formats: thick and thin. Read more about thick and thin bundles in the [bundle formats section](104-bundle-formats.md).

The examples given in this documentation predominantly use thin bundles. Examples of thick bundles will be noted as such.

The following is an example of a `bundle.json` for a bundled distributed as a _thin_ bundle:

```json
{
   "credentials":{
      "hostkey":{
         "env":"HOST_KEY",
         "path":"/etc/hostkey.txt"
      }
   },
   "custom":{
      "com.example.backup-preferences":{
         "frequency":"daily"
      },
      "com.example.duffle-bag":{
         "icon":"https://example.com/icon.png",
         "iconType":"PNG"
      }
   },
   "definitions":{
      "http_port":{
         "default":80,
         "maximum":10240,
         "minimum":10,
         "type":"integer"
      },
      "port":{
         "maximum":65535,
         "minimum":1024,
         "type":"integer"
      },
      "string":{
         "type":"string"
      },
      "x509Certificate":{
         "contentEncoding":"base64",
         "contentMediaType":"application/x-x509-user-cert",
         "type":"string",
         "writeOnly":true
      }
   },
   "description":"An example 'thin' helloworld Cloud-Native Application Bundle",
   "images":{
      "my-microservice":{
         "contentDigest":"sha256:aaaaaaaaaaaa...",
         "description":"my microservice",
         "image":"example/microservice:1.2.3"
      }
   },
   "invocationImages":[
      {
         "contentDigest":"sha256:aaaaaaa...",
         "image":"example/helloworld:0.1.0",
         "imageType":"docker"
      }
   ],
   "labels": {
      "cnab.io/app": "my-microservice",
      "cnab.io/appVersion": "1.2.3"
   },
   "maintainers":[
      {
         "email":"matt.butcher@microsoft.com",
         "name":"Matt Butcher",
         "url":"https://example.com"
      }
   ],
   "name":"helloworld",
   "outputs":{
      "clientCert":{
         "definition":"x509Certificate",
         "path":"/cnab/app/outputs/clientCert"
      },
      "hostName":{
         "applyTo":[
            "install"
         ],
         "definition":"string",
         "description":"the hostname produced installing the bundle",
         "path":"/cnab/app/outputs/hostname"
      },
      "port":{
         "definition":"port",
         "path":"/cnab/app/outputs/port"
      }
   },
   "parameters":{
      "backend_port":{
         "definition":"http_port",
         "description":"The port that the back-end will listen on",
         "destination":{
            "env":"BACKEND_PORT"
         }
      }
   },
   "schemaVersion":"v1.1.0",
   "version":"0.1.2"
}
```

Source: [101.01-bundle.json](examples/101.01-bundle.json)

The canonical JSON version of the above is:

<!-- prettier-ignore -->
```json
{"credentials":{"hostkey":{"env":"HOST_KEY","path":"/etc/hostkey.txt"}},"custom":{"com.example.backup-preferences":{"frequency":"daily"},"com.example.duffle-bag":{"icon":"https://example.com/icon.png","iconType":"PNG"}},"definitions":{"http_port":{"default":80,"maximum":10240,"minimum":10,"type":"integer"},"port":{"maximum":65535,"minimum":1024,"type":"integer"},"string":{"type":"string"},"x509Certificate":{"contentEncoding":"base64","contentMediaType":"application/x-x509-user-cert","type":"string","writeOnly":true}},"description":"An example 'thin' helloworld Cloud-Native Application Bundle","images":{"my-microservice":{"contentDigest":"sha256:aaaaaaaaaaaa...","description":"my microservice","image":"example/microservice:1.2.3"}},"invocationImages":[{"contentDigest":"sha256:aaaaaaa...","image":"example/helloworld:0.1.0","imageType":"docker"}],"labels":{"cnab.io/app":"helloworld"},"maintainers":[{"email":"matt.butcher@microsoft.com","name":"Matt Butcher","url":"https://example.com"}],"name":"helloworld","outputs":{"clientCert":{"definition":"x509Certificate","path":"/cnab/app/outputs/clientCert"},"hostName":{"applyTo":["install"],"definition":"string","description":"the hostname produced installing the bundle","path":"/cnab/app/outputs/hostname"},"port":{"definition":"port","path":"/cnab/app/outputs/port"}},"parameters":{"backend_port":{"definition":"http_port","description":"The port that the back-end will listen on","destination":{"env":"BACKEND_PORT"}}},"schemaVersion":"v1.1.0","version":"0.1.2"}
```

What follows is an example of a thick bundle. Notice how the `invocationImage` and `images` fields reference the underlying docker image manifest (`application/vnd.docker.distribution.manifest.v2+json`), which in turn references the underlying images:

```json
{
   "credentials":{
      "hostkey":{
         "env":"HOST_KEY",
         "path":"/etc/hostkey.txt"
      },
      "image_token":{
         "env":"AZ_IMAGE_TOKEN", 
         "applyTo": ["install"]
      },
      "kubeconfig":{
         "path":"/home/.kube/config"
      }
   },
   "definitions":{
      "http_port":{
         "default":80,
         "maximum":10240,
         "minimum":10,
         "type":"integer"
      },
      "port":{
         "maximum":65535,
         "minimum":1024,
         "type":"integer"
      },
      "string":{
         "type":"string"
      },
      "x509Certificate":{
         "contentEncoding":"base64",
         "contentMediaType":"application/x-x509-user-cert",
         "type":"string",
         "writeOnly":true
      }
   },
   "description":"An example 'thick' helloworld Cloud-Native Application Bundle",
   "images":{
      "my-microservice":{
         "contentDigest":"sha256:bbbbbbbbbbbb...",
         "description":"helloworld microservice",
         "image":"example/helloworld:0.1.2",
         "mediaType":"application/vnd.docker.distribution.manifest.v2+json",
         "labels":{
            "architecture":"amd64",
            "os":"linux"
         },
         "size":1337
      }
   },
   "invocationImages":[
      {
         "contentDigest":"sha256:aaaaaaaaaaaa...",
         "image":"example/helloworld:1.2.3",
         "imageType":"docker",
         "mediaType":"application/vnd.docker.distribution.manifest.v2+json",
         "labels":{
            "architecture":"amd64",
            "os":"linux"
         },
         "size":1337
      }
   ],
   "labels": {
      "cnab.io/app": "my-microservice",
      "cnab.io/appVersion": "0.1.2"
   },
   "name":"helloworld",
   "outputs":{
      "clientCert":{
         "definition":"x509Certificate",
         "path":"/cnab/app/outputs/clientCert"
      },
      "hostName":{
         "applyTo":[
            "install"
         ],
         "definition":"string",
         "description":"the hostname produced installing the bundle",
         "path":"/cnab/app/outputs/hostname"
      },
      "port":{
         "definition":"port",
         "path":"/cnab/app/outputs/port"
      }
   },
   "parameters":{
      "backend_port":{
         "definition":"http_port",
         "description":"The port that the backend will listen on",
         "destination":{
            "path":"/path/to/backend_port"
         }
      }
   },
   "schemaVersion":"v1.1.0",
   "version":"1.0.0"
}

```

Source: [101.02-bundle.json](examples/101.02-bundle.json)

In descriptions below, fields marked REQUIRED MUST be present in any conformant bundle descriptor, while fields not thusly marked are considered optional.

## Dotted Names

Within this specification, certain user-supplied names SHOULD be expressed in the form of a _dotted name_, which is defined herein as a name composed by concatenating name components together, separated by dot (`.`) characters. Name components contain only Unicode characters with the General Category of Letter (L) and the dash (`-`) character. Whitespace characters are not allowed within names, and there is no escape sequence for the dot character.
A string MUST have at least one dot to be considered a _dotted name_.

Dotted names are used to encourage name spacing and reduce the likelihood of naming collisions.

Dotted names SHOULD follow the reverse-DNS pattern used by [Java, C#, and other languages](https://en.wikipedia.org/wiki/Reverse_domain_name_notation).
CNAB tools MUST NOT treat these strings as domain names or domain components, as this specification allows characters that are not legal in DNS addresses.

Examples:

- `com.example.myapp.port`
- `org.example.action.status`
- `𝕔𝕠𝕞.𝕖𝕩𝕒𝕞𝕡𝕝𝕖.𝕞𝕪𝕒𝕡𝕡.𝕡𝕠𝕣𝕥`
- `snʇɐʇs.uoıʇɔɐ.ǝʃdɯɐxǝ.ƃɹo`
- `example.foo` (This format MAY be used, but the reverse DNS format is preferred)

## Schema Version

Every `bundle.json` MUST have a `schemaVersion` element.

The schema version must reference the version of the schema used for this document. It follows the [SemVer v2 specification](https://semver.org/). The following pre-release markers are recognized:

- `WD` indicates that the document references a working draft of the specification, and is not considered stable.
- `CR` indicates that the document references a candidate recommendation. Stability is not assured.
- No suffix indicates that the document references a release of the specification, and is considered stable.

The current schema version is `v1.1.0`, which is considered stable.

## Name and Version: Identifying Metadata

The `name` and `version` fields are used to identify the CNAB bundle. Both fields are REQUIRED.
Fields that do not match this specification SHOULD cause failures.

- `name` MUST contain only characters from the [Unicode graphic characters](http://www.unicode.org/glossary/#graphic_character)
- `version` MUST be a [SemVer2](https://semver.org) string

The Unicode graphic character set allowed for `name` includes letters, numbers, punctuation, symbols, and spaces; it does not include newlines or tabs.

## Informational Metadata

The following fields are informational pieces of metadata designed to convey additional information about a bundle, but not to be used as identification for a bundle:

- `description`: A short description of a bundle (OPTIONAL)
- `keywords`: A list of keywords (OPTIONAL)
- `labels`: Key/value pairs of type string that specify identifying attributes of the bundle (OPTIONAL). MUST follow the [CNAB Label Format].
- `license`: The license under which this bundle is covered. This SHOULD use one of the [SPDX License Identifiers](https://spdx.org/licenses/) whenever possible (OPTIONAL)
- `maintainers`: An OPTIONAL list of maintainers, where each maintainer MAY optionally have the following:
  - `name`: Maintainer name
  - `email`: Maintainer's email
  - `url`: URL to relevant maintainer information

## Invocation Images

The `invocationImages` section describes the images that are responsible for bootstrapping the installation. The appropriate invocation image is selected by the CNAB runtime, typically by considering the runtime requirements of the bundle. For example, both a Windows and a Linux version of the invocation image may be included in the list. It is up to the CNAB runtime to determine which one to use. If no sufficient image is found, the CNAB runtime MUST emit an error and stop processing. If multiple images match the criterion set by the user, the runtime MUST execute only one, and MUST execute the first match as determined by the order of the `invocationImages` list.

A CNAB bundle MUST have at least one invocation image.

```json
{
  "invocationImages": [
    {
      "contentDigest": "sha256:aca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120685",
      "image": "example/helloworld:0.1.0",
      "imageType": "docker"
    }
  ]
}
```

The `imageType` field MUST describe the format of the image. The list of formats is open-ended, but any CNAB-compliant system MUST implement `docker` and `oci`. The default is `oci`.

The `image` field MUST give a path-like or URI-like representation of the location of the image. It is REQUIRED. The expectation is that an installer should be able to locate the image (given the image type) without additional information.

The `contentDigest` field MUST contain a digest, in [OCI format](https://github.com/opencontainers/image-spec/blob/master/descriptor.md#digests), to be used to compute the integrity of the image. The calculation of how the image matches the `contentDigest` is dependent upon image type. (OCI, for example, uses a Merkle tree while VM images are checksums).
  - If the `imageType` is `oci` or `docker`, the value for this field MUST be the registry-compressed digest (known as a repo digest, [image digest][image-digest] and/or manifest digest) as opposed to the registry-independent image ID.
  - During bundle development, it may be ideal to omit the `contentDigest` field and/or skip validation. Once a bundle is ready to be transmitted as a thick or thin bundle, it MUST have a `contentDigest` field.
  - If a `contentDigest` field is present, a runtime MUST validate the image digest prior to executing an action
  - If the `contentDigest` is not present, the runtime SHOULD report an error so the user is aware that there is no `contentDigest` provided.
  - Runtimes MAY allow users to override this behavior and perform actions on bundles that do not have `contentDigest` values populated.

The following OPTIONAL fields MAY be attached to an invocation image:

- `size`: The image size in bytes. Implementations SHOULD verify this when a bundle is packaged as a _thick_ bundle, and MAY verify it when the image is part of a thin bundle.
- `labels`: Key/value pairs that used to specify identifying attributes of invocation images
- `mediaType`: The media type of the image

## The Image Map

The `bundle.json` maps image metadata (name, origin, tag) to placeholders within the bundle. This allows images to be renamed, relabeled, or replaced during the CNAB bundle build operation.

The following illustrates an `images` section:

```json
{
  "images": {
    "backend": {
      "contentDigest": "sha256:bca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120686",
      "description": "backend component image",
      "image": "example.com/example/vote-backend@sha256:bca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120686",
      "imageType": "docker"
    },
    "frontend": {
      "contentDigest": "sha256:aca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120685",
      "description": "frontend component image",
      "image": "example.com/example/vote-frontend@sha256:aca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120685",
      "imageType": "docker"
    }
  }
}
```

Fields:

- `images`: The list of dependent images
  - `description`: The description field provides additional context of the purpose of the image.
  - `imageType`: The `imageType` field MUST describe the format of the image. The list of formats is open-ended, but any CNAB-compliant system MUST implement `docker` and `oci`. The default is `oci`.
  - `image`: The REQUIRED `image` field provides a valid reference for the image. Note that SHOULD be a CAS SHA, as in the example above, not a version tag.
  - `contentDigest`: MUST contain a digest of the contents of the image, in [OCI format](https://github.com/opencontainers/image-spec/blob/master/descriptor.md#digests), to be used to compute the integrity of the image. The calculation of how the image matches the contentDigest is dependent upon image type. (OCI, for example, uses a Merkle tree while VM images use checksums.) If the `imageType` is `oci` or `docker`, the value for this field MUST be the registry-compressed digest (known as a repo digest, [image digest][image-digest] and/or manifest digest) as opposed to the registry-independent image ID.
  - `size`: The image size in bytes
  - `labels`: Key/value pairs that used to specify identifying attributes of images:
  - `mediaType`: The media type of the image

## Definitions

The `definitions` section of the `bundle.json` defines set of JSONSchema definitions outlining how bundle configuration should be validated by a runtime.

Definitions have no utility on their own. They enable the runtime to validate parameters and outputs when used in combination with those features. Examples
of how to use `definitions` along with `parameters` and `outputs` can be seen in the [Parameters](#parameters) and [Outputs](#outputs) sections below. A `definition` must conform to both JSON Schema and Canonical JSON, therefore only `integer` numeric types are supported.

- `definitions`: A collection of JSONSchema definitions used to validate user-input.
  - `<name>`: The name of the definition.
    - `$comment`: Reserved for comments from bundle authors to readers or maintainers of the bundle. This MUST be a string (OPTIONAL)
    - `$id`: A URI for the schema resolved against the base URI of its parent schema. MUST be a uri-reference string in accordance with [RFC3986](https://tools.ietf.org/html/rfc3986) (OPTIONAL)
    - `$ref`: A URI reference used to resolve a schema located elsewhere. This MUST be a uri-reference string in accordance with [RFC3986](https://tools.ietf.org/html/rfc3986) (OPTIONAL)
    - `additionalItems`: Parameter validation requiring that any additional items included in a user-provided array must conform to the specified schema. MUST be a JSON schema. (OPTIONAL)
    - `additionalProperties`: Parameter validation requiring that any additional properties in the user-provided object conform to the specified schema. MUST be a JSON schema. (OPTIONAL)
    - `allOf`: Parameter validation requiring that the user-provided value match ALL of the specified schemas. MUST be a non-empty array of JSON schemas. (OPTIONAL)
    - `anyOf`: Parameter validation requiring that the user-provided value match ANY of the specified schemas. MUST be a non-empty array of JSON schemas. (OPTIONAL)
    - `const`: Parameter validation requiring that the user-provided value matches exactly the specified const. MAY be of any type, including null. (OPTIONAL)
    - `contains`: Parameter validation requiring at least one item included in the user-provided array conform to the specified schema. MUST be a JSON schema. (OPTIONAL)
    - `contentEncoding`: Indicates that the user-provided content should interpreted as binary data and decoded using the encoding named by this property. MUST be a string in accordance with [RFC2045, Sec 6.1](https://json-schema.org/latest/json-schema-validation.html#RFC2045). (OPTIONAL)
    - `contentMediaType`: MIME type indicating the media type of the user-provided content. MUST be a string in accordance with [RFC2046](https://json-schema.org/latest/json-schema-validation.html#RFC2046). (OPTIONAL)
    - `default`: A default JSON value associated with a particular schema. RECOMMENDED that a default value be valid against the associated schema. Numeric values MUST be integers.(OPTIONAL)
    - `definitions`: Provides a standardized location for bundle authors to inline re-usable JSON Schemas into a more general schema. MUST be an object where each named property contains a JSON schema. (OPTIONAL)
    - `dependencies`: Specifies rules that are evaluated if the parameter type is an object and contains a certain property. MUST be an object where each named dependency is either an array of unique strings or a JSON schema. (OPTIONAL)
    - `description`: Descriptive text for the field. Can be used to decorate a user interface. MUST be a string. (OPTIONAL)
    - `else`: Parameter validation requiring that the user-provided value match the specified schema. Only matches if the user-provided value does NOT match the schema provided in the `if` property. MUST be a JSON schema. (OPTIONAL)
    - `enum`: Parameter validation requiring that the user-provided value is one of the specified items in the specified array. MUST be a non-empty array of unique elements that can be of any type. (OPTIONAL)
    - `examples`: Sample JSON values associated with a particular schema. MUST be an array. (OPTIONAL)
    - `exclusiveMaximum`: Parameter validation requiring that the user-provided integer be less than the integer specified. MUST be an integer. (OPTIONAL)
    - `exclusiveMinimum`: Parameter validation requiring that the user-provided integer be greater than the integer specified. MUST be an integer. (OPTIONAL)
    - `format`: Parameter validation requiring that the user-provided value adhere to the specified format. MUST be a string. (OPTIONAL)
    - `if`: Provides a method to conditionally validate user-provided values against a schema. MUST be a JSON schema. (OPTIONAL)
    - `items`: Parameter validation requiring the items included in a user-provided array must conform to the specified schema(s). MUST be either a JSON schema or an array of JSON schemas. (OPTIONAL)
    - `maxItems`: Parameter validation requiring the length of the user-provided array be less than or equal to the number specified. MUST be a non-negative number. (OPTIONAL)
    - `maxLength`: Parameter validation requiring that the length of the user-provided string be less than or equal to the number specified. MUST be a non-negative integer. (OPTIONAL)
    - `maxProperties`: Parameter validation requiring the number of properties included in the user-provided object be less than or equal to the specified number. MUST be a non-negative integer. (OPTIONAL)
    - `maximum`: Parameter validation requiring that the user-provided number be less than or equal to the integer specified. MUST be an integer. (OPTIONAL)
    - `minItems`: Parameter validation requiring the length of the user-provided array be greater than or equal to the number specified. MUST be a non-negative integer. (OPTIONAL)
    - `minLength`: Parameter validation requiring that the length of the user-provided string be greater than or equal to the number specified. MUST be a non-negative integer. (OPTIONAL)
    - `minProperties`: Parameter validation requiring the number of properties included in the user-provided object be greater than or equal to the specified number. MUST be a non-negative integer. (OPTIONAL)
    - `minimum`: Parameter validation requiring that the user-provided number be greater than or equal to the integer specified. MUST be an integer. (OPTIONAL)
    - `multipleOf`: Parameter validation requiring that the user-provided number be wholly divisible by the integer specified. MUST be an integer strictly greater than zero. (OPTIONAL)
    - `not`: Parameter validation requiring that the user-provided value NOT match the specified schema. MUST be a JSON schema. (OPTIONAL)
    - `oneOf`: Parameter validation requiring that the user-provided value match ONE of the specified schemas. MUST be a non-empty array of JSON schemas. (OPTIONAL)
    - `patternProperties`: The set of matching properties and schemas for their values included in an object type parameter. MUST be an object where each named property is a regular expression with a JSON schema as the value. (OPTIONAL)
    - `pattern`: Parameter validation requiring that the user-provided string match the regular expression specified. MUST be a string representation of a valid ECMA 262 regular expression. (OPTIONAL)
    - `properties`: The set of named properties and schemas for their values included in an object type parameter. MUST be an object where each named property contains a JSON schema. (OPTIONAL)
    - `propertyNames`: Parameter validation requiring that each property name in an object match the specified schema. MUST be a JSON schema. (OPTIONAL)
    - `readOnly`: Parameter annotation indicating that the value of the parameter cannot be modified after the initial install. Runtimes SHOULD display a warning or similar output when the parameter's setting is being ignored for subsequent actions. MUST be a boolean. (OPTIONAL)
    - `required`: Parameter validation requiring the properties named in the user-provided object include the specified list of properties. MUST be an array of strings. (OPTIONAL)
    - `then`: Parameter validation requiring that the user-provided value match the specified schema. Only matches if the user-provided value matches the schema provided in the `if` property. MUST be a JSON schema. (OPTIONAL)
    - `title`: Short, human-readable descriptive name for the field. Can be used to decorate a user interface. MUST be a string. (OPTIONAL)
    - `type`: Parameter validation requiring that the user-provided value is either a "null", "boolean", "object", "array", "string", or "integer". MUST be a string or an array of strings with unique elements. If you need to represent another numeric type, upscale to an integer or use a string type and convert within your bundle. (OPTIONAL)
    - `uniqueItems`: Parameter validation requiring the items included in the user-provided array be unique. MUST be a boolean. (OPTIONAL)
    - `writeOnly`: Indicates that the value of the parameter is sensitive and MUST NOT be written to insecure locations such as log files or user-facing output. MUST be a boolean. (OPTIONAL)

For more information on the supported definition properties, review the the [definitions JSON schema](schema/definitions.bundle.json)

Evaluation of the validation keywords should conform to the applicable sections of [Section 6 of the JSONSchema specification](https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6).

## Parameters

The `parameters` and `definitions` sections of the `bundle.json` define which parameters a user (person installing a CNAB bundle) MAY configure on an invocation image and how those parameters should be validated by a runtime. Parameters represent information about the application configuration, and may be persisted by the runtime.

Parameter specifications consist of name/value pairs. The name is fixed, but the value MAY be overridden by the user. The parameter definition includes a specification of how to constrain the values submitted by the user.

```json
{
  "definitions": {
    "http_port": {
      "default": 80,
      "maximum": 10240,
      "minimum": 10,
      "type": "integer"
    }
  },
  "parameters": {
    "backend_port": {
      "applyTo": ["install", "action1", "action2"],
      "definition": "http_port",
      "description": "The port that the backend will listen on",
      "destination": {
        "env": "MY_ENV_VAR",
        "path": "/my/destination/path"
      },
      "required": true
    }
  }
}
```

- `parameters`: Name/value pairs describing a user-overridable parameter.
  - `<name>`: The name of the parameter. In the example above, this is `backend_port`. This
    is mapped to a value definition, which contains the following fields (REQUIRED):
    - `applyTo`: restricts this parameter to a given list of actions. If empty or missing, applies to all actions (OPTIONAL)
    - `definition`: The name of a definition schema that is used to validate user-input for this parameter. (REQUIRED)
    - `description`: Descriptive text for the field. Can be used to decorate a user interface. MUST be a string. (OPTIONAL)
    - `destination`: Indicates where (in the invocation image) the parameter is to be written (REQUIRED)
      - `env`: The name of an environment variable
      - `path`: The fully qualified path to a file that will be created. Specified path MUST NOT be a subpath of `/cnab/app/outputs`.
    - `required`: indicates whether this parameter MUST be supplied. By default it is `false`, which means the parameter is optional. When `true`, a runtime MUST fail if the parameter is not provided for any action to which the parameter applies.

Parameter names (the keys in `parameters`) ought to conform to the [Open Group Base Specification Issue 6, Section 8.1, paragraph 4](http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap08.html) definition of environment variable names with one exception: parameter names MAY begin with a digit (approximately `[A-Z0-9_]+`).

> The term _parameters_ indicates the present specification of what can be provided to a bundle. The term _values_ is frequently used to indicate the user-supplied values which are tested against the parameter definitions.

### Format of Parameter/Definition Specification

The structure of a `parameters` and `definitions` section looks like the section below.

```
{
  "definitions: {
    "<definition-name>": {
      "$comment": <string>,
      "$id": <uri-reference>,
      "$ref": <uri-reference>,
      "additionalItems": <json-schema>,
      "additionalProperties": <json-schema>,
      "allOf": [ <json-schema> ],
      "anyOf": [ <json-schema> ],
      "const": <any-value>,
      "contains": <json-schema>,
      "contentEncoding": <string>,
      "contentMediaType": <string>,
      "default": <any-value>,
      "definitions": {
        "<definition-name>": <json-schema>
      },
      "io.cnab.dependencies": {
        "<first-property-name>": <json-schema>,
        "<second-property-name>": [ <string> ]
      },
      "description": <string>,
      "else": <json-schema>,
      "enum": [ <any-value> ],
      "examples": [ <any-value> ],
      "exclusiveMaximum": <number>,
      "exclusiveMinimum": <number>,
      "format": <string>,
      "if": <json-schema>,
      "items": <json-schema> | [ <json-schema> ],
      "maxItems": <integer>,
      "maxLength": <integer>,
      "maxProperties": <integer>,
      "maximum": <number>,
      "minItems": <integer>,
      "minLength": <integer>,
      "minProperties": <integer>,
      "minimum": <integer>,
      "multipleOf": <number>,
      "not": <json-schema>,
      "oneOf": [ <json-schema> ],
      "pattern": <string>,
      "patternProperties": {
        "<regular-expression-for-property-name>": <json-schema>
      },
      "properties": {
        "<property-name>": <json-schema>
      },
      "propertyNames": <json-schema>,
      "readOnly": <boolean>,
      "required": [ <string> ],
      "then": <json-schema>,
      "title": <string>,
      "type": <string> | [ <string> ],
      "uniqueItems": <boolean>,
      "writeOnly": <boolean>
    }
  },
  "parameters": {
    "<parameter-name>": {
      "applyTo": [ <string> ],
      "definition": <definition-name>,
      "description": <string>,
      "destination": {
        "env": <string>,
        "path": <string>
      },
      "required" : <boolean>
    }
  }
}
```

See [The Bundle Runtime](103-bundle-runtime.md) for details of how parameters are injected into the invocation image.

### Examples

Below are a few more complicated examples that outline some of the possible parameter configurations that a bundle author can expose.

Check out the [JSON Schema specification](https://json-schema.org/) for more examples and further documentation.

```json
{
  "definitions": {
    "address": {
      "properties": {
        "country_name": {
          "type": "string"
        },
        "extended_street_address": {
          "type": "string"
        },
        "locality": {
          "type": "string"
        },
        "postal_code": {
          "type": "string"
        },
        "region": {
          "type": "string"
        },
        "street_address": {
          "type": "string"
        }
      },
      "required": [
        "country_name",
        "locality",
        "postal_code",
        "region",
        "street_address"
      ],
      "type": "object"
    },
    "email-address": {
      "format": "idn-email",
      "type": "string"
    },
    "greetings": {
      "default": ["Hello"],
      "description": "a list of greetings",
      "items": {
        "examples": ["Aloha", "Bonjour", "こんにちは"],
        "type": "string"
      },
      "title": "Greetings for new users",
      "type": "array"
    },
    "jpeg": {
      "contentEncoding": "base64",
      "contentMediaType": "image/jpeg",
      "type": "string"
    }
  },
  "parameters": {
    "email": {
      "definition": "email-address",
      "destination": {
        "env": "EMAIL"
      }
    },
    "greetings": {
      "definition": "greetings",
      "destination": {
        "env": "GREETINGS"
      }
    },
    "profile_picture": {
      "definition": "jpeg",
      "destination": {
        "path": "/tmp/user.jpg"
      }
    },
    "workplace_address": {
      "definition": "address",
      "description": "the address of your workplace",
      "destination": {
        "path": "/tmp/address.adr"
      },
      "required": true
    }
  }
}
```

### Resolving Destinations

When resolving destinations, there are two ways a particular parameter value MAY be placed into the invocation image. Here is an example illustrating both:

```json
{
  "definitions": {
    "configuration": {
      "default": "",
      "type": "string"
    },
    "greeting": {
      "default": "hello",
      "type": "string"
    }
  },
  "parameters": {
    "config": {
      "definition": "configuration",
      "description": "this will be located in a file",
      "destination": {
        "path": "/opt/example-parameters/config.txt"
      }
    },
    "greeting": {
      "definition": "greeting",
      "description": "this will be in $GREETING",
      "destination": {
        "env": "GREETING"
      }
    }
  }
}
```

For the (REQUIRED) `destination` field, at least one of `env` or `path` MUST be specified. (Both MAY be provided).

If `env` is set, the value of the parameter will be assigned to the given environment variable name. In the example in the previous section, `GREETING` is set to `hello`.

If `path` is set, the value of the parameter will be written into a file at the specified location on the invocation image's filesystem. This file name MUST NOT be present already on the invocation image's filesystem.

If both `env` and `path` are specified, implementations MUST put a copy of the data in each destination.

## Credentials

A `bundle.json` MAY contain a section that describes which credentials the bundle expects to have access to in the invocation image. This information is provided so that users can be informed about the credentials that are required by the invocation image in order for the invocation image to perform its tasks.

Credentials differ from parameters in intention: A _parameter_ represents application configuration. A _credential_ represents the _identity of the agent performing the action_. For example, the lifecycle of one bundle installation may be managed by several individuals. When interacting with that bundle, individuals may use their own credentials. However, the bundle's _parameters_ are assumed to be attached to the bundle itself, regardless of which individual is presently acting on that bundle.

What about parameters such as database passwords used by the application? Properly speaking, these are _parameters_ if the application uses them.

> Note that the CNAB specification does not mandate specific security implementations on storage of either parameters or credentials. CNAB Runtimes ought to consider that both parameters and credentials may contain secret data, and OUGHT to secure both parameter and credential data in ways appropriate to the underlying platform. It is recommended that credentials are not persisted between actions, and that parameters _are_ persisted between actions.

```json
{
  "credentials": {
    "hostkey": {
      "env": "HOST_KEY",
      "path": "/etc/hostkey.txt"
    },
    "image_token": {
      "env": "AZ_IMAGE_TOKEN",
      "required": true,
      "applyTo": ["install"]
    },
    "kubeconfig": {
      "path": "/home/.kube/config"
    }
  }
}
```

- The `credentials` container is a map of human-friendly credential names to a description of where the invocation image expects to find them.
  - The name key MUST be human-readable
    - `applyTo`: restricts this credential to a given list of actions. If empty or missing, applies to all actions (OPTIONAL).
    - `path` describes the _absolute path within the invocation image_ where the invocation image expects to find the credential. Specified path MUST NOT be a subpath of `/cnab/app/outputs`.
    - `env` contains _the name of an environment variable_ that the invocation image expects to have available when executing the CNAB `run` tool (covered in the next section).
    - `description` contains a user-friendly description of the credential.
    - `required` indicates whether this credential MUST be supplied. By default it is `false`, which means the credential is optional. When `true`, a runtime MUST fail if the credential is not provided.

One of `env` or `path` MUST be specified. (Both MAY be provided).

If `env` is set, the value of the credential MUST be assigned to the given environment variable name. In the example in the previous section, `HOST_KEY` is set to `HOST_KEY`.

If `path` is set, the value of the credential MUST be written into a file at the specified location on the invocation image's filesystem. This file name MUST NOT be present already on the invocation image's filesystem.

### Resolving Destination Conflicts in Environment Variables and Paths

Parameters and credentials may specify environment variables or paths as destinations.

- Implementations SHOULD produce an error if a parameter and a credential use the same destination environment variable
- Implementations SHOULD produce an error if a parameter and a credential use the same destination path
- Implementations MUST NOT override a credential value with a parameter value
- Implementations SHOULD NOT allow any parameter or credential to declare an environment variable with the prefix `CNAB_`
- Implementations MUST NOT allow a parameter or credential to override any environment variable with the `CNAB_` prefix
  - The `CNAB_` variables are defined in the [Bundle Runtime Description](./103-bundle-runtime.md) of this specification

## Custom Actions

Every implementation of a CNAB tool MUST support three built-in actions:

- `install`
- `upgrade`
- `uninstall`

Implementations MAY support user-defined additional actions as well. Such actions are exposed via the `bundle` definition file. An action definition contains an action _name_ followed by a description of that action:

```json
{
  "actions": {
    "io.cnab.dry-run": {
      "title": "Dry Run",
      "description": "prints what install would do with the given parameters values",
      "modifies": false,
      "stateless": true
    },
    "io.cnab.migrate": {
      "title": "Migrate",
      "modifies": false
    },
    "io.cnab.status": {
      "title": "Status",
      "description": "retrieves the status of an installation",
      "modifies": false
    }
  }
}
```

The action _name_ SHOULD use _dotted name_ syntax as defined earlier in this section.

The above declares three actions: `io.cnab.status`, `io.cnab.migrate` and `io.cnab.dry-run`. This means that the associated invocation images can handle requests for `io.cnab.status`, `io.cnab.migrate` and `io.cnab.dry-run` in addition to `install`, `upgrade`, and `uninstall`.

Each action is accompanied by a description, which contains the following fields:

- `title`: The human-readable name of the operation. If omitted, tools MAY use the value of the `actions` key (e.g. `io.cnab.dry-run`). User agents that display the title SHOULD disambiguate if two or more actions have the same `title` value (OPTIONAL).
- `modifies`: Indicates whether the given action will _modify resources_ in any way. If not provided, it will be assumed `false`.
- `description`: A human readable description of the action (OPTIONAL)
- `stateless`: The action does not act on a claim, and does not require credentials. This is useful for exposing dry-run actions, printing documentation, etc. (OPTIONAL)

The `modifies` field MUST be set to `true` if any resource that is managed by the bundle is changed in any way. The `modifies` field assists CNAB implementations in tracking history of changes over time. An implementation of CNAB MAY use this information when describing history or managing releases.

The `stateless` field indicates that the runtime will bypass credentials requirements (the user MAY or MAY NOT pass any credentials), and will not keep track of this action. If credentials are supplied, the runtime SHOULD pass the credentials to the invocation image (as in stateful actions). An invocation image MAY exit with an error if the necessary credentials are not supplied. However, the runtime MUST NOT fail to invoke the invocation image because of missing credentials.

The primary intention of a `stateless` action is to allow invocation bundles to provide dry-run or detailed help functionalities. Stateless actions can be invoked on a non-existing installation. In this case, the `name` passed to the runtime need not exist, and MUST not result in the creation of a name record. Runtimes MAY ignore `name` if supplied.

An invocation image _ought_ to handle all custom targets declared in the `actions` section. An invocation image SHOULD NOT handle actions that are not included by the default list (`install`, `upgrade`, `uninstall`) and the custom actions section.

The built-in actions (`install`, `upgrade`, `uninstall`) MUST NOT appear in the `actions` section, and an implementation MUST NOT allow custom actions named `install`, `upgrade`, or `uninstall`.

Implementations that do not support custom actions MUST NOT emit errors (either runtime or validation) if a bundle defines custom actions. That is, even if an implementation cannot execute custom actions, it MUST NOT fail to operate on bundles that declare custom actions.

## Custom Extensions

In many cases, the bundle descriptor is a sufficient artifact for delivering a CNAB bundle, since invocation images and other images may be retrieved from registries and repositories. However, it is important to provide an extension mechanism. A _custom extension_ is a named collection of auxiliary data whose meaning is defined outside of this specification.

Tools MAY define and declare additional fields inside of the `custom` section. Tools MUST NOT define additional fields anywhere else in the bundle descriptor. Implementations MAY produce an error or MAY ignore additional fields outside of the extension, but MUST be consistent in either ignoring or producing an error. However, implementations SHOULD preserve the data inside of the `custom` section even when that information is not understood by the implementation.

The `custom` object is used as follows:

```json
{
  "custom": {
    "com.example.backup-preferences": {
      "frequency": "daily"
    },
    "com.example.duffle-bag": {
      "icon": "https://example.com/icon.png",
      "iconType": "PNG"
    }
  }
}
```

The format is:

```json
{
  "custom": {
    "EXTENSION NAME": "ARBITRARY JSON DATA"
  }
}
```

The fields are defined as follows:

- `custom` defines the wrapper object for extensions
  - `EXTENSION NAME`: a unique name for an extension. Names SHOULD follow the dotted name format described earlier in this section.
  - The value of the extension must be valid JSON, but is otherwise undefined.

### Required Extensions

Some extensions defined in the `custom` object of a bundle MAY be required in order for a runtime to perform any action on the bundle. A bundle author MUST use the `requiredExtensions` array to define those extensions that are required. The `requiredExtensions` array SHOULD contain the `EXTENSION NAME` defined in the `custom` object for each extension that is required.

A runtime MUST check that it supports any required extensions before performing any action on the bundle. If the runtime does not support the required extension(s), it MAY proceed with the action or fail, however it MUST notify the user that it does not support the required extension(s). Runtimes that do not support extensions that are NOT identified in the `requiredExtensions` field of a bundle SHOULD perform actions on the bundle.

```json
{
   "credentials":{
      "hostkey":{
         "env":"HOST_KEY",
         "path":"/etc/hostkey.txt"
      }
   },
   "custom":{
      "com.example.backup-preferences":{
         "frequency":"daily"
      },
      "com.example.duffle-bag":{
         "icon":"https://example.com/icon.png",
         "iconType":"PNG"
      },
      "io.cnab.dependencies":[
         {
            "sequence":["mysql"],
            "requires":{
               "bundle":"azure/mysql",
               "version":{
                  "prereleases":"true",
                  "range":"5.7.x"
               }
            }
         }
      ]
   },
   "definitions":{
      "http_port":{
         "default":80,
         "maximum":10240,
         "minimum":10,
         "type":"integer"
      },
      "port":{
         "maximum":65535,
         "minimum":1024,
         "type":"integer"
      },
      "string":{
         "type":"string"
      },
      "x509Certificate":{
         "contentEncoding":"base64",
         "contentMediaType":"application/x-x509-user-cert",
         "type":"string",
         "writeOnly":true
      }
   },
   "description":"An example 'thin' helloworld Cloud-Native Application Bundle",
   "images":{
      "my-microservice":{
         "contentDigest":"sha256:aaaaaaaaaaaa...",
         "description":"my microservice",
         "image":"example/microservice:1.2.3"
      }
   },
   "invocationImages":[
      {
         "contentDigest":"sha256:aaaaaaa...",
         "image":"example/helloworld:0.1.0",
         "imageType":"docker"
      }
   ],
   "maintainers":[
      {
         "email":"matt.butcher@microsoft.com",
         "name":"Matt Butcher",
         "url":"https://example.com"
      }
   ],
   "name":"helloworld",
   "outputs":{
      "clientCert":{
         "definition":"x509Certificate",
         "path":"/cnab/app/outputs/clientCert",
         "labels": {
            "format": "PEM"
         }
      },
      "hostName":{
         "applyTo":[
            "install"
         ],
         "definition":"string",
         "description":"the hostname produced installing the bundle",
         "path":"/cnab/app/outputs/hostname"
      },
      "port":{
         "definition":"port",
         "path":"/cnab/app/outputs/port"
      }
   },
   "parameters":{
      "backend_port":{
         "definition":"http_port",
         "description":"The port that the back-end will listen on",
         "destination":{
            "env":"BACKEND_PORT"
         }
      }
   },
   "requiredExtensions":[
      "io.cnab.dependencies"
   ],
   "schemaVersion":"v1.1.0",
   "version":"0.1.2"
}
```

Source: [101.03-bundle.json](examples/101.03-bundle.json)

## Outputs

The `outputs` section of the `bundle.json` defines which outputs an application will produce during the course of executing a bundle. Outputs are expected to be written to one or more files on the file system of the invocation image. The location of this file MUST be provided in the output definition.

Output specifications are flat (not tree-like), consisting of name/value pairs. The output definition includes a destination the output will be written to, along with a definition to help validate their contents.

```json
{
   "definitions":{
      "port":{
         "maximum":65535,
         "minimum":1024,
         "type":"integer"
      },
      "string":{
         "type":"string"
      },
      "x509Certificate":{
         "contentEncoding":"base64",
         "contentMediaType":"application/x-x509-user-cert",
         "type":"string",
         "writeOnly":true
      }
   },
   "outputs":{
      "clientCert":{
         "applyTo":[
            "install",
            "action2"
         ],
         "definition":"x509Certificate",
         "path":"/cnab/app/outputs/clientCert"
      },
      "hostName":{
         "definition":"string",
         "path":"/cnab/app/outputs/hostname"
      },
      "port":{
         "definition":"port",
         "path":"/cnab/app/outputs/port"
      }
   }
}

```

- `outputs`: name/value pairs describing an application output.
  - `<name>`: The name of the output. In the example above, this is `clientCert`, `hostName`, and `port`. This is mapped to a value definition, which contains the following fields (REQUIRED):
    - `applyTo`: restricts this output to a given list of actions. If empty or missing, applies to all actions (OPTIONAL)
    - `definition`: The name of a definition schema that is used to validate the output content. (REQUIRED)
    - `description`: Descriptive text for the field. Can be used to decorate a user interface. MUST be a string. (OPTIONAL)
    - `labels`: Key/value pairs of type string that specify identifying attributes of the output (OPTIONAL). MUST follow the [CNAB Label Format].
    - `path`: The fully qualified path to a file that will be created (REQUIRED). The path specified MUST be a _strict_ subpath of `/cnab/app/outputs` and MUST be distinct from the paths for all other outputs in this bundle.

An invocation image should write outputs to a file specified by the `path` attribute for each output. A bundle runtime can then extract values from the specified path and present them to a user.
All outputs that apply to a specified action are considered to be required. If an output is missing at the end of an action, and a default is defined, the runtime SHOULD write the default to the file specified by the `path` attribute. Otherwise the runtime SHOULD report the missing output as an error to the user.
A runtime can leverage appropriate [in-memory](https://docs.docker.com/v17.09/engine/admin/volumes/tmpfs/#choosing-the-tmpfs-or-mount-flag) volume mounted at the `path` location for storing these outputs.

A runtime may validate outputs based on schema references by the definition field.

Next section: [The invocation image definition](102-invocation-image.md)

[image-digest]: https://docs.docker.com/engine/reference/commandline/images/#list-image-digests
[CNAB Label Format]: /105-labels.md

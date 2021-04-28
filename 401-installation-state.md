---
title: Installation State
weight: 401
---

# CNAB Installation State 1.0.0
*Draft, Mar. 2021*

This specification describes CNAB Installation State. This is not part of the [CNAB Core](100-CNAB.md) specification, but is a specification describing how state related to an installation of a bundle is formatted and stored. Implementations of CNAB Core can meet the CNAB Core specification without implementing this specification. Implementations that support installation state MAY declare that they comply with CNAB Installation State 1.0.0.

The Installation State specification is based on the CNAB Claims specification, extending it to cover additional data that MAY be used by a CNAB runtime. After we have implemented and vetted this specification, one possible outcome would be to replace the Claims specification with this one.

A _host environment_ is an environment, possibly shared between multiple CNAB tools, that provides persistence for CNAB documents. For example, a filesystem may contain a record of claims that two different CNAB clients share. Or a database may contain the environment that is shared by multiple tools at different locations in the network. Each of these is a CNAB host environment.

This specification uses the terminology defined in [the CNAB Core specification](100-CNAB.md).

* [State Management](#state-management)
* [Documents](#documents)
* [Terminology](#terminology)
* [Claim Injection](#claim-injection)
* [Determine Execution Status](#determine-execution-status)
* [Sensitive Data Storage](#sensitive-data-storage)

## State Management

Fundamentally, package managers provide a state management layer to keep records of what was installed. For example, [homebrew](http://homebrew.sh), a popular macOS package manager, stores records for all installed software in `/usr/local/Cellar`. Helm, the package manager for Kubernetes, stores state records in Kubernetes ConfigMaps located in the system namespace. The Debian Apt system stores state in `/var/run`. In all of these cases, the stored state allows the package managing system to be able to answer (quickly) the question of whether a given package is installed.

Example from Homebrew:

```console
$ brew info cscope
cscope: stable 15.8b (bottled)
Tool for browsing source code
https://cscope.sourceforge.io/
/usr/local/Cellar/cscope/15.8b (10 files, 714.2KB) *
  Poured from bottle on 2017-05-15 at 09:24:58
From: https://github.com/Homebrew/homebrew-core/blob/master/Formula/cscope.rb
```

The CNAB Installation State specification does not define where or how records are stored. However, this specification describes how a CNAB-based system MUST emit a claim to an invocation image, and provides some guidance on maintaining integrity of the system. This is done so that implementors can standardize on a way of relating a claim to operations like `install`, `upgrade`, or `uninstall`. This, in turn, is necessary if CNAB bundles are expected to be executable by different implementations.

Installation data is used to inform any CNAB tooling about how to address a particular installation. For example, given the documents for an installation, a runtime that implements the CNAB Installation State specification SHOULD be able to:

- List the _names_ of installations defined within a given _namespace_
- List the _names_ of the installations, given a _bundle name_
- Given an installation's _name_, return the _bundle info_ that is installed under that name
- Given an installation _name_ and a _bundle_, generate a _bundle info_.
  - This is accompanied by running the `install` path in the bundle
- Given an installation's _name_, replace the _bundle info_ with updated _bundle info_, and update the revision with a new ULID, and the modified timestamp with the current time. This is an upgrade operation.
  - This is accompanied by running the `upgrade` path in the bundle
- Given an installation's name, mark the installation as uninstalled.
  - This is accompanied by running the `uninstall` path in the bundle
- Given an installation's name, return the name(s) of the generated outputs.

To satisfy these requirements, implementations of a CNAB runtime are expected to be able to store and retrieve state information. However, note that nothing in the CNAB Installation State specification says _how or where_ this state information is to be stored. It is _not a requirement_ to store that state information inside of the invocation image. (In fact, this is discouraged.)


## Documents

This specification defines the format of the documents associated with a CNAB installation, and describes certain necessary behaviors of any implementation.

* [Installation](#installation)
* [Claim](#claim)
* [Claim Result](#claim-result)
* [Output](#output)

### Installation

In CNAB, an _installation_ is a particular installed instance of a CNAB bundle. For example, if a bundle named `myApp` is installed in two places, we say there are _two installations of `myApp`_.

The CNAB installation is defined as a JSON document. The specification does not require that installations are formatted as Canonical JSON.

```json
{
  "bundleRepository": "hub.example.com/technosophos/hellohelm",
  "bundleVersion": "0.1.2",
  "created": "2018-08-30T20:39:55.549002887-06:00",
  "custom": {},
  "labels": {
    "env": "dev",
    "owner": "javier",
    "cnab.io/app": "hello-world",
    "cnab.io/appVersion": "v1.0.0"
  },
  "name": "hello-world",
  "namespace": "demo"  ,
  "schemaVersion": "1.0.0-DRAFT+abc123"
}
```
Source: [401.01-installation.json](examples/401.01-installation.json)

The fields above are defined as follows:

- `bundleRepository` (REQUIRED): The repository of the associated bundle.
- `bundleVersion` (REQUIRED): The version of the associated bundle.
- `created` (REQUIRED): A [timestamp](#timestamps) indicating when this _installation_ was created.
- `custom` (OPTIONAL): A section for custom extension data applicable to a given runtime.
- `labels` (OPTIONAL): [Labels](#labels) are a set of key/value pairs of type string that MAY be used for querying. Labels defined on the bundle SHOULD be copied to the labels field on the installation. MUST follow the [CNAB Label Format]. 
- `name` (REQUIRED): The name of the _installation_. Elsewhere, this field is referenced as the _installation name_. The format of this field MUST follow the same format used for the `installation` field in the [bundle.json file specification](101-bundle-json.md#the-bundlejson-file).
- `namespace` (OPTIONAL): The [namespace](#namespaces) of the installation. MUST follow the [CNAB Namespace Format].
- `schemaVersion` (REQUIRED): The [schema version][schema-version] of the Installation State Specification with which this document conforms.

### Claim

A _claim_ is a record of the inputs to an action against a CNAB _installation_.

The word _claim_ was chosen because it represents the relationship between a certain CNAB host environment and the resources that were created by a CNAB runtime in that host environment. In this sense, an environment takes responsibility for those resources if and only if it can _claim_ them. A claim is an _external assertion of ownership_. That is, the claim itself is not "installed" into the host environment. It is stored separately, possibly in an entirely different location.

An installation MAY change over time, as a particular bundle is installed, then upgraded. In CNAB, each time a modifying operation is performed (such as `install`, `upgrade`, or custom operations that are not read-only), the installation gets a new _revision_. A revision is a unique identifier that identifies the combination of an _installation_ and a modification of that installation. Revision is stored on the claim. For example, when a CNAB bundle is installed, the installation will have an initial revision ID. When that installation is upgraded, it will have a new revision ID. How revisions are used is outside of the scope of this document, but it is safe to assume that if a revision ID has changed, one or more artifacts owned by the installation has also been changed.

The claims system is designed to satisfy the requirements of the [Bundle Runtime specification](103-bundle-runtime.md) regarding the tracking of `CNAB_REVISION`. It also provides a description of how the state of a bundle installation may be represented.

The CNAB claim is defined as a JSON document. The specification does not require that claims are formatted as Canonical JSON. Claims are immutable and are not modified after creation. Before a modifying action is executed against an installation, a new claim is created to represent the operation. The claim for the last modifying action MUST be retained. Previous claims, and/or claims for non-modifying actions, MAY be retained to provide a history of actions performed on an installation.

```json
{
  "action": "install",
  "bundle": {
    "credentials": {},
    "images": {},
    "invocationImages": [
      {
        "image": "example/helloworld:0.1.0",
        "imageType": "docker"
      }
    ],
    "name": "helloworld",
    "outputs": {
      "clientCert": {
        "definition": "x509Certificate",
        "path": "/cnab/app/outputs/clientCert"
      },
      "hostName": {
        "applyTo": [
          "install"
        ],
        "definition": "string",
        "description": "the hostname produced installing the bundle",
        "path": "/cnab/app/outputs/hostname"
      },
      "port": {
        "definition": "port",
        "path": "/cnab/app/outputs/port"
      }
    },
    "parameters": {},
    "schemaVersion": "v1.0.0",
    "version": "0.1.2"
  },
  "bundleReference": "hub.example.com/technosophos/hellohelm@sha256:eec03d9da1bad36b3e3a4526cc774153f7024a94f25df8d2dc3ca5602fc5273d",
  "created": "2018-08-30T20:39:55.549002887-06:00",
  "custom": {
    "io.cnab.credentialSets": [
      {
        "name": "myCluster",
        "namespace": "demo"
      }
    ]
  },
  "id": "01E5G8ZYP714JVM8NHTJQ4FH15",
  "installation": "technosophos.helloworld",
  "labels": {
    "cnab.io/executor": "porter",
    "cnab.io/executorVersion": "v0.35.0"
  },
  "namespace": "demo",
  "parameters": {},
  "revision": "01CP6XM0KVB9V1BQDZ9NK8VP29",
  "schemaVersion": "1.0.0-DRAFT+abc123"
}
```
Source: [401.01-claim.json](examples/401.01-claim.json)

The fields above are defined as follows:

- `action` (REQUIRED): The name of the action executed against the installation. This may be any of the built-in actions (`install`, `upgrade`, `uninstall`) as well as any custom actions as defined in the bundle descriptor. The special name `unknown` MAY be used in the case where the CNAB Runtime cannot determine the action name of a claim.
- `bundle` (REQUIRED): The bundle, as defined in [the Bundle Definition](101-bundle-json.md).
- `created` (REQUIRED): A [timestamp](#timestamps) indicating when this _claim_ was created.
- `bundleReference` (OPTIONAL): A canonical reference to the bundle used in the action. This bundle reference SHOULD be digested to identify a specific version of the referenced bundle.
- `custom` (OPTIONAL): A section for custom extension data applicable to a given runtime.
- `id` (REQUIRED): The claim id. A [ULID](#ulids) that MUST change with each new claim, so that every claim associated with an installation has a unique id. This is used to associate the the claim with its result(s). 
- `installation` (REQUIRED): The name of the _installation_.
- `labels` (OPTIONAL): [Labels](#labels) are a set of key/value pairs of type string that MAY be used for querying. MUST follow the [CNAB Label Format].
- `namespace` (OPTIONAL): The [namespace](#namespaces) of the claim. Claims MUST be defined in the same namespace as the installation. MUST follow the [CNAB Namespace Format].
- `parameters` (OPTIONAL): Key/value pairs that were passed in during the operation. These are stored so that the operation can be re-run. See the [Parameters](#parameters) section below for more details.
- `revision` (REQUIRED): The _installation_ revision. A [ULID](#ulids) that MUST change each time the installation is modified. It MUST NOT change when a [non-modifying operation](https://github.com/cnabio/cnab-spec/blob/main/101-bundle-json.md#custom-actions) is performed on the installation.
- `schemaVersion` (REQUIRED): The [schema version][schema-version] of the Installation State Specification with which this document conforms.

#### Credentials

Note that credential data is _never_ stored in a claim. For this reason, a claim is not considered _trivially repeatable_. Credentials MUST be supplied on each action. Implementations of the Installation State specification are expected to retrieve the credential requirements from the `bundle` field.

#### Parameters

If parameters are passed in during the operation, they MUST be stored on the claim. The parameter data stored in a claim is _the resolved key/value pairs_ that result from the following transformation:

- The values supplied by the user are validated by the rules specified in the `bundle.json` file
- The output of this operation is a set of key/value pairs in which:
  - Valid user-supplied values are presented
  - Default values are supplied for all parameters where `default` is provided and no user-supplied value overrides this

### Claim Result

A _claim result_ is a record of the result of an action against a CNAB _installation_, such as the status of the operation and any outputs generated.

The CNAB claim result is stored as a JSON document. Claim results are immutable and are not modified after creation. A claim can have multiple results. Only the final status, such as `succeeded` or `failed` MUST be recorded for a claim, though an implementation MAY choose to persist results for intermediate status transitions. For example, a claim may have a result for `starting` and another for `succeeded`, or have multiple results when the operation was cancelled and then retried.

The last result associated with a retained claim MUST also be retained. Previous results MAY also be retained to provide a more detailed history of the operation's progress. 
The claim result provides metadata about the outputs generated by the operation. A tool MAY choose to request the contents of any outputs to persist them but is not required to do so.

```json
{
  "claimId": "01E5G8ZYP714JVM8NHTJQ4FH15",
  "custom": {},
  "id": "01E2ZZ2FKSE0V41DCXFCSW5D1M",
  "created": "2018-08-30T20:39:55.549002887-06:00",
  "labels": {
    "cnab.io/retry": "true"
  },
  "message": "",
  "namespace": "demo",
  "outputs": {
    "clientCert": {
      "contentDigest":"sha256:aaa...",
      "labels": {
      	"format": "PEM"
      }
    },
    "hostName": {
      "contentDigest":"sha256:bbb..."
    },
    "port": {
      "contentDigest":"sha256:ccc..."
    }
  },
  "schemaVersion": "1.0.0-DRAFT+abc123",
  "status": "succeeded"
}
```
Source: [401.01-claim-result.json](examples/401.01-claim-result.json)

The fields above are defined as follows:

- `claimId` (REQUIRED): ID of the claim that generated this result.
- `custom` (OPTIONAL): A section for custom extension data applicable to a given runtime.
- `id` (REQUIRED): A [ULID](#ulids) identifier for the result.
- `created` (REQUIRED): A [timestamp](#timestamps) indicating when this result was created.
- `labels` (OPTIONAL): [Labels](#labels) are a set of key/value pairs of type string that MAY be used for querying. MUST follow the [CNAB Label Format].
- `message` (OPTIONAL): A human-readable string that communicates the outcome. Error messages MAY be included in `failed` conditions.
- `namespace` (OPTIONAL): The [namespace](#namespaces) of the result. Claim results MUST be in the same namespace as the installation. MUST follow the [CNAB Namespace Format].
- `outputs` (OPTIONAL): Outputs generated by the operation. It is a map from the output names to metadata about the output. The output value is not stored in the claim result. If this field is not present, it MAY be assumed that no outputs were generated as a result of the operation.
  - `contentDigest` (OPTIONAL): Contains a digest, in [OCI format](https://github.com/opencontainers/image-spec/blob/master/descriptor.md#digests), which can be used to compute the integrity of the output.
  - `generatedByBundle` (OPTIONAL): Indicates if the output was defined in the bundle and populated by the invocation image's execution. Outputs on the result can also be dynamically generated by the CNAB runtime.
  - `labels` (OPTIONAL): [Labels](#labels) are a set of key/value pairs of type string that MAY be used for querying. Labels defined on an output in a bundle SHOULD be copied to the output's labels field on the claim result that generated the output. MUST follow the [CNAB Label Format].
- `schemaVersion` (REQUIRED): The [schema version][schema-version] of the Installation State Specification with which this document conforms.
- `status` (REQUIRED): Indicates the status of the last phase transition. Valid statuses are:
  - `cancelled`: The operation was cancelled, potentially during the operation's execution. This is an error condition.
  - `failed`: Failed before completion.
  - `pending`: Execution has been requested and has not begun. This SHOULD be considered a temporary status, and the runtime SHOULD work to resolve this to either `failed` or `succeeded`.
  - `running`: Execution is in progress and has not completed. This SHOULD be considered a temporary status, and the runtime SHOULD work to resolve this to either `failed` or `succeeded`.
  - `unknown`: The state is unknown. This is an error condition.
  - `succeeded`: Completed successfully.


### Output

An _output_ is data generated by the execution of a bundle. Outputs can be defined ahead of time by the bundle, such as the ip address of a provisioned virtual machine. Outputs can also be generated by the CNAB runtime dynamically, such as the logs output by the invocation image.

Outputs are not structured documents and contain only the data output from the bundle. Outputs can store additional metadata in the `outputs` field of the associated claim result.

* Outputs are always defined in the same namespace as the associated installation. The output namespace is not explicitly stored.
* Labels for an output are defined on the claim result's output declaration.

The output name, as defined in the bundle, is used to request the content of the file located at the path defined for that output.

Below, you can see an example of a claim result that includes an entry for the output `clientCert`.

```json
{
  "claimId": "01E5G8ZYP714JVM8NHTJQ4FH15",
  "id": "01E2ZZ2FKSE0V41DCXFCSW5D1M",
  "created": "2018-08-30T20:39:55.549002887-06:00",
  "message": "",
  "namespace": "demo",
  "outputs": {
    "clientCert": {
      "contentDigest":"sha256:aaa...",
      "generatedByBundle": true,
      "labels": {
        "format": "PEM"
      }
    },
    "hostName": {
      "contentDigest":"sha256:bbb...",
      "generatedByBundle": true
    },
    "port": {
      "contentDigest":"sha256:ccc...",
      "generatedByBundle": true
    },
    "io.cnab.outputs.invocationImageLogs": {
      "contentDigest":"sha256:ddd",
      "generatedByBundle": false
    }
  },
  "status": "succeeded",
}
```

The tool MAY request the contents of the output, retrieved from `/cnab/app/outputs/clientCert`, and persist it for later use.

```
-----BEGIN CERTIFICATE-----
MIIDBzCCAe+gAwIBAgIJAL2nOwEePOPvMA0GCSqGSIb3DQEBBQUAMBoxGDAWBgNV
BAMMD3d3dy5leGFtcGxlLmNvbTAeFw0xOTA3MTUxNjQwMzdaFw0yOTA3MTIxNjQw
MzdaMBoxGDAWBgNVBAMMD3d3dy5leGFtcGxlLmNvbTCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAJ7779ImmmvEt+ywP8GjfpzgM57n1WZ26fBTVy+ZibiH
hKCJuzU5vynu5M0eYCufRFQ7LG/xet1GvpBIch0U6ilZVnNDrsNUtQ03Hpen144g
li5ldPh5Sm88ibDbi4yEIgti2JBKIuVE+iEdkIejF8DZps008TbLLoENM1VpHpUT
CIJY657t+Xhz9GOhp1w3bVoKEoF/6psvc6IFHK8bUMq+4003VGDZe2BMlgazZPHc
3o5CqNviajnRoo9QnLUH1qOljNMR+mkewNOkL2PRGvkCuHJrEk0qmUU7lX3iVN1J
C7y1fax53ePXajLD+5/sQNeszVg1cIIUlXBy2Bx/F7UCAwEAAaNQME4wHQYDVR0O
BBYEFAZ1+cZNMujQhCrtCRKfPm+NLDg0MB8GA1UdIwQYMBaAFAZ1+cZNMujQhCrt
CRKfPm+NLDg0MAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADggEBAAuyyYER
T5+E+KuFbDL/COmxRWZhF/u7wIW9cC2o5LlKCUp5rRQfAVRNJlqasldM/G4Bg/uQ
5khSYe2XNe2C3iajVkR2RlqXBvCdQuCtudhZVd4jSGWi/yI7Ub2/HyOTjZ5eG82o
F6e3pNRCQwTw0y0orQmdh0s+UmHEVjIe8PfbdRymfeQO70EXTxncBJ5elZx8s0E9
TPPdbl2knZmKJhwnZFKCaa4DmDA6CDa2GPz+2++DQl1rCIB3mIcxpg6wSdMA6C6l
nBJBX5Wnxckldp8G0FNXTa1DYqjPZ5U84tkh46pFSLsbSse45xNhrMPeZDWlgHsp
WfK01YbCWioNVGk=
-----END CERTIFICATE-----
```


## Terminology

* [Schema Version](#schema-version)
* [Timestamps](#timestamps)
* [ULIDs](#ULIDs)
* [Namespaces](#namespaces)
* [Labels](#labels)
* [Parameters](#parameters)

## Schema Version

Every document MUST have a `schemaVersion` field.

The schema version must reference the version of the Installation State Specification schema used for this document.
It follows the [SemVer v2 specification](https://semver.org/).
The versioning scheme is further described in the [Process - Versioning][versioning].

[versioning]: 901-process.md#versioning

### Timestamps

Timestamps in JSON are defined in the [ECMAScript specification](https://www.ecma-international.org/ecma-262/9.0/index.html#sec-date-time-string-format), which matches the [ISO-8601 Extended Format](https://www.iso.org/iso-8601-date-and-time-format.html).

### ULIDs

A Universally Unique Lexicographically Sortable Identifier, [ULID], has multiple desirable characteristics:

- High probability of uniqueness
- Sortable by time. The first 48 bits contain a timestamp
- Monotonically increasing

Compared to a monotonic increment, ULID has strong advantages when it cannot be assumed that only one actor will be creating records. While other unique IDs are not meaningfully sortable, ULIDs are. Thus, even unordered claim storage records can be sorted.

[ULID]: https://github.com/ulid/spec

### Namespaces

Installation data MAY be scoped to a [namespace](/106-namespaces.md).
Namespaces MUST follow the [CNAB Namespace Format]. 

* The combination of namespace and name MUST be unique.
* IDs MUST be globally unique across namespaces.
* All data created by an installation MUST be defined in the same namespace.

### Labels

Documents MAY define [labels](/105-labels.md) which can be used by storage providers to query for the document.
For example, retrieving all installations with particular label.
Labels are key/value string pairs and MUST follow the [CNAB Label Format]. 

How labels are represented in storage is out-of-scope of this specification and is up to the implementing storage provider.


## Claim Injection

Compliant CNAB Installation State specification implementations MUST conform to this section.

### Environment Variables

The claim is produced outside of the CNAB package. The following claim data is injected
into the invocation container at runtime:

- `$CNAB_INSTALLATION_NAME`: The value of `claim.installation`.
- `$CNAB_BUNDLE_NAME`: The name of the present bundle.
- `$CNAB_ACTION`: The action to be performed (install, upgrade, ...)
- `$CNAB_REVISION`: The ULID for the present revision. (On upgrade, this is the _new_ revision)
- `$CNAB_CLAIMS_VERSION`: The version of this specification (currently `CNAB-Claims-1.0.0`)

Credential data, which is also injected into the invocation image, is _not_ managed by the claim system. Rules for injecting credentials are found in [the bundle runtime definition](103-bundle-runtime.md).

Parameters declared with an `env` key in the `destination` object MUST have their values injected as environment variables according to the name specified. Likewise, files MUST be injected if `path` is set on `destination`.

### Files

The invocation image may benefit from accessing the claim. Consequently, a claim MUST be attached to the invocation image when the invocation image is started.

The claim MUST be mounted at the path `/cnab/claim.json` inside of the bundle. The version of this claim that is to be mounted is the _version representing the current operation_. In other words, when a bundle is installed, the runtime creates the original installation claim and passes this in. On the first upgrade, the claim describing the _upgrade_ operation is located at `/cnab/claim.json`.

Note: Systems MAY be compliant with the CNAB Core specification but not support the Installation State specification. If `$CNAB_CLAIMS_VERSION` is not present, a runtime SHOULD assume that the Installation State specification is not implemented. Bundle authors may therefore have to take care when relying upon `/cnab/claim.json`, accommodating the case where the runtime does not support claims.

## Determine Execution Status

The claim result result is populated by the result of the invocation image's action. For example, consider the case where an invocation image executes an installation action. The action is represented by the following shell script, and `$CNAB_INSTALLATION_NAME` is set to `my_first_install`:

```bash
#!/bin/bash

set -eo pipefail

helm install stable/wordpress -n $CNAB_INSTALLATION_NAME > /dev/null
kubectl create pod $CNAB_INSTALLATION_NAME > /dev/null
echo "yay!"
```

(Note that the above script redirects data to `/dev/null` just to make the example easier. A production CNAB bundle might choose to include more verbose output.)

If both commands exit with code `0`, then the claim result will look like this:

```
{
  "claimId": "01E5G8ZYP714JVM8NHTJQ4FH15",
  "id": "ULID",
  "message": "yay!",    // From STDOUT (echo)
  "created": "TIMESTAMP",
  "status": "succeeded"   // succeeded (exit == 0), failed (exit > 0), or unknown (connection terminated before exit code was received)
}
```

Tools that implement claims MAY then present this result info to end users to show the result of running an invocation image.

## Sensitive Data Storage

The Installation State specification makes two assumptions about security:

- Claims are safe for writing sensitive information
- Claims are not a means for proxying identity

Parameters MAY contain sensitive information, such as database passwords. And this specification assumes that storing such information (un-redacted) can be done securely. However, the precise security mechanisms applied at the storage layer are beyond the scope of this specification.

Parameter values MUST be stored in claims. Implementations of the Installation State specification MUST NOT provide methods to block certain parameters from having their values written to the claim.

Credentials, on the other hand, are proxies for user identity, including potentially both authentication information and authorization information. Claims are not intended to provide a proxy for identity. In other words, a claim record SHOULD allow two users with identical permissions the ability to install the same configuration, it SHOULD NOT provide a way for one user to _gain_ the permissions of another user.

Credential data MUST NOT be stored in claims. Credentials are identity-specific, while claims are identity-neutral.

[CNAB Label Format]: /105-labels.md
[CNAB Namespace Format]: /106-namespaces.md

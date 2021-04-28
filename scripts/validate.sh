#!/bin/sh
###
# Use this to validate that the files in examples/* accord with the schema in schema/
#
# To get `ajv`, run `npm install -g ajv-cli`
###

set -eou pipefail

# Test all of the bundle files against the bundle schema
for json in $(ls -1 examples/101*-bundle.json); do
  schema="schema/bundle.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid -r schema/definitions.schema.json
done

# Test all of the claim files against the claim schema.
for json in $(ls -1 examples/400*-claim.json); do
  schema="schema/claim.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid -r schema/bundle.schema.json -r schema/definitions.schema.json
done

# Test all of the claim result files against the claim result schema.
for json in $(ls -1 examples/400*-claim-result.json); do
  schema="schema/claim-result.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid -r schema/definitions.schema.json
done

# Test all of the installation files against the installation state schema.
for json in $(ls -1 examples/401*-installation.json); do
  schema="schema/installation.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid -r schema/definitions.schema.json
done

# Test all of the claim files against the installation state schema.
for json in $(ls -1 examples/401*-claim.json); do
  schema="schema/claim.v2.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid -r schema/bundle.schema.json -r schema/definitions.schema.json
done

# Test all of the claim result files against the claim result schema.
for json in $(ls -1 examples/401*-claim-result.json); do
  schema="schema/claim-result.v2.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid -r schema/definitions.schema.json
done

# Test all of the dependency files against the dependencies schema
for json in $(ls -1 examples/500*-dependencies.json); do
  schema="schema/dependencies.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid
done

# Test all of the parameter sources files against the parameter sources schema
for json in $(ls -1 examples/810*-parameter-sources.json); do
  schema="schema/parameter-sources.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid
done

# Test all of the relocation mapping files against the relocation mapping schema.
for json in $(ls -1 examples/103*-relocation-mapping.json); do
  schema="schema/relocation-mapping.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid
done

# Test all of the status files against the status schema.
for json in $(ls -1 examples/804*-status.json); do
  schema="schema/status.schema.json"
  echo "Testing json '$json' against schema '$schema'"
  ajv test -s $schema -d $json --valid -r schema/bundle.schema.json
done


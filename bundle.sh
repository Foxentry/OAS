#!/bin/bash
set -e

# Run if GENERATE_EXAMPLES is set
if [ -z "$GENERATE_EXAMPLES" ]; then
  echo "Skipping example generation"
else
  echo "Generating examples"
  (cd ./requests && ./generate-examples.sh)
fi

redocly bundle openapi.yaml -o openapi-bundled.yaml

redocly lint openapi-bundled.yaml

#!/bin/bash

# Run if GENERATE_EXAMPLES is set
if [ -z "$GENERATE_EXAMPLES" ]; then
  echo "Skipping example generation"
else
  echo "Generating examples"
  (cd ./requests && ./generate-examples.sh)
  # Fail if previous command failed
  if [ $? -ne 0 ]; then
    echo "Failed to generate examples"
    exit 1
  fi
fi

redocly bundle openapi.yaml -o openapi-bundled.yaml

redocly lint openapi-bundled.yaml

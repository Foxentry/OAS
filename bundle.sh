#!/bin/bash

for generator in ./requests/*/generate-examples.sh; do
  bash "$generator"
done

redocly bundle openapi.yaml -o openapi-bundled.yaml

#!/bin/bash

# Check if API_KEY is set, if not, exit with error
if [ -z "$API_KEY" ]; then
  echo "API_KEY is not set"
  exit 1
fi


# Iterate over all JSON files in the requests directory
find . -type f -name "*.json" | while read json_file; do
  folder=$(dirname "$json_file")
  file=$(basename "$json_file" .json)
  echo "Generating $json_file"

  mkdir -p "../components/responseExamples/$folder"

  # Run the curl command and pipe the output to yq to convert to YAML
  curl -s --request POST \
       --url "https://api.foxentry.com/$folder" \
       --header "accept: application/json" \
       --header "api-version: 2.0" \
       --header "authorization: Bearer $API_KEY" \
       --header "content-type: application/json" \
       --header "foxentry-include-request-details: true" \
       --data @"$json_file" | yq -y . > "../components/responseExamples/$folder/${file}Example.yaml"
done

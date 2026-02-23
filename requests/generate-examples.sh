#!/bin/bash
set -euo pipefail

# Colors
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
BLACK=$'\033[30m'
BG_YELLOW=$'\033[43m'
WHITE=$'\033[97m'
BG_RED=$'\033[41m'

updated_count=0

# Check if API_KEY is set, if not, exit with error
if [ -z "${API_KEY:-}" ]; then
  printf "%bAPI_KEY is not set%b\n" "$BG_RED$WHITE$BOLD" "$RESET" >&2
  exit 1
fi

# Iterate over all JSON files in the requests directory
while IFS= read -r json_file; do
  folder=$(dirname "$json_file")
  file=$(basename "$json_file" .json)
  echo "Generating $json_file"

  out_dir="../components/responseExamples/$folder"
  out_file="$out_dir/${file}Example.yaml"
  mkdir -p "$out_dir"

  # Fetch new response and convert to YAML, wrapped in 'value:' for OpenAPI examples
  tmp_yaml=$(mktemp)
  curl -s --request POST \
       --url "https://api.foxentry.com/$folder" \
       --header "accept: application/json" \
       --header "api-version: 2.1" \
       --header "authorization: Bearer $API_KEY" \
       --header "content-type: application/json" \
       --header "foxentry-include-request-details: true" \
       --data @"$json_file" | yq -y '{value: .}' > "$tmp_yaml"

  # If no previous example exists, save immediately
  if [ ! -f "$out_file" ]; then
    mv "$tmp_yaml" "$out_file"
    printf "%bCreated %s%b\n\n" "$BG_YELLOW$BLACK$BOLD" "$out_file" "$RESET"
    continue
  fi

  # Compare ignoring request.code
  if diff -q \
      <(yq -y 'del(.value.request.code)' "$out_file" 2>/dev/null) \
      <(yq -y 'del(.value.request.code)' "$tmp_yaml" 2>/dev/null) >/dev/null 2>&1; then
    printf "%bNo change%b\n\n" "$GREEN" "$RESET"
    rm -f "$tmp_yaml"
  else
    mv "$tmp_yaml" "$out_file"
    ((++updated_count))
    printf "%bUpdated %s%b\n\n" "$BG_YELLOW$BLACK$BOLD" "$out_file" "$RESET"
  fi
done < <(find . -type f -name "*.json")

if (( updated_count == 0 )); then
  printf "%bNo files updated%b\n" "$GREEN" "$RESET"
else
  printf "%bUpdated files: %d%b\n" "$BG_YELLOW$BLACK$BOLD" "$updated_count" "$RESET"
fi

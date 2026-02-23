#!/usr/bin/env bash
# update-enabled-countries.sh
# Fetches enabled countries for each supported service type from the Foxentry API
# and updates the dataSource default + example lists in the OAS schema files using yq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_BASE="https://api.app.foxentry.com/projects/v1/service"

# service → schema file path (relative to SCRIPT_DIR)
declare -A SERVICE_FILES=(
  [location]="components/schemas/requests/location/LocationOptions.yaml"
  [company]="components/schemas/requests/company/CompanyOptions.yaml"
  [name]="components/schemas/requests/name/NameValidationBody.yaml"
)

# service → yq path to the dataSource property
declare -A SERVICE_YQ_PATH=(
  [location]=".properties.dataSource"
  [company]=".properties.dataSource"
  [name]=".properties.options.properties.dataSource"
)

# ── helpers ───────────────────────────────────────────────────────────────────

fetch_countries() {
  local service="$1"
  local response

  response=$(curl -sf "${API_BASE}/${service}/enabled-countries") || {
    echo "ERROR: Failed to fetch countries for '${service}'" >&2
    exit 1
  }

  # Extract country codes from the JSON array (no jq dependency needed here)
  echo "$response" | grep -oP '"countries":\[.*?\]' | grep -oP '"[A-Z]{2}"' | tr -d '"' | sort
}

update_datasource() {
  local file="$1"
  local yq_path="$2"
  local countries_json="$3"   # JSON array string, e.g. ["CZ","SK","PL"]

  # Update default list with all countries
  yq -Yi "${yq_path}.default = ${countries_json}" "$file"
}

# ── main ──────────────────────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <service>" >&2
  echo "  Available services: ${!SERVICE_FILES[*]}" >&2
  exit 1
fi

service="$1"

if [[ -z "${SERVICE_FILES[$service]+_}" ]]; then
  echo "ERROR: Unknown service '${service}'." >&2
  echo "  Available services: ${!SERVICE_FILES[*]}" >&2
  exit 1
fi

file="${SCRIPT_DIR}/${SERVICE_FILES[$service]}"
yq_path="${SERVICE_YQ_PATH[$service]}"

echo "→ Processing service: ${service}"
echo "  File: ${SERVICE_FILES[$service]}"

mapfile -t countries < <(fetch_countries "$service")

if [[ ${#countries[@]} -eq 0 ]]; then
  echo "ERROR: No countries returned for '${service}'" >&2
  exit 1
fi

echo "  Countries (${#countries[@]}): ${countries[*]}"

countries_json=$(printf '%s\n' "${countries[@]}" | jq -R . | jq -sc .)

update_datasource "$file" "$yq_path" "$countries_json"
  echo "  ✓ Updated."

echo ""
echo "Done. Run './bundle.sh' to rebundle."


#!/bin/sh
set -eu

app_name=$(printf '%s' "$AZURE_ENV_NAME" | tr -d '-' | tr '[:upper:]' '[:lower:]')
app_name_length=${#app_name}
if [ "$app_name_length" -lt 2 ] || [ "$app_name_length" -gt 18 ]; then
  echo "The normalized azd environment name must be between 2 and 18 characters to produce valid resource names." >&2
  exit 1
fi

#!/bin/bash

# Compile and upload ESPHome configs from this repo.
# Each device is a <name>.yaml entry point in the repo root.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

ESPHOME_IMAGE="ghcr.io/esphome/esphome:2026.9.1"

list_devices() {
  local yaml name
  shopt -s nullglob
  for yaml in *.yaml; do
    name="${yaml%.yaml}"
    printf '  %s\n' "$name"
  done
  shopt -u nullglob
}

resolve_yaml() {
  local device_name="$1"
  if [[ -f "${device_name}.yaml" ]]; then
    printf '%s.yaml\n' "$device_name"
  else
    return 1
  fi
}

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <device> [<device> ...]"
  echo "Example: $0 header-tank-controller water-management-panel"
  echo "Available devices:"
  list_devices
  exit 1
fi

status=0
for device_name in "$@"; do
  if ! yaml_file="$(resolve_yaml "$device_name")"; then
    echo "Error: no config found for '$device_name'."
    echo "Available devices:"
    list_devices
    status=1
    continue
  fi

  echo "Compiling and uploading $device_name ($yaml_file)..."
  docker run --rm --network host --privileged \
    -v "${ROOT}":/config \
    "$ESPHOME_IMAGE" compile "/config/${yaml_file}" && \
  docker run --rm --network host --privileged \
    -v "${ROOT}":/config \
    "$ESPHOME_IMAGE" upload "/config/${yaml_file}" || status=1
done

exit "$status"

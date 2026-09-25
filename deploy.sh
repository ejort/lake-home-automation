#!/bin/bash

# Compile and upload ESPHome configs from this repo.
# Device configs live at devices/<name>/device.yaml.
# One-off configs such as first-flash live at <name>.yaml in the repo root.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

ESPHOME_IMAGE="ghcr.io/esphome/esphome:2025.4.2"

list_devices() {
  local yaml name
  shopt -s nullglob
  for yaml in devices/*/device.yaml; do
    name="${yaml#devices/}"
    name="${name%/device.yaml}"
    printf '  %s\n' "$name"
  done
  for yaml in *.yaml; do
    name="${yaml%.yaml}"
    printf '  %s\n' "$name"
  done
  shopt -u nullglob
}

resolve_yaml() {
  local device_name="$1"
  if [[ -f "devices/${device_name}/device.yaml" ]]; then
    printf 'devices/%s/device.yaml\n' "$device_name"
  elif [[ -f "${device_name}.yaml" ]]; then
    printf '%s.yaml\n' "$device_name"
  else
    return 1
  fi
}

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <device> [<device> ...]"
  echo "Example: $0 tank-controller-1 lake-control"
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

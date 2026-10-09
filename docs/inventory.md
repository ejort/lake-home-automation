# Device inventory

Filenames are the ESPHome dashboard entry points. `name` is the deployed node name and hostname. Those stay as they are so OTA and existing API clients keep working.

| File | Node name | Friendly name | Board |
| --- | --- | --- | --- |
| `header-tank-controller.yaml` | `header-tank-controller` | Header Tank Controller | ESP32 relay board + tank interface v1 |
| `house-tank-controller.yaml` | `house-tank-controller` | House Collection Tank Controller | ESP32 relay board + tank interface v1 |
| `shed-tank-controller.yaml` | `shed-tank-controller` | Shed Collection Tank Controller | ESP32 relay board + tank interface v1 |
| `house-transfer-pump-controller.yaml` | `house-pump-controller` | House Transfer Pump Controller | ESP32 relay board |
| `water-management-panel.yaml` | `lake-control` | Water Management Panel | Guition ESP32-S3-4848S040 (3-relay) |
| `first-flash.yaml` | `first-flash` | First Flash | Bare ESP32 (esp32dev, ESP-IDF) |

The panel model is the Guition ESP32-S3-4848S040: ESP32-S3, 16 MB flash, octal PSRAM, 480×480 ST7701S, GT911. The config comments and the relay pins (GPIO40, GPIO2, GPIO1) match the 3-relay variant. Pin map: `docs/wiring/gpio.md`. Public pinout reference: [ESPHome device page](https://devices.esphome.io/devices/guition-esp32-s3-4848s040/). No vendor PDF is stored in this repo.

## Identity changes already applied

Friendly names changed. ESPHome prefixes entity names with `friendly_name`, and the restart button name and fallback AP SSID both embed it.

| Node | Previous friendly name | Current friendly name |
| --- | --- | --- |
| `house-tank-controller` | House Tank Controller | House Collection Tank Controller |
| `shed-tank-controller` | Shed Tank Controller | Shed Collection Tank Controller |
| `house-pump-controller` | House Pump Controller | House Transfer Pump Controller |
| `lake-control` | Guition480-basic | Water Management Panel |

Affected references:

- Home Assistant device name, and entity display names that pick up the friendly-name prefix.
- Restart button text: `Restart ${friendly_name}`.
- Fallback AP SSID. The shared default is still `${friendly_name} Hotspot`. House tank, shed tank, and house pump override it with `<node-name> Hotspot` because the new friendly names make that string longer than 32 characters.

Unchanged entity names: `Valve Relay`, `LED Switch`, `Pressure Sensor Voltage`, `Pressure Sensor Current`, `Backlight`, `Internal Light`, diagnostics (`Uptime`, `ESPHome Version`, Wi-Fi, IP).

`house-pump-controller` no longer includes the ADS1115 pressure sensors. That interface was copied from the tank template. The pump file now includes only the relay board and the contactor relay. Dropped entities on the next upload, if they were adopted: Pressure Sensor Voltage, Pressure Sensor Current.

The relay entity on the pump is still `id: valve_relay`, name `Valve Relay`.

## Proposed identity changes, not applied

| Current | Proposed | Why it is not done |
| --- | --- | --- |
| Node `house-pump-controller` | `house-transfer-pump-controller` | OTA hostname and API client identity would change. |
| Node `lake-control` | `water-management-panel` | Same. The panel has not been compiled from this tree, but the node name is already in the config. |
| Pump switch `valve_relay` / `Valve Relay` | `pump_relay` / `Pump Relay` | Keeps the entity that the current pump config publishes. |
| Build cache name `holding-tank-controller` | — | Local ESPHome storage under the old header-tank directory recorded node `holding-tank-controller`, friendly name Holding Tank Controller, address `first-flash.local`. The committed config was already `header-tank-controller` before this refactor. Confirm the name running on the header-tank board before the next OTA. |

## Installation overrides

| Node | `wifi.use_address` | Last recorded dashboard address |
| --- | --- | --- |
| `house-tank-controller` | `first-flash.local` | `first-flash.local` |
| `house-pump-controller` | `first-flash.local` | `first-flash.local` |
| `shed-tank-controller` | none | `shed-tank-controller.local` |
| `header-tank-controller` | none | cache still says `first-flash.local` from the holding-tank build |
| `lake-control` | none | no compile storage in this repo |
| `first-flash` | none | `first-flash.local` |

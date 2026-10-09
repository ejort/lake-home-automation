# Lake Home Automation

ESPHome firmware for the rainwater system at the lake house. Each physical device has one YAML file at the repo root so the ESPHome dashboard can open it directly. Shared behaviour lives in packages.

Five devices make up the system:

- **Header tank controller** — main storage tank. Reads level and switches its valve. Water leaves by gravity.
- **House collection tank controller** — rainwater tank. Its valve has to open together with the house transfer pump.
- **Shed collection tank controller** — rainwater tank. Opening its valve lets the shed's existing pressure-switch pump transfer water.
- **House transfer pump controller** — switches the contactor for the house transfer pump.
- **Water Management Panel** — Guition ESP32-S3-4848S040. It is the intended coordinator and touch UI. The screen still runs the board bring-up page.

`first-flash.yaml` is a minimal image for the first USB flash of a new relay-board ESP32, before it can take OTA updates.

## Layout

```text
header-tank-controller.yaml
house-tank-controller.yaml
shed-tank-controller.yaml
house-transfer-pump-controller.yaml
water-management-panel.yaml
first-flash.yaml

packages/
  common/          base, Wi-Fi, diagnostics
  hardware/        relay board, tank interface, Guition panel
  features/        pressure current, valve relay, pump relay
  applications/rainwater/
    header-tank.yaml
    collection-tank.yaml
    transfer-pump.yaml
    panel/         panel application and LVGL UI

assets/fonts/      Material Design Icons used by the panel
docs/              inventory, system behaviour, commissioning, wiring
secrets.yaml       local only, not committed
```

Device files stay small: node name, friendly name, package selection, and installation overrides such as `wifi.use_address`. GPIO maps stay in hardware packages. Pressure math, valve relay, and pump relay stay in feature packages. Tank role notes stay in the rainwater application packages.

There is no device-to-device transport in the tree yet. See `docs/rainwater-system.md` before adding ESPHome packet transport.

## Package relationships

Every device includes `packages/common/base.yaml`, which includes Wi-Fi and diagnostics.

| Device file | Also includes |
| --- | --- |
| `header-tank-controller.yaml` | relay board, tank interface, `rainwater/header-tank.yaml` |
| `house-tank-controller.yaml` | relay board, tank interface, `rainwater/collection-tank.yaml` |
| `shed-tank-controller.yaml` | relay board, tank interface, `rainwater/collection-tank.yaml` |
| `house-transfer-pump-controller.yaml` | relay board, `rainwater/transfer-pump.yaml` |
| `water-management-panel.yaml` | `guition-esp32-s3-4848s040.yaml`, `rainwater/panel/main.yaml` |
| `first-flash.yaml` | base only, plus a bare ESP32 block |

`header-tank.yaml` and `collection-tank.yaml` include valve control and pressure current. `transfer-pump.yaml` includes pump control. `panel/main.yaml` includes the LVGL UI. Valve control and pump control both use GPIO16, so a device includes only one of them.

Node names are not the same as every filename. `water-management-panel.yaml` builds node `lake-control`. `house-transfer-pump-controller.yaml` builds node `house-pump-controller`. Details and proposed renames are in `docs/inventory.md`.

## Secrets

```bash
cp secrets.yaml.example secrets.yaml
```

Fill in Wi-Fi, the fallback AP, OTA, and the API encryption key. `secrets.yaml` is gitignored.

## Deploy

Docker is required. From the repo root:

```bash
./deploy.sh header-tank-controller
./deploy.sh water-management-panel
./deploy.sh first-flash
```

Pass more than one name to compile and upload several devices in order. With no arguments, the script lists the configs it can build. The script uploads; do not point it at a board unless that upload is intended.

`esphome config <file>.yaml` checks a config without compiling or flashing.

## Add a device

1. Copy the closest root YAML file to a new filename.
2. Set `name` to a new node name. Reuse an existing node name only when you mean to update that same device.
3. Set `friendly_name`.
4. Include `packages/common/base.yaml` and the hardware package that matches the board. Include one application package.
5. Put installation-only settings in the new file: `wifi.use_address`, and later any per-tank level calibration. Do not copy GPIO maps into the device file.
6. Validate with `esphome config`, then compile. Flash only when the node name and `use_address` match the board you intend to update.

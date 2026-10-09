# Commissioning

## Secrets and tooling

Copy `secrets.yaml.example` to `secrets.yaml` in the repo root and fill it in. Do not commit `secrets.yaml`. Generated `.esphome/` directories are gitignored.

The deploy script uses Docker image `ghcr.io/esphome/esphome:2026.9.1`. Check a file with `esphome config <file>.yaml` before any upload.

## First flash

New relay-board modules start from `first-flash.yaml` over USB. That image has Wi-Fi, API, and OTA only. It does not drive the valve relay or the pressure interface.

After the first boot the node is `first-flash`. The house tank and house pump entry points still set `wifi.use_address: first-flash.local` so OTA can find a board that has not yet booted its final node name. Remove that override after a successful upload, once mDNS answers on the real node name.

Shed tank storage last recorded `shed-tank-controller.local`, and its entry point has no `use_address` override.

## Header tank name check

A local build cache for the header tank directory still records node `holding-tank-controller` and address `first-flash.local`. The YAML node name is `header-tank-controller` and has no `use_address`. Before OTA, confirm which name the board is actually advertising. Uploading `header-tank-controller` at `header-tank-controller.local` will not reach a board that is still `first-flash` or `holding-tank-controller`.

## Panel

`water-management-panel.yaml` keeps node name `lake-control`. LVGL is the copy built into ESPHome 2026.9. The old pin of `clydebarrow/esphome` at `82264dc` fails to compile against current ESPHome (`esph_log_e`). The bring-up page was adjusted to that schema: display and touchscreen entries are ids, `btn` is `button`, `default_group: general` declares the focus group, and the only page is `skip: false`. Widget tree, colours, and the Center Light action are otherwise unchanged. GPIO45 (touch SCL) still warns as a strapping pin; that pin was already in the bring-up config. The ST7701S driver is deprecated in favour of `mipi_rgb`, and the official device page still publishes the ST7701S pin map used here.

The icon font is `assets/fonts/materialdesignicons-webfont.ttf` (Material Design Icons 7.4.47). It was referenced before but not stored in the repo. Roboto is fetched from Google Fonts at compile time, so the panel compile needs network.

## Calibration

Tank interfaces share one gain (`4.096`) and the 100 ohm shunt formula. Per-tank zero and span are not set. When they are known, put them in that tank's root YAML and consume them from `packages/features/pressure-level.yaml`. Do not hard-code one tank's depth into the shared feature.

## Upload

`./deploy.sh <config-name>` compiles and then uploads. Compile alone when you only want a firmware check. Nothing in this refactor should be flashed until the node name and `use_address` have been checked against the board.

# Commissioning

## Secrets and tooling

Copy `secrets.yaml.example` to `secrets.yaml` in the repo root and fill it in. Do not commit `secrets.yaml`. Generated `.esphome/` directories are gitignored.

`packet_transport_key` is shared by every node on the UDP transport. Nodes with different keys reject each other's packets, so changing it means reflashing all of them.

All five nodes are now on that transport and have to be flashed from this tree together. A panel talking to a tank controller running older firmware sees that node as offline, and offline counts as unsafe: the house pump and the shed valve will be held off.

The deploy script uses Docker image `ghcr.io/esphome/esphome:2026.9.1`. Check a file with that image before any upload, not with a local `esphome`, because the configs use options newer than many installs:

```bash
docker run --rm -v "$PWD":/config ghcr.io/esphome/esphome:2026.9.1 config /config/<file>.yaml
```

## First flash

New relay-board modules start from `first-flash.yaml` over USB. That image has Wi-Fi, API, and OTA only. It does not drive the valve relay or the pressure interface.

After the first boot the node is `first-flash`. The house tank and house pump entry points still set `wifi.use_address: first-flash.local` so OTA can find a board that has not yet booted its final node name. Remove that override after a successful upload, once mDNS answers on the real node name.

Shed tank storage last recorded `shed-tank-controller.local`, and its entry point has no `use_address` override.

## Header tank name check

A local build cache for the header tank directory still records node `holding-tank-controller` and address `first-flash.local`. The YAML node name is `header-tank-controller` and has no `use_address`. Before OTA, confirm which name the board is actually advertising. Uploading `header-tank-controller` at `header-tank-controller.local` will not reach a board that is still `first-flash` or `holding-tank-controller`.

Node names matter more than they used to: the panel lists its field nodes by node name under `providers`, so a board advertising an unexpected name is simply not heard.

## Panel

`water-management-panel.yaml` keeps node name `lake-control`. LVGL is the copy built into ESPHome 2026.9. The old pin of `clydebarrow/esphome` at `82264dc` fails to compile against current ESPHome (`esph_log_e`). GPIO45 (touch SCL) still warns as a strapping pin; that pin was already in the bring-up config. The ST7701S driver is deprecated in favour of `mipi_rgb`, and the official device page still publishes the ST7701S pin map used here.

The screen is the water status and control page: a level gauge per tank on the top row, and the actuator under each tank on the bottom row. The Guition bring-up page and its Center Light button are gone, and with them the `Internal Light` entity. GPIO40 is still wired as an output in the hardware package, just with nothing driving it.

The icon font is `assets/fonts/materialdesignicons-webfont.ttf` (Material Design Icons 7.4.47). Roboto is fetched from Google Fonts at compile time, so the panel compile needs network.

### What to expect on the first boot

For the first 30 seconds the three buttons read "Starting" and refuse to command anything. The interlocks publish nothing until then, which is deliberate: every rule treats an unknown tank level as unsafe, so arming immediately would make each panel reboot stop the pump and close the shed valve. See `docs/rainwater-system.md`.

After that, a button reading "No level" or "Offline" means the panel is not hearing that node, or that board has no calibration that resolves. "No level" is the first symptom; the `... Link` binary sensors on the panel's web server take up to 60s to catch up, so check the gauges before concluding a node is fine.

A refused button press is logged rather than silent. Watch `esphome logs water-management-panel.yaml` for "refused; interlock not satisfied" if a button does nothing.

## Calibration

Tank interfaces share one gain (`4.096`) and the 100 ohm shunt formula. Percent full is calibrated on the board, not in YAML, so the three tanks run the same firmware with different numbers.

Each tank node publishes two config numbers, `Level Empty Current` and `Level Full Current`, in mA. Percent full is the straight line between them, clamped to 0-100. First boot uses the nominal span, 4.0 and 20.0, which is not a measured tank.

To calibrate, open the node's web server or use the API, read `Pressure Sensor Current` at a known empty tank and write that value into `Level Empty Current`, then do the same at full for `Level Full Current`. `Tank Level` updates as soon as either number changes. Values are stored in flash and survive a reboot, but preferences flush every 10 minutes, so leave the node powered for a while after calibrating. A node where empty and full are equal publishes no level.

Calibrate before relying on the interlocks. They compare against the calibrated span, so an uncalibrated header tank reaching "100%" on the nominal 4-20 mA line will stop the pump well before the tank is actually full, and an uncalibrated collection tank reading "0%" will refuse to start it.

## Upload

`./deploy.sh <config-name>` compiles and then uploads. Compile alone when you only want a firmware check. Nothing should be flashed until the node name and `use_address` have been checked against the board.

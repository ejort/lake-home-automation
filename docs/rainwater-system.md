# Rainwater system

The header tank is the main store. House and shed tanks collect rainwater and transfer into it.

House transfer needs two controllers: the house tank valve opens, and the house transfer-pump controller closes its contactor. Neither action alone is a complete house transfer. The field controllers do not sequence each other.

Shed transfer is different. Opening the shed tank valve lets water reach the shed pump, which already starts from its own pressure switch. The house transfer-pump controller is not part of shed transfer.

Each tank controller keeps its own valve relay and, on the tank boards, its own pressure reading. Nothing in this repo imposes a maximum run time, a remote heartbeat, or a safe state when Wi-Fi drops.

## What the firmware does today

Tank controllers publish shunt voltage and calculated current, and they switch GPIO16 for the valve. The pump controller switches that same pin for the contactor. The panel shows the Guition bring-up page (one button, internal relay light) and does not read tank levels or command field relays.

Relay state is the coil output only. No valve end-stop, contactor auxiliary, or flow switch is configured, so published "on" is not physical confirmation.

## Packet transport

No ESPHome packet transport is configured. This refactor does not add one. Two transports are supported by [packet transport](https://esphome.io/components/packet_transport/) and neither has been proven on this site:

- **UDP over Wi-Fi.** Uses the existing association and IP network. It fails when a node is off Wi-Fi, on the wrong VLAN, or asleep. Coverage is the access-point layout, which is not documented here.
- **ESP-NOW.** Radio frames on the current Wi-Fi channel, without IP. Peers still share the Wi-Fi radio, unicast needs MAC addresses, and range is not the same thing as "joined the house SSID".

Pick one after a range check between the panel, both collection tanks, the header tank, and the pump. Until then, do not assume any pair can hear each other.

Intended shape once a transport exists:

- Carry sensor and binary-sensor state (level, relay output, later any real proof sensors).
- Publish persistent desired state, for example `house_pump_run_requested`, `house_valve_open_requested`, and `shed_valve_open_requested`. Receivers act on that level. Do not send toggles.
- Keep desired state and reported state separate. Reported relay state stays distinct from any future end-stop or contactor feedback.
- Put shared transport setup in one package. Put each node's published and received ids in that node's own communications package.
- Keep house and shed sequences in separate panel coordination packages. Shed transfer must not grow a pump-contactor step.

The panel should own requested state, reported state, availability, and transfer progress. UI handlers should call the same command entry points as automatic coordination, not drive relays inline.

## Gaps left in place

These are missing on purpose. Adding them would change how the relays behave.

- **Heartbeat expiry.** No "peer last seen" timeout. A stuck remote request would not clear.
- **Communication loss.** API `reboot_timeout` is `0s`, so losing Home Assistant does not reboot the node and does not force relays off. Wi-Fi loss does not change valve or pump outputs.
- **Restart recovery.** Valve, pump, and status LED use `RESTORE_DEFAULT_OFF`: the last state is restored when flash has it, otherwise the output stays off. Preferences flush every 10 minutes, so a power cut inside that window can forget a recent switch change. Panel backlight is `ALWAYS_ON`.
- **Maximum runtime.** Nothing turns a valve or the pump off after a time limit. A latched request or a restored "on" can run until something switches it off.
- **Level calibration.** Current is shunt voltage times 10. There is no per-tank empty/full span, so percent or depth is not published.
- **Panel coordination and water UI.** Not implemented. The LVGL page is still the Center Light bring-up control.

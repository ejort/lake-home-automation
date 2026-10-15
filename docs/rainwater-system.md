# Rainwater system

The header tank is the main store. House and shed tanks collect rainwater and transfer into it.

House transfer is the house transfer-pump controller closing its contactor. The house collection tank controller reads level and does not switch a valve. The field controllers do not sequence each other.

Shed transfer is different. Opening the shed tank valve lets water reach the shed pump, which already starts from its own pressure switch. The house transfer-pump controller is not part of shed transfer.

The header and shed tank controllers each switch their own valve relay. The house collection tank controller has no valve relay. Every tank board publishes its own pressure reading. Nothing in this repo imposes a maximum run time, a remote heartbeat, or a safe state when Wi-Fi drops.

## What the firmware does today

Tank controllers publish shunt voltage, calculated current, and percent full from a per-board empty/full calibration. The header and shed controllers switch GPIO16 for the valve. The house collection tank controller leaves that relay unconfigured. The pump controller switches that same pin for the contactor. The panel shows the Guition bring-up page, now with a House Pump button beside the internal relay light. It does not read tank levels, and the pump is the only field relay it commands.

Relay state is the coil output only. No valve end-stop, contactor auxiliary, or flow switch is configured, so published "on" is not physical confirmation.

## Packet transport

The panel and the house pump are linked by [packet transport](https://esphome.io/components/packet_transport/) over UDP, in `packages/communications/udp.yaml` and each node's own communications package. There is no Home Assistant and no broker. Broadcast defaults are used (`255.255.255.255`, port `18511`), so the link needs both nodes on the same Wi-Fi without client isolation. Traffic is encrypted with the shared `packet_transport_key` secret and carries a rolling code, so a replayed packet cannot close the contactor.

This pair has not been range-checked on site, and no other node is on the transport yet. ESP-NOW remains the alternative if UDP coverage turns out to be the problem: radio frames on the current Wi-Fi channel, without IP, but unicast needs MAC addresses and range is not the same thing as "joined the house SSID".

The pump link follows the shape the rest should keep:

- Carry sensor and binary-sensor state. Tank levels and any real proof sensors are still to come.
- Publish persistent desired state. `house_pump_run_requested` is live. `shed_valve_open_requested` is not. The house collection tank has no valve relay to command. Receivers act on that level. Do not send toggles.
- Keep desired state and reported state separate. `pump_relay_reported` is the coil output and stays distinct from any future end-stop or contactor feedback.
- Keep shared transport setup in `packages/communications/udp.yaml`. Put each node's published and received ids in that node's own communications package.
- Keep house and shed sequences in separate panel coordination packages. Shed transfer must not grow a pump-contactor step.

The panel should own requested state, reported state, availability, and transfer progress. UI handlers should call the same command entry points as automatic coordination, not drive relays inline.

## Gaps left in place

These are missing on purpose. Adding them would change how the relays behave.

- **Heartbeat expiry.** No "peer last seen" timeout. A stuck remote request would not clear.
- **Communication loss.** API `reboot_timeout` is `0s`, so losing Home Assistant does not reboot the node and does not force relays off. Wi-Fi loss does not change valve or pump outputs.
- **Restart recovery.** Valve, pump, and status LED use `RESTORE_DEFAULT_OFF`: the last state is restored when flash has it, otherwise the output stays off. Preferences flush every 10 minutes, so a power cut inside that window can forget a recent switch change. Panel backlight is `ALWAYS_ON`.
- **Maximum runtime.** Nothing turns a valve or the pump off after a time limit. A latched request or a restored "on" can run until something switches it off.
- **Level in depth.** Percent full comes from the per-tank empty/full current span set on each board. Depth in length is still not published, and nothing uses percent to start or stop a transfer.
- **Panel coordination and water UI.** Not implemented. The LVGL page is still the Center Light bring-up control.

# Rainwater system

The header tank is the main store. House and shed tanks collect rainwater and transfer into it.

House transfer is the house transfer-pump controller closing its contactor. The house collection tank controller reads level and does not switch a valve. Shed transfer is different: opening the shed tank valve lets water reach the shed pump, which already starts from its own pressure switch, so the house transfer-pump controller is not part of shed transfer.

The header and shed tank controllers each switch their own valve relay. The house collection tank controller has no valve relay. Every tank board publishes its own pressure reading.

The panel is the coordinator. Field controllers still do not sequence each other; they follow the panel's held requests and report their own relay back.

## What the firmware does today

Tank controllers publish shunt voltage, calculated current, and percent full from a per-board empty/full calibration. The header and shed controllers switch GPIO16 for the valve. The house collection tank controller leaves that relay unconfigured. The pump controller switches that same pin for the contactor.

The panel reads all three tank levels, draws a gauge for each, and commands the header valve, the house pump, and the shed valve from three buttons. It also holds the interlocks below.

Relay state is the coil output only. No valve end-stop, contactor auxiliary, or flow switch is configured, so published "on" is not physical confirmation. Every interlock below is therefore reasoning about requested and reported coil state, not about water actually moving.

## Interlocks

The panel will not start something it cannot justify, and withdraws a request when the justification goes away. Nothing is ever started automatically; starting is always a button press.

House pump, all of which must hold:

- header tank below 100%
- house collection tank above 0%
- header tank valve reporting open
- the pump and both tanks reachable, and both levels readable

Shed tank valve, all of which must hold:

- header tank below 100%
- shed collection tank above 0%
- both tanks reachable, and both levels readable

Header tank valve: only that the header tank controller is reachable. It is the gravity feed to the house, not a transfer path, so no level rule opens or closes it.

Losing a condition stops the pump or closes the shed valve. That is one mechanism, not a rule per threshold: `house_pump_permitted` and `shed_valve_permitted` in `packages/applications/rainwater/panel/coordination/` are the whole condition, and their `on_release` withdraws the request.

A running pump under a header valve that closes is covered the same way, by stopping the pump. The alternative, refusing to close the valve while the pump runs, was not taken: a valve that will not close is worse than a pump that stops.

Percent full is clamped to 0-100, so "100%" is the top of the calibrated span and "0%" the bottom, not a full or dry tank. Both thresholds are inclusive, matching `>= 100` and `<= 0`.

There is no hysteresis and none is needed. Reaching 100% stops the pump, and dropping back below 100% only makes the button pressable again; nothing restarts on its own, so the contactor cannot cycle at the threshold.

### Unknown state is unsafe

An unreadable level and an unreachable node both count as "not permitted", so they stop the pump and close the shed valve the same way a threshold does.

Reachability comes from the packet transport ping-pong handshake, surfaced as the `*_online` status sensors and published as the `... Link` entities. A node reads offline after twice `ping_pong_recycle_time` without returning a pong, so the configured 30s is a 60s detection window. That is the only heartbeat in the system.

Two things cover a silent node, which is why both are checked. The transport itself sets a timed-out provider's sensors to NaN, so a stale level cannot be mistaken for a fresh one. The status sensor then reports the node offline. The NaN check is the one that matters at boot: a provider's `last_key_response_time` starts at zero, so for the first minute the status sensor reads connected before any pong has actually arrived, and only the absent level gives it away.

Treating unknown as unsafe would otherwise make every panel reboot stop the pump, because at boot nothing is known yet. So `coordination/arming.yaml` holds every interlock unpublished for 30s after boot, long enough for Wi-Fi association and a ping-pong round trip at a 5s update interval. While unarmed nothing can be turned on, because the request scripts refuse without a state, and nothing is turned off, because no rule has published a false yet. A relay already running keeps running across a panel reboot.

### Where the guard lives

The guard is in the request scripts, not on the widgets. `request_house_pump_on`, `request_shed_valve_open`, and `request_header_valve_open` each re-check the interlock and log a refusal, so a stale button cannot command a start. The disabled state on screen is cosmetic.

A button is disabled only while its actuator is both off and not permitted. Anything that is running stays pressable, so a losing interlock never leaves a relay running with no way to stop it by hand.

### Field-side enforcement

The pump and the shed valve each re-assert a held "off" on a 5s interval, in their communications packages. Triggers alone fire on change only, so a relay switched on from a node's own web page would otherwise sit there with the panel holding "off". Only "off" is re-asserted; a stale "on" must not fight a local stop. The header valve has no automatic close, so it has no interval.

## Packet transport

All five nodes are linked by [packet transport](https://esphome.io/components/packet_transport/) over UDP, in `packages/communications/udp.yaml` and each node's own communications package. There is no Home Assistant and no broker. Broadcast defaults are used (`255.255.255.255`, port `18511`), so the link needs every node on the same Wi-Fi without client isolation. Traffic is encrypted with the shared `packet_transport_key` secret. Field nodes add a rolling code, so a replayed packet cannot close a contactor, and the panel adds ping-pong so it can tell a silent node from a steady one.

This has not been range-checked on site. ESP-NOW remains the alternative if UDP coverage turns out to be the problem: radio frames on the current Wi-Fi channel, without IP, but unicast needs MAC addresses and range is not the same thing as "joined the house SSID".

What goes over the wire:

| Direction | Carried |
| --- | --- |
| Tank nodes to panel | `tank_level`, and `valve_relay_reported` on the header and shed tanks |
| Pump to panel | `pump_relay_reported` |
| Panel to field | `header_valve_open_requested`, `house_pump_run_requested`, `shed_valve_open_requested` |

Tank nodes keep generic broadcast ids, because all three run the same level feature. The panel tells them apart by `provider` and maps them with `remote_id`, so `header_tank_level` and `shed_valve_reported` only exist on the panel.

The rules the link follows:

- Carry sensor and binary-sensor state. Real proof sensors are still to come.
- Publish persistent desired state. Receivers act on that level. Do not send toggles.
- Keep desired state and reported state separate. `pump_relay_reported` is the coil output and stays distinct from any future end-stop or contactor feedback.
- Set `trigger_on_initial_state: true` on anything acted upon. ESPHome does not fire triggers for an entity's first state, so without it a node ignores the first request it ever receives and the panel draws a stale button.
- Keep shared transport setup in `packages/communications/udp.yaml`. Put each node's published and received ids in that node's own communications package.
- Keep house and shed sequences in separate panel coordination packages. Shed transfer must not grow a pump-contactor step.

## Gaps left in place

These are missing on purpose. Adding them would change how the relays behave.

- **Field-side heartbeat expiry.** The panel notices a silent field node; a field node does not notice a silent panel. A request latched "on" before the panel disappeared stays on.
- **Communication loss.** API `reboot_timeout` is `0s`, so losing Home Assistant does not reboot the node and does not force relays off. Wi-Fi loss does not change valve or pump outputs.
- **Restart recovery.** Valve, pump, and status LED use `RESTORE_DEFAULT_OFF`: the last state is restored when flash has it, otherwise the output stays off. Preferences flush every 10 minutes, so a power cut inside that window can forget a recent switch change. Panel backlight is `ALWAYS_ON`.
- **Maximum runtime.** Nothing turns a valve or the pump off after a time limit. A transfer permitted by the interlocks can run until a threshold, a dropped link, or a button stops it.
- **Level in depth.** Percent full comes from the per-tank empty/full current span set on each board. Depth in length is still not published.
- **Automatic transfer.** Nothing starts a transfer on its own. The interlocks only decide what a person is allowed to start, and when to withdraw it.

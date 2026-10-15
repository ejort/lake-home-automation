# GPIO map

Values below are the ones the firmware drives. Relay outputs are not inverted unless noted. No separate wiring diagram or datasheet PDF is in the repo.

## ESP32 relay board

Used by the header, house, and shed tank controllers and by the house transfer pump.

| Function | GPIO | Notes |
| --- | --- | --- |
| Relay 1 | GPIO16 | Output, active-high. Valve on the header and shed tank controllers. Unused on the house collection tank controller. Pump contactor on the house pump controller. `RESTORE_DEFAULT_OFF`. |
| Status LED | GPIO23 | Output, active-high. `RESTORE_DEFAULT_OFF`. |

Tank controllers also carry the pressure interface. The pump controller does not.

## Tank interface v1

| Function | Connection | Notes |
| --- | --- | --- |
| I2C SDA | GPIO26 | |
| I2C SCL | GPIO27 | |
| ADS1115 | address `0x48` | Single-ended A0 to ground, gain ±4.096 V, update 10 s |
| Shunt | 100 ohm on A0 | 4–20 mA reads about 0.4–2.0 V. Current (mA) = voltage × 10 |

## Guition ESP32-S3-4848S040 (3-relay)

| Function | GPIO | Notes |
| --- | --- | --- |
| Backlight PWM | GPIO38 | LEDC 100 Hz. Light `Backlight`, `ALWAYS_ON` |
| Relay 1 | GPIO40 | Built-in 240 V relay. Output only, no switch entity since the bring-up page was replaced |
| Relay 2 | GPIO2 | Output only, no switch entity |
| Relay 3 | GPIO1 | Output only, no switch entity |
| Touch I2C SDA | GPIO19 | GT911, bus `bus_a` |
| Touch I2C SCL | GPIO45 | |
| LCD SPI clock | GPIO48 | ST7701S init bus |
| LCD SPI MOSI | GPIO47 | |
| LCD CS | GPIO39 | |
| LCD DE | GPIO18 | |
| LCD HSYNC | GPIO16 | |
| LCD VSYNC | GPIO17 | |
| LCD PCLK | GPIO21 | 12 MHz, not inverted |
| Red data | GPIO11, GPIO12, GPIO13, GPIO14, GPIO0 | r1–r5 |
| Green data | GPIO8, GPIO20, GPIO3, GPIO46, GPIO9, GPIO10 | g0–g5 |
| Blue data | GPIO4, GPIO5, GPIO6, GPIO7, GPIO15 | b1–b5 |

Display timing matches the existing bring-up config: 480×480, SPI mode 3, 2 MHz init, RGB order, MDT flag disabled. Touch is not mirrored.

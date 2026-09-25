# Lake Home Automation

ESPHome firmware for the rainwater system at the lake house. These configs live in their own project so the tank devices can be built and flashed separately from the rest of the house.

Five devices make up the system:

- **Three tank controllers**, one for each rainwater tank. Each reads a pressure sensor for the water level and drives a switch for that tank's valve.
- **One transfer-pump controller**, which switches an AC contactor to run the pump that moves water between tanks.
- **One display**, for reporting levels and for central control of the valves and pump.

## Layout

Shared board setup, Wi-Fi, and the Home Assistant API live in `common/`. Wi-Fi credentials and API keys are in `common/secrets.yaml`, which is not committed.

Each device is a directory under `devices/` with a `device.yaml` entry point. A one-off bring-up config can also sit at the repo root as `<name>.yaml`.

| Config | Role |
| --- | --- |
| `devices/tank-controller-1` | Shed tank. Pressure sensor on an ADS1115, plus the valve relay. |
| `devices/lake-control` | Display board (Guition ESP32-S3). Starting point for reporting and central control. |
| `first-flash.yaml` | Minimal image for the first USB flash of a new board, before it can take OTA updates. |

The other two tank controllers and the transfer-pump controller are not in the tree yet.

## Deploy

Docker is required. From anywhere:

```bash
./deploy.sh tank-controller-1
./deploy.sh lake-control
./deploy.sh first-flash
```

Pass more than one name to compile and upload several devices in order. With no arguments, the script lists the configs it can build.

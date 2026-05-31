Here is your completely updated `meshtastic-esp32-dxlr30-setup.md` documentation. It has been revised to precisely match the hardware pinout definitions from your verified, working `variant.h` and the streamlined `platformio.ini` environment block that successfully brought your DX-LR30 node online.

---

# Meshtastic Setup: ESP32 WROOM-32 + DX-LR30 (SX1262)

## Hardware

| Component | Details |
| --- | --- |
| MCU | ESP32 WROOM-32 dev board |
| LoRa module | DX-LR30 by DX-SMART Technology |
| LoRa chip | Semtech SX1262 |
| OS | Linux Mint 22.3 (Ubuntu 24.04 base) |
| Firmware | Meshtastic 2.8.0 |

---

## Wiring

> ⚠️ **Always connect the antenna before powering on.** Operating the SX1262 without an antenna can permanently damage the RF front-end.
> ⚠️ **Use 3.3V only.** The DX-LR30 is not 5V tolerant.

| ESP32 WROOM-32 Pin | DX-LR30 Pin | Wire color (suggested) | Notes |
| --- | --- | --- | --- |
| 3.3V | VCC | Red | 3.3V only — never 5V |
| GND | GND | Black | Common Ground |
| **GPIO5** | **SCK** | **Yellow** | Hardware SPI Clock |
| GPIO19 | MISO | Blue | Standard Hardware MISO |
| **GPIO27** | **MOSI** | **Green** | Hardware SPI MOSI |
| **GPIO18** | **NSS** | **Orange** | Radio Chip Select (CS) |
| GPIO14 | RST | White | Reset |
| GPIO26 | DIO1 | Purple | IRQ interrupt — SX1262 specific |
| GPIO32 | BUSY | Grey | **Required** — SX1262 specific |
| — | ANT | — | Connect antenna first |

### Wiring Diagram

```text
  +----------------------+             +-------------------+
  |    ESP32 WROOM-32    |             |   DX-LR30 Radio   |
  |                      |             |     (SX1262)      |
  |                 3.3V +-------------+ VCC               |
  |                  GND +-------------+ GND               |
  |                      |             |                   |
  |         (SCK) GPIO 5 +-------------+ SCK               |
  |       (MISO) GPIO 19 +-------------+ MISO              |
  |       (MOSI) GPIO 27 +-------------+ MOSI              |
  |                      |             |                   |
  |         (CS) GPIO 18 +-------------+ NSS               |
  |       (RESET) GPIO 14+-------------+ RST               |
  |        (IRQ) GPIO 26 +-------------+ DIO1              |
  |       (BUSY) GPIO 32 +-------------+ BUSY              |
  +----------------------+             +-------------------+

```

### Key differences from SX1276/SX1278

The SX1262 requires two extra pins not present on older modules:

* **BUSY (GPIO32)** — must be read before every SPI transaction
* **DIO1 (GPIO26)** — interrupt pin (replaces DIO0 on SX1276)

Both are mandatory. The firmware will fail silently if BUSY is left unconnected.

---

## Variant file

Location: `variants/dxlr30-wroom32/variant.h`

```cpp
#pragma once

// SPI Pins Configuration
#define PIN_SPI_SCK     5
#define PIN_SPI_MISO    19
#define PIN_SPI_MOSI    27

// SX1262 (DX-LR30) - Meshtastic macro names
#define SX126X_CS       18   
#define SX126X_RESET    14
#define SX126X_DIO1     26
#define SX126X_BUSY     32   // SX1262 required
#define SX126X_DIO2_AS_RF_SWITCH true

// Misc
#define BUTTON_PIN      0    // BOOT button
#define LED_PIN         2    // onboard LED

// I2C (optional OLED)
#define I2C_SDA         21
#define I2C_SCL         22

```

---

## platformio.ini entry

```ini
[env:diy-esp32-sx1262]
extends = esp32_base
board = esp32dev

board_build.flash_size = 4MB
board_upload.flash_size = 4MB
board_build.partitions = huge_app.csv

build_flags =
  ${esp32_base.build_flags}
  -I variants/dxlr30-wroom32
  -DUSE_SX1262
  -D FORCE_REGION=1

```

> Note: By omitting `-DSX126X_CS=...` macros from `build_flags`, PlatformIO compiles cleanly using your explicit layout inside `variants/dxlr30-wroom32/variant.h`.

### Partition table

The Meshtastic firmware for ESP32 compiles to ~2.1MB which exceeds `min_spiffs.csv` (1.96MB app limit). Use `huge_app.csv` instead:

```bash
cp ~/.platformio/packages/framework-arduinoespressif32/tools/partitions/huge_app.csv .

```

---

## Build environment

### System dependencies (Linux Mint 22.3 / Ubuntu 24.04)

```bash
sudo apt-get install -y \
  libncurses6 libncurses-dev \
  libffi-dev libssl-dev \
  python3-venv python3-pip \
  gcc git wget flex bison \
  cmake ninja-build libusb-1.0-0 \
  libtinfo6

# Symlinks for legacy toolchain compatibility
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 \
            /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 \
            /usr/lib/x86_64-linux-gnu/libtinfo.so.5

```

### Clone firmware repo

```bash
git clone https://github.com/meshtastic/firmware.git
cd firmware
git submodule update --init --recursive

```

### Build with Docker (recommended)

The current PlatformIO toolchain can hit compilation friction on modern Ubuntu/Mint distributions due to shared library discrepancies. Using Docker isolates the compiler cleanly.

**Dockerfile**

```dockerfile
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    git curl libncurses6 libtinfo6 \
    gcc g++ make cmake ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN pip install platformio

WORKDIR /workspace

```

```bash
docker build -t meshtastic-builder .

```

**runDocker.sh**

```bash
#!/bin/bash
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  meshtastic-builder \
  platformio run -e diy-esp32-sx1262

# Fix ownership after Docker run (Docker writes files as root)
sudo chown -R $USER:$USER .pio/

```

```bash
chmod +x runDocker.sh
sh runDocker.sh

```

---

## Output files

After a successful build, output files are located at:

```
.pio/build/diy-esp32-sx1262/
├── firmware-diy-esp32-sx1262-2.8.0.bin          # app only
├── firmware-diy-esp32-sx1262-2.8.0.factory.bin  # full flash image ← use this
└── littlefs-diy-esp32-sx1262-2.8.0.bin          # filesystem image

```

---

## Flashing

```bash
# Find your serial port
ls /dev/ttyUSB* /dev/ttyACM*

# Flash the factory binary (bootloader + partitions + firmware bundle)
python -m esptool --port /dev/ttyUSB0 --baud 921600 \
  write_flash 0x0 \
  .pio/build/diy-esp32-sx1262/firmware-diy-esp32-sx1262-2.8.0.factory.bin

```

> 💡 **Pro-Tip:** If flashing over esptool or an online web installer drops communication midway or causes strapping pin conflicts, briefly disconnect the **NSS (Grey / GPIO 18)** and **SCK (Blue / GPIO 5)** lines during the flash sequence, then reconnect them before booting.

---

## First boot & configuration

1. Connect to your computer via your serial utility at **921600 baud**.
2. Tap the physical **RST** button to verify the setup cycle.
3. Open the **Meshtastic mobile application** (iOS or Android).
4. Go to the **Manual** connection tab, input the target node's unique MAC address footprint discovered during the boot logs, and authenticate using the pairing code:
> **`123456`**



### Expected Serial Monitor Output

```text
DEBUG | SPI.begin(SCK=5, MISO=19, MOSI=27, NSS=18)
DEBUG | SX126xInterface(cs=18, irq=26, rst=14, busy=32)
INFO  | Start meshradio init
INFO  | Radio freq=906.875, config.lora.frequency_offset=0.000
INFO  | Wanted region 1, using US
INFO  | SX126x init result 0
INFO  | SX1262 init success

```

---

## DX-LR30 frequency variants

| Model | Frequency | Region |
| --- | --- | --- |
| DX-LR30-433M22S | 433 MHz | Asia (CN, IN) |
| DX-LR30-900M22S | 868 / 915 MHz | US, EU, AU |

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Dynconfig for target esp32 is not exist` | Build inside the isolated Docker container script environment |
| `Permission denied: .pio/build` | Adjust user permissions: `sudo chown -R $USER:$USER .pio/` |
| `invalid header` Boot-Loop | The flash space got corrupted. Run a full `erase_flash` over esptool before re-uploading the `.factory.bin` image |
| `SX126x init result -2` | Re-verify your physical layout matches the `variant.h`. Ensure **SCK is on GPIO 5** and **NSS is on GPIO 18** |
| BLE pairing failures / Drops | Android security parameters can drop low MTU values. Go to your system Bluetooth settings, pair manually with code `123456`, then initialize connection over the app |

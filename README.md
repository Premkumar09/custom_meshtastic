# Meshtastic Automation Toolset & Workspace Documentation

This comprehensive repository serves as a consolidated workspace for building, flashing, monitoring, and managing custom **Meshtastic** node deployments. It links your automation wrappers (`custom_meshtastic/`) directly with the underlying firmware code boundaries (`firmware/`).

---

## 🏗️ Workspace Architecture

To leverage these generalized scripts out of the box, map your local system workspace directory boundaries precisely to the structural diagram below:

```text
~/
├── git/
│   ├── firmware/             # The core Meshtastic firmware repository
│   │   ├── .pio/             # PlatformIO compilation targets (Host Git Ignored)
│   │   └── latest/           # Target destination directory populated by build.sh
│   │       ├── esp32-ideaspark-dxlr30/
│   │       │   └── latest.bin
│   │       └── diy-esp32-sx1262/
│   │           └── latest.bin
│   └── custom_meshtastic/    # Automation toolset container folder
│       ├── README.md         # This consolidated manual
│       ├── build.sh          # Isolated Dockerized compilation controller
│       ├── flash.sh          # Version-agnostic deployment utility
│       └── serial_connect.sh # Hardware-detecting diagnostic console line

```

---

## 🛠️ Hardware Profile: ESP32 WROOM-32 + DX-LR30 (SX1262)

The automation profiles target decoupled, customized DIY layouts. The system layout beneath utilizes the high-efficiency **Semtech SX1262** transceiver module (DX-LR30) paired with an **ESP32 WROOM-32** development layout.

### Technical Pin Layout Mapping

> ⚠️ **CRITICAL:** Always verify a tuned antenna structure is securely mounted to the RF interface line before powering on. Running an un-terminated radio frequency front-end will cause immediate, permanent destruction to the power amplifier silicon layer. Use 3.3V power rails exclusively; the module is not 5V tolerant.

| ESP32 Pin Identifier | DX-LR30 Target Line | Recommended Color | Architectural Responsibility |
| --- | --- | --- | --- |
| **3.3V** | VCC | Red | Main DC Supply Rail (3.3V Max) |
| **GND** | GND | Black | Shared Chassis Ground Reference |
| **GPIO 5** | SCK | Yellow | Hardware SPI Clock Reference Line |
| **GPIO 19** | MISO | Blue | Hardware Master-In Slave-Out Data Path |
| **GPIO 27** | MOSI | Green | Hardware Master-Out Slave-In Data Path |
| **GPIO 18** | NSS | Orange | Active-Low Radio Chip-Select Protocol (CS) |
| **GPIO 14** | RST | White | Hardware Reset Trigger Line |
| **GPIO 26** | DIO1 | Purple | Main Interrupt Service Request Line (IRQ) |
| **GPIO 32** | BUSY | Grey | **Mandatory** Hardware State Check Pin |

Unlike legacy SX1276 architectures, the modern SX1262 relies heavily on the **BUSY** status indicator flag (read synchronously prior to executing any SPI transaction) and routes internal events over **DIO1**. Leaving these lines disconnected causes total, silent firmware processing blocks.

---

## 🎛️ Automation Engine Scripts

### 1. Unified Compilation Manager (`build.sh`)

This workflow steps into your system directory, normalizes storage user permissions altered by prior container loops, wipes legacy artifacts cleanly, mounts execution directories via isolated Docker abstractions, and outputs target deployment images cleanly into specific `latest/` structures.

```bash
#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_ENV="esp32-ideaspark-dxlr30"
TARGET_ENV="${1:-$DEFAULT_ENV}"

# Paths
FIRMWARE_DIR="$HOME/git/firmware"
PIO_CACHE_DIR="/home/prem/.platformio/"
TARGET_LATEST_DIR="$FIRMWARE_DIR/latest/$TARGET_ENV"

# --- PRE-BUILD CLEANUP ---
echo "⚙️ Navigating to firmware directory..."
cd "$FIRMWARE_DIR" || { echo "❌ Directory not found!"; exit 1; }

echo "🔒 Resetting local permissions..."
sudo chown -R $USER:$USER .pio/

echo "🧹 Removing old build artifacts for [$TARGET_ENV]..."
rm -rf ".pio/build/$TARGET_ENV"

# --- DOCKER EXECUTION ---
echo "🐳 Running PlatformIO clean & build for [$TARGET_ENV] via Docker..."

# Deep cache clean using python's direct handler path inside container
docker run --rm \
  -v "${PIO_CACHE_DIR}:/root/.platformio/" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  infinitecoding/platformio-for-ci:latest \
  python3 -m platformio run -e "$TARGET_ENV" --target clean

# Main Build Command
docker run --rm -it \
  -v "${PIO_CACHE_DIR}:/root/.platformio/" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  infinitecoding/platformio-for-ci:latest \
  platformio run -e "$TARGET_ENV"

# --- POST-BUILD CLEANUP & COPY ---
echo "🔒 Restoring local permissions for generated files..."
sudo chown -R $USER:$USER .pio/

# Check if the build actually succeeded before copying
BUILD_DIR=".pio/build/$TARGET_ENV"
FIRMWARE_BIN=$(ls $BUILD_DIR/firmware-$TARGET_ENV-*.factory.bin 2>/dev/null | head -n 1)

if [ -n "$FIRMWARE_BIN" ]; then
    echo "📂 Creating target latest directory at $TARGET_LATEST_DIR..."
    mkdir -p "$TARGET_LATEST_DIR"

    echo "💾 Copying build artifact to latest directory..."
    cp "$FIRMWARE_BIN" "$TARGET_LATEST_DIR/latest.bin"
    echo "✨ Saved as: $TARGET_LATEST_DIR/latest.bin"
else
    echo "⚠️ Warning: No factory binary found. Build might have failed."
fi

echo "✅ Done!"

```

### 2. Version-Agnostic Flashing Tool (`flash.sh`)

Bypasses manual entry of variable version numbers (`*.factory.bin`) by referencing the standardized output structures maintained by the build pipeline.

```bash
#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_ENV="esp32-ideaspark-dxlr30"
TARGET_ENV="${1:-$DEFAULT_ENV}"
PORT="${2:-/dev/ttyUSB0}"
BAUD="921600"

# Points directly to the static 'latest.bin' handled by build.sh
FIRMWARE_BIN="$HOME/git/firmware/latest/$TARGET_ENV/latest.bin"

if [ ! -f "$FIRMWARE_BIN" ]; then
    echo "❌ Error: Binary not found at $FIRMWARE_BIN"
    echo "Please run: ./build.sh $TARGET_ENV first."
    exit 1
fi

echo "🔌 Target Environment: $TARGET_ENV"
echo "📡 Serial Port:        $PORT"
echo "🚀 Flashing $FIRMWARE_BIN..."

python -m esptool --port "$PORT" --baud "$BAUD" write_flash 0x0 "$FIRMWARE_BIN"

```

### 3. Dynamic Serial Interface Engine (`serial_connect.sh`)

Scans host device nodes programmatically for active serial ports, converts shorthand index inputs safely, and automatically defaults to the primary system diagnostic line.

```bash
#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_BAUD="115200"
BAUD="${2:-$DEFAULT_BAUD}"

# --- AUTO-DETECT ACTIVE PORTS ---
ACTIVE_PORTS=($(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null))

if [ ${#ACTIVE_PORTS[@]} -eq 0 ]; then
    echo "❌ Error: No active serial devices found (/dev/ttyUSB* or /dev/ttyACM*)."
    exit 1
fi

# --- DETERMINE TARGET PORT ---
if [ -n "$1" ]; then
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        TARGET_PORT="/dev/ttyUSB$1"
    else
        TARGET_PORT="$1"
    fi
else
    TARGET_PORT="${ACTIVE_PORTS[0]}"
    echo "🔌 Auto-detected active ports: ${ACTIVE_PORTS[*]}"
    echo "💡 Tip: You can pass a specific port or number, e.g.: $0 1"
fi

# --- CONNECT ---
echo "🚀 Connecting to $TARGET_PORT at $BAUD baud..."
echo "⌨️  Press Ctrl+] to exit miniterm."
echo "--------------------------------------------------"

python -m serial.tools.miniterm "$TARGET_PORT" "$BAUD"

```

---

## 🚀 Step-by-Step Execution Lifecycle

### Phase 1: Initialize Permissions

Authorize execution privileges inside your environment configuration repo folder:

```bash
cd ~/git/custom_meshtastic
chmod +x build.sh flash.sh serial_connect.sh

```

### Phase 2: Execution Syntax

| Operation Pipeline | Standard Default Method (`esp32-ideaspark-dxlr30`) | Alternative Explicit Targets (`diy-esp32-sx1262`) |
| --- | --- | --- |
| **1. Compile via Container** | `./build.sh` | `./build.sh diy-esp32-sx1262` |
| **2. Flash Hardware Core** | `./flash.sh` | `./flash.sh diy-esp32-sx1262` |
| **3. Interface Mapping Adjust** | *Auto-picks port* | `./flash.sh diy-esp32-sx1262 /dev/ttyUSB1` |
| **4. Diagnostic Monitoring** | `./serial_connect.sh` | `./serial_connect.sh 1` *(Shorthand maps to `/dev/ttyUSB1`)* |

> ⚠️ **CRITICAL USAGE NOTE:** Always execute the telemetry tool natively via standard Bash contexts (`./serial_connect.sh` or `bash serial_connect.sh`). **Do not use `sh serial_connect.sh**`. Primitive POSIX execution shells (like `dash`) lack native handling logic for vector arrays used to scan host controller pathways.

---

## 🔧 Internal Configuration Records (Firmware Core)

For tracking reference, the specific firmware structures implemented within your `firmware/` repository module are mapped as follows:

### 1. Variant Header Definition

Located inside the codebase tree at: `variants/dxlr30-wroom32/variant.h`

```cpp
#pragma once

#define PIN_SPI_SCK     5
#define PIN_SPI_MISO    19
#define PIN_SPI_MOSI    27

#define SX126X_CS       18   
#define SX126X_RESET    14
#define SX126X_DIO1     26
#define SX126X_BUSY     32   
#define SX126X_DIO2_AS_RF_SWITCH true

#define BUTTON_PIN      0    
#define LED_PIN         2    

#define I2C_SDA         21
#define I2C_SCL         22

```

### 2. PlatformIO Environment Block

Located inside the root configuration manifest at: `platformio.ini`

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

*Note: Due to file sizing optimizations, make sure `huge_app.csv` is mirrored into your local layout from your local `.platformio/packages/framework-arduinoespressif32/tools/partitions/` directory structure.*

```text
ESP32 WROOM-32                   DX-LR30 LoRa Module
+----------------+                +-------------------+
|    [3.3V]      | -------------> |     [ VCC ]       |  (3.3V Only!)
|    [GND]       | -------------> |     [ GND ]       |  (Common Ground)
|                |                |                   |
|  SCK  [GPIO  5]| -------------> |     [ SCK ]       |  (SPI Clock)
|  MISO [GPIO 19]| -------------> |     [ MISO]       |  (SPI Data Out from Radio)
|  MOSI [GPIO 27]| -------------> |     [ MOSI]       |  (SPI Data In to Radio)
|                |                |                   |
|  CS   [GPIO 18]| -------------> |     [ NSS ]       |  (Radio Chip Select)
|  RST  [GPIO 14]| -------------> |     [ RST ]       |  (Hardware Reset)
|  DIO1 [GPIO 26]| -------------> |     [ DIO1]       |  (IRQ Interrupt)
|  BUSY [GPIO 32]| -------------> |     [ BUSY]       |  (Mandatory Status Pin)
+----------------+                +-------------------+
```
---

## 🩺 Diagnostic Traces & Verification

Upon flashing, verify functionality by establishing serial monitoring hooks. The target node prints out system startup information following a quick pulse of the hardware **RST** switch:

```text
DEBUG | SPI.begin(SCK=5, MISO=19, MOSI=27, NSS=18)
DEBUG | SX126xInterface(cs=18, irq=26, rst=14, busy=32)
INFO  | Start meshradio init
INFO  | Radio freq=906.875, config.lora.frequency_offset=0.000
INFO  | Wanted region 1, using US
INFO  | SX126x init result 0
INFO  | SX1262 init success

```

### Bluetooth Provisioning

Connect your Meshtastic mobile application via the **Manual** node sync tab. Track your device’s distinct physical MAC address output in the boot traces and authenticate wireless pairing utilizing the baseline pin code pass:
🔑 **`123456`**

---

## 📋 Operational Troubleshooting Guide

| Symptom Matrix | Probable Root Factor | Corrective Resolution Matrix |
| --- | --- | --- |
| `Dynconfig for target... does not exist` | Host operating library divergence on modern systems | Run compilation through the isolated `infinitecoding/platformio-for-ci` container script |
| `Permission denied: .pio/build` | Host/Docker tracking ID boundaries overlapping | Clear path resource locks explicitly: `sudo chown -R $USER:$USER .pio/` |
| `invalid header` Boot-Looping | Local internal partitions corrupted or partially flashed | Issue a global storage wipe command via esptool before re-uploading: `python -m esptool --port /dev/ttyUSB0 erase_flash` |
| `SX126x init result -2` | Device communication link interrupted | Double-check pinouts. Ensure **SCK connects to GPIO 5** and **NSS connects to GPIO 18**. |
| Flash communication freezes midway | Strapping pin conflict or module line load | Disconnect **NSS (GPIO 18)** and **SCK (GPIO 5)** temporarily during the flashing routine, then reconnect before reboot. |

```


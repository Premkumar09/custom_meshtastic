#!/bin/bash

DEFAULT_ENV="esp32-ideaspark-dxlr30"
TARGET_ENV="${1:-$DEFAULT_ENV}"
PORT="${2:-/dev/ttyUSB0}"
BAUD="921600"

# Points directly to the static 'latest.bin' we just copied
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

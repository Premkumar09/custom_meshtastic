#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_ENV="esp32-ideaspark-dxlr30"
TARGET_ENV="${1:-$DEFAULT_ENV}"

# Paths
FIRMWARE_DIR="$HOME/git/firmware"
PIO_CACHE_DIR="/home/prem/.platformio/"
# This dynamic path evaluates to .../latest/esp32-ideaspark-dxlr30/ etc.
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

# Deep cache clean
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

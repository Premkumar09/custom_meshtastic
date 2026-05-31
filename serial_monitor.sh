#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_BAUD="115200"
BAUD="${2:-$DEFAULT_BAUD}"

# --- AUTO-DETECT ACTIVE PORTS ---
# Finds active USB/ACM serial ports on Linux
ACTIVE_PORTS=($(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null))

if [ ${#ACTIVE_PORTS[@]} -eq 0 ]; then
    echo "❌ Error: No active serial devices found (/dev/ttyUSB* or /dev/ttyACM*)."
    exit 1
fi

# --- DETERMINE TARGET PORT ---
if [ -n "$1" ]; then
    # If the user provided an argument (like /dev/ttyUSB1 or just '1')
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        TARGET_PORT="/dev/ttyUSB$1"
    else
        TARGET_PORT="$1"
    fi
else
    # Fallback: Auto-pick the first detected active port
    TARGET_PORT="${ACTIVE_PORTS[0]}"
    echo "🔌 Auto-detected active ports: ${ACTIVE_PORTS[*]}"
    echo "💡 Tip: You can pass a specific port or number, e.g.: $0 1"
fi

# --- CONNECT ---
echo "🚀 Connecting to $TARGET_PORT at $BAUD baud..."
echo "⌨️  Press Ctrl+] to exit miniterm."
echo "--------------------------------------------------"

python -m serial.tools.miniterm "$TARGET_PORT" "$BAUD"

#!/bin/bash

GODOT_APP_PATH="${1:-$HOME/Downloads/Godot.app}"

if [ ! -d "$GODOT_APP_PATH" ]; then
    echo "Godot.app not found at: $GODOT_APP_PATH"
    echo ""
    echo "Usage: ./run_godot.sh [path/to/Godot.app]"
    echo ""
    echo "Common locations:"
    echo "  ~/Downloads/Godot.app"
    echo "  /Applications/Godot.app"
    echo ""
    echo "If Godot is in a different location, provide the full path:"
    echo "  ./run_godot.sh /path/to/Godot.app"
    exit 1
fi

GODOT_BINARY="$GODOT_APP_PATH/Contents/MacOS/Godot"

if [ ! -f "$GODOT_BINARY" ]; then
    echo "Error: Godot executable not found at: $GODOT_BINARY"
    echo "Make sure you're pointing to the .app bundle, not the executable inside it."
    exit 1
fi

PROJECT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Godot from: $GODOT_BINARY"
echo "Project path: $PROJECT_PATH"
echo ""
echo "=== Godot Output (errors will appear below) ==="
echo ""

cd "$PROJECT_PATH"
"$GODOT_BINARY" --editor 2>&1

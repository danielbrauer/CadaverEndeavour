#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <audio_file> [output_dir]"
    exit 1
fi

AUDIO_FILE="$1"
SCRIPT_DIR="$(dirname "$0")"
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/resources"
OUTPUT_DIR="${2:-$DEFAULT_OUTPUT_DIR}"

if [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: Audio file not found: $AUDIO_FILE"
    exit 1
fi

AUDIO_DIR=$(dirname "$(realpath "$AUDIO_FILE")")
AUDIO_FILENAME=$(basename "$AUDIO_FILE")
AUDIO_BASENAME="${AUDIO_FILENAME%.*}"
OUTPUT_PATH=$(realpath "$OUTPUT_DIR")
CACHE_DIR="$SCRIPT_DIR/.whisper_cache"

mkdir -p "$OUTPUT_PATH"
mkdir -p "$CACHE_DIR"

echo "Transcribing $AUDIO_FILE..."
echo "Output directory: $OUTPUT_PATH"
echo "Output filename: ${AUDIO_BASENAME}.json"
echo "Model cache: $CACHE_DIR"

IMAGE_NAME="whisper-subtitle-tools"

if ! docker images --format "{{.Repository}}" | grep -q "^${IMAGE_NAME}$"; then
    echo "Building Docker image (first time only)..."
    docker build --platform linux/arm64 -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

docker run --rm --platform linux/arm64 \
    -v "$AUDIO_DIR:/input" \
    -v "$OUTPUT_PATH:/output" \
    -v "$CACHE_DIR:/root/.cache/whisper" \
    "$IMAGE_NAME" \
    "/input/$AUDIO_FILENAME" \
    --output_dir /output \
    --output_format json \
    --model base

if [ $? -eq 0 ]; then
    JSON_FILE="$OUTPUT_PATH/${AUDIO_BASENAME}.json"
    if [ -f "$JSON_FILE" ]; then
        echo "Transcription complete: $JSON_FILE"
        
        AUDIO_IN_RESOURCES="$OUTPUT_PATH/$AUDIO_FILENAME"
        if [ ! -f "$AUDIO_IN_RESOURCES" ] && [ "$AUDIO_DIR" != "$OUTPUT_PATH" ]; then
            echo "Copying audio file to resources directory..."
            cp "$AUDIO_FILE" "$AUDIO_IN_RESOURCES"
        fi
        
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
        
        REL_OUTPUT_DIR=$(python3 -c "import os; print(os.path.relpath('$OUTPUT_PATH', '$PROJECT_ROOT'))" 2>/dev/null)
        if [ -z "$REL_OUTPUT_DIR" ]; then
            REL_OUTPUT_DIR="${OUTPUT_PATH#${PROJECT_ROOT}/}"
        fi
        
        REL_AUDIO_FILE="res://$REL_OUTPUT_DIR/$AUDIO_FILENAME"
        REL_JSON_FILE="res://$REL_OUTPUT_DIR/${AUDIO_BASENAME}.json"
        REL_CONFIG_SCRIPT="res://subtitle_tools/subtitle_config.gd"
        
        AUDIO_EXT="${AUDIO_FILENAME##*.}"
        case "$AUDIO_EXT" in
            mp3) AUDIO_STREAM_TYPE="AudioStreamMP3" ;;
            wav) AUDIO_STREAM_TYPE="AudioStreamWAV" ;;
            ogg) AUDIO_STREAM_TYPE="AudioStreamOggVorbis" ;;
            *) AUDIO_STREAM_TYPE="AudioStream" ;;
        esac
        
        TRES_FILE="$OUTPUT_PATH/${AUDIO_BASENAME}.tres"
        cat > "$TRES_FILE" <<EOF
[gd_resource type="Resource" script_class="SubtitleConfig" load_steps=3 format=3]

[ext_resource type="Script" path="$REL_CONFIG_SCRIPT" id="1"]
[ext_resource type="$AUDIO_STREAM_TYPE" path="$REL_AUDIO_FILE" id="2"]

[resource]
script = ExtResource("1")
audio_stream = ExtResource("2")
transcription_path = "$REL_JSON_FILE"
EOF
        
        echo "Created resource file: $TRES_FILE"
    else
        echo "Warning: JSON file not found at expected location: $JSON_FILE"
        echo "Looking for alternative JSON files in output directory..."
        ls -la "$OUTPUT_PATH"/*.json 2>/dev/null || echo "No JSON files found"
    fi
else
    echo "Error: Transcription failed"
    exit 1
fi

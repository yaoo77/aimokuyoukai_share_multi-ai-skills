#!/usr/bin/env bash
# AI Rally Voice Generator
# Generate speech from AI debate outputs using ElevenLabs API
# Requires: ELEVENLABS_API_KEY environment variable, ffmpeg (for combining)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="/tmp/ai_rally_voices"

# Voice ID mapping - customize with your preferred ElevenLabs voices
get_voice_id() {
    local speaker="$1"
    case "$speaker" in
        Claude)   echo "${AI_ARENA_VOICE_CLAUDE:-XrExE9yKIg1WjnnlVkGX}" ;;   # Matilda
        Codex)    echo "${AI_ARENA_VOICE_CODEX:-nPczCjzI2devNBz1zQrb}" ;;    # Brian
        Gemini)   echo "${AI_ARENA_VOICE_GEMINI:-Xb7hH8MSUJpSbSDYk0k2}" ;;   # Alice
        GLM)      echo "${AI_ARENA_VOICE_GLM:-pqHfZKP75CvOlQylNhV4}" ;;      # Bill
        Narrator) echo "${AI_ARENA_VOICE_NARRATOR:-EHMH9cyd1z3rXm4z0Jja}" ;; # Yuma Uchida
        *)        echo "" ;;
    esac
}

MODEL_ID="${AI_ARENA_TTS_MODEL:-eleven_v3}"
STABILITY="0.5"
SIMILARITY_BOOST="0.8"

usage() {
    cat << EOF
AI Rally Voice Generator

Usage: $0 <command> [options]

Commands:
    generate <speaker> <text> [output.mp3]
        Generate speech for a single speaker
        Speakers: Claude, Codex, Gemini, GLM, Narrator

    from-file <input.txt> [output_dir]
        Generate from text file (format: [Speaker] text)

    from-capture [output_dir]
        Generate from live tmux capture

    combine <output.mp3> <input1.mp3> [input2.mp3 ...]
        Combine multiple audio files

    list-voices
        Show available voice assignments

Environment variables:
    ELEVENLABS_API_KEY       Required. Your ElevenLabs API key
    AI_ARENA_VOICE_CLAUDE    Voice ID for Claude (default: Matilda)
    AI_ARENA_VOICE_CODEX     Voice ID for Codex (default: Brian)
    AI_ARENA_VOICE_GEMINI    Voice ID for Gemini (default: Alice)
    AI_ARENA_VOICE_GLM       Voice ID for GLM (default: Bill)
    AI_ARENA_TTS_MODEL       TTS model (default: eleven_v3)
EOF
}

check_api_key() {
    if [[ -z "$ELEVENLABS_API_KEY" ]]; then
        echo "Error: ELEVENLABS_API_KEY is not set" >&2
        echo "Run: export ELEVENLABS_API_KEY='your-api-key'" >&2
        exit 1
    fi
}

generate_speech() {
    local speaker="$1"
    local text="$2"
    local output="$3"

    check_api_key

    local voice_id=$(get_voice_id "$speaker")
    if [[ -z "$voice_id" ]]; then
        echo "Error: Unknown speaker '$speaker'" >&2
        echo "Available: Claude, Codex, Gemini, GLM, Narrator" >&2
        exit 1
    fi

    local request_file="/tmp/elevenlabs_request_$$.json"
    cat > "$request_file" << EOF
{
  "text": "$text",
  "model_id": "$MODEL_ID",
  "voice_settings": {
    "stability": $STABILITY,
    "similarity_boost": $SIMILARITY_BOOST
  }
}
EOF

    echo "Generating voice for [$speaker]: ${text:0:50}..." >&2

    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$voice_id" \
        --header "xi-api-key: $ELEVENLABS_API_KEY" \
        --header "Content-Type: application/json" \
        --header "Accept: audio/mpeg" \
        -d @"$request_file" \
        --output "$output"

    rm -f "$request_file"

    if [[ -f "$output" ]] && [[ $(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null) -gt 1000 ]]; then
        echo "Generated: $output ($(du -h "$output" | cut -f1))" >&2
    else
        echo "Error: Failed to generate audio for [$speaker]" >&2
        return 1
    fi
}

from_capture() {
    local output_dir="${1:-$OUTPUT_DIR}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    output_dir="$output_dir/$timestamp"
    mkdir -p "$output_dir"

    if ! tmux has-session -t ai-rally 2>/dev/null; then
        echo "Error: ai-rally session not found" >&2
        exit 1
    fi

    echo "Capturing from ai-rally session..."

    local files=()
    for ai in codex claude gemini glm; do
        local pane
        case "$ai" in
            codex) pane=0 ;; claude) pane=1 ;; gemini) pane=2 ;; glm) pane=3 ;;
        esac
        local text=$(tmux capture-pane -t "ai-rally:0.$pane" -p -S -50 | tail -30 | grep -v "^$" | head -5)
        if [[ -n "$text" ]]; then
            local speaker=$(echo "$ai" | sed 's/^./\U&/')
            generate_speech "$speaker" "$text" "$output_dir/${ai}.mp3"
            files+=("$output_dir/${ai}.mp3")
        fi
    done

    if [[ ${#files[@]} -gt 1 ]]; then
        combine "$output_dir/combined.mp3" "${files[@]}"
    fi

    echo "Output: $output_dir"
}

combine() {
    local output="$1"
    shift
    local inputs=("$@")

    if [[ ${#inputs[@]} -lt 2 ]]; then
        echo "Error: Need at least 2 input files" >&2
        exit 1
    fi

    echo "Combining ${#inputs[@]} files..."

    local list_file="/tmp/ffmpeg_list_$$.txt"
    for f in "${inputs[@]}"; do
        echo "file '$f'" >> "$list_file"
    done

    if ffmpeg -y -f concat -safe 0 -i "$list_file" -c copy "$output" 2>/dev/null; then
        echo "Combined: $output ($(du -h "$output" | cut -f1))"
    else
        echo "Error: ffmpeg failed. Is ffmpeg installed?" >&2
    fi

    rm -f "$list_file"
}

list_voices() {
    echo "AI Arena Voice Assignments:"
    echo ""
    printf "%-12s %-20s %s\n" "Speaker" "Voice Name" "Voice ID"
    echo "---------------------------------------------------"
    printf "%-12s %-20s %s\n" "Claude" "Matilda" "$(get_voice_id Claude)"
    printf "%-12s %-20s %s\n" "Codex" "Brian" "$(get_voice_id Codex)"
    printf "%-12s %-20s %s\n" "Gemini" "Alice" "$(get_voice_id Gemini)"
    printf "%-12s %-20s %s\n" "GLM" "Bill" "$(get_voice_id GLM)"
    printf "%-12s %-20s %s\n" "Narrator" "Yuma Uchida" "$(get_voice_id Narrator)"
    echo ""
    echo "Model: $MODEL_ID"
    echo "Override with: AI_ARENA_VOICE_<SPEAKER>=<voice_id>"
}

case "${1:-}" in
    generate)
        [[ $# -lt 3 ]] && { usage; exit 1; }
        output="${4:-/tmp/$(echo "$2" | tr '[:upper:]' '[:lower:]')_$(date +%s).mp3}"
        generate_speech "$2" "$3" "$output"
        ;;
    from-file)
        [[ $# -lt 2 ]] && { usage; exit 1; }
        from_file "$2" "${3:-}"
        ;;
    from-capture)
        from_capture "${2:-}"
        ;;
    combine)
        [[ $# -lt 3 ]] && { usage; exit 1; }
        combine "${@:2}"
        ;;
    list-voices)
        list_voices
        ;;
    *)
        usage
        ;;
esac

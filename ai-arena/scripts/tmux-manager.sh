#!/bin/bash
# AI Rally - Multi-AI tmux session manager
# Manages 4 AI CLIs in a 2x2 tmux grid layout
#
# Layout:
# ┌─────────┬─────────┐
# │  Codex  │ Claude  │
# │ (Pane 0)│(Pane 1) │
# ├─────────┼─────────┤
# │ Gemini  │   GLM   │
# │ (Pane 2)│(Pane 3) │
# └─────────┴─────────┘

SESSION="ai-rally"
CODEX_PANE=0
CLAUDE_PANE=1
GEMINI_PANE=2
GLM_PANE=3
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# === CLI Commands ===
# Customize these to match your local CLI aliases/commands
CODEX_CMD="${AI_ARENA_CODEX_CMD:-codex}"
CLAUDE_CMD="${AI_ARENA_CLAUDE_CMD:-claude}"
GEMINI_CMD="${AI_ARENA_GEMINI_CMD:-gemini}"
GLM_CMD="${AI_ARENA_GLM_CMD:-glm}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[ai-rally]${NC} $1"; }
print_error() { echo -e "${RED}[ai-rally ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[ai-rally]${NC} $1"; }

session_exists() { tmux has-session -t "$SESSION" 2>/dev/null; }

# === Clipboard-based send (CJK-safe) ===
clipboard_send() {
    local pane="$1"
    local message="$2"

    if command -v pbcopy &>/dev/null; then
        echo "$message" | pbcopy
        tmux send-keys -t "$pane" "$(pbpaste)" C-m
    elif command -v xclip &>/dev/null; then
        echo "$message" | xclip -selection clipboard
        tmux send-keys -t "$pane" "$(xclip -selection clipboard -o)" C-m
    else
        tmux send-keys -t "$pane" "$message" C-m
    fi
}

# === START ===
cmd_start() {
    if session_exists; then
        print_error "Session already exists. Use 'stop' first or 'status' to check."
        return 1
    fi

    print_status "Creating tmux session (2x2 grid layout)..."

    tmux new-session -d -s "$SESSION" -c "$(pwd)"
    tmux split-window -h -t "$SESSION"
    tmux split-window -v -t "$SESSION:0.0"
    tmux split-window -v -t "$SESSION:0.2"
    tmux select-layout -t "$SESSION" tiled

    # Unset CLAUDECODE to allow nested Claude Code sessions
    for p in $CODEX_PANE $CLAUDE_PANE $GEMINI_PANE $GLM_PANE; do
        tmux send-keys -t "$SESSION:0.$p" 'unset CLAUDECODE' Enter
    done
    sleep 1

    print_status "Starting Codex in pane 0..."
    tmux send-keys -t "$SESSION:0.$CODEX_PANE" "$CODEX_CMD" Enter

    print_status "Starting Claude in pane 1..."
    tmux send-keys -t "$SESSION:0.$CLAUDE_PANE" "$CLAUDE_CMD" Enter

    print_status "Starting Gemini in pane 2..."
    tmux send-keys -t "$SESSION:0.$GEMINI_PANE" "$GEMINI_CMD" Enter

    print_status "Starting GLM in pane 3..."
    tmux send-keys -t "$SESSION:0.$GLM_PANE" "$GLM_CMD" Enter

    sleep 5

    # Skip update notifications if present (Codex/Gemini sometimes prompt)
    tmux send-keys -t "$SESSION:0.$CODEX_PANE" '2' Enter 2>/dev/null
    tmux send-keys -t "$SESSION:0.$GEMINI_PANE" '2' Enter 2>/dev/null
    sleep 3

    print_status "Session started! All 4 AIs are ready."
    print_info "Use 'view' to open a terminal window, or 'tmux attach -t $SESSION'"
    print_info "Layout: 2x2 grid (Codex|Claude / Gemini|GLM)"
}

# === STOP ===
cmd_stop() {
    if ! session_exists; then
        print_error "No session found."
        return 1
    fi

    for p in $CODEX_PANE $CLAUDE_PANE $GEMINI_PANE $GLM_PANE; do
        tmux send-keys -t "$SESSION:0.$p" '/exit' Enter 2>/dev/null
    done
    sleep 2

    tmux kill-session -t "$SESSION" 2>/dev/null
    print_status "Session stopped."
}

# === VIEW ===
cmd_view() {
    if ! session_exists; then
        print_error "No session found. Use 'start' first."
        return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "tell application \"Terminal\" to do script \"tmux attach -t $SESSION\""
        print_status "Opened Terminal window with session view."
    else
        print_info "Run: tmux attach -t $SESSION"
    fi
}

# === STATUS ===
cmd_status() {
    if session_exists; then
        print_status "Session is running."
        tmux list-panes -t "$SESSION" -F "Pane #{pane_index}: #{pane_current_command}"
    else
        print_info "No session running."
    fi
}

# === SEND ===
cmd_send() {
    local target="$1"
    local message="$2"

    if ! session_exists; then
        print_error "No session found. Use 'start' first."
        return 1
    fi

    if [ -z "$message" ]; then
        print_error "Usage: send <codex|gemini|claude|glm> <message>"
        return 1
    fi

    local pane
    case "$target" in
        codex)  pane=$CODEX_PANE ;;
        gemini) pane=$GEMINI_PANE ;;
        claude) pane=$CLAUDE_PANE ;;
        glm)    pane=$GLM_PANE ;;
        *)
            print_error "Unknown target: $target. Use 'codex', 'gemini', 'claude', or 'glm'."
            return 1
            ;;
    esac

    clipboard_send "$SESSION:0.$pane" "$message"
    print_status "Sent to $target."
}

# === BROADCAST ===
cmd_broadcast() {
    local message="$1"

    if ! session_exists; then
        print_error "No session found. Use 'start' first."
        return 1
    fi

    if [ -z "$message" ]; then
        print_error "Usage: broadcast <message>"
        return 1
    fi

    print_status "Broadcasting to all 4 AIs..."

    # Send to all 4 panes
    for pane in $CODEX_PANE $CLAUDE_PANE $GEMINI_PANE $GLM_PANE; do
        clipboard_send "$SESSION:0.$pane" "$message" &
    done
    wait

    # Retry Enter if prompt is still showing (handles slow CLIs)
    for attempt in 1 2 3; do
        sleep 3
        local need_retry=0

        for pane in $CODEX_PANE $CLAUDE_PANE $GEMINI_PANE $GLM_PANE; do
            local cur=$(tmux capture-pane -t "$SESSION:0.$pane" -p -S -3 2>/dev/null)
            if echo "$cur" | grep -qE "^(>|\\$)"; then
                local name
                case "$pane" in
                    0) name="Codex" ;; 1) name="Claude" ;; 2) name="Gemini" ;; 3) name="GLM" ;;
                esac
                print_info "$name: retry Enter (attempt $attempt)..."
                tmux send-keys -t "$SESSION:0.$pane" C-m
                need_retry=1
            fi
        done

        [ "$need_retry" -eq 0 ] && break
    done

    print_status "Broadcast sent to all 4 AIs."
}

# === CAPTURE ===
cmd_capture() {
    local target="$1"
    local lines="${2:-100}"

    if ! session_exists; then
        print_error "No session found."
        return 1
    fi

    local pane
    case "$target" in
        codex)  pane=$CODEX_PANE ;;
        gemini) pane=$GEMINI_PANE ;;
        claude) pane=$CLAUDE_PANE ;;
        glm)    pane=$GLM_PANE ;;
        *)
            print_error "Unknown target: $target"
            return 1
            ;;
    esac

    echo -e "${YELLOW}=== [$target] Output ===${NC}"
    tmux capture-pane -t "$SESSION:0.$pane" -p -S -"$lines"
}

# === CAPTURE ALL ===
cmd_capture_all() {
    local lines="${1:-100}"

    if ! session_exists; then
        print_error "No session found."
        return 1
    fi

    for target in codex claude gemini glm; do
        local pane
        case "$target" in
            codex) pane=$CODEX_PANE ;; claude) pane=$CLAUDE_PANE ;;
            gemini) pane=$GEMINI_PANE ;; glm) pane=$GLM_PANE ;;
        esac
        echo -e "${YELLOW}=== [$(echo $target | sed 's/^./\U&/')] Output ===${NC}"
        tmux capture-pane -t "$SESSION:0.$pane" -p -S -"$lines"
        echo ""
    done
}

# === RALLY ===
cmd_rally() {
    local topic="$1"
    local rounds="${2:-3}"

    if ! session_exists; then
        print_error "No session found. Use 'start' first."
        return 1
    fi

    if [ -z "$topic" ]; then
        print_error "Usage: rally <topic> [rounds]"
        return 1
    fi

    print_status "Starting $rounds-round rally on: $topic"
    cmd_broadcast "$topic"

    for round in $(seq 1 $rounds); do
        print_status "Round $round/$rounds"
        print_info "Waiting for responses..."
        sleep 20

        if [ $round -lt $rounds ]; then
            print_info "Cross-sharing responses..."

            local codex_output=$(tmux capture-pane -t "$SESSION:0.$CODEX_PANE" -p -S -50 | tail -10 | head -5)
            local gemini_output=$(tmux capture-pane -t "$SESSION:0.$GEMINI_PANE" -p -S -50 | tail -10 | head -5)

            clipboard_send "$SESSION:0.$CODEX_PANE" "Gemini said: \"$gemini_output\" What do you think?"
            sleep 1
            clipboard_send "$SESSION:0.$GEMINI_PANE" "Codex said: \"$codex_output\" What do you think?"
        fi
    done

    print_status "Rally completed! Use 'capture-all' to see final outputs."
}

# === VOICE GEN (delegate) ===
cmd_voice_gen() {
    local voice_script="$SCRIPT_DIR/voice-gen.sh"
    if [ -f "$voice_script" ]; then
        "$voice_script" from-capture "$1"
    else
        print_error "voice-gen.sh not found."
    fi
}

# === MAIN ===
case "$1" in
    start)       cmd_start ;;
    stop)        cmd_stop ;;
    view)        cmd_view ;;
    status)      cmd_status ;;
    send)        cmd_send "$2" "$3" ;;
    broadcast)   shift; cmd_broadcast "$*" ;;
    capture)     cmd_capture "$2" "$3" ;;
    capture-all) cmd_capture_all "$2" ;;
    rally)       cmd_rally "$2" "$3" ;;
    voice-gen)   cmd_voice_gen "$2" ;;
    *)
        echo "AI Rally - Multi-AI tmux session manager"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  start              Start 2x2 grid: Codex + Claude + Gemini + GLM"
        echo "  stop               Stop session"
        echo "  view               Open Terminal window to watch session"
        echo "  status             Check session status"
        echo "  send <ai> <msg>    Send to: codex, gemini, claude, glm"
        echo "  broadcast <msg>    Send to all 4 AIs"
        echo "  capture <ai>       Capture output from one AI"
        echo "  capture-all        Capture output from all 4 AIs"
        echo "  rally <topic> [n]  n-round rally with cross-pollination (default: 3)"
        echo "  voice-gen [dir]    Generate voice from outputs (requires ElevenLabs)"
        echo ""
        echo "Layout:"
        echo "  ┌─────────┬─────────┐"
        echo "  │  Codex  │ Claude  │"
        echo "  │ (Pane 0)│(Pane 1) │"
        echo "  ├─────────┼─────────┤"
        echo "  │ Gemini  │   GLM   │"
        echo "  │ (Pane 2)│(Pane 3) │"
        echo "  └─────────┴─────────┘"
        echo ""
        echo "Environment variables for custom CLI commands:"
        echo "  AI_ARENA_CODEX_CMD   (default: codex)"
        echo "  AI_ARENA_CLAUDE_CMD  (default: claude)"
        echo "  AI_ARENA_GEMINI_CMD  (default: gemini)"
        echo "  AI_ARENA_GLM_CMD     (default: glm)"
        ;;
esac

#!/bin/bash
# AI Rally - Multi-AI tmux session manager
# Multi-AI tmux session manager

SESSION="ai-rally"
CODEX_PANE=0
GEMINI_PANE=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper: Print with color
print_status() {
    echo -e "${GREEN}[ai-rally]${NC} $1"
}

print_error() {
    echo -e "${RED}[ai-rally ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ai-rally]${NC} $1"
}

# Check if session exists
session_exists() {
    tmux has-session -t "$SESSION" 2>/dev/null
}

# Wait for output to stabilize
wait_for_output() {
    local pane="$1"
    local max_polls="${2:-20}"
    local interval="${3:-3}"
    local prev_output=""

    for i in $(seq 1 $max_polls); do
        current=$(tmux capture-pane -t "$SESSION:0.$pane" -p -S -100 2>/dev/null)
        if [ "$current" = "$prev_output" ] && [ -n "$current" ]; then
            return 0
        fi
        prev_output="$current"
        sleep $interval
    done
    return 1
}

# Start session with Codex and Gemini
cmd_start() {
    if session_exists; then
        print_error "Session already exists. Use 'stop' first or 'status' to check."
        return 1
    fi

    print_status "Creating tmux session..."

    # Create session with first pane (Codex)
    tmux new-session -d -s "$SESSION" -c "$(pwd)"

    # Split horizontally for Gemini
    tmux split-window -h -t "$SESSION:0"

    # Start Codex in pane 0
    print_status "Starting Codex in pane 0..."
    tmux send-keys -t "$SESSION:0.$CODEX_PANE" 'codex' Enter

    # Start Gemini in pane 1
    print_status "Starting Gemini in pane 1..."
    tmux send-keys -t "$SESSION:0.$GEMINI_PANE" 'gemini' Enter

    # Wait for startup
    sleep 5

    # Skip update notifications if present
    tmux send-keys -t "$SESSION:0.$CODEX_PANE" '2' Enter 2>/dev/null
    tmux send-keys -t "$SESSION:0.$GEMINI_PANE" '2' Enter 2>/dev/null

    sleep 3

    print_status "Session started! Both AIs are ready."
    print_info "Use 'view' to open a terminal window, or 'tmux attach -t $SESSION'"
}

# Stop session
cmd_stop() {
    if ! session_exists; then
        print_error "No session found."
        return 1
    fi

    # Send exit to both
    tmux send-keys -t "$SESSION:0.$CODEX_PANE" '/exit' Enter 2>/dev/null
    tmux send-keys -t "$SESSION:0.$GEMINI_PANE" '/exit' Enter 2>/dev/null
    sleep 2

    tmux kill-session -t "$SESSION" 2>/dev/null
    print_status "Session stopped."
}

# Open view window for user
cmd_view() {
    if ! session_exists; then
        print_error "No session found. Use 'start' first."
        return 1
    fi

    # macOS: open new Terminal window with tmux attach
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "tell application \"Terminal\" to do script \"echo 'AI Rally Session' && tmux attach -t $SESSION\""
        print_status "Opened Terminal window with session view."
    else
        print_info "Run: tmux attach -t $SESSION"
    fi
}

# Check status
cmd_status() {
    if session_exists; then
        print_status "Session is running."
        tmux list-panes -t "$SESSION" -F "Pane #{pane_index}: #{pane_current_command}"
    else
        print_info "No session running."
    fi
}

# Send message to specific AI
cmd_send() {
    local target="$1"
    local message="$2"

    if ! session_exists; then
        print_error "No session found. Use 'start' first."
        return 1
    fi

    if [ -z "$message" ]; then
        print_error "Usage: send <codex|gemini> <message>"
        return 1
    fi

    local pane
    case "$target" in
        codex) pane=$CODEX_PANE ;;
        gemini) pane=$GEMINI_PANE ;;
        *)
            print_error "Unknown target: $target. Use 'codex' or 'gemini'."
            return 1
            ;;
    esac

    # Use pbcopy for Japanese text support
    echo "$message" | pbcopy
    tmux send-keys -t "$SESSION:0.$pane" "$(pbpaste)" Enter
    sleep 1
    tmux send-keys -t "$SESSION:0.$pane" Enter  # Confirm

    print_status "Sent to $target: $message"
}

# Broadcast message to both AIs
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

    print_status "Broadcasting to both AIs..."

    # Use pbcopy for Japanese text support
    echo "$message" | pbcopy

    # Send to Codex
    tmux send-keys -t "$SESSION:0.$CODEX_PANE" "$(pbpaste)" Enter
    sleep 1
    tmux send-keys -t "$SESSION:0.$CODEX_PANE" Enter

    # Send to Gemini
    tmux send-keys -t "$SESSION:0.$GEMINI_PANE" "$(pbpaste)" Enter
    sleep 1
    tmux send-keys -t "$SESSION:0.$GEMINI_PANE" Enter

    print_status "Broadcast sent to both AIs."
}

# Capture output from specific AI
cmd_capture() {
    local target="$1"
    local lines="${2:-100}"

    if ! session_exists; then
        print_error "No session found."
        return 1
    fi

    local pane
    case "$target" in
        codex) pane=$CODEX_PANE ;;
        gemini) pane=$GEMINI_PANE ;;
        *)
            print_error "Unknown target: $target. Use 'codex' or 'gemini'."
            return 1
            ;;
    esac

    echo -e "${YELLOW}=== [$target] Output ===${NC}"
    tmux capture-pane -t "$SESSION:0.$pane" -p -S -"$lines"
}

# Capture output from both AIs
cmd_capture_all() {
    local lines="${1:-100}"

    if ! session_exists; then
        print_error "No session found."
        return 1
    fi

    echo -e "${YELLOW}=== [Codex] Output ===${NC}"
    tmux capture-pane -t "$SESSION:0.$CODEX_PANE" -p -S -"$lines"
    echo ""
    echo -e "${YELLOW}=== [Gemini] Output ===${NC}"
    tmux capture-pane -t "$SESSION:0.$GEMINI_PANE" -p -S -"$lines"
}

# Round-robin rally
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

    # Initial broadcast
    cmd_broadcast "$topic"

    for round in $(seq 1 $rounds); do
        print_status "Round $round/$rounds"

        # Wait for both to respond
        print_info "Waiting for responses..."
        sleep 20

        # Capture both outputs
        codex_output=$(tmux capture-pane -t "$SESSION:0.$CODEX_PANE" -p -S -50 | tail -30)
        gemini_output=$(tmux capture-pane -t "$SESSION:0.$GEMINI_PANE" -p -S -50 | tail -30)

        # Share outputs with each other (simplified cross-pollination)
        if [ $round -lt $rounds ]; then
            print_info "Cross-sharing responses..."

            # Send Gemini's view to Codex
            echo "Geminiの意見: 「$(echo "$gemini_output" | tail -10 | head -5)」 これについてどう思う？" | pbcopy
            tmux send-keys -t "$SESSION:0.$CODEX_PANE" "$(pbpaste)" Enter
            sleep 1
            tmux send-keys -t "$SESSION:0.$CODEX_PANE" Enter

            # Send Codex's view to Gemini
            echo "Codexの意見: 「$(echo "$codex_output" | tail -10 | head -5)」 これについてどう思う？" | pbcopy
            tmux send-keys -t "$SESSION:0.$GEMINI_PANE" "$(pbpaste)" Enter
            sleep 1
            tmux send-keys -t "$SESSION:0.$GEMINI_PANE" Enter
        fi
    done

    print_status "Rally completed! Use 'capture-all' to see final outputs."
}

# Main command dispatcher
case "$1" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    view)
        cmd_view
        ;;
    status)
        cmd_status
        ;;
    send)
        cmd_send "$2" "$3"
        ;;
    broadcast)
        shift
        cmd_broadcast "$*"
        ;;
    capture)
        cmd_capture "$2" "$3"
        ;;
    capture-all)
        cmd_capture_all "$2"
        ;;
    rally)
        cmd_rally "$2" "$3"
        ;;
    *)
        echo "AI Rally - Multi-AI tmux session manager"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  start              Start session with Codex + Gemini"
        echo "  stop               Stop session"
        echo "  view               Open Terminal window to view session"
        echo "  status             Check session status"
        echo "  send <ai> <msg>    Send message to codex or gemini"
        echo "  broadcast <msg>    Send message to both AIs"
        echo "  capture <ai>       Capture output from codex or gemini"
        echo "  capture-all        Capture output from both AIs"
        echo "  rally <topic> [n]  Run n-round rally (default: 3)"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 broadcast 'このリポジトリについて教えて'"
        echo "  $0 rally '最適なAI分担' 5"
        echo "  $0 capture-all"
        echo "  $0 stop"
        ;;
esac

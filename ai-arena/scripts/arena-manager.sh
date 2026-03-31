#!/bin/bash
# AI Arena - Unified orchestrator for ai-rally + Claude Agent Teams
# Send the same question to multiple AI CLIs and compare responses side-by-side
#
# Supported AIs: Codex, Claude Code, Gemini CLI, GLM (via tmux)
# Optional: Claude Code Agent Teams for multi-perspective analysis

RALLY_SESSION="ai-rally"
TEAM_SESSION="claude-team"
TEAM_LEADER_PANE="$TEAM_SESSION:0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RALLY_SCRIPT="$SCRIPT_DIR/tmux-manager.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[ai-arena]${NC} $1"; }
print_error() { echo -e "${RED}[ai-arena ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[ai-arena]${NC} $1"; }

rally_exists() { tmux has-session -t "$RALLY_SESSION" 2>/dev/null; }
team_exists() { tmux has-session -t "$TEAM_SESSION" 2>/dev/null; }

# === START ===
cmd_start() {
    local mode="${1:-rally}"  # rally | full | team

    print_status "AI Arena starting... (mode: $mode)"

    # 1. Start ai-rally (Codex/Claude/Gemini/GLM)
    if [ "$mode" != "team" ]; then
        if rally_exists; then
            print_info "ai-rally already running."
        else
            print_status "Starting ai-rally (Codex/Claude/Gemini/GLM)..."
            "$RALLY_SCRIPT" start
            sleep 8
        fi
    fi

    # 2. Start claude-team (Agent Teams leader) - only in full mode
    if [ "$mode" = "full" ]; then
        if team_exists; then
            print_info "claude-team already running."
        else
            print_status "Starting claude-team (Agent Teams leader)..."
            tmux new-session -d -s "$TEAM_SESSION" -c "$(pwd)"
            tmux send-keys -t "$TEAM_LEADER_PANE" 'unset CLAUDECODE' Enter
            sleep 1
            # Start Claude Code in the team pane
            # Customize this command if your Claude Code alias differs
            tmux send-keys -t "$TEAM_LEADER_PANE" 'claude' Enter
            sleep 8

            # Initial instruction for Agent Teams leader
            print_status "Setting up leader with Agent Teams instruction..."
            local init_msg="You are the AI Arena leader. When you receive a topic, launch 3 sub-agents via Agent Teams with different perspectives: (1) Business/Strategy (2) Technical/Implementation (3) Quality/Reliability. Compile their responses into a comparison table. Acknowledge with 'Ready'."
            clipboard_send "$TEAM_LEADER_PANE" "$init_msg"
            sleep 5
        fi
    fi

    print_status "AI Arena ready!"
    cmd_status
}

# === STOP ===
cmd_stop() {
    print_status "Stopping AI Arena..."

    if rally_exists; then
        "$RALLY_SCRIPT" stop
        print_status "ai-rally stopped."
    fi

    if team_exists; then
        tmux send-keys -t "$TEAM_LEADER_PANE" '/exit' Enter 2>/dev/null
        sleep 2
        tmux kill-session -t "$TEAM_SESSION" 2>/dev/null
        print_status "claude-team stopped."
    fi

    print_status "AI Arena shut down."
}

# === STATUS ===
cmd_status() {
    echo -e "${CYAN}=== AI Arena Status ===${NC}"
    echo ""

    if rally_exists; then
        echo -e "${GREEN}[ai-rally]${NC} RUNNING"
        tmux list-panes -t "$RALLY_SESSION" -F "  Pane #{pane_index}: #{pane_current_command} (#{pane_width}x#{pane_height})" 2>/dev/null
    else
        echo -e "${RED}[ai-rally]${NC} NOT RUNNING"
    fi

    echo ""

    if team_exists; then
        echo -e "${GREEN}[claude-team]${NC} RUNNING"
        tmux list-panes -t "$TEAM_SESSION" -F "  Pane #{pane_index}: #{pane_title} (#{pane_width}x#{pane_height})" 2>/dev/null
    else
        echo -e "${RED}[claude-team]${NC} NOT RUNNING"
    fi
}

# === Clipboard-based send (supports CJK text) ===
clipboard_send() {
    local pane="$1"
    local message="$2"

    if command -v pbcopy &>/dev/null; then
        # macOS
        echo "$message" | pbcopy
        tmux send-keys -t "$pane" "$(pbpaste)" C-m
    elif command -v xclip &>/dev/null; then
        # Linux with xclip
        echo "$message" | xclip -selection clipboard
        tmux send-keys -t "$pane" "$(xclip -selection clipboard -o)" C-m
    else
        # Fallback: direct send (may break CJK)
        tmux send-keys -t "$pane" "$message" C-m
    fi
}

# === Send with retry helper ===
send_with_retry() {
    local pane="$1"
    local message="$2"
    local name="$3"

    clipboard_send "$pane" "$message"

    for attempt in 1 2 3; do
        sleep 3
        local current=$(tmux capture-pane -t "$pane" -p -S -3 2>/dev/null)
        if echo "$current" | grep -qE "^(>|\\$)"; then
            print_info "$name: retry Enter (attempt $attempt)..."
            tmux send-keys -t "$pane" C-m
        else
            return 0
        fi
    done
}

# === BROADCAST ===
cmd_broadcast() {
    local message="$1"

    if [ -z "$message" ]; then
        print_error "Usage: broadcast <message>"
        return 1
    fi

    local sent=0

    # Send to ai-rally (all 4 AIs)
    if rally_exists; then
        print_status "Broadcasting to ai-rally (4 AIs)..."
        "$RALLY_SCRIPT" broadcast "$message"
        sent=$((sent + 4))
    else
        print_info "ai-rally not running, skipping."
    fi

    # Send to claude-team leader
    if team_exists; then
        print_status "Sending to claude-team leader..."
        local team_msg="Discuss this topic using your 3 sub-agents (Business, Technical, Quality). Topic: $message"
        send_with_retry "$TEAM_LEADER_PANE" "$team_msg" "Leader"
        sent=$((sent + 1))
    fi

    print_status "Broadcast sent to $sent targets."
}

# === CAPTURE ALL ===
cmd_capture_all() {
    local lines="${1:-80}"

    echo -e "${CYAN}=== AI Arena - All Responses ===${NC}"
    echo ""

    if rally_exists; then
        echo -e "${YELLOW}--- [Codex] ---${NC}"
        tmux capture-pane -t "$RALLY_SESSION:0.0" -p -S -"$lines" | tail -40
        echo ""
        echo -e "${YELLOW}--- [Claude (Rally)] ---${NC}"
        tmux capture-pane -t "$RALLY_SESSION:0.1" -p -S -"$lines" | tail -40
        echo ""
        echo -e "${YELLOW}--- [Gemini] ---${NC}"
        tmux capture-pane -t "$RALLY_SESSION:0.2" -p -S -"$lines" | tail -40
        echo ""
        echo -e "${YELLOW}--- [GLM] ---${NC}"
        tmux capture-pane -t "$RALLY_SESSION:0.3" -p -S -"$lines" | tail -40
        echo ""
    fi

    if team_exists; then
        echo -e "${YELLOW}--- [Agent Team Leader] ---${NC}"
        tmux capture-pane -t "$TEAM_LEADER_PANE" -p -S -"$lines" | tail -60
        echo ""
    fi
}

# === SEND to specific target ===
cmd_send() {
    local target="$1"
    local message="$2"

    if [ -z "$message" ]; then
        print_error "Usage: send <codex|gemini|claude|glm|leader> <message>"
        return 1
    fi

    case "$target" in
        leader|team)
            if ! team_exists; then
                print_error "claude-team not running."
                return 1
            fi
            clipboard_send "$TEAM_LEADER_PANE" "$message"
            print_status "Sent to Agent Team leader."
            ;;
        codex|gemini|claude|glm)
            if ! rally_exists; then
                print_error "ai-rally not running."
                return 1
            fi
            "$RALLY_SCRIPT" send "$target" "$message"
            ;;
        *)
            print_error "Unknown target: $target"
            print_info "Targets: codex, gemini, claude, glm, leader"
            return 1
            ;;
    esac
}

# === CROSS (cross-pollination between AIs) ===
cmd_cross() {
    if ! rally_exists; then
        print_error "ai-rally not running."
        return 1
    fi

    print_status "Capturing ai-rally responses for cross-sharing..."

    local codex_sum=$(tmux capture-pane -t "$RALLY_SESSION:0.0" -p -S -40 | grep -v "^$" | tail -8 | head -5)
    local claude_sum=$(tmux capture-pane -t "$RALLY_SESSION:0.1" -p -S -40 | grep -v "^$" | tail -8 | head -5)
    local gemini_sum=$(tmux capture-pane -t "$RALLY_SESSION:0.2" -p -S -40 | grep -v "^$" | tail -8 | head -5)
    local glm_sum=$(tmux capture-pane -t "$RALLY_SESSION:0.3" -p -S -40 | grep -v "^$" | tail -8 | head -5)

    # Cross-share: Codex<-Claude, Claude<-GLM, Gemini<-Codex, GLM<-Gemini
    print_status "Cross-sharing: Codex <- Claude..."
    send_with_retry "$RALLY_SESSION:0.0" \
        "Claude said: \"${claude_sum}\". What do you think? Agree, disagree, or add to it." "Codex"

    print_status "Cross-sharing: Claude <- GLM..."
    send_with_retry "$RALLY_SESSION:0.1" \
        "GLM said: \"${glm_sum}\". What do you think? Agree, disagree, or add to it." "Claude"

    print_status "Cross-sharing: Gemini <- Codex..."
    send_with_retry "$RALLY_SESSION:0.2" \
        "Codex said: \"${codex_sum}\". What do you think? Agree, disagree, or add to it." "Gemini"

    print_status "Cross-sharing: GLM <- Gemini..."
    send_with_retry "$RALLY_SESSION:0.3" \
        "Gemini said: \"${gemini_sum}\". What do you think? Agree, disagree, or add to it." "GLM"

    print_status "Cross-share sent! Use 'capture-all' to see results."
}

# === RALLY (multi-round with cross-pollination) ===
cmd_rally() {
    local topic="$1"
    local rounds="${2:-3}"

    if [ -z "$topic" ]; then
        print_error "Usage: rally <topic> [rounds]"
        return 1
    fi

    print_status "Starting $rounds-round Arena Rally on: $topic"
    cmd_broadcast "$topic"

    for round in $(seq 1 $rounds); do
        print_status "=== Round $round/$rounds ==="
        print_info "Waiting for responses (30s)..."
        sleep 30

        if [ "$round" -lt "$rounds" ]; then
            print_info "Cross-sharing responses..."

            if team_exists && rally_exists; then
                local team_summary=$(tmux capture-pane -t "$TEAM_LEADER_PANE" -p -S -30 | tail -10 | head -5)
                "$RALLY_SCRIPT" broadcast "Agent Team opinion: $team_summary What do you think?"
            fi

            if rally_exists && team_exists; then
                local codex_summary=$(tmux capture-pane -t "$RALLY_SESSION:0.0" -p -S -30 | tail -10 | head -5)
                clipboard_send "$TEAM_LEADER_PANE" "Codex opinion: $codex_summary Discuss this with your team."
            fi
        fi
    done

    print_status "Arena Rally completed! Use 'capture-all' to see results."
}

# === DEBATE (deep discussion mode) ===
cmd_debate() {
    local topic="$1"
    local rounds="${2:-2}"

    if [ -z "$topic" ]; then
        print_error "Usage: debate <topic> [rounds]"
        return 1
    fi

    print_status "Starting Arena Debate on: $topic"

    if rally_exists; then
        print_status "Broadcasting to ai-rally..."
        "$RALLY_SCRIPT" broadcast "$topic"
    fi

    if team_exists; then
        print_status "Sending to claude-team (deep debate mode)..."
        local team_msg="Discuss this topic in depth. Each sub-agent should cross-question the others. Topic: $topic"
        send_with_retry "$TEAM_LEADER_PANE" "$team_msg" "Leader"
    fi

    for round in $(seq 1 $rounds); do
        print_status "=== Round $round/$rounds ==="
        print_info "Waiting for responses (45s)..."
        sleep 45

        if rally_exists; then
            print_status "ai-rally cross-sharing round $round..."
            cmd_cross
        fi

        if rally_exists && team_exists && [ "$round" -eq 1 ]; then
            local codex_highlight=$(tmux capture-pane -t "$RALLY_SESSION:0.0" -p -S -30 | grep -v "^$" | tail -5 | head -3)
            print_status "Sharing ai-rally highlights with Agent Team..."
            send_with_retry "$TEAM_LEADER_PANE" \
                "Codex from ai-rally said: \"${codex_highlight}\". Factor this into your team discussion." "Leader"
        fi
    done

    print_status "Arena Debate completed! Use 'capture-all' to see all results."
}

# === VOICE GEN (delegate to voice-gen.sh) ===
cmd_voice_gen() {
    local voice_script="$SCRIPT_DIR/voice-gen.sh"
    if [ ! -f "$voice_script" ]; then
        print_error "voice-gen.sh not found. Voice generation requires ElevenLabs setup."
        return 1
    fi

    if ! rally_exists; then
        print_error "ai-rally not running."
        return 1
    fi

    "$voice_script" from-capture "$1"
}

# === MAIN ===
case "$1" in
    start)       cmd_start "$2" ;;
    stop)        cmd_stop ;;
    status)      cmd_status ;;
    broadcast)   shift; cmd_broadcast "$*" ;;
    capture-all) cmd_capture_all "$2" ;;
    send)        cmd_send "$2" "$3" ;;
    rally)       cmd_rally "$2" "$3" ;;
    cross)       cmd_cross ;;
    debate)      cmd_debate "$2" "$3" ;;
    voice-gen)   cmd_voice_gen "$2" ;;
    *)
        echo -e "${CYAN}AI Arena${NC} - Multi-AI Debate Orchestrator"
        echo ""
        echo "Send the same question to multiple AI CLIs and compare responses."
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  start [mode]         Start arena (rally=4AI only, full=4AI+team, team=team only)"
        echo "  stop                 Stop everything"
        echo "  status               Show status of all sessions"
        echo "  broadcast <msg>      Send to ALL AIs"
        echo "  capture-all          Capture all responses"
        echo "  send <target> <msg>  Send to: codex|gemini|claude|glm|leader"
        echo "  rally <topic> [n]    Multi-round rally with cross-pollination (default: 3)"
        echo "  cross                Cross-share responses between AIs"
        echo "  debate <topic> [n]   Deep debate mode (cross + team, default: 2 rounds)"
        echo "  voice-gen [dir]      Generate voice from outputs (requires ElevenLabs)"
        echo ""
        echo "Architecture:"
        echo "  ┌──────────────────────────────────┐"
        echo "  │       You (Orchestrator)          │"
        echo "  └──────┬───────────────┬───────────┘"
        echo "         │               │"
        echo "         v               v"
        echo "  ┌──────────────┐ ┌──────────────┐"
        echo "  │  ai-rally    │ │ claude-team  │"
        echo "  │ Codex/Claude │ │ Agent Teams  │"
        echo "  │ Gemini/GLM   │ │ (optional)   │"
        echo "  └──────────────┘ └──────────────┘"
        echo "    tmux 2x2 grid     tmux session"
        ;;
esac

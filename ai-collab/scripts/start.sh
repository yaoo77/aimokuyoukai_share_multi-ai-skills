#!/bin/bash
# AI Collab - セッション開始

SESSION="ai-collab"
CODEX_PANE=0
GEMINI_PANE=1

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Check if session exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${RED}[ai-collab]${NC} Session already exists. Use stop.sh first."
    exit 1
fi

echo -e "${GREEN}[ai-collab]${NC} Starting session..."

# Create session with Codex pane
tmux new-session -d -s "$SESSION" -c "$(pwd)"

# Split for Gemini
tmux split-window -h -t "$SESSION:0"

# Start Codex
echo -e "${BLUE}[ai-collab]${NC} Starting Codex..."
tmux send-keys -t "$SESSION:0.$CODEX_PANE" 'codex' Enter

# Start Gemini
echo -e "${BLUE}[ai-collab]${NC} Starting Gemini..."
tmux send-keys -t "$SESSION:0.$GEMINI_PANE" 'gemini' Enter

# Wait for startup
sleep 5

# Skip update notifications
tmux send-keys -t "$SESSION:0.$CODEX_PANE" '2' Enter 2>/dev/null
tmux send-keys -t "$SESSION:0.$GEMINI_PANE" '2' Enter 2>/dev/null

sleep 3

echo -e "${GREEN}[ai-collab]${NC} Session ready!"
echo -e "${BLUE}[ai-collab]${NC} View: tmux attach -t $SESSION"

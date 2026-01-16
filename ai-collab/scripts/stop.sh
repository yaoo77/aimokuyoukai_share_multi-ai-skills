#!/bin/bash
# AI Collab - セッション終了

SESSION="ai-collab"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${RED}[ai-collab]${NC} No session found."
    exit 0
fi

# Send exit to both
tmux send-keys -t "$SESSION:0.0" '/exit' Enter 2>/dev/null
tmux send-keys -t "$SESSION:0.1" '/exit' Enter 2>/dev/null
sleep 2

# Kill session
tmux kill-session -t "$SESSION" 2>/dev/null

echo -e "${GREEN}[ai-collab]${NC} Session stopped."

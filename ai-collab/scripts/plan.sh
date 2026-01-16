#!/bin/bash
# AI Collab - Phase 1: Codexに企画依頼

SESSION="ai-collab"
CODEX_PANE=0

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TASK="$1"

if [ -z "$TASK" ]; then
    echo -e "${RED}[ai-collab]${NC} Usage: plan.sh <task description>"
    exit 1
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${RED}[ai-collab]${NC} No session. Run start.sh first."
    exit 1
fi

echo -e "${GREEN}[ai-collab]${NC} Sending task to Codex for planning..."

# Build planning prompt
PROMPT="以下のタスクの要件整理と計画を作成して:

【タスク】
$TASK

【出力形式】
1. 要件の明確化（何を作るか）
2. 作業ステップ（順番に）
3. 成果物の形式
4. 注意点・考慮事項

簡潔に、箇条書きで。"

# Send to Codex
echo "$PROMPT" | pbcopy
tmux send-keys -t "$SESSION:0.$CODEX_PANE" "$(pbpaste)" Enter
sleep 1
tmux send-keys -t "$SESSION:0.$CODEX_PANE" Enter

# Wait for response (polling)
echo -e "${YELLOW}[ai-collab]${NC} Waiting for Codex response..."
prev_output=""
for i in {1..30}; do
    current=$(tmux capture-pane -t "$SESSION:0.$CODEX_PANE" -p -S -100 2>/dev/null)
    if [ "$current" = "$prev_output" ] && [ -n "$current" ]; then
        break
    fi
    prev_output="$current"
    sleep 3
done

# Capture and output
echo -e "${GREEN}[ai-collab]${NC} Codex planning complete."
echo ""
echo -e "${YELLOW}=== Codex Plan ===${NC}"
tmux capture-pane -t "$SESSION:0.$CODEX_PANE" -p -S -80 | tail -60

#!/bin/bash
# AI Collab - Phase 3: Codex + Gemini にレビュー依頼

SESSION="ai-collab"
CODEX_PANE=0
GEMINI_PANE=1

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

RESULT="$1"

if [ -z "$RESULT" ]; then
    echo -e "${RED}[ai-collab]${NC} Usage: review.sh <result description>"
    exit 1
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${RED}[ai-collab]${NC} No session. Run start.sh first."
    exit 1
fi

echo -e "${GREEN}[ai-collab]${NC} Sending to Codex + Gemini for review..."

# Build review prompt
PROMPT="以下の成果物をレビューして:

【成果物】
$RESULT

【レビュー観点】
1. 品質: 要件を満たしているか
2. 改善点: 具体的に何を直すべきか
3. 判定: ok: true（問題なし）または ok: false（要改善）

最後に必ず「ok: true」または「ok: false」を明記して。"

# Send to both (parallel)
echo "$PROMPT" | pbcopy

# Codex
tmux send-keys -t "$SESSION:0.$CODEX_PANE" "$(pbpaste)" Enter
sleep 1
tmux send-keys -t "$SESSION:0.$CODEX_PANE" Enter

# Gemini
tmux send-keys -t "$SESSION:0.$GEMINI_PANE" "$(pbpaste)" Enter
sleep 1
tmux send-keys -t "$SESSION:0.$GEMINI_PANE" Enter

# Wait for responses
echo -e "${YELLOW}[ai-collab]${NC} Waiting for reviews..."
sleep 25

# Capture both outputs
echo -e "${GREEN}[ai-collab]${NC} Review complete."
echo ""
echo -e "${YELLOW}=== Codex Review ===${NC}"
tmux capture-pane -t "$SESSION:0.$CODEX_PANE" -p -S -80 | tail -50
echo ""
echo -e "${BLUE}=== Gemini Review ===${NC}"
tmux capture-pane -t "$SESSION:0.$GEMINI_PANE" -p -S -80 | tail -50

# Check for ok: true
codex_ok=$(tmux capture-pane -t "$SESSION:0.$CODEX_PANE" -p -S -50 | grep -i "ok: true" | wc -l)
gemini_ok=$(tmux capture-pane -t "$SESSION:0.$GEMINI_PANE" -p -S -50 | grep -i "ok: true" | wc -l)

echo ""
if [ "$codex_ok" -gt 0 ] && [ "$gemini_ok" -gt 0 ]; then
    echo -e "${GREEN}[ai-collab]${NC} ✓ Both approved! (ok: true)"
elif [ "$codex_ok" -gt 0 ]; then
    echo -e "${YELLOW}[ai-collab]${NC} Codex: ok, Gemini: needs improvement"
elif [ "$gemini_ok" -gt 0 ]; then
    echo -e "${YELLOW}[ai-collab]${NC} Codex: needs improvement, Gemini: ok"
else
    echo -e "${RED}[ai-collab]${NC} Both need improvement (ok: false)"
fi

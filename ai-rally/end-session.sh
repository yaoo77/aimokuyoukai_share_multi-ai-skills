#!/bin/bash
# AI Rally セッション終了時にBash許可を削除

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS_FILE="${PROJECT_ROOT}/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "[ai-rally] 設定ファイルが見つかりません"
  exit 0
fi

# tmuxセッションを終了
tmux kill-session -t ai-rally 2>/dev/null

# 許可を削除（jqがあれば使用）
if command -v jq &> /dev/null; then
  jq '.permissions.allow -= [
    "Bash(tmux*)",
    "Bash(sleep*)",
    "Bash(echo*)",
    "Bash(pbcopy*)",
    "Bash(pbpaste*)",
    "Bash(prev=*)",
    "Bash(for *)",
    "Bash(curr=*)",
    "Bash(codex*)",
    "Bash(gemini*)",
    "Bash(which *)",
    "Bash(osascript*)",
    "Bash(.claude/skills/ai-rally/*)"
  ]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
fi

echo "[ai-rally] セッション終了・Bash許可を削除しました"

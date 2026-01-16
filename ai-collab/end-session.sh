#!/bin/bash
# AI Collab セッション終了時にBash許可を削除

SETTINGS_FILE="/Users/aoion/obsidian_Wrt/.claude/settings.json"

# tmuxセッションを終了
tmux kill-session -t ai-collab 2>/dev/null

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "[ai-collab] 設定ファイルが見つかりません"
  exit 0
fi

# 許可を削除
if command -v jq &> /dev/null; then
  jq '.permissions.allow -= [
    "Bash(tmux*)",
    "Bash(sleep*)",
    "Bash(echo*)",
    "Bash(pbcopy*)",
    "Bash(pbpaste*)",
    "Bash(prev*)",
    "Bash(for *)",
    "Bash(curr*)",
    "Bash(codex*)",
    "Bash(gemini*)",
    "Bash(which *)",
    "Bash(osascript*)",
    "Bash(.claude/skills/ai-collab/*)"
  ]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
fi

echo "[ai-collab] セッション終了・Bash許可を削除しました"

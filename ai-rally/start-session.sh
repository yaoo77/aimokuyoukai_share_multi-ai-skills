#!/bin/bash
# AI Rally セッション開始時にBash許可を追加

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS_FILE="${PROJECT_ROOT}/.claude/settings.json"

# 設定ファイルがなければ作成
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{"permissions":{"allow":[]}}' > "$SETTINGS_FILE"
fi

# 許可を追加（jqがあれば使用、なければ直接書き込み）
if command -v jq &> /dev/null; then
  jq '.permissions.allow += [
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
  ] | .permissions.allow |= unique' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
else
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "permissions": {
    "allow": [
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
    ]
  }
}
EOF
fi

echo "[ai-rally] Bash許可を追加しました"

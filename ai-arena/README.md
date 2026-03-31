# AI Arena

同じ質問を複数のAI CLIに一斉送信し、回答を並べて比較するスキル。

ai-rally（4者並列対話）を内包し、さらにClaude Code Agent Teamsとの統合管理も可能。

## アーキテクチャ

```
┌──────────────────────────────────┐
│       You (Orchestrator)          │
│   arena-manager.sh                │
└──────┬───────────────┬───────────┘
       │               │
       v               v
┌──────────────┐ ┌──────────────┐
│  ai-rally    │ │ claude-team  │
│ Codex/Claude │ │ Agent Teams  │
│ Gemini/GLM   │ │ (optional)   │
└──────────────┘ └──────────────┘
  tmux 2x2 grid     tmux session
```

## クイックスタート

```bash
# 起動
./scripts/arena-manager.sh start

# 全AIにお題を一斉送信
./scripts/arena-manager.sh broadcast "AIエージェントの最適な役割分担について"

# 回答を取得（30-60秒後）
./scripts/arena-manager.sh capture-all

# 個別送信
./scripts/arena-manager.sh send codex "コードレビューして"

# クロス質問（各AIの回答を別のAIに共有して反応を引き出す）
./scripts/arena-manager.sh cross

# マルチラウンド・ラリー
./scripts/arena-manager.sh rally "AIの未来" 3

# 終了
./scripts/arena-manager.sh stop
```

## コマンド一覧

| コマンド | 説明 |
|----------|------|
| `start [mode]` | 起動（rally=4AIのみ, full=4AI+Agent Teams, team=Agent Teamsのみ） |
| `stop` | 全セッション終了 |
| `status` | 状態確認 |
| `broadcast <msg>` | 全AIに一斉送信 |
| `capture-all` | 全レスポンスを一括取得 |
| `send <target> <msg>` | 個別送信（codex/gemini/claude/glm/leader） |
| `cross` | クロス質問（回答を相互共有して反応を引き出す） |
| `rally <topic> [n]` | マルチラウンド・ラリー（デフォルト3ラウンド） |
| `debate <topic> [n]` | 深い議論モード（クロス + Agent Teams、デフォルト2ラウンド） |
| `voice-gen [dir]` | 音声化（ElevenLabs連携） |

## 議論モード

### broadcast（シンプル比較）
同じプロンプトを送り、回答を並べて比較。

### cross（クロス質問）
各AIの回答を別のAIに共有して反応を引き出す。
```
Codex ← Claudeの意見   Claude ← GLMの意見
Gemini ← Codexの意見   GLM ← Geminiの意見
```

### rally（マルチラウンド）
broadcast + cross を自動で複数ラウンド繰り返す。

### debate（深い議論）
rally + Agent Teams外部エージェント呼び出しを統合した最も深い議論モード。

## カスタマイズ

### CLIコマンド名の変更

```bash
export AI_ARENA_CODEX_CMD="codex"
export AI_ARENA_CLAUDE_CMD="claude"
export AI_ARENA_GEMINI_CMD="gemini"
export AI_ARENA_GLM_CMD="glm"
```

### 音声生成（ElevenLabs）

```bash
export ELEVENLABS_API_KEY="your-key"
```

## サンプル出力

[examples/sample-comparison.md](examples/sample-comparison.md) に実際の比較結果例あり。

# Multi-AI Collaboration Skills

Claude Code + Codex + Gemini CLI + GLM の複数AI協働スキル集。

## 前提条件

- Claude Code がインストール済み
- tmux がインストール済み
- 以下のAI CLIを2つ以上インストール:
  - [Codex CLI](https://github.com/openai/codex) (`codex`)
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) (`gemini`)
  - [GLM CLI](https://github.com/nicekate/GLM-cli) (`glm`)
- macOS（pbcopy/pbpaste）または Linux（xclip）

## インストール

```bash
# プロジェクトの .claude/skills/ にコピー
cp -r ai-arena /path/to/your/project/.claude/skills/
cp -r ai-rally /path/to/your/project/.claude/skills/
cp -r ai-collab /path/to/your/project/.claude/skills/
```

## スキル一覧

| スキル | 用途 | AI数 |
|--------|------|------|
| [ai-arena](#スキル1-ai-arena回答比較) | 同じ質問を全AIに送って回答比較 | 4+Agent Teams |
| [ai-rally](#スキル2-ai-rally4者ラリー) | tmux 2x2グリッドで4者並列対話 | 4 |
| [ai-collab](#スキル3-ai-collab3者協働ワークフロー) | 企画→実行→レビュー→改善サイクル | 3 |

---

## スキル1: ai-arena（回答比較）

**同じ質問を全AIに一斉送信し、回答を並べて比較する統合オーケストレーター。**

ai-rally（4者並列対話）を内包し、Claude Code Agent Teamsとの統合管理も可能。

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

### 使い方

```bash
# 起動（4AI）
ai-arena/scripts/arena-manager.sh start

# 全AIに質問
ai-arena/scripts/arena-manager.sh broadcast "Claude Codeで生活はどう変わるか？"

# 回答取得（30-60秒後）
ai-arena/scripts/arena-manager.sh capture-all

# クロス質問（各AIの回答を別のAIに共有して反応を引き出す）
ai-arena/scripts/arena-manager.sh cross

# マルチラウンド・ラリー
ai-arena/scripts/arena-manager.sh rally "AIの未来" 3

# 深い議論（クロス + Agent Teams）
ai-arena/scripts/arena-manager.sh start full
ai-arena/scripts/arena-manager.sh debate "プログラミングの民主化" 2

# 終了
ai-arena/scripts/arena-manager.sh stop
```

### コマンド一覧

| コマンド | 説明 |
|----------|------|
| `start [mode]` | 起動（rally/full/team） |
| `stop` | 全セッション終了 |
| `status` | 状態確認 |
| `broadcast <msg>` | 全AIに一斉送信 |
| `capture-all` | 全レスポンスを一括取得 |
| `send <target> <msg>` | 個別送信（codex/gemini/claude/glm/leader） |
| `cross` | クロス質問 |
| `rally <topic> [n]` | マルチラウンド・ラリー（デフォルト3ラウンド） |
| `debate <topic> [n]` | 深い議論モード（デフォルト2ラウンド） |
| `voice-gen [dir]` | 音声化（ElevenLabs連携・オプション） |

### 議論モード

- **broadcast**: シンプルに送信→回答比較
- **cross**: 各AIの回答を別のAIに共有して反応を引き出す
- **rally**: broadcast + cross を複数ラウンド自動繰り返し
- **debate**: rally + Agent Teams外部エージェント呼び出し

### サンプル出力

[ai-arena/examples/sample-comparison.md](ai-arena/examples/sample-comparison.md) に実際の比較結果あり。

---

## スキル2: ai-rally（4者ラリー）

Codex / Claude / Gemini / GLM を tmux 2x2グリッドで起動し、Claude Code が司会として4者間でラリー形式の対話を行う。

### tmuxレイアウト

```
┌─────────┬─────────┐
│  Codex  │ Claude  │
│ (Pane 0)│(Pane 1) │
├─────────┼─────────┤
│ Gemini  │   GLM   │
│ (Pane 2)│(Pane 3) │
└─────────┴─────────┘
```

### 使い方

```bash
# セッション開始
ai-rally/scripts/tmux-manager.sh start

# ターミナルで見る
tmux attach -t ai-rally

# 全員にメッセージ送信
ai-rally/scripts/tmux-manager.sh broadcast "AIエージェントの役割分担について議論しよう"

# 個別に送信
ai-rally/scripts/tmux-manager.sh send codex "レビューして"
ai-rally/scripts/tmux-manager.sh send gemini "リファクタ案出して"

# 出力取得
ai-rally/scripts/tmux-manager.sh capture-all

# ラウンドロビン・ラリー（5ラウンド）
ai-rally/scripts/tmux-manager.sh rally "最適なAI分担" 5

# セッション終了
ai-rally/scripts/tmux-manager.sh stop
```

### コマンド一覧

| コマンド | 説明 |
|----------|------|
| `start` | セッション作成 + 4AI起動 |
| `stop` | セッション終了 |
| `view` | ターミナルウィンドウを開く |
| `status` | セッション状態確認 |
| `send <ai> <msg>` | codex/gemini/claude/glm にメッセージ送信 |
| `broadcast <msg>` | 全員に同じメッセージを送信 |
| `capture <ai>` | 出力取得 |
| `capture-all` | 全員の出力を取得 |
| `rally <topic> [n]` | nラウンドのラリー |

### CLIコマンドのカスタマイズ

```bash
export AI_ARENA_CODEX_CMD="codex"    # デフォルト
export AI_ARENA_CLAUDE_CMD="claude"  # デフォルト
export AI_ARENA_GEMINI_CMD="gemini"  # デフォルト
export AI_ARENA_GLM_CMD="glm"        # デフォルト
```

### 音声化（ElevenLabs連携・オプション）

討論結果を各AIに固有の声で読み上げ。

| AI | Voice | 特徴 |
|----|-------|------|
| Claude | Matilda | 明るく親しみやすい女性声 |
| Codex | Brian | 落ち着いた男性声 |
| Gemini | Alice | 知的な女性声 |
| GLM | Bill | 深みのある男性声 |

```bash
export ELEVENLABS_API_KEY="your-key"
ai-rally/scripts/voice-gen.sh list-voices
ai-rally/scripts/voice-gen.sh generate Claude "こんにちは" hello.mp3
```

---

## スキル3: ai-collab（3者協働ワークフロー）

汎用的な3者協働ワークフロー。企画→実行→レビュー→改善のサイクルを自動化。

### ワークフロー

```
┌─────────────────────────────────────────────────────┐
│  Phase 1: 企画 (Codex)                              │
│    → 要件整理・計画                                 │
├─────────────────────────────────────────────────────┤
│  Phase 2: 実行 (Claude)                             │
│    → 適切な手段を自動選択（スキル/サブエージェント）│
├─────────────────────────────────────────────────────┤
│  Phase 3: レビュー (Codex + Gemini)                 │
│    → 並列でフィードバック                           │
├─────────────────────────────────────────────────────┤
│  Phase 4: 改善 (Claude)                             │
│    → ok: true が出るまでループ                      │
└─────────────────────────────────────────────────────┘
```

### 使い方

```bash
# 1. セッション開始
ai-collab/scripts/start.sh

# 2. Codexに企画依頼
ai-collab/scripts/plan.sh "READMEを改善して"

# 3. Claude自身が実行（スキル/サブエージェント活用）

# 4. レビュー依頼
ai-collab/scripts/review.sh "README改善完了。セクション追加、例を充実。"

# 5. ok: true が出るまで改善→レビュー繰り返し

# 6. セッション終了
ai-collab/scripts/stop.sh
```

### スクリプト一覧

| スクリプト | 用途 |
|------------|------|
| `scripts/start.sh` | セッション開始 |
| `scripts/stop.sh` | セッション終了 |
| `scripts/plan.sh <task>` | Codexに企画依頼 |
| `scripts/review.sh <result>` | 両者にレビュー依頼 |

---

## トラブルシューティング

### セッションが残っている
```bash
tmux kill-session -t ai-rally
tmux kill-session -t ai-collab
tmux kill-session -t claude-team
```

### Codex/Geminiが起動しない
```bash
which codex   # パス確認
which gemini  # パス確認
which glm     # パス確認
```

### メッセージが送信されない
- 日本語はクリップボード経由で送信（スクリプト内で自動処理）
- 確定のため Enter が複数回必要な場合あり（3秒間隔で最大3回リトライ）

### Linux環境
`pbcopy`/`pbpaste` の代わりに `xclip` をインストール:
```bash
sudo apt install xclip
```

---

## ライセンス

MIT License - 自由に使ってください。

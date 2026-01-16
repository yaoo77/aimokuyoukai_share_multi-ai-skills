# Multi-AI Collaboration Skills

Claude Code + Codex + Gemini CLI の3者協働スキル集。

## 前提条件

- Claude Code がインストール済み
- Codex CLI がインストール済み（`codex` コマンドが使える）
- Gemini CLI がインストール済み（`gemini` コマンドが使える）
- tmux がインストール済み
- macOS（pbcopy/pbpaste使用のため。Linux対応は要修正）

## インストール

```bash
# プロジェクトの .claude/skills/ にコピー
cp -r ai-rally /path/to/your/project/.claude/skills/
cp -r ai-collab /path/to/your/project/.claude/skills/
```

---

## スキル1: ai-rally（3者雑談・ラリー）

Codex と Gemini を tmux で起動し、Claude Code が司会として3者間でラリー形式の対話を行う。

### 使い方

```bash
# セッション開始
.claude/skills/ai-rally/scripts/tmux-manager.sh start

# ターミナルで見る
.claude/skills/ai-rally/scripts/tmux-manager.sh view
# または: tmux attach -t ai-rally

# 両方にメッセージ送信
.claude/skills/ai-rally/scripts/tmux-manager.sh broadcast "AIエージェントの役割分担について議論しよう"

# 個別に送信
.claude/skills/ai-rally/scripts/tmux-manager.sh send codex "レビューして"
.claude/skills/ai-rally/scripts/tmux-manager.sh send gemini "リファクタ案出して"

# 出力取得
.claude/skills/ai-rally/scripts/tmux-manager.sh capture-all

# ラウンドロビン・ラリー（5ラウンド）
.claude/skills/ai-rally/scripts/tmux-manager.sh rally "最適なAI分担" 5

# セッション終了
.claude/skills/ai-rally/scripts/tmux-manager.sh stop
```

### コマンド一覧

| コマンド | 説明 |
|----------|------|
| `start` | セッション作成 + Codex/Gemini起動 |
| `stop` | セッション終了 |
| `view` | ターミナルウィンドウを開く |
| `status` | セッション状態確認 |
| `send <ai> <msg>` | codex or gemini にメッセージ送信 |
| `broadcast <msg>` | 両方に同じメッセージを送信 |
| `capture <ai>` | 出力取得 |
| `capture-all` | 両方の出力を取得 |
| `rally <topic> [n]` | nラウンドのラリー |

---

## スキル2: ai-collab（3者協働ワークフロー）

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
.claude/skills/ai-collab/scripts/start.sh

# 2. Codexに企画依頼
.claude/skills/ai-collab/scripts/plan.sh "READMEを改善して"

# 3. Claude自身が実行（スキル/サブエージェント活用）

# 4. レビュー依頼
.claude/skills/ai-collab/scripts/review.sh "README改善完了。セクション追加、例を充実。"

# 5. ok: true が出るまで改善→レビュー繰り返し

# 6. セッション終了
.claude/skills/ai-collab/scripts/stop.sh
```

### スクリプト一覧

| スクリプト | 用途 |
|------------|------|
| `scripts/start.sh` | セッション開始 |
| `scripts/stop.sh` | セッション終了 |
| `scripts/plan.sh <task>` | Codexに企画依頼 |
| `scripts/review.sh <result>` | 両者にレビュー依頼 |

---

## tmuxレイアウト

```
┌─────────────────┬─────────────────┐
│     Codex       │     Gemini      │
│   (pane 0)      │    (pane 1)     │
└─────────────────┴─────────────────┘
```

ユーザーは `tmux attach -t ai-rally` または `tmux attach -t ai-collab` でリアルタイムに会話を見れる。

---

## トラブルシューティング

### セッションが残っている
```bash
tmux kill-session -t ai-rally
tmux kill-session -t ai-collab
```

### Codex/Geminiが起動しない
```bash
which codex   # パス確認
which gemini  # パス確認
```

### メッセージが送信されない
- 日本語はクリップボード経由で送信（スクリプト内で自動処理）
- 確定のため Enter が2回必要（スクリプト内で自動処理）

---

## ライセンス

MIT License - 自由に使ってください。

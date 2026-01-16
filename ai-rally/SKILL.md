---
name: ai-rally
description: Claude/Codex/Geminiの3者でtmux経由の対話・ラリーを行うスキル。複数AIの並列対話を自動化。
---

# AI Rally Skill

Claude Code が司会として、Codex と Gemini を tmux で起動し、3者間でラリー形式の対話を行うスキル。

## クイックスタート

```bash
# セッション開始（Codex + Gemini を起動）
.claude/skills/ai-rally/scripts/tmux-manager.sh start

# ユーザーが見れるウィンドウを開く
.claude/skills/ai-rally/scripts/tmux-manager.sh view

# 両方に同じメッセージを送信
.claude/skills/ai-rally/scripts/tmux-manager.sh broadcast "このリポジトリの構造について教えて"

# 個別に送信
.claude/skills/ai-rally/scripts/tmux-manager.sh send codex "コードレビューして"
.claude/skills/ai-rally/scripts/tmux-manager.sh send gemini "リファクタリング案を出して"

# 出力取得
.claude/skills/ai-rally/scripts/tmux-manager.sh capture codex
.claude/skills/ai-rally/scripts/tmux-manager.sh capture gemini

# セッション終了
.claude/skills/ai-rally/scripts/tmux-manager.sh stop
```

## 構成

```
.claude/skills/ai-rally/
├── SKILL.md              # このファイル
├── scripts/
│   └── tmux-manager.sh   # メイン管理スクリプト
├── start-session.sh      # Bash許可追加
└── end-session.sh        # Bash許可削除
```

## tmux-manager.sh コマンド一覧

| コマンド | 説明 |
|----------|------|
| `start` | セッション作成 + Codex/Gemini起動 |
| `stop` | セッション終了 |
| `view` | ユーザー用のターミナルウィンドウを開く |
| `status` | セッション状態確認 |
| `send <target> <msg>` | 指定AIにメッセージ送信 (codex/gemini) |
| `broadcast <msg>` | 両方に同じメッセージを送信 |
| `capture <target>` | 指定AIの出力を取得 |
| `capture-all` | 両方の出力を取得 |
| `rally <msg> [rounds]` | ラウンドロビン形式でラリー（デフォルト3ラウンド） |

## 使用例

### 1. 基本的な3者対話

```bash
# 起動
.claude/skills/ai-rally/scripts/tmux-manager.sh start
sleep 8  # 起動待ち

# テーマを投げる
.claude/skills/ai-rally/scripts/tmux-manager.sh broadcast "AIエージェントの最適な役割分担について議論しよう"
sleep 30

# 出力確認
.claude/skills/ai-rally/scripts/tmux-manager.sh capture-all

# 終了
.claude/skills/ai-rally/scripts/tmux-manager.sh stop
```

### 2. ラウンドロビン・ラリー

```bash
# 起動
.claude/skills/ai-rally/scripts/tmux-manager.sh start

# 5ラウンドのラリー
.claude/skills/ai-rally/scripts/tmux-manager.sh rally "tmuxでの複数AI連携の改善案" 5

# 終了
.claude/skills/ai-rally/scripts/tmux-manager.sh stop
```

### 3. 個別タスク依頼

```bash
# 起動
.claude/skills/ai-rally/scripts/tmux-manager.sh start

# Codexにレビュー依頼
.claude/skills/ai-rally/scripts/tmux-manager.sh send codex "@src/main.py をレビューして"

# Geminiにリファクタリング依頼
.claude/skills/ai-rally/scripts/tmux-manager.sh send gemini "@src/main.py のリファクタリング案を出して"

# 両方の結果を取得
.claude/skills/ai-rally/scripts/tmux-manager.sh capture-all

# 終了
.claude/skills/ai-rally/scripts/tmux-manager.sh stop
```

## セッション管理

### Bash許可の自動管理

対話開始時:
```bash
.claude/skills/ai-rally/start-session.sh
```

対話終了時:
```bash
.claude/skills/ai-rally/end-session.sh
```

## tmuxレイアウト

```
┌─────────────────┬─────────────────┐
│     Codex       │     Gemini      │
│   (pane 0)      │    (pane 1)     │
│                 │                 │
│                 │                 │
└─────────────────┴─────────────────┘
       Session: ai-rally
```

## 役割タグ

出力時に自動付与:
- `[Codex]` - Codexからの発言
- `[Gemini]` - Geminiからの発言
- `[Claude]` - Claude Code（司会）からの発言

## 出力ルール

### 保存先
- **AI討論の結果は `20_Project/20_AI討論/` に保存**
- ファイル名: `YYYY-MM-DD_テーマ名.md`

### 書き方
- Claudeくん、Codexさん、Geminiちゃん などキャラクター名で呼ぶ
- 雑談風の読みやすい形式で

## トラブルシューティング

### セッションが残っている場合
```bash
tmux kill-session -t ai-rally 2>/dev/null
```

### Codex/Geminiが起動しない
```bash
which codex
which gemini
```

### メッセージが送信されない
- 日本語はクリップボード経由（スクリプト内で自動処理）
- Enter2回の確定が必要（スクリプト内で自動処理）

## 関連スキル

| スキル | 用途 |
|--------|------|
| ai-rally | 3者並列対話（このスキル） |
| codex-dialogue | Codex単体との対話 |
| gemini-dialogue | Gemini単体との対話 |
| codex-review | Codexでのレビュー特化 |
| claude-company | tmux並列組織管理 |


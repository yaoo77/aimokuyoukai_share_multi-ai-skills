---
name: ai-collab
description: Claude/Codex/Geminiの3者協働で汎用タスクを実行するスキル。Codexが企画、Claudeが実行（サブエージェント活用）、Codex+Geminiがレビュー、改善ループまで自動化。
---

# AI Collab Skill

汎用的な3者協働ワークフロー。自然言語で依頼するだけで、企画→実行→レビュー→改善のサイクルを回す。

## クイックスタート

ユーザーから依頼を受けたら、以下のワークフローを実行:

```bash
# 1. セッション開始
.claude/skills/ai-collab/scripts/start.sh

# 2. Codexに企画依頼
.claude/skills/ai-collab/scripts/plan.sh "依頼内容"

# 3. (Claude自身が実行 - スキル/サブエージェント活用)

# 4. レビュー依頼
.claude/skills/ai-collab/scripts/review.sh "成果物の説明"

# 5. セッション終了
.claude/skills/ai-collab/scripts/stop.sh
```

## ワークフロー詳細

### Phase 1: 企画 (Codex)

```bash
# Codexに要件整理・計画を依頼
output=$(.claude/skills/ai-collab/scripts/plan.sh "依頼内容")
```

Codexが出力する内容:
- 要件の明確化
- 作業ステップ
- 成果物の形式
- 注意点

### Phase 2: 実行 (Claude)

**Claudeが自動判断して適切な手段を選ぶ:**

| 依頼タイプ | 選択する手段 |
|------------|--------------|
| YouTube台本 | `/youtube-ai-hitorigoto` スキル or Task(youtube-scriptwriter) |
| 技術調査 | Task(Explore), Task(youtube-tech-researcher) |
| コード実装 | Task(general-purpose), 直接編集 |
| ドキュメント | Task(Plan), 直接執筆 |
| 設計 | Task(Plan), Task(senior-backend) |

**重要:** 既存スキルがあればそれを使う。なければサブエージェントか直接実行。

### Phase 3: レビュー (Codex + Gemini)

```bash
# 成果物をCodexとGeminiに並列レビュー依頼
feedback=$(.claude/skills/ai-collab/scripts/review.sh "成果物の説明や内容")
```

両者からのフィードバック:
- 品質評価
- 改善点
- `ok: true` または `ok: false`

### Phase 4: 改善 (Claude)

フィードバックに `ok: true` が両方から出るまでループ:

1. フィードバックを分析
2. 改善を実行
3. 再度レビュー依頼
4. 繰り返し

## 実行例

### 例1: YouTube台本

```
ユーザー: "AIブラウザの選び方でYouTube台本作って"

Claude:
1. start.sh 実行
2. plan.sh "YouTube台本: AIブラウザの選び方。ターゲットは非エンジニア。"
3. Codexの企画を確認
4. /youtube-ai-hitorigoto スキル or Task(youtube-scriptwriter) で執筆
5. review.sh "台本完成。約3000文字、5セクション構成。"
6. フィードバック確認 → 改善 → 再レビュー
7. ok: true 確認後、stop.sh
```

### 例2: 設計書作成

```
ユーザー: "Slack連携機能の設計書作って"

Claude:
1. start.sh 実行
2. plan.sh "Slack連携機能の設計書。API連携、Webhook、通知機能を含む。"
3. Codexの企画を確認
4. Task(Plan) で設計 → 直接ドキュメント作成
5. review.sh "設計書完成。アーキテクチャ図、API仕様、シーケンス図含む。"
6. フィードバック確認 → 改善
7. ok: true 確認後、stop.sh
```

### 例3: コードリファクタリング

```
ユーザー: "src/utils/ をリファクタリングして"

Claude:
1. start.sh 実行
2. plan.sh "src/utils/ のリファクタリング。重複排除、型安全性向上。"
3. Codexの企画を確認
4. Task(Explore) で現状分析 → 直接編集
5. review.sh "リファクタリング完了。5ファイル変更、重複3箇所削除。"
6. フィードバック確認 → 改善
7. ok: true 確認後、stop.sh
```

## スクリプト一覧

| スクリプト | 用途 |
|------------|------|
| `scripts/start.sh` | tmuxセッション開始（Codex + Gemini起動） |
| `scripts/stop.sh` | tmuxセッション終了 |
| `scripts/plan.sh <task>` | Codexに企画依頼、結果を出力 |
| `scripts/review.sh <result>` | 両者にレビュー依頼、フィードバック出力 |
| `start-session.sh` | Bash許可追加 |
| `end-session.sh` | Bash許可削除 |

## 注意事項

### Claudeの判断基準

1. **既存スキルがあるか？** → あれば使う
2. **専門サブエージェントがあるか？** → あればTask()で起動
3. **どちらもない？** → 直接実行 or Task(general-purpose)

### レビューループの上限

- 最大3回のループで終了
- 3回目で ok: true が出なければ、ユーザーに確認

### セッション管理

- 必ず `stop.sh` で終了すること
- 異常終了時: `tmux kill-session -t ai-collab`

## 関連スキル

| スキル | 関係 |
|--------|------|
| ai-rally | tmuxインフラを共有（セッション名は別） |
| codex-dialogue | 単体対話用（ai-collabはワークフロー） |
| codex-review | レビュー特化（ai-collabは汎用） |
| youtube-ai-hitorigoto | YouTube台本用（ai-collabから呼び出し可能） |

## トラブルシューティング

### セッションが残っている
```bash
tmux kill-session -t ai-collab 2>/dev/null
```

### Codex/Geminiが応答しない
```bash
# セッション再起動
.claude/skills/ai-collab/scripts/stop.sh
.claude/skills/ai-collab/scripts/start.sh
```

### レビューが永遠に終わらない
- 3回ループしたらユーザーに確認
- 要件が曖昧な可能性 → Codexの企画フェーズをやり直し

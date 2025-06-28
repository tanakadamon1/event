# データベース設定手順

## 方法1: Supabaseダッシュボード（推奨）

1. Supabaseダッシュボードにアクセス
2. プロジェクトを選択
3. 左メニューから「SQL Editor」をクリック
4. 「New query」をクリック
5. `database_schema.sql`の内容をコピー&ペースト
6. 「Run」をクリック

## 方法2: psqlコマンドライン

```bash
# Supabaseの接続情報を取得
# ダッシュボード → Settings → Database → Connection string

# 接続例（実際の値に置き換えてください）
psql "postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres" -f database_schema.sql
```

## 必要な環境変数

`.env`ファイルに以下を設定してください：

```env
VITE_SUPABASE_URL=https://[YOUR-PROJECT-REF].supabase.co
VITE_SUPABASE_ANON_KEY=[YOUR-ANON-KEY]
```

## 確認事項

スキーマ設定後、以下が作成されていることを確認：

- ✅ `events`テーブル
- ✅ `event_images`テーブル  
- ✅ `applications`テーブル
- ✅ `profiles`テーブル
- ✅ `event-images`ストレージバケット
- ✅ RLSポリシー
- ✅ インデックス

## トラブルシューティング

### エラーが発生した場合

1. **権限エラー**: Supabaseダッシュボードで実行することを推奨
2. **テーブルが存在する**: `IF NOT EXISTS`を使用しているので重複エラーは発生しません
3. **RLSポリシーエラー**: ポリシーは個別に削除して再作成可能

### 確認コマンド

```sql
-- テーブル一覧確認
\dt

-- ストレージバケット確認
SELECT * FROM storage.buckets;

-- RLSポリシー確認
SELECT schemaname, tablename, policyname FROM pg_policies;
``` 
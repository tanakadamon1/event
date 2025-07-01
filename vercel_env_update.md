# Vercel環境変数更新手順

## 本番Supabaseの環境変数をVercelに設定

### 1. Vercelプロジェクトにアクセス
- https://vercel.com/dashboard にアクセス
- 該当プロジェクトを選択

### 2. 環境変数を更新
- Settings → Environment Variables に移動
- 以下の変数を更新：

#### VITE_SUPABASE_URL
```
https://znzqsmazlrsolwmnxyqp.supabase.co
```

#### VITE_SUPABASE_ANON_KEY
```
[本番Supabaseのanon public keyを設定]
```

### 3. 本番Supabaseのanon keyを取得
- 本番Supabaseプロジェクト → Settings → API
- `anon public` キーをコピー
- Vercelの `VITE_SUPABASE_ANON_KEY` に設定

### 4. デプロイを再実行
- 環境変数更新後、自動的に再デプロイされます
- または手動で「Redeploy」を実行

### 5. 認証設定
- 本番Supabase → Authentication → Settings
- Site URL: `https://[your-domain].vercel.app`
- Redirect URLs: `https://[your-domain].vercel.app/auth/callback` 
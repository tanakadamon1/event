# VRChatイベントキャスト募集掲示板

VRChatで開催されるイベントのキャスト募集を効率的に行うための掲示板システムです。

## 機能

- 🎭 **イベント投稿**: VRChatイベントの詳細情報を投稿
- 👥 **簡単応募**: ワンクリックでイベントに応募
- 💬 **メッセージング**: 主催者と応募者間のリアルタイムチャット
- 🔔 **通知機能**: 新規応募やメッセージのリアルタイム通知
- 💰 **投げ銭機能**: イベント主催者へのPayPay投げ銭
- 🔍 **検索・フィルター**: タグや日付でのイベント検索

## 技術スタック

- **フロントエンド**: Vue.js 3 + TypeScript
- **状態管理**: Pinia
- **ルーティング**: Vue Router
- **バックエンド**: Supabase
- **認証**: Google OAuth
- **決済**: PayPay（QRコード決済）
- **UI**: カスタムCSS + Vue Toastification

## セットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd vrchat-event-board
```

### 2. 依存関係のインストール

```bash
npm install
```

### 3. 環境変数の設定

`env.example`をコピーして`.env`ファイルを作成し、必要な環境変数を設定してください：

```bash
cp env.example .env
```

```env
# Supabase Configuration
VITE_SUPABASE_URL=your_supabase_url_here
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here

# PayPay Configuration (Optional)
VITE_PAYPAY_MERCHANT_ID=your_paypay_merchant_id_here
VITE_PAYPAY_API_KEY=your_paypay_api_key_here
VITE_PAYPAY_API_SECRET=your_paypay_api_secret_here
```

### 4. Supabaseプロジェクトの設定

1. [Supabase](https://supabase.com)で新しいプロジェクトを作成
2. 以下のSQLスクリプトを実行してテーブルを作成：

```sql
-- Users table
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  vrchat_username TEXT NOT NULL,
  profile_image TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Events table
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  max_participants INTEGER,
  application_deadline TIMESTAMP WITH TIME ZONE,
  discord_id TEXT,
  contact_info TEXT,
  user_id UUID REFERENCES users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event images table
CREATE TABLE event_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event tags table
CREATE TABLE event_tags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  tag TEXT NOT NULL
);

-- Applications table
CREATE TABLE applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  message TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

-- Messages table
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('application', 'message', 'event_update')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  related_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Donations table
CREATE TABLE donations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  donor_id UUID REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('paypal', 'stripe')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reports table
CREATE TABLE reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reported_event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  reported_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'dismissed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Events policies
CREATE POLICY "Events are viewable by everyone" ON events FOR SELECT USING (true);
CREATE POLICY "Users can create events" ON events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own events" ON events FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own events" ON events FOR DELETE USING (auth.uid() = user_id);

-- Event images policies
CREATE POLICY "Event images are viewable by everyone" ON event_images FOR SELECT USING (true);
CREATE POLICY "Event owners can manage images" ON event_images FOR ALL USING (
  EXISTS (
    SELECT 1 FROM events WHERE events.id = event_images.event_id AND events.user_id = auth.uid()
  )
);

-- Event tags policies
CREATE POLICY "Event tags are viewable by everyone" ON event_tags FOR SELECT USING (true);
CREATE POLICY "Event owners can manage tags" ON event_tags FOR ALL USING (
  EXISTS (
    SELECT 1 FROM events WHERE events.id = event_tags.event_id AND events.user_id = auth.uid()
  )
);

-- Applications policies
CREATE POLICY "Users can view applications for events they own" ON applications FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM events WHERE events.id = applications.event_id AND events.user_id = auth.uid()
  )
);
CREATE POLICY "Users can view their own applications" ON applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create applications" ON applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own applications" ON applications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own applications" ON applications FOR DELETE USING (auth.uid() = user_id);

-- Messages policies
CREATE POLICY "Users can view messages they sent or received" ON messages FOR SELECT USING (
  auth.uid() = sender_id OR auth.uid() = receiver_id
);
CREATE POLICY "Users can create messages" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update messages they sent" ON messages FOR UPDATE USING (auth.uid() = sender_id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Donations policies
CREATE POLICY "Users can view their own donations" ON donations FOR SELECT USING (
  auth.uid() = donor_id OR auth.uid() = recipient_id
);
CREATE POLICY "Users can create donations" ON donations FOR INSERT WITH CHECK (auth.uid() = donor_id);

-- Reports policies
CREATE POLICY "Users can view their own reports" ON reports FOR SELECT USING (auth.uid() = reporter_id);
CREATE POLICY "Users can create reports" ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Functions and triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

3. Storage bucketを作成：
   - `event-images` bucketを作成
   - Public accessを有効化

4. Google OAuth設定：
   - Authentication > Providers > Google を有効化
   - Google Cloud ConsoleでOAuth 2.0クライアントIDを設定

### 5. PayPay決済の設定（オプション）

投げ銭機能を使用する場合は、PayPayビジネスアカウントが必要です：

1. [PayPayビジネス](https://paypay.ne.jp/business/)でアカウントを作成
2. 開発者向けAPIキーを取得
3. 環境変数に設定

### 6. 開発サーバーの起動

```bash
npm run dev
```

アプリケーションは `http://localhost:3000` で起動します。

## 開発

### 利用可能なスクリプト

```bash
# 開発サーバーの起動
npm run dev

# プロダクションビルド
npm run build

# ビルドのプレビュー
npm run preview

# リンターの実行
npm run lint

# 型チェック
npm run type-check
```

### プロジェクト構造

```
src/
├── components/          # 再利用可能なコンポーネント
├── views/              # ページコンポーネント
├── stores/             # Piniaストア
├── router/             # Vue Router設定
├── lib/                # ライブラリ設定
├── types/              # TypeScript型定義
├── utils/              # ユーティリティ関数
└── assets/             # 静的アセット
```

## デプロイ

### Vercel

1. Vercelにプロジェクトを接続
2. 環境変数を設定
3. デプロイ

### Netlify

1. Netlifyにプロジェクトを接続
2. 環境変数を設定
3. ビルドコマンド: `npm run build`
4. デプロイ

## ライセンス

MIT License



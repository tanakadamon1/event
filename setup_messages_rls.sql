-- Messages テーブルの本番環境用RLSポリシー設定
-- このスクリプトをSupabaseのSQL Editorで実行してください

-- 1. 既存のポリシーを削除（クリーンアップ）
DROP POLICY IF EXISTS "Users can read their messages" ON messages;
DROP POLICY IF EXISTS "Users can insert messages" ON messages;
DROP POLICY IF EXISTS "Users can update their messages" ON messages;
DROP POLICY IF EXISTS "Users can mark their received messages as read" ON messages;

-- 2. 新しいポリシーを作成

-- 2.1 メッセージの読み取りポリシー
-- 自分が送信者または受信者のメッセージを読み取り可能
CREATE POLICY "Users can read their messages" ON messages
FOR SELECT USING (
  sender_id = auth.uid() OR receiver_id = auth.uid()
);

-- 2.2 メッセージの送信ポリシー
-- 認証されたユーザーがメッセージを送信可能
CREATE POLICY "Users can insert messages" ON messages
FOR INSERT WITH CHECK (
  sender_id = auth.uid() AND 
  sender_id IS NOT NULL AND 
  receiver_id IS NOT NULL AND 
  event_id IS NOT NULL AND 
  content IS NOT NULL
);

-- 2.3 メッセージの既読更新ポリシー
-- 受信者が自分の受信メッセージを既読にできる
CREATE POLICY "Users can mark their received messages as read" ON messages
FOR UPDATE USING (
  receiver_id = auth.uid()
) WITH CHECK (
  receiver_id = auth.uid() AND
  -- is_readフィールドのみ更新可能
  (SELECT COUNT(*) FROM jsonb_object_keys(to_jsonb(NEW)) AS keys WHERE keys != 'is_read') = 0
);

-- 2.4 メッセージの削除ポリシー（オプション）
-- 自分が送信したメッセージを削除可能
CREATE POLICY "Users can delete their sent messages" ON messages
FOR DELETE USING (
  sender_id = auth.uid()
);

-- 3. RLSを有効化
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 4. 確認用クエリ
-- 現在のポリシー一覧を表示
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'messages'; 
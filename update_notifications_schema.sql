-- notificationsテーブルにmessageタイプを追加
-- このスクリプトをSupabaseのSQL Editorで実行してください

-- 1. 既存のCHECK制約を削除
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

-- 2. 新しいCHECK制約を作成（messageタイプを含む）
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check 
CHECK (type IN ('application', 'status_change', 'event_update', 'system', 'message'));

-- 3. 確認用クエリ
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'notifications'::regclass 
AND contype = 'c'; 
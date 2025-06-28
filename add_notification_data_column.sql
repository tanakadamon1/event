-- 通知テーブルにdataカラムを追加
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS data JSONB;

-- 既存の通知のdataカラムをNULLに設定
UPDATE notifications 
SET data = NULL 
WHERE data IS NULL;

-- dataカラムにコメントを追加
COMMENT ON COLUMN notifications.data IS '通知に関連する追加データ（JSON形式）'; 
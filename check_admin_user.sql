-- 運営者IDの存在確認
SELECT 
    id,
    email,
    created_at,
    CASE 
        WHEN id = '90cc28a6-cb6a-46bf-b62f-7afad97ca226' THEN 'ADMIN_USER'
        ELSE 'REGULAR_USER'
    END as user_type
FROM auth.users 
WHERE id = '90cc28a6-cb6a-46bf-b62f-7afad97ca226';

-- もし運営者IDが存在しない場合、テスト用のユーザーを作成するか、
-- 既存のユーザーIDを使用する必要があります

-- 全ユーザーの一覧（最初の10件）
SELECT 
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10; 
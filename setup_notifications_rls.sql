-- 通知の受信者が自分の通知を既読にできるRLSポリシー
CREATE POLICY "Users can mark their notifications as read" ON notifications
FOR UPDATE USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid()); 
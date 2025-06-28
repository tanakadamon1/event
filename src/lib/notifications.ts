import { supabase } from './supabase'

export interface Notification {
  id: string
  user_id: string
  title: string
  message: string
  type: 'application' | 'status_change' | 'event_update' | 'system' | 'message' | 'donation'
  related_event_id?: string
  related_application_id?: string
  is_read: boolean
  created_at: string
}

// 汎用的な通知を作成
export const createNotification = async (notification: {
  user_id: string
  type: string
  title: string
  message: string
  data?: any
}) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .insert({
        user_id: notification.user_id,
        title: notification.title,
        content: notification.message,
        type: notification.type,
        data: notification.data ? JSON.stringify(notification.data) : null
      })

    if (error) {
      console.error('Error creating notification:', error)
      throw error
    }
  } catch (error) {
    console.error('Error creating notification:', error)
    throw error
  }
}

// 応募通知を作成
export const createApplicationNotification = async (
  eventId: string,
  eventTitle: string,
  applicantUsername: string
) => {
  try {
    // イベントの主催者を取得
    const { data: event } = await supabase
      .from('events')
      .select('user_id')
      .eq('id', eventId)
      .single()

    if (!event) return

    // 主催者に通知を作成
    const { error } = await supabase
      .from('notifications')
      .insert({
        user_id: event.user_id,
        title: '新しい応募があります',
        content: `「${eventTitle}」に${applicantUsername}さんが応募しました。`,
        type: 'application',
        related_id: eventId
      })

    if (error) {
      console.error('Error creating application notification:', error)
    }
  } catch (error) {
    console.error('Error creating application notification:', error)
  }
}

// 応募ステータス変更通知を作成
export const createStatusChangeNotification = async (
  applicationId: string,
  eventTitle: string,
  status: 'approved' | 'rejected',
  applicantId: string
) => {
  try {
    const statusText = status === 'approved' ? '承認' : '却下'
    
    const { error } = await supabase
      .from('notifications')
      .insert({
        user_id: applicantId,
        title: '応募ステータスが更新されました',
        content: `「${eventTitle}」の応募が${statusText}されました。`,
        type: 'status_change',
        related_id: applicationId
      })

    if (error) {
      console.error('Error creating status change notification:', error)
    }
  } catch (error) {
    console.error('Error creating status change notification:', error)
  }
}

// 通知を既読にする
export const markNotificationAsRead = async (notificationId: string) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', notificationId)

    if (error) {
      console.error('Error marking notification as read:', error)
    }
  } catch (error) {
    console.error('Error marking notification as read:', error)
  }
}

// 通知を削除する
export const deleteNotification = async (notificationId: string) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', notificationId)

    if (error) {
      console.error('Error deleting notification:', error)
    }
  } catch (error) {
    console.error('Error deleting notification:', error)
  }
}

// ユーザーの通知一覧を取得
export const fetchUserNotifications = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];
    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error
    return data
  } catch (error) {
    console.error('Error fetching notifications:', error)
    return []
  }
}

// 未読通知数を取得
export const getUnreadNotificationCount = async () => {
  try {
    const { count, error } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('is_read', false)

    if (error) throw error
    return count || 0
  } catch (error) {
    console.error('Error getting unread notification count:', error)
    return 0
  }
}

// メッセージ通知を作成
export const createMessageNotification = async (
  eventId: string,
  eventTitle: string,
  senderUsername: string,
  receiverId: string
) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .insert({
        user_id: receiverId,
        title: '新しいメッセージがあります',
        content: `「${eventTitle}」で${senderUsername}さんからメッセージが届きました。`,
        type: 'message',
        related_id: eventId
      })

    if (error) {
      console.error('Error creating message notification:', error)
    }
  } catch (error) {
    console.error('Error creating message notification:', error)
  }
}

// 投げ銭通知を作成
export const createDonationNotification = async (
  eventId: string,
  eventTitle: string,
  donorUsername: string,
  amount: number,
  recipientId: string
) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .insert({
        user_id: recipientId,
        title: '投げ銭を受け取りました',
        content: `「${eventTitle}」で${donorUsername}さんから${amount.toLocaleString()}円の投げ銭を受け取りました。`,
        type: 'system',
        related_id: eventId
      })

    if (error) {
      console.error('Error creating donation notification:', error)
    }
  } catch (error) {
    console.error('Error creating donation notification:', error)
  }
} 
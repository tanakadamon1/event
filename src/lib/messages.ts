import { supabase } from './supabase'
import { createMessageNotification } from './notifications'

export interface Message {
  id: string
  sender_id: string
  receiver_id: string
  event_id: string
  content: string
  is_read: boolean
  created_at: string
  sender_profile?: {
    username: string
    avatar_url: string
  }
  receiver_profile?: {
    username: string
    avatar_url: string
  }
}

export interface Conversation {
  event_id: string
  event_title: string
  other_user_id: string
  other_user_username: string
  last_message?: string
  last_message_time?: string
  unread_count: number
}

function isUUID(str: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);
}

// メッセージを送信
export const sendMessage = async (
  receiverId: string,
  eventId: string,
  content: string
) => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    console.log('sendMessage: receiverId =', receiverId, 'user.id =', user.id);
    const { data, error } = await supabase
      .from('messages')
      .insert({
        sender_id: user.id,
        receiver_id: receiverId,
        event_id: eventId,
        content: content.trim()
      })
      .select()
      .single();

    if (error) throw error;
    
    // メッセージ送信後に通知を作成
    try {
      // 送信者のユーザー名を取得
      const { data: senderProfile } = await supabase
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .single();
      
      // イベント名を取得
      const { data: eventData } = await supabase
        .from('events')
        .select('title')
        .eq('id', eventId)
        .single();
      
      if (senderProfile?.username && eventData?.title) {
        await createMessageNotification(
          eventId,
          eventData.title,
          senderProfile.username,
          receiverId
        );
      }
    } catch (notificationError) {
      console.error('Error creating message notification:', notificationError);
      // 通知作成に失敗してもメッセージ送信は成功とする
    }
    
    return data;
  } catch (error) {
    console.error('Error sending message:', error);
    throw error;
  }
}

// メッセージを既読にする
export const markMessageAsRead = async (messageId: string) => {
  try {
    const { error } = await supabase
      .from('messages')
      .update({ is_read: true })
      .eq('id', messageId)

    if (error) throw error
  } catch (error) {
    console.error('Error marking message as read:', error)
  }
}

// 会話内のすべてのメッセージを既読にする
export const markConversationAsRead = async (eventId: string, otherUserId: string) => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    // event_idとreceiver_idだけで一括UPDATE
    const { error } = await supabase
      .from('messages')
      .update({ is_read: true })
      .eq('event_id', eventId)
      .eq('receiver_id', user.id)
      .eq('is_read', false);
    if (error) {
      console.error('markConversationAsRead: error updating messages:', error);
      throw error;
    }
    // 関連するメッセージ通知を既読にする
    try {
      const { data: messageNotifications, error: selectError } = await supabase
        .from('notifications')
        .select('id, is_read')
        .eq('user_id', user.id)
        .eq('type', 'message')
        .eq('related_event_id', eventId)
        .eq('is_read', false);
      if (selectError) {
        console.error('Error selecting message notifications:', selectError);
      } else if (messageNotifications && messageNotifications.length > 0) {
        for (const notification of messageNotifications) {
          const { error: updateError } = await supabase
            .from('notifications')
            .update({ is_read: true })
            .eq('id', notification.id);
          if (updateError) {
            console.error(`Error marking notification ${notification.id} as read:`, updateError);
          } else {
            // UPDATE後の状態を確認
            const { data: updated, error: checkError } = await supabase
              .from('notifications')
              .select('id, is_read')
              .eq('id', notification.id)
              .single();
            if (checkError) {
              console.error('Error checking updated notification:', checkError);
            } else {
              console.log('Notification updated:', updated);
            }
          }
        }
      }
    } catch (notificationError) {
      console.error('Error marking message notifications as read:', notificationError);
    }
  } catch (error) {
    console.error('Error marking conversation as read:', error)
  }
}

// ユーザーの会話一覧を取得
export const fetchConversations = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    // 自分が参加しているメッセージを取得
    const { data: messages, error } = await supabase
      .from('messages')
      .select(`
        event_id,
        sender_id,
        receiver_id,
        content,
        created_at,
        is_read
      `)
      .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`)
      .order('created_at', { ascending: false })

    if (error) throw error

    // 会話をグループ化
    const conversations = new Map<string, Conversation>()
    
    messages?.forEach(message => {
      const otherUserId = message.sender_id === user.id 
        ? message.receiver_id 
        : message.sender_id
      
      const key = `${message.event_id}-${otherUserId}`
      
      if (!conversations.has(key)) {
        conversations.set(key, {
          event_id: message.event_id,
          event_title: '', // 後で取得
          other_user_id: otherUserId,
          other_user_username: '', // 後で取得
          unread_count: 0
        })
      }
      
      const conversation = conversations.get(key)!
      
      // 最新メッセージを更新
      if (!conversation.last_message_time || message.created_at > conversation.last_message_time) {
        conversation.last_message = message.content
        conversation.last_message_time = message.created_at
      }
      
      // 未読数をカウント
      if (!message.is_read && message.receiver_id === user.id) {
        conversation.unread_count++
      }
    })

    // イベント情報を取得
    const eventIds = Array.from(conversations.values()).map(conversation => conversation.event_id);
    let events: { id: string, title: string }[] = [];
    if (eventIds.length === 1) {
      const { data } = await supabase
        .from('events')
        .select('id, title')
        .eq('id', eventIds[0]);
      events = data || [];
    } else if (eventIds.length > 1) {
      const { data } = await supabase
        .from('events')
        .select('id, title')
        .in('id', eventIds);
      events = data || [];
    }

    // 他のユーザーのプロフィール情報を取得
    const userIds = Array.from(conversations.values()).map(c => c.other_user_id)
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, username')
      .in('id', userIds)

    // 情報を会話に追加
    conversations.forEach(conversation => {
      const event = events?.find(e => e.id === conversation.event_id)
      if (event && event.title) {
        conversation.event_title = event.title
      }
      const profile = profiles?.find(p => p.id === conversation.other_user_id)
      if (profile) {
        conversation.other_user_username = profile.username
      }
    })

    return Array.from(conversations.values())
  } catch (error) {
    console.error('Error fetching conversations:', error)
    return []
  }
}

// 特定のイベントでの会話履歴を取得
export const fetchConversation = async (eventId: string, otherUserId: string) => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('event_id', eventId)
      .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`)
      .order('created_at', { ascending: true });

    if (error) throw error;

    // プロフィールIDを集める
    const userIds = Array.from(new Set(
      (data || []).flatMap(msg => [msg.sender_id, msg.receiver_id])
    ));
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, username, avatar_url')
      .in('id', userIds);

    // メッセージにプロフィール情報を付与
    const messagesWithProfiles = (data || []).map(msg => ({
      ...msg,
      sender_profile: profiles?.find(p => p.id === msg.sender_id),
      receiver_profile: profiles?.find(p => p.id === msg.receiver_id),
    }));

    return messagesWithProfiles;
  } catch (error) {
    console.error('Error fetching conversation:', error);
    return [];
  }
}

// メッセージを削除
export const deleteMessage = async (messageId: string) => {
  try {
    const { error } = await supabase
      .from('messages')
      .delete()
      .eq('id', messageId)

    if (error) throw error
  } catch (error) {
    console.error('Error deleting message:', error)
  }
}

// 未読メッセージ数を取得
export const getUnreadMessageCount = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return 0;
    
    const { count, error } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .eq('receiver_id', user.id)
      .eq('is_read', false)

    if (error) {
      console.error('getUnreadMessageCount: error querying messages:', error);
      throw error;
    }
    
    return count || 0
  } catch (error) {
    console.error('Error getting unread message count:', error)
    return 0
  }
} 
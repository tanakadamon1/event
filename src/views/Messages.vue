<template>
  <div class="messages-page">
    <div class="container">
      <div class="page-header">
        <h1>メッセージ</h1>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>読み込み中...</p>
      </div>

      <div v-else-if="conversations.length === 0" class="no-conversations">
        <p>メッセージはありません。</p>
      </div>

      <div v-else class="messages-layout">
        <!-- 会話一覧 -->
        <div class="conversations-list">
          <div 
            v-for="conversation in conversations" 
            :key="`${conversation.event_id}-${conversation.other_user_id}`"
            class="conversation-item"
            :class="{ 
              active: selectedConversation?.event_id === conversation.event_id && 
                      selectedConversation?.other_user_id === conversation.other_user_id,
              unread: conversation.unread_count > 0
            }"
            @click="selectConversation(conversation)"
          >
            <div class="conversation-header">
              <h3 class="conversation-title">{{ conversation.event_title || 'イベントが削除されました' }}</h3>
              <span v-if="conversation.unread_count > 0" class="unread-badge">
                {{ conversation.unread_count }}
              </span>
            </div>
            
            <div class="conversation-meta">
              <span class="conversation-user">{{ conversation.other_user_username }}</span>
              <span v-if="conversation.last_message_time" class="conversation-time">
                {{ formatDate(conversation.last_message_time) }}
              </span>
            </div>
            
            <p v-if="conversation.last_message" class="conversation-preview">
              {{ truncateText(conversation.last_message, 50) }}
            </p>
          </div>
        </div>

        <!-- メッセージ詳細 -->
        <div v-if="selectedConversation" class="message-detail">
          <div class="message-header">
            <h2>{{ selectedConversation.event_title || 'イベントが削除されました' }}</h2>
            <template v-if="selectedTwitterId">
              <a
                :href="`https://twitter.com/${selectedTwitterId.replace('@','')}`"
                target="_blank"
                rel="noopener"
                class="twitter-link"
              >
                @{{ selectedConversation.other_user_username }}
              </a>
            </template>
            <template v-else>
              <p>@{{ selectedConversation.other_user_username }}</p>
            </template>
          </div>

          <div class="message-list" ref="messageList">
            <div 
              v-for="message in messages" 
              :key="message.id"
              class="message-item"
              :class="{ 
                sent: message.sender_id === currentUserId,
                received: message.receiver_id === currentUserId
              }"
            >
              <div class="message-content">
                <p>{{ message.content }}</p>
                <span class="message-time">{{ formatTime(message.created_at) }}</span>
              </div>
            </div>
          </div>

          <div class="message-input">
            <form @submit.prevent="sendMessage">
              <div class="input-group">
                <textarea
                  v-model="newMessage"
                  placeholder="メッセージを入力..."
                  rows="3"
                  class="message-textarea"
                  :disabled="sending"
                ></textarea>
                <button 
                  type="submit" 
                  class="send-btn"
                  :disabled="!newMessage.trim() || sending"
                >
                  {{ sending ? '送信中...' : '送信' }}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div v-else class="no-selection">
          <p>会話を選択してください</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'
import { format } from 'date-fns'
import { ja } from 'date-fns/locale'
import { 
  fetchConversations, 
  fetchConversation, 
  sendMessage as sendMessageUtil,
  markConversationAsRead,
  type Conversation,
  type Message 
} from '@/lib/messages'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const toast = useToast()

const conversations = ref<Conversation[]>([])
const selectedConversation = ref<Conversation | null>(null)
const messages = ref<Message[]>([])
const newMessage = ref('')
const loading = ref(false)
const sending = ref(false)
const messageList = ref<HTMLElement | null>(null)
const selectedTwitterId = ref<string | null>(null)

const currentUserId = computed(() => authStore.user?.id)

const fetchConversationsList = async () => {
  if (!authStore.user) {
    router.push('/login')
    return
  }

  loading.value = true
  try {
    const data = await fetchConversations()
    conversations.value = data
  } catch (error) {
    console.error('Error fetching conversations:', error)
    toast.error('会話の取得に失敗しました')
  } finally {
    loading.value = false
  }
}

const selectConversation = async (conversation: Conversation) => {
  selectedConversation.value = conversation
  newMessage.value = ''
  selectedTwitterId.value = null
  try {
    // 相手ユーザーのtwitter_idを取得
    const { data: userProfile } = await supabase
      .from('profiles')
      .select('twitter_id')
      .eq('id', conversation.other_user_id)
      .single()
    if (userProfile?.twitter_id) {
      selectedTwitterId.value = userProfile.twitter_id
    }
    const data = await fetchConversation(conversation.event_id, conversation.other_user_id)
    messages.value = data
    
    // 既読にする
    await markConversationAsRead(conversation.event_id, conversation.other_user_id)
    
    // 会話一覧の未読数を更新
    conversation.unread_count = 0
    
    // ナビゲーションバーの未読数を更新
    window.dispatchEvent(new CustomEvent('updateUnreadCounts'))
    
    // メッセージリストを最下部にスクロール
    await nextTick()
    if (messageList.value) {
      messageList.value.scrollTop = messageList.value.scrollHeight
    }
  } catch (error) {
    console.error('Error fetching conversation:', error)
    toast.error('メッセージの取得に失敗しました')
  }
}

const sendMessage = async () => {
  if (!selectedConversation.value || !newMessage.value.trim() || !authStore.user) return
  
  sending.value = true
  try {
    await sendMessageUtil(
      selectedConversation.value.other_user_id,
      selectedConversation.value.event_id,
      newMessage.value
    )
    
    // メッセージリストを更新
    await selectConversation(selectedConversation.value)
    
    newMessage.value = ''
    toast.success('メッセージを送信しました')
  } catch (error) {
    console.error('Error sending message:', error)
    toast.error('メッセージの送信に失敗しました')
  } finally {
    sending.value = false
  }
}

const formatDate = (dateString: string) => {
  return format(new Date(dateString), 'MM/dd HH:mm', { locale: ja })
}

const formatTime = (dateString: string) => {
  return format(new Date(dateString), 'HH:mm', { locale: ja })
}

const truncateText = (text: string, maxLength: number) => {
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

// メッセージが追加されたときに自動スクロール
watch(messages, async () => {
  await nextTick()
  if (messageList.value) {
    messageList.value.scrollTop = messageList.value.scrollHeight
  }
})

onMounted(async () => {
  document.title = 'メッセージ | VRChatイベントキャスト募集掲示板'
  await fetchConversationsList()

  // event_titleが空の会話を補完
  for (const conv of conversations.value) {
    if (!conv.event_title && conv.event_id) {
      try {
        const { data: eventData } = await supabase
          .from('events')
          .select('title')
          .eq('id', conv.event_id)
          .single()
        if (eventData?.title) conv.event_title = eventData.title
      } catch {}
    }
  }

  // クエリパラメータからeventとuserを取得
  const eventId = route.query.event as string | undefined
  const userId = route.query.user as string | undefined

  if (eventId && userId && authStore.user) {
    // 既存の会話を探す
    let conversation = conversations.value.find(
      c => c.event_id === eventId && c.other_user_id === userId
    )
    // なければ仮の会話を作成
    if (!conversation) {
      // イベント名とユーザー名を取得
      let eventTitle = 'イベント'
      let userName = 'ユーザー'
      try {
        const { data: eventData } = await supabase
          .from('events')
          .select('title')
          .eq('id', eventId)
          .single()
        if (eventData?.title) eventTitle = eventData.title
        const { data: userProfile } = await supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single()
        if (userProfile?.username) userName = userProfile.username
      } catch {}
      conversation = {
        event_id: eventId,
        event_title: eventTitle,
        other_user_id: userId,
        other_user_username: userName,
        unread_count: 0
      }
      conversations.value.unshift(conversation)
    }
    await selectConversation(conversation)
  }
})
</script>

<style scoped>
.messages-page {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.container {
  flex: 1 1 0;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.page-header {
  margin-bottom: 2rem;
}

.page-header h1 {
  margin: 0;
  font-size: 2.5rem;
  color: #333;
}

.loading, .no-conversations {
  text-align: center;
  padding: 4rem 0;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.messages-layout {
  max-height: 700px;
  height: 80vh;
  flex: 1 1 0;
  min-height: 0;
  display: grid;
  grid-template-columns: 350px 1fr;
  gap: 2rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  overflow: hidden;
}

.conversations-list {
  border-right: 1px solid #e1e5e9;
  overflow-y: auto;
}

.conversation-item {
  padding: 1rem;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  transition: background-color 0.3s;
}

.conversation-item:hover {
  background-color: #f8f9fa;
}

.conversation-item.active {
  background-color: #e3f2fd;
  border-left: 4px solid #667eea;
}

.conversation-item.unread {
  background-color: #fff3cd;
}

.conversation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.conversation-title {
  margin: 0;
  font-size: 1rem;
  color: #333;
  font-weight: 600;
}

.unread-badge {
  background-color: #dc3545;
  color: white;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: bold;
}

.conversation-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.conversation-user {
  font-size: 0.875rem;
  color: #666;
}

.conversation-time {
  font-size: 0.75rem;
  color: #999;
}

.conversation-preview {
  margin: 0;
  font-size: 0.875rem;
  color: #555;
  line-height: 1.4;
}

.message-detail {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 0;
}

.message-header {
  padding: 1rem;
  border-bottom: 1px solid #e1e5e9;
  background-color: #f8f9fa;
}

.message-header h2 {
  margin: 0 0 0.25rem 0;
  font-size: 1.25rem;
  color: #333;
}

.message-header p {
  margin: 0;
  color: #666;
  font-size: 0.875rem;
}

.message-list {
  flex: 1 1 0;
  min-height: 0;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.message-item {
  display: flex;
}

.message-item.sent {
  justify-content: flex-end;
}

.message-item.received {
  justify-content: flex-start;
}

.message-content {
  max-width: 70%;
  padding: 0.75rem 1rem;
  border-radius: 12px;
  position: relative;
}

.message-item.sent .message-content {
  background-color: #667eea;
  color: white;
}

.message-item.received .message-content {
  background-color: #f0f0f0;
  color: #333;
}

.message-content p {
  margin: 0 0 0.25rem 0;
  line-height: 1.4;
}

.message-time {
  font-size: 0.75rem;
  opacity: 0.7;
}

.message-input {
  padding: 1rem;
  border-top: 1px solid #e1e5e9;
  background-color: #f8f9fa;
}

.input-group {
  display: flex;
  gap: 0.5rem;
}

.message-textarea {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  resize: none;
  font-family: inherit;
  font-size: 0.875rem;
}

.message-textarea:focus {
  outline: none;
  border-color: #667eea;
}

.send-btn {
  padding: 0.75rem 1.5rem;
  background-color: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.3s;
}

.send-btn:hover:not(:disabled) {
  background-color: #5a6fd8;
}

.send-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.no-selection {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  font-size: 1.125rem;
}

@media (max-width: 768px) {
  .messages-layout {
    grid-template-columns: 1fr;
    height: auto;
    max-height: 90vh;
  }
  .page-header {
    margin-bottom: 0.7rem;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
  }
  .page-header h1 {
    font-size: 1.3rem;
    margin: 0;
  }
  .message-detail {
    height: 350px;
    min-height: 0;
  }
  .conversations-list {
    max-height: 200px;
    min-height: 0;
  }
}
</style> 
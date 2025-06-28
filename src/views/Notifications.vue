<template>
  <div class="notifications-page">
    <div class="container">
      <div class="page-header">
        <h1>通知</h1>
        <div class="header-actions">
          <button 
            v-if="hasUnread" 
            @click="markAllAsRead" 
            class="btn btn-secondary"
            :disabled="loading"
          >
            すべて既読にする
          </button>
          <button 
            @click="deleteAllRead" 
            class="btn btn-danger"
            :disabled="loading || !hasReadNotifications"
          >
            既読を削除
          </button>
        </div>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>読み込み中...</p>
      </div>

      <div v-else-if="notifications.length === 0" class="no-notifications">
        <p>通知はありません。</p>
      </div>

      <div v-else class="notifications-list">
        <div 
          v-for="notification in notifications" 
          :key="notification.id" 
          class="notification-item"
          :class="{ unread: !notification.is_read }"
        >
          <div class="notification-content" @click="handleNotificationClick(notification)">
            <div class="notification-header">
              <h3 class="notification-title">{{ notification.title }}</h3>
              <div class="notification-meta">
                <span class="notification-time">{{ formatDate(notification.created_at) }}</span>
                <span v-if="!notification.is_read" class="unread-badge">未読</span>
              </div>
            </div>
            
            <p class="notification-message">{{ notification.message }}</p>
            
            <div class="notification-actions">
              <button 
                v-if="!notification.is_read" 
                @click.stop="markAsRead(notification.id)"
                class="btn btn-sm btn-secondary"
              >
                既読にする
              </button>
              <button 
                @click.stop="deleteNotification(notification.id)"
                class="btn btn-sm btn-danger"
              >
                削除
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'
import { format } from 'date-fns'
import { ja } from 'date-fns/locale'
import { 
  fetchUserNotifications, 
  markNotificationAsRead, 
  deleteNotification as deleteNotificationUtil,
  type Notification 
} from '@/lib/notifications'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const notifications = ref<Notification[]>([])
const loading = ref(false)

const hasUnread = computed(() => 
  notifications.value.some(notification => !notification.is_read)
)

const hasReadNotifications = computed(() => 
  notifications.value.some(notification => notification.is_read)
)

const fetchNotifications = async () => {
  if (!authStore.user) {
    router.push('/login')
    return
  }

  loading.value = true
  try {
    const data = await fetchUserNotifications()
    notifications.value = data || []
  } catch (error) {
    console.error('Error fetching notifications:', error)
    toast.error('通知の取得に失敗しました')
  } finally {
    loading.value = false
  }
}

const markAsRead = async (notificationId: string) => {
  try {
    await markNotificationAsRead(notificationId)
    
    // ローカル状態を更新
    const notification = notifications.value.find(n => n.id === notificationId)
    if (notification) {
      notification.is_read = true
    }
    
    toast.success('既読にしました')
  } catch (error) {
    console.error('Error marking notification as read:', error)
    toast.error('既読の更新に失敗しました')
  }
}

const markAllAsRead = async () => {
  try {
    const unreadNotifications = notifications.value.filter(n => !n.is_read)
    
    await Promise.all(
      unreadNotifications.map(notification => markNotificationAsRead(notification.id))
    )
    
    // ローカル状態を更新
    notifications.value.forEach(notification => {
      notification.is_read = true
    })
    
    toast.success('すべて既読にしました')
  } catch (error) {
    console.error('Error marking all notifications as read:', error)
    toast.error('既読の更新に失敗しました')
  }
}

const deleteNotificationItem = async (notificationId: string) => {
  try {
    await deleteNotificationUtil(notificationId)
    
    // ローカル状態から削除
    notifications.value = notifications.value.filter(n => n.id !== notificationId)
    
    toast.success('通知を削除しました')
  } catch (error) {
    console.error('Error deleting notification:', error)
    toast.error('通知の削除に失敗しました')
  }
}

const deleteNotification = async (notificationId: string) => {
  if (confirm('この通知を削除しますか？')) {
    await deleteNotificationItem(notificationId)
  }
}

const deleteAllRead = async () => {
  if (!confirm('既読の通知をすべて削除しますか？')) return
  
  try {
    const readNotifications = notifications.value.filter(n => n.is_read)
    
    await Promise.all(
      readNotifications.map(notification => deleteNotification(notification.id))
    )
    
    // ローカル状態から削除
    notifications.value = notifications.value.filter(n => !n.is_read)
    
    toast.success('既読の通知を削除しました')
  } catch (error) {
    console.error('Error deleting read notifications:', error)
    toast.error('通知の削除に失敗しました')
  }
}

const handleNotificationClick = (notification: Notification) => {
  // 未読の場合は既読にする
  if (!notification.is_read) {
    markAsRead(notification.id)
  }
  
  // 関連するページに遷移
  if (notification.type === 'message' && notification.related_event_id) {
    // メッセージ通知の場合は、メッセージページに遷移
    // 相手のユーザーIDを取得する必要があるため、メッセージページで処理
    router.push(`/messages?event=${notification.related_event_id}`)
  } else if (notification.related_event_id) {
    router.push(`/events/${notification.related_event_id}`)
  } else if (notification.related_application_id) {
    router.push('/applications')
  }
}

const formatDate = (dateString: string) => {
  return format(new Date(dateString), 'yyyy年MM月dd日 HH:mm', { locale: ja })
}

onMounted(() => {
  fetchNotifications()
})
</script>

<style scoped>
.notifications-page {
  padding: 2rem 0;
}

.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 0 1rem;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  margin: 0;
  font-size: 2.5rem;
  color: #333;
}

.header-actions {
  display: flex;
  gap: 0.5rem;
}

.loading, .no-notifications {
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

.notifications-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.notification-item {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  overflow: hidden;
  transition: all 0.3s;
}

.notification-item:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.12);
}

.notification-item.unread {
  border-left: 4px solid #667eea;
  background-color: #f8f9ff;
}

.notification-content {
  padding: 1.5rem;
  cursor: pointer;
}

.notification-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 0.5rem;
}

.notification-title {
  margin: 0;
  font-size: 1.125rem;
  color: #333;
  font-weight: 600;
}

.notification-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.notification-time {
  font-size: 0.875rem;
  color: #666;
}

.unread-badge {
  background-color: #667eea;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
}

.notification-message {
  margin: 0 0 1rem 0;
  color: #555;
  line-height: 1.5;
}

.notification-actions {
  display: flex;
  gap: 0.5rem;
}

.btn {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
}

.btn-sm {
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
}

.btn-primary {
  background-color: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #5a6fd8;
}

.btn-secondary {
  background-color: #f0f0f0;
  color: #333;
}

.btn-secondary:hover:not(:disabled) {
  background-color: #e1e5e9;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background-color: #c82333;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .header-actions {
    justify-content: center;
  }
  
  .notification-header {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .notification-actions {
    flex-direction: column;
  }
}
</style> 
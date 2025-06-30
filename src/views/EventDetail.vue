<template>
  <div class="event-detail-page">
    <div class="container">
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>読み込み中...</p>
      </div>

      <div v-else-if="!event" class="error">
        <p>イベントが見つかりませんでした。</p>
        <router-link to="/events" class="btn btn-secondary">イベント一覧に戻る</router-link>
      </div>

      <div v-else class="event-content">
        <!-- イベントヘッダー -->
        <div class="event-header">
          <div class="event-title-section">
            <h1>{{ event.title }}</h1>
            <div class="event-status" :class="getStatusClass(event)">
              {{ getStatusText(event) }}
            </div>
          </div>
          
          <div class="event-actions" v-if="isAuthenticated">
            <button 
              v-if="!hasApplied && !isEventCreator" 
              @click="showApplicationModal = true"
              class="btn btn-primary"
              :disabled="isApplicationClosed"
            >
              {{ isApplicationClosed ? '応募締切' : '応募する' }}
            </button>
            
            <button 
              v-if="hasApplied && !isEventCreator" 
              class="btn btn-primary" 
              disabled
            >
              応募済み
            </button>
            
            <router-link 
              v-if="isEventCreator" 
              :to="`/events/${event.id}/edit`" 
              class="btn btn-secondary"
            >
              編集
            </router-link>
          </div>
        </div>

        <!-- イベント画像 -->
        <div v-if="event.images && event.images.length > 0" class="event-images">
          <div class="main-image">
            <img 
              :src="event.images[currentImageIndex].image_url" 
              :alt="event.title"
            />
          </div>
          <div v-if="event.images.length > 1" class="image-thumbnails">
            <img
              v-for="(image, index) in event.images"
              :key="image.id"
              :src="image.image_url"
              :alt="`${event.title} - 画像${index + 1}`"
              :class="{ active: index === currentImageIndex }"
              @click="currentImageIndex = index"
            />
          </div>
        </div>

        <!-- イベント情報 -->
        <div class="event-info">
          <div class="info-grid">
            <div class="info-item">
              <h3>開催日時</h3>
              <p>{{ formatDate(event.schedule_type, event.single_date, event.single_time, event.weekly_day, event.weekly_time, event.biweekly_day, event.biweekly_time, event.biweekly_note, event.monthly_week, event.monthly_day, event.monthly_time, event.irregular_note) }}</p>
            </div>
            
            <div class="info-item">
              <h3>主催者</h3>
              <p>{{ event.profile?.username || 'Unknown' }}</p>
            </div>
            
            <div class="info-item" v-if="event.max_participants">
              <h3>募集人数</h3>
              <p>承認済み: {{ event.applications_count || 0 }} / {{ event.max_participants }}人</p>
            </div>
            
            <div class="info-item" v-if="true">
              <h3>応募締切</h3>
              <p>
                <template v-if="event.application_deadline">
                  {{ formatDateForDeadline(event.application_deadline) }}
                </template>
                <template v-else>
                  未定
                </template>
              </p>
            </div>
          </div>

          <!-- 連絡先情報 -->
          <div class="contact-info">
            <h3>連絡先</h3>
            <div class="contact-links">
              <a 
                v-if="event.twitter_id" 
                :href="`https://twitter.com/${event.twitter_id.replace('@', '')}`" 
                target="_blank"
                class="contact-link twitter"
              >
                <span>🐦</span> {{ event.twitter_id }}
              </a>
              <span v-if="event.discord_id" class="contact-link discord">
                <span>💬</span> {{ event.discord_id }}
              </span>
            </div>
          </div>

          <!-- イベント詳細 -->
          <div class="event-description">
            <h3>イベント詳細</h3>
            <div class="description-content">
              {{ event.description }}
            </div>
          </div>
          <div v-if="!isAuthenticated" class="login-required-message" style="color: #dc3545; font-weight: bold; margin-top: 1.5rem;">
            応募するにはログインしてください
          </div>
        </div>
      </div>
    </div>

    <!-- 応募モーダル -->
    <div v-if="showApplicationModal" class="modal-overlay" @click="showApplicationModal = false">
      <div class="modal-content" @click.stop>
        <h3>イベントに応募</h3>
        <form @submit.prevent="submitApplication">
          <div class="form-group">
            <label>メッセージ（任意）</label>
            <textarea 
              v-model="applicationMessage" 
              rows="4" 
              placeholder="主催者へのメッセージがあれば入力してください..."
              class="form-input"
            ></textarea>
          </div>
          <div class="modal-actions">
            <button type="button" @click="showApplicationModal = false" class="btn btn-secondary">
              キャンセル
            </button>
            <button type="submit" class="btn btn-primary" :disabled="submitting">
              {{ submitting ? '応募中...' : '応募する' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { format } from 'date-fns'
import { ja } from 'date-fns/locale'
import { useToast } from 'vue-toastification'
import { createApplicationNotification } from '@/lib/notifications'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

interface EventImage {
  id: string
  event_id: string
  image_url: string
  created_at: string
}

interface Profile {
  id: string
  username: string
  avatar_url: string
  bio: string
  twitter_id: string
  discord_id: string
  created_at: string
  updated_at: string
}

interface Event {
  id: string
  title: string
  description: string
  schedule_type: string
  single_date: string | null
  single_time: string | null
  weekly_day: string | null
  weekly_time: string | null
  biweekly_day: string | null
  biweekly_time: string | null
  biweekly_note: string | null
  monthly_week: number | null
  monthly_day: string | null
  monthly_time: string | null
  irregular_note: string | null
  max_participants: number | null
  application_deadline: string | null
  twitter_id: string | null
  discord_id: string | null
  user_id: string
  created_at: string
  updated_at: string
  images: EventImage[]
  profile: Profile
  applications_count: number
}

const event = ref<Event | null>(null)
const loading = ref(false)
const currentImageIndex = ref(0)
const showApplicationModal = ref(false)
const applicationMessage = ref('')
const submitting = ref(false)
const applied = ref(false)

const isAuthenticated = computed(() => authStore.isAuthenticated)
const isEventCreator = computed(() => 
  event.value && authStore.user && event.value.user_id === authStore.user.id
)
const hasApplied = computed(() => {
  if (!authStore.user || !event.value) return false
  return applied.value
})
const isApplicationClosed = computed(() => {
  if (!event.value?.application_deadline) return false
  return new Date(event.value.application_deadline) <= new Date()
})

const fetchEvent = async () => {
  loading.value = true
  try {
    // イベント情報を取得
    const { data: eventData, error: eventError } = await supabase
      .from('events')
      .select(`
        *,
        images:event_images(*),
        applications_count:applications(count)
      `)
      .eq('id', route.params.id)
      .single()

    if (eventError) throw eventError

    // プロフィール情報を取得
    let { data: profileData } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', eventData.user_id)
      .single()

    if (!profileData) {
      const { data: newProfile } = await supabase
        .from('profiles')
        .insert({
          id: eventData.user_id,
          username: eventData.user_id.slice(0, 8),
          avatar_url: '',
          bio: '',
          twitter_id: '',
          discord_id: ''
        })
        .select()
        .single()
      profileData = newProfile
    }

    // 応募済み判定
    applied.value = false
    if (authStore.user) {
      const { data: application } = await supabase
        .from('applications')
        .select('id')
        .eq('event_id', eventData.id)
        .eq('user_id', authStore.user.id)
        .maybeSingle()
      applied.value = !!application
    }

    const eventWithCount = {
      ...eventData,
      profile: profileData || {
        id: eventData.user_id,
        username: 'Unknown',
        avatar_url: '',
        bio: '',
        twitter_id: '',
        discord_id: '',
        created_at: '',
        updated_at: ''
      },
      applications_count: 0
    }

    // 承認済みの応募者数を取得
    const { count: approvedCount } = await supabase
      .from('applications')
      .select('*', { count: 'exact', head: true })
      .eq('event_id', eventData.id)
      .eq('status', 'approved')

    eventWithCount.applications_count = approvedCount || 0

    event.value = eventWithCount
  } catch (error) {
    console.error('Error fetching event:', error)
    toast.error('イベントの取得に失敗しました')
  } finally {
    loading.value = false
  }
}

const submitApplication = async () => {
  if (!authStore.user || !event.value || hasApplied.value) return
  submitting.value = true
  try {
    const { error } = await supabase
      .from('applications')
      .insert({
        event_id: event.value.id,
        user_id: authStore.user.id,
        message: applicationMessage.value.trim()
      })

    if (error) throw error

    // 通知を作成
    await createApplicationNotification(
      event.value.id,
      event.value.title,
      authStore.user.email?.split('@')[0] || 'Unknown'
    )

    toast.success('応募が完了しました')
    showApplicationModal.value = false
    applicationMessage.value = ''
    await fetchEvent()
  } catch (error) {
    console.error('Error submitting application:', error)
    toast.error('応募に失敗しました')
  } finally {
    submitting.value = false
  }
}

const formatDate = (scheduleType: string, singleDate?: string | null, singleTime?: string | null, weeklyDay?: string | null, weeklyTime?: string | null, biweeklyDay?: string | null, biweeklyTime?: string | null, biweeklyNote?: string | null, monthlyWeek?: number | null, monthlyDay?: string | null, monthlyTime?: string | null, irregularNote?: string | null) => {
  switch (scheduleType) {
    case 'single':
      if (singleDate && singleTime) {
        const dateTime = `${singleDate}T${singleTime}`
        return format(new Date(dateTime), 'yyyy年MM月dd日 HH:mm', { locale: ja })
      }
      return '日時未定'
    
    case 'weekly':
      if (weeklyDay && weeklyTime) {
        return `毎週${weeklyDay} ${weeklyTime}`
      }
      return '毎週開催（詳細未定）'
    
    case 'biweekly':
      if (biweeklyDay && biweeklyTime) {
        return `隔週${biweeklyDay} ${biweeklyTime}${biweeklyNote ? ` (${biweeklyNote})` : ''}`
      }
      return '隔週開催（詳細未定）'
    
    case 'monthly':
      if (monthlyWeek && monthlyDay && monthlyTime) {
        const weekText = ['', '第1', '第2', '第3', '第4', '第5'][monthlyWeek]
        return `毎月${weekText}${monthlyDay} ${monthlyTime}`
      }
      return '毎月開催（詳細未定）'
    
    case 'irregular':
      return irregularNote || '不定期開催'
    
    default:
      return '日時未定'
  }
}

const formatDateForDeadline = (dateStr: string | null) => {
  if (!dateStr) return '未定'
  try {
    return format(new Date(dateStr), 'yyyy年MM月dd日', { locale: ja })
  } catch {
    return dateStr
  }
}

const getStatusClass = (event: Event) => {
  if (event.application_deadline && new Date(event.application_deadline) <= new Date()) {
    return 'status-closed'
  }
  return 'status-open'
}

const getStatusText = (event: Event) => {
  if (event.application_deadline && new Date(event.application_deadline) <= new Date()) {
    return '締切'
  }
  return '募集中'
}

onMounted(() => {
  fetchEvent()
})
</script>

<style scoped>
.event-detail-page {
  padding: 2rem 0;
}

.container {
  max-width: 1000px;
  margin: 0 auto;
  padding: 0 1rem;
}

.loading, .error {
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

.event-content {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  overflow: hidden;
}

.event-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 2rem;
  border-bottom: 1px solid #e1e5e9;
  gap: 1rem;
}

.event-title-section {
  flex: 1;
}

.event-title-section h1 {
  margin: 0 0 0.5rem 0;
  font-size: 2rem;
  color: #333;
}

.event-status {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-open {
  background: #d4edda;
  color: #155724;
}

.status-closed {
  background: #f8d7da;
  color: #721c24;
}

.event-actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.btn {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  border: none;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
  text-align: center;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #5a6fd8;
  transform: translateY(-2px);
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #5a6268;
  transform: translateY(-2px);
}

.event-images {
  margin-bottom: 2rem;
}

.main-image {
  width: 100%;
  height: 400px;
  overflow: hidden;
  border-radius: 8px;
  margin-bottom: 1rem;
}

.main-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.image-thumbnails {
  display: flex;
  gap: 0.5rem;
  overflow-x: auto;
  padding-bottom: 0.5rem;
}

.image-thumbnails img {
  width: 80px;
  height: 60px;
  object-fit: cover;
  border-radius: 4px;
  cursor: pointer;
  border: 2px solid transparent;
  transition: border-color 0.3s;
}

.image-thumbnails img.active {
  border-color: #667eea;
}

.event-info {
  padding: 2rem;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.info-item h3 {
  margin: 0 0 0.5rem 0;
  color: #333;
  font-size: 1rem;
}

.info-item p {
  margin: 0;
  color: #666;
  font-size: 1.1rem;
}

.contact-info {
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: #f8f9fa;
  border-radius: 8px;
}

.contact-info h3 {
  margin: 0 0 1rem 0;
  color: #333;
}

.contact-links {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.contact-link {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  text-decoration: none;
  color: #333;
  padding: 0.5rem;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.contact-link:hover {
  background: #e9ecef;
}

.contact-link.twitter {
  color: #1da1f2;
}

.contact-link.discord {
  color: #7289da;
}

.event-description h3 {
  margin: 0 0 1rem 0;
  color: #333;
}

.description-content {
  line-height: 1.6;
  color: #666;
  white-space: pre-wrap;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  max-width: 500px;
  width: 90%;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
}

.modal-content h3 {
  margin: 0 0 1.5rem 0;
  color: #333;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #333;
}

.form-input {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
  resize: vertical;
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
}

.modal-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .event-header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .event-actions {
    justify-content: stretch;
  }
  
  .btn {
    flex: 1;
  }
  
  .info-grid {
    grid-template-columns: 1fr;
  }
}
</style> 
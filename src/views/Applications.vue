<template>
  <div class="applications-page">
    <div class="container">
      <div class="page-header">
        <h1>応募管理</h1>
        <router-link to="/events" class="btn btn-secondary">イベント一覧に戻る</router-link>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>読み込み中...</p>
      </div>

      <div v-else-if="myEvents.length === 0" class="no-events">
        <p>あなたが主催するイベントがありません。</p>
        <router-link to="/events/create" class="btn btn-primary">イベントを投稿</router-link>
      </div>

      <div v-else class="events-section">
        <div v-for="event in myEvents" :key="event.id" class="event-card">
          <div class="event-header">
            <h3>
              <router-link :to="`/events/${event.id}`" class="event-title-link">
                {{ event.title }}
              </router-link>
            </h3>
            <div class="event-status" :class="getStatusClass(event)">
              {{ getStatusText(event) }}
            </div>
          </div>
          
          <div class="event-info">
            <p class="event-date">{{ formatDate(event.event_date) }}</p>
            <p class="applications-count" :class="{ 'limit-warning': isLimitWarning(event) }">
              承認済み: {{ event.applications_count || 0 }}人
              <span v-if="event.max_participants">/ {{ event.max_participants }}人</span>
              <span v-if="isLimitWarning(event)" class="warning-text">⚠️ 募集人数に近づいています</span>
            </p>
          </div>

          <div v-if="event.applications && event.applications.length > 0" class="applications-list">
            <h4>応募者一覧</h4>
            <div class="applications-summary">
              <span class="summary-item pending">審査中: {{ event.applications.filter(app => app.status === 'pending').length }}人</span>
              <span class="summary-item approved">承認済み: {{ event.applications.filter(app => app.status === 'approved').length }}人</span>
              <span class="summary-item rejected">却下: {{ event.applications.filter(app => app.status === 'rejected').length }}人</span>
            </div>
            <div v-for="application in event.applications" :key="application.id" class="application-item">
              <div class="application-header">
                <div class="applicant-info">
                  <div class="applicant-profile">
                    <div class="applicant-avatar">
                      <img 
                        v-if="application.profiles?.avatar_url" 
                        :src="application.profiles.avatar_url" 
                        :alt="application.profiles?.username"
                      />
                      <div v-else class="avatar-placeholder">
                        <span>{{ (application.profiles?.username || 'U').charAt(0) }}</span>
                      </div>
                    </div>
                    <div class="applicant-details">
                      <span class="applicant-name">
                        {{ application.profiles?.username || 'Unknown' }}
                      </span>
                      <div class="applicant-contact" v-if="application.profiles?.twitter_id || application.profiles?.discord_id">
                        <a 
                          v-if="application.profiles.twitter_id" 
                          :href="`https://twitter.com/${application.profiles.twitter_id.replace('@', '')}`" 
                          target="_blank"
                          class="contact-link twitter"
                        >
                          🐦 {{ application.profiles.twitter_id }}
                        </a>
                        <span v-if="application.profiles.discord_id" class="contact-link discord">
                          💬 {{ application.profiles.discord_id }}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div class="application-meta">
                    <span class="application-date">{{ formatDate(application.created_at) }}</span>
                    <span class="application-time">{{ formatTime(application.created_at) }}</span>
                  </div>
                </div>
                <div class="application-status" :class="`status-${application.status}`">
                  {{ getStatusTextForApplication(application.status) }}
                </div>
              </div>
              
              <div v-if="application.message" class="application-message">
                <strong>メッセージ:</strong>
                <p>{{ application.message }}</p>
              </div>
              
              <div class="application-actions">
                <div v-if="application.status === 'pending'" class="status-actions">
                  <button @click="updateApplicationStatus(application.id, 'approved')" class="btn btn-success">
                    承認
                  </button>
                  <button @click="updateApplicationStatus(application.id, 'rejected')" class="btn btn-danger">
                    却下
                  </button>
                </div>
                <router-link 
                  :to="`/messages?event=${event.id}&user=${application.user_id}`"
                  class="btn btn-primary"
                >
                  メッセージ
                </router-link>
              </div>
            </div>
          </div>

          <div v-else class="no-applications">
            <p>まだ応募がありません。</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { format } from 'date-fns'
import { ja } from 'date-fns/locale'
import { useToast } from 'vue-toastification'
import { createStatusChangeNotification } from '@/lib/notifications'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

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

interface Application {
  id: string
  event_id: string
  user_id: string
  status: 'pending' | 'approved' | 'rejected'
  message: string
  created_at: string
  updated_at: string
  profiles: Profile
}

interface Event {
  id: string
  title: string
  description: string
  event_date: string
  max_participants: number | null
  application_deadline: string | null
  twitter_id: string | null
  discord_id: string | null
  user_id: string
  created_at: string
  updated_at: string
  applications: Application[]
  applications_count: number
}

const myEvents = ref<Event[]>([])
const loading = ref(false)

const fetchMyEvents = async () => {
  if (!authStore.user) {
    router.push('/login')
    return
  }

  loading.value = true
  try {
    // まずイベントを取得
    const { data: eventsData, error: eventsError } = await supabase
      .from('events')
      .select('*')
      .eq('user_id', authStore.user.id)
      .order('created_at', { ascending: false })

    if (eventsError) throw eventsError

    // 各イベントの応募情報を取得
    const eventsWithApplications = await Promise.all(
      eventsData?.map(async (event) => {
        // 応募情報を取得
        const { data: applicationsData } = await supabase
          .from('applications')
          .select('*')
          .eq('event_id', event.id)

        // 応募者のプロフィール情報を取得
        const applicationsWithProfiles = await Promise.all(
          applicationsData?.map(async (application) => {
            const { data: profileData } = await supabase
              .from('profiles')
              .select('*')
              .eq('id', application.user_id)
              .single()

            return {
              ...application,
              profiles: profileData || {
                id: application.user_id,
                username: 'Unknown',
                avatar_url: '',
                bio: '',
                twitter_id: '',
                discord_id: '',
                created_at: '',
                updated_at: ''
              }
            }
          }) || []
        )

        return {
          ...event,
          applications: applicationsWithProfiles,
          applications_count: applicationsWithProfiles.filter(app => app.status === 'approved').length
        }
      }) || []
    )

    myEvents.value = eventsWithApplications
  } catch (error) {
    console.error('Error fetching events:', error)
    toast.error('イベントの取得に失敗しました')
  } finally {
    loading.value = false
  }
}

const updateApplicationStatus = async (applicationId: string, status: 'approved' | 'rejected') => {
  try {
    const { error } = await supabase
      .from('applications')
      .update({ status })
      .eq('id', applicationId)

    if (error) throw error

    // 応募者とイベント情報を取得して通知を作成
    const { data: application } = await supabase
      .from('applications')
      .select(`
        *,
        events!applications_event_id_fkey(title)
      `)
      .eq('id', applicationId)
      .single()

    if (application) {
      await createStatusChangeNotification(
        applicationId,
        application.events.title,
        status,
        application.user_id
      )
    }

    toast.success(`応募を${status === 'approved' ? '承認' : '却下'}しました`)
    
    // イベント情報を再取得
    await fetchMyEvents()
  } catch (error) {
    console.error('Error updating application:', error)
    toast.error('ステータス更新に失敗しました')
  }
}

const formatDate = (dateString: string) => {
  return format(new Date(dateString), 'yyyy年MM月dd日 HH:mm', { locale: ja })
}

const formatTime = (dateString: string) => {
  return format(new Date(dateString), 'HH:mm', { locale: ja })
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

const getStatusTextForApplication = (status: string) => {
  switch (status) {
    case 'pending': return '審査中'
    case 'approved': return '承認済み'
    case 'rejected': return '却下'
    default: return status
  }
}

const isLimitWarning = (event: Event) => {
  if (!event.max_participants || !event.applications_count) return false
  return event.applications_count >= Math.floor(event.max_participants * 0.8)
}

onMounted(() => {
  fetchMyEvents()
})
</script>

<style scoped>
.applications-page {
  padding: 2rem 0;
}

.container {
  max-width: 1000px;
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

.loading, .no-events {
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

.events-section {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.event-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  padding: 2rem;
}

.event-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.event-header h3 {
  margin: 0;
  font-size: 1.5rem;
  color: #333;
}

.event-status {
  display: inline-block;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 500;
  font-size: 0.875rem;
}

.status-open {
  background-color: #d4edda;
  color: #155724;
}

.status-closed {
  background-color: #f8d7da;
  color: #721c24;
}

.event-info {
  display: flex;
  gap: 2rem;
  margin-bottom: 1.5rem;
  color: #666;
}

.event-date, .applications-count {
  margin: 0;
}

.applications-list h4 {
  margin: 0 0 1rem 0;
  font-size: 1.25rem;
  color: #333;
}

.applications-summary {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  padding: 0.75rem;
  background-color: #f8f9fa;
  border-radius: 8px;
}

.summary-item {
  font-size: 0.875rem;
  font-weight: 500;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
}

.summary-item.pending {
  background-color: #fff3cd;
  color: #856404;
}

.summary-item.approved {
  background-color: #d4edda;
  color: #155724;
}

.summary-item.rejected {
  background-color: #f8d7da;
  color: #721c24;
}

.application-item {
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  padding: 1rem;
  margin-bottom: 1rem;
  background-color: #f8f9fa;
}

.application-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 0.5rem;
}

.applicant-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.applicant-profile {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.applicant-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  overflow: hidden;
}

.avatar-placeholder {
  width: 40px;
  height: 40px;
  background-color: #f0f0f0;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
}

.applicant-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.applicant-name {
  font-weight: 500;
  color: #333;
}

.applicant-contact {
  display: flex;
  gap: 0.5rem;
}

.contact-link {
  color: #666;
  text-decoration: none;
}

.contact-link:hover {
  text-decoration: underline;
}

.application-meta {
  display: flex;
  gap: 0.5rem;
  color: #666;
}

.application-status {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.875rem;
  font-weight: 500;
}

.status-pending {
  background-color: #fff3cd;
  color: #856404;
}

.status-approved {
  background-color: #d4edda;
  color: #155724;
}

.status-rejected {
  background-color: #f8d7da;
  color: #721c24;
}

.application-message {
  margin: 1rem 0;
  padding: 0.75rem;
  background-color: white;
  border-radius: 4px;
}

.application-message strong {
  color: #333;
}

.application-message p {
  margin: 0.5rem 0 0 0;
  color: #555;
  line-height: 1.5;
}

.application-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
  align-items: center;
}

.status-actions {
  display: flex;
  gap: 0.5rem;
}

.no-applications {
  text-align: center;
  padding: 2rem;
  color: #666;
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

.btn-primary {
  background-color: #667eea;
  color: white;
}

.btn-primary:hover {
  background-color: #5a6fd8;
}

.btn-secondary {
  background-color: #f0f0f0;
  color: #333;
}

.btn-secondary:hover {
  background-color: #e1e5e9;
}

.btn-success {
  background-color: #28a745;
  color: white;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
}

.btn-success:hover {
  background-color: #218838;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
}

.btn-danger:hover {
  background-color: #c82333;
}

.warning-text {
  color: #dc3545;
  font-weight: 500;
}

.applications-count {
  margin: 0;
}

.limit-warning {
  color: #dc3545;
  font-weight: 500;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .event-header {
    flex-direction: column;
    gap: 1rem;
  }
  
  .event-info {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .application-header {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .application-actions {
    flex-direction: column;
  }
}
</style> 
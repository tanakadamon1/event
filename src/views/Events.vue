<template>
  <div class="events-page">
    <div class="container">
      <div class="page-header">
        <h1>イベント一覧</h1>
        <router-link v-if="isAuthenticated" to="/events/create" class="btn btn-primary">
          イベントを投稿
        </router-link>
      </div>

      <!-- 検索・フィルター -->
      <div class="search-filters">
        <div class="search-box">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="イベント名や詳細を検索..."
            class="search-input"
          />
        </div>
        
        <div class="filters">
          <div class="filter-group">
            <label>並び順:</label>
            <select v-model="sortBy" class="filter-select">
              <option value="created_at_desc">新着順</option>
              <option value="created_at_asc">古い順</option>
              <option value="event_date_asc">開催日時順（近い順）</option>
              <option value="event_date_desc">開催日時順（遠い順）</option>
            </select>
          </div>
          
          <div class="filter-group">
            <label>募集状況:</label>
            <select v-model="statusFilter" class="filter-select">
              <option value="">すべて</option>
              <option value="open">募集中</option>
              <option value="closed">締切</option>
            </select>
          </div>
        </div>
      </div>

      <!-- イベント一覧 -->
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>読み込み中...</p>
      </div>

      <div v-else-if="filteredEvents.length === 0" class="no-events">
        <p>イベントが見つかりませんでした。</p>
      </div>

      <div v-else class="events-grid">
        <div
          v-for="event in paginatedEvents"
          :key="event.id"
          class="event-card"
          @click="goToEvent(event.id)"
        >
          <div class="event-image">
            <img
              v-if="event.images && event.images.length > 0 && event.images[0].image_url"
              :src="event.images[0].image_url"
              :alt="event.title"
            />
            <div v-else class="event-placeholder">
              <span>📅</span>
            </div>
            <div class="event-status" :class="getStatusClass(event)">
              {{ getStatusText(event) }}
            </div>
          </div>
          
          <div class="event-content">
            <h3 class="event-title">{{ event.title }}</h3>
            <p class="event-date">{{ formatEventDate(event) }}</p>
            <p class="event-description">{{ truncateText(event.description, 120) }}</p>
            
            <div class="event-meta">
              <div class="event-organizer">
                <span>主催者: {{ event.profile?.username || 'Unknown' }}</span>
              </div>
              <div class="event-applications">
                <span>承認済み: {{ event.applications_count || 0 }}人</span>
                <span v-if="event.max_participants">
                  / {{ event.max_participants }}人
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ページネーション -->
      <div v-if="totalPages > 1" class="pagination">
        <button
          @click="currentPage--"
          :disabled="currentPage === 1"
          class="pagination-btn"
        >
          前へ
        </button>
        
        <span class="pagination-info">
          {{ currentPage }} / {{ totalPages }}
        </span>
        
        <button
          @click="currentPage++"
          :disabled="currentPage === totalPages"
          class="pagination-btn"
        >
          次へ
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { format } from 'date-fns'
import { ja } from 'date-fns/locale'

const router = useRouter()
const authStore = useAuthStore()

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

const events = ref<Event[]>([])
const loading = ref(false)
const searchQuery = ref('')
const sortBy = ref('created_at_desc')
const statusFilter = ref('')
const currentPage = ref(1)
const itemsPerPage = 12

const isAuthenticated = computed(() => authStore.isAuthenticated)

const fetchEvents = async () => {
  loading.value = true
  try {
    // イベント情報を取得
    const { data: eventsData, error: eventsError } = await supabase
      .from('events')
      .select(`
        *,
        images:event_images(*),
        applications_count:applications(count)
      `)
      .order('created_at', { ascending: false })

    if (eventsError) throw eventsError

    // 各イベントのプロフィール情報と承認済み応募者数を取得
    const eventsWithProfiles = await Promise.all(
      eventsData?.map(async (event) => {
        let { data: profileData } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', event.user_id)
          .single()

        // プロフィールが存在しない場合は作成
        if (!profileData) {
          const { data: newProfile } = await supabase
            .from('profiles')
            .insert({
              id: event.user_id,
              username: event.user_id.slice(0, 8),
              avatar_url: '',
              bio: '',
              twitter_id: '',
              discord_id: ''
            })
            .select()
            .single()
          
          profileData = newProfile
        }

        // 承認済みの応募者数を取得
        const { count: approvedCount } = await supabase
          .from('applications')
          .select('*', { count: 'exact', head: true })
          .eq('event_id', event.id)
          .eq('status', 'approved')

        return {
          ...event,
          profile: profileData || {
            id: event.user_id,
            username: 'Unknown',
            avatar_url: '',
            bio: '',
            twitter_id: '',
            discord_id: '',
            created_at: '',
            updated_at: ''
          },
          applications_count: approvedCount || 0
        }
      }) || []
    )

    events.value = eventsWithProfiles
  } catch (error) {
    console.error('Error fetching events:', error)
  } finally {
    loading.value = false
  }
}

const filteredEvents = computed(() => {
  let filtered = events.value

  // 検索クエリでフィルター
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(event =>
      event.title.toLowerCase().includes(query) ||
      event.description.toLowerCase().includes(query)
    )
  }

  // 募集状況でフィルター
  if (statusFilter.value) {
    const now = new Date()
    filtered = filtered.filter(event => {
      if (statusFilter.value === 'open') {
        return !event.application_deadline || new Date(event.application_deadline) > now
      } else {
        return event.application_deadline && new Date(event.application_deadline) <= now
      }
    })
  }

  // ソート
  filtered.sort((a, b) => {
    switch (sortBy.value) {
      case 'created_at_desc':
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      case 'created_at_asc':
        return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
      case 'event_date_asc':
        return getEventDate(a).getTime() - getEventDate(b).getTime()
      case 'event_date_desc':
        return getEventDate(b).getTime() - getEventDate(a).getTime()
      default:
        return 0
    }
  })

  return filtered
})

const totalPages = computed(() => Math.ceil(filteredEvents.value.length / itemsPerPage))

const paginatedEvents = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  const end = start + itemsPerPage
  return filteredEvents.value.slice(start, end)
})

const goToEvent = (eventId: string) => {
  router.push(`/events/${eventId}`)
}

const getEventDate = (event: Event): Date => {
  switch (event.schedule_type) {
    case 'single':
      if (event.single_date && event.single_time) {
        return new Date(`${event.single_date}T${event.single_time}`)
      }
      return new Date(event.created_at)
    default:
      return new Date(event.created_at)
  }
}

const formatEventDate = (event: Event) => {
  switch (event.schedule_type) {
    case 'single':
      if (event.single_date && event.single_time) {
        const dateTime = `${event.single_date}T${event.single_time}`
        return format(new Date(dateTime), 'yyyy年MM月dd日 HH:mm', { locale: ja })
      }
      return '日時未定'
    
    case 'weekly':
      if (event.weekly_day && event.weekly_time) {
        return `毎週${event.weekly_day} ${event.weekly_time}`
      }
      return '毎週開催（詳細未定）'
    
    case 'biweekly':
      if (event.biweekly_day && event.biweekly_time) {
        return `隔週${event.biweekly_day} ${event.biweekly_time}${event.biweekly_note ? ` (${event.biweekly_note})` : ''}`
      }
      return '隔週開催（詳細未定）'
    
    case 'monthly':
      if (event.monthly_week && event.monthly_day && event.monthly_time) {
        const weekText = ['', '第1', '第2', '第3', '第4', '第5'][event.monthly_week]
        return `毎月${weekText}${event.monthly_day} ${event.monthly_time}`
      }
      return '毎月開催（詳細未定）'
    
    case 'irregular':
      return event.irregular_note || '不定期開催'
    
    default:
      return '日時未定'
  }
}

const truncateText = (text: string, maxLength: number) => {
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
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

// フィルター変更時にページをリセット
watch([searchQuery, sortBy, statusFilter], () => {
  currentPage.value = 1
})

onMounted(() => {
  fetchEvents()
})
</script>

<style scoped>
.events-page {
  padding: 2rem 0;
}

.container {
  max-width: 1200px;
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
  font-size: 2.5rem;
  color: #333;
  margin: 0;
}

.btn {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  text-decoration: none;
  font-weight: 500;
  transition: all 0.3s;
  border: none;
  cursor: pointer;
}

.btn-primary {
  background-color: #667eea;
  color: white;
}

.btn-primary:hover {
  background-color: #5a6fd8;
  transform: translateY(-2px);
}

.search-filters {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

.search-box {
  margin-bottom: 1rem;
}

.search-input {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.search-input:focus {
  outline: none;
  border-color: #667eea;
}

.filters {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.filter-group label {
  font-weight: 500;
  color: #333;
  white-space: nowrap;
}

.filter-select {
  padding: 0.5rem;
  border: 2px solid #e1e5e9;
  border-radius: 6px;
  background: white;
  font-size: 0.9rem;
}

.loading {
  text-align: center;
  padding: 3rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.no-events {
  text-align: center;
  padding: 3rem;
  color: #666;
}

.events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 2rem;
  margin-bottom: 2rem;
}

.event-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s;
  cursor: pointer;
}

.event-card:hover {
  transform: translateY(-5px);
}

.event-image {
  aspect-ratio: 16/9;
  overflow: hidden;
  position: relative;
}

.event-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.event-placeholder {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 3rem;
}

.event-status {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

.status-open {
  background-color: #28a745;
  color: white;
}

.status-closed {
  background-color: #dc3545;
  color: white;
}

.event-content {
  padding: 1.5rem;
}

.event-title {
  font-size: 1.25rem;
  font-weight: bold;
  margin-bottom: 0.5rem;
  color: #333;
}

.event-date {
  color: #667eea;
  font-weight: 500;
  margin-bottom: 0.5rem;
}

.event-description {
  color: #666;
  margin-bottom: 1rem;
  line-height: 1.5;
}

.event-meta {
  display: flex;
  justify-content: space-between;
  margin-bottom: 1rem;
  font-size: 0.875rem;
  color: #666;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  margin-top: 2rem;
}

.pagination-btn {
  padding: 0.5rem 1rem;
  border: 2px solid #667eea;
  background: white;
  color: #667eea;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s;
}

.pagination-btn:hover:not(:disabled) {
  background: #667eea;
  color: white;
}

.pagination-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination-info {
  font-weight: 500;
  color: #333;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }
  
  .page-header h1 {
    font-size: 2rem;
  }
  
  .filters {
    flex-direction: column;
  }
  
  .filter-group {
    justify-content: space-between;
  }
  
  .events-grid {
    grid-template-columns: 1fr;
  }
}
</style> 
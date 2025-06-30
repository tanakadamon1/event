<template>
  <div class="edit-event-page">
    <div class="container">
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>読み込み中...</p>
      </div>

      <div v-else-if="!event" class="error">
        <p>イベントが見つかりませんでした。</p>
        <router-link to="/events" class="btn btn-secondary">イベント一覧に戻る</router-link>
      </div>

      <div v-else class="edit-content">
        <div class="page-header">
          <h1>イベント編集</h1>
          <router-link to="/events" class="btn btn-secondary">キャンセル</router-link>
        </div>

        <form @submit.prevent="updateEvent" class="event-form">
          <div class="form-group">
            <label>イベント名 <span class="required-asterisk">*</span></label>
            <input v-model="form.title" type="text" required class="form-input" />
          </div>
          
          <div class="form-group">
            <label>イベント詳細 <span class="required-asterisk">*</span></label>
            <textarea v-model="form.description" required rows="5" class="form-input"></textarea>
          </div>
          
          <div class="form-group">
            <label>開催パターン <span class="required-asterisk">*</span></label>
            <select v-model="form.schedule_type" required class="form-input">
              <option value="single">単発</option>
              <option value="weekly">毎週</option>
              <option value="biweekly">隔週</option>
              <option value="monthly">毎月</option>
              <option value="irregular">不定期</option>
            </select>
          </div>
          <div v-if="form.schedule_type === 'single'" class="form-group">
            <label>開催日 <span class="required-asterisk">*</span></label>
            <input v-model="form.single_date" type="date" class="form-input" required />
            <label>開始時刻 <span class="required-asterisk">*</span></label>
            <input v-model="form.single_time" type="time" class="form-input" required />
          </div>
          <div v-else-if="form.schedule_type === 'weekly'" class="form-group">
            <label>曜日 <span class="required-asterisk">*</span></label>
            <select v-model="form.weekly_day" class="form-input" required>
              <option value="月">月</option>
              <option value="火">火</option>
              <option value="水">水</option>
              <option value="木">木</option>
              <option value="金">金</option>
              <option value="土">土</option>
              <option value="日">日</option>
            </select>
            <label>開始時刻 <span class="required-asterisk">*</span></label>
            <input v-model="form.weekly_time" type="time" class="form-input" required />
          </div>
          <div v-else-if="form.schedule_type === 'biweekly'" class="form-group">
            <label>曜日 <span class="required-asterisk">*</span></label>
            <select v-model="form.biweekly_day" class="form-input" required>
              <option value="月">月</option>
              <option value="火">火</option>
              <option value="水">水</option>
              <option value="木">木</option>
              <option value="金">金</option>
              <option value="土">土</option>
              <option value="日">日</option>
            </select>
            <label>開始時刻 <span class="required-asterisk">*</span></label>
            <input v-model="form.biweekly_time" type="time" class="form-input" required />
            <label>備考（例：第1・第3週など）</label>
            <input v-model="form.biweekly_note" type="text" class="form-input" placeholder="例：第1・第3週" />
          </div>
          <div v-else-if="form.schedule_type === 'monthly'" class="form-group">
            <label>第何週 <span class="required-asterisk">*</span></label>
            <select v-model="form.monthly_week" class="form-input" required>
              <option value="1">第1</option>
              <option value="2">第2</option>
              <option value="3">第3</option>
              <option value="4">第4</option>
              <option value="5">第5</option>
            </select>
            <label>曜日 <span class="required-asterisk">*</span></label>
            <select v-model="form.monthly_day" class="form-input" required>
              <option value="月">月</option>
              <option value="火">火</option>
              <option value="水">水</option>
              <option value="木">木</option>
              <option value="金">金</option>
              <option value="土">土</option>
              <option value="日">日</option>
            </select>
            <label>開始時刻 <span class="required-asterisk">*</span></label>
            <input v-model="form.monthly_time" type="time" class="form-input" required />
          </div>
          <div v-else-if="form.schedule_type === 'irregular'" class="form-group">
            <label>備考</label>
            <input v-model="form.irregular_note" type="text" class="form-input" placeholder="例：都度Twitterで告知" required />
          </div>
          
          <div class="form-group">
            <label>募集人数</label>
            <input v-model.number="form.max_participants" type="number" min="1" class="form-input" />
          </div>
          
          <div class="form-group">
            <label>募集締切日</label>
            <input v-model="form.application_deadline" type="date" class="form-input" />
          </div>

          <!-- 既存の画像 -->
          <div class="form-group">
            <label>現在の画像</label>
            <div class="current-images">
              <div v-for="(image, index) in event.images" :key="image.id" class="current-image">
                <img :src="image.image_url" alt="event image" />
                <button type="button" @click="removeExistingImage(image.id)" class="remove-btn">削除</button>
              </div>
            </div>
          </div>

          <!-- 新しい画像の追加 -->
          <div class="form-group">
            <label>新しい画像（最大5枚, 5MB/枚, JPEG/PNG/WebP）</label>
            <input type="file" multiple accept="image/jpeg,image/png,image/webp" @change="handleImageChange" />
            <div class="image-preview-list">
              <div v-for="(img, i) in imagePreviews" :key="i" class="image-preview">
                <img :src="img" alt="preview" />
                <button type="button" @click="removeImage(i)">削除</button>
              </div>
            </div>
          </div>
          
          <div class="form-group">
            <label>Twitter ID <span class="required-asterisk">*</span></label>
            <input v-model="form.twitter_id" type="text" class="form-input" placeholder="@example" />
          </div>
          
          <div class="form-actions">
            <button type="submit" class="btn btn-primary" :disabled="submitting">
              {{ submitting ? '更新中...' : 'イベントを更新' }}
            </button>
            <button type="button" @click="deleteEvent" class="btn btn-danger" :disabled="submitting">
              イベントを削除
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { useToast } from 'vue-toastification'

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

interface MyEvent {
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
}

const event = ref<MyEvent | null>(null)
const loading = ref(false)
const submitting = ref(false)
const imagePreviews = ref<string[]>([])

const form = reactive({
  title: '',
  description: '',
  schedule_type: 'single',
  single_date: '',
  single_time: '',
  weekly_day: '',
  weekly_time: '',
  biweekly_day: '',
  biweekly_time: '',
  biweekly_note: '',
  monthly_week: null as number | null,
  monthly_day: '',
  monthly_time: '',
  irregular_note: '',
  max_participants: null as number | null,
  application_deadline: '',
  images: [] as File[],
  twitter_id: '',
  discord_id: ''
})

const fetchEvent = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('events')
      .select(`
        *,
        images:event_images(*)
      `)
      .eq('id', route.params.id)
      .single()

    if (error) throw error

    // 権限チェック
    if (data.user_id !== authStore.user?.id) {
      toast.error('このイベントを編集する権限がありません')
      router.push('/events')
      return
    }

    event.value = data

    // フォームにデータを設定
    form.title = data.title
    form.description = data.description
    form.schedule_type = data.schedule_type || 'single'
    form.single_date = data.single_date || ''
    form.single_time = data.single_time || ''
    form.weekly_day = data.weekly_day || ''
    form.weekly_time = data.weekly_time || ''
    form.biweekly_day = data.biweekly_day || ''
    form.biweekly_time = data.biweekly_time || ''
    form.biweekly_note = data.biweekly_note || ''
    form.monthly_week = data.monthly_week || ''
    form.monthly_day = data.monthly_day || ''
    form.monthly_time = data.monthly_time || ''
    form.irregular_note = data.irregular_note || ''
    form.max_participants = data.max_participants || undefined
    form.application_deadline = data.application_deadline || ''
    form.twitter_id = data.twitter_id || ''
    form.discord_id = data.discord_id || ''
  } catch (error) {
    console.error('Error fetching event:', error)
    toast.error('イベントの取得に失敗しました')
  } finally {
    loading.value = false
  }
}

const handleImageChange = (e: globalThis.Event) => {
  const files = (e.target as HTMLInputElement).files
  if (!files) return
  
  const currentImageCount = event.value?.images?.length || 0
  if (files.length + form.images.length + currentImageCount > 5) {
    toast.error('画像は最大5枚までです')
    return
  }
  
  for (const file of Array.from(files)) {
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      toast.error('JPEG/PNG/WebP形式のみ対応')
      continue
    }
    if (file.size > 5 * 1024 * 1024) {
      toast.error('画像サイズは5MB以下にしてください')
      continue
    }
    form.images.push(file)
    const reader = new FileReader()
    reader.onload = (ev) => {
      imagePreviews.value.push(ev.target?.result as string)
    }
    reader.readAsDataURL(file)
  }
}

const removeImage = (i: number) => {
  form.images.splice(i, 1)
  imagePreviews.value.splice(i, 1)
}

const removeExistingImage = async (imageId: string) => {
  if (!confirm('この画像を削除しますか？')) return
  
  try {
    const { error } = await supabase
      .from('event_images')
      .delete()
      .eq('id', imageId)

    if (error) throw error

    toast.success('画像を削除しました')
    await fetchEvent() // イベント情報を再取得
  } catch (error) {
    console.error('Error removing image:', error)
    toast.error('画像の削除に失敗しました')
  }
}

const updateEvent = async () => {
  if (!event.value) return
  
  if (!form.title.trim() || !form.description.trim() || !form.schedule_type) {
    toast.error('必須項目を入力してください')
    return
  }
  
  if (!form.twitter_id.trim()) {
    toast.error('Twitter IDを入力してください')
    return
  }
  
  submitting.value = true
  try {
    // time型カラムの空文字をnullに変換
    const patchData = {
      title: form.title.trim(),
      description: form.description.trim(),
      schedule_type: form.schedule_type,
      single_date: form.single_date,
      single_time: form.single_time === '' ? null : form.single_time,
      weekly_day: form.weekly_day,
      weekly_time: form.weekly_time === '' ? null : form.weekly_time,
      biweekly_day: form.biweekly_day,
      biweekly_time: form.biweekly_time === '' ? null : form.biweekly_time,
      biweekly_note: form.biweekly_note,
      monthly_week: form.monthly_week === null ? null : Number(form.monthly_week),
      monthly_day: form.monthly_day,
      monthly_time: form.monthly_time === '' ? null : form.monthly_time,
      irregular_note: form.irregular_note,
      max_participants: form.max_participants === null ? null : Number(form.max_participants),
      application_deadline: form.application_deadline || null,
      twitter_id: form.twitter_id
    }
    // 1. イベント情報を更新
    const { error: updateError } = await supabase
      .from('events')
      .update(patchData)
      .eq('id', event.value.id)

    if (updateError) throw updateError

    // 2. 新しい画像をアップロード
    for (const file of form.images) {
      const ext = file.name.split('.').pop()
      const fileName = `${event.value.id}-${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`
      const { error: uploadError } = await supabase.storage
        .from('event-images')
        .upload(fileName, file, {
          upsert: true,
          contentType: file.type
        })
      if (uploadError) throw uploadError
      
      const { data } = supabase.storage.from('event-images').getPublicUrl(fileName)
      await supabase.from('event_images').insert({ 
        event_id: event.value.id, 
        image_url: data.publicUrl 
      })
    }

    toast.success('イベントを更新しました')
    router.push(`/events/${event.value.id}`)
  } catch (error) {
    console.error('Error updating event:', error)
    toast.error('イベントの更新に失敗しました')
  } finally {
    submitting.value = false
  }
}

const deleteEvent = async () => {
  if (!event.value) return
  
  if (!confirm('このイベントを削除しますか？この操作は取り消せません。')) return
  
  submitting.value = true
  try {
    const { error } = await supabase
      .from('events')
      .delete()
      .eq('id', event.value.id)

    if (error) throw error

    toast.success('イベントを削除しました')
    router.push('/events')
  } catch (error) {
    console.error('Error deleting event:', error)
    toast.error('イベントの削除に失敗しました')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  fetchEvent()
})
</script>

<style scoped>
.edit-event-page {
  padding: 2rem 0;
}

.container {
  max-width: 800px;
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

.edit-content {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  padding: 2rem;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  margin: 0;
  font-size: 2rem;
  color: #333;
}

.event-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-weight: 500;
  color: #333;
}

.form-input {
  padding: 0.75rem;
  border: 1.5px solid #e1e5e9;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
}

.current-images {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.current-image {
  position: relative;
  width: 120px;
  height: 120px;
  border-radius: 8px;
  overflow: hidden;
}

.current-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.remove-btn {
  position: absolute;
  top: 4px;
  right: 4px;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 0.25rem 0.5rem;
  font-size: 0.8rem;
  cursor: pointer;
}

.image-preview-list {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  margin-top: 0.5rem;
}

.image-preview {
  position: relative;
  width: 80px;
  height: 80px;
  border-radius: 8px;
  overflow: hidden;
  background: #f8f9fa;
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.image-preview button {
  position: absolute;
  top: 2px;
  right: 2px;
  background: #dc3545;
  color: #fff;
  border: none;
  border-radius: 4px;
  font-size: 0.8rem;
  padding: 0.2rem 0.5rem;
  cursor: pointer;
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

.btn-primary:hover:not(:disabled) {
  background-color: #5a6fd8;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  background-color: #f0f0f0;
  color: #333;
}

.btn-secondary:hover {
  background-color: #e1e5e9;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background-color: #c82333;
}

.btn-danger:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1rem;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .form-actions {
    flex-direction: column;
  }
}

.required-asterisk { color: #e53935; font-weight: bold; }
</style> 
<template>
  <div class="create-event-page">
    <div class="container">
      <h1>イベント投稿</h1>
      <form @submit.prevent="submitEvent" class="event-form">
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
        <div class="form-group">
          <label>画像（最大5枚, 5MB/枚, JPEG/PNG/WebP）</label>
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
          <button type="submit" class="btn btn-primary" :disabled="loading">
            {{ loading ? '投稿中...' : 'イベントを投稿' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { useToast } from 'vue-toastification'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()
const loading = ref(false)

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
  monthly_week: '',
  monthly_day: '',
  monthly_time: '',
  irregular_note: '',
  max_participants: null as number | null,
  application_deadline: '',
  images: [] as File[],
  twitter_id: '',
  discord_id: ''
})

const imagePreviews = ref<string[]>([])

const handleImageChange = (e: Event) => {
  const files = (e.target as HTMLInputElement).files
  if (!files) return
  if (files.length + form.images.length > 5) {
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

function cleanInsertData(obj: Record<string, any>) {
  const cleaned: Record<string, any> = {};
  for (const key in obj) {
    cleaned[key] = obj[key] === "" || obj[key] === undefined ? null : obj[key];
  }
  return cleaned;
}

const submitEvent = async () => {
  if (!authStore.user) {
    toast.error('ログインしてください')
    return
  }
  if (!form.title.trim() || !form.description.trim()) {
    toast.error('必須項目を入力してください')
    return
  }
  if (!form.twitter_id.trim()) {
    toast.error('Twitter IDを入力してください')
    return
  }
  loading.value = true
  try {
    const insertData = cleanInsertData({
      title: form.title.trim(),
      description: form.description.trim(),
      schedule_type: form.schedule_type,
      single_date: form.single_date,
      single_time: form.single_time,
      weekly_day: form.weekly_day,
      weekly_time: form.weekly_time,
      biweekly_day: form.biweekly_day,
      biweekly_time: form.biweekly_time,
      biweekly_note: form.biweekly_note,
      monthly_week: form.monthly_week,
      monthly_day: form.monthly_day,
      monthly_time: form.monthly_time,
      irregular_note: form.irregular_note,
      max_participants: form.max_participants,
      application_deadline: form.application_deadline,
      twitter_id: form.twitter_id,
      user_id: authStore.user.id
    });
    console.log('event insert:', insertData);
    const { data: event, error } = await supabase
      .from('events')
      .insert(insertData)
      .select()
      .single()
    if (error) throw error
    // 2. 画像アップロード
    let imageUrls: string[] = []
    for (const file of form.images) {
      const ext = file.name.split('.').pop()
      const fileName = `${event.id}-${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`
      const { error: uploadError } = await supabase.storage
        .from('event-images')
        .upload(fileName, file, {
          upsert: true,
          contentType: file.type
        })
      if (uploadError) throw uploadError
      const { data } = supabase.storage.from('event-images').getPublicUrl(fileName)
      imageUrls.push(data.publicUrl)
    }
    // 3. event_imagesテーブルにinsert
    for (const url of imageUrls) {
      await supabase.from('event_images').insert({ event_id: event.id, image_url: url })
    }
    toast.success('イベントを投稿しました')
    router.push(`/events/${event.id}`)
  } catch (e) {
    console.error(e)
    toast.error('イベント投稿に失敗しました')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  if (authStore.user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('twitter_id')
      .eq('id', authStore.user.id)
      .single()
    if (profile && profile.twitter_id) {
      form.twitter_id = profile.twitter_id
    }
  }
})
</script>

<style scoped>
.create-event-page {
  padding: 2rem 0;
}
.container {
  max-width: 600px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  padding: 2rem 1.5rem;
}
h1 {
  text-align: center;
  margin-bottom: 2rem;
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
}
.btn-primary {
  background-color: #667eea;
  color: white;
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
.form-actions {
  display: flex;
  justify-content: center;
  margin-top: 1rem;
}
.required-asterisk { color: #e53935; font-weight: bold; }
</style> 
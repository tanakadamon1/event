<template>
  <div class="profile-page">
    <div class="container">
      <div class="profile-header">
        <h1>プロフィール設定</h1>
      </div>

      <div class="profile-content">
        <div class="profile-card">
          <form @submit.prevent="updateProfile" class="profile-form">
            <div class="form-group">
              <label for="username">ユーザー名 *</label>
              <input
                id="username"
                v-model="formData.username"
                type="text"
                placeholder="ユーザー名を入力"
                class="form-input"
                :class="{ error: errors.username }"
              />
              <span v-if="errors.username" class="error-message">
                {{ errors.username }}
              </span>
            </div>

            <div class="form-group">
              <label for="bio">自己紹介</label>
              <textarea
                id="bio"
                v-model="formData.bio"
                rows="4"
                placeholder="自己紹介を入力（任意）"
                class="form-input"
              ></textarea>
            </div>

            <div class="form-group">
              <label for="twitter_id">Twitter ID</label>
              <input
                id="twitter_id"
                v-model="formData.twitter_id"
                type="text"
                placeholder="@example"
                class="form-input"
              />
            </div>

            <div class="form-actions">
              <button
                type="submit"
                :disabled="loading"
                class="btn btn-primary"
              >
                {{ loading ? '更新中...' : 'プロフィールを更新' }}
              </button>
              <button
                type="button"
                @click="resetForm"
                class="btn btn-secondary"
              >
                リセット
              </button>
            </div>
          </form>
        </div>

        <div class="profile-stats">
          <h3>統計情報</h3>
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-number">{{ userStats.createdEvents }}</div>
              <div class="stat-label">投稿したイベント</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">{{ userStats.appliedEvents }}</div>
              <div class="stat-label">応募したイベント</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { useToast } from 'vue-toastification'

const authStore = useAuthStore()
const toast = useToast()

const user = computed(() => authStore.user)
const loading = ref(false)

interface ProfileData {
  id: string
  username: string
  bio: string
  twitter_id: string
  discord_id: string
  created_at: string
  updated_at: string
}

const profileData = ref<ProfileData>({
  id: '',
  username: '',
  bio: '',
  twitter_id: '',
  discord_id: '',
  created_at: '',
  updated_at: ''
})

const formData = reactive({
  username: '',
  bio: '',
  twitter_id: '',
  discord_id: ''
})

const errors = reactive({
  username: ''
})

const userStats = reactive({
  createdEvents: 0,
  appliedEvents: 0
})

const fetchProfile = async () => {
  if (!user.value) return

  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.value.id)
      .single()

    if (error && error.code !== 'PGRST116') {
      throw error
    }

    if (data) {
      profileData.value = data
      initializeForm()
    } else {
      // プロフィールが存在しない場合は作成
      await createProfile()
    }
  } catch (error) {
    console.error('Error fetching profile:', error)
    toast.error('プロフィールの取得に失敗しました')
  }
}

const createProfile = async () => {
  if (!user.value) return

  try {
    const { data, error } = await supabase
      .from('profiles')
      .insert({
        id: user.value.id,
        username: '',
        bio: '',
        twitter_id: '',
        discord_id: ''
      })
      .select()
      .single()

    if (error) throw error

    profileData.value = data
    initializeForm()
  } catch (error) {
    console.error('Error creating profile:', error)
    toast.error('プロフィールの作成に失敗しました')
  }
}

const fetchUserStats = async () => {
  if (!user.value) return

  try {
    // 作成したイベント数
    const { count: createdCount } = await supabase
      .from('events')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.value.id)

    // 応募したイベント数
    const { count: appliedCount } = await supabase
      .from('applications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.value.id)

    userStats.createdEvents = createdCount || 0
    userStats.appliedEvents = appliedCount || 0
  } catch (error) {
    console.error('Error fetching user stats:', error)
  }
}

const initializeForm = () => {
  formData.username = profileData.value.username || ''
  formData.bio = profileData.value.bio || ''
  formData.twitter_id = profileData.value.twitter_id || ''
  formData.discord_id = profileData.value.discord_id || ''
}

const validateForm = () => {
  errors.username = ''
  
  if (!formData.username.trim()) {
    errors.username = 'ユーザー名は必須です'
    return false
  }
  
  if (formData.username.length < 3) {
    errors.username = 'ユーザー名は3文字以上で入力してください'
    return false
  }
  
  return true
}

const updateProfile = async () => {
  if (!validateForm() || !user.value) return
  
  try {
    loading.value = true
    
    const updates = {
      username: formData.username.trim(),
      bio: formData.bio.trim() || null,
      twitter_id: formData.twitter_id.trim() || null,
      discord_id: formData.discord_id.trim() || null
    }
    
    const { error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', user.value.id)

    if (error) throw error

    toast.success('プロフィールを更新しました')
    await fetchProfile()
  } catch (error) {
    console.error('Profile update error:', error)
    toast.error('プロフィールの更新に失敗しました')
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  initializeForm()
}

onMounted(() => {
  fetchProfile()
  fetchUserStats()
})
</script>

<style scoped>
.profile-page {
  padding: 2rem 0;
}

.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 0 1rem;
}

.profile-header {
  text-align: center;
  margin-bottom: 2rem;
}

.profile-header h1 {
  font-size: 2.5rem;
  color: #333;
  margin: 0;
}

.profile-content {
  display: grid;
  gap: 2rem;
}

.profile-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.profile-form {
  max-width: 500px;
  margin: 0 auto;
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
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
}

.form-input.disabled {
  background-color: #f8f9fa;
  color: #6c757d;
  cursor: not-allowed;
}

.form-input.error {
  border-color: #dc3545;
}

.error-message {
  color: #dc3545;
  font-size: 0.875rem;
  margin-top: 0.25rem;
  display: block;
}

.form-group small {
  color: #6c757d;
  font-size: 0.875rem;
  margin-top: 0.25rem;
  display: block;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 2rem;
}

.btn {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.3s;
  border: none;
  cursor: pointer;
  font-size: 1rem;
}

.btn-primary {
  background-color: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #5a6fd8;
  transform: translateY(-2px);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  background-color: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background-color: #5a6268;
  transform: translateY(-2px);
}

.profile-stats {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.profile-stats h3 {
  text-align: center;
  margin-bottom: 1.5rem;
  color: #333;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
}

.stat-card {
  text-align: center;
  padding: 1.5rem;
  background: #f8f9fa;
  border-radius: 8px;
}

.stat-number {
  font-size: 2rem;
  font-weight: bold;
  color: #667eea;
  margin-bottom: 0.5rem;
}

.stat-label {
  color: #666;
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .profile-header h1 {
    font-size: 2rem;
  }
  
  .profile-card {
    padding: 1.5rem;
  }
  
  .form-actions {
    flex-direction: column;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
}
</style> 
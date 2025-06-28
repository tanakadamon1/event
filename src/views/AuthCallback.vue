<template>
  <div class="auth-callback">
    <div class="callback-container">
      <div class="callback-card">
        <div class="loading-spinner">
          <div class="spinner"></div>
        </div>
        <h2>{{ message }}</h2>
        <p v-if="error" class="error-message">{{ error }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const message = ref('認証中...')
const error = ref('')

const handleCallback = async () => {
  try {
    message.value = 'プロフィールを確認中...'
    await authStore.handleAuthCallback()
    
    message.value = 'ログインに成功しました'
    toast.success('ログインに成功しました')
    
    // Check if user needs to set VRChat username
    if (authStore.user && !authStore.user.vrchat_username) {
      router.push('/profile')
    } else {
      router.push('/')
    }
  } catch (err) {
    console.error('Auth callback error:', err)
    error.value = '認証に失敗しました。もう一度お試しください。'
    message.value = '認証エラー'
    toast.error('認証に失敗しました')
    
    setTimeout(() => {
      router.push('/login')
    }, 3000)
  }
}

onMounted(() => {
  handleCallback()
})
</script>

<style scoped>
.auth-callback {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.callback-container {
  width: 100%;
  max-width: 400px;
}

.callback-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  text-align: center;
}

.loading-spinner {
  margin-bottom: 1.5rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

h2 {
  color: #333;
  margin-bottom: 1rem;
}

.error-message {
  color: #dc3545;
  background: #f8d7da;
  padding: 0.75rem;
  border-radius: 4px;
  margin-top: 1rem;
}
</style> 
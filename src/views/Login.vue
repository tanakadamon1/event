<template>
  <div class="login-page">
    <div class="login-container">
      <div class="login-card">
        <div class="login-header">
          <h1>ログイン</h1>
          <p>VRChatイベント掲示板にログインしてください</p>
        </div>
        
        <div class="login-content">
          <button
            @click="handleGoogleLogin"
            :disabled="loading"
            class="google-login-btn"
          >
            <svg class="google-icon" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            {{ loading ? 'ログイン中...' : 'Googleでログイン' }}
          </button>
          
          <div class="login-info">
            <h3>ログインについて</h3>
            <ul>
              <li>Googleアカウントで簡単ログイン</li>
              <li>初回ログイン時にVRChatユーザー名の設定が必要</li>
              <li>個人情報は安全に保護されます</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'

const authStore = useAuthStore()
const toast = useToast()
const loading = ref(false)

const handleGoogleLogin = async () => {
  try {
    loading.value = true
    await authStore.login()
    // 認証後はSupabase側で自動リダイレクトされる
  } catch (error) {
    console.error('Login error:', error)
    toast.error('ログインに失敗しました')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.login-container {
  width: 100%;
  max-width: 400px;
}

.login-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
}

.login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.login-header h1 {
  font-size: 2rem;
  color: #333;
  margin-bottom: 0.5rem;
}

.login-header p {
  color: #666;
  font-size: 1rem;
}

.login-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.google-login-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.75rem 1.5rem;
  background: white;
  border: 2px solid #ddd;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  color: #333;
  cursor: pointer;
  transition: all 0.3s;
}

.google-login-btn:hover:not(:disabled) {
  border-color: #4285F4;
  box-shadow: 0 2px 8px rgba(66, 133, 244, 0.2);
}

.google-login-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.google-icon {
  width: 20px;
  height: 20px;
}

.login-info {
  background: #f8f9fa;
  padding: 1.5rem;
  border-radius: 8px;
}

.login-info h3 {
  font-size: 1.1rem;
  color: #333;
  margin-bottom: 1rem;
}

.login-info ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.login-info li {
  color: #666;
  margin-bottom: 0.5rem;
  padding-left: 1.5rem;
  position: relative;
}

.login-info li::before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #28a745;
  font-weight: bold;
}

@media (max-width: 480px) {
  .login-card {
    padding: 1.5rem;
  }
  
  .login-header h1 {
    font-size: 1.75rem;
  }
}
</style> 
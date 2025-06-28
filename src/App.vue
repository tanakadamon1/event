<template>
  <div id="app">
    <nav class="navbar glass-navbar animate-navbar">
      <div class="nav-container">
        <router-link to="/" class="nav-brand gradient-text">VRChatイベントキャスト募集掲示板</router-link>
        <div class="nav-menu">
          <router-link to="/events" class="nav-link">イベント一覧</router-link>
          <router-link v-if="user" to="/applications" class="nav-link">応募管理</router-link>
          <router-link v-if="user" to="/messages" class="nav-link message-link">
            メッセージ
            <span v-if="unreadMessageCount > 0" class="message-badge">{{ unreadMessageCount }}</span>
          </router-link>
          <router-link v-if="!user" to="/login" class="nav-link">ログイン</router-link>
          <router-link v-if="user" to="/profile" class="nav-link">プロフィール</router-link>
          <button v-if="user" @click="logout" class="nav-link logout-btn">ログアウト</button>
        </div>
      </div>
    </nav>

    <main class="main-content beautiful-main">
      <router-view />
    </main>

    <Footer />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { storeToRefs } from 'pinia'
import { getUnreadNotificationCount } from '@/lib/notifications'
import { getUnreadMessageCount } from '@/lib/messages'
import Footer from '@/components/Footer.vue'

const authStore = useAuthStore()
const { user } = storeToRefs(authStore)
const unreadCount = ref(0)
const unreadMessageCount = ref(0)

const isAdmin = computed(() => {
  const adminUserId = import.meta.env.VITE_ADMIN_USER_ID || '00000000-0000-0000-0000-000000000000'
  return user.value?.id === adminUserId
})

const logout = async () => {
  await authStore.logout()
}

const fetchUnreadCount = async () => {
  if (user.value) {
    unreadCount.value = await getUnreadNotificationCount()
  } else {
    unreadCount.value = 0
  }
}

const fetchUnreadMessageCount = async () => {
  if (user.value) {
    let count = await getUnreadMessageCount()
    if (count > 0) {
      // 100ms待ってもう一度取得
      await new Promise(r => setTimeout(r, 100))
      count = await getUnreadMessageCount()
    }
    unreadMessageCount.value = count
  } else {
    unreadMessageCount.value = 0
  }
}

// ユーザーのログイン状態が変わったときに未読数を更新
watch(user, () => {
  fetchUnreadCount()
  fetchUnreadMessageCount()
})

// カスタムイベントで未読数を更新
const handleUpdateUnreadCounts = () => {
  fetchUnreadCount()
  fetchUnreadMessageCount()
}

onMounted(() => {
  fetchUnreadCount()
  fetchUnreadMessageCount()
  
  // カスタムイベントをリッスン
  window.addEventListener('updateUnreadCounts', handleUpdateUnreadCounts)
})

onUnmounted(() => {
  // カスタムイベントをクリーンアップ
  window.removeEventListener('updateUnreadCounts', handleUpdateUnreadCounts)
})
</script>

<style scoped>
#app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.glass-navbar {
  background: rgba(255,255,255,0.85);
  box-shadow: 0 4px 32px 0 #667eea22;
  backdrop-filter: blur(12px);
  border-bottom: 1.5px solid #e0e7ff;
  padding: 1rem 0 0.7rem 0;
  position: sticky;
  top: 0;
  z-index: 100;
  animation: navbar-fadein 1.2s cubic-bezier(.4,0,.2,1);
}
.animate-navbar {
  animation: navbar-fadein 1.2s cubic-bezier(.4,0,.2,1);
}
@keyframes navbar-fadein {
  from { opacity: 0; transform: translateY(-40px); }
  to { opacity: 1; transform: none; }
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.nav-brand {
  font-size: 1.4rem;
  font-weight: 900;
  letter-spacing: 0.04em;
  text-decoration: none;
  background: linear-gradient(90deg, #667eea 0%, #ff6b35 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  text-fill-color: transparent;
}

.nav-menu {
  display: flex;
  gap: 1.5rem;
  align-items: center;
}

.nav-link {
  color: #333;
  text-decoration: none;
  padding: 0.4rem 1rem;
  border-radius: 2rem;
  font-weight: 600;
  font-size: 1rem;
  transition: background 0.3s, color 0.3s, box-shadow 0.3s;
  background: none;
  position: relative;
}

.nav-link:hover {
  background: linear-gradient(90deg, #667eea22 0%, #ff6b3522 100%);
  color: #667eea;
  box-shadow: 0 2px 16px #667eea22;
}

.logout-btn {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1.1rem;
  font-weight: 600;
  color: #ff6b35;
  padding: 0.6rem 1.3rem;
  border-radius: 2rem;
  transition: background 0.3s, color 0.3s;
}
.logout-btn:hover {
  background: #ff6b3522;
  color: #fff;
}

.message-link {
  position: relative;
}

.message-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  background-color: #dc3545;
  color: white;
  border-radius: 50%;
  width: 22px;
  height: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.85rem;
  font-weight: bold;
  box-shadow: 0 2px 8px #dc354544;
}

.beautiful-main {
  flex: 1;
  max-width: 1200px;
  margin: 0 auto;
  padding: 3.5rem 2rem 3rem 2rem;
  width: 100%;
  background: rgba(255,255,255,0.7);
  border-radius: 2.5rem;
  box-shadow: 0 8px 32px rgba(102,126,234,0.08);
  margin-top: 2.5rem;
  margin-bottom: 2.5rem;
}

@media (max-width: 768px) {
  .nav-container {
    flex-direction: column;
    gap: 1.2rem;
    padding: 0.5rem 0;
  }
  .nav-menu {
    flex-wrap: wrap;
    gap: 0.7rem;
    justify-content: center;
  }
  .nav-brand {
    font-size: 1rem;
  }
  .nav-link {
    font-size: 0.95rem;
    padding: 0.4rem 0.7rem;
  }
  .beautiful-main {
    padding: 1.2rem 0.5rem 1.2rem 0.5rem;
    border-radius: 1.2rem;
    margin-top: 1.2rem;
    margin-bottom: 1.2rem;
  }
}
</style> 
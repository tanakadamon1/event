<template>
  <footer class="footer">
    <div class="container">
      <div class="footer-content">
        <div class="footer-section">
          <h3>{{ siteName }}</h3>
          <p>{{ siteDescription }}</p>
        </div>
        
        <div class="footer-section">
          <h4>リンク</h4>
          <ul class="footer-links">
            <li><router-link to="/events">イベント一覧</router-link></li>
            <li><router-link to="/applications">応募管理</router-link></li>
            <li><router-link to="/messages">メッセージ</router-link></li>
            <li><router-link to="/profile">プロフィール</router-link></li>
          </ul>
        </div>

        <div class="footer-section">
          <h4>法的情報</h4>
          <ul class="footer-links">
            <li><router-link to="/legal">特定商取引法に基づく表記</router-link></li>
            <li><a href="https://twitter.com/yokena45330" target="_blank" rel="noopener">運営者Twitter（@yokena45330）</a></li>
          </ul>
        </div>
      </div>
      
      <div class="footer-bottom">
        <p>&copy; 2025 {{ siteName }}. All rights reserved.</p>
      </div>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useToast } from 'vue-toastification'
import { SITE_NAME, SITE_DESCRIPTION } from '@/lib/constants'

const toast = useToast()
const showDonationModal = ref(false)

const siteName = SITE_NAME
const siteDescription = SITE_DESCRIPTION

const handleDonationSuccess = (amount: number) => {
  toast.success(`${amount.toLocaleString()}円の投げ銭が完了しました！サイト運営の励みになります。`)
}
</script>

<style scoped>
.footer {
  background: #2c3e50;
  color: white;
  padding: 3rem 0 1rem;
  margin-top: 4rem;
  position: relative;
  z-index: 10;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

.footer-content {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
  margin-bottom: 2rem;
}

.footer-section h3 {
  margin: 0 0 1rem 0;
  font-size: 1.5rem;
  color: #ecf0f1;
}

.footer-section h4 {
  margin: 0 0 1rem 0;
  font-size: 1.2rem;
  color: #ecf0f1;
}

.footer-section p {
  margin: 0 0 1rem 0;
  color: #bdc3c7;
  line-height: 1.6;
}

.footer-links {
  list-style: none;
  padding: 0;
  margin: 0;
}

.footer-links li {
  margin-bottom: 0.5rem;
}

.footer-links a {
  color: #bdc3c7;
  text-decoration: none;
  transition: color 0.3s;
}

.footer-links a:hover {
  color: #ecf0f1;
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

.btn-donation {
  background: #ff6b35;
  color: white;
}

.btn-donation:hover {
  background: #e55a2b;
  transform: translateY(-2px);
}

.footer-bottom {
  border-top: 1px solid #34495e;
  padding-top: 1rem;
  text-align: center;
}

.footer-bottom p {
  margin: 0;
  color: #95a5a6;
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .footer-content {
    grid-template-columns: 1fr;
    text-align: center;
  }
  
  .footer-section {
    margin-bottom: 2rem;
  }
}
</style> 
<template></template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
const router = useRouter()
onMounted(() => {
  router.push('/events')
})
</script>

<style scoped>
.home-hero-bg {
  min-height: 100vh;
  width: 100vw;
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}
.bg-gradient {
  position: absolute;
  inset: 0;
  width: 100vw;
  height: 100vh;
  background: linear-gradient(120deg, #667eea 0%, #ffb347 100%);
  opacity: 0.15;
  z-index: 0;
}
.bg-particles {
  position: absolute;
  inset: 0;
  z-index: 1;
  pointer-events: none;
}
.particle {
  position: absolute;
  border-radius: 50%;
  opacity: 0.13;
  filter: blur(2px);
  animation: float 8s ease-in-out infinite alternate;
  background: linear-gradient(135deg, #667eea 0%, #ff6b35 100%);
}
.particle-1 { width: 60px; height: 60px; top: 10%; left: 8%; animation-delay: 0s; }
.particle-2 { width: 40px; height: 40px; top: 20%; left: 80%; animation-delay: 1.2s; }
.particle-3 { width: 30px; height: 30px; top: 70%; left: 15%; animation-delay: 2.1s; }
.particle-4 { width: 50px; height: 50px; top: 60%; left: 60%; animation-delay: 0.7s; }
.particle-5 { width: 35px; height: 35px; top: 40%; left: 30%; animation-delay: 1.7s; }
.particle-6 { width: 25px; height: 25px; top: 80%; left: 70%; animation-delay: 2.7s; }
.particle-7 { width: 70px; height: 70px; top: 15%; left: 50%; animation-delay: 0.3s; }
.particle-8 { width: 20px; height: 20px; top: 55%; left: 85%; animation-delay: 1.9s; }
.particle-9 { width: 45px; height: 45px; top: 75%; left: 40%; animation-delay: 2.5s; }
.particle-10 { width: 30px; height: 30px; top: 30%; left: 60%; animation-delay: 0.9s; }
.particle-11 { width: 25px; height: 25px; top: 65%; left: 75%; animation-delay: 1.5s; }
.particle-12 { width: 40px; height: 40px; top: 85%; left: 20%; animation-delay: 2.2s; }
.particle-13 { width: 35px; height: 35px; top: 50%; left: 10%; animation-delay: 1.1s; }
.particle-14 { width: 20px; height: 20px; top: 35%; left: 90%; animation-delay: 2.8s; }
.particle-15 { width: 60px; height: 60px; top: 80%; left: 55%; animation-delay: 0.5s; }
.particle-16 { width: 30px; height: 30px; top: 10%; left: 70%; animation-delay: 1.6s; }
.particle-17 { width: 25px; height: 25px; top: 60%; left: 25%; animation-delay: 2.4s; }
.particle-18 { width: 50px; height: 50px; top: 25%; left: 35%; animation-delay: 0.8s; }

.hero-center {
  position: relative;
  z-index: 2;
  width: 100vw;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}
.hero-card {
  background: rgba(255,255,255,0.97);
  border-radius: 1.5rem;
  box-shadow: 0 4px 24px rgba(102,126,234,0.13);
  border: 1.5px solid #e0e7ff;
  max-width: 600px;
  width: 95vw;
  padding: 2rem 1.5rem 1.5rem 1.5rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.hero-title {
  font-size: 2.2rem;
  font-weight: 900;
  margin-bottom: 0.7rem;
  letter-spacing: 0.04em;
  line-height: 1.1;
  text-shadow: 0 2px 16px #667eea22;
  text-align: center;
}
.gradient-text {
  background: linear-gradient(90deg, #667eea 0%, #ff6b35 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  text-fill-color: transparent;
}
.hero-subtitle {
  font-size: 1rem;
  margin-bottom: 1.1rem;
  color: #444;
  opacity: 0.92;
  font-weight: 500;
  line-height: 1.5;
  text-align: center;
}
.hero-actions {
  display: flex;
  gap: 0.7rem;
  justify-content: center;
  flex-wrap: wrap;
  margin-bottom: 0;
}
.btn {
  display: inline-block;
  padding: 0.9rem 2.1rem;
  border-radius: 2rem;
  font-size: 1.1rem;
  font-weight: 700;
  border: none;
  cursor: pointer;
  transition: box-shadow 0.3s, transform 0.2s;
  box-shadow: 0 2px 16px rgba(102,126,234,0.10);
  background: #fff;
  color: #667eea;
  position: relative;
  letter-spacing: 0.02em;
}
.btn-primary {
  background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
  color: #fff;
}
.btn-secondary {
  background: linear-gradient(90deg, #ff6b35 0%, #ffb347 100%);
  color: #fff;
}
@media (max-width: 700px) {
  .hero-card {
    max-width: 98vw;
    padding: 1.2rem 0.5rem 1rem 0.5rem;
  }
  .hero-title {
    font-size: 1.3rem;
  }
  .hero-subtitle {
    font-size: 0.95rem;
  }
  .btn {
    font-size: 0.95rem;
    padding: 0.7rem 1.2rem;
  }
}
@keyframes float {
  0% { transform: translateY(0); }
  100% { transform: translateY(-18px); }
}
</style> 
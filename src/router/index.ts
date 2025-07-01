import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import Legal from '@/views/Legal.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue')
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue')
  },
  {
    path: '/auth/callback',
    name: 'AuthCallback',
    component: () => import('@/views/AuthCallback.vue')
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('@/views/Profile.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/events',
    name: 'Events',
    component: () => import('@/views/Events.vue')
  },
  {
    path: '/events/create',
    name: 'CreateEvent',
    component: () => import('@/views/CreateEvent.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/events/:id',
    name: 'EventDetail',
    component: () => import('@/views/EventDetail.vue')
  },
  {
    path: '/events/:id/edit',
    name: 'EditEvent',
    component: () => import('@/views/EditEvent.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/applications',
    name: 'Applications',
    component: () => import('@/views/Applications.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/messages',
    name: 'Messages',
    component: () => import('@/views/Messages.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/notifications',
    name: 'Notifications',
    component: () => import('@/views/Notifications.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/legal',
    name: 'Legal',
    component: Legal
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guard
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  
  if (to.meta.requiresAuth) {
    if (!authStore.isAuthenticated) {
      await authStore.getCurrentUser()
      if (!authStore.isAuthenticated) {
        next('/login')
        return
      }
    }
  }
  
  // Admin check
  if (to.meta.requiresAdmin) {
    const adminUserId = import.meta.env.VITE_ADMIN_USER_ID || '00000000-0000-0000-0000-000000000000'
    if (authStore.user?.id !== adminUserId) {
      next('/')
      return
    }
  }
  
  next()
})

export default router 
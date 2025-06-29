import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { User } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const loading = ref(false)

  const isAuthenticated = computed(() => !!user.value)

  const login = async () => {
    loading.value = true
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`
      }
    })
    loading.value = false
    if (error) throw error
  }

  const logout = async () => {
    loading.value = true
    const { error } = await supabase.auth.signOut()
    loading.value = false
    if (error) throw error
    user.value = null
  }

  const getCurrentUser = async () => {
    loading.value = true
    const { data: { user: authUser }, error } = await supabase.auth.getUser()
    if (error) {
      loading.value = false
      throw error
    }
    if (authUser) {
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', authUser.id)
        .single()
      if (profileError) {
        loading.value = false
        throw profileError
      }
      user.value = profile
    } else {
      user.value = null
    }
    loading.value = false
  }

  const updateProfile = async (updates: Partial<User>) => {
    if (!user.value) throw new Error('User not authenticated')
    loading.value = true
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', user.value.id)
      .select()
      .single()
    loading.value = false
    if (error) throw error
    user.value = data
    return data
  }

  const handleAuthCallback = async () => {
    loading.value = true
    const { data: { user: authUser }, error } = await supabase.auth.getUser()
    if (error) {
      loading.value = false
      throw error
    }
    if (authUser) {
      // プロフィールがなければ作成
      const { data: existingProfile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', authUser.id)
        .single()
      if (!existingProfile) {
        const { data: newProfile, error: createError } = await supabase
          .from('profiles')
          .insert({
            id: authUser.id,
            email: authUser.email,
            vrchat_username: '',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .select()
          .single()
        if (createError) {
          loading.value = false
          throw createError
        }
        user.value = newProfile
      } else {
        user.value = existingProfile
      }
    }
    loading.value = false
  }

  return {
    user,
    loading,
    isAuthenticated,
    login,
    logout,
    getCurrentUser,
    updateProfile,
    handleAuthCallback
  }
}) 
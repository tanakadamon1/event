import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ffdyirdacmfiqjqgddav.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmZHlpcmRhY21maXFqcWdkZGF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMDU1MjUsImV4cCI6MjA2NjU4MTUyNX0.RoM-dCQrUrh5Zf0ZIqdUKm6SiMMYAOR7nvFhlOHys34'

export const supabase = createClient(supabaseUrl, supabaseAnonKey) 
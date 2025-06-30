export interface User {
  id: string
  email: string
  vrchat_username: string
  profile_image?: string
  bio?: string
  created_at: string
  updated_at: string
}

export interface Event {
  id: string
  title: string
  description: string
  event_date: string
  max_participants?: number
  application_deadline?: string
  discord_id?: string
  contact_info?: string
  user_id: string
  created_at: string
  updated_at: string
  images: EventImage[]
  tags: EventTag[]
  applications: Application[]
  _count?: {
    applications: number
  }
}

export interface EventImage {
  id: string
  event_id: string
  image_url: string
  created_at: string
}

export interface EventTag {
  id: string
  event_id: string
  tag: string
}

export interface Application {
  id: string
  event_id: string
  user_id: string
  message?: string
  status: 'pending' | 'accepted' | 'rejected'
  created_at: string
  user: User
}

export interface Message {
  id: string
  event_id: string
  sender_id: string
  receiver_id: string
  content: string
  is_read: boolean
  created_at: string
  sender: User
  receiver: User
}

export interface Notification {
  id: string
  user_id: string
  type: 'application' | 'message' | 'event_update'
  title: string
  content: string
  is_read: boolean
  related_event_id?: string
  created_at: string
}

export interface Donation {
  id: string
  donor_id: string
  recipient_id: string
  amount: number
  payment_method: 'paypal' | 'stripe'
  status: 'pending' | 'completed' | 'failed'
  created_at: string
}

export interface Report {
  id: string
  reporter_id: string
  reported_event_id?: string
  reported_user_id?: string
  reason: string
  description?: string
  status: 'pending' | 'resolved' | 'dismissed'
  created_at: string
}

export interface CreateEventData {
  title: string
  description: string
  event_date: string
  max_participants?: number
  application_deadline?: string
  discord_id?: string
  contact_info?: string
  tags: string[]
  images: File[]
}

export interface UpdateEventData extends Partial<CreateEventData> {
  id: string
}

export interface CreateApplicationData {
  event_id: string
  message?: string
}

export interface CreateMessageData {
  event_id: string
  receiver_id: string
  content: string
}

export interface CreateDonationData {
  recipient_id: string
  amount: number
  payment_method: 'paypal' | 'stripe'
} 
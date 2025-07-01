-- Create complete database schema for production environment
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table first (referenced by events)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username VARCHAR(100) UNIQUE,
    display_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    twitter_id VARCHAR(100),
    discord_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create events table with schedule pattern support
CREATE TABLE IF NOT EXISTS events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    schedule_type VARCHAR(20) NOT NULL CHECK (schedule_type IN ('single', 'weekly', 'biweekly', 'monthly', 'irregular')),
    single_date DATE,
    single_time TIME,
    weekly_day VARCHAR(10),
    weekly_time TIME,
    biweekly_day VARCHAR(10),
    biweekly_time TIME,
    biweekly_note TEXT,
    monthly_week INTEGER CHECK (monthly_week IS NULL OR (monthly_week >= 1 AND monthly_week <= 5)),
    monthly_day VARCHAR(10),
    monthly_time TIME,
    irregular_note TEXT,
    max_participants INTEGER,
    application_deadline DATE,
    twitter_id VARCHAR(100),
    discord_id VARCHAR(100),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create event_images table for multiple images per event
CREATE TABLE IF NOT EXISTS event_images (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create applications table for event applications
CREATE TABLE IF NOT EXISTS applications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

-- Create notifications table for user notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('application', 'status_change', 'event_update', 'system')),
    related_event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    related_application_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create messages table for direct messaging
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (Row Level Security)
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Events policies
CREATE POLICY "Events are viewable by everyone" ON events
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own events" ON events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own events" ON events
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own events" ON events
    FOR DELETE USING (auth.uid() = user_id);

-- Event images policies
CREATE POLICY "Event images are viewable by everyone" ON event_images
    FOR SELECT USING (true);

CREATE POLICY "Users can insert images for their events" ON event_images
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM events 
            WHERE events.id = event_images.event_id 
            AND events.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete images for their events" ON event_images
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM events 
            WHERE events.id = event_images.event_id 
            AND events.user_id = auth.uid()
        )
    );

-- Applications policies
CREATE POLICY "Users can view applications for events they created" ON applications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM events 
            WHERE events.id = applications.event_id 
            AND events.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view their own applications" ON applications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own applications" ON applications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Event creators can update applications" ON applications
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM events 
            WHERE events.id = applications.event_id 
            AND events.user_id = auth.uid()
        )
    );

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Messages policies
CREATE POLICY "Users can view messages they sent or received" ON messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages" ON messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they sent" ON messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- Create storage bucket for event images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('event-images', 'event-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for event images
CREATE POLICY "Event images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'event-images');

CREATE POLICY "Users can upload event images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'event-images' AND auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their own event images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'event-images' AND auth.uid() IS NOT NULL);

CREATE POLICY "Users can delete their own event images" ON storage.objects
    FOR DELETE USING (bucket_id = 'event-images' AND auth.uid() IS NOT NULL); 
-- VRChat Event Cast Recruitment Bulletin Board Database Schema (Fixed)

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create events table
CREATE TABLE IF NOT EXISTS events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
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

-- Create profiles table for user profiles
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

-- Enable RLS (Row Level Security)
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Events policies (with IF NOT EXISTS check)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Events are viewable by everyone' AND tablename = 'events') THEN
        CREATE POLICY "Events are viewable by everyone" ON events
            FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own events' AND tablename = 'events') THEN
        CREATE POLICY "Users can insert their own events" ON events
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own events' AND tablename = 'events') THEN
        CREATE POLICY "Users can update their own events" ON events
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete their own events' AND tablename = 'events') THEN
        CREATE POLICY "Users can delete their own events" ON events
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Event images policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Event images are viewable by everyone' AND tablename = 'event_images') THEN
        CREATE POLICY "Event images are viewable by everyone" ON event_images
            FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert images for their events' AND tablename = 'event_images') THEN
        CREATE POLICY "Users can insert images for their events" ON event_images
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM events 
                    WHERE events.id = event_images.event_id 
                    AND events.user_id = auth.uid()
                )
            );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete images for their events' AND tablename = 'event_images') THEN
        CREATE POLICY "Users can delete images for their events" ON event_images
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM events 
                    WHERE events.id = event_images.event_id 
                    AND events.user_id = auth.uid()
                )
            );
    END IF;
END $$;

-- Applications policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view applications for events they created' AND tablename = 'applications') THEN
        CREATE POLICY "Users can view applications for events they created" ON applications
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM events 
                    WHERE events.id = applications.event_id 
                    AND events.user_id = auth.uid()
                )
            );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own applications' AND tablename = 'applications') THEN
        CREATE POLICY "Users can view their own applications" ON applications
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own applications' AND tablename = 'applications') THEN
        CREATE POLICY "Users can insert their own applications" ON applications
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Event creators can update applications' AND tablename = 'applications') THEN
        CREATE POLICY "Event creators can update applications" ON applications
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM events 
                    WHERE events.id = applications.event_id 
                    AND events.user_id = auth.uid()
                )
            );
    END IF;
END $$;

-- Profiles policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Profiles are viewable by everyone' AND tablename = 'profiles') THEN
        CREATE POLICY "Profiles are viewable by everyone" ON profiles
            FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own profile' AND tablename = 'profiles') THEN
        CREATE POLICY "Users can insert their own profile" ON profiles
            FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own profile' AND tablename = 'profiles') THEN
        CREATE POLICY "Users can update their own profile" ON profiles
            FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

-- Create storage bucket for event images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('event-images', 'event-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for event images
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Event images are publicly accessible' AND tablename = 'objects') THEN
        CREATE POLICY "Event images are publicly accessible" ON storage.objects
            FOR SELECT USING (bucket_id = 'event-images');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can upload event images' AND tablename = 'objects') THEN
        CREATE POLICY "Authenticated users can upload event images" ON storage.objects
            FOR INSERT WITH CHECK (
                bucket_id = 'event-images' 
                AND auth.role() = 'authenticated'
            );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete their own event images' AND tablename = 'objects') THEN
        CREATE POLICY "Users can delete their own event images" ON storage.objects
            FOR DELETE USING (
                bucket_id = 'event-images' 
                AND auth.uid()::text = (storage.foldername(name))[1]
            );
    END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_events_user_id ON events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_event_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_event_images_event_id ON event_images(event_id);
CREATE INDEX IF NOT EXISTS idx_applications_event_id ON applications(event_id);
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON applications(user_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_events_updated_at ON events;
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_applications_updated_at ON applications;
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 
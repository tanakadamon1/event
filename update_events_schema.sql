-- Update events table schema to support different schedule patterns
-- This script should be run on the existing database

-- First, backup existing data (optional but recommended)
-- CREATE TABLE events_backup AS SELECT * FROM events;

-- Add new columns
ALTER TABLE events ADD COLUMN IF NOT EXISTS schedule_type VARCHAR(20);
ALTER TABLE events ADD COLUMN IF NOT EXISTS single_date DATE;
ALTER TABLE events ADD COLUMN IF NOT EXISTS single_time TIME;
ALTER TABLE events ADD COLUMN IF NOT EXISTS weekly_day VARCHAR(10);
ALTER TABLE events ADD COLUMN IF NOT EXISTS weekly_time TIME;
ALTER TABLE events ADD COLUMN IF NOT EXISTS biweekly_day VARCHAR(10);
ALTER TABLE events ADD COLUMN IF NOT EXISTS biweekly_time TIME;
ALTER TABLE events ADD COLUMN IF NOT EXISTS biweekly_note TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS monthly_week INTEGER;
ALTER TABLE events ADD COLUMN IF NOT EXISTS monthly_day VARCHAR(10);
ALTER TABLE events ADD COLUMN IF NOT EXISTS monthly_time TIME;
ALTER TABLE events ADD COLUMN IF NOT EXISTS irregular_note TEXT;

-- Add constraint for schedule_type
ALTER TABLE events ADD CONSTRAINT IF NOT EXISTS events_schedule_type_check 
    CHECK (schedule_type IN ('single', 'weekly', 'biweekly', 'monthly', 'irregular'));

-- Add constraint for monthly_week
ALTER TABLE events ADD CONSTRAINT IF NOT EXISTS events_monthly_week_check 
    CHECK (monthly_week IS NULL OR (monthly_week >= 1 AND monthly_week <= 5));

-- Migrate existing event_date data to single_date (if needed)
-- UPDATE events SET single_date = event_date::date WHERE event_date IS NOT NULL;
-- UPDATE events SET single_time = event_date::time WHERE event_date IS NOT NULL;
-- UPDATE events SET schedule_type = 'single' WHERE event_date IS NOT NULL;

-- Remove old event_date column (uncomment when ready)
-- ALTER TABLE events DROP COLUMN IF EXISTS event_date; 
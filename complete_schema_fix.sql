-- Complete schema fix for events table
-- Step 1: Drop existing constraints
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_schedule_type_check;
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_monthly_week_check;

-- Step 2: Fix monthly_week column type
UPDATE events SET monthly_week = NULL WHERE monthly_week = '' OR monthly_week IS NULL;
ALTER TABLE events ALTER COLUMN monthly_week TYPE INTEGER USING 
  CASE 
    WHEN monthly_week IS NULL THEN NULL
    WHEN monthly_week = '' THEN NULL
    ELSE monthly_week::INTEGER 
  END;

-- Step 3: Fix time columns to proper TIME type
-- single_time
UPDATE events SET single_time = NULL WHERE single_time = '' OR single_time IS NULL;
ALTER TABLE events ALTER COLUMN single_time TYPE TIME USING 
  CASE 
    WHEN single_time IS NULL THEN NULL
    WHEN single_time = '' THEN NULL
    ELSE single_time::TIME 
  END;

-- weekly_time
UPDATE events SET weekly_time = NULL WHERE weekly_time = '' OR weekly_time IS NULL;
ALTER TABLE events ALTER COLUMN weekly_time TYPE TIME USING 
  CASE 
    WHEN weekly_time IS NULL THEN NULL
    WHEN weekly_time = '' THEN NULL
    ELSE weekly_time::TIME 
  END;

-- biweekly_time
UPDATE events SET biweekly_time = NULL WHERE biweekly_time = '' OR biweekly_time IS NULL;
ALTER TABLE events ALTER COLUMN biweekly_time TYPE TIME USING 
  CASE 
    WHEN biweekly_time IS NULL THEN NULL
    WHEN biweekly_time = '' THEN NULL
    ELSE biweekly_time::TIME 
  END;

-- monthly_time
UPDATE events SET monthly_time = NULL WHERE monthly_time = '' OR monthly_time IS NULL;
ALTER TABLE events ALTER COLUMN monthly_time TYPE TIME USING 
  CASE 
    WHEN monthly_time IS NULL THEN NULL
    WHEN monthly_time = '' THEN NULL
    ELSE monthly_time::TIME 
  END;

-- Step 4: Add constraints
ALTER TABLE events ADD CONSTRAINT events_schedule_type_check 
  CHECK (schedule_type IN ('single', 'weekly', 'biweekly', 'monthly', 'irregular'));

ALTER TABLE events ADD CONSTRAINT events_monthly_week_check 
  CHECK (monthly_week IS NULL OR (monthly_week >= 1 AND monthly_week <= 5));

-- Step 5: Migrate existing event_date data to new schema (if needed)
UPDATE events 
SET 
  single_date = event_date::date,
  single_time = event_date::time,
  schedule_type = 'single'
WHERE event_date IS NOT NULL AND schedule_type IS NULL;

-- Step 6: Remove old event_date column
ALTER TABLE events DROP COLUMN IF EXISTS event_date; 
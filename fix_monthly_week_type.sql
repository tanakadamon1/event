-- Fix monthly_week column type to INTEGER
-- Step 1: Drop existing constraint if exists
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_monthly_week_check;

-- Step 2: Convert monthly_week to INTEGER
-- First, handle any existing data
UPDATE events SET monthly_week = NULL WHERE monthly_week = '' OR monthly_week IS NULL;

-- Then convert the column type
ALTER TABLE events ALTER COLUMN monthly_week TYPE INTEGER USING 
  CASE 
    WHEN monthly_week IS NULL THEN NULL
    WHEN monthly_week = '' THEN NULL
    ELSE monthly_week::INTEGER 
  END;

-- Step 3: Add the constraint back
ALTER TABLE events ADD CONSTRAINT events_monthly_week_check 
  CHECK (monthly_week IS NULL OR (monthly_week >= 1 AND monthly_week <= 5)); 
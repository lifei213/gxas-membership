-- Add AR ID column to profiles and generate random IDs

-- 1. Add column if not exists
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS member_code VARCHAR(20);

-- 2. Function to generate random 11-digit ID
CREATE OR REPLACE FUNCTION generate_member_code() 
RETURNS TRIGGER AS $$
BEGIN
  -- Only generate if not already present
  IF NEW.member_code IS NULL THEN
    -- Generate random 11 digit number
    -- Range: 10000000000 to 99999999999
    NEW.member_code := floor(random() * 90000000000 + 10000000000)::text;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger to auto-generate on insert
DROP TRIGGER IF EXISTS set_member_code_trigger ON profiles;
CREATE TRIGGER set_member_code_trigger
BEFORE INSERT ON profiles
FOR EACH ROW
EXECUTE FUNCTION generate_member_code();

-- 4. Backfill existing users who don't have a code
UPDATE profiles
SET member_code = floor(random() * 90000000000 + 10000000000)::text
WHERE member_code IS NULL;

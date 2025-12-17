-- Add theme column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS theme JSONB DEFAULT '{
  "mode": "light",
  "primaryColor": "#10b981",
  "fontSize": "14px"
}';

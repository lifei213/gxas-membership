
-- Add position column to profiles table
alter table public.profiles 
add column if not exists position text default '会员';

-- Allow admins to update position (existing policy should cover it, but just in case)
-- "Admins can update any profile" is likely already there.

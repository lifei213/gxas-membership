-- Create membership_applications table
create table if not exists public.membership_applications (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id) not null,
    name text not null,
    gender text,
    unit text, -- School or Company
    phone text,
    email text,
    reason text,
    status text default 'pending' check (status in ('pending', 'approved', 'rejected')),
    created_at timestamptz default now()
);

-- Enable RLS
alter table public.membership_applications enable row level security;

-- Policies

-- 1. Users can insert their own applications
create policy "Users can insert their own applications"
on public.membership_applications for insert
to authenticated
with check (auth.uid() = user_id);

-- 2. Users can view their own applications
create policy "Users can view their own applications"
on public.membership_applications for select
to authenticated
using (auth.uid() = user_id);

-- 3. Admins can view all applications
create policy "Admins can view all applications"
on public.membership_applications for select
to authenticated
using (is_admin());

-- 4. Admins can update applications (approve/reject)
create policy "Admins can update applications"
on public.membership_applications for update
to authenticated
using (is_admin());

-- 广西自动化学会会员管理系统数据库初始化脚本 (Consolidated Setup)
-- 此脚本整合了所有功能模块的数据库定义、权限策略及修复补丁。
-- 包含：Profiles, Membership, Forum, Messages, Notifications, Storage, AI Persona

-- ==========================================
-- 1. Helper Functions (Security & Utils)
-- ==========================================

-- 1.1. Check if user is admin (Security Definer to bypass RLS recursion)
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1
    from profiles
    where id = auth.uid()
      and role = 'admin'
  );
end;
$$ language plpgsql security definer;

-- ==========================================
-- 2. Core Tables (Profiles)
-- ==========================================

-- 2.1. Create Profiles Table (if not exists)
-- Base structure matching Supabase Auth
create table if not exists public.profiles (
    id uuid references auth.users(id) on delete cascade primary key,
    email text,
    name text,
    role text default 'member', -- 'admin' or 'member'
    member_level text default '普通会员',
    created_at timestamptz default now()
);

-- 2.2. Add Extended Columns (Idempotent)
-- Position
alter table public.profiles 
add column if not exists position text default '会员';

-- AR/Member Code
alter table public.profiles 
add column if not exists member_code varchar(20);

-- Theme Settings
alter table public.profiles 
add column if not exists theme jsonb default '{
  "mode": "light",
  "primaryColor": "#10b981",
  "fontSize": "14px"
}';

-- AI Persona & Analysis Fields
alter table public.profiles 
add column if not exists ai_persona jsonb,
add column if not exists activity_tags text[] default '{}',
add column if not exists similarity_score float default 0,
add column if not exists professional_field text,
add column if not exists organization text,
add column if not exists join_date timestamptz default now(),
add column if not exists last_updated timestamptz default now();

-- 2.3. Profiles RLS Policies
alter table public.profiles enable row level security;

-- Reset policies to avoid conflicts
drop policy if exists "Public profiles are viewable by everyone" on profiles;
drop policy if exists "Users can insert their own profile" on profiles;
drop policy if exists "Users can update own profile" on profiles;
drop policy if exists "Admin full access" on profiles;

create policy "Public profiles are viewable by everyone" 
on profiles for select 
using (true);

create policy "Users can insert their own profile" 
on profiles for insert 
with check (auth.uid() = id);

create policy "Users can update own profile" 
on profiles for update 
using (auth.uid() = id);

create policy "Admin full access"
on profiles for all
using ( public.is_admin() );

-- 2.4. Member Code Generation Trigger
create or replace function generate_member_code() 
returns trigger as $$
begin
  if new.member_code is null then
    new.member_code := floor(random() * 90000000000 + 10000000000)::text;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_member_code_trigger on profiles;
create trigger set_member_code_trigger
before insert on profiles
for each row
execute function generate_member_code();

-- Backfill missing codes
update profiles
set member_code = floor(random() * 90000000000 + 10000000000)::text
where member_code is null;

-- ==========================================
-- 3. Membership Applications
-- ==========================================

create table if not exists public.membership_applications (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id) not null,
    name text not null,
    gender text,
    unit text,
    phone text,
    email text,
    reason text,
    status text default 'pending' check (status in ('pending', 'approved', 'rejected')),
    created_at timestamptz default now()
);

alter table public.membership_applications enable row level security;

-- Policies
create policy "Users can insert their own applications"
on public.membership_applications for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can view their own applications"
on public.membership_applications for select
to authenticated
using (auth.uid() = user_id);

create policy "Admins can view all applications"
on public.membership_applications for select
to authenticated
using (is_admin());

create policy "Admins can update applications"
on public.membership_applications for update
to authenticated
using (is_admin());

-- Approval Function
create or replace function public.approve_application(app_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_name text;
begin
  select user_id, name into v_user_id, v_name
  from public.membership_applications
  where id = app_id;

  if v_user_id is null then
    raise exception 'Application not found';
  end if;

  update public.membership_applications
  set status = 'approved'
  where id = app_id;

  update public.profiles
  set 
    member_level = '正式会员',
    name = v_name
  where id = v_user_id;
  
  if not found then
    insert into public.profiles (id, name, member_level, role)
    values (v_user_id, v_name, '正式会员', 'member');
  end if;
end;
$$;

-- ==========================================
-- 4. Communication (Messages & Notifications)
-- ==========================================

-- 4.1. Contact Messages
create table if not exists public.contact_messages (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id) on delete cascade,
    content text not null,
    reply_content text,
    status text default 'unread' check (status in ('unread', 'read', 'replied')),
    created_at timestamptz default now(),
    reply_at timestamptz
);

alter table public.contact_messages enable row level security;

create policy "Users can view own messages" 
on public.contact_messages for select 
using (auth.uid() = user_id);

create policy "Users can insert own messages" 
on public.contact_messages for insert 
with check (auth.uid() = user_id);

create policy "Admins can view all messages" 
on public.contact_messages for select 
using (is_admin());

create policy "Admins can update messages" 
on public.contact_messages for update 
using (is_admin());

-- 4.2. Notifications
create table if not exists public.notifications (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id),
    title text,
    message text not null,
    read boolean default false,
    created_at timestamptz default now()
);

alter table public.notifications enable row level security;

create policy "Users read own or broadcast"
on public.notifications for select
to authenticated
using (auth.uid() = user_id or user_id is null);

create policy "Admins insert notifications"
on public.notifications for insert
to authenticated
with check (is_admin());

create policy "Admins update notifications"
on public.notifications for update
to authenticated
using (is_admin());

-- ==========================================
-- 5. Forum System
-- ==========================================

-- 5.1. Tables
create table if not exists forum_sections (
  id bigserial primary key,
  name varchar(100) not null,
  description text,
  parent_id bigint references forum_sections(id),
  created_at timestamptz default now()
);

create table if not exists posts (
  id bigserial primary key,
  title varchar(200) not null,
  content text not null,
  author_id uuid not null references profiles(id) on delete cascade, -- Using profiles instead of auth.users
  section_id bigint not null references forum_sections(id),
  is_pinned boolean default false,
  is_essence boolean default false,
  view_count int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists comments (
  id bigserial primary key,
  content text not null,
  author_id uuid not null references profiles(id) on delete cascade, -- Using profiles
  post_id bigint not null references posts(id) on delete cascade,
  parent_id bigint references comments(id),
  created_at timestamptz default now()
);

create table if not exists interactions (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade, -- Using profiles
  post_id bigint not null references posts(id) on delete cascade,
  interaction_type varchar(20) not null,
  created_at timestamptz default now(),
  unique(user_id, post_id, interaction_type)
);

-- 5.2. RLS & Policies
alter table forum_sections enable row level security;
alter table posts enable row level security;
alter table comments enable row level security;
alter table interactions enable row level security;

-- Drop old policies to ensure clean state
drop policy if exists "Public read access for sections" on forum_sections;
drop policy if exists "Public read access for posts" on posts;
drop policy if exists "Authenticated users can create posts" on posts;
drop policy if exists "Users can update own posts" on posts;
drop policy if exists "Users can delete own posts" on posts;
drop policy if exists "Public read access for comments" on comments;
drop policy if exists "Authenticated users can create comments" on comments;
drop policy if exists "Users can delete own comments" on comments;
drop policy if exists "Public read access for interactions" on interactions;
drop policy if exists "Authenticated users can manage interactions" on interactions;

-- Re-create Policies
create policy "Public read access for sections" on forum_sections for select using (true);

create policy "Public read access for posts" on posts for select using (true);
create policy "Authenticated users can create posts" on posts for insert with check (auth.uid() = author_id);
create policy "Users can update own posts" on posts for update using (auth.uid() = author_id);
create policy "Users can delete own posts" on posts for delete using (auth.uid() = author_id);

create policy "Public read access for comments" on comments for select using (true);
create policy "Authenticated users can create comments" on comments for insert with check (auth.uid() = author_id);
create policy "Users can delete own comments" on comments for delete using (auth.uid() = author_id);

create policy "Public read access for interactions" on interactions for select using (true);
create policy "Authenticated users can manage interactions" on interactions for all using (auth.uid() = user_id);

-- 5.3. View Count Function
create or replace function increment_view_count(post_id bigint)
returns void as $$
begin
  update posts
  set view_count = view_count + 1
  where id = post_id;
end;
$$ language plpgsql security definer;

-- 5.4. Initial Sections (if empty)
insert into forum_sections (name, description)
select '学术交流', '探讨前沿学术问题，分享研究成果'
where not exists (select 1 from forum_sections where name = '学术交流');

insert into forum_sections (name, description)
select '活动通知', '学会近期活动发布与讨论'
where not exists (select 1 from forum_sections where name = '活动通知');

-- ==========================================
-- 6. AI Persona & Member Activities
-- ==========================================

create table if not exists member_tags (
  id bigint generated by default as identity primary key,
  member_id uuid references profiles(id) on delete cascade,
  tag_name varchar(50),
  tag_weight float default 1.0,
  created_at timestamptz default now()
);

create table if not exists member_activities (
  id bigint generated by default as identity primary key,
  member_id uuid references profiles(id) on delete cascade,
  activity_type varchar(50),
  activity_desc text,
  created_at timestamptz default now()
);

alter table member_tags enable row level security;
alter table member_activities enable row level security;

create policy "Users can view their own tags" on member_tags for select using (auth.uid() = member_id);
create policy "Admins can view all tags" on member_tags for select using (is_admin());

create policy "Users can view their own activities" on member_activities for select using (auth.uid() = member_id);
create policy "Users can insert their own activities" on member_activities for insert with check (auth.uid() = member_id);

-- ==========================================
-- 7. Storage
-- ==========================================

-- 7.1. Create Bucket
insert into storage.buckets (id, name, public)
values ('chat-files', 'chat-files', true)
on conflict (id) do update set public = true;

-- 7.2. Storage Policies
drop policy if exists "Public Access" on storage.objects;
drop policy if exists "Authenticated Upload" on storage.objects;
drop policy if exists "User Update Own Files" on storage.objects;
drop policy if exists "User Delete Own Files" on storage.objects;
drop policy if exists "Public Read Access" on storage.objects;

-- Allow public read (for images/links)
create policy "Public Read Access"
on storage.objects for select
using ( bucket_id = 'chat-files' );

-- Allow authenticated upload
create policy "Authenticated Upload"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'chat-files' );

-- Allow user management
create policy "User Update Own Files"
on storage.objects for update
using ( bucket_id = 'chat-files' and auth.uid() = owner );

create policy "User Delete Own Files"
on storage.objects for delete
using ( bucket_id = 'chat-files' and auth.uid() = owner );

-- ==========================================
-- 8. Final Utilities
-- ==========================================

-- 8.1. Profile Backfill (Fix missing profiles)
insert into public.profiles (id, email, name, role, member_level)
select 
    id, 
    email, 
    '补录会员',
    'member',
    '普通会员'
from auth.users
where id not in (select id from public.profiles);

-- 8.2. Admin Setup Instructions (Commented)
/*
-- 注册 admin@gxas.org 账号后，执行以下命令将其设为管理员：
update profiles
set 
  role = 'admin', 
  member_level = '管理员',
  name = '系统管理员'
where email = 'admin@gxas.org';
*/

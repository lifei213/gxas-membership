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

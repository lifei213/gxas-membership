-- Create a function to handle application approval
create or replace function public.approve_application(app_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_name text;
begin
  -- 1. Get application details
  select user_id, name into v_user_id, v_name
  from public.membership_applications
  where id = app_id;

  if v_user_id is null then
    raise exception 'Application not found';
  end if;

  -- 2. Update application status
  update public.membership_applications
  set status = 'approved'
  where id = app_id;

  -- 3. Update profile
  update public.profiles
  set 
    member_level = '正式会员',
    name = v_name
  where id = v_user_id;
  
  -- If profile doesn't exist (rare case if trigger failed), insert it
  if not found then
    insert into public.profiles (id, name, member_level, role)
    values (v_user_id, v_name, '正式会员', 'member');
  end if;
end;
$$;

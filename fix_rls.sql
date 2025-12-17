-- 修复 "infinite recursion" (无限递归) 错误的 SQL 脚本
-- 请将以下所有代码复制并在 Supabase 的 SQL Editor 中执行

-- 1. 删除导致死循环的旧策略
drop policy if exists "Admin full access" on profiles;

-- 2. 创建一个“特权函数”来检查管理员身份
-- SECURITY DEFINER 意味着此函数以创建者（管理员）的权限运行，从而绕过 RLS 检查，打破死循环
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

-- 3. 重新创建管理员策略，调用上面的函数
create policy "Admin full access"
on profiles
for all
using ( public.is_admin() );

-- 4. 确保普通会员策略存在（如果之前已创建则会忽略或报错，这里仅作补充说明，无需重复执行如果已存在）
-- create policy "Member read own profile" on profiles for select using (auth.uid() = id);

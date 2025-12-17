-- 修复缺失的会员档案 (Profile)
-- 运行此脚本将为所有在 auth.users 中存在但在 profiles 表中不存在的用户自动创建档案

insert into public.profiles (id, email, name, role, member_level)
select 
    id, 
    email, 
    '补录会员',
    'member',
    '普通会员'
from auth.users
where id not in (select id from public.profiles);

-- 检查结果
select * from profiles;

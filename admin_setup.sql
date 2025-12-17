-- 设置管理员权限的 SQL 脚本
-- 使用方法：
-- 1. 先在网页端注册一个账号，邮箱填写: admin@gxas.org (密码自设，例如 123456)
-- 2. 注册成功后，在 Supabase SQL Editor 中执行此脚本

update profiles
set 
  role = 'admin', 
  member_level = '管理员',
  name = '系统管理员'
where email = 'admin@gxas.org';

-- 验证是否成功
select email, role, member_level from profiles where email = 'admin@gxas.org';

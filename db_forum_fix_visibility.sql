-- 修复论坛可见性问题的 SQL 脚本

-- 1. 确保 profiles 表允许公开读取（用于显示发帖人名字）
-- 先尝试删除可能存在的旧策略以避免冲突
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- 重新创建 profiles 策略
CREATE POLICY "Public profiles are viewable by everyone" 
ON profiles FOR SELECT 
USING (true);

CREATE POLICY "Users can insert their own profile" 
ON profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
USING (auth.uid() = id);

-- 2. 确保 posts 表允许公开读取
DROP POLICY IF EXISTS "Public read access for posts" ON posts;
CREATE POLICY "Public read access for posts" 
ON posts FOR SELECT 
USING (true);

-- 3. 确保 comments 表允许公开读取
DROP POLICY IF EXISTS "Public read access for comments" ON comments;
CREATE POLICY "Public read access for comments" 
ON comments FOR SELECT 
USING (true);

-- 4. 确保 forum_sections 表允许公开读取
DROP POLICY IF EXISTS "Public read access for sections" ON forum_sections;
CREATE POLICY "Public read access for sections" 
ON forum_sections FOR SELECT 
USING (true);

-- 5. 检查并修复可能缺失的 section_id 外键约束问题（防止脏数据）
-- 如果之前有数据 section_id 存错了，这里可以尝试修复，但通常 RLS 是主因。

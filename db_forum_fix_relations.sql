-- 修复帖子无法显示的关联问题 (Foreign Key Fix)

-- 问题原因：Supabase 需要明确的外键关联才能在查询帖子时自动“联表查询”作者信息。
-- 之前的设置是关联到 auth.users，现在我们需要改为关联到 profiles 表，
-- 这样前端代码 .select('*, author:profiles(name)') 才能正常工作。

-- 1. 修正 posts 表的作者关联
ALTER TABLE posts
  DROP CONSTRAINT IF EXISTS posts_author_id_fkey;

ALTER TABLE posts
  ADD CONSTRAINT posts_author_id_fkey
  FOREIGN KEY (author_id)
  REFERENCES profiles(id)
  ON DELETE CASCADE;

-- 2. 修正 comments 表的作者关联
ALTER TABLE comments
  DROP CONSTRAINT IF EXISTS comments_author_id_fkey;

ALTER TABLE comments
  ADD CONSTRAINT comments_author_id_fkey
  FOREIGN KEY (author_id)
  REFERENCES profiles(id)
  ON DELETE CASCADE;

-- 3. 修正 interactions 表的用户关联
ALTER TABLE interactions
  DROP CONSTRAINT IF EXISTS interactions_user_id_fkey;

ALTER TABLE interactions
  ADD CONSTRAINT interactions_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES profiles(id)
  ON DELETE CASCADE;

-- 4. 再次确保 RLS 策略允许读取 (双重保险)
DROP POLICY IF EXISTS "Public read access for posts" ON posts;
CREATE POLICY "Public read access for posts" ON posts FOR SELECT USING (true);

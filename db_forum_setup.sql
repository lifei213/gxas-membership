-- 1. Forum Sections Table
CREATE TABLE IF NOT EXISTS forum_sections (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  parent_id BIGINT REFERENCES forum_sections(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Posts Table
CREATE TABLE IF NOT EXISTS posts (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL, -- Rich text content
  author_id UUID NOT NULL REFERENCES auth.users(id),
  section_id BIGINT NOT NULL REFERENCES forum_sections(id),
  is_pinned BOOLEAN DEFAULT FALSE,
  is_essence BOOLEAN DEFAULT FALSE,
  view_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Comments Table
CREATE TABLE IF NOT EXISTS comments (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  author_id UUID NOT NULL REFERENCES auth.users(id),
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  parent_id BIGINT REFERENCES comments(id), -- Nested comments
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Interactions Table (Likes/Favorites)
CREATE TABLE IF NOT EXISTS interactions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  interaction_type VARCHAR(20) NOT NULL, -- 'like', 'favorite'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id, interaction_type)
);

-- 5. RLS Policies

-- Enable RLS
ALTER TABLE forum_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;

-- Policies for forum_sections
CREATE POLICY "Public read access for sections" ON forum_sections
  FOR SELECT USING (true);

-- Policies for posts
CREATE POLICY "Public read access for posts" ON posts
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own posts" ON posts
  FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own posts" ON posts
  FOR DELETE USING (auth.uid() = author_id);

-- Policies for comments
CREATE POLICY "Public read access for comments" ON comments
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create comments" ON comments
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own comments" ON comments
  FOR DELETE USING (auth.uid() = author_id);

-- Policies for interactions
CREATE POLICY "Public read access for interactions" ON interactions
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage interactions" ON interactions
  FOR ALL USING (auth.uid() = user_id);

-- 6. Helper Functions
-- Function to increment view count safely
CREATE OR REPLACE FUNCTION increment_view_count(post_id BIGINT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts
  SET view_count = view_count + 1
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Initial Data (Sections)
INSERT INTO forum_sections (name, description) VALUES
('学术交流', '探讨前沿学术问题，分享研究成果'),
('活动通知', '学会近期活动发布与讨论'),
('会员互助', '求助、答疑、资源共享'),
('灌水专区', '轻松话题，自由畅聊');

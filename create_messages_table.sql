-- Create messages table for user-admin communication
CREATE TABLE IF NOT EXISTS public.contact_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    reply_content TEXT,
    status TEXT DEFAULT 'unread' CHECK (status IN ('unread', 'read', 'replied')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    reply_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;

-- Policies

-- Users can view their own messages
CREATE POLICY "Users can view own messages" 
ON public.contact_messages FOR SELECT 
USING (auth.uid() = user_id);

-- Users can insert their own messages
CREATE POLICY "Users can insert own messages" 
ON public.contact_messages FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Admins can view all messages
CREATE POLICY "Admins can view all messages" 
ON public.contact_messages FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- Admins can update messages (to reply)
CREATE POLICY "Admins can update messages" 
ON public.contact_messages FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- Create the storage bucket for chat files
insert into storage.buckets (id, name, public)
values ('chat-files', 'chat-files', true)
on conflict (id) do nothing;

-- Set up security policies for the bucket

-- Allow public read access to all files in the bucket
create policy "Public Access"
  on storage.objects for select
  using ( bucket_id = 'chat-files' );

-- Allow authenticated users to upload files
create policy "Authenticated Upload"
  on storage.objects for insert
  with check ( bucket_id = 'chat-files' and auth.role() = 'authenticated' );

-- Allow users to update/delete their own files (Optional)
create policy "User Update Own Files"
  on storage.objects for update
  using ( bucket_id = 'chat-files' and auth.uid() = owner );

create policy "User Delete Own Files"
  on storage.objects for delete
  using ( bucket_id = 'chat-files' and auth.uid() = owner );

-- Lecture 2, after the CSV backups: empty the project for the Supabase prompt.
-- (The curriculum's prompt says "I've currently deleted all tables".)
--
-- Supabase → SQL Editor → paste → Run. Then Table Editor shows no tables.
-- The "dev: open access until auth" policies go with their tables.
--
-- Also works later (time-check backup): it removes a half-built auth version too.

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop function if exists public.create_task_with_tags(text, uuid, date, uuid, uuid[]);
drop function if exists public.create_task_with_tags(text, uuid, date, uuid[]);
drop table if exists public.task_tags, public.tasks, public.tags, public.projects, public.users cascade;

-- Accounts made before the trigger existed would have no public.users row,
-- so start with none. (Lecture 1's test user should already be deleted.)
delete from auth.users;

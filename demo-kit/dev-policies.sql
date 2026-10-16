-- TEMPORARY development access for Ticked (no logins yet).
--
-- Row Level Security is ON for every table, with no rules, so the publishable
-- (anon) key can't see or change anything: GET returns [] and POST is refused.
-- These rules open each table to the anon role, for development only.
--
-- Anyone with the publishable key can read and change these tables while
-- the rules exist. Real per-user rules (auth.uid()) replace them in the
-- authentication lecture.
--
-- Backup for Lecture 1: paste into Supabase → SQL Editor → Run.

create policy "dev: open access until auth" on public.users
  for all to anon using (true) with check (true);

create policy "dev: open access until auth" on public.projects
  for all to anon using (true) with check (true);

create policy "dev: open access until auth" on public.tasks
  for all to anon using (true) with check (true);

create policy "dev: open access until auth" on public.tags
  for all to anon using (true) with check (true);

create policy "dev: open access until auth" on public.task_tags
  for all to anon using (true) with check (true);

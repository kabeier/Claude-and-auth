-- After a dry run: put Supabase back to where Monday starts (Friday's end).
--
-- Supabase → SQL Editor → paste → Run. Then check:
--   Table Editor: 5 tables, a Demo User and 3 tasks.  Authentication → Users: empty.
--
-- Removes: the auth version of the tables, the trigger, every auth user.
-- Recreates: Friday's schema (start-ticked/supabase/schema.sql), the
-- "dev: open access until auth" rules, the Demo User and a few rows.

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop function if exists public.create_task_with_tags(text, uuid, date, uuid[]);
drop function if exists public.create_task_with_tags(text, uuid, date, uuid, uuid[]);
drop table if exists public.task_tags, public.tasks, public.tags, public.projects, public.users cascade;
delete from auth.users;

-- 1. users ---------------------------------------------------------------
-- Story 1: an account with a name and email.
create table public.users (
  id          uuid         primary key default gen_random_uuid(),
  name        varchar(100) not null,
  email       varchar(255) not null,
  created_at  timestamptz  not null default now()
);

create unique index users_email_lower_key on public.users (lower(email));

alter table public.users enable row level security;


-- 2. projects ------------------------------------------------------------
-- Story 2: projects with a name and an optional description.
create table public.projects (
  id           uuid         primary key default gen_random_uuid(),
  name         varchar(255) not null,
  description  text,
  user_id      uuid         references public.users (id) on delete set null,
  created_at   timestamptz  not null default now()
);

create index projects_user_id_idx on public.projects (user_id);

alter table public.projects enable row level security;


-- 3. tags ----------------------------------------------------------------
-- Story 7: labels like "school" or "urgent".
create table public.tags (
  id    uuid        primary key default gen_random_uuid(),
  name  varchar(50) not null unique
);

alter table public.tags enable row level security;


-- 4. tasks ---------------------------------------------------------------
-- Stories 3, 4, 5, 6, 8: title, optional project, optional due date,
-- complete flag, created time.
create table public.tasks (
  id           uuid         primary key default gen_random_uuid(),
  title        varchar(255) not null,
  is_complete  boolean      not null default false,
  due_date     date,
  project_id   uuid         references public.projects (id) on delete set null,
  user_id      uuid         references public.users (id) on delete set null,
  created_at   timestamptz  not null default now()
);

create index tasks_user_id_idx    on public.tasks (user_id);
create index tasks_project_id_idx on public.tasks (project_id);

alter table public.tasks enable row level security;


-- 5. task_tags -----------------------------------------------------------
-- Story 7: many-to-many join, a task can have several tags.
create table public.task_tags (
  task_id  uuid not null references public.tasks (id) on delete cascade,
  tag_id   uuid not null references public.tags (id)  on delete cascade,
  primary key (task_id, tag_id)
);

-- task_id is covered by the primary key; tag_id needs its own index.
create index task_tags_tag_id_idx on public.task_tags (tag_id);

alter table public.task_tags enable row level security;


-- 6. API: create_task_with_tags ------------------------------------------
-- Stories 3 and 7: save a new task and its tags in one go. The app calls
-- this as supabase.rpc('create_task_with_tags', {...}). It runs as one
-- transaction, so either the task and all its tags are saved, or nothing is
-- (for example, an unknown tag id leaves no half-made task behind).
-- It runs with the caller's permissions (security invoker), so row level
-- security still applies. Duplicate and null tag ids are ignored.
create or replace function public.create_task_with_tags(
  p_title      text,
  p_project_id uuid   default null,
  p_due_date   date   default null,
  p_user_id    uuid   default null,
  p_tag_ids    uuid[] default '{}'
)
returns public.tasks
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_task public.tasks;
begin
  insert into public.tasks (title, project_id, due_date, user_id)
  values (p_title, p_project_id, p_due_date, p_user_id)
  returning * into v_task;

  insert into public.task_tags (task_id, tag_id)
  select v_task.id, t.tag_id
  from (select distinct unnest(coalesce(p_tag_ids, '{}'::uuid[])) as tag_id) t
  where t.tag_id is not null;

  return v_task;
end;
$$;

revoke execute on function public.create_task_with_tags(text, uuid, date, uuid, uuid[]) from public;
grant execute on function public.create_task_with_tags(text, uuid, date, uuid, uuid[]) to anon, authenticated;


-- Friday's temporary rules ---------------------------------------------------
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


-- Friday's rows -----------------------------------------------------------
insert into public.users (name, email) values ('Demo User', 'demo@ticked.app');
insert into public.projects (name, description, user_id)
  select 'Gym', 'Workouts and stretching', id from public.users where email = 'demo@ticked.app';
insert into public.tags (name) values ('urgent'), ('errands');
insert into public.tasks (title, user_id, project_id)
  select t.title, u.id, case when t.gym then p.id end
  from public.users u
  cross join (values ('Finish the API lecture', false), ('Leg day', true), ('Buy groceries', false)) as t(title, gym)
  left join public.projects p on p.user_id = u.id
  where u.email = 'demo@ticked.app';

select (select count(*) from public.tasks) as tasks, (select count(*) from auth.users) as auth_users;

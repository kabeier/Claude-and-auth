# Prompts for the authentication lectures

Copy them from here during class. Each one says which folder Claude runs in. Lecture 1 has no Claude prompts (it's Postman); everything below is Lecture 2.

**Where:** every prompt runs in Claude in **`~/demos/ticked`**, the root. That's "the directory running your supabase project", because `.mcp.json` is there since Friday's restructure. Before pasting, run `/model` → Opus.

---

## Lecture 2, slide 4: drop the tables (after the CSV backups)

Ours, not the curriculum's. The curriculum's prompt (slide 5) assumes the project is already empty ("I've currently deleted all tables"); this is that step.

```text
I backed up all five tables to CSV in supabase/backups/. Using the Supabase MCP, drop every
table in the public schema (users, projects, tags, tasks, task_tags) and the
create_task_with_tags function, so the project is empty. Show me the SQL first and wait for
my approval.
```

**Backup:** paste `drop-tables.sql` into Supabase → SQL Editor → Run.

---

## Lecture 2, slide 5: the Supabase prompt (the curriculum's, paths filled in)

```text
I have confirmed my application works well with this type of database schema and am now ready to implement authentication methods to my project.

I would like you to take a look at the following resources:

1. User Journey can be found: front-end/app_outline/user_journey.md
2. The current supabase schema is as follows: supabase/schema.sql
3. The current testing data I've populated while ensuring this works is here: supabase/backups/

You should know that I've currently deleted all tables existing in my project and it is now an empty project.

Using these resources as context I would like you to conduct the following:

1. alter the user table function as an authentication table
2. ensure proper RLS policies are set where a user can only view the tasks they own.
3. recreate my database tables on supabase

After conducting each action, pause and ask for confirmation that your actions worked correctly before proceeding to the next step.

Do you have any questions before executing this task?
```

### Likely questions from Claude, and good answers

```text
- public.users: its id IS the auth.users id (foreign key, on delete cascade). Keep name and
  email. A trigger on auth.users creates the row; take the name from the sign-up metadata
  ("name"), or the part of the email before the @ if it's missing.
- projects.user_id and tasks.user_id: NOT NULL, default auth.uid(), on delete cascade.
  The app will never send a user id.
- RLS: every policy "to authenticated". users, projects, tasks: only your own rows, for
  select, insert, update and delete. tags have no user_id and stay shared: any logged-in
  user can read and add them. task_tags follow the owner of their task. No anon access.
  The old "dev: open access until auth" policies are gone with the tables; don't recreate them.
- create_task_with_tags: keep it, but remove p_user_id (the owner comes from auth.uid()).
  security invoker, executable by authenticated only.
- Backups: don't re-import them. Their rows belong to the Demo User, who has no login.
  Use them only to see what the data looks like.
- When you're done, replace supabase/schema.sql with the new schema, so the repo matches
  the database.
- Email confirmation is already turned off for development.
```

**What to check at each pause** (in the dashboard, before you say "confirmed, continue"):

| Claude's step | Where to look | You should see |
|---|---|---|
| 1 users as an auth table | Database → Functions; Database → Triggers | `handle_new_user`, and `on_auth_user_created` on `auth.users` |
| 2 RLS policies | Authentication → Policies | `auth.uid() = user_id` on tasks and projects, `to authenticated`, no "dev:" policies |
| 3 recreate the tables | Table Editor | 5 tables, all empty, RLS on (no "unrestricted" badge) |

(Claude may do the steps in a different order, for example tables before policies. That's fine: check each one when it pauses.)

**Backup:** `backup-ticked-auth/supabase/schema.sql` in the SQL Editor (needs the empty project from slide 4).

---

## Lecture 2, slide 9: the Vite + React prompt (the curriculum's, filled in)

Fill in your URL (no `/rest/v1`) and publishable key; both are in `front-end/.env`.

```text
Utilizing the following resources:

- Supabase db schema: supabase/schema.sql
- user journey: front-end/app_outline/user_journey.md
- Project API url: https://<your-project-id>.supabase.co
- Project API Key: sb_publishable_<your key>

I would like you to update the functionality for the User Authentication process. Consider the following actions a user can take:

- Register: A brand new user can sign up for our application and interact with our site.
- Log In: A returning user can interact with our site and ONLY their corresponding data
- Log out: A logged in user can end their session and exit our website while removing their credentials from the front-end code.
- User Confirmation: While logged in we need to have a way of confirming who the user is
    - while logged in if the user refreshes the browser, we should be able of leveraging the current credentials to recover the logged in `user` and their corresponding`data`

Each of these actions should be an independent phase. Utilize playwright to ensure completion of each phase prior to moving on to the next one.

Do you have any questions before completing these actions?
```

### Likely questions from Claude, and good answers

```text
- Pages: a Log in page (/login) and a Register page (/register). Register asks for name,
  email and password (at least 6 characters). Every other page needs a logged-in user;
  if nobody is logged in, go to /login.
- After register or log in, go to Tasks. The header shows the user's name and a Log out
  button (that's how the user confirms who they are).
- Keep ALL Supabase calls, auth included, in front-end/src/data/db.js (supabase-js).
  Put the logged-in user in a React context next to TaskContext.
- Remove the Demo User: delete VITE_DEMO_USER_ID and never send a user_id. The database
  fills it in with auth.uid().
- The URL and key are already in front-end/.env. Keep the variable names that are there.
  Never use the secret key.
- Email confirmation is off. For Playwright, register test accounts such as
  maria@ticked.app and sam@ticked.app (password: ticked123), and check that each one sees
  only their own tasks.
- Add the Register / Log in / Log out / refresh steps to user_journey.md.
- Don't change the rest of the UI.
```

**Backup:** see the RUNBOOK's time check (copy `backup-ticked-auth/front-end/src` over).

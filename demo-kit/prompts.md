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

**Approve if** the SQL drops only the 5 tables (`cascade` is fine) and `create_task_with_tags`.

**If Claude asks about `rls_auto_enable()`** (or any function you didn't write): **keep it.** It came with the Supabase project, not with Ticked. It turns RLS on for every new table, which is what we want when Claude rebuilds them. Answer:

```text
Keep rls_auto_enable(). Only drop the five tables and create_task_with_tags.
```

---

## Lecture 2, slide 5: the Supabase prompt (the curriculum's, paths filled in, plus an "Also for this project" block)

The "Also for this project" block is ours. It answers ahead of time what Claude asked in the dry run, and it adds the one thing the curriculum's prompt misses for Ticked: rebuilding `create_task_with_tags` (the drop step removed it, and `db.js` calls it to save a task).

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

Also for this project:
- Order: users, then the tables, then the RLS policies, then the function.
- users.id is the auth.users id. A trigger on auth.users creates the profile at sign-up (that trigger is fine to add). Keep name and email.
- projects.user_id and tasks.user_id: not null, default auth.uid(), on delete cascade. The app will never send a user id.
- RLS: own rows only, for every action. A task can only use my own project, and task_tags only my own tasks. No anon access. Tags: any signed-in user can read and add them, but not edit or delete.
- Start with empty tables. Don't re-import the backups: their rows belong to a Demo User who has no login.
- Recreate create_task_with_tags (my front end calls it): no p_user_id, security invoker, executable by authenticated only.
- Keep rls_auto_enable(). Database only: don't change the front end, that's my next prompt.
- Before applying each step, show me the complete SQL. When you're done, rewrite supabase/schema.sql to match, header comments included.

Do you have any questions before executing this task?
```

### Dry run 2 (with the block): Claude's 5 questions, and our reply

The block above now answers these, so you may not see them. If you do:

```text
1. Yes, the trigger on auth.users is fine. That's the one exception to "only my app's tables".
2. Keep email in public.users. This app doesn't let users change their email.
3. Yes to all of it.
4. Yes: read and add only, no edit or delete.
5. Separate task. Database only for now; I'll do the front end in my next prompt.
The plan is good. Go ahead with step 1.
```

### What Claude asked in the dry run (slide 6)

A tabbed question box. Pick option 1 (Recommended) every time:

| Claude asks | Pick | Why |
|---|---|---|
| How should `public.users` work as the authentication table? | **1 Profile linked to auth** | `id` references `auth.users(id) on delete cascade`; a trigger makes the row |
| Your backup rows belong to user ids that won't exist. What happens to the CSV data? | **1 Start empty** | The rows belong to the Demo User, who has no login |
| Tags are shared by every user. What should the RLS rules be? | **1 Shared, any signed-in user** | Tags have no `user_id`; `task_tags` follow their task's owner |
| RLS policies need the tables to exist. How should I sequence it? | **1 Users → tables → RLS** | Keeps a pause after each step; the tables start locked |

The question box doesn't take notes. Instead, **at the tables pause, read the SQL** and check:

- `projects.user_id` and `tasks.user_id` are `not null default auth.uid()`. If not: "Add default auth.uid() to projects.user_id and tasks.user_id."
- `create_task_with_tags` has no `p_user_id`. If not: "Remove p_user_id; the owner comes from auth.uid()."
- At the end, `supabase/schema.sql` is replaced with the new schema.

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

**When step 3 finishes**, Claude may offer extras. Reply:

```text
Confirmed, step 3 works. Don't change the front end or CLAUDE.md yet: that's my next prompt. Leave rls_auto_enable() and the leaked-password setting as they are.
```

- The Security Advisor may flag `rls_auto_enable()` as callable by anon/authenticated. Low risk: it's an event-trigger function, and Postgres won't run those through a normal call. Fine to leave for class.
- "Leaked password protection is off": a dashboard setting (Pro plan). Skip.
- "The front end won't work until db.js is updated": correct, and expected. That's the React prompt.

**What to check at each pause** (in the dashboard, before you say "confirmed, continue"):

| Claude's step | Where to look | You should see |
|---|---|---|
| 1 users as an auth table | Database → Functions; Database → Triggers (schema dropdown: **auth**) | `handle_new_user`, and `on_auth_user_created` on `auth.users` |
| 2 recreate the tables | Table Editor (and the SQL Claude ran) | 5 tables, all empty, RLS on (no "unrestricted" badge); `user_id` has `default auth.uid()` |
| 3 RLS policies | Authentication → Policies | `auth.uid() = user_id` on tasks and projects, `to authenticated`, no "dev:" policies |

(Claude may do the steps in a different order, for example tables before policies. That's fine: check each one when it pauses.)

**Backup:** `backup-ticked-auth/supabase/schema.sql` in the SQL Editor (needs the empty project from slide 4).

---

## Lecture 2, slide 11: the Vite + React prompt (the curriculum's, filled in)

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

### What Claude asked in the dry run (slide 12)

Pick option 1 (Recommended) every time:

| Claude asks | Pick | Why |
|---|---|---|
| What should the "User Confirmation" phase cover? | **1 Session survives refresh** | The curriculum means "confirm who is logged in", not the email link |
| Playwright can't open an inbox. How should the tests handle Confirm email? | **1 Turn confirmation off** | Already off since Lecture 1 |
| What should the Register form ask for? | **1 Name, email, password** | The name goes to the trigger through the sign-up metadata |
| Playwright creates real accounts. What happens to them? | **1 Delete after tests** | Clean Users list; frees maria@ / sam@ for the live payoff |

If Claude says the User Confirmation line was "cut off", it got the shortened version: paste the full prompt below.

### Likely questions from Claude, and good answers

```text
- Pages: a Log in page (/login) and a Register page (/register). Register asks for name,
  email and password (at least 6 characters). Every other page needs a logged-in user;
  if nobody is logged in, go to /login.
- After register or log in, go to Tasks. The header shows the user's name and a Log out
  button (that's how the user confirms who they are).
- Keep ALL Supabase calls, auth included, in front-end/src/data/db.js (supabase-js).
  Put the logged-in user in a React context next to TaskContext.
- Remove the Demo User: delete the demo user id variable (VITE_DEMO_USER_ID or VITE_DEFAULT_USER_ID, whichever .env has) and never send a user_id. The database
  fills it in with auth.uid().
- The URL and key are already in front-end/.env. Keep the variable names that are there.
  Never use the secret key.
- Email confirmation is off. For Playwright, use throwaway test accounts, check that each
  one sees only their own tasks, and delete them afterwards. (I'll register maria@ and
  sam@ticked.app myself afterwards.)
- Add the Register / Log in / Log out / refresh steps to user_journey.md.
- Don't change the rest of the UI.
```

**Backup:** see the RUNBOOK's time check (copy `backup-ticked-auth/front-end/src` over).

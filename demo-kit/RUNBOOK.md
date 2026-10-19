# Live demo runbook: Ticked gets logins

**The story:** on Friday, Ticked (front-end + Supabase) got connected, but it's an open house. Anyone with the publishable key can read and change everything.
- **Lecture 1 (How Authentication Works):** authentication vs authorization, 401 vs 403, four auth types, JWTs. Live: get a real access token in Postman, decode it, and see that Friday's `to anon` rules give a logged-in user `[]` and 403.
- **Lecture 2 (Supabase Authentication):** back up and drop the tables, run the curriculum's Supabase prompt (trigger + RLS + rebuild), then the Vite + React prompt (Register, Log in, Log out, refresh). Two accounts in two browsers, each sees only their own.

## What's in the kit

| File | What it is |
|---|---|
| `prompts.md` | Every prompt, in order, plus good answers to Claude's questions and what to check at each pause |
| `Ticked-Auth.postman_collection.json` | (step-by-step page: `postman/`) Lecture 1's Postman demo: sign up, log in, then GET/POST as anon vs as the user |
| `drop-tables.sql` | Backup for the drop prompt (also clears half-built auth tables and auth users) |
| `dev-policies.sql` | Friday's temporary rules (used by the reset) |
| `reset-to-start.sql` | After a dry run: Supabase back to Monday's start (Friday's tables, dev rules, Demo User, 3 tasks, no auth users) |
| `start-ticked/` | **The starting point:** Ticked as the class left it on Friday. No `.mcp.json` and no `.env`; both hold your project's details |
| `backup-ticked-auth/` | Ticked after Lecture 2. Tested against a local Supabase stack (Auth + PostgREST + Postgres). Its `README.md` is the handoff for the next instructor (also published as github.com/kabeier/ticked-handoff) |

## Setup (once, before Lecture 1)

```bash
cp -r /mnt/storage/CP/new_Lectures/claude-auth/demo-kit ~/auth-kit

cd ~/demos/ticked
git status                       # clean? If not: git add -A && git commit -m "Before auth"
claude mcp list                  # context7 and playwright connected
cat .mcp.json                    # supabase, in the ROOT (moved there Friday)

# Snapshot for resetting after the dry run
rm -rf ~/demos/ticked-auth-snapshot && cp -a ~/demos/ticked ~/demos/ticked-auth-snapshot
```

- **Postman:** if sign-up says `PGRST125 Invalid path`, `base_url` still ends in `/rest/v1` (check the environment dropdown: an environment variable beats the collection's).
- **Postman:** Import `~/auth-kit/Ticked-Auth.postman_collection.json`. In its Variables, set `base_url` (no `/rest/v1`) and `publishable_key`, the same values as Friday's collection. **Save.**
- **Check the env var name:** `grep VITE_ ~/demos/ticked/front-end/.env*`. The backup app reads `VITE_SUPABASE_PUBLISHABLE_KEY`. If you only have `VITE_SUPABASE_ANON_KEY`, add a second line with the same value: `VITE_SUPABASE_PUBLISHABLE_KEY=…`.

## Dry run (the night before), then reset

1. Run both lectures' live steps from the tables below. Note what Claude asks and how long each prompt takes.
2. Reset the folder:
   ```bash
   rm -rf ~/demos/ticked && cp -a ~/demos/ticked-auth-snapshot ~/demos/ticked
   ```
3. Reset Supabase: SQL Editor → paste `reset-to-start.sql` → Run. It ends with `tasks = 3, auth_users = 0`.
4. **Leave Confirm email OFF** if you want to skip that step in class, or turn it back on to show it live.
5. Delete the downloaded CSVs from Downloads.

## Lecture 1 in class (How Authentication Works)

| Slide (~min) | Where | Do | Say |
|---|---|---|---|
| 2 (~1) | Postman | Friday's collection: `GET {{base_url}}/rest/v1/users` → the Demo User's email | "This key is in every browser." |
| 5 (~8) | browser | `activity-bouncer-or-vip/`, 6-minute countdown on the slide | — |
| 10 (~26) | Supabase | Authentication → Sign In / Providers → Email → **Confirm email OFF** → Save | "Real apps keep it on." |
| 10 | Postman | "Ticked Auth" → **1 Sign up** → 200 + tokens. Supabase → Authentication → Users: the new account | "auth.users, not our users table" |
| 10 | browser | JWT X-ray: paste `access_token` → `sub`, `role`, `exp` | "Readable by anyone, fakeable by no one." |
| 10 | Postman | **3** anon GET → all tasks. **4** user GET → `[]`. **5** user POST → **403** | "Logged in, and you see less than a stranger." |
| 11 (~31) | Supabase | Explain with the diagram, then **delete `test@ticked.app`** (Authentication → Users) | "The trigger only fires for new accounts." |
| 12 (~33) | slide | Why `[]` but 403: reading = a filter, writing = a gate | "Authentication worked. Authorization has no rule for us yet." |

## Lecture 2 in class (Supabase Authentication)

| Slide (~min) | Where | Do | Say |
|---|---|---|---|
| 4 (~4) | Supabase + terminal | Table Editor → each of the 5 tables → Export → CSV. `mkdir -p supabase/backups`, move the CSVs in. Claude (root, `/model` → Opus): the drop prompt → read SQL → approve | "Never drop what you can't restore." |
| 5 (~8) | Claude | Paste the Supabase prompt | "Pause and ask for confirmation: we're the test." |
| 6 (~10) | Claude | Its 4 questions: pick option 1 (Recommended) for each. then Submit | "Every answer is its Recommended one, and here's why." |
| 7–8 (~11) | Claude + dashboard | At each pause, in order: Triggers/Functions, Table Editor, Policies (prompts.md table). At the tables pause, check the SQL has `user_id … default auth.uid()`. "Confirmed, continue." | — |
| 10 (~19) | Claude | Paste the Vite + React prompt (the full text, from prompts.md or the slide) | "Four phases, each proven with Playwright." |
| 11 (~20) | Claude | Its 4 questions: option 1 each (refresh, confirm off, name+email+password, delete test users). Submit, approve the plan, allow edits for the session | — |
| 12 (~21) | browser | `activity-what-comes-back/` while Claude builds | — |
| 13 (~27) | Claude | Approve Playwright/MCP calls. Watch each phase pass (its test accounts get deleted after) | "Claude is testing like a user would." |
| 14 (~30) | 2 browsers | `cd front-end && npm run dev`. Maria (normal window) adds "Leg day"; Sam (private window) sees nothing. Refresh Maria. DevTools: Network → Bearer; Application → Local Storage. Log out | "Same key, different token." |
| 15 (~35) | terminal | `git status` (no .env), commit | — |

**Time check, Lecture 2:** the two prompts are the risky part.

- **Database not done by ~min 17:**
  1. Esc.
  2. SQL Editor: run `drop-tables.sql`, then `backup-ticked-auth/supabase/schema.sql`.
  3. `cp ~/auth-kit/backup-ticked-auth/supabase/schema.sql ~/demos/ticked/supabase/schema.sql`
  4. Go on to the React prompt.
- **Front end not on Log out by ~min 31:**
  1. Esc.
  2. Undo its half-done changes:
     ```bash
     cd ~/demos/ticked && git checkout -- front-end && git clean -fd front-end/src
     ```
  3. Copy the backup's `src` in:
     ```bash
     cp -r ~/auth-kit/backup-ticked-auth/front-end/src ~/demos/ticked/front-end/
     ```
  4. The backup needs the backup schema, because its `create_task_with_tags` has no `p_user_id`. If Claude's schema differs, run `drop-tables.sql` + `backup-ticked-auth/supabase/schema.sql` in the SQL Editor.
  5. `npm run dev` and do the payoff. Say: "This is what Claude was building." Open `src/data/db.js` and `src/context/AuthContext.jsx`.

## Things to expect

- **Claude asks whether to drop `rls_auto_enable()`:** no. It's Supabase's, not ours: it turns RLS on for new tables. Drop only the 5 tables and `create_task_with_tags`.
- **Claude asks to re-import the backups:** say no. Their rows belong to the Demo User, who has no account, so `user_id` would point at nobody.
- **Claude wants to keep `p_user_id`** in `create_task_with_tags`: ask it to drop the parameter and rely on `default auth.uid()`. Otherwise a user could create tasks for someone else (RLS would stop it with 403, but the parameter is pointless).
- **"Email not confirmed" / Playwright stuck at "check your email":** Confirm email got turned back on. Turn it off, then delete the stuck user in Authentication → Users.
- **"email rate limit exceeded":** Confirm email is on and Supabase's built-in sender has hit its hourly limit. Same fix.
- **Register works but saving a task fails with a foreign-key error:** the account existed before the trigger, so it has no `public.users` row. Delete it in Authentication → Users and register again.
- **A logged-in user sees `[]` for everything:** RLS is on with no `to authenticated` policies (or Friday's `to anon` ones survived). Check Authentication → Policies.
- **401 vs 403:** anon refused → 401; logged in and refused → 403; deleting someone else's row → 204 with nothing deleted.
- **Bearer:** Friday it carried the publishable key; now supabase-js puts the user's access token there. The `apikey` header stays the publishable key.

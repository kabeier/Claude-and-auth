# Claude and Authentication

Two ~40-minute lectures for Code Platoon Phase III, Building Applications → Authentication. Live site: https://kabeier.github.io/Claude-and-auth/

Each deck is a single HTML file. Open it, press **P** for presenter notes in a second window, **T** to start the lecture clock, **O** for the slide overview, **F** for fullscreen.

## Lecture 1: How Authentication Works (~40 min, 14 slides)

| ~min | Segment |
|---|---|
| 0–3 | Open: Ticked is an open house (Postman reads every email) |
| 3–8 | Authentication vs authorization, 401 vs 403 |
| 8–14 | Activity: Bouncer or VIP List? (the only activity) |
| 14–20 | Four ways to log in; which fits a React SPA on Supabase |
| 20–26 | JWTs; access + refresh tokens |
| 26–35 | Live: sign up in Postman, decode the token, `[]` and 403 as a logged-in user; how Postgres knows who's asking |
| 35–40 | Wrap up, homework Part I |

## Lecture 2: Supabase Authentication (~40 min, 17 slides)

| ~min | Segment |
|---|---|
| 0–4 | Open; the plan (auth.users → trigger → public.users → RLS) |
| 4–8 | Live: back up all 5 tables to CSV, Claude drops them |
| 8–17 | The curriculum's Supabase prompt; check each pause in the dashboard |
| 17–21 | The four workflows; the curriculum's Vite + React prompt |
| 21–27 | Activity: What Comes Back? (while Claude builds) |
| 27–35 | Claude verifies each phase with Playwright; two accounts in two browsers |
| 35–40 | Commit, wrap up, homework Part II |

## Folder map

- `index.html`: the class landing page, with homework steps for Part I and Part II
- `lecture-1-how-auth-works/`: slides, Bouncer or VIP List?, JWT X-ray
- `lecture-2-supabase-auth/`: slides, What Comes Back?
- `demo-kit/`: everything for the live demos. Start with `RUNBOOK.md`
  - `start-ticked/`: the starting point, Ticked as the class left it after the full-stack lectures (no `.mcp.json`, no `.env`)
  - `backup-ticked-auth/`: a reference build with logins (the backup for class). The class's own finished version, built live on Monday, is published for the next instructor as [kabeier/ticked-handoff](https://github.com/kabeier/ticked-handoff)
- `diagrams/`: tldraw diagrams (`.png` + editable `.tldr`)
- `shared/`: the slide engine (same as the earlier lecture sites)

## Notes on choices

- **Both prompts are the curriculum's, word for word**, with Ticked's paths filled in. Good answers to Claude's likely questions are in `demo-kit/prompts.md`.
- **Lecture 1 is live too:** a real sign-up in Postman shows that Friday's `to anon` dev rules give a logged-in user `[]` and 403. That sets up both 401 vs 403 and Lecture 2's rebuild.
- **All five tables are backed up**, not just users and tasks. The backups are context for Claude, not re-imported: their rows belong to the Demo User, who has no login.
- **Nothing in the app sends a user id:** `user_id` defaults to `auth.uid()`, and RLS checks it.
- **Tested:** the backup schema and app were run against a local Supabase stack (Auth, PostgREST, Postgres): trigger, every policy, 401/403/204 cases, and register / log in / log out / refresh in a browser.

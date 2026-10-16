# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Ticked is a mobile-first task manager: tasks, projects, tags, due dates, tick to complete. The repo has two halves:

- `front-end/`: the React SPA. It was built from the specs in `front-end/app_outline/` (read `user_journey.md` first, then `app.png`, then `pages/*/user_story.md` and the wireframe next to each, then `style_guide.md`).
- `supabase/`: the database design for the Supabase back-end (`user_stories.md`, `task-manager-erd.png`, `schema.sql`).

The front end reads and writes the live Supabase project (ref in `.mcp.json`) through its auto-generated REST API, using supabase-js and the publishable key. Data persists across refresh; there is no seed data. There is no login: every new project and task is owned by one fixed demo user (`VITE_DEMO_USER_ID`, the "Demo User" row), and every list shows all rows.

## Commands

Run these from `front-end/`. Copy `.env.example` to `.env.local` first (gitignored) and fill in `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` and `VITE_DEMO_USER_ID`; a build also needs them.

```bash
npm install
npm run dev       # http://localhost:5173
npm run lint      # oxlint
npm run build     # BASE=/sub/path/ npm run build for a sub-folder deploy
```

## Front end (`front-end/`)

- **Stack:** React 19 + Vite + React Router DOM (`BrowserRouter`, `basename` = Vite's `BASE_URL`).
- **Routes** (`src/App.jsx`): `/` Tasks, `/tasks/new` New Task (`?project=<id>` pre-picks a project), `/projects` Projects, `/projects/:id` Project Detail, `*` Not Found.
- **Data layer: `src/data/db.js` is the ONLY file that reads or changes data.** It creates the Supabase client (lazily, so missing env vars show in the ErrorBanner) and turns every Supabase `{ error }` into a thrown `Error`. The exports kept the names and return shapes they had when the data was in-memory arrays, so the UI didn't change:
  - `listProjects`, `createProject`, `deleteProject`
  - `listTasks` (`select('*, tags(id, name)')`, each task returned with `tags: [{ id, name }]`), `createTask` (calls the `create_task_with_tags` RPC), `setTaskComplete`, `deleteTask`
  - `listTags`, `createTag`
  - Order: projects oldest first, tasks newest first, tags A→Z (the tags table has no `created_at`).
- **State:** `src/context/TaskContext.jsx` loads everything through `db.js` on mount and exposes the data, `loading`, `error`, and actions. Components read it with `useTasks()` (`src/context/useTasks.js`).
- **Pages** in `src/pages/`, shared UI in `src/components/` (TaskRow, TaskList, ConfirmDialog, Toast, ErrorBanner, BottomNav, …), helpers in `src/utils/` (dates, task sorting, tag colors).
- `src/main.jsx` handles the GitHub Pages `?p=` deep-link redirect.
- `screenshots/` holds screenshots of the four pages.

## Database (`supabase/`)

- `user_stories.md`: the 8 stories the database has to remember (story 1, user accounts, has no page yet).
- `task-manager-erd.png`: the ERD (DrawSQL).
- `schema.sql`: Postgres DDL for five tables, in creation order: `users`, `projects`, `tags`, `tasks`, `task_tags`. Its header comment lists the approved changes from the diagram.
  - UUID primary keys (`gen_random_uuid()`), `created_at timestamptz default now()`.
  - Deleting a project or user sets `project_id` / `user_id` to null (tasks are kept). Deleting a task or tag cascades to `task_tags`.
  - Email unique case-insensitively; tags are global (no `user_id`); index on every foreign key.
  - Section 6, `create_task_with_tags(p_title, p_project_id, p_due_date, p_user_id, p_tag_ids)`: the one custom endpoint (`POST /rest/v1/rpc/create_task_with_tags`). It inserts a task and its `task_tags` rows in one transaction and returns the task row. SECURITY INVOKER, so it follows the caller's RLS.
  - RLS is enabled on every table with no policies in the file.
  - **Temporary:** the live Supabase project has open dev policies for the `anon` role on all 5 tables so the app can read and write before login exists (policy "dev: open access until auth", migration `dev_open_access_until_auth`). These are not in `schema.sql`, and anyone with the publishable key can read `users.email`, so keep only test data in the database. They get dropped and replaced with real per-user policies when users and auth are added on Monday 2026-10-19; don't build on them.
- `.mcp.json` (repo root) connects the Supabase MCP server to the project.

## Conventions

- Keep all front-end data access in `front-end/src/data/db.js`; components never call Supabase directly.
- Column names match the database: `id` (UUID), `created_at`, `is_complete`, `due_date` (`YYYY-MM-DD` or null), `project_id` (or null). Keep `db.js` and `schema.sql` in step.
- Deleting a project keeps its tasks (their `project_id` becomes null). Deleting a task removes its `task_tags` rows.
- Validation messages, empty states and confirm dialogs use the exact wording in the user stories.
- Mobile-first, 44px touch targets, real form controls with labels, visible focus, `prefers-reduced-motion` respected.

## Agents and skills

- `.claude/agents/front-end-agent.md`: front-end specialist (Context7, Playwright, Chrome DevTools MCPs).
- `.claude/skills/`: front-end design skills (frontend-design, ui-ux-pro-max, taste-skill, design-motion-principles) and `postgresql-table-design` for schema work.

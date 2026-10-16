# Ticked (Task Manager)

A small task manager built with React, Vite and React Router: add tasks, group them into
projects, tag them, give them due dates, and tick them off. It was built from the specs in
[`front-end/app_outline/`](front-end/app_outline/) (user journey, style guide, wireframes and a user story per page).

The app's data lives in a Supabase (Postgres) database designed in [`supabase/`](supabase/), so it
**persists across refreshes**. There's no login yet: everything the app creates belongs to one demo user.

## What's in this folder

This is the project as it stands after the SPA lectures plus the database design, along with the context Claude Code used to build it.

- `front-end/`: the React app
  - `app_outline/`: the plan (user journey, `app.png`, style guide, one folder per page with a wireframe and a user story)
  - `src/`, `public/`, `index.html`, package and Vite/oxlint config
  - `screenshots/`: one screenshot per page
- `supabase/`: the database design
  - `user_stories.md`: what the database has to remember
  - `task-manager-erd.png`: the ERD
  - `schema.sql`: the tables, keys and indexes
- `.mcp.json`: connects Claude Code to the Supabase MCP server
- `CLAUDE.md`: project notes for Claude Code (front end and database)
- `.claude/skills/`: the four design skills (frontend-design, ui-ux-pro-max, taste-skill, design-motion-principles) and postgresql-table-design
- `.claude/agents/front-end-agent.md`: the front-end sub-agent

## Run it

```bash
cd front-end
cp .env.example .env.local   # then fill in the Supabase URL, publishable key and demo user id
npm install && npm run dev
```

## Where the data lives

Every read and write goes through **one file: [`front-end/src/data/db.js`](front-end/src/data/db.js)**. It exports async
functions (`listTasks`, `createTask`, `deleteProject`, ...) that call Supabase's auto-generated REST API
(for example `GET /rest/v1/tasks?select=*,tags(id,name)`), plus one database function,
`POST /rest/v1/rpc/create_task_with_tags`, that saves a task and its tags together. It started out as four
in-memory arrays; swapping them for Supabase changed only that file, and `front-end/src/context/TaskContext.jsx` and the pages stayed the same.

## Pages

| Route | Page |
| --- | --- |
| `/` | Tasks: everything, filter by status and tag |
| `/tasks/new` | New Task (`?project=<id>` pre-picks a project) |
| `/projects` | Projects + new project form |
| `/projects/:id` | One project and its tasks |

Building for GitHub Pages in a sub-folder: `cd front-end && BASE=/Databases-and-Supabase/task-manager/ npm run build`.

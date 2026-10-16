// =====================================================================
// db.js: the ONLY file in Ticked that reads or changes data.
//
// The data now lives in a real Supabase (Postgres) database, in the
// tables from schema.sql:
//
//   projects   (id, name, description, user_id, created_at)
//   tasks      (id, title, is_complete, due_date, project_id, user_id, created_at)
//   tags       (id, name)
//   task_tags  (task_id, tag_id)   <- joins tasks and tags (many-to-many)
//
// Because the data is stored on a server, refreshing the browser no
// longer resets anything: what you create is still there next time.
//
// Every function is `async` and returns a Promise, because the database
// answers over the network. Each one is a call to Supabase's
// auto-generated REST API, for example:
//
//   listTasks()   ->  GET  /rest/v1/tasks?select=*,tags(id,name)
//   createTag()   ->  POST /rest/v1/tags
//   createTask()  ->  POST /rest/v1/rpc/create_task_with_tags
//
// The names, arguments and return shapes did not change when we swapped
// the old in-memory arrays for these calls, so the rest of the app
// (context, pages, components) didn't have to change at all.
//
// There is no login yet. New projects and tasks are given to one fixed
// demo user, and every list shows ALL rows no matter who owns them.
// =====================================================================

import { createClient } from '@supabase/supabase-js'

// ---------- the connection ----------

// The client is made the first time we need it (not when the file loads),
// so a missing setting becomes an error the app can show in its banner
// instead of a blank page.
let client = null

function supabase() {
  if (client) return client

  const url = import.meta.env.VITE_SUPABASE_URL
  const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY
  if (!url || !key) {
    throw new Error(
      'Supabase is not configured. Copy .env.example to .env.local and fill in VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY.',
    )
  }

  client = createClient(url, key)
  return client
}

// The demo owner for new rows (until real users exist).
function demoUserId() {
  const id = import.meta.env.VITE_DEMO_USER_ID
  if (!id) {
    throw new Error('Missing VITE_DEMO_USER_ID. Add it to .env.local (see .env.example).')
  }
  return id
}

// Supabase reports problems as `{ error }` instead of throwing.
// We turn that into a normal Error, and hand back the data otherwise.
function unwrap({ data, error }) {
  if (error) throw new Error(error.message)
  return data
}

// =====================================================================
// PROJECTS
// =====================================================================

// All projects, oldest first.
export async function listProjects() {
  return unwrap(
    await supabase()
      .from('projects')
      .select('id, name, description, user_id, created_at')
      .order('created_at', { ascending: true }),
  )
}

// Add a project (owned by the demo user). Returns the new row.
export async function createProject({ name, description }) {
  return unwrap(
    await supabase()
      .from('projects')
      .insert({ name: name, description: description || null, user_id: demoUserId() })
      .select()
      .single(),
  )
}

// Remove a project. Its tasks stay, but lose their project
// (the database does this itself: ON DELETE SET NULL in schema.sql).
export async function deleteProject(id) {
  unwrap(await supabase().from('projects').delete().eq('id', id))
}

// =====================================================================
// TASKS
// =====================================================================

// All tasks, newest first. `tags(id, name)` asks Supabase to follow
// task_tags and bring each task's tags along as a `tags` array
// ([{ id, name }, ...]), sorted by name.
export async function listTasks() {
  return unwrap(
    await supabase()
      .from('tasks')
      .select('*, tags(id, name)')
      .order('created_at', { ascending: false })
      .order('name', { referencedTable: 'tags', ascending: true }),
  )
}

// Add a task (not complete yet) and link it to its tags. Returns the new row.
// A plain insert can't write two tables at once, so we call a database
// function (an RPC) that creates the task and its task_tags rows together:
// either everything is saved, or nothing is.
export async function createTask({ title, project_id, due_date, tagIds }) {
  return unwrap(
    await supabase().rpc('create_task_with_tags', {
      p_title: title,
      p_project_id: project_id || null,
      p_due_date: due_date || null,
      p_user_id: demoUserId(),
      p_tag_ids: tagIds || [],
    }),
  )
}

// Tick a task off (true) or re-open it (false).
export async function setTaskComplete(id, is_complete) {
  unwrap(await supabase().from('tasks').update({ is_complete: is_complete }).eq('id', id))
}

// Remove a task. Its task_tags rows go with it
// (the database does this itself: ON DELETE CASCADE in schema.sql).
export async function deleteTask(id) {
  unwrap(await supabase().from('tasks').delete().eq('id', id))
}

// =====================================================================
// TAGS
// =====================================================================

// All tags, A to Z (the tags table has no created_at to sort by).
export async function listTags() {
  return unwrap(
    await supabase().from('tags').select('id, name').order('name', { ascending: true }),
  )
}

// Add a tag. Returns the new row.
export async function createTag(name) {
  return unwrap(await supabase().from('tags').insert({ name: name }).select('id, name').single())
}

import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Tasks from './pages/Tasks'
import NewTask from './pages/NewTask'
import Projects from './pages/Projects'
import ProjectDetail from './pages/ProjectDetail'
import NotFound from './pages/NotFound'

export default function App() {
  return (
    <Routes>
      {/* Layout renders the header, bottom nav + <Outlet/> for the current page */}
      <Route element={<Layout />}>
        <Route path="/" element={<Tasks />} />
        <Route path="/tasks/new" element={<NewTask />} />
        <Route path="/projects" element={<Projects />} />
        <Route path="/projects/:id" element={<ProjectDetail />} />
        <Route path="*" element={<NotFound />} />
      </Route>
    </Routes>
  )
}

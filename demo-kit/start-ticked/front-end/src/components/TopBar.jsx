import { Link } from 'react-router-dom'
import { TickedMark } from './Icons'
import NavLinks from './NavLinks'

// App name at the top. On wide screens the nav links move up here too.
export default function TopBar() {
  return (
    <header className="topbar">
      <Link to="/" className="brand" aria-label="Ticked, go to Tasks">
        <TickedMark />
        <span className="brand-name">Ticked</span>
      </Link>
      <nav className="topnav" aria-label="Main">
        <NavLinks />
      </nav>
    </header>
  )
}

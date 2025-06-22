import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { cn } from '../../lib/utils'
import { 
  LayoutDashboard, 
  Users, 
  Handshake, 
  MapPin, 
  Calendar, 
  DollarSign, 
  Megaphone, 
  BarChart3, 
  Settings,
  Menu,
  X,
  Music
} from 'lucide-react'

interface NavItem {
  id: string
  label: string
  icon: React.ElementType
  path: string
  badge?: number
}

const navItems: NavItem[] = [
  {
    id: 'dashboard',
    label: 'Dashboard',
    icon: LayoutDashboard,
    path: '/'
  },
  {
    id: 'contacts',
    label: 'Contacts',
    icon: Users,
    path: '/contacts'
  },
  {
    id: 'deals',
    label: 'Deals',
    icon: Handshake,
    path: '/deals',
    badge: 3
  },
  {
    id: 'tour-planner',
    label: 'Tour Planner',
    icon: MapPin,
    path: '/tour-planner'
  },
  {
    id: 'calendar',
    label: 'Calendar',
    icon: Calendar,
    path: '/calendar'
  },
  {
    id: 'finance',
    label: 'Finance',
    icon: DollarSign,
    path: '/finance'
  },
  {
    id: 'media-pr',
    label: 'Media & PR',
    icon: Megaphone,
    path: '/media-pr'
  },
  {
    id: 'analytics',
    label: 'Analytics',
    icon: BarChart3,
    path: '/analytics'
  },
  {
    id: 'settings',
    label: 'Settings',
    icon: Settings,
    path: '/settings'
  }
]

interface SidebarProps {
  className?: string
}

export function Sidebar({ className }: SidebarProps) {
  const [isCollapsed, setIsCollapsed] = useState(false)
  const [isMobileOpen, setIsMobileOpen] = useState(false)
  const location = useLocation()

  const toggleCollapse = () => setIsCollapsed(!isCollapsed)
  const toggleMobile = () => setIsMobileOpen(!isMobileOpen)

  return (
    <>
      {/* Mobile menu button */}
      <button
        onClick={toggleMobile}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-lg bg-card border border-border text-foreground"
      >
        {isMobileOpen ? <X size={20} /> : <Menu size={20} />}
      </button>

      {/* Mobile overlay */}
      {isMobileOpen && (
        <div 
          className="lg:hidden fixed inset-0 bg-black/50 z-40"
          onClick={toggleMobile}
        />
      )}

      {/* Sidebar */}
      <aside className={cn(
        "fixed left-0 top-0 z-40 h-screen transition-all duration-300 border-r border-border bg-card",
        isCollapsed ? "w-16" : "w-64",
        isMobileOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0",
        className
      )}>
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between p-4 border-b border-border">
            <div className={cn(
              "flex items-center gap-2 transition-opacity duration-300",
              isCollapsed && "lg:opacity-0"
            )}>
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-primary">
                <Music className="w-5 h-5 text-primary-foreground" />
              </div>
              <div className="flex flex-col">
                <h1 className="text-lg font-bold text-foreground">IndieBooking</h1>
                <p className="text-xs text-muted-foreground">CRM</p>
              </div>
            </div>
            
            <button
              onClick={toggleCollapse}
              className="hidden lg:flex p-1.5 rounded-md hover:bg-muted transition-colors"
            >
              <Menu size={16} />
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = location.pathname === item.path
              
              return (
                <Link
                  key={item.id}
                  to={item.path}
                  onClick={() => setIsMobileOpen(false)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all duration-200 group relative",
                    isActive 
                      ? "bg-primary text-primary-foreground shadow-sm" 
                      : "text-muted-foreground hover:text-foreground hover:bg-muted",
                    isCollapsed && "lg:justify-center"
                  )}
                >
                  <Icon size={20} className="flex-shrink-0" />
                  
                  <span className={cn(
                    "font-medium transition-opacity duration-300",
                    isCollapsed && "lg:opacity-0 lg:absolute lg:left-12 lg:bg-card lg:px-2 lg:py-1 lg:rounded lg:shadow-lg lg:border lg:border-border lg:z-50 lg:whitespace-nowrap lg:group-hover:opacity-100"
                  )}>
                    {item.label}
                  </span>

                  {/* Badge */}
                  {item.badge && (
                    <div className={cn(
                      "ml-auto flex items-center justify-center w-5 h-5 text-xs font-medium bg-primary text-primary-foreground rounded-full",
                      isCollapsed && "lg:absolute lg:top-1 lg:right-1 lg:w-4 lg:h-4"
                    )}>
                      {item.badge}
                    </div>
                  )}
                </Link>
              )
            })}
          </nav>

          {/* Footer */}
          <div className="p-4 border-t border-border">
            <div className={cn(
              "flex items-center gap-3 p-3 rounded-lg bg-muted/50",
              isCollapsed && "lg:justify-center"
            )}>
              <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
                <span className="text-sm font-medium text-primary-foreground">JD</span>
              </div>
              
              <div className={cn(
                "flex flex-col transition-opacity duration-300",
                isCollapsed && "lg:opacity-0"
              )}>
                <p className="text-sm font-medium text-foreground">John Doe</p>
                <p className="text-xs text-muted-foreground">Booker/Agent</p>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </>
  )
}

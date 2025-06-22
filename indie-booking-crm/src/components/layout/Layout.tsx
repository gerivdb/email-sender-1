import { ReactNode } from 'react'
import { Sidebar } from './Sidebar'
import { FloatingActionButton } from './FloatingActionButton'
import { cn } from '../../lib/utils'

interface LayoutProps {
  children: ReactNode
  className?: string
}

export function Layout({ children, className }: LayoutProps) {
  return (
    <div className="min-h-screen bg-background">
      <Sidebar />
      
      {/* Main content */}
      <main className={cn(
        "lg:ml-64 transition-all duration-300",
        className
      )}>
        <div className="p-4 lg:p-6 pt-16 lg:pt-6">
          {children}
        </div>
      </main>

      {/* Floating Action Button */}
      <FloatingActionButton />
    </div>
  )
}

import { useState } from 'react'
import { useLocation } from 'react-router-dom'
import { Plus, X, Users, Handshake, MapPin, DollarSign, Megaphone } from 'lucide-react'
import { cn } from '../../lib/utils'

interface QuickAction {
  id: string
  label: string
  icon: React.ElementType
  action: () => void
  color?: string
}

export function FloatingActionButton() {
  const [isOpen, setIsOpen] = useState(false)
  const location = useLocation()

  // Actions rapides basées sur la page actuelle
  const getQuickActions = (): QuickAction[] => {
    const basePath = location.pathname

    const actions: Record<string, QuickAction[]> = {
      '/contacts': [
        {
          id: 'new-contact',
          label: 'Nouveau Contact',
          icon: Users,
          action: () => {
            console.log('Nouveau contact')
            setIsOpen(false)
          }
        }
      ],
      '/deals': [
        {
          id: 'new-deal',
          label: 'Nouveau Deal',
          icon: Handshake,
          action: () => {
            console.log('Nouveau deal')
            setIsOpen(false)
          }
        }
      ],
      '/tour-planner': [
        {
          id: 'new-tour',
          label: 'Nouvelle Tournée',
          icon: MapPin,
          action: () => {
            console.log('Nouvelle tournée')
            setIsOpen(false)
          }
        }
      ],
      '/finance': [
        {
          id: 'new-invoice',
          label: 'Nouvelle Facture',
          icon: DollarSign,
          action: () => {
            console.log('Nouvelle facture')
            setIsOpen(false)
          }
        }
      ],
      '/media-pr': [
        {
          id: 'new-campaign',
          label: 'Nouvelle Campagne',
          icon: Megaphone,
          action: () => {
            console.log('Nouvelle campagne')
            setIsOpen(false)
          }
        }
      ]
    }

    // Actions communes
    const commonActions: QuickAction[] = [
      {
        id: 'new-contact',
        label: 'Contact',
        icon: Users,
        action: () => {
          console.log('Nouveau contact')
          setIsOpen(false)
        }
      },
      {
        id: 'new-deal',
        label: 'Deal',
        icon: Handshake,
        action: () => {
          console.log('Nouveau deal')
          setIsOpen(false)
        }
      }
    ]

    return actions[basePath] || commonActions
  }

  const quickActions = getQuickActions()

  return (
    <div className="fixed bottom-6 right-6 z-50">
      {/* Actions rapides */}
      {isOpen && (
        <div className="mb-4 space-y-3">
          {quickActions.map((action, index) => {
            const Icon = action.icon
            return (
              <div
                key={action.id}
                className={cn(
                  "flex items-center gap-3 opacity-0 animate-in slide-in-from-bottom duration-300",
                  `animation-delay-${index * 100}`
                )}
                style={{ animationDelay: `${index * 100}ms` }}
              >
                <span className="px-3 py-2 bg-card border border-border rounded-lg text-sm font-medium text-foreground shadow-lg">
                  {action.label}
                </span>
                <button
                  onClick={action.action}
                  className="w-12 h-12 bg-secondary hover:bg-secondary/80 text-secondary-foreground rounded-full shadow-lg hover:shadow-xl transition-all duration-200 flex items-center justify-center"
                >
                  <Icon size={20} />
                </button>
              </div>
            )
          })}
        </div>
      )}

      {/* Bouton principal */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={cn(
          "w-14 h-14 bg-primary hover:bg-primary/90 text-primary-foreground rounded-full shadow-lg hover:shadow-xl transition-all duration-300 flex items-center justify-center",
          isOpen && "rotate-45"
        )}
      >
        {isOpen ? <X size={24} /> : <Plus size={24} />}
      </button>
    </div>
  )
}

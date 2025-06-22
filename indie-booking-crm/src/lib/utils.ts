import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number, currency: string = "EUR"): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: currency
  }).format(amount)
}

export function formatDate(date: string | Date, options?: Intl.DateTimeFormatOptions): string {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  return new Intl.DateTimeFormat('fr-FR', {
    dateStyle: 'medium',
    ...options
  }).format(dateObj)
}

export function formatRelativeTime(date: string | Date): string {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  const now = new Date()
  const diffTime = Math.abs(now.getTime() - dateObj.getTime())
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return "Aujourd'hui"
  if (diffDays === 1) return "Hier"
  if (diffDays < 7) return `Il y a ${diffDays} jours`
  if (diffDays < 30) return `Il y a ${Math.floor(diffDays / 7)} semaines`
  
  return formatDate(dateObj)
}

export function getStatusColor(status: string): string {
  const statusColors: Record<string, string> = {
    // Deal status
    'prospect': 'bg-purple-500/20 text-purple-300 border-purple-500/30',
    'offre': 'bg-blue-500/20 text-blue-300 border-blue-500/30',
    'negotiation': 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30',
    'confirme': 'bg-green-500/20 text-green-300 border-green-500/30',
    'signe': 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
    'termine': 'bg-gray-500/20 text-gray-300 border-gray-500/30',
    
    // Task status
    'todo': 'bg-gray-500/20 text-gray-300 border-gray-500/30',
    'in_progress': 'bg-blue-500/20 text-blue-300 border-blue-500/30',
    'completed': 'bg-green-500/20 text-green-300 border-green-500/30',
    'cancelled': 'bg-red-500/20 text-red-300 border-red-500/30',
    
    // Priority levels
    'low': 'bg-gray-500/20 text-gray-300 border-gray-500/30',
    'medium': 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30',
    'high': 'bg-orange-500/20 text-orange-300 border-orange-500/30',
    'urgent': 'bg-red-500/20 text-red-300 border-red-500/30',
    
    // Invoice status
    'brouillon': 'bg-gray-500/20 text-gray-300 border-gray-500/30',
    'envoye': 'bg-blue-500/20 text-blue-300 border-blue-500/30',
    'paye': 'bg-green-500/20 text-green-300 border-green-500/30',
    'en_retard': 'bg-red-500/20 text-red-300 border-red-500/30'
  }
  
  return statusColors[status] || 'bg-gray-500/20 text-gray-300 border-gray-500/30'
}

export function getStatusLabel(status: string, type: 'deal' | 'task' | 'invoice' = 'deal'): string {
  const labels: Record<string, Record<string, string>> = {
    deal: {
      'prospect': 'Prospect',
      'offre': 'Offre',
      'negotiation': 'Négociation',
      'confirme': 'Confirmé',
      'signe': 'Signé',
      'termine': 'Terminé'
    },
    task: {
      'todo': 'À faire',
      'in_progress': 'En cours',
      'completed': 'Terminé',
      'cancelled': 'Annulé'
    },
    invoice: {
      'brouillon': 'Brouillon',
      'envoye': 'Envoyé',
      'paye': 'Payé',
      'en_retard': 'En retard'
    }
  }
  
  return labels[type]?.[status] || status
}

export function getPriorityLabel(priority: string): string {
  const labels: Record<string, string> = {
    'low': 'Faible',
    'medium': 'Moyenne',
    'high': 'Élevée',
    'urgent': 'Urgente'
  }
  
  return labels[priority] || priority
}

export function getRoleLabel(role: string): string {
  const labels: Record<string, string> = {
    'apporteur_affaires': 'Apporteur d\'affaires',
    'booker_agent': 'Booker/Agent',
    'charge_diffusion': 'Chargé·e de diffusion',
    'tourneur_manager': 'Tourneur/Tour manager',
    'label_management': 'Label/Management',
    'programmateur_promoteur': 'Programmateur/Promoteur',
    'attache_presse': 'Attaché·e de presse/Com\'',
    'regisseur_general': 'Régisseur général'
  }
  
  return labels[role] || role
}

export function getContactTypeLabel(type: string): string {
  const labels: Record<string, string> = {
    'venue': 'Venue',
    'agent': 'Agent',
    'promoteur': 'Promoteur',
    'label': 'Label',
    'media': 'Média',
    'artiste': 'Artiste',
    'fournisseur': 'Fournisseur'
  }
  
  return labels[type] || type
}

export function calculateCommission(fee: number, percentage: number): number {
  return Math.round(fee * (percentage / 100))
}

export function generateId(prefix: string): string {
  const timestamp = Date.now().toString(36)
  const random = Math.random().toString(36).substr(2, 5)
  return `${prefix}_${timestamp}_${random}`
}

// Fonction pour filtrer les données
export function filterData<T>(
  data: T[],
  searchTerm: string,
  searchFields: (keyof T)[]
): T[] {
  if (!searchTerm) return data
  
  const lowercaseSearch = searchTerm.toLowerCase()
  
  return data.filter(item =>
    searchFields.some(field => {
      const value = item[field]
      if (typeof value === 'string') {
        return value.toLowerCase().includes(lowercaseSearch)
      }
      if (Array.isArray(value)) {
        return value.some(v => 
          typeof v === 'string' && v.toLowerCase().includes(lowercaseSearch)
        )
      }
      return false
    })
  )
}

// Fonction pour trier les données
export function sortData<T>(
  data: T[],
  sortField: keyof T,
  sortDirection: 'asc' | 'desc' = 'asc'
): T[] {
  return [...data].sort((a, b) => {
    const aValue = a[sortField]
    const bValue = b[sortField]
    
    if (aValue < bValue) return sortDirection === 'asc' ? -1 : 1
    if (aValue > bValue) return sortDirection === 'asc' ? 1 : -1
    return 0
  })
}

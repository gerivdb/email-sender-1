import { useState, useEffect } from 'react'
import type { Contact, Deal, Task, TourPackage, Invoice, MediaContact } from '../types'

// Hook générique pour charger les données depuis le dossier public
function useDataLoader<T>(endpoint: string) {
  const [data, setData] = useState<T[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true)
        const response = await fetch(`/data/${endpoint}.json`)
        if (!response.ok) {
          throw new Error(`Erreur lors du chargement des données: ${response.statusText}`)
        }
        const result = await response.json()
        setData(result)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Erreur inconnue')
      } finally {
        setLoading(false)
      }
    }

    loadData()
  }, [endpoint])

  return { data, setData, loading, error }
}

// Hooks spécifiques pour chaque type de données
export function useContacts() {
  return useDataLoader<Contact>('contacts')
}

export function useDeals() {
  return useDataLoader<Deal>('deals')
}

export function useTasks() {
  return useDataLoader<Task>('tasks')
}

export function useTours() {
  return useDataLoader<TourPackage>('tours')
}

export function useInvoices() {
  return useDataLoader<Invoice>('invoices')
}

export function useMediaContacts() {
  return useDataLoader<MediaContact>('media-contacts')
}

// Hook pour les statistiques du dashboard
export function useDashboardStats() {
  const { data: deals } = useDeals()
  const { data: tasks } = useTasks()
  const { data: tours } = useTours()

  const stats = {
    prochains_shows: deals.filter(deal => 
      deal.status === 'confirme' || deal.status === 'signe'
    ).length,
    deals_en_negociation: deals.filter(deal => 
      deal.status === 'negotiation'
    ).length,
    ca_ytd: deals
      .filter(deal => deal.status === 'signe' || deal.status === 'termine')
      .reduce((total, deal) => total + deal.fee_artistique, 0),
    taches_dues: tasks.filter(task => {
      if (!task.due_date) return false
      const dueDate = new Date(task.due_date)
      const today = new Date()
      return dueDate <= today && task.status !== 'completed'
    }).length
  }

  return stats
}

// Hook pour les données filtrées
export function useFilteredData<T>(
  data: T[],
  searchTerm: string,
  filters: Record<string, any>
) {
  const [filteredData, setFilteredData] = useState<T[]>(data)

  useEffect(() => {
    let result = [...data]

    // Appliquer la recherche textuelle
    if (searchTerm) {
      const searchLower = searchTerm.toLowerCase()
      result = result.filter((item: any) => {
        return Object.values(item).some(value => 
          typeof value === 'string' && value.toLowerCase().includes(searchLower)
        )
      })
    }

    // Appliquer les filtres
    Object.entries(filters).forEach(([key, value]) => {
      if (value && value.length > 0) {
        result = result.filter((item: any) => {
          const itemValue = item[key]
          if (Array.isArray(value)) {
            return Array.isArray(itemValue) 
              ? itemValue.some(v => value.includes(v))
              : value.includes(itemValue)
          }
          return itemValue === value
        })
      }
    })

    setFilteredData(result)
  }, [data, searchTerm, filters])

  return filteredData
}

// Hook pour la gestion des rôles utilisateur
export function useUserRole() {
  const [currentRole, setCurrentRole] = useState<string>('booker_agent')
  
  // Dans une vraie application, ceci viendrait de l'authentification
  const switchRole = (role: string) => {
    setCurrentRole(role)
  }

  return { currentRole, switchRole }
}

// Hook pour la gestion des actions CRUD
export function useCRUD<T extends { id: string }>(
  data: T[],
  setData: (data: T[]) => void
) {
  const create = (item: Omit<T, 'id' | 'created_at' | 'updated_at'>) => {
    const newItem = {
      ...item,
      id: `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    } as T

    setData([...data, newItem])
    return newItem
  }

  const update = (id: string, updates: Partial<T>) => {
    const updatedData = data.map(item => 
      item.id === id 
        ? { ...item, ...updates, updated_at: new Date().toISOString() }
        : item
    )
    setData(updatedData)
  }

  const remove = (id: string) => {
    setData(data.filter(item => item.id !== id))
  }

  const findById = (id: string) => {
    return data.find(item => item.id === id)
  }

  return { create, update, remove, findById }
}

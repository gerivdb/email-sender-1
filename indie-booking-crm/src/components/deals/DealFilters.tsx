import { useState } from 'react'
import { Button } from '../ui/Button'
import { Badge } from '../ui/Badge'
import { Card, CardContent } from '../ui/Card'
import { getStatusLabel, getPriorityLabel } from '../../lib/utils'
import { Search, Filter, X, ChevronDown, Calendar } from 'lucide-react'
import type { Deal, DealFilters as DealFiltersType, DealStatus, PriorityLevel } from '../../types'

interface DealFiltersProps {
  filters: Partial<DealFiltersType>
  onFiltersChange: (filters: Partial<DealFiltersType>) => void
  deals: Deal[]
}

export function DealFilters({ filters, onFiltersChange, deals }: DealFiltersProps) {
  const [showAdvanced, setShowAdvanced] = useState(false)

  // Extraire les valeurs uniques pour les filtres
  const uniqueArtists = Array.from(new Set(deals.map(d => d.artiste))).sort()
  const uniqueVenues = Array.from(new Set(deals.map(d => d.venue))).sort()

  const handleStatusToggle = (status: DealStatus) => {
    const currentStatuses = filters.status || []
    const newStatuses = currentStatuses.includes(status)
      ? currentStatuses.filter(s => s !== status)
      : [...currentStatuses, status]
    
    onFiltersChange({ ...filters, status: newStatuses })
  }

  const handlePriorityToggle = (priority: PriorityLevel) => {
    const currentPriorities = filters.priority || []
    const newPriorities = currentPriorities.includes(priority)
      ? currentPriorities.filter(p => p !== priority)
      : [...currentPriorities, priority]
    
    onFiltersChange({ ...filters, priority: newPriorities })
  }

  const handleArtistToggle = (artist: string) => {
    const currentArtists = filters.artiste || []
    const newArtists = currentArtists.includes(artist)
      ? currentArtists.filter(a => a !== artist)
      : [...currentArtists, artist]
    
    onFiltersChange({ ...filters, artiste: newArtists })
  }

  const clearFilters = () => {
    onFiltersChange({})
  }

  const activeFiltersCount = Object.values(filters).filter(v => v && v.length > 0).length +
    (filters.date_debut ? 1 : 0) + (filters.date_fin ? 1 : 0)

  const statuses: DealStatus[] = ['prospect', 'offre', 'negotiation', 'confirme', 'signe', 'termine']
  const priorities: PriorityLevel[] = ['low', 'medium', 'high', 'urgent']

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        {/* Barre de recherche principale */}
        <div className="flex items-center gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Rechercher deals (artiste, venue, titre...)"
              value={filters.search || ''}
              onChange={(e) => onFiltersChange({ ...filters, search: e.target.value })}
              className="w-full pl-10 pr-4 py-2 bg-background border border-border rounded-lg text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>
          
          <Button
            variant="outline"
            onClick={() => setShowAdvanced(!showAdvanced)}
            className="flex items-center gap-2"
          >
            <Filter className="w-4 h-4" />
            Filtres
            {activeFiltersCount > 0 && (
              <Badge variant="default" size="sm">{activeFiltersCount}</Badge>
            )}
            <ChevronDown className={`w-4 h-4 transition-transform ${showAdvanced ? 'rotate-180' : ''}`} />
          </Button>

          {activeFiltersCount > 0 && (
            <Button variant="ghost" onClick={clearFilters}>
              <X className="w-4 h-4" />
              Effacer
            </Button>
          )}
        </div>

        {/* Filtres rapides par statut */}
        <div className="flex flex-wrap gap-2">
          {statuses.map(status => {
            const isSelected = filters.status?.includes(status) || false
            const count = deals.filter(d => d.status === status).length
            
            return (
              <button
                key={status}
                onClick={() => handleStatusToggle(status)}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  isSelected 
                    ? 'bg-primary text-primary-foreground' 
                    : 'bg-muted text-muted-foreground hover:bg-muted/80'
                }`}
              >
                {getStatusLabel(status, 'deal')}
                <span className="ml-2 text-xs">({count})</span>
              </button>
            )
          })}
        </div>

        {/* Filtres avancés */}
        {showAdvanced && (
          <div className="space-y-4 pt-4 border-t border-border">
            {/* Filtres par priorité */}
            <div>
              <h4 className="text-sm font-medium text-foreground mb-2">Priorité</h4>
              <div className="flex flex-wrap gap-2">
                {priorities.map(priority => {
                  const isSelected = filters.priority?.includes(priority) || false
                  const count = deals.filter(d => d.priority === priority).length
                  
                  return (
                    <button
                      key={priority}
                      onClick={() => handlePriorityToggle(priority)}
                      className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                        isSelected 
                          ? 'bg-primary text-primary-foreground' 
                          : 'bg-muted text-muted-foreground hover:bg-muted/80'
                      }`}
                    >
                      {getPriorityLabel(priority)}
                      <span className="ml-2 text-xs">({count})</span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Filtres par artiste */}
            <div>
              <h4 className="text-sm font-medium text-foreground mb-2">Artiste</h4>
              <div className="flex flex-wrap gap-2 max-h-32 overflow-y-auto">
                {uniqueArtists.map(artist => {
                  const isSelected = filters.artiste?.includes(artist) || false
                  const count = deals.filter(d => d.artiste === artist).length
                  
                  return (
                    <button
                      key={artist}
                      onClick={() => handleArtistToggle(artist)}
                      className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                        isSelected 
                          ? 'bg-primary text-primary-foreground' 
                          : 'bg-muted text-muted-foreground hover:bg-muted/80'
                      }`}
                    >
                      {artist}
                      <span className="ml-2 text-xs">({count})</span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Filtres par date */}
            <div>
              <h4 className="text-sm font-medium text-foreground mb-2 flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                Période
              </h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs text-muted-foreground mb-1">Date début</label>
                  <input
                    type="date"
                    value={filters.date_debut || ''}
                    onChange={(e) => onFiltersChange({ ...filters, date_debut: e.target.value })}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                <div>
                  <label className="block text-xs text-muted-foreground mb-1">Date fin</label>
                  <input
                    type="date"
                    value={filters.date_fin || ''}
                    onChange={(e) => onFiltersChange({ ...filters, date_fin: e.target.value })}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>
            </div>

            {/* Filtres par montant */}
            <div>
              <h4 className="text-sm font-medium text-foreground mb-2">Montant</h4>
              <div className="flex flex-wrap gap-2">
                {[
                  { label: '< 5k€', min: 0, max: 5000 },
                  { label: '5k€ - 10k€', min: 5000, max: 10000 },
                  { label: '10k€ - 25k€', min: 10000, max: 25000 },
                  { label: '> 25k€', min: 25000, max: Infinity }
                ].map(range => {
                  const count = deals.filter(d => 
                    d.fee_artistique >= range.min && d.fee_artistique < range.max
                  ).length
                  
                  return (
                    <button
                      key={range.label}
                      className="px-3 py-1 rounded-lg text-sm font-medium bg-muted text-muted-foreground hover:bg-muted/80 transition-colors"
                    >
                      {range.label}
                      <span className="ml-2 text-xs">({count})</span>
                    </button>
                  )
                })}
              </div>
            </div>
          </div>
        )}

        {/* Résumé des filtres actifs */}
        {activeFiltersCount > 0 && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <span>{deals.length} deals au total</span>
            <span>•</span>
            <span className="font-medium text-foreground">
              {deals.filter(deal => {
                // Appliquer tous les filtres
                if (filters.search && !Object.values(deal).some(value => 
                  typeof value === 'string' && value.toLowerCase().includes(filters.search!.toLowerCase())
                )) return false
                
                if (filters.status?.length && !filters.status.includes(deal.status)) return false
                if (filters.priority?.length && !filters.priority.includes(deal.priority)) return false
                if (filters.artiste?.length && !filters.artiste.includes(deal.artiste)) return false
                
                if (filters.date_debut && deal.date_show && new Date(deal.date_show) < new Date(filters.date_debut)) return false
                if (filters.date_fin && deal.date_show && new Date(deal.date_show) > new Date(filters.date_fin)) return false
                
                return true
              }).length} correspondent aux critères
            </span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

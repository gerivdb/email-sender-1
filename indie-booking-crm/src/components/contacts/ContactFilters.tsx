import { useState } from 'react'
import { Button } from '../ui/Button'
import { Badge } from '../ui/Badge'
import { Card, CardContent } from '../ui/Card'
import { getContactTypeLabel } from '../../lib/utils'
import { Search, Filter, X, ChevronDown } from 'lucide-react'
import type { Contact, ContactFilters as ContactFiltersType, ContactType } from '../../types'

interface ContactFiltersProps {
  searchTerm: string
  onSearchChange: (term: string) => void
  filters: Partial<ContactFiltersType>
  onFiltersChange: (filters: Partial<ContactFiltersType>) => void
  contacts: Contact[]
}

export function ContactFilters({ 
  searchTerm, 
  onSearchChange, 
  filters, 
  onFiltersChange, 
  contacts 
}: ContactFiltersProps) {
  const [showAdvanced, setShowAdvanced] = useState(false)

  // Extraire les valeurs uniques pour les filtres
  const uniqueRoles = Array.from(new Set(contacts.map(c => c.role))).sort()
  const uniqueCountries = Array.from(new Set(contacts.map(c => c.pays))).sort()
  const uniqueTags = Array.from(new Set(contacts.flatMap(c => c.tags))).sort()

  const handleRoleToggle = (role: ContactType) => {
    const currentRoles = filters.role || []
    const newRoles = currentRoles.includes(role)
      ? currentRoles.filter(r => r !== role)
      : [...currentRoles, role]
    
    onFiltersChange({ ...filters, role: newRoles })
  }

  const handleCountryToggle = (country: string) => {
    const currentCountries = filters.pays || []
    const newCountries = currentCountries.includes(country)
      ? currentCountries.filter(c => c !== country)
      : [...currentCountries, country]
    
    onFiltersChange({ ...filters, pays: newCountries })
  }

  const handleTagToggle = (tag: string) => {
    const currentTags = filters.tags || []
    const newTags = currentTags.includes(tag)
      ? currentTags.filter(t => t !== tag)
      : [...currentTags, tag]
    
    onFiltersChange({ ...filters, tags: newTags })
  }

  const clearFilters = () => {
    onFiltersChange({})
    onSearchChange('')
  }

  const activeFiltersCount = Object.values(filters).filter(v => v && v.length > 0).length

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        {/* Barre de recherche principale */}
        <div className="flex items-center gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Rechercher contacts (nom, entreprise, ville...)"
              value={searchTerm}
              onChange={(e) => onSearchChange(e.target.value)}
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

          {(activeFiltersCount > 0 || searchTerm) && (
            <Button variant="ghost" onClick={clearFilters}>
              <X className="w-4 h-4" />
              Effacer
            </Button>
          )}
        </div>

        {/* Filtres avancés */}
        {showAdvanced && (
          <div className="space-y-4 pt-4 border-t border-border">
            {/* Filtres par rôle */}
            <div>
              <h4 className="text-sm font-medium text-foreground mb-2">Rôle</h4>
              <div className="flex flex-wrap gap-2">
                {uniqueRoles.map(role => {
                  const isSelected = filters.role?.includes(role) || false
                  return (
                    <button
                      key={role}
                      onClick={() => handleRoleToggle(role)}
                      className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                        isSelected 
                          ? 'bg-primary text-primary-foreground' 
                          : 'bg-muted text-muted-foreground hover:bg-muted/80'
                      }`}
                    >
                      {getContactTypeLabel(role)}
                      <span className="ml-2 text-xs">
                        ({contacts.filter(c => c.role === role).length})
                      </span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Filtres par pays */}
            <div>
              <h4 className="text-sm font-medium text-foreground mb-2">Pays</h4>
              <div className="flex flex-wrap gap-2">
                {uniqueCountries.map(country => {
                  const isSelected = filters.pays?.includes(country) || false
                  return (
                    <button
                      key={country}
                      onClick={() => handleCountryToggle(country)}
                      className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                        isSelected 
                          ? 'bg-primary text-primary-foreground' 
                          : 'bg-muted text-muted-foreground hover:bg-muted/80'
                      }`}
                    >
                      {country}
                      <span className="ml-2 text-xs">
                        ({contacts.filter(c => c.pays === country).length})
                      </span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Filtres par tags */}
            {uniqueTags.length > 0 && (
              <div>
                <h4 className="text-sm font-medium text-foreground mb-2">Tags</h4>
                <div className="flex flex-wrap gap-2">
                  {uniqueTags.map(tag => {
                    const isSelected = filters.tags?.includes(tag) || false
                    return (
                      <button
                        key={tag}
                        onClick={() => handleTagToggle(tag)}
                        className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                          isSelected 
                            ? 'bg-primary text-primary-foreground' 
                            : 'bg-muted text-muted-foreground hover:bg-muted/80'
                        }`}
                      >
                        #{tag}
                        <span className="ml-2 text-xs">
                          ({contacts.filter(c => c.tags.includes(tag)).length})
                        </span>
                      </button>
                    )
                  })}
                </div>
              </div>
            )}

            {/* Filtres par activité récente */}
            <div>
              <h4 className="text-sm font-medium text-foreground mb-2">Dernier contact</h4>
              <div className="flex flex-wrap gap-2">
                {[
                  { label: 'Cette semaine', days: 7 },
                  { label: 'Ce mois', days: 30 },
                  { label: 'Ce trimestre', days: 90 },
                  { label: 'Plus de 6 mois', days: 180 }
                ].map(period => {
                  const isSelected = filters.dernier_contact_depuis === period.days
                  return (
                    <button
                      key={period.days}
                      onClick={() => onFiltersChange({ 
                        ...filters, 
                        dernier_contact_depuis: isSelected ? undefined : period.days 
                      })}
                      className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                        isSelected 
                          ? 'bg-primary text-primary-foreground' 
                          : 'bg-muted text-muted-foreground hover:bg-muted/80'
                      }`}
                    >
                      {period.label}
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
            <span>{contacts.length} contacts au total</span>
            <span>•</span>
            <span className="font-medium text-foreground">
              {contacts.filter(contact => {
                if (searchTerm && !Object.values(contact).some(value => 
                  typeof value === 'string' && value.toLowerCase().includes(searchTerm.toLowerCase())
                )) return false
                
                if (filters.role?.length && !filters.role.includes(contact.role)) return false
                if (filters.pays?.length && !filters.pays.includes(contact.pays)) return false
                if (filters.tags?.length && !filters.tags.some(tag => contact.tags.includes(tag))) return false
                
                return true
              }).length} correspondent aux critères
            </span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

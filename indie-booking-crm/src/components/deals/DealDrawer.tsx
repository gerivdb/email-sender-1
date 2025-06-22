import { useState, useEffect } from 'react'
import { Button } from '../ui/Button'
import { Badge } from '../ui/Badge'
import { X, Save, Handshake, User, MapPin, Calendar, DollarSign, Percent } from 'lucide-react'
import { getStatusLabel, getPriorityLabel, formatCurrency, calculateCommission } from '../../lib/utils'
import type { Deal, DealStatus, PriorityLevel, Contact } from '../../types'

interface DealDrawerProps {
  isOpen: boolean
  onClose: () => void
  deal: Deal | null
  onSave: (deal: Partial<Deal>) => void
  contacts: Contact[]
}

export function DealDrawer({ isOpen, onClose, deal, onSave, contacts }: DealDrawerProps) {
  const [formData, setFormData] = useState<Partial<Deal>>({
    titre: '',
    artiste: '',
    venue: '',
    contact_id: '',
    status: 'prospect',
    date_show: '',
    fee_artistique: 0,
    commission_pourcentage: 15,
    commission_montant: 0,
    budget_total: 0,
    priority: 'medium',
    description: '',
    notes: '',
    date_limite: ''
  })

  useEffect(() => {
    if (deal) {
      setFormData(deal)
    } else {
      setFormData({
        titre: '',
        artiste: '',
        venue: '',
        contact_id: '',
        status: 'prospect',
        date_show: '',
        fee_artistique: 0,
        commission_pourcentage: 15,
        commission_montant: 0,
        budget_total: 0,
        priority: 'medium',
        description: '',
        notes: '',
        date_limite: ''
      })
    }
  }, [deal])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    // Calculer la commission automatiquement
    const calculatedCommission = calculateCommission(
      formData.fee_artistique || 0, 
      formData.commission_pourcentage || 15
    )
    
    const finalData = {
      ...formData,
      commission_montant: calculatedCommission,
      budget_total: formData.budget_total || formData.fee_artistique
    }
    
    onSave(finalData)
  }

  const handleInputChange = (field: keyof Deal, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  const handleFeeChange = (fee: number) => {
    const commission = calculateCommission(fee, formData.commission_pourcentage || 15)
    setFormData(prev => ({
      ...prev,
      fee_artistique: fee,
      commission_montant: commission,
      budget_total: prev.budget_total || fee
    }))
  }

  const handleCommissionPercentageChange = (percentage: number) => {
    const commission = calculateCommission(formData.fee_artistique || 0, percentage)
    setFormData(prev => ({
      ...prev,
      commission_pourcentage: percentage,
      commission_montant: commission
    }))
  }

  const handleContactChange = (contactId: string) => {
    const contact = contacts.find(c => c.id === contactId)
    setFormData(prev => ({
      ...prev,
      contact_id: contactId,
      venue: contact?.entreprise || prev.venue
    }))
  }

  const statuses: DealStatus[] = ['prospect', 'offre', 'negotiation', 'confirme', 'signe', 'termine']
  const priorities: PriorityLevel[] = ['low', 'medium', 'high', 'urgent']

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex">
      {/* Overlay */}
      <div 
        className="fixed inset-0 bg-black/50"
        onClick={onClose}
      />

      {/* Drawer */}
      <div className="ml-auto w-full max-w-2xl bg-card border-l border-border shadow-xl h-full overflow-y-auto">
        <form onSubmit={handleSubmit} className="h-full flex flex-col">
          {/* Header */}
          <div className="p-6 border-b border-border">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold text-foreground">
                {deal ? 'Modifier le Deal' : 'Nouveau Deal'}
              </h2>
              <Button variant="ghost" size="sm" onClick={onClose}>
                <X className="w-5 h-5" />
              </Button>
            </div>
          </div>

          {/* Content */}
          <div className="flex-1 p-6 space-y-6">
            {/* Informations de base */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground flex items-center gap-2">
                <Handshake className="w-5 h-5" />
                Informations générales
              </h3>
              
              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Titre du deal *
                </label>
                <input
                  type="text"
                  value={formData.titre || ''}
                  onChange={(e) => handleInputChange('titre', e.target.value)}
                  required
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  placeholder="Ex: The Midnight Wolves @ Le Bataclan"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Artiste *
                  </label>
                  <input
                    type="text"
                    value={formData.artiste || ''}
                    onChange={(e) => handleInputChange('artiste', e.target.value)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Venue *
                  </label>
                  <input
                    type="text"
                    value={formData.venue || ''}
                    onChange={(e) => handleInputChange('venue', e.target.value)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Contact
                </label>
                <select
                  value={formData.contact_id || ''}
                  onChange={(e) => handleContactChange(e.target.value)}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                >
                  <option value="">Sélectionner un contact</option>
                  {contacts.map(contact => (
                    <option key={contact.id} value={contact.id}>
                      {contact.prenom} {contact.nom} - {contact.entreprise}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Statut et priorité */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground">
                Statut et priorité
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Statut
                  </label>
                  <select
                    value={formData.status || 'prospect'}
                    onChange={(e) => handleInputChange('status', e.target.value as DealStatus)}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  >
                    {statuses.map(status => (
                      <option key={status} value={status}>
                        {getStatusLabel(status, 'deal')}
                      </option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Priorité
                  </label>
                  <select
                    value={formData.priority || 'medium'}
                    onChange={(e) => handleInputChange('priority', e.target.value as PriorityLevel)}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  >
                    {priorities.map(priority => (
                      <option key={priority} value={priority}>
                        {getPriorityLabel(priority)}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            {/* Dates */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground flex items-center gap-2">
                <Calendar className="w-5 h-5" />
                Planification
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Date du show
                  </label>
                  <input
                    type="datetime-local"
                    value={formData.date_show || ''}
                    onChange={(e) => handleInputChange('date_show', e.target.value)}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Date limite négociation
                  </label>
                  <input
                    type="date"
                    value={formData.date_limite || ''}
                    onChange={(e) => handleInputChange('date_limite', e.target.value)}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>
            </div>

            {/* Financier */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground flex items-center gap-2">
                <DollarSign className="w-5 h-5" />
                Aspects financiers
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Fee artistique (€)
                  </label>
                  <input
                    type="number"
                    value={formData.fee_artistique || ''}
                    onChange={(e) => handleFeeChange(parseFloat(e.target.value) || 0)}
                    min="0"
                    step="100"
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Commission (%)
                  </label>
                  <input
                    type="number"
                    value={formData.commission_pourcentage || ''}
                    onChange={(e) => handleCommissionPercentageChange(parseFloat(e.target.value) || 0)}
                    min="0"
                    max="100"
                    step="0.5"
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Commission calculée
                  </label>
                  <div className="px-3 py-2 bg-muted border border-border rounded-lg text-foreground">
                    {formatCurrency(formData.commission_montant || 0)}
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Budget total
                  </label>
                  <input
                    type="number"
                    value={formData.budget_total || ''}
                    onChange={(e) => handleInputChange('budget_total', parseFloat(e.target.value) || 0)}
                    min="0"
                    step="100"
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>
            </div>

            {/* Description et notes */}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Description
                </label>
                <textarea
                  value={formData.description || ''}
                  onChange={(e) => handleInputChange('description', e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  placeholder="Description du projet, contexte, conditions particulières..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Notes internes
                </label>
                <textarea
                  value={formData.notes || ''}
                  onChange={(e) => handleInputChange('notes', e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  placeholder="Notes privées, historique des négociations..."
                />
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="p-6 border-t border-border">
            <div className="flex items-center justify-end gap-3">
              <Button type="button" variant="outline" onClick={onClose}>
                Annuler
              </Button>
              <Button type="submit">
                <Save className="w-4 h-4" />
                {deal ? 'Mettre à jour' : 'Créer'}
              </Button>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}

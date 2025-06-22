import { useState } from 'react'
import { Button } from '../ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Badge } from '../ui/Badge'
import { X, FileText, Download, Send, Eye } from 'lucide-react'
import { formatCurrency, formatDate } from '../../lib/utils'
import type { Deal, Contact } from '../../types'

interface ContractPanelProps {
  isOpen: boolean
  onClose: () => void
  deals: Deal[]
  contacts: Contact[]
}

export function ContractPanel({ isOpen, onClose, deals, contacts }: ContractPanelProps) {
  const [selectedDeal, setSelectedDeal] = useState<string>('')
  const [contractData, setContractData] = useState({
    type: 'standard',
    language: 'fr',
    includeRider: true,
    includeMerchandising: false,
    includeRecording: false,
    paymentTerms: '50_50', // 50% à la signature, 50% jour J
    cancellationTerms: 'standard'
  })

  const availableDeals = deals.filter(d => 
    ['confirme', 'signe'].includes(d.status) && 
    !d.documents?.some(doc => doc.includes('contrat'))
  )

  const getContactInfo = (contactId: string) => {
    return contacts.find(c => c.id === contactId)
  }

  const generateContract = () => {
    const deal = deals.find(d => d.id === selectedDeal)
    if (!deal) return

    // Simuler la génération de contrat
    console.log('Génération du contrat pour:', deal.titre)
    
    // Dans une vraie application, ceci ferait appel à un service de génération de PDF
    alert(`Contrat généré pour ${deal.titre}\n\nLe document sera téléchargé dans quelques instants.`)
    
    onClose()
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Overlay */}
      <div 
        className="fixed inset-0 bg-black/50"
        onClick={onClose}
      />

      {/* Panel */}
      <div className="relative w-full max-w-4xl max-h-[90vh] bg-card border border-border shadow-xl rounded-xl overflow-y-auto mx-4">
        {/* Header */}
        <div className="p-6 border-b border-border">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold text-foreground flex items-center gap-2">
              <FileText className="w-5 h-5" />
              Générateur de Contrats
            </h2>
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="w-5 h-5" />
            </Button>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Sélection du deal */}
          <div className="space-y-4">
            <h3 className="text-lg font-medium text-foreground">
              Sélectionner un deal
            </h3>
            
            {availableDeals.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {availableDeals.map(deal => {
                  const contact = getContactInfo(deal.contact_id)
                  const isSelected = selectedDeal === deal.id
                  
                  return (
                    <Card 
                      key={deal.id}
                      className={`cursor-pointer transition-all duration-200 ${
                        isSelected 
                          ? 'ring-2 ring-primary bg-primary/5' 
                          : 'hover:bg-muted/50'
                      }`}
                      onClick={() => setSelectedDeal(deal.id)}
                    >
                      <CardContent className="p-4">
                        <div className="space-y-3">
                          <div className="flex items-start justify-between">
                            <h4 className="font-medium text-foreground line-clamp-2">
                              {deal.titre}
                            </h4>
                            <Badge variant="status" status={deal.status} size="sm">
                              {deal.status}
                            </Badge>
                          </div>
                          
                          <div className="space-y-1 text-sm">
                            <p className="text-foreground">
                              <span className="font-medium">Artiste:</span> {deal.artiste}
                            </p>
                            <p className="text-foreground">
                              <span className="font-medium">Venue:</span> {deal.venue}
                            </p>
                            {deal.date_show && (
                              <p className="text-foreground">
                                <span className="font-medium">Date:</span> {formatDate(deal.date_show)}
                              </p>
                            )}
                            <p className="text-green-400 font-medium">
                              {formatCurrency(deal.fee_artistique)}
                            </p>
                          </div>
                          
                          {contact && (
                            <div className="pt-2 border-t border-border text-xs text-muted-foreground">
                              Contact: {contact.prenom} {contact.nom}
                            </div>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  )
                })}
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                <FileText className="w-12 h-12 mx-auto mb-4 opacity-50" />
                <h3 className="font-medium mb-2">Aucun deal disponible</h3>
                <p className="text-sm">
                  Les contrats ne peuvent être générés que pour les deals confirmés ou signés
                </p>
              </div>
            )}
          </div>

          {/* Configuration du contrat */}
          {selectedDeal && (
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground">
                Configuration du contrat
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Type de contrat */}
                <div className="space-y-3">
                  <h4 className="font-medium text-foreground">Type de contrat</h4>
                  <div className="space-y-2">
                    {[
                      { value: 'standard', label: 'Contrat standard', description: 'Modèle de base pour concerts' },
                      { value: 'festival', label: 'Contrat festival', description: 'Adapté aux événements multi-artistes' },
                      { value: 'tour', label: 'Contrat tournée', description: 'Pour plusieurs dates liées' },
                      { value: 'residency', label: 'Résidence artistique', description: 'Séjour créatif avec performances' }
                    ].map(type => (
                      <label key={type.value} className="flex items-start gap-3 cursor-pointer">
                        <input
                          type="radio"
                          name="contractType"
                          value={type.value}
                          checked={contractData.type === type.value}
                          onChange={(e) => setContractData(prev => ({ ...prev, type: e.target.value }))}
                          className="mt-1"
                        />
                        <div>
                          <p className="font-medium text-foreground">{type.label}</p>
                          <p className="text-sm text-muted-foreground">{type.description}</p>
                        </div>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Options */}
                <div className="space-y-3">
                  <h4 className="font-medium text-foreground">Options</h4>
                  <div className="space-y-3">
                    <label className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={contractData.includeRider}
                        onChange={(e) => setContractData(prev => ({ ...prev, includeRider: e.target.checked }))}
                      />
                      <div>
                        <p className="font-medium text-foreground">Inclure rider technique</p>
                        <p className="text-sm text-muted-foreground">Spécifications techniques et logistiques</p>
                      </div>
                    </label>
                    
                    <label className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={contractData.includeMerchandising}
                        onChange={(e) => setContractData(prev => ({ ...prev, includeMerchandising: e.target.checked }))}
                      />
                      <div>
                        <p className="font-medium text-foreground">Clause merchandising</p>
                        <p className="text-sm text-muted-foreground">Vente de produits dérivés</p>
                      </div>
                    </label>
                    
                    <label className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={contractData.includeRecording}
                        onChange={(e) => setContractData(prev => ({ ...prev, includeRecording: e.target.checked }))}
                      />
                      <div>
                        <p className="font-medium text-foreground">Droits d'enregistrement</p>
                        <p className="text-sm text-muted-foreground">Audio/vidéo du concert</p>
                      </div>
                    </label>
                  </div>
                </div>
              </div>

              {/* Conditions de paiement */}
              <div className="space-y-3">
                <h4 className="font-medium text-foreground">Conditions de paiement</h4>
                <select
                  value={contractData.paymentTerms}
                  onChange={(e) => setContractData(prev => ({ ...prev, paymentTerms: e.target.value }))}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                >
                  <option value="100_signature">100% à la signature</option>
                  <option value="50_50">50% à la signature, 50% jour J</option>
                  <option value="30_70">30% à la signature, 70% jour J</option>
                  <option value="jour_j">100% le jour J</option>
                  <option value="30_apres">100% à 30 jours après le concert</option>
                </select>
              </div>

              {/* Langue */}
              <div className="space-y-3">
                <h4 className="font-medium text-foreground">Langue du contrat</h4>
                <div className="flex gap-4">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="language"
                      value="fr"
                      checked={contractData.language === 'fr'}
                      onChange={(e) => setContractData(prev => ({ ...prev, language: e.target.value }))}
                    />
                    <span className="text-foreground">Français</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="language"
                      value="en"
                      checked={contractData.language === 'en'}
                      onChange={(e) => setContractData(prev => ({ ...prev, language: e.target.value }))}
                    />
                    <span className="text-foreground">Anglais</span>
                  </label>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-6 border-t border-border">
          <div className="flex items-center justify-between">
            <div className="text-sm text-muted-foreground">
              {selectedDeal ? (
                <>Le contrat sera généré en PDF et envoyé automatiquement par email</>
              ) : (
                <>Sélectionnez un deal pour continuer</>
              )}
            </div>
            
            <div className="flex items-center gap-3">
              <Button variant="outline" onClick={onClose}>
                Annuler
              </Button>
              <Button 
                variant="outline" 
                disabled={!selectedDeal}
              >
                <Eye className="w-4 h-4" />
                Aperçu
              </Button>
              <Button 
                onClick={generateContract}
                disabled={!selectedDeal}
              >
                <Download className="w-4 h-4" />
                Générer & Envoyer
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

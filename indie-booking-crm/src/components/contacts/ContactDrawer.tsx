import { useState, useEffect } from 'react'
import { Button } from '../ui/Button'
import { Badge } from '../ui/Badge'
import { X, Save, User, Building, MapPin, Phone, Mail, Globe, Plus } from 'lucide-react'
import { getContactTypeLabel } from '../../lib/utils'
import type { Contact, ContactType } from '../../types'

interface ContactDrawerProps {
  isOpen: boolean
  onClose: () => void
  contact: Contact | null
  onSave: (contact: Partial<Contact>) => void
}

export function ContactDrawer({ isOpen, onClose, contact, onSave }: ContactDrawerProps) {
  const [formData, setFormData] = useState<Partial<Contact>>({
    nom: '',
    prenom: '',
    entreprise: '',
    role: 'venue',
    email: '',
    telephone: '',
    ville: '',
    pays: '',
    adresse: '',
    site_web: '',
    capacite: undefined,
    genre_musical: [],
    tags: [],
    notes: '',
    prochaine_action: ''
  })

  const [newTag, setNewTag] = useState('')
  const [newGenre, setNewGenre] = useState('')

  useEffect(() => {
    if (contact) {
      setFormData(contact)
    } else {
      setFormData({
        nom: '',
        prenom: '',
        entreprise: '',
        role: 'venue',
        email: '',
        telephone: '',
        ville: '',
        pays: '',
        adresse: '',
        site_web: '',
        capacite: undefined,
        genre_musical: [],
        tags: [],
        notes: '',
        prochaine_action: ''
      })
    }
  }, [contact])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave(formData)
  }

  const handleInputChange = (field: keyof Contact, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  const addTag = () => {
    if (newTag.trim() && !formData.tags?.includes(newTag.trim())) {
      handleInputChange('tags', [...(formData.tags || []), newTag.trim()])
      setNewTag('')
    }
  }

  const removeTag = (tag: string) => {
    handleInputChange('tags', formData.tags?.filter(t => t !== tag) || [])
  }

  const addGenre = () => {
    if (newGenre.trim() && !formData.genre_musical?.includes(newGenre.trim())) {
      handleInputChange('genre_musical', [...(formData.genre_musical || []), newGenre.trim()])
      setNewGenre('')
    }
  }

  const removeGenre = (genre: string) => {
    handleInputChange('genre_musical', formData.genre_musical?.filter(g => g !== genre) || [])
  }

  const contactTypes: ContactType[] = ['venue', 'agent', 'promoteur', 'label', 'media', 'artiste', 'fournisseur']

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
                {contact ? 'Modifier le Contact' : 'Nouveau Contact'}
              </h2>
              <Button variant="ghost" size="sm" onClick={onClose}>
                <X className="w-5 h-5" />
              </Button>
            </div>
          </div>

          {/* Content */}
          <div className="flex-1 p-6 space-y-6">
            {/* Informations personnelles */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground flex items-center gap-2">
                <User className="w-5 h-5" />
                Informations personnelles
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Prénom
                  </label>
                  <input
                    type="text"
                    value={formData.prenom || ''}
                    onChange={(e) => handleInputChange('prenom', e.target.value)}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Nom *
                  </label>
                  <input
                    type="text"
                    value={formData.nom || ''}
                    onChange={(e) => handleInputChange('nom', e.target.value)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>
            </div>

            {/* Informations professionnelles */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground flex items-center gap-2">
                <Building className="w-5 h-5" />
                Informations professionnelles
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Entreprise *
                  </label>
                  <input
                    type="text"
                    value={formData.entreprise || ''}
                    onChange={(e) => handleInputChange('entreprise', e.target.value)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Rôle *
                  </label>
                  <select
                    value={formData.role || 'venue'}
                    onChange={(e) => handleInputChange('role', e.target.value as ContactType)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  >
                    {contactTypes.map(type => (
                      <option key={type} value={type}>
                        {getContactTypeLabel(type)}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {formData.role === 'venue' && (
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Capacité
                  </label>
                  <input
                    type="number"
                    value={formData.capacite || ''}
                    onChange={(e) => handleInputChange('capacite', e.target.value ? parseInt(e.target.value) : undefined)}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                    placeholder="Nombre de places"
                  />
                </div>
              )}
            </div>

            {/* Contact */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground flex items-center gap-2">
                <Phone className="w-5 h-5" />
                Contact
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Email *
                  </label>
                  <input
                    type="email"
                    value={formData.email || ''}
                    onChange={(e) => handleInputChange('email', e.target.value)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Téléphone
                  </label>
                  <input
                    type="tel"
                    value={formData.telephone || ''}
                    onChange={(e) => handleInputChange('telephone', e.target.value)}
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Site web
                </label>
                <input
                  type="url"
                  value={formData.site_web || ''}
                  onChange={(e) => handleInputChange('site_web', e.target.value)}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  placeholder="https://"
                />
              </div>
            </div>

            {/* Localisation */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground flex items-center gap-2">
                <MapPin className="w-5 h-5" />
                Localisation
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Ville *
                  </label>
                  <input
                    type="text"
                    value={formData.ville || ''}
                    onChange={(e) => handleInputChange('ville', e.target.value)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">
                    Pays *
                  </label>
                  <input
                    type="text"
                    value={formData.pays || ''}
                    onChange={(e) => handleInputChange('pays', e.target.value)}
                    required
                    className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Adresse complète
                </label>
                <textarea
                  value={formData.adresse || ''}
                  onChange={(e) => handleInputChange('adresse', e.target.value)}
                  rows={2}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>

            {/* Genres musicaux */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground">
                Genres musicaux
              </h3>
              
              <div className="flex flex-wrap gap-2">
                {formData.genre_musical?.map(genre => (
                  <Badge 
                    key={genre} 
                    variant="default" 
                    className="cursor-pointer"
                    onClick={() => removeGenre(genre)}
                  >
                    {genre} <X className="w-3 h-3 ml-1" />
                  </Badge>
                ))}
              </div>

              <div className="flex gap-2">
                <input
                  type="text"
                  value={newGenre}
                  onChange={(e) => setNewGenre(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addGenre())}
                  placeholder="Ajouter un genre"
                  className="flex-1 px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
                <Button type="button" variant="outline" onClick={addGenre}>
                  <Plus className="w-4 h-4" />
                </Button>
              </div>
            </div>

            {/* Tags */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-foreground">
                Tags
              </h3>
              
              <div className="flex flex-wrap gap-2">
                {formData.tags?.map(tag => (
                  <Badge 
                    key={tag} 
                    variant="default" 
                    className="cursor-pointer"
                    onClick={() => removeTag(tag)}
                  >
                    #{tag} <X className="w-3 h-3 ml-1" />
                  </Badge>
                ))}
              </div>

              <div className="flex gap-2">
                <input
                  type="text"
                  value={newTag}
                  onChange={(e) => setNewTag(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addTag())}
                  placeholder="Ajouter un tag"
                  className="flex-1 px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
                <Button type="button" variant="outline" onClick={addTag}>
                  <Plus className="w-4 h-4" />
                </Button>
              </div>
            </div>

            {/* Notes et prochaine action */}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Notes
                </label>
                <textarea
                  value={formData.notes || ''}
                  onChange={(e) => handleInputChange('notes', e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  placeholder="Notes internes sur ce contact..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-foreground mb-2">
                  Prochaine action
                </label>
                <input
                  type="text"
                  value={formData.prochaine_action || ''}
                  onChange={(e) => handleInputChange('prochaine_action', e.target.value)}
                  className="w-full px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  placeholder="Ex: Envoyer dossier artiste, Relancer pour dates automne..."
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
                {contact ? 'Mettre à jour' : 'Créer'}
              </Button>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}

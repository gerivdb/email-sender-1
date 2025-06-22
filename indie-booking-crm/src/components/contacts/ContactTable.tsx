import { useState } from 'react'
import { Card, CardContent } from '../ui/Card'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { formatRelativeTime, getContactTypeLabel } from '../../lib/utils'
import { 
  Edit, 
  Trash2, 
  Mail, 
  Phone, 
  ExternalLink, 
  MapPin,
  Users,
  Building,
  ArrowUpDown,
  MoreHorizontal
} from 'lucide-react'
import type { Contact } from '../../types'

interface ContactTableProps {
  contacts: Contact[]
  onEditContact: (contact: Contact) => void
  onDeleteContact: (contactId: string) => void
}

type SortField = 'nom' | 'entreprise' | 'ville' | 'pays' | 'dernier_contact'
type SortDirection = 'asc' | 'desc'

export function ContactTable({ contacts, onEditContact, onDeleteContact }: ContactTableProps) {
  const [sortField, setSortField] = useState<SortField>('nom')
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')
  const [selectedContacts, setSelectedContacts] = useState<Set<string>>(new Set())

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection('asc')
    }
  }

  const sortedContacts = [...contacts].sort((a, b) => {
    const aValue = a[sortField]
    const bValue = b[sortField]
    
    if (!aValue && !bValue) return 0
    if (!aValue) return 1
    if (!bValue) return -1
    
    const comparison = aValue.toString().localeCompare(bValue.toString())
    return sortDirection === 'asc' ? comparison : -comparison
  })

  const toggleContactSelection = (contactId: string) => {
    const newSelection = new Set(selectedContacts)
    if (newSelection.has(contactId)) {
      newSelection.delete(contactId)
    } else {
      newSelection.add(contactId)
    }
    setSelectedContacts(newSelection)
  }

  const toggleSelectAll = () => {
    if (selectedContacts.size === contacts.length) {
      setSelectedContacts(new Set())
    } else {
      setSelectedContacts(new Set(contacts.map(c => c.id)))
    }
  }

  const SortableHeader = ({ field, children }: { field: SortField, children: React.ReactNode }) => (
    <button
      onClick={() => handleSort(field)}
      className="flex items-center gap-1 font-medium text-left hover:text-foreground transition-colors group"
    >
      {children}
      <ArrowUpDown 
        className={`w-4 h-4 opacity-0 group-hover:opacity-100 transition-opacity ${
          sortField === field ? 'opacity-100 text-primary' : ''
        }`} 
      />
    </button>
  )

  return (
    <Card>
      <CardContent className="p-0">
        {/* Actions en lot */}
        {selectedContacts.size > 0 && (
          <div className="p-4 border-b border-border bg-muted/30">
            <div className="flex items-center justify-between">
              <span className="text-sm text-foreground">
                {selectedContacts.size} contact{selectedContacts.size > 1 ? 's' : ''} sélectionné{selectedContacts.size > 1 ? 's' : ''}
              </span>
              <div className="flex items-center gap-2">
                <Button variant="outline" size="sm">
                  <Mail className="w-4 h-4" />
                  Envoyer email
                </Button>
                <Button variant="outline" size="sm">
                  Exporter
                </Button>
                <Button variant="destructive" size="sm">
                  <Trash2 className="w-4 h-4" />
                  Supprimer
                </Button>
              </div>
            </div>
          </div>
        )}

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="border-b border-border bg-muted/30">
              <tr>
                <th className="p-4 text-left">
                  <input
                    type="checkbox"
                    checked={selectedContacts.size === contacts.length && contacts.length > 0}
                    onChange={toggleSelectAll}
                    className="rounded border-border"
                  />
                </th>
                <th className="p-4 text-left text-sm text-muted-foreground">
                  <SortableHeader field="nom">Contact</SortableHeader>
                </th>
                <th className="p-4 text-left text-sm text-muted-foreground">
                  <SortableHeader field="entreprise">Entreprise</SortableHeader>
                </th>
                <th className="p-4 text-left text-sm text-muted-foreground">Rôle</th>
                <th className="p-4 text-left text-sm text-muted-foreground">
                  <SortableHeader field="ville">Localisation</SortableHeader>
                </th>
                <th className="p-4 text-left text-sm text-muted-foreground">Contact</th>
                <th className="p-4 text-left text-sm text-muted-foreground">
                  <SortableHeader field="dernier_contact">Dernière Interaction</SortableHeader>
                </th>
                <th className="p-4 text-left text-sm text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody>
              {sortedContacts.map((contact) => (
                <tr 
                  key={contact.id} 
                  className="border-b border-border hover:bg-muted/30 transition-colors"
                >
                  <td className="p-4">
                    <input
                      type="checkbox"
                      checked={selectedContacts.has(contact.id)}
                      onChange={() => toggleContactSelection(contact.id)}
                      className="rounded border-border"
                    />
                  </td>
                  
                  <td className="p-4">
                    <div className="space-y-1">
                      <p className="font-medium text-foreground">
                        {contact.prenom} {contact.nom}
                      </p>
                      {contact.tags.length > 0 && (
                        <div className="flex flex-wrap gap-1">
                          {contact.tags.slice(0, 2).map(tag => (
                            <Badge key={tag} variant="default" size="sm">
                              {tag}
                            </Badge>
                          ))}
                          {contact.tags.length > 2 && (
                            <Badge variant="default" size="sm">
                              +{contact.tags.length - 2}
                            </Badge>
                          )}
                        </div>
                      )}
                    </div>
                  </td>
                  
                  <td className="p-4">
                    <div className="space-y-1">
                      <p className="font-medium text-foreground">{contact.entreprise}</p>
                      {contact.capacite && (
                        <p className="text-xs text-muted-foreground flex items-center gap-1">
                          <Users className="w-3 h-3" />
                          {contact.capacite} places
                        </p>
                      )}
                    </div>
                  </td>
                  
                  <td className="p-4">
                    <Badge variant="default" size="sm">
                      {getContactTypeLabel(contact.role)}
                    </Badge>
                  </td>
                  
                  <td className="p-4">
                    <div className="space-y-1">
                      <p className="text-sm text-foreground">{contact.ville}</p>
                      <p className="text-xs text-muted-foreground flex items-center gap-1">
                        <MapPin className="w-3 h-3" />
                        {contact.pays}
                      </p>
                    </div>
                  </td>
                  
                  <td className="p-4">
                    <div className="space-y-1">
                      <a 
                        href={`mailto:${contact.email}`}
                        className="text-sm text-primary hover:underline flex items-center gap-1"
                      >
                        <Mail className="w-3 h-3" />
                        {contact.email}
                      </a>
                      {contact.telephone && (
                        <a 
                          href={`tel:${contact.telephone}`}
                          className="text-xs text-muted-foreground hover:text-foreground flex items-center gap-1"
                        >
                          <Phone className="w-3 h-3" />
                          {contact.telephone}
                        </a>
                      )}
                    </div>
                  </td>
                  
                  <td className="p-4">
                    <div className="space-y-1">
                      {contact.dernier_contact ? (
                        <>
                          <p className="text-sm text-foreground">
                            {formatRelativeTime(contact.dernier_contact)}
                          </p>
                          {contact.prochaine_action && (
                            <p className="text-xs text-muted-foreground">
                              Prochaine: {contact.prochaine_action}
                            </p>
                          )}
                        </>
                      ) : (
                        <p className="text-sm text-muted-foreground">Jamais contacté</p>
                      )}
                    </div>
                  </td>
                  
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => onEditContact(contact)}
                      >
                        <Edit className="w-4 h-4" />
                      </Button>
                      
                      {contact.site_web && (
                        <Button
                          variant="ghost"
                          size="sm"
                          asChild
                        >
                          <a href={contact.site_web} target="_blank" rel="noopener noreferrer">
                            <ExternalLink className="w-4 h-4" />
                          </a>
                        </Button>
                      )}
                      
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => onDeleteContact(contact.id)}
                        className="text-red-400 hover:text-red-300"
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Empty state */}
        {contacts.length === 0 && (
          <div className="text-center py-12">
            <Building className="w-12 h-12 mx-auto mb-4 text-muted-foreground opacity-50" />
            <h3 className="text-lg font-medium text-foreground mb-2">Aucun contact trouvé</h3>
            <p className="text-muted-foreground mb-4">
              Commencez par ajouter vos premiers contacts professionnels
            </p>
            <Button>
              <Building className="w-4 h-4" />
              Ajouter un contact
            </Button>
          </div>
        )}

        {/* Pagination */}
        {contacts.length > 0 && (
          <div className="p-4 border-t border-border flex items-center justify-between">
            <p className="text-sm text-muted-foreground">
              Affichage de {contacts.length} contact{contacts.length > 1 ? 's' : ''}
            </p>
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" disabled>
                Précédent
              </Button>
              <Button variant="outline" size="sm" disabled>
                Suivant
              </Button>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

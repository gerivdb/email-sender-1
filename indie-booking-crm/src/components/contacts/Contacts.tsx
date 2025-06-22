import { useState } from 'react'
import { ContactTable } from './ContactTable'
import { ContactFilters } from './ContactFilters'
import { ContactDrawer } from './ContactDrawer'
import { useContacts, useFilteredData } from '../../hooks/useData'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Button } from '../ui/Button'
import { Users, Download, Upload, Plus } from 'lucide-react'
import type { Contact, ContactFilters as ContactFiltersType } from '../../types'

export function Contacts() {
  const { data: contacts, setData: setContacts } = useContacts()
  const [searchTerm, setSearchTerm] = useState('')
  const [filters, setFilters] = useState<Partial<ContactFiltersType>>({})
  const [selectedContact, setSelectedContact] = useState<Contact | null>(null)
  const [isDrawerOpen, setIsDrawerOpen] = useState(false)

  // Données filtrées
  const filteredContacts = useFilteredData(contacts, searchTerm, filters)

  const handleCreateContact = () => {
    setSelectedContact(null)
    setIsDrawerOpen(true)
  }

  const handleEditContact = (contact: Contact) => {
    setSelectedContact(contact)
    setIsDrawerOpen(true)
  }

  const handleSaveContact = (contactData: Partial<Contact>) => {
    if (selectedContact) {
      // Modifier contact existant
      const updatedContacts = contacts.map(c => 
        c.id === selectedContact.id 
          ? { ...c, ...contactData, updated_at: new Date().toISOString() }
          : c
      )
      setContacts(updatedContacts)
    } else {
      // Créer nouveau contact
      const newContact: Contact = {
        id: `contact_${Date.now()}`,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        tags: [],
        ...contactData
      } as Contact
      
      setContacts([...contacts, newContact])
    }
    setIsDrawerOpen(false)
  }

  const handleDeleteContact = (contactId: string) => {
    setContacts(contacts.filter(c => c.id !== contactId))
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Contacts</h1>
          <p className="text-muted-foreground">
            Gérez votre réseau professionnel de l'industrie musicale
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm">
            <Download className="w-4 h-4" />
            Exporter
          </Button>
          <Button variant="outline" size="sm">
            <Upload className="w-4 h-4" />
            Importer
          </Button>
          <Button onClick={handleCreateContact}>
            <Plus className="w-4 h-4" />
            Nouveau Contact
          </Button>
        </div>
      </div>

      {/* Statistiques rapides */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Contacts</p>
                <p className="text-2xl font-bold text-foreground">{contacts.length}</p>
              </div>
              <Users className="w-8 h-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Venues</p>
                <p className="text-2xl font-bold text-foreground">
                  {contacts.filter(c => c.role === 'venue').length}
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-purple-500/20 flex items-center justify-center">
                <span className="text-purple-500 font-bold">V</span>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Agents</p>
                <p className="text-2xl font-bold text-foreground">
                  {contacts.filter(c => c.role === 'agent').length}
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-green-500/20 flex items-center justify-center">
                <span className="text-green-500 font-bold">A</span>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Promoteurs</p>
                <p className="text-2xl font-bold text-foreground">
                  {contacts.filter(c => c.role === 'promoteur').length}
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-orange-500/20 flex items-center justify-center">
                <span className="text-orange-500 font-bold">P</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filtres */}
      <ContactFilters
        searchTerm={searchTerm}
        onSearchChange={setSearchTerm}
        filters={filters}
        onFiltersChange={setFilters}
        contacts={contacts}
      />

      {/* Table */}
      <ContactTable
        contacts={filteredContacts}
        onEditContact={handleEditContact}
        onDeleteContact={handleDeleteContact}
      />

      {/* Drawer d'édition */}
      <ContactDrawer
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        contact={selectedContact}
        onSave={handleSaveContact}
      />
    </div>
  )
}

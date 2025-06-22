import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Button } from '../ui/Button'
import { Badge } from '../ui/Badge'
import { Megaphone, Plus, Send, Edit } from 'lucide-react'
import { useMediaContacts } from '../../hooks/useData'

export function MediaPR() {
  const { data: mediaContacts } = useMediaContacts()

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Media & PR</h1>
          <p className="text-muted-foreground">
            Gérez vos relations presse et campagnes marketing
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm">
            <Edit className="w-4 h-4" />
            Nouveau Communiqué
          </Button>
          <Button>
            <Plus className="w-4 h-4" />
            Nouvelle Campagne
          </Button>
        </div>
      </div>

      {/* Contacts Media */}
      <Card>
        <CardHeader>
          <CardTitle>Contacts Média</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {mediaContacts.map(contact => (
              <div key={contact.id} className="p-4 rounded-lg border border-border">
                <div className="space-y-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-medium text-foreground">{contact.nom}</h3>
                      <p className="text-sm text-muted-foreground">{contact.media}</p>
                    </div>
                    <Badge variant="default" size="sm">
                      {contact.type}
                    </Badge>
                  </div>
                  
                  <div className="space-y-1">
                    <p className="text-sm text-foreground">{contact.email}</p>
                    {contact.specialite && (
                      <div className="flex flex-wrap gap-1">
                        {contact.specialite.map(spec => (
                          <Badge key={spec} variant="default" size="sm">
                            {spec}
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <Badge variant="status" status={contact.status_outreach} size="sm">
                      {contact.status_outreach}
                    </Badge>
                    <Button variant="ghost" size="sm">
                      <Send className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Campagnes */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Communiqués de Presse</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8 text-muted-foreground">
              <Megaphone className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <h3 className="font-medium mb-2">Éditeur de Communiqués</h3>
              <p className="text-sm">
                L'éditeur rich-text pour créer des communiqués sera intégré ici
              </p>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader>
            <CardTitle>Posts Réseaux Sociaux</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8 text-muted-foreground">
              <div className="w-12 h-12 rounded-full bg-primary/20 mx-auto mb-4 flex items-center justify-center">
                <span className="text-primary font-bold">📱</span>
              </div>
              <h3 className="font-medium mb-2">Planificateur Social</h3>
              <p className="text-sm">
                Le planificateur de posts pour tous les réseaux sociaux
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

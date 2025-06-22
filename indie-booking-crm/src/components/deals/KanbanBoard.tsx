import { Droppable, Draggable } from '@hello-pangea/dnd'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { formatCurrency, getStatusLabel, getPriorityLabel } from '../../lib/utils'
import { 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  Calendar, 
  MapPin, 
  DollarSign,
  User,
  Clock
} from 'lucide-react'
import type { Deal, DealStatus, Contact } from '../../types'

interface KanbanBoardProps {
  dealsByStatus: Record<DealStatus, Deal[]>
  onEditDeal: (deal: Deal) => void
  onDeleteDeal: (dealId: string) => void
  contacts: Contact[]
}

const statusConfig = {
  prospect: { 
    title: 'Prospect', 
    color: 'bg-purple-500/20 text-purple-300 border-purple-500/30',
    bgColor: 'bg-purple-500/10'
  },
  offre: { 
    title: 'Offre', 
    color: 'bg-blue-500/20 text-blue-300 border-blue-500/30',
    bgColor: 'bg-blue-500/10'
  },
  negotiation: { 
    title: 'Négociation', 
    color: 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30',
    bgColor: 'bg-yellow-500/10'
  },
  confirme: { 
    title: 'Confirmé', 
    color: 'bg-green-500/20 text-green-300 border-green-500/30',
    bgColor: 'bg-green-500/10'
  },
  signe: { 
    title: 'Signé', 
    color: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
    bgColor: 'bg-emerald-500/10'
  },
  termine: { 
    title: 'Terminé', 
    color: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
    bgColor: 'bg-gray-500/10'
  }
}

export function KanbanBoard({ dealsByStatus, onEditDeal, onDeleteDeal, contacts }: KanbanBoardProps) {
  const statuses: DealStatus[] = ['prospect', 'offre', 'negotiation', 'confirme', 'signe', 'termine']

  const getContactInfo = (contactId: string) => {
    return contacts.find(c => c.id === contactId)
  }

  const DealCard = ({ deal, index }: { deal: Deal, index: number }) => {
    const contact = getContactInfo(deal.contact_id)
    const isOverdue = deal.date_limite && new Date(deal.date_limite) < new Date()

    return (
      <Draggable draggableId={deal.id} index={index}>
        {(provided, snapshot) => (
          <div
            ref={provided.innerRef}
            {...provided.draggableProps}
            {...provided.dragHandleProps}
            className={`mb-3 ${snapshot.isDragging ? 'opacity-50' : ''}`}
          >
            <Card className={`cursor-move hover:shadow-md transition-all duration-200 ${
              snapshot.isDragging ? 'rotate-3 scale-105' : ''
            } ${isOverdue ? 'border-red-500/50' : ''}`}>
              <CardContent className="p-4">
                <div className="space-y-3">
                  {/* Header avec priorité */}
                  <div className="flex items-start justify-between">
                    <h4 className="font-medium text-foreground text-sm line-clamp-2 flex-1">
                      {deal.titre}
                    </h4>
                    <div className="flex items-center gap-1 ml-2">
                      <Badge variant="priority" status={deal.priority} size="sm">
                        {getPriorityLabel(deal.priority)}
                      </Badge>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="w-6 h-6 p-0"
                        onClick={(e) => {
                          e.stopPropagation()
                          // Menu contextuel
                        }}
                      >
                        <MoreHorizontal className="w-3 h-3" />
                      </Button>
                    </div>
                  </div>

                  {/* Artiste */}
                  <div className="flex items-center gap-2 text-sm">
                    <User className="w-3 h-3 text-muted-foreground" />
                    <span className="text-foreground font-medium">{deal.artiste}</span>
                  </div>

                  {/* Venue */}
                  <div className="flex items-center gap-2 text-sm">
                    <MapPin className="w-3 h-3 text-muted-foreground" />
                    <span className="text-muted-foreground">{deal.venue}</span>
                  </div>

                  {/* Date du show */}
                  {deal.date_show && (
                    <div className="flex items-center gap-2 text-sm">
                      <Calendar className="w-3 h-3 text-muted-foreground" />
                      <span className={`text-sm ${
                        isOverdue ? 'text-red-400' : 'text-muted-foreground'
                      }`}>
                        {new Date(deal.date_show).toLocaleDateString('fr-FR')}
                      </span>
                    </div>
                  )}

                  {/* Date limite */}
                  {deal.date_limite && (
                    <div className="flex items-center gap-2 text-sm">
                      <Clock className="w-3 h-3 text-muted-foreground" />
                      <span className={`text-xs ${
                        isOverdue ? 'text-red-400 font-medium' : 'text-muted-foreground'
                      }`}>
                        Deadline: {new Date(deal.date_limite).toLocaleDateString('fr-FR')}
                      </span>
                    </div>
                  )}

                  {/* Montants */}
                  <div className="space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-muted-foreground">Fee artistique</span>
                      <span className="text-sm font-medium text-green-400">
                        {formatCurrency(deal.fee_artistique)}
                      </span>
                    </div>
                    {deal.commission_montant > 0 && (
                      <div className="flex items-center justify-between">
                        <span className="text-xs text-muted-foreground">
                          Commission ({deal.commission_pourcentage}%)
                        </span>
                        <span className="text-sm font-medium text-primary">
                          {formatCurrency(deal.commission_montant)}
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Contact */}
                  {contact && (
                    <div className="pt-2 border-t border-border">
                      <p className="text-xs text-muted-foreground">
                        Contact: {contact.prenom} {contact.nom}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {contact.entreprise}
                      </p>
                    </div>
                  )}

                  {/* Actions */}
                  <div className="flex items-center justify-between pt-2">
                    <div className="flex items-center gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-6 px-2 text-xs"
                        onClick={(e) => {
                          e.stopPropagation()
                          onEditDeal(deal)
                        }}
                      >
                        <Edit className="w-3 h-3" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-6 px-2 text-xs text-red-400 hover:text-red-300"
                        onClick={(e) => {
                          e.stopPropagation()
                          onDeleteDeal(deal.id)
                        }}
                      >
                        <Trash2 className="w-3 h-3" />
                      </Button>
                    </div>
                    
                    <div className="text-xs text-muted-foreground">
                      Mis à jour {new Date(deal.updated_at).toLocaleDateString('fr-FR')}
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        )}
      </Draggable>
    )
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-6 gap-6 overflow-x-auto">
      {statuses.map((status) => {
        const deals = dealsByStatus[status] || []
        const totalValue = deals.reduce((sum, deal) => sum + deal.fee_artistique, 0)
        const config = statusConfig[status]

        return (
          <div key={status} className="min-w-80">
            <Card className="h-full">
              <CardHeader className="pb-4">
                <CardTitle className="flex items-center justify-between">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <div className={`w-3 h-3 rounded-full ${config.color}`} />
                      <h3 className="text-sm font-medium text-foreground">
                        {config.title}
                      </h3>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {deals.length} deal{deals.length > 1 ? 's' : ''}
                    </p>
                  </div>
                  
                  {totalValue > 0 && (
                    <div className="text-right">
                      <p className="text-sm font-medium text-green-400">
                        {formatCurrency(totalValue)}
                      </p>
                    </div>
                  )}
                </CardTitle>
              </CardHeader>

              <CardContent className="pt-0">
                <Droppable droppableId={status}>
                  {(provided, snapshot) => (
                    <div
                      ref={provided.innerRef}
                      {...provided.droppableProps}
                      className={`min-h-96 transition-colors duration-200 rounded-lg p-2 -m-2 ${
                        snapshot.isDraggingOver ? config.bgColor : ''
                      }`}
                    >
                      {deals.map((deal, index) => (
                        <DealCard key={deal.id} deal={deal} index={index} />
                      ))}
                      {provided.placeholder}
                      
                      {deals.length === 0 && (
                        <div className="text-center py-12 text-muted-foreground">
                          <div className={`w-12 h-12 rounded-full ${config.bgColor} mx-auto mb-4 flex items-center justify-center`}>
                            <DollarSign className="w-6 h-6" />
                          </div>
                          <p className="text-sm">Aucun deal</p>
                          <p className="text-xs">Glissez-déposez ici</p>
                        </div>
                      )}
                    </div>
                  )}
                </Droppable>
              </CardContent>
            </Card>
          </div>
        )
      })}
    </div>
  )
}

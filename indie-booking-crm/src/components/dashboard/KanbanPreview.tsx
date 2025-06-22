import { Link } from 'react-router-dom'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { formatCurrency, getStatusLabel } from '../../lib/utils'
import { Handshake, ExternalLink, DollarSign } from 'lucide-react'
import type { Deal } from '../../types'

interface KanbanPreviewProps {
  deals: Deal[]
}

export function KanbanPreview({ deals }: KanbanPreviewProps) {
  // Grouper les deals par statut
  const dealsByStatus = deals.reduce((acc, deal) => {
    if (!acc[deal.status]) {
      acc[deal.status] = []
    }
    acc[deal.status].push(deal)
    return acc
  }, {} as Record<string, Deal[]>)

  const statuses = ['prospect', 'offre', 'negotiation', 'confirme', 'signe', 'termine']

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Handshake className="w-5 h-5 text-primary" />
            Pipeline des Deals
          </div>
          <Button variant="outline" size="sm" asChild>
            <Link to="/deals">
              <ExternalLink className="w-4 h-4" />
              Vue complète
            </Link>
          </Button>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
          {statuses.map(status => {
            const statusDeals = dealsByStatus[status] || []
            const totalValue = statusDeals.reduce((sum, deal) => sum + deal.fee_artistique, 0)
            
            return (
              <div key={status} className="space-y-3">
                {/* Header de colonne */}
                <div className="flex items-center justify-between">
                  <div className="space-y-1">
                    <h3 className="font-medium text-foreground text-sm">
                      {getStatusLabel(status, 'deal')}
                    </h3>
                    <p className="text-xs text-muted-foreground">
                      {statusDeals.length} deal{statusDeals.length > 1 ? 's' : ''}
                    </p>
                  </div>
                  {totalValue > 0 && (
                    <p className="text-xs font-medium text-green-400">
                      {formatCurrency(totalValue)}
                    </p>
                  )}
                </div>

                {/* Deals */}
                <div className="space-y-2 max-h-48 overflow-y-auto">
                  {statusDeals.slice(0, 3).map(deal => (
                    <div 
                      key={deal.id}
                      className="p-3 rounded-lg border border-border bg-card hover:bg-muted/50 transition-colors cursor-pointer"
                    >
                      <div className="space-y-2">
                        <div className="flex items-start justify-between">
                          <h4 className="font-medium text-foreground text-sm line-clamp-2">
                            {deal.artiste}
                          </h4>
                          <Badge variant="priority" status={deal.priority} size="sm">
                            {deal.priority}
                          </Badge>
                        </div>
                        
                        <p className="text-xs text-muted-foreground line-clamp-1">
                          {deal.venue}
                        </p>
                        
                        {deal.date_show && (
                          <p className="text-xs text-muted-foreground">
                            {new Date(deal.date_show).toLocaleDateString('fr-FR')}
                          </p>
                        )}
                        
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-medium text-green-400">
                            {formatCurrency(deal.fee_artistique)}
                          </span>
                          {deal.commission_montant > 0 && (
                            <span className="text-xs text-primary">
                              +{formatCurrency(deal.commission_montant)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                  
                  {statusDeals.length > 3 && (
                    <div className="text-center">
                      <Button variant="ghost" size="sm" className="text-xs">
                        +{statusDeals.length - 3} autres
                      </Button>
                    </div>
                  )}
                  
                  {statusDeals.length === 0 && (
                    <div className="p-6 text-center text-muted-foreground">
                      <div className="w-8 h-8 rounded-full bg-muted mx-auto mb-2 flex items-center justify-center">
                        <Handshake className="w-4 h-4" />
                      </div>
                      <p className="text-xs">Aucun deal</p>
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>

        {/* Statistiques rapides */}
        <div className="mt-6 pt-4 border-t border-border">
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-2xl font-bold text-foreground">
                {deals.length}
              </p>
              <p className="text-sm text-muted-foreground">Total deals</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-green-400">
                {formatCurrency(deals.reduce((sum, deal) => sum + deal.fee_artistique, 0))}
              </p>
              <p className="text-sm text-muted-foreground">Valeur pipeline</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-primary">
                {Math.round((deals.filter(d => d.status === 'signe').length / Math.max(deals.length, 1)) * 100)}%
              </p>
              <p className="text-sm text-muted-foreground">Taux conversion</p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { useTours } from '../../hooks/useData'
import { formatCurrency, formatDate } from '../../lib/utils'
import { MapPin, Calendar, DollarSign, Navigation, ExternalLink } from 'lucide-react'

export function TourMapWidget() {
  const { data: tours } = useTours()
  
  // Prendre la première tournée active
  const activeTour = tours.find(tour => tour.status === 'en_cours' || tour.status === 'confirme') || tours[0]

  return (
    <Card className="h-full">
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <MapPin className="w-5 h-5 text-primary" />
            Carte de Tournée
          </div>
          <Button variant="outline" size="sm">
            <ExternalLink className="w-4 h-4" />
            Vue complète
          </Button>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {activeTour ? (
          <>
            {/* Info tournée */}
            <div className="p-4 rounded-lg bg-muted/30 border border-border">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold text-foreground">{activeTour.nom}</h3>
                <Badge variant="status" status={activeTour.status}>
                  {activeTour.status}
                </Badge>
              </div>
              
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Artiste</p>
                  <p className="font-medium text-foreground">{activeTour.artiste}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Dates</p>
                  <p className="font-medium text-foreground">
                    {formatDate(activeTour.date_debut)} - {formatDate(activeTour.date_fin)}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Total Fees</p>
                  <p className="font-medium text-green-400">{formatCurrency(activeTour.total_fees)}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Profit Prévu</p>
                  <p className="font-medium text-green-400">{formatCurrency(activeTour.profit_prevu)}</p>
                </div>
              </div>
            </div>

            {/* Carte visuelle (simulée avec image) */}
            <div className="relative h-64 rounded-lg overflow-hidden bg-muted">
              <img 
                src="/images/tour-map.png" 
                alt="Carte de tournée"
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
              
              {/* Overlay avec info */}
              <div className="absolute bottom-4 left-4 right-4">
                <div className="flex items-center justify-between text-white">
                  <div className="flex items-center gap-2">
                    <Navigation className="w-4 h-4" />
                    <span className="text-sm font-medium">
                      {activeTour.events.length} dates confirmées
                    </span>
                  </div>
                  <div className="text-sm">
                    {activeTour.events.filter(e => e.statut === 'confirme').length}/
                    {activeTour.events.length} villes
                  </div>
                </div>
              </div>
            </div>

            {/* Liste des événements */}
            <div className="space-y-2 max-h-48 overflow-y-auto">
              <h4 className="font-medium text-foreground mb-2">Dates de la tournée</h4>
              {activeTour.events.map((event, index) => (
                <div key={event.id} className="flex items-center justify-between p-3 rounded-lg border border-border bg-card">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-sm font-medium">
                      {index + 1}
                    </div>
                    <div>
                      <p className="font-medium text-foreground">{event.ville}, {event.pays}</p>
                      <p className="text-sm text-muted-foreground">{event.venue}</p>
                    </div>
                  </div>
                  
                  <div className="text-right">
                    <p className="text-sm font-medium text-foreground">
                      {formatDate(event.date)}
                    </p>
                    <div className="flex items-center gap-2">
                      <Badge variant="status" status={event.statut} size="sm">
                        {event.statut}
                      </Badge>
                      <span className="text-sm text-green-400">
                        {formatCurrency(event.fee)}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Résumé financier */}
            <div className="grid grid-cols-3 gap-4 p-4 rounded-lg bg-primary/10 border border-primary/20">
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Transport</p>
                <p className="font-medium text-foreground">{formatCurrency(activeTour.budget_transport)}</p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Hébergement</p>
                <p className="font-medium text-foreground">{formatCurrency(activeTour.budget_hebergement)}</p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Per Diem</p>
                <p className="font-medium text-foreground">{formatCurrency(activeTour.budget_per_diem)}</p>
              </div>
            </div>
          </>
        ) : (
          <div className="flex flex-col items-center justify-center h-64 text-muted-foreground">
            <MapPin className="w-12 h-12 mb-4 opacity-50" />
            <h3 className="font-medium mb-2">Aucune tournée active</h3>
            <p className="text-sm text-center">
              Créez votre première tournée pour voir l'itinéraire ici
            </p>
            <Button className="mt-4">
              Nouvelle Tournée
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

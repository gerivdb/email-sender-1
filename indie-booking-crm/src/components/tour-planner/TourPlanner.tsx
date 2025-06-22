import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Button } from '../ui/Button'
import { MapPin, Plus, Calendar, Route, DollarSign } from 'lucide-react'
import { useTours } from '../../hooks/useData'
import { formatCurrency, formatDate } from '../../lib/utils'

export function TourPlanner() {
  const { data: tours } = useTours()

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Tour Planner</h1>
          <p className="text-muted-foreground">
            Planifiez et optimisez vos tournées européennes
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm">
            <Route className="w-4 h-4" />
            Optimiser Route
          </Button>
          <Button>
            <Plus className="w-4 h-4" />
            Nouvelle Tournée
          </Button>
        </div>
      </div>

      {/* Tours actives */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {tours.map(tour => (
          <Card key={tour.id}>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <MapPin className="w-5 h-5 text-primary" />
                  {tour.nom}
                </div>
                <span className="text-sm text-muted-foreground">
                  {tour.events.length} dates
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Artiste</p>
                  <p className="font-medium text-foreground">{tour.artiste}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Période</p>
                  <p className="font-medium text-foreground">
                    {formatDate(tour.date_debut)} - {formatDate(tour.date_fin)}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Revenue Total</p>
                  <p className="font-medium text-green-400">{formatCurrency(tour.total_fees)}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Profit Prévu</p>
                  <p className="font-medium text-green-400">{formatCurrency(tour.profit_prevu)}</p>
                </div>
              </div>
              
              <div className="pt-4 border-t border-border">
                <Button variant="outline" className="w-full">
                  Voir Détails
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Carte placeholder */}
      <Card>
        <CardHeader>
          <CardTitle>Carte Interactive</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-96 bg-muted rounded-lg flex items-center justify-center">
            <div className="text-center text-muted-foreground">
              <MapPin className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <h3 className="font-medium mb-2">Carte Interactive</h3>
              <p className="text-sm">
                La carte Google Maps sera intégrée ici pour visualiser les tournées
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

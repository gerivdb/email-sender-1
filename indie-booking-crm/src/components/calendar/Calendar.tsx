import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Button } from '../ui/Button'
import { Calendar as CalendarIcon, Plus, Filter } from 'lucide-react'

export function Calendar() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Calendrier</h1>
          <p className="text-muted-foreground">
            Gérez vos événements et synchronisez avec Google Calendar
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm">
            <Filter className="w-4 h-4" />
            Filtres
          </Button>
          <Button>
            <Plus className="w-4 h-4" />
            Nouvel Événement
          </Button>
        </div>
      </div>

      {/* Calendar placeholder */}
      <Card>
        <CardHeader>
          <CardTitle>Vue Calendrier</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-96 bg-muted rounded-lg flex items-center justify-center">
            <div className="text-center text-muted-foreground">
              <CalendarIcon className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <h3 className="font-medium mb-2">Calendrier Intégré</h3>
              <p className="text-sm">
                Le calendrier complet avec vue mensuelle/hebdomadaire sera intégré ici
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

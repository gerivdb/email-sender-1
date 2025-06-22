import { useEffect, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { KPICards } from './KPICards'
import { TourMapWidget } from './TourMapWidget'
import { KanbanPreview } from './KanbanPreview'
import { TaskList } from './TaskList'
import { useDashboardStats, useDeals, useTasks } from '../../hooks/useData'
import { formatCurrency, getRoleLabel } from '../../lib/utils'
import { Calendar, Clock, MapPin, TrendingUp } from 'lucide-react'

export function Dashboard() {
  const stats = useDashboardStats()
  const { data: deals } = useDeals()
  const { data: tasks } = useTasks()
  
  // Prochains événements
  const upcomingEvents = deals
    .filter(deal => deal.date_show && (deal.status === 'confirme' || deal.status === 'signe'))
    .sort((a, b) => new Date(a.date_show!).getTime() - new Date(b.date_show!).getTime())
    .slice(0, 3)

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-foreground mb-2">Dashboard</h1>
        <p className="text-muted-foreground">
          Vue d'ensemble de vos activités et performances
        </p>
      </div>

      {/* KPI Cards */}
      <KPICards stats={stats} />

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Carte de tournée */}
        <div className="lg:col-span-2">
          <TourMapWidget />
        </div>

        {/* Prochains événements */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="w-5 h-5 text-primary" />
              Prochains Shows
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {upcomingEvents.length > 0 ? (
              upcomingEvents.map((deal) => (
                <div key={deal.id} className="p-3 rounded-lg border border-border bg-muted/30">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-medium text-foreground">{deal.artiste}</h4>
                    <Badge variant="status" status={deal.status} size="sm">
                      {deal.status}
                    </Badge>
                  </div>
                  <div className="space-y-1 text-sm text-muted-foreground">
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4" />
                      {deal.venue}
                    </div>
                    <div className="flex items-center gap-2">
                      <Calendar className="w-4 h-4" />
                      {new Date(deal.date_show!).toLocaleDateString('fr-FR', {
                        weekday: 'long',
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      })}
                    </div>
                    <div className="flex items-center gap-2">
                      <TrendingUp className="w-4 h-4" />
                      {formatCurrency(deal.fee_artistique)}
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center text-muted-foreground py-8">
                <Calendar className="w-12 h-12 mx-auto mb-4 opacity-50" />
                <p>Aucun événement confirmé</p>
              </div>
            )}
            
            <Button variant="outline" className="w-full">
              Voir tous les événements
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Kanban Preview + Tasks */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Aperçu Kanban */}
        <div className="xl:col-span-2">
          <KanbanPreview deals={deals} />
        </div>

        {/* Liste des tâches */}
        <div>
          <TaskList tasks={tasks} />
        </div>
      </div>

      {/* Statistiques rapides */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Commission totale</p>
                <p className="text-2xl font-bold text-foreground">
                  {formatCurrency(
                    deals
                      .filter(d => d.status === 'signe' || d.status === 'termine')
                      .reduce((sum, d) => sum + d.commission_montant, 0)
                  )}
                </p>
              </div>
              <TrendingUp className="w-8 h-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Taux de conversion</p>
                <p className="text-2xl font-bold text-foreground">
                  {Math.round((deals.filter(d => d.status === 'signe').length / Math.max(deals.length, 1)) * 100)}%
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center">
                <span className="text-blue-500 font-bold">%</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Deals actifs</p>
                <p className="text-2xl font-bold text-foreground">
                  {deals.filter(d => ['prospect', 'offre', 'negotiation', 'confirme'].includes(d.status)).length}
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-purple-500/20 flex items-center justify-center">
                <span className="text-purple-500 font-bold">#</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Deadline cette semaine</p>
                <p className="text-2xl font-bold text-foreground">
                  {tasks.filter(task => {
                    if (!task.due_date) return false
                    const dueDate = new Date(task.due_date)
                    const today = new Date()
                    const weekFromNow = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000)
                    return dueDate >= today && dueDate <= weekFromNow && task.status !== 'completed'
                  }).length}
                </p>
              </div>
              <Clock className="w-8 h-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

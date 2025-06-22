import { Card, CardContent } from '../ui/Card'
import { formatCurrency } from '../../lib/utils'
import { Calendar, Handshake, DollarSign, CheckSquare, TrendingUp, Clock } from 'lucide-react'

interface KPIStats {
  prochains_shows: number
  deals_en_negociation: number
  ca_ytd: number
  taches_dues: number
}

interface KPICardsProps {
  stats: KPIStats
}

export function KPICards({ stats }: KPICardsProps) {
  const kpis = [
    {
      id: 'shows',
      title: 'Prochains Shows',
      value: stats.prochains_shows,
      icon: Calendar,
      color: 'text-blue-500',
      bgColor: 'bg-blue-500/20',
      trend: '+12%',
      trendDirection: 'up' as const
    },
    {
      id: 'deals',
      title: 'Deals en Négociation',
      value: stats.deals_en_negociation,
      icon: Handshake,
      color: 'text-purple-500',
      bgColor: 'bg-purple-500/20',
      trend: '+8%',
      trendDirection: 'up' as const
    },
    {
      id: 'revenue',
      title: 'CA YTD',
      value: formatCurrency(stats.ca_ytd),
      icon: DollarSign,
      color: 'text-green-500',
      bgColor: 'bg-green-500/20',
      trend: '+24%',
      trendDirection: 'up' as const
    },
    {
      id: 'tasks',
      title: 'Tâches Dues',
      value: stats.taches_dues,
      icon: Clock,
      color: 'text-red-500',
      bgColor: 'bg-red-500/20',
      trend: '-5%',
      trendDirection: 'down' as const
    }
  ]

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {kpis.map((kpi) => {
        const Icon = kpi.icon
        return (
          <Card key={kpi.id} className="relative overflow-hidden">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div className="space-y-2">
                  <p className="text-sm font-medium text-muted-foreground">
                    {kpi.title}
                  </p>
                  <p className="text-2xl font-bold text-foreground">
                    {kpi.value}
                  </p>
                  
                  {/* Tendance */}
                  <div className="flex items-center gap-1">
                    <TrendingUp 
                      className={`w-4 h-4 ${
                        kpi.trendDirection === 'up' ? 'text-green-500' : 'text-red-500'
                      } ${kpi.trendDirection === 'down' ? 'rotate-180' : ''}`} 
                    />
                    <span className={`text-sm ${
                      kpi.trendDirection === 'up' ? 'text-green-500' : 'text-red-500'
                    }`}>
                      {kpi.trend}
                    </span>
                    <span className="text-xs text-muted-foreground">vs mois dernier</span>
                  </div>
                </div>

                {/* Icône */}
                <div className={`w-12 h-12 ${kpi.bgColor} rounded-lg flex items-center justify-center`}>
                  <Icon className={`w-6 h-6 ${kpi.color}`} />
                </div>
              </div>

              {/* Barre de progression décorative */}
              <div className="mt-4">
                <div className="w-full bg-muted rounded-full h-1">
                  <div 
                    className={`h-1 rounded-full bg-gradient-to-r from-primary/60 to-primary`}
                    style={{ width: `${Math.min((typeof kpi.value === 'number' ? kpi.value : 50), 100)}%` }}
                  />
                </div>
              </div>
            </CardContent>

            {/* Effet de brillance */}
            <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-white/5 to-transparent pointer-events-none" />
          </Card>
        )
      })}
    </div>
  )
}

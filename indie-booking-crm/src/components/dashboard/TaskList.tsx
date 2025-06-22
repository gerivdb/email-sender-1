import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { formatRelativeTime, getRoleLabel, getStatusLabel, getPriorityLabel } from '../../lib/utils'
import { CheckSquare, Clock, Filter, User, ChevronDown } from 'lucide-react'
import type { Task, UserRole } from '../../types'

interface TaskListProps {
  tasks: Task[]
}

export function TaskList({ tasks }: TaskListProps) {
  const [selectedRole, setSelectedRole] = useState<UserRole | 'all'>('all')
  const [showCompleted, setShowCompleted] = useState(false)

  // Filtrer les tâches
  const filteredTasks = tasks.filter(task => {
    if (selectedRole !== 'all' && task.assignee_role !== selectedRole) return false
    if (!showCompleted && task.status === 'completed') return false
    return true
  })

  // Trier par priorité et date
  const sortedTasks = filteredTasks.sort((a, b) => {
    const priorityOrder = { urgent: 4, high: 3, medium: 2, low: 1 }
    if (a.priority !== b.priority) {
      return priorityOrder[b.priority] - priorityOrder[a.priority]
    }
    if (a.due_date && b.due_date) {
      return new Date(a.due_date).getTime() - new Date(b.due_date).getTime()
    }
    return 0
  })

  const roles: UserRole[] = [
    'booker_agent',
    'tourneur_manager', 
    'attache_presse',
    'apporteur_affaires',
    'regisseur_general'
  ]

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <CheckSquare className="w-5 h-5 text-primary" />
            Tâches
          </div>
          <div className="flex items-center gap-2">
            {/* Filtre par rôle */}
            <div className="relative">
              <select
                value={selectedRole}
                onChange={(e) => setSelectedRole(e.target.value as UserRole | 'all')}
                className="appearance-none bg-muted border border-border rounded-lg px-3 py-1 text-sm text-foreground pr-8"
              >
                <option value="all">Tous les rôles</option>
                {roles.map(role => (
                  <option key={role} value={role}>
                    {getRoleLabel(role)}
                  </option>
                ))}
              </select>
              <ChevronDown className="absolute right-2 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
            </div>

            {/* Toggle terminées */}
            <Button
              variant={showCompleted ? "default" : "outline"}
              size="sm"
              onClick={() => setShowCompleted(!showCompleted)}
            >
              <Filter className="w-4 h-4" />
            </Button>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {sortedTasks.length > 0 ? (
          <div className="space-y-3 max-h-96 overflow-y-auto">
            {sortedTasks.slice(0, 10).map(task => {
              const isOverdue = task.due_date && 
                new Date(task.due_date) < new Date() && 
                task.status !== 'completed'
              
              return (
                <div 
                  key={task.id}
                  className={`p-3 rounded-lg border transition-colors cursor-pointer ${
                    task.status === 'completed' 
                      ? 'border-green-500/30 bg-green-500/10' 
                      : isOverdue
                        ? 'border-red-500/30 bg-red-500/10'
                        : 'border-border bg-card hover:bg-muted/50'
                  }`}
                >
                  <div className="space-y-2">
                    {/* Header avec statut */}
                    <div className="flex items-start justify-between">
                      <h4 className={`font-medium text-sm ${
                        task.status === 'completed' ? 'line-through text-muted-foreground' : 'text-foreground'
                      }`}>
                        {task.titre}
                      </h4>
                      <div className="flex items-center gap-2">
                        <Badge variant="priority" status={task.priority} size="sm">
                          {getPriorityLabel(task.priority)}
                        </Badge>
                        <Badge variant="status" status={task.status} size="sm">
                          {getStatusLabel(task.status, 'task')}
                        </Badge>
                      </div>
                    </div>

                    {/* Description */}
                    {task.description && (
                      <p className="text-xs text-muted-foreground line-clamp-2">
                        {task.description}
                      </p>
                    )}

                    {/* Métadonnées */}
                    <div className="flex items-center justify-between text-xs">
                      <div className="flex items-center gap-3">
                        <div className="flex items-center gap-1">
                          <User className="w-3 h-3" />
                          <span className="text-muted-foreground">
                            {getRoleLabel(task.assignee_role)}
                          </span>
                        </div>
                        
                        {task.due_date && (
                          <div className={`flex items-center gap-1 ${
                            isOverdue ? 'text-red-400' : 'text-muted-foreground'
                          }`}>
                            <Clock className="w-3 h-3" />
                            <span>
                              {isOverdue ? 'En retard' : formatRelativeTime(task.due_date)}
                            </span>
                          </div>
                        )}
                      </div>

                      {/* Actions */}
                      <div className="flex items-center gap-1">
                        {task.status !== 'completed' && (
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-6 px-2 text-xs"
                            onClick={(e) => {
                              e.stopPropagation()
                              // Marquer comme terminé
                              console.log('Marquer terminé:', task.id)
                            }}
                          >
                            ✓
                          </Button>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              )
            })}
            
            {sortedTasks.length > 10 && (
              <div className="text-center">
                <Button variant="outline" size="sm">
                  Voir toutes les tâches ({sortedTasks.length})
                </Button>
              </div>
            )}
          </div>
        ) : (
          <div className="text-center py-8 text-muted-foreground">
            <CheckSquare className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <h3 className="font-medium mb-2">Aucune tâche</h3>
            <p className="text-sm">
              {selectedRole === 'all' 
                ? 'Toutes les tâches sont terminées !' 
                : `Aucune tâche pour ${getRoleLabel(selectedRole)}`
              }
            </p>
          </div>
        )}

        {/* Résumé */}
        <div className="pt-3 border-t border-border">
          <div className="grid grid-cols-2 gap-4 text-center">
            <div>
              <p className="text-lg font-bold text-foreground">
                {tasks.filter(t => t.status !== 'completed').length}
              </p>
              <p className="text-xs text-muted-foreground">En cours</p>
            </div>
            <div>
              <p className="text-lg font-bold text-red-400">
                {tasks.filter(t => {
                  if (!t.due_date || t.status === 'completed') return false
                  return new Date(t.due_date) < new Date()
                }).length}
              </p>
              <p className="text-xs text-muted-foreground">En retard</p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

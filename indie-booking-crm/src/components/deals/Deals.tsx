import { useState } from 'react'
import { DragDropContext, DropResult } from '@hello-pangea/dnd'
import { KanbanBoard } from './KanbanBoard'
import { DealFilters } from './DealFilters'
import { DealDrawer } from './DealDrawer'
import { ContractPanel } from './ContractPanel'
import { useDeals, useContacts } from '../../hooks/useData'
import { Card, CardContent } from '../ui/Card'
import { Button } from '../ui/Button'
import { formatCurrency } from '../../lib/utils'
import { Handshake, Download, FileText, Plus, BarChart3 } from 'lucide-react'
import type { Deal, DealStatus, DealFilters as DealFiltersType } from '../../types'

export function Deals() {
  const { data: deals, setData: setDeals } = useDeals()
  const { data: contacts } = useContacts()
  const [filters, setFilters] = useState<Partial<DealFiltersType>>({})
  const [selectedDeal, setSelectedDeal] = useState<Deal | null>(null)
  const [isDrawerOpen, setIsDrawerOpen] = useState(false)
  const [isContractPanelOpen, setIsContractPanelOpen] = useState(false)

  // Grouper les deals par statut
  const dealsByStatus = deals.reduce((acc, deal) => {
    if (!acc[deal.status]) {
      acc[deal.status] = []
    }
    acc[deal.status].push(deal)
    return acc
  }, {} as Record<DealStatus, Deal[]>)

  const handleDragEnd = (result: DropResult) => {
    const { destination, source, draggableId } = result

    if (!destination) return
    if (destination.droppableId === source.droppableId && destination.index === source.index) return

    const deal = deals.find(d => d.id === draggableId)
    if (!deal) return

    const newStatus = destination.droppableId as DealStatus
    const updatedDeal = { ...deal, status: newStatus, updated_at: new Date().toISOString() }

    const updatedDeals = deals.map(d => d.id === draggableId ? updatedDeal : d)
    setDeals(updatedDeals)
  }

  const handleCreateDeal = () => {
    setSelectedDeal(null)
    setIsDrawerOpen(true)
  }

  const handleEditDeal = (deal: Deal) => {
    setSelectedDeal(deal)
    setIsDrawerOpen(true)
  }

  const handleSaveDeal = (dealData: Partial<Deal>) => {
    if (selectedDeal) {
      // Modifier deal existant
      const updatedDeals = deals.map(d => 
        d.id === selectedDeal.id 
          ? { ...d, ...dealData, updated_at: new Date().toISOString() }
          : d
      )
      setDeals(updatedDeals)
    } else {
      // Créer nouveau deal
      const newDeal: Deal = {
        id: `deal_${Date.now()}`,
        status: 'prospect',
        priority: 'medium',
        commission_pourcentage: 15,
        commission_montant: 0,
        fee_artistique: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        ...dealData
      } as Deal
      
      // Calculer la commission
      newDeal.commission_montant = Math.round(newDeal.fee_artistique * (newDeal.commission_pourcentage / 100))
      
      setDeals([...deals, newDeal])
    }
    setIsDrawerOpen(false)
  }

  const handleDeleteDeal = (dealId: string) => {
    setDeals(deals.filter(d => d.id !== dealId))
  }

  // Statistiques
  const stats = {
    totalDeals: deals.length,
    totalValue: deals.reduce((sum, deal) => sum + deal.fee_artistique, 0),
    totalCommission: deals.reduce((sum, deal) => sum + deal.commission_montant, 0),
    conversionRate: Math.round((deals.filter(d => d.status === 'signe').length / Math.max(deals.length, 1)) * 100)
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Pipeline des Deals</h1>
          <p className="text-muted-foreground">
            Gérez vos négociations et suivez vos opportunités
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm">
            <BarChart3 className="w-4 h-4" />
            Analytics
          </Button>
          <Button variant="outline" size="sm" onClick={() => setIsContractPanelOpen(true)}>
            <FileText className="w-4 h-4" />
            Générer Contrat
          </Button>
          <Button variant="outline" size="sm">
            <Download className="w-4 h-4" />
            Exporter
          </Button>
          <Button onClick={handleCreateDeal}>
            <Plus className="w-4 h-4" />
            Nouveau Deal
          </Button>
        </div>
      </div>

      {/* Statistiques rapides */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Deals</p>
                <p className="text-2xl font-bold text-foreground">{stats.totalDeals}</p>
              </div>
              <Handshake className="w-8 h-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Valeur Pipeline</p>
                <p className="text-2xl font-bold text-foreground">{formatCurrency(stats.totalValue)}</p>
              </div>
              <div className="w-8 h-8 rounded-full bg-green-500/20 flex items-center justify-center">
                <span className="text-green-500 font-bold">€</span>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Commission Prévue</p>
                <p className="text-2xl font-bold text-foreground">{formatCurrency(stats.totalCommission)}</p>
              </div>
              <div className="w-8 h-8 rounded-full bg-purple-500/20 flex items-center justify-center">
                <span className="text-purple-500 font-bold">%</span>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Taux Conversion</p>
                <p className="text-2xl font-bold text-foreground">{stats.conversionRate}%</p>
              </div>
              <div className="w-8 h-8 rounded-full bg-orange-500/20 flex items-center justify-center">
                <span className="text-orange-500 font-bold">📈</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filtres */}
      <DealFilters
        filters={filters}
        onFiltersChange={setFilters}
        deals={deals}
      />

      {/* Kanban Board */}
      <DragDropContext onDragEnd={handleDragEnd}>
        <KanbanBoard
          dealsByStatus={dealsByStatus}
          onEditDeal={handleEditDeal}
          onDeleteDeal={handleDeleteDeal}
          contacts={contacts}
        />
      </DragDropContext>

      {/* Deal Drawer */}
      <DealDrawer
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        deal={selectedDeal}
        onSave={handleSaveDeal}
        contacts={contacts}
      />

      {/* Contract Panel */}
      <ContractPanel
        isOpen={isContractPanelOpen}
        onClose={() => setIsContractPanelOpen(false)}
        deals={deals}
        contacts={contacts}
      />
    </div>
  )
}

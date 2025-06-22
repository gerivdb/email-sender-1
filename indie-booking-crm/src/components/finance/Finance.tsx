import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { Button } from '../ui/Button'
import { Badge } from '../ui/Badge'
import { DollarSign, Plus, Download, Receipt } from 'lucide-react'
import { useInvoices } from '../../hooks/useData'
import { formatCurrency, getStatusLabel } from '../../lib/utils'

export function Finance() {
  const { data: invoices } = useInvoices()

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">Finance</h1>
          <p className="text-muted-foreground">
            Gérez vos budgets, factures et commissions
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm">
            <Download className="w-4 h-4" />
            Export Comptable
          </Button>
          <Button>
            <Plus className="w-4 h-4" />
            Nouvelle Facture
          </Button>
        </div>
      </div>

      {/* KPIs Financiers */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">CA Total</p>
                <p className="text-2xl font-bold text-foreground">
                  {formatCurrency(invoices.reduce((sum, inv) => sum + inv.montant, 0))}
                </p>
              </div>
              <DollarSign className="w-8 h-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Factures Payées</p>
                <p className="text-2xl font-bold text-foreground">
                  {invoices.filter(inv => inv.status === 'paye').length}
                </p>
              </div>
              <Receipt className="w-8 h-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">En Attente</p>
                <p className="text-2xl font-bold text-foreground">
                  {formatCurrency(
                    invoices
                      .filter(inv => inv.status === 'envoye')
                      .reduce((sum, inv) => sum + inv.montant, 0)
                  )}
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-yellow-500/20 flex items-center justify-center">
                <span className="text-yellow-500 font-bold">⏳</span>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">En Retard</p>
                <p className="text-2xl font-bold text-foreground">
                  {invoices.filter(inv => inv.status === 'en_retard').length}
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-red-500/20 flex items-center justify-center">
                <span className="text-red-500 font-bold">⚠️</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Liste des factures */}
      <Card>
        <CardHeader>
          <CardTitle>Factures Récentes</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {invoices.map(invoice => (
              <div key={invoice.id} className="flex items-center justify-between p-4 rounded-lg border border-border">
                <div className="space-y-1">
                  <p className="font-medium text-foreground">{invoice.numero}</p>
                  <p className="text-sm text-muted-foreground">{invoice.client}</p>
                  <p className="text-xs text-muted-foreground">{invoice.description}</p>
                </div>
                
                <div className="text-right space-y-1">
                  <p className="font-medium text-foreground">{formatCurrency(invoice.total)}</p>
                  <Badge variant="status" status={invoice.status} size="sm">
                    {getStatusLabel(invoice.status, 'invoice')}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

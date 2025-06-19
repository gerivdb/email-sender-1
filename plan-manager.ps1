# 🚀 Plan Management Utility
# Utilitaire de gestion des plans de développement v64 & v65

param(
    [Parameter()]
    [ValidateSet("status", "v64", "v65", "reports", "next", "help")]
    [string]$Action = "help",
    
    [Parameter()]
    [string]$TaskRange = "",
    
    [Parameter()]
    [switch]$Detailed = $false
)

$ErrorActionPreference = "Stop"

# Configuration des chemins
$RootPath = $PSScriptRoot
$PlansPath = Join-Path $RootPath "projet\roadmaps\plans\consolidated"
$PlanV64 = Join-Path $PlansPath "plan-dev-v64-correlation-avec-manager-go-existant.md"
$PlanV65 = Join-Path $PlansPath "plan-dev-v65-extensions-manager-hybride.md"

function Show-Header {
    param([string]$Title, [string]$Icon = "🎯")
    
    Write-Host ""
    Write-Host "$Icon ============================================" -ForegroundColor Cyan
    Write-Host "$Icon $Title" -ForegroundColor Yellow
    Write-Host "$Icon ============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Status {
    Show-Header "STATUS GLOBAL DES PLANS" "📊"
    
    # Vérification existence des fichiers
    $v64Exists = Test-Path $PlanV64
    $v65Exists = Test-Path $PlanV65
    
    Write-Host "📁 FICHIERS DE PLANS:" -ForegroundColor Green
    Write-Host "  • Plan v64: " -NoNewline
    if ($v64Exists) {
        Write-Host "✅ PRÉSENT" -ForegroundColor Green
    } else {
        Write-Host "❌ MANQUANT" -ForegroundColor Red
    }
    
    Write-Host "  • Plan v65: " -NoNewline
    if ($v65Exists) {
        Write-Host "✅ PRÉSENT" -ForegroundColor Green
    } else {
        Write-Host "❌ MANQUANT" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Comptage des actions complétées dans v64
    if ($v64Exists) {
        $v64Content = Get-Content $PlanV64 -Raw
        $completedTasks = ([regex]::Matches($v64Content, "\[x\].*Action")).Count
        $totalTasksV64 = ([regex]::Matches($v64Content, "\[.\].*Action")).Count
        
        Write-Host "📋 PLAN V64 - ÉTAT D'AVANCEMENT:" -ForegroundColor Green
        Write-Host "  • Actions complétées: $completedTasks/$totalTasksV64" -ForegroundColor Yellow
        
        if ($totalTasksV64 -gt 0) {
            $percentage = [math]::Round(($completedTasks / $totalTasksV64) * 100, 1)
            Write-Host "  • Progression: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } else { "Yellow" })
        }
    }
    
    # Information sur v65
    if ($v65Exists) {
        $v65Content = Get-Content $PlanV65 -Raw
        $v65Tasks = ([regex]::Matches($v65Content, "Action Atomique \d+")).Count
        
        Write-Host ""
        Write-Host "🚀 PLAN V65 - INFORMATION:" -ForegroundColor Green
        Write-Host "  • Actions définies: $v65Tasks" -ForegroundColor Yellow
        Write-Host "  • Status: EN DÉVELOPPEMENT" -ForegroundColor Cyan
    }
    
    # Rapports d'implémentation
    $reports = Get-ChildItem -Path $RootPath -Name "ACTIONS_*_IMPLEMENTATION_REPORT.md"
    Write-Host ""
    Write-Host "📄 RAPPORTS D'IMPLÉMENTATION:" -ForegroundColor Green
    if ($reports.Count -gt 0) {
        foreach ($report in $reports) {
            Write-Host "  ✅ $report" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠️  Aucun rapport trouvé" -ForegroundColor Yellow
    }
}

function Show-PlanV64 {
    Show-Header "PLAN V64 - ACTIONS DÉTAILLÉES" "📋"
    
    if (-not (Test-Path $PlanV64)) {
        Write-Host "❌ Plan v64 non trouvé: $PlanV64" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $PlanV64 -Raw
    
    # Extraction des actions avec leur statut
    $actionPattern = '\[(x| )\].*?(Action \d+[^:]*):([^\n]*)'
    $matches = [regex]::Matches($content, $actionPattern)
    
    $completedActions = @()
    $pendingActions = @()
    
    foreach ($match in $matches) {
        $status = $match.Groups[1].Value
        $actionNumber = $match.Groups[2].Value
        $description = $match.Groups[3].Value.Trim()
        
        $actionInfo = @{
            Number = $actionNumber
            Description = $description
            Status = if ($status -eq "x") { "✅ TERMINÉ" } else { "🔄 EN COURS" }
        }
        
        if ($status -eq "x") {
            $completedActions += $actionInfo
        } else {
            $pendingActions += $actionInfo
        }
    }
    
    Write-Host "✅ ACTIONS TERMINÉES ($($completedActions.Count)):" -ForegroundColor Green
    foreach ($action in $completedActions) {
        Write-Host "  $($action.Status) $($action.Number)" -ForegroundColor Green
        if ($Detailed) {
            Write-Host "    └─ $($action.Description)" -ForegroundColor Gray
        }
    }
    
    if ($pendingActions.Count -gt 0) {
        Write-Host ""
        Write-Host "🔄 ACTIONS EN COURS ($($pendingActions.Count)):" -ForegroundColor Yellow
        foreach ($action in $pendingActions) {
            Write-Host "  $($action.Status) $($action.Number)" -ForegroundColor Yellow
            if ($Detailed) {
                Write-Host "    └─ $($action.Description)" -ForegroundColor Gray
            }
        }
    }
}

function Show-PlanV65 {
    Show-Header "PLAN V65 - EXTENSIONS MANAGER" "🚀"
    
    if (-not (Test-Path $PlanV65)) {
        Write-Host "❌ Plan v65 non trouvé: $PlanV65" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $PlanV65 -Raw
    
    # Extraction des actions atomiques v65
    $actionPattern = 'Action Atomique (\d+)[^:]*:([^\n]*)'
    $matches = [regex]::Matches($content, $actionPattern)
    
    Write-Host "🎯 ACTIONS ATOMIQUES V65:" -ForegroundColor Cyan
    foreach ($match in $matches) {
        $actionNumber = $match.Groups[1].Value
        $description = $match.Groups[2].Value.Trim()
        
        Write-Host "  📋 Action $actionNumber" -ForegroundColor Yellow
        if ($Detailed) {
            Write-Host "    └─ $description" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "💡 PROCHAINES PRIORITÉS:" -ForegroundColor Green
    Write-Host "  1. API Gateway v2 + GraphQL (Actions 076-081)" -ForegroundColor White
    Write-Host "  2. Système Quotas Multi-tenant (Action 082)" -ForegroundColor White
    Write-Host "  3. Gestion Erreurs Avancée (Action 083)" -ForegroundColor White
}

function Show-Reports {
    Show-Header "RAPPORTS D'IMPLÉMENTATION" "📄"
    
    $reports = Get-ChildItem -Path $RootPath -Name "ACTIONS_*_IMPLEMENTATION_REPORT.md" | Sort-Object
    
    if ($reports.Count -eq 0) {
        Write-Host "⚠️  Aucun rapport d'implémentation trouvé" -ForegroundColor Yellow
        return
    }
    
    foreach ($report in $reports) {
        $reportPath = Join-Path $RootPath $report
        $content = Get-Content $reportPath -Raw
        
        # Extraction du titre et du statut
        if ($content -match '# ([^\n]+)') {
            $title = $matches[1]
        } else {
            $title = $report
        }
        
        if ($content -match 'Statut global.*?:\s*(.+)') {
            $status = $matches[1].Trim()
        } else {
            $status = "Non défini"
        }
        
        Write-Host "📋 $title" -ForegroundColor Yellow
        Write-Host "   Status: $status" -ForegroundColor $(if ($status -match "SUCCÈS|COMPLET") { "Green" } else { "Yellow" })
        Write-Host "   Fichier: $report" -ForegroundColor Gray
        Write-Host ""
    }
}

function Show-NextSteps {
    Show-Header "PROCHAINES ÉTAPES RECOMMANDÉES" "🎯"
    
    Write-Host "🚀 PRIORITÉ IMMÉDIATE (Semaine 1-2):" -ForegroundColor Green
    Write-Host "  1. Finaliser les actions 076-081 du plan v65" -ForegroundColor White
    Write-Host "  2. Implémenter le système de quotas multi-tenant" -ForegroundColor White
    Write-Host "  3. Développer l'API Gateway v2 avec GraphQL" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📋 MOYEN TERME (Semaine 3-4):" -ForegroundColor Yellow
    Write-Host "  1. Gestion avancée des erreurs avec circuit breaker" -ForegroundColor White
    Write-Host "  2. Monitoring temps réel avec WebSocket" -ForegroundColor White
    Write-Host "  3. Système d'internationalisation (i18n)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔮 LONG TERME (Mois 2):" -ForegroundColor Cyan
    Write-Host "  1. Compliance RGPD avec audit trail" -ForegroundColor White
    Write-Host "  2. SDK mobile pour iOS/Android" -ForegroundColor White
    Write-Host "  3. Edge computing géo-distribué" -ForegroundColor White
    Write-Host ""
    
    Write-Host "💡 COMMANDES UTILES:" -ForegroundColor Magenta
    Write-Host "  • .\plan-manager.ps1 status -Detailed" -ForegroundColor Gray
    Write-Host "  • .\plan-manager.ps1 v64 -Detailed" -ForegroundColor Gray
    Write-Host "  • .\plan-manager.ps1 v65 -Detailed" -ForegroundColor Gray
    Write-Host "  • .\plan-manager.ps1 reports" -ForegroundColor Gray
}

function Show-Help {
    Show-Header "AIDE - PLAN MANAGER UTILITY" "💡"
    
    Write-Host "UTILISATION:" -ForegroundColor Green
    Write-Host "  .\plan-manager.ps1 [ACTION] [OPTIONS]" -ForegroundColor White
    Write-Host ""
    
    Write-Host "ACTIONS DISPONIBLES:" -ForegroundColor Yellow
    Write-Host "  status    - Affiche le statut global des plans" -ForegroundColor White
    Write-Host "  v64       - Détails du plan v64 (actions terminées/en cours)" -ForegroundColor White
    Write-Host "  v65       - Détails du plan v65 (extensions manager)" -ForegroundColor White
    Write-Host "  reports   - Liste tous les rapports d'implémentation" -ForegroundColor White
    Write-Host "  next      - Affiche les prochaines étapes recommandées" -ForegroundColor White
    Write-Host "  help      - Affiche cette aide" -ForegroundColor White
    Write-Host ""
    
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -Detailed - Affiche des informations détaillées" -ForegroundColor White
    Write-Host ""
    
    Write-Host "EXEMPLES:" -ForegroundColor Green
    Write-Host "  .\plan-manager.ps1 status" -ForegroundColor Gray
    Write-Host "  .\plan-manager.ps1 v64 -Detailed" -ForegroundColor Gray
    Write-Host "  .\plan-manager.ps1 reports" -ForegroundColor Gray
}

# Exécution principale
try {
    switch ($Action.ToLower()) {
        "status" { Show-Status }
        "v64" { Show-PlanV64 }
        "v65" { Show-PlanV65 }
        "reports" { Show-Reports }
        "next" { Show-NextSteps }
        "help" { Show-Help }
        default { Show-Help }
    }
} catch {
    Write-Host ""
    Write-Host "❌ ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Show-Help
    exit 1
}

Write-Host ""
Write-Host "✅ Opération terminée avec succès!" -ForegroundColor Green
Write-Host ""
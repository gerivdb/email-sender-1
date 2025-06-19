# 🔍 Plan Validation Utility
# Validation de l'intégrité et cohérence des plans v64 & v65

param(
    [Parameter()]
    [ValidateSet("all", "v64", "v65", "reports", "links", "help")]
    [string]$Scope = "all",
    
    [Parameter()]
    [switch]$Fix = $false,
    
    [Parameter()]
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Configuration
$RootPath = $PSScriptRoot
$PlansPath = Join-Path $RootPath "projet\roadmaps\plans\consolidated"
$PlanV64 = Join-Path $PlansPath "plan-dev-v64-correlation-avec-manager-go-existant.md"
$PlanV65 = Join-Path $PlansPath "plan-dev-v65-extensions-manager-hybride.md"

$ValidationResults = @{
    Errors = @()
    Warnings = @()
    Info = @()
    Stats = @{}
}

function Write-ValidationMessage {
    param(
        [string]$Message,
        [ValidateSet("Error", "Warning", "Info", "Success")]
        [string]$Type = "Info"
    )
    
    $color = switch ($Type) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        default { "White" }
    }
    
    $icon = switch ($Type) {
        "Error" { "❌" }
        "Warning" { "⚠️ " }
        "Success" { "✅" }
        default { "💡" }
    }
    
    if ($Verbose -or $Type -in @("Error", "Warning")) {
        Write-Host "$icon $Message" -ForegroundColor $color
    }
    
    switch ($Type) {
        "Error" { $ValidationResults.Errors += $Message }
        "Warning" { $ValidationResults.Warnings += $Message }
        "Info" { $ValidationResults.Info += $Message }
    }
}

function Test-FileExists {
    param([string]$FilePath, [string]$Description)
    
    if (Test-Path $FilePath) {
        Write-ValidationMessage "Fichier trouvé: $Description" "Success"
        return $true
    } else {
        Write-ValidationMessage "Fichier manquant: $Description ($FilePath)" "Error"
        return $false
    }
}

function Test-PlanV64 {
    Write-Host ""
    Write-Host "🔍 VALIDATION PLAN V64..." -ForegroundColor Cyan
    
    if (-not (Test-FileExists $PlanV64 "Plan v64")) {
        return
    }
    
    $content = Get-Content $PlanV64 -Raw
    
    # Test 1: Actions numérotées
    $actionPattern = '\[(x| )\].*?(Action \d+)'
    $actions = [regex]::Matches($content, $actionPattern)
    
    Write-ValidationMessage "Actions trouvées: $($actions.Count)" "Info"
    $ValidationResults.Stats.V64_Actions_Total = $actions.Count
    
    # Test 2: Actions complétées
    $completedActions = $actions | Where-Object { $_.Groups[1].Value -eq "x" }
    Write-ValidationMessage "Actions complétées: $($completedActions.Count)" "Info"
    $ValidationResults.Stats.V64_Actions_Completed = $completedActions.Count
    
    # Test 3: Continuité numérique
    $actionNumbers = @()
    foreach ($action in $actions) {
        if ($action.Groups[2].Value -match 'Action (\d+)') {
            $actionNumbers += [int]$matches[1]
        }
    }
    
    $actionNumbers = $actionNumbers | Sort-Object
    $expectedStart = 30
    $expectedEnd = 75
    
    # Vérification de la séquence
    for ($i = $expectedStart; $i -le $expectedEnd; $i++) {
        if ($i -notin $actionNumbers) {
            Write-ValidationMessage "Action manquante: Action $i" "Warning"
        }
    }
    
    # Test 4: Structure markdown
    $requiredSections = @(
        "# Plan de Développement",
        "## 🎯 ACTIONS ATOMIQUES",
        "### 📋 Lot"
    )
    
    foreach ($section in $requiredSections) {
        if ($content -match [regex]::Escape($section)) {
            Write-ValidationMessage "Section trouvée: $section" "Success"
        } else {
            Write-ValidationMessage "Section manquante: $section" "Warning"
        }
    }
    
    # Test 5: Liens vers livrables
    $deliverablePattern = 'Sortie.*?`([^`]+)`'
    $deliverables = [regex]::Matches($content, $deliverablePattern)
    
    Write-ValidationMessage "Livrables définis: $($deliverables.Count)" "Info"
    $ValidationResults.Stats.V64_Deliverables = $deliverables.Count
    
    # Vérification existence fichiers de sortie
    $missingDeliverables = 0
    foreach ($deliverable in $deliverables) {
        $filePath = $deliverable.Groups[1].Value
        $fullPath = Join-Path $RootPath $filePath
        
        if (-not (Test-Path $fullPath)) {
            $missingDeliverables++
            if ($Verbose) {
                Write-ValidationMessage "Livrable manquant: $filePath" "Warning"
            }
        }
    }
    
    if ($missingDeliverables -gt 0) {
        Write-ValidationMessage "Livrables manquants: $missingDeliverables/$($deliverables.Count)" "Warning"
    } else {
        Write-ValidationMessage "Tous les livrables sont présents" "Success"
    }
}

function Test-PlanV65 {
    Write-Host ""
    Write-Host "🔍 VALIDATION PLAN V65..." -ForegroundColor Cyan
    
    if (-not (Test-FileExists $PlanV65 "Plan v65")) {
        return
    }
    
    $content = Get-Content $PlanV65 -Raw
    
    # Test 1: Actions atomiques v65
    $actionPattern = 'Action Atomique (\d+)'
    $actions = [regex]::Matches($content, $actionPattern)
    
    Write-ValidationMessage "Actions atomiques trouvées: $($actions.Count)" "Info"
    $ValidationResults.Stats.V65_Actions_Total = $actions.Count
    
    # Test 2: Range d'actions attendu (076-090)
    $actionNumbers = @()
    foreach ($action in $actions) {
        $actionNumbers += [int]$action.Groups[1].Value
    }
    
    $actionNumbers = $actionNumbers | Sort-Object | Get-Unique
    $expectedRange = 76..90
    
    foreach ($expected in $expectedRange) {
        if ($expected -notin $actionNumbers) {
            Write-ValidationMessage "Action v65 manquante: Action $expected" "Warning"
        }
    }
    
    # Test 3: Structure avancée
    $requiredV65Sections = @(
        "🚨 CONSIGNES CRITIQUES",
        "🏗️ ARCHITECTURE v65",
        "🎯 ROADMAP ULTRA-GRANULAIRE",
        "📊 MATRICE DE DÉPENDANCES"
    )
    
    foreach ($section in $requiredV65Sections) {
        if ($content -match [regex]::Escape($section)) {
            Write-ValidationMessage "Section v65 trouvée: $section" "Success"
        } else {
            Write-ValidationMessage "Section v65 manquante: $section" "Warning"
        }
    }
    
    # Test 4: Exemples de code
    $codeBlocks = [regex]::Matches($content, '```(?:go|yaml|json|typescript)')
    Write-ValidationMessage "Blocs de code trouvés: $($codeBlocks.Count)" "Info"
    $ValidationResults.Stats.V65_Code_Examples = $codeBlocks.Count
    
    if ($codeBlocks.Count -lt 10) {
        Write-ValidationMessage "Peu d'exemples de code (recommandé: 15+)" "Warning"
    }
    
    # Test 5: Diagrammes
    $diagrams = [regex]::Matches($content, '```(?:mermaid|plantuml)')
    Write-ValidationMessage "Diagrammes trouvés: $($diagrams.Count)" "Info"
    $ValidationResults.Stats.V65_Diagrams = $diagrams.Count
}

function Test-ImplementationReports {
    Write-Host ""
    Write-Host "🔍 VALIDATION RAPPORTS D'IMPLÉMENTATION..." -ForegroundColor Cyan
    
    $reports = Get-ChildItem -Path $RootPath -Name "ACTIONS_*_IMPLEMENTATION_REPORT.md"
    
    Write-ValidationMessage "Rapports trouvés: $($reports.Count)" "Info"
    $ValidationResults.Stats.Implementation_Reports = $reports.Count
    
    # Vérification structure rapports
    foreach ($report in $reports) {
        $reportPath = Join-Path $RootPath $report
        $content = Get-Content $reportPath -Raw
        
        $requiredReportSections = @(
            "# 🎯 Rapport d'Implémentation",
            "## 📋 Résumé Exécutif",
            "## 🔍 Récapitulatif des Actions",
            "Statut global"
        )
        
        $missingSections = 0
        foreach ($section in $requiredReportSections) {
            if (-not ($content -match [regex]::Escape($section))) {
                $missingSections++
            }
        }
        
        if ($missingSections -eq 0) {
            Write-ValidationMessage "Rapport valide: $report" "Success"
        } else {
            Write-ValidationMessage "Rapport incomplet: $report ($missingSections sections manquantes)" "Warning"
        }
    }
    
    # Vérification couverture actions
    $expectedReports = @(
        "ACTIONS_030_032_IMPLEMENTATION_REPORT.md",
        "ACTIONS_033_041_IMPLEMENTATION_REPORT.md", 
        "ACTIONS_042_044_IMPLEMENTATION_REPORT.md",
        "ACTIONS_046_060_IMPLEMENTATION_REPORT.md",
        "ACTIONS_061_075_IMPLEMENTATION_REPORT.md"
    )
    
    foreach ($expectedReport in $expectedReports) {
        if ($expectedReport -in $reports.Name) {
            Write-ValidationMessage "Rapport attendu présent: $expectedReport" "Success"
        } else {
            Write-ValidationMessage "Rapport attendu manquant: $expectedReport" "Warning"
        }
    }
}

function Test-CrossReferences {
    Write-Host ""
    Write-Host "🔍 VALIDATION RÉFÉRENCES CROISÉES..." -ForegroundColor Cyan
    
    # Test cohérence numérotation actions entre v64 et rapports
    if ((Test-Path $PlanV64)) {
        $v64Content = Get-Content $PlanV64 -Raw
        $v64Actions = [regex]::Matches($v64Content, 'Action (\d+)') | ForEach-Object { [int]$_.Groups[1].Value }
        
        $reports = Get-ChildItem -Path $RootPath -Name "ACTIONS_*_IMPLEMENTATION_REPORT.md"
        $reportActions = @()
        
        foreach ($report in $reports) {
            if ($report -match 'ACTIONS_(\d+)_(\d+)_') {
                $start = [int]$matches[1]
                $end = [int]$matches[2]
                $reportActions += $start..$end
            }
        }
        
        # Vérification couverture
        $uncoveredActions = $v64Actions | Where-Object { $_ -notin $reportActions }
        
        if ($uncoveredActions.Count -eq 0) {
            Write-ValidationMessage "Toutes les actions v64 sont couvertes par les rapports" "Success"
        } else {
            Write-ValidationMessage "Actions v64 non couvertes: $($uncoveredActions -join ', ')" "Warning"
        }
    }
}

function Show-ValidationSummary {
    Write-Host ""
    Write-Host "📊 RÉSUMÉ DE VALIDATION" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    # Statistiques
    if ($ValidationResults.Stats.Count -gt 0) {
        Write-Host ""
        Write-Host "📈 STATISTIQUES:" -ForegroundColor Green
        foreach ($stat in $ValidationResults.Stats.GetEnumerator()) {
            Write-Host "  • $($stat.Key): $($stat.Value)" -ForegroundColor White
        }
    }
    
    # Résumé des problèmes
    Write-Host ""
    Write-Host "🚨 PROBLÈMES DÉTECTÉS:" -ForegroundColor Yellow
    Write-Host "  • Erreurs: $($ValidationResults.Errors.Count)" -ForegroundColor $(if ($ValidationResults.Errors.Count -eq 0) { "Green" } else { "Red" })
    Write-Host "  • Avertissements: $($ValidationResults.Warnings.Count)" -ForegroundColor $(if ($ValidationResults.Warnings.Count -eq 0) { "Green" } else { "Yellow" })
    
    # Score global
    $totalIssues = $ValidationResults.Errors.Count + $ValidationResults.Warnings.Count
    $score = if ($totalIssues -eq 0) { 100 } else { [math]::Max(0, 100 - ($ValidationResults.Errors.Count * 10 + $ValidationResults.Warnings.Count * 2)) }
    
    Write-Host ""
    Write-Host "🏆 SCORE DE QUALITÉ: $score/100" -ForegroundColor $(
        if ($score -ge 90) { "Green" }
        elseif ($score -ge 70) { "Yellow" }
        else { "Red" }
    )
    
    # Recommandations
    if ($ValidationResults.Errors.Count -gt 0) {
        Write-Host ""
        Write-Host "🔧 ACTIONS CORRECTIVES RECOMMANDÉES:" -ForegroundColor Red
        foreach ($error in $ValidationResults.Errors) {
            Write-Host "  ❌ $error" -ForegroundColor Red
        }
    }
    
    if ($ValidationResults.Warnings.Count -gt 0 -and $Verbose) {
        Write-Host ""
        Write-Host "⚠️  AMÉLIORATIONS SUGGÉRÉES:" -ForegroundColor Yellow
        foreach ($warning in $ValidationResults.Warnings) {
            Write-Host "  ⚠️  $warning" -ForegroundColor Yellow
        }
    }
}

function Show-Help {
    Write-Host ""
    Write-Host "💡 AIDE - PLAN VALIDATION UTILITY" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "UTILISATION:" -ForegroundColor Green
    Write-Host "  .\validate-plans.ps1 [SCOPE] [OPTIONS]" -ForegroundColor White
    Write-Host ""
    
    Write-Host "SCOPES DISPONIBLES:" -ForegroundColor Yellow
    Write-Host "  all       - Validation complète (défaut)" -ForegroundColor White
    Write-Host "  v64       - Validation plan v64 uniquement" -ForegroundColor White
    Write-Host "  v65       - Validation plan v65 uniquement" -ForegroundColor White
    Write-Host "  reports   - Validation rapports d'implémentation" -ForegroundColor White
    Write-Host "  links     - Validation références croisées" -ForegroundColor White
    Write-Host "  help      - Affiche cette aide" -ForegroundColor White
    Write-Host ""
    
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -Verbose  - Affiche tous les détails de validation" -ForegroundColor White
    Write-Host "  -Fix      - Tente de corriger automatiquement (WIP)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "EXEMPLES:" -ForegroundColor Green
    Write-Host "  .\validate-plans.ps1" -ForegroundColor Gray
    Write-Host "  .\validate-plans.ps1 v64 -Verbose" -ForegroundColor Gray
    Write-Host "  .\validate-plans.ps1 reports" -ForegroundColor Gray
}

# Exécution principale
try {
    Write-Host "🔍 DÉMARRAGE VALIDATION DES PLANS..." -ForegroundColor Cyan
    
    switch ($Scope.ToLower()) {
        "all" {
            Test-PlanV64
            Test-PlanV65
            Test-ImplementationReports
            Test-CrossReferences
        }
        "v64" { Test-PlanV64 }
        "v65" { Test-PlanV65 }
        "reports" { Test-ImplementationReports }
        "links" { Test-CrossReferences }
        "help" { Show-Help; return }
        default { 
            Write-Host "❌ Scope invalide: $Scope" -ForegroundColor Red
            Show-Help
            exit 1
        }
    }
    
    Show-ValidationSummary
    
} catch {
    Write-Host ""
    Write-Host "❌ ERREUR LORS DE LA VALIDATION: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "✅ Validation terminée!" -ForegroundColor Green
Write-Host ""
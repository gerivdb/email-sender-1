# ========================================
# Script de Validation Manuelle des Plans
# Phase 6.1.2 - Scripts PowerShell d'Administration  
# ========================================

param(
    [Parameter(Mandatory=$true)]
    [string]$PlanFile,
    [switch]$Interactive,
    [switch]$DetailedOutput,
    [string]$OutputPath = "./manual-validation-result.json"
)

# Configuration
$ErrorColor = "Red"
$WarningColor = "Yellow"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$PromptColor = "Magenta"

function Write-ValidationStep {
    param([string]$Step, [string]$Status = "PENDING", [string]$Details = "")
    
    $statusColor = switch ($Status) {
        "OK" { $SuccessColor }
        "FAILED" { $ErrorColor }
        "WARNING" { $WarningColor }
        "PENDING" { $InfoColor }
        default { "White" }
    }
    
    Write-Host "⏳ $Step..." -ForegroundColor Yellow -NoNewline
    if ($Status -ne "PENDING") {
        Write-Host " [$Status]" -ForegroundColor $statusColor
        if ($Details) {
            Write-Host "   └─ $Details" -ForegroundColor Gray
        }
    } else {
        Write-Host ""
    }
}

function Test-PlanMetadata {
    param([string]$Content, [string]$FileName)
    
    $results = @{
        TestName = "Vérification métadonnées"
        Status = "OK"
        Issues = @()
        Details = @()
    }
    
    # Test 1: Titre du plan
    if ($Content -notmatch "^# Plan de développement v\d+") {
        $results.Issues += "Titre du plan manquant ou malformé"
        $results.Status = "FAILED"
    } else {
        $results.Details += "Titre du plan détecté"
    }
    
    # Test 2: Progression
    $progressMatch = [regex]::Match($Content, "Progression:\s*(\d+)%")
    if ($progressMatch.Success) {
        $progression = [int]$progressMatch.Groups[1].Value
        $results.Details += "Progression déclarée: $progression%"
        
        # Vérifier cohérence avec les tâches
        $totalTasks = ([regex]::Matches($Content, "- \[[x ]\]")).Count
        $completedTasks = ([regex]::Matches($Content, "- \[x\]")).Count
        
        if ($totalTasks -gt 0) {
            $calculatedProgress = [math]::Round(($completedTasks / $totalTasks) * 100)
            $results.Details += "Progression calculée: $calculatedProgress% ($completedTasks/$totalTasks tâches)"
            
            $diff = [math]::Abs($progression - $calculatedProgress)
            if ($diff -gt 5) {
                $results.Issues += "Incohérence progression: déclarée $progression%, calculée $calculatedProgress%"
                $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
            }
        }
    } else {
        $results.Issues += "Progression non déclarée"
        $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
    }
    
    # Test 3: Date de mise à jour
    if ($Content -match "Mise à jour:\s*(.+)") {
        $results.Details += "Date de mise à jour trouvée"
    } else {
        $results.Issues += "Date de mise à jour manquante"
        $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
    }
    
    # Test 4: Objectif
    if ($Content -match "Objectif") {
        $results.Details += "Section objectif trouvée"
    } else {
        $results.Issues += "Section objectif manquante"
        $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
    }
    
    return $results
}

function Test-PlanStructure {
    param([string]$Content)
    
    $results = @{
        TestName = "Validation structure phases"
        Status = "OK"
        Issues = @()
        Details = @()
    }
    
    # Test phases
    $phaseMatches = [regex]::Matches($Content, "##\s+(Phase\s+\d+[^:]*):?")
    if ($phaseMatches.Count -eq 0) {
        $results.Issues += "Aucune phase détectée (format attendu: ## Phase X:)"
        $results.Status = "FAILED"
    } else {
        $results.Details += "Phases détectées: $($phaseMatches.Count)"
        
        # Vérifier numérotation séquentielle
        $phaseNumbers = @()
        foreach ($match in $phaseMatches) {
            if ($match.Groups[1].Value -match "Phase\s+(\d+)") {
                $phaseNumbers += [int]$matches[1]
            }
        }
        
        if ($phaseNumbers.Count -gt 0) {
            $sortedNumbers = $phaseNumbers | Sort-Object
            for ($i = 0; $i -lt $sortedNumbers.Count; $i++) {
                if ($sortedNumbers[$i] -ne ($i + 1)) {
                    $results.Issues += "Numérotation des phases non séquentielle"
                    $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
                    break
                }
            }
        }
    }
    
    # Test sous-sections
    $subsectionMatches = [regex]::Matches($Content, "###\s+(.+)")
    $results.Details += "Sous-sections détectées: $($subsectionMatches.Count)"
    
    # Test hiérarchie
    $headerLevels = [regex]::Matches($Content, "^(#{1,6})\s+(.+)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $invalidHierarchy = $false
    $lastLevel = 0
    
    foreach ($match in $headerLevels) {
        $currentLevel = $match.Groups[1].Value.Length
        if ($currentLevel - $lastLevel -gt 1) {
            $invalidHierarchy = $true
            break
        }
        $lastLevel = $currentLevel
    }
    
    if ($invalidHierarchy) {
        $results.Issues += "Hiérarchie des titres incohérente (saut de niveau détecté)"
        $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
    }
    
    return $results
}

function Test-TaskCoherence {
    param([string]$Content)
    
    $results = @{
        TestName = "Contrôle cohérence tâches"
        Status = "OK"
        Issues = @()
        Details = @()
    }
    
    # Analyse des tâches
    $totalTasks = ([regex]::Matches($Content, "- \[[x ]\]")).Count
    $completedTasks = ([regex]::Matches($Content, "- \[x\]")).Count
    $pendingTasks = $totalTasks - $completedTasks
    
    $results.Details += "Total tâches: $totalTasks"
    $results.Details += "Tâches complétées: $completedTasks"
    $results.Details += "Tâches en attente: $pendingTasks"
    
    if ($totalTasks -eq 0) {
        $results.Issues += "Aucune tâche avec checkbox détectée"
        $results.Status = "WARNING"
    } else {
        $completionRate = [math]::Round(($completedTasks / $totalTasks) * 100, 1)
        $results.Details += "Taux de completion: $completionRate%"
    }
    
    # Vérifier format des tâches
    $malformedTasks = [regex]::Matches($Content, "- \[[^x ]\]")
    if ($malformedTasks.Count -gt 0) {
        $results.Issues += "$($malformedTasks.Count) tâche(s) avec format de checkbox invalide"
        $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
    }
    
    # Vérifier tâches orphelines (pas dans une section)
    $lines = $Content -split "`n"
    $inSection = $false
    $orphanTasks = 0
    
    foreach ($line in $lines) {
        if ($line -match "^#{2,6}\s+") {
            $inSection = $true
        } elseif ($line -match "^- \[[x ]\]" -and -not $inSection) {
            $orphanTasks++
        }
    }
    
    if ($orphanTasks -gt 0) {
        $results.Issues += "$orphanTasks tâche(s) orpheline(s) (en dehors d'une section)"
        $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
    }
    
    return $results
}

function Test-Dependencies {
    param([string]$Content)
    
    $results = @{
        TestName = "Vérification dépendances"
        Status = "OK"
        Issues = @()
        Details = @()
    }
    
    # Recherche de références entre phases
    $phaseRefs = [regex]::Matches($Content, "Phase\s+(\d+)")
    $results.Details += "Références de phases trouvées: $($phaseRefs.Count)"
    
    # Recherche de liens internes
    $internalLinks = [regex]::Matches($Content, "\[([^\]]+)\]\(#([^)]+)\)")
    $results.Details += "Liens internes: $($internalLinks.Count)"
    
    # Vérifier liens cassés (ancres référencées mais non définies)
    $definedAnchors = [regex]::Matches($Content, "\{#([^}]+)\}")
    $referencedAnchors = [regex]::Matches($Content, "\]\(#([^)]+)\)")
    
    $brokenLinks = 0
    foreach ($refMatch in $referencedAnchors) {
        $refAnchor = $refMatch.Groups[1].Value
        $found = $false
        foreach ($defMatch in $definedAnchors) {
            if ($defMatch.Groups[1].Value -eq $refAnchor) {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $brokenLinks++
        }
    }
    
    if ($brokenLinks -gt 0) {
        $results.Issues += "$brokenLinks lien(s) interne(s) cassé(s)"
        $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
    }
    
    # Vérifier références externes
    $externalRefs = [regex]::Matches($Content, "`([^`]+\.md)`")
    $results.Details += "Références de fichiers externes: $($externalRefs.Count)"
    
    return $results
}

function Test-ProgressionValidation {
    param([string]$Content)
    
    $results = @{
        TestName = "Validation progression"
        Status = "OK"
        Issues = @()
        Details = @()
    }
    
    # Analyse détaillée par phase
    $phases = [regex]::Matches($Content, "##\s+Phase\s+\d+[^#]*?(?=##|\z)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    foreach ($phase in $phases) {
        $phaseContent = $phase.Value
        $phaseName = ($phaseContent -split "`n")[0] -replace "##\s*", ""
        
        $phaseTotalTasks = ([regex]::Matches($phaseContent, "- \[[x ]\]")).Count
        $phaseCompletedTasks = ([regex]::Matches($phaseContent, "- \[x\]")).Count
        
        if ($phaseTotalTasks -gt 0) {
            $phaseProgress = [math]::Round(($phaseCompletedTasks / $phaseTotalTasks) * 100, 1)
            $results.Details += "$phaseName : $phaseProgress% ($phaseCompletedTasks/$phaseTotalTasks)"
        } else {
            $results.Details += "$phaseName : Aucune tâche détectée"
        }
    }
    
    # Vérifier cohérence temporelle
    $dates = [regex]::Matches($Content, "\b(\d{1,2}\/\d{1,2}\/\d{4})\b")
    if ($dates.Count -gt 1) {
        try {
            $parsedDates = $dates | ForEach-Object { [DateTime]::ParseExact($_.Value, "dd/MM/yyyy", $null) }
            $sortedDates = $parsedDates | Sort-Object
            $results.Details += "Plage temporelle: $($sortedDates[0].ToString('dd/MM/yyyy')) - $($sortedDates[-1].ToString('dd/MM/yyyy'))"
        }
        catch {
            $results.Issues += "Format de date incohérent détecté"
            $results.Status = if ($results.Status -eq "OK") { "WARNING" } else { $results.Status }
        }
    }
    
    return $results
}

function Invoke-InteractiveValidation {
    param([array]$ValidationResults)
    
    Write-Host "`n🔍 VALIDATION INTERACTIVE" -ForegroundColor $PromptColor
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $PromptColor
    
    foreach ($result in $ValidationResults) {
        Write-Host "`n📋 $($result.TestName)" -ForegroundColor $InfoColor
        
        if ($result.Issues.Count -eq 0) {
            Write-Host "✅ Aucun problème détecté" -ForegroundColor $SuccessColor
        } else {
            Write-Host "⚠️ Problèmes détectés:" -ForegroundColor $WarningColor
            foreach ($issue in $result.Issues) {
                Write-Host "   • $issue" -ForegroundColor $ErrorColor
            }
            
            $response = Read-Host "`nSouhaitez-vous voir les détails? (o/N)"
            if ($response -eq "o" -or $response -eq "O") {
                Write-Host "`n📝 Détails:" -ForegroundColor $InfoColor
                foreach ($detail in $result.Details) {
                    Write-Host "   ℹ️ $detail" -ForegroundColor Gray
                }
            }
        }
        
        if ($result.Issues.Count -gt 0) {
            $continueResponse = Read-Host "`nContinuer la validation? (O/n)"
            if ($continueResponse -eq "n" -or $continueResponse -eq "N") {
                Write-Host "🛑 Validation interrompue par l'utilisateur" -ForegroundColor $WarningColor
                break
            }
        }
    }
}

# ========================================
# EXECUTION PRINCIPALE
# ========================================

Write-Host "🔍 VALIDATION MANUELLE DU PLAN" -ForegroundColor $InfoColor
Write-Host "📄 Fichier: $PlanFile" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

# Vérification existence du fichier
if (-not (Test-Path $PlanFile)) {
    Write-Host "❌ Fichier non trouvé: $PlanFile" -ForegroundColor $ErrorColor
    exit 1
}

# Lecture du contenu
$content = Get-Content $PlanFile -Raw
$fileInfo = Get-Item $PlanFile

Write-Host "`n📊 Informations du fichier:" -ForegroundColor $InfoColor
Write-Host "   Taille: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
Write-Host "   Dernière modification: $($fileInfo.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Gray
Write-Host "   Lignes: $(($content -split "`n").Count)" -ForegroundColor Gray

# Étapes de validation
$validationSteps = @(
    "Vérification métadonnées",
    "Validation structure phases",
    "Contrôle cohérence tâches", 
    "Vérification dépendances",
    "Validation progression"
)

$validationResults = @()
$overallStatus = "OK"

# Exécution des tests
Write-Host "`n🧪 TESTS DE VALIDATION" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

# Test 1: Métadonnées
$result1 = Test-PlanMetadata $content $fileInfo.Name
Write-ValidationStep $result1.TestName $result1.Status "$($result1.Issues.Count) problème(s), $($result1.Details.Count) détail(s)"
$validationResults += $result1
if ($result1.Status -eq "FAILED") { $overallStatus = "FAILED" }
elseif ($result1.Status -eq "WARNING" -and $overallStatus -eq "OK") { $overallStatus = "WARNING" }

# Test 2: Structure
$result2 = Test-PlanStructure $content
Write-ValidationStep $result2.TestName $result2.Status "$($result2.Issues.Count) problème(s), $($result2.Details.Count) détail(s)"
$validationResults += $result2
if ($result2.Status -eq "FAILED") { $overallStatus = "FAILED" }
elseif ($result2.Status -eq "WARNING" -and $overallStatus -eq "OK") { $overallStatus = "WARNING" }

# Test 3: Tâches
$result3 = Test-TaskCoherence $content
Write-ValidationStep $result3.TestName $result3.Status "$($result3.Issues.Count) problème(s), $($result3.Details.Count) détail(s)"
$validationResults += $result3
if ($result3.Status -eq "FAILED") { $overallStatus = "FAILED" }
elseif ($result3.Status -eq "WARNING" -and $overallStatus -eq "OK") { $overallStatus = "WARNING" }

# Test 4: Dépendances
$result4 = Test-Dependencies $content
Write-ValidationStep $result4.TestName $result4.Status "$($result4.Issues.Count) problème(s), $($result4.Details.Count) détail(s)"
$validationResults += $result4
if ($result4.Status -eq "FAILED") { $overallStatus = "FAILED" }
elseif ($result4.Status -eq "WARNING" -and $overallStatus -eq "OK") { $overallStatus = "WARNING" }

# Test 5: Progression
$result5 = Test-ProgressionValidation $content
Write-ValidationStep $result5.TestName $result5.Status "$($result5.Issues.Count) problème(s), $($result5.Details.Count) détail(s)"
$validationResults += $result5
if ($result5.Status -eq "FAILED") { $overallStatus = "FAILED" }
elseif ($result5.Status -eq "WARNING" -and $overallStatus -eq "OK") { $overallStatus = "WARNING" }

# Mode interactif
if ($Interactive) {
    Invoke-InteractiveValidation $validationResults
}

# Affichage détaillé si demandé
if ($DetailedOutput) {
    Write-Host "`n📋 RÉSULTATS DÉTAILLÉS" -ForegroundColor $InfoColor
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
    
    foreach ($result in $validationResults) {
        Write-Host "`n🔸 $($result.TestName)" -ForegroundColor $InfoColor
        
        if ($result.Details.Count -gt 0) {
            Write-Host "   📝 Détails:" -ForegroundColor Gray
            foreach ($detail in $result.Details) {
                Write-Host "      • $detail" -ForegroundColor Gray
            }
        }
        
        if ($result.Issues.Count -gt 0) {
            Write-Host "   ⚠️ Problèmes:" -ForegroundColor $WarningColor
            foreach ($issue in $result.Issues) {
                Write-Host "      • $issue" -ForegroundColor $ErrorColor
            }
        }
    }
}

# Résumé final
Write-Host "`n📊 RÉSUMÉ DE VALIDATION" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

$totalIssues = ($validationResults | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum
$testsWithIssues = ($validationResults | Where-Object { $_.Issues.Count -gt 0 }).Count

Write-Host "📄 Fichier: $($fileInfo.Name)" -ForegroundColor $InfoColor
Write-Host "🧪 Tests exécutés: $($validationResults.Count)" -ForegroundColor $InfoColor
Write-Host "⚠️ Tests avec problèmes: $testsWithIssues" -ForegroundColor $(if ($testsWithIssues -eq 0) { $SuccessColor } else { $WarningColor })
Write-Host "🚨 Total problèmes: $totalIssues" -ForegroundColor $(if ($totalIssues -eq 0) { $SuccessColor } else { $ErrorColor })

$statusColor = switch ($overallStatus) {
    "OK" { $SuccessColor }
    "WARNING" { $WarningColor }
    "FAILED" { $ErrorColor }
}
Write-Host "🎯 Statut global: $overallStatus" -ForegroundColor $statusColor

# Export JSON
$reportData = @{
    ValidationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    PlanFile = $PlanFile
    OverallStatus = $overallStatus
    TotalIssues = $totalIssues
    TestsExecuted = $validationResults.Count
    TestsWithIssues = $testsWithIssues
    Results = $validationResults
}

$reportData | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "`n💾 Rapport détaillé exporté: $OutputPath" -ForegroundColor $InfoColor

# Code de sortie
switch ($overallStatus) {
    "OK" { 
        Write-Host "`n🎉 Validation réussie!" -ForegroundColor $SuccessColor
        exit 0 
    }
    "WARNING" { 
        Write-Host "`n⚠️ Validation avec avertissements" -ForegroundColor $WarningColor
        exit 1 
    }
    "FAILED" { 
        Write-Host "`n❌ Validation échouée" -ForegroundColor $ErrorColor
        exit 2 
    }
}

#Requires -Version 5.1
<#
.SYNOPSIS
    Identifie les parties du code non couvertes par les tests.

.DESCRIPTION
    Ce script analyse le module Format-Converters et identifie les fonctions et les lignes de code
    qui ne sont pas couvertes par les tests existants.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Chemin du module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"

# Chemin des tests
$testsPath = $PSScriptRoot

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module Format-Converters n'existe pas à l'emplacement : $modulePath"
    exit 1
}

# Obtenir tous les fichiers de test réels
$testFiles = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1" | 
    Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
    ForEach-Object { $_.FullName }

# Exécuter les tests avec couverture de code
Write-Host "Analyse de la couverture de code..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $testFiles -CodeCoverage $modulePath -PassThru

# Extraire les informations de couverture
$coveredCommands = $results.CodeCoverage.HitCommands
$analyzedCommands = $results.CodeCoverage.MissedCommands + $results.CodeCoverage.HitCommands

# Identifier les fonctions dans le module
$moduleContent = Get-Content -Path $modulePath -Raw
$functionMatches = [regex]::Matches($moduleContent, 'function\s+([A-Za-z0-9\-]+)\s*{')
$functions = $functionMatches | ForEach-Object { $_.Groups[1].Value }

# Analyser la couverture par fonction
$functionCoverage = @{}
foreach ($function in $functions) {
    # Trouver les lignes de début et de fin de la fonction
    $functionPattern = "function\s+$function\s*{"
    $functionStartMatch = [regex]::Match($moduleContent, $functionPattern)
    if (-not $functionStartMatch.Success) {
        continue
    }
    
    $functionStartLine = ($moduleContent.Substring(0, $functionStartMatch.Index).Split("`n")).Length
    
    # Trouver la fin de la fonction (prochaine fonction ou fin du fichier)
    $nextFunctionMatch = [regex]::Match($moduleContent.Substring($functionStartMatch.Index + $functionStartMatch.Length), 'function\s+([A-Za-z0-9\-]+)\s*{')
    $functionEndLine = if ($nextFunctionMatch.Success) {
        $functionStartLine + ($moduleContent.Substring($functionStartMatch.Index, $nextFunctionMatch.Index + $functionStartMatch.Length).Split("`n")).Length - 1
    } else {
        ($moduleContent.Split("`n")).Length
    }
    
    # Compter les commandes couvertes et non couvertes dans cette fonction
    $functionCommands = $analyzedCommands | Where-Object { $_.Line -ge $functionStartLine -and $_.Line -le $functionEndLine }
    $functionCoveredCommands = $coveredCommands | Where-Object { $_.Line -ge $functionStartLine -and $_.Line -le $functionEndLine }
    
    $totalCommands = $functionCommands.Count
    $coveredCommandsCount = $functionCoveredCommands.Count
    $coveragePercent = if ($totalCommands -gt 0) { [math]::Round(($coveredCommandsCount / $totalCommands) * 100, 2) } else { 0 }
    
    $functionCoverage[$function] = @{
        TotalCommands = $totalCommands
        CoveredCommands = $coveredCommandsCount
        CoveragePercent = $coveragePercent
        StartLine = $functionStartLine
        EndLine = $functionEndLine
    }
}

# Trier les fonctions par couverture (de la plus basse à la plus haute)
$sortedFunctions = $functionCoverage.GetEnumerator() | Sort-Object { $_.Value.CoveragePercent }

# Afficher les résultats
Write-Host "`nRésumé de la couverture par fonction :" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$totalCoverage = [math]::Round(($results.CodeCoverage.NumberOfCommandsExecuted / $results.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2)
Write-Host "Couverture totale du module : $totalCoverage%" -ForegroundColor Yellow

Write-Host "`nFonctions avec une couverture faible (moins de 50%) :" -ForegroundColor Red
foreach ($function in $sortedFunctions) {
    if ($function.Value.CoveragePercent -lt 50) {
        Write-Host "  - $($function.Key): $($function.Value.CoveragePercent)% ($($function.Value.CoveredCommands)/$($function.Value.TotalCommands)) [Lignes $($function.Value.StartLine)-$($function.Value.EndLine)]" -ForegroundColor Red
    }
}

Write-Host "`nFonctions avec une couverture moyenne (50% à 80%) :" -ForegroundColor Yellow
foreach ($function in $sortedFunctions) {
    if ($function.Value.CoveragePercent -ge 50 -and $function.Value.CoveragePercent -lt 80) {
        Write-Host "  - $($function.Key): $($function.Value.CoveragePercent)% ($($function.Value.CoveredCommands)/$($function.Value.TotalCommands)) [Lignes $($function.Value.StartLine)-$($function.Value.EndLine)]" -ForegroundColor Yellow
    }
}

Write-Host "`nFonctions avec une bonne couverture (80% et plus) :" -ForegroundColor Green
foreach ($function in $sortedFunctions) {
    if ($function.Value.CoveragePercent -ge 80) {
        Write-Host "  - $($function.Key): $($function.Value.CoveragePercent)% ($($function.Value.CoveredCommands)/$($function.Value.TotalCommands)) [Lignes $($function.Value.StartLine)-$($function.Value.EndLine)]" -ForegroundColor Green
    }
}

# Générer un rapport détaillé des lignes non couvertes
$uncoveredLines = $results.CodeCoverage.MissedCommands | Sort-Object Line

Write-Host "`nLignes non couvertes :" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

$currentFunction = ""
foreach ($line in $uncoveredLines) {
    # Déterminer à quelle fonction appartient cette ligne
    $functionName = ($sortedFunctions | Where-Object { 
        $line.Line -ge $_.Value.StartLine -and $line.Line -le $_.Value.EndLine 
    } | Select-Object -First 1).Key
    
    if ($functionName -and $functionName -ne $currentFunction) {
        Write-Host "`nFonction: $functionName" -ForegroundColor Yellow
        $currentFunction = $functionName
    }
    
    Write-Host "  Ligne $($line.Line): $($line.Command)" -ForegroundColor Gray
}

# Suggérer des tests à ajouter
Write-Host "`nSuggestions de tests à ajouter :" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

foreach ($function in ($sortedFunctions | Where-Object { $_.Value.CoveragePercent -lt 50 })) {
    Write-Host "`nFonction: $($function.Key)" -ForegroundColor Yellow
    
    # Analyser les paramètres de la fonction
    $functionContent = $moduleContent.Split("`n")[$function.Value.StartLine..($function.Value.StartLine + 20)]
    $paramMatches = [regex]::Matches(($functionContent -join "`n"), '\[Parameter.*?\]\s*\[([^\]]+)\]\$([A-Za-z0-9_]+)')
    
    Write-Host "  Créer un test qui vérifie :" -ForegroundColor White
    Write-Host "    - Le comportement normal de la fonction" -ForegroundColor White
    
    if ($paramMatches.Count -gt 0) {
        Write-Host "    - Les cas limites pour les paramètres suivants :" -ForegroundColor White
        foreach ($param in $paramMatches) {
            $paramType = $param.Groups[1].Value
            $paramName = $param.Groups[2].Value
            Write-Host "      * $paramName ($paramType)" -ForegroundColor White
        }
    }
    
    # Vérifier s'il y a des conditions ou des boucles non couvertes
    $ifMatches = [regex]::Matches(($functionContent -join "`n"), 'if\s*\(([^)]+)\)')
    if ($ifMatches.Count -gt 0) {
        Write-Host "    - Les branches conditionnelles suivantes :" -ForegroundColor White
        foreach ($ifMatch in $ifMatches) {
            $condition = $ifMatch.Groups[1].Value
            Write-Host "      * $condition" -ForegroundColor White
        }
    }
}

Write-Host "`nPour améliorer rapidement la couverture, concentrez-vous d'abord sur les fonctions avec le plus grand nombre de commandes non couvertes." -ForegroundColor Cyan

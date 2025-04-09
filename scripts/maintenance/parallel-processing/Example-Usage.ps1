<#
.SYNOPSIS
    Exemple d'utilisation du module ParallelProcessing.
.DESCRIPTION
    Ce script montre comment utiliser le module ParallelProcessing pour analyser
    et corriger des scripts PowerShell en parallèle.
.EXAMPLE
    .\Example-Usage.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Compatibilité: PowerShell 5.1 et supérieur
#>

# Importer le module
Import-Module "$PSScriptRoot\ParallelProcessing.psd1" -Force

# Définir le répertoire à analyser
$scriptsDir = "C:\Scripts" # Remplacer par le chemin réel des scripts à analyser

# Vérifier si le répertoire existe
if (-not (Test-Path -Path $scriptsDir)) {
    Write-Error "Le répertoire $scriptsDir n'existe pas."
    exit 1
}

# Obtenir tous les scripts PowerShell dans le répertoire
$scriptFiles = Get-ChildItem -Path $scriptsDir -Filter "*.ps1" -Recurse | Select-Object -ExpandProperty FullName

if ($scriptFiles.Count -eq 0) {
    Write-Warning "Aucun script PowerShell trouvé dans le répertoire $scriptsDir."
    exit 0
}

Write-Host "Analyse de $($scriptFiles.Count) scripts PowerShell..."

# Exemple 1: Analyser les scripts en parallèle
Write-Host "`n--- Exemple 1: Analyse parallèle ---"
$analysisResults = $scriptFiles | Invoke-ParallelScriptAnalysis -MaxThreads 8

# Afficher les détails des problèmes pour le premier script avec des problèmes
$scriptWithIssues = $analysisResults | Where-Object { $_.IssueCount -gt 0 } | Select-Object -First 1

if ($null -ne $scriptWithIssues) {
    Write-Host "`nDétails des problèmes pour $($scriptWithIssues.ScriptPath):"
    $scriptWithIssues.Issues | Format-Table -Property Name, LineNumber, Description
}

# Exemple 2: Corriger les scripts en parallèle (simulation)
Write-Host "`n--- Exemple 2: Correction parallèle (simulation) ---"
$correctionResults = $scriptFiles | Invoke-ParallelScriptCorrection -MaxThreads 8 -WhatIf

# Afficher les statistiques des corrections
Write-Host "`nStatistiques des corrections (simulation):"
Write-Host "  Scripts traités: $($correctionResults.Count)"
Write-Host "  Problèmes détectés: $(($correctionResults | Measure-Object -Property IssuesFound -Sum).Sum)"
Write-Host "  Corrections potentielles: $(($correctionResults | Measure-Object -Property CorrectionsMade -Sum).Sum)"

# Exemple 3: Utilisation directe de Invoke-OptimizedParallel
Write-Host "`n--- Exemple 3: Utilisation directe de Invoke-OptimizedParallel ---"
$customResults = $scriptFiles | Invoke-OptimizedParallel -ScriptBlock {
    param($scriptPath)

    try {
        # Lire le contenu du script
        $content = Get-Content -Path $scriptPath -Raw -ErrorAction Stop

        # Effectuer une analyse personnalisée
        $functionCount = ([regex]::Matches($content, 'function\s+\w+')).Count
        $commentCount = ([regex]::Matches($content, '^\s*#.*$', 'Multiline')).Count
        $lineCount = ($content -split "`n").Length

        return [PSCustomObject]@{
            ScriptPath = $scriptPath
            FunctionCount = $functionCount
            CommentCount = $commentCount
            LineCount = $lineCount
            CommentRatio = [math]::Round(($commentCount / $lineCount) * 100, 2)
        }
    }
    catch {
        return [PSCustomObject]@{
            ScriptPath = $scriptPath
            Error = $_.Exception.Message
        }
    }
} -MaxThreads 8

# Afficher les statistiques des scripts
Write-Host "`nStatistiques des scripts:"
$customResults | Sort-Object -Property CommentRatio -Descending | Select-Object -First 5 |
    Format-Table -Property @{
        Label = "Script"
        Expression = { Split-Path -Leaf $_.ScriptPath }
    }, FunctionCount, CommentCount, LineCount, @{
        Label = "Comment Ratio (%)"
        Expression = { $_.CommentRatio }
    }

Write-Host "`nExemple d'utilisation terminé."

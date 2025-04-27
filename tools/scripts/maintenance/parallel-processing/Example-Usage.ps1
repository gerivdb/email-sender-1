<#
.SYNOPSIS
    Exemple d'utilisation du module ParallelProcessing.
.DESCRIPTION
    Ce script montre comment utiliser le module ParallelProcessing pour analyser
    et corriger des scripts PowerShell en parallÃ¨le.
.EXAMPLE
    .\Example-Usage.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur
#>

# Importer le module
Import-Module "$PSScriptRoot\ParallelProcessing.psd1" -Force

# DÃ©finir le rÃ©pertoire Ã  analyser
$scriptsDir = "C:\Scripts" # Remplacer par le chemin rÃ©el des scripts Ã  analyser

# VÃ©rifier si le rÃ©pertoire existe
if (-not (Test-Path -Path $scriptsDir)) {
    Write-Error "Le rÃ©pertoire $scriptsDir n'existe pas."
    exit 1
}

# Obtenir tous les scripts PowerShell dans le rÃ©pertoire
$scriptFiles = Get-ChildItem -Path $scriptsDir -Filter "*.ps1" -Recurse | Select-Object -ExpandProperty FullName

if ($scriptFiles.Count -eq 0) {
    Write-Warning "Aucun script PowerShell trouvÃ© dans le rÃ©pertoire $scriptsDir."
    exit 0
}

Write-Host "Analyse de $($scriptFiles.Count) scripts PowerShell..."

# Exemple 1: Analyser les scripts en parallÃ¨le
Write-Host "`n--- Exemple 1: Analyse parallÃ¨le ---"
$analysisResults = $scriptFiles | Invoke-ParallelScriptAnalysis -MaxThreads 8

# Afficher les dÃ©tails des problÃ¨mes pour le premier script avec des problÃ¨mes
$scriptWithIssues = $analysisResults | Where-Object { $_.IssueCount -gt 0 } | Select-Object -First 1

if ($null -ne $scriptWithIssues) {
    Write-Host "`nDÃ©tails des problÃ¨mes pour $($scriptWithIssues.ScriptPath):"
    $scriptWithIssues.Issues | Format-Table -Property Name, LineNumber, Description
}

# Exemple 2: Corriger les scripts en parallÃ¨le (simulation)
Write-Host "`n--- Exemple 2: Correction parallÃ¨le (simulation) ---"
$correctionResults = $scriptFiles | Invoke-ParallelScriptCorrection -MaxThreads 8 -WhatIf

# Afficher les statistiques des corrections
Write-Host "`nStatistiques des corrections (simulation):"
Write-Host "  Scripts traitÃ©s: $($correctionResults.Count)"
Write-Host "  ProblÃ¨mes dÃ©tectÃ©s: $(($correctionResults | Measure-Object -Property IssuesFound -Sum).Sum)"
Write-Host "  Corrections potentielles: $(($correctionResults | Measure-Object -Property CorrectionsMade -Sum).Sum)"

# Exemple 3: Utilisation directe de Invoke-OptimizedParallel
Write-Host "`n--- Exemple 3: Utilisation directe de Invoke-OptimizedParallel ---"
$customResults = $scriptFiles | Invoke-OptimizedParallel -ScriptBlock {
    param($scriptPath)

    try {
        # Lire le contenu du script
        $content = Get-Content -Path $scriptPath -Raw -ErrorAction Stop

        # Effectuer une analyse personnalisÃ©e
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

Write-Host "`nExemple d'utilisation terminÃ©."

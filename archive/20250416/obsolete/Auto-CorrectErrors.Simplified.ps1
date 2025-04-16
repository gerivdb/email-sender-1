<#
.SYNOPSIS
    Version simplifiée du script pour automatiser intelligemment les corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script utilise la base de connaissances des erreurs pour suggérer et appliquer
    automatiquement des corrections aux scripts PowerShell problématiques.
.PARAMETER ScriptPath
    Chemin du script à analyser et corriger.
.PARAMETER ApplyCorrections
    Si spécifié, applique automatiquement les corrections suggérées.
.EXAMPLE
    .\Auto-CorrectErrors.Simplified.ps1 -ScriptPath "C:\Scripts\MonScript.ps1"
    Analyse le script et suggère des corrections.
.EXAMPLE
    .\Auto-CorrectErrors.Simplified.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -ApplyCorrections
    Analyse le script et applique automatiquement les corrections suggérées.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $false)]
    [switch]$ApplyCorrections
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Vérifier si le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script spécifié n'existe pas : $ScriptPath"
    exit 1
}

# Lire le contenu du script
$scriptContent = Get-Content -Path $ScriptPath -Raw
$scriptLines = Get-Content -Path $ScriptPath

# Définir les patterns d'erreurs courantes
$errorPatterns = @(
    @{
        Name = "HardcodedPath"
        Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
        Description = "Chemin codé en dur détecté"
        Correction = {
            param($Line)
            $Line -replace '(?<!\\)["'']([A-Z]:\\|\\\\)[^"'']*["'']', '(Join-Path -Path $PSScriptRoot -ChildPath "CHEMIN_RELATIF")'
        }
    },
    @{
        Name = "NoErrorHandling"
        Pattern = '(?<!try\s*\{\s*)(?:Get-Content|Set-Content)(?!\s*-ErrorAction)'
        Description = "Absence de gestion d'erreurs détecté"
        Correction = {
            param($Line)
            $Line -replace '(Get-Content|Set-Content)(?!\s*-ErrorAction)', '$1 -ErrorAction Stop'
        }
    },
    @{
        Name = "WriteHostUsage"
        Pattern = 'Write-Host'
        Description = "Utilisation de Write-Host détecté"
        Correction = {
            param($Line)
            $Line -replace 'Write-Host', 'Write-Output'
        }
    },
    @{
        Name = "ObsoleteCmdlet"
        Pattern = '(Get-WmiObject|Invoke-Expression)'
        Description = "Utilisation de cmdlets obsolètes détecté"
        Correction = {
            param($Line)
            $Line -replace 'Get-WmiObject', 'Get-CimInstance'
        }
    }
)

# Pré-compiler les expressions régulières pour de meilleures performances
$compiledPatterns = @()
foreach ($pattern in $errorPatterns) {
    $compiledPatterns += @{
        Name = $pattern.Name
        Regex = [regex]::new($pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
        Description = $pattern.Description
        Correction = $pattern.Correction
    }
}

# Analyser le script
$detectedIssues = @()

# Préparer les lignes une seule fois
$lines = $scriptContent.Split("`n")

# Analyser chaque pattern
foreach ($pattern in $compiledPatterns) {
    $regexMatches = $pattern.Regex.Matches($scriptContent)

    # Traiter les correspondances par lots pour améliorer les performances
    if ($regexMatches.Count -gt 0) {
        foreach ($match in $regexMatches) {
            # Trouver le numéro de ligne
            $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length

            # Extraire la ligne complète
            $line = $lines[$lineNumber - 1].Trim()

            # Créer un objet pour l'erreur détectée
            $issue = [PSCustomObject]@{
                Name = $pattern.Name
                Description = $pattern.Description
                LineNumber = $lineNumber
                Line = $line
                Match = $match.Value
                Correction = $pattern.Correction
            }

            $detectedIssues += $issue
        }
    }
}

# Afficher les résultats
Write-Host "Analyse du script : $ScriptPath"
Write-Host "Erreurs détectées : $($detectedIssues.Count)"

if ($detectedIssues.Count -gt 0) {
    Write-Host "`nDétails des erreurs :"

    foreach ($issue in $detectedIssues) {
        Write-Host "`n[$($issue.Name)] Ligne $($issue.LineNumber)"
        Write-Host "  Message : $($issue.Description)"
        Write-Host "  Ligne : $($issue.Line)"
    }
}
else {
    Write-Host "`nAucune erreur détectée."
}

# Appliquer les corrections si demandé
if ($ApplyCorrections -and $detectedIssues.Count -gt 0) {
    Write-Host "`nApplication des corrections..."

    # Trier les problèmes par numéro de ligne (décroissant) pour éviter les décalages
    $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending

    # Créer une sauvegarde du script original
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force

    # Optimisation : Regrouper les corrections par ligne pour éviter les modifications redondantes
    $lineCorrections = @{}

    foreach ($issue in $sortedIssues) {
        $lineIndex = $issue.LineNumber - 1

        if (-not $lineCorrections.ContainsKey($lineIndex)) {
            $lineCorrections[$lineIndex] = @{
                OriginalLine = $scriptLines[$lineIndex]
                Issues = @()
            }
        }

        $lineCorrections[$lineIndex].Issues += $issue
    }

    # Appliquer les corrections par ligne
    $correctionsApplied = 0

    foreach ($lineIndex in $lineCorrections.Keys | Sort-Object -Descending) {
        $correction = $lineCorrections[$lineIndex]
        $currentLine = $correction.OriginalLine

        # Appliquer toutes les corrections pour cette ligne
        foreach ($issue in $correction.Issues) {
            try {
                $currentLine = & $issue.Correction $currentLine
                $correctionsApplied++
            }
            catch {
                Write-Warning "Impossible d'appliquer une correction pour l'erreur à la ligne $($issue.LineNumber) : $($issue.Description)"
            }
        }

        # Mettre à jour la ligne dans le script
        $scriptLines[$lineIndex] = $currentLine
    }

    # Sauvegarder le script corrigé en une seule opération
    $scriptLines | Out-File -FilePath $ScriptPath -Force -Encoding UTF8

    Write-Host "Corrections appliquées : $correctionsApplied"
    Write-Host "Sauvegarde créée : $backupPath"
}

Write-Host "`nAnalyse terminée."

<#
.SYNOPSIS
    Version simplifiée du script pour analyser un script PowerShell et détecter les erreurs potentielles.
.DESCRIPTION
    Ce script analyse un script PowerShell pour détecter les erreurs potentielles
    en utilisant des patterns connus et des règles d'analyse statique.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $false)]
    [switch]$FixErrors,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ""
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

# Définir les patterns d'erreurs courantes
$errorPatterns = @(
    @{
        Name = "HardcodedPath"
        Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
        Description = "Chemin codé en dur détecté"
        Suggestion = "Utiliser des chemins relatifs ou des variables d'environnement."
        Severity = "Warning"
    },
    @{
        Name = "UndeclaredVariable"
        Pattern = '\$[a-zA-Z0-9_]+\s*='
        Description = "Variable non déclarée détecté"
        Suggestion = "Déclarer les variables avec [string], [int], etc. ou utiliser 'Set-StrictMode -Version Latest'."
        Severity = "Warning"
    },
    @{
        Name = "NoErrorHandling"
        Pattern = '(?<!try\s*\{\s*)(?:Get-Content|Set-Content)(?!\s*-ErrorAction)'
        Description = "Absence de gestion d'erreurs détecté"
        Suggestion = "Ajouter un bloc try/catch ou utiliser le paramètre -ErrorAction."
        Severity = "Warning"
    },
    @{
        Name = "WriteHostUsage"
        Pattern = 'Write-Host'
        Description = "Utilisation de Write-Host détecté"
        Suggestion = "Utiliser Write-Output pour les données, Write-Verbose pour les informations de débogage, Write-Warning pour les avertissements."
        Severity = "Information"
    },
    @{
        Name = "ObsoleteCmdlet"
        Pattern = '(Get-WmiObject|Invoke-Expression)'
        Description = "Utilisation de cmdlets obsolètes détecté"
        Suggestion = "Remplacer Get-WmiObject par Get-CimInstance, éviter Invoke-Expression si possible."
        Severity = "Warning"
    }
)

# Pré-compiler les expressions régulières pour de meilleures performances
$compiledPatterns = @()
foreach ($pattern in $errorPatterns) {
    $compiledPatterns += @{
        Name = $pattern.Name
        Regex = [regex]::new($pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
        Description = $pattern.Description
        Suggestion = $pattern.Suggestion
        Severity = $pattern.Severity
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
                Suggestion = $pattern.Suggestion
                Severity = $pattern.Severity
                LineNumber = $lineNumber
                Line = $line
                Match = $match.Value
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
        Write-Host "`n[$($issue.Severity)] $($issue.Name) (Ligne $($issue.LineNumber))"
        Write-Host "  Message : $($issue.Description)"
        Write-Host "  Ligne : $($issue.Line)"
        Write-Host "  Suggestions de correction :"
    }
}
else {
    Write-Host "`nAucune erreur détectée."
}

# Corriger les erreurs si demandé
if ($FixErrors) {
    Write-Host "`nApplication des corrections..."

    # Trier les problèmes par numéro de ligne (décroissant) pour éviter les décalages
    $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending

    # Lire le contenu du script en tant que tableau de lignes
    $scriptLines = Get-Content -Path $ScriptPath

    # Créer une sauvegarde du script original
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force

    # Appliquer les corrections
    $correctionsApplied = 0

    foreach ($issue in $sortedIssues) {
        $lineIndex = $issue.LineNumber - 1
        $originalLine = $scriptLines[$lineIndex]

        # Appliquer la correction en fonction du type de problème
        switch ($issue.Name) {
            "HardcodedPath" {
                # Remplacer les chemins codés en dur par des variables
                $newLine = $originalLine -replace '(?<!\\)["'']([A-Z]:\\|\\\\)[^"'']*["'']', '(Join-Path -Path $PSScriptRoot -ChildPath "CHEMIN_RELATIF")'
                $scriptLines[$lineIndex] = $newLine
                $correctionsApplied++
            }
            "NoErrorHandling" {
                # Ajouter -ErrorAction Stop
                $newLine = $originalLine -replace '(Get-Content|Set-Content)(?!\s*-ErrorAction)', '$1 -ErrorAction Stop'
                $scriptLines[$lineIndex] = $newLine
                $correctionsApplied++
            }
            "WriteHostUsage" {
                # Remplacer Write-Host par Write-Output
                $newLine = $originalLine -replace 'Write-Host', 'Write-Output'
                $scriptLines[$lineIndex] = $newLine
                $correctionsApplied++
            }
            "ObsoleteCmdlet" {
                # Remplacer les cmdlets obsolètes
                $newLine = $originalLine -replace 'Get-WmiObject', 'Get-CimInstance'
                $scriptLines[$lineIndex] = $newLine
                $correctionsApplied++
            }
            default {
                Write-Warning "Impossible d'appliquer une correction pour l'erreur à la ligne $($issue.LineNumber) : $($issue.Description)"
            }
        }
    }

    # Sauvegarder le script corrigé
    $scriptLines | Out-File -FilePath $ScriptPath -Force

    Write-Host "Corrections appliquées : $correctionsApplied"
    Write-Host "Sauvegarde créée : $backupPath"
}

Write-Host "`nAnalyse terminée."

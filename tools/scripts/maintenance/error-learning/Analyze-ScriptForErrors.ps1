<#
.SYNOPSIS
    Script pour analyser un script PowerShell et détecter les erreurs potentielles.
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
        Name = "Chemin codé en dur"
        Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
        Description = "Utilisation de chemins codés en dur, ce qui peut causer des problèmes de compatibilité."
        Suggestion = "Utiliser des chemins relatifs ou des variables d'environnement."
        Severity = "Warning"
    },
    @{
        Name = "Variable non déclarée"
        Pattern = '\$[a-zA-Z0-9_]+\s*='
        Description = "Utilisation de variables sans déclaration préalable."
        Suggestion = "Déclarer les variables avec [string], [int], etc. ou utiliser 'Set-StrictMode -Version Latest'."
        Severity = "Warning"
    },
    @{
        Name = "Absence de gestion d'erreurs"
        Pattern = '(?<!try\s*\{\s*)(?:Invoke-RestMethod|Invoke-WebRequest|New-Item|Remove-Item|Copy-Item|Move-Item|Get-Content|Set-Content)(?!\s*-ErrorAction)'
        Description = "Appel de cmdlet sans gestion d'erreurs explicite."
        Suggestion = "Ajouter un bloc try/catch ou utiliser le paramètre -ErrorAction."
        Severity = "Warning"
    },
    @{
        Name = "Utilisation de Write-Host"
        Pattern = 'Write-Host'
        Description = "Utilisation de Write-Host au lieu de Write-Output, Write-Verbose, etc."
        Suggestion = "Utiliser Write-Output pour les données, Write-Verbose pour les informations de débogage, Write-Warning pour les avertissements."
        Severity = "Information"
    },
    @{
        Name = "Absence de commentaires"
        Pattern = '^(?:\s*#.*\r?\n){0,3}function\s+[a-zA-Z0-9_-]+\s*\{'
        Description = "Fonction sans commentaires ou avec peu de commentaires."
        Suggestion = "Ajouter des commentaires de type .SYNOPSIS, .DESCRIPTION, .PARAMETER, etc."
        Severity = "Information"
    },
    @{
        Name = "Utilisation de cmdlets obsolètes"
        Pattern = '(Get-WmiObject|Invoke-Expression)'
        Description = "Utilisation de cmdlets obsolètes ou dangereuses."
        Suggestion = "Remplacer Get-WmiObject par Get-CimInstance, éviter Invoke-Expression si possible."
        Severity = "Warning"
    }
)

# Analyser le script
$detectedIssues = @()

foreach ($pattern in $errorPatterns) {
    $matches = [regex]::Matches($scriptContent, $pattern.Pattern)
    
    foreach ($match in $matches) {
        # Trouver le numéro de ligne
        $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length
        
        # Extraire la ligne complète
        $lines = $scriptContent.Split("`n")
        $line = $lines[$lineNumber - 1].Trim()
        
        # Créer un objet pour l'erreur détectée
        $issue = @{
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

# Afficher les résultats
Write-Host "Analyse du script : $ScriptPath"
Write-Host "Problèmes potentiels détectés : $($detectedIssues.Count)"

if ($detectedIssues.Count -gt 0) {
    Write-Host "`nDétails des problèmes :"
    
    foreach ($issue in $detectedIssues) {
        Write-Host "`n[$($issue.Severity)] $($issue.Name) (Ligne $($issue.LineNumber))"
        Write-Host "  Description : $($issue.Description)"
        Write-Host "  Suggestion : $($issue.Suggestion)"
        Write-Host "  Code : $($issue.Line)"
    }
}
else {
    Write-Host "`nAucun problème potentiel détecté."
}

# Générer un rapport si demandé
if ($GenerateReport) {
    $reportContent = @"
# Rapport d'analyse de script
- **Script** : $ScriptPath
- **Date d'analyse** : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Problèmes détectés** : $($detectedIssues.Count)

## Détails des problèmes

"@

    foreach ($issue in $detectedIssues) {
        $reportContent += @"

### [$($issue.Severity)] $($issue.Name) (Ligne $($issue.LineNumber))
- **Description** : $($issue.Description)
- **Suggestion** : $($issue.Suggestion)
- **Code** : ``$($issue.Line)``

"@
    }

    if (-not $ReportPath) {
        $ReportPath = [System.IO.Path]::ChangeExtension($ScriptPath, "report.md")
    }

    $reportContent | Out-File -FilePath $ReportPath -Encoding utf8
    Write-Host "`nRapport généré : $ReportPath"
}

# Corriger les erreurs si demandé
if ($FixErrors) {
    Write-Host "`nCorrection des erreurs..."
    
    # Trier les problèmes par numéro de ligne (décroissant) pour éviter les décalages
    $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending
    
    # Lire le contenu du script en tant que tableau de lignes
    $scriptLines = Get-Content -Path $ScriptPath
    
    # Appliquer les corrections
    foreach ($issue in $sortedIssues) {
        $lineIndex = $issue.LineNumber - 1
        $originalLine = $scriptLines[$lineIndex]
        
        # Appliquer la correction en fonction du type de problème
        switch ($issue.Name) {
            "Chemin codé en dur" {
                # Remplacer les chemins codés en dur par des variables
                $newLine = $originalLine -replace '(?<!\\)["'']([A-Z]:\\|\\\\)[^"'']*["'']', '(Join-Path -Path $PSScriptRoot -ChildPath "CHEMIN_RELATIF")'
                $scriptLines[$lineIndex] = $newLine
            }
            "Absence de gestion d'erreurs" {
                # Ajouter -ErrorAction Stop
                $newLine = $originalLine -replace '(Invoke-RestMethod|Invoke-WebRequest|New-Item|Remove-Item|Copy-Item|Move-Item|Get-Content|Set-Content)(?!\s*-ErrorAction)', '$1 -ErrorAction Stop'
                $scriptLines[$lineIndex] = $newLine
            }
            "Utilisation de Write-Host" {
                # Remplacer Write-Host par Write-Output
                $newLine = $originalLine -replace 'Write-Host', 'Write-Output'
                $scriptLines[$lineIndex] = $newLine
            }
            "Utilisation de cmdlets obsolètes" {
                # Remplacer les cmdlets obsolètes
                $newLine = $originalLine -replace 'Get-WmiObject', 'Get-CimInstance'
                $scriptLines[$lineIndex] = $newLine
            }
            default {
                # Ajouter un commentaire pour les autres problèmes
                $scriptLines[$lineIndex] = "$originalLine # TODO: $($issue.Suggestion)"
            }
        }
        
        Write-Host "Ligne $($issue.LineNumber) corrigée : $($issue.Name)"
    }
    
    # Sauvegarder le script corrigé
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force
    $scriptLines | Out-File -FilePath $ScriptPath -Encoding utf8
    
    Write-Host "`nScript corrigé. Sauvegarde créée : $backupPath"
}

Write-Host "`nAnalyse terminée."

<#
.SYNOPSIS
    Script pour analyser un script PowerShell et dÃ©tecter les erreurs potentielles.
.DESCRIPTION
    Ce script analyse un script PowerShell pour dÃ©tecter les erreurs potentielles
    en utilisant des patterns connus et des rÃ¨gles d'analyse statique.
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

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script spÃ©cifiÃ© n'existe pas : $ScriptPath"
    exit 1
}

# Lire le contenu du script
$scriptContent = Get-Content -Path $ScriptPath -Raw

# DÃ©finir les patterns d'erreurs courantes
$errorPatterns = @(
    @{
        Name = "Chemin codÃ© en dur"
        Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
        Description = "Utilisation de chemins codÃ©s en dur, ce qui peut causer des problÃ¨mes de compatibilitÃ©."
        Suggestion = "Utiliser des chemins relatifs ou des variables d'environnement."
        Severity = "Warning"
    },
    @{
        Name = "Variable non dÃ©clarÃ©e"
        Pattern = '\$[a-zA-Z0-9_]+\s*='
        Description = "Utilisation de variables sans dÃ©claration prÃ©alable."
        Suggestion = "DÃ©clarer les variables avec [string], [int], etc. ou utiliser 'Set-StrictMode -Version Latest'."
        Severity = "Warning"
    },
    @{
        Name = "Absence de gestion d'erreurs"
        Pattern = '(?<!try\s*\{\s*)(?:Invoke-RestMethod|Invoke-WebRequest|New-Item|Remove-Item|Copy-Item|Move-Item|Get-Content|Set-Content)(?!\s*-ErrorAction)'
        Description = "Appel de cmdlet sans gestion d'erreurs explicite."
        Suggestion = "Ajouter un bloc try/catch ou utiliser le paramÃ¨tre -ErrorAction."
        Severity = "Warning"
    },
    @{
        Name = "Utilisation de Write-Host"
        Pattern = 'Write-Host'
        Description = "Utilisation de Write-Host au lieu de Write-Output, Write-Verbose, etc."
        Suggestion = "Utiliser Write-Output pour les donnÃ©es, Write-Verbose pour les informations de dÃ©bogage, Write-Warning pour les avertissements."
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
        Name = "Utilisation de cmdlets obsolÃ¨tes"
        Pattern = '(Get-WmiObject|Invoke-Expression)'
        Description = "Utilisation de cmdlets obsolÃ¨tes ou dangereuses."
        Suggestion = "Remplacer Get-WmiObject par Get-CimInstance, Ã©viter Invoke-Expression si possible."
        Severity = "Warning"
    }
)

# Analyser le script
$detectedIssues = @()

foreach ($pattern in $errorPatterns) {
    $matches = [regex]::Matches($scriptContent, $pattern.Pattern)
    
    foreach ($match in $matches) {
        # Trouver le numÃ©ro de ligne
        $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length
        
        # Extraire la ligne complÃ¨te
        $lines = $scriptContent.Split("`n")
        $line = $lines[$lineNumber - 1].Trim()
        
        # CrÃ©er un objet pour l'erreur dÃ©tectÃ©e
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

# Afficher les rÃ©sultats
Write-Host "Analyse du script : $ScriptPath"
Write-Host "ProblÃ¨mes potentiels dÃ©tectÃ©s : $($detectedIssues.Count)"

if ($detectedIssues.Count -gt 0) {
    Write-Host "`nDÃ©tails des problÃ¨mes :"
    
    foreach ($issue in $detectedIssues) {
        Write-Host "`n[$($issue.Severity)] $($issue.Name) (Ligne $($issue.LineNumber))"
        Write-Host "  Description : $($issue.Description)"
        Write-Host "  Suggestion : $($issue.Suggestion)"
        Write-Host "  Code : $($issue.Line)"
    }
}
else {
    Write-Host "`nAucun problÃ¨me potentiel dÃ©tectÃ©."
}

# GÃ©nÃ©rer un rapport si demandÃ©
if ($GenerateReport) {
    $reportContent = @"
# Rapport d'analyse de script
- **Script** : $ScriptPath
- **Date d'analyse** : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **ProblÃ¨mes dÃ©tectÃ©s** : $($detectedIssues.Count)

## DÃ©tails des problÃ¨mes

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
    Write-Host "`nRapport gÃ©nÃ©rÃ© : $ReportPath"
}

# Corriger les erreurs si demandÃ©
if ($FixErrors) {
    Write-Host "`nCorrection des erreurs..."
    
    # Trier les problÃ¨mes par numÃ©ro de ligne (dÃ©croissant) pour Ã©viter les dÃ©calages
    $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending
    
    # Lire le contenu du script en tant que tableau de lignes
    $scriptLines = Get-Content -Path $ScriptPath
    
    # Appliquer les corrections
    foreach ($issue in $sortedIssues) {
        $lineIndex = $issue.LineNumber - 1
        $originalLine = $scriptLines[$lineIndex]
        
        # Appliquer la correction en fonction du type de problÃ¨me
        switch ($issue.Name) {
            "Chemin codÃ© en dur" {
                # Remplacer les chemins codÃ©s en dur par des variables
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
            "Utilisation de cmdlets obsolÃ¨tes" {
                # Remplacer les cmdlets obsolÃ¨tes
                $newLine = $originalLine -replace 'Get-WmiObject', 'Get-CimInstance'
                $scriptLines[$lineIndex] = $newLine
            }
            default {
                # Ajouter un commentaire pour les autres problÃ¨mes
                $scriptLines[$lineIndex] = "$originalLine # TODO: $($issue.Suggestion)"
            }
        }
        
        Write-Host "Ligne $($issue.LineNumber) corrigÃ©e : $($issue.Name)"
    }
    
    # Sauvegarder le script corrigÃ©
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force
    $scriptLines | Out-File -FilePath $ScriptPath -Encoding utf8
    
    Write-Host "`nScript corrigÃ©. Sauvegarde crÃ©Ã©e : $backupPath"
}

Write-Host "`nAnalyse terminÃ©e."

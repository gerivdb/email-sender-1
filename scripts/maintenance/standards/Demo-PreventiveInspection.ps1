#Requires -Version 5.1
<#
.SYNOPSIS
    Démontre l'utilisation du script Inspect-ScriptPreventively.ps1.
.DESCRIPTION
    Ce script montre comment utiliser Inspect-ScriptPreventively.ps1 dans un flux
    de travail de développement pour détecter et corriger les problèmes dans les
    scripts PowerShell.
.EXAMPLE
    .\Demo-PreventiveInspection.ps1
    Exécute la démonstration avec les paramètres par défaut.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Chemin du script d'inspection
$inspectScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Inspect-ScriptPreventively.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $inspectScriptPath)) {
    throw "Le script d'inspection n'existe pas: $inspectScriptPath"
}

# Créer un répertoire temporaire pour la démonstration
$demoDir = Join-Path -Path $env:TEMP -ChildPath "PreventiveInspectionDemo"
if (-not (Test-Path -Path $demoDir)) {
    New-Item -Path $demoDir -ItemType Directory -Force | Out-Null
}

# Créer des scripts de démonstration avec différents problèmes
$scripts = @{
    "NullComparison.ps1" = @'
function Test-NullComparison {
    param($value)
    
    if ($value -eq $null) {
        return $true
    }
    
    return $false
}
'@
    "UnusedVariable.ps1" = @'
function Test-UnusedVariable {
    # Variable non utilisée
    $unused = "Cette variable n'est jamais utilisée"
    
    # Variable utilisée
    $used = "Cette variable est utilisée"
    return $used
}
'@
    "WriteHost.ps1" = @'
function Test-WriteHost {
    param($message)
    
    # Utilisation de Write-Host
    Write-Host "Message: $message" -ForegroundColor Green
    
    return "Message traité: $message"
}
'@
    "PluralNoun.ps1" = @'
function Get-Users {
    # Fonction avec un nom pluriel
    return @("User1", "User2", "User3")
}
'@
    "SwitchDefaultValue.ps1" = @'
function Test-SwitchDefault {
    param(
        [switch]$Force = $true,
        [switch]$Verbose = $true
    )
    
    # Faire quelque chose
    return "Force: $Force, Verbose: $Verbose"
}
'@
}

# Créer les scripts de démonstration
foreach ($script in $scripts.Keys) {
    $scriptPath = Join-Path -Path $demoDir -ChildPath $script
    Set-Content -Path $scriptPath -Value $scripts[$script] -Force
    Write-Host "Script créé: $scriptPath" -ForegroundColor Green
}

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)
    
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# Démonstration 1: Analyser un script spécifique
Show-SectionTitle "Démonstration 1: Analyser un script spécifique"
$scriptPath = Join-Path -Path $demoDir -ChildPath "NullComparison.ps1"
Write-Host "Analyse du script: $scriptPath" -ForegroundColor Yellow
& $inspectScriptPath -Path $scriptPath

# Démonstration 2: Analyser et corriger un script
Show-SectionTitle "Démonstration 2: Analyser et corriger un script"
$scriptPath = Join-Path -Path $demoDir -ChildPath "UnusedVariable.ps1"
Write-Host "Contenu original:" -ForegroundColor Yellow
Get-Content -Path $scriptPath | ForEach-Object { Write-Host "  $_" }

Write-Host "`nAnalyse et correction du script..." -ForegroundColor Yellow
& $inspectScriptPath -Path $scriptPath -Fix

Write-Host "`nContenu corrigé:" -ForegroundColor Yellow
Get-Content -Path $scriptPath | ForEach-Object { Write-Host "  $_" }

# Démonstration 3: Analyser tous les scripts dans un dossier
Show-SectionTitle "Démonstration 3: Analyser tous les scripts dans un dossier"
Write-Host "Analyse de tous les scripts dans: $demoDir" -ForegroundColor Yellow
$results = & $inspectScriptPath -Path $demoDir -Recurse

# Afficher un résumé des résultats
$summary = $results | Group-Object RuleName | Select-Object Name, Count
Write-Host "`nRésumé des problèmes détectés:" -ForegroundColor Yellow
$summary | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) occurrence(s)" -ForegroundColor White
}

# Démonstration 4: Filtrer par règle
Show-SectionTitle "Démonstration 4: Filtrer par règle"
Write-Host "Analyse avec filtre sur PSUseSingularNouns:" -ForegroundColor Yellow
& $inspectScriptPath -Path $demoDir -Recurse -IncludeRule PSUseSingularNouns

# Démonstration 5: Filtrer par sévérité
Show-SectionTitle "Démonstration 5: Filtrer par sévérité"
Write-Host "Analyse avec filtre sur la sévérité Warning:" -ForegroundColor Yellow
& $inspectScriptPath -Path $demoDir -Recurse -Severity Warning

# Nettoyer les fichiers de démonstration
Write-Host "`nNettoyage des fichiers de démonstration..." -ForegroundColor Yellow
Remove-Item -Path $demoDir -Recurse -Force

Write-Host "`nDémonstration terminée!" -ForegroundColor Green

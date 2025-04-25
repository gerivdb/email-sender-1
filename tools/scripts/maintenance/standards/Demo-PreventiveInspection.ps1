#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©montre l'utilisation du script Inspect-ScriptPreventively.ps1.
.DESCRIPTION
    Ce script montre comment utiliser Inspect-ScriptPreventively.ps1 dans un flux
    de travail de dÃ©veloppement pour dÃ©tecter et corriger les problÃ¨mes dans les
    scripts PowerShell.
.EXAMPLE
    .\Demo-PreventiveInspection.ps1
    ExÃ©cute la dÃ©monstration avec les paramÃ¨tres par dÃ©faut.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Chemin du script d'inspection
$inspectScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Inspect-ScriptPreventively.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $inspectScriptPath)) {
    throw "Le script d'inspection n'existe pas: $inspectScriptPath"
}

# CrÃ©er un rÃ©pertoire temporaire pour la dÃ©monstration
$demoDir = Join-Path -Path $env:TEMP -ChildPath "PreventiveInspectionDemo"
if (-not (Test-Path -Path $demoDir)) {
    New-Item -Path $demoDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er des scripts de dÃ©monstration avec diffÃ©rents problÃ¨mes
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
    # Variable non utilisÃ©e
    $unused = "Cette variable n'est jamais utilisÃ©e"
    
    # Variable utilisÃ©e
    $used = "Cette variable est utilisÃ©e"
    return $used
}
'@
    "WriteHost.ps1" = @'
function Test-WriteHost {
    param($message)
    
    # Utilisation de Write-Host
    Write-Host "Message: $message" -ForegroundColor Green
    
    return "Message traitÃ©: $message"
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

# CrÃ©er les scripts de dÃ©monstration
foreach ($script in $scripts.Keys) {
    $scriptPath = Join-Path -Path $demoDir -ChildPath $script
    Set-Content -Path $scriptPath -Value $scripts[$script] -Force
    Write-Host "Script crÃ©Ã©: $scriptPath" -ForegroundColor Green
}

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)
    
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# DÃ©monstration 1: Analyser un script spÃ©cifique
Show-SectionTitle "DÃ©monstration 1: Analyser un script spÃ©cifique"
$scriptPath = Join-Path -Path $demoDir -ChildPath "NullComparison.ps1"
Write-Host "Analyse du script: $scriptPath" -ForegroundColor Yellow
& $inspectScriptPath -Path $scriptPath

# DÃ©monstration 2: Analyser et corriger un script
Show-SectionTitle "DÃ©monstration 2: Analyser et corriger un script"
$scriptPath = Join-Path -Path $demoDir -ChildPath "UnusedVariable.ps1"
Write-Host "Contenu original:" -ForegroundColor Yellow
Get-Content -Path $scriptPath | ForEach-Object { Write-Host "  $_" }

Write-Host "`nAnalyse et correction du script..." -ForegroundColor Yellow
& $inspectScriptPath -Path $scriptPath -Fix

Write-Host "`nContenu corrigÃ©:" -ForegroundColor Yellow
Get-Content -Path $scriptPath | ForEach-Object { Write-Host "  $_" }

# DÃ©monstration 3: Analyser tous les scripts dans un dossier
Show-SectionTitle "DÃ©monstration 3: Analyser tous les scripts dans un dossier"
Write-Host "Analyse de tous les scripts dans: $demoDir" -ForegroundColor Yellow
$results = & $inspectScriptPath -Path $demoDir -Recurse

# Afficher un rÃ©sumÃ© des rÃ©sultats
$summary = $results | Group-Object RuleName | Select-Object Name, Count
Write-Host "`nRÃ©sumÃ© des problÃ¨mes dÃ©tectÃ©s:" -ForegroundColor Yellow
$summary | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) occurrence(s)" -ForegroundColor White
}

# DÃ©monstration 4: Filtrer par rÃ¨gle
Show-SectionTitle "DÃ©monstration 4: Filtrer par rÃ¨gle"
Write-Host "Analyse avec filtre sur PSUseSingularNouns:" -ForegroundColor Yellow
& $inspectScriptPath -Path $demoDir -Recurse -IncludeRule PSUseSingularNouns

# DÃ©monstration 5: Filtrer par sÃ©vÃ©ritÃ©
Show-SectionTitle "DÃ©monstration 5: Filtrer par sÃ©vÃ©ritÃ©"
Write-Host "Analyse avec filtre sur la sÃ©vÃ©ritÃ© Warning:" -ForegroundColor Yellow
& $inspectScriptPath -Path $demoDir -Recurse -Severity Warning

# Nettoyer les fichiers de dÃ©monstration
Write-Host "`nNettoyage des fichiers de dÃ©monstration..." -ForegroundColor Yellow
Remove-Item -Path $demoDir -Recurse -Force

Write-Host "`nDÃ©monstration terminÃ©e!" -ForegroundColor Green

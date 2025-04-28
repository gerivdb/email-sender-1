<#
.SYNOPSIS
    Organisation des scripts du projet
.DESCRIPTION
    Ce script organise les scripts du projet en fonction des rÃ©sultats de l'analyse.
    Il crÃ©e les dossiers nÃ©cessaires et dÃ©place les scripts dans les dossiers appropriÃ©s.
.PARAMETER AnalysisPath
    Chemin du fichier d'analyse (par dÃ©faut : ..\D)
.PARAMETER AutoApply
    Applique automatiquement les recommandations d'organisation
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es
.EXAMPLE
    .\Organize-Scripts.ps1
    Affiche les recommandations d'organisation sans les appliquer
.EXAMPLE
    .\Organize-Scripts.ps1 -AutoApply
    Applique automatiquement les recommandations d'organisation
#>

param (
    [string]$AnalysisPath = "..\D",
    [switch]$AutoApply
)

# VÃ©rifier si le fichier d'analyse existe
if (-not (Test-Path -Path $AnalysisPath)) {
    Write-Host "Fichier d'analyse non trouvÃ©: $AnalysisPath" -ForegroundColor Red
    exit 1
}

# Charger l'analyse
$Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json

# Afficher la banniÃ¨re
Write-Host "=== Organisation des scripts ===" -ForegroundColor Cyan
Write-Host "Fichier d'analyse: $AnalysisPath" -ForegroundColor Yellow
Write-Host "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -ForegroundColor Yellow
Write-Host ""

# Afficher les statistiques par catÃ©gorie
Write-Host "Statistiques par catÃ©gorie:" -ForegroundColor Yellow
foreach ($CategoryStat in $Analysis.ScriptsByCategory) {
    Write-Host "- $($CategoryStat.Category): $($CategoryStat.Count) script(s)" -ForegroundColor Cyan
}

# Afficher le nombre de scripts Ã  dÃ©placer
Write-Host ""
Write-Host "Nombre de scripts Ã  dÃ©placer: $($Analysis.ScriptsToMove)" -ForegroundColor Magenta
Write-Host ""

# CrÃ©er un tableau pour stocker les rÃ©sultats de l'organisation
$OrganizationResults = @()

# Traiter chaque script qui doit Ãªtre dÃ©placÃ©
$ScriptsToMove = $Analysis.Scripts | Where-Object { $_.NeedsMove }
$Counter = 0
$Total = $ScriptsToMove.Count

foreach ($Script in $ScriptsToMove) {
    $Counter++
    $Progress = [math]::Round(($Counter / $Total) * 100)
    Write-Progress -Activity "Organisation des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
    
    # DÃ©terminer le chemin source et le chemin cible
    $SourcePath = $Script.Path
    $TargetFolder = $Script.TargetFolder
    $TargetPath = Join-Path -Path $TargetFolder -ChildPath $Script.Name
    
    # CrÃ©er un objet avec les rÃ©sultats de l'organisation
    $OrganizationResult = [PSCustomObject]@{
        Name = $Script.Name
        SourcePath = $SourcePath
        TargetPath = $TargetPath
        Category = $Script.Category
        SubCategory = $Script.SubCategory
        Success = $false
        Error = $null
    }
    
    # Afficher les informations sur le dÃ©placement
    Write-Host "DÃ©placement de $SourcePath vers $TargetPath" -ForegroundColor Yellow
    
    # Si AutoApply est activÃ©, dÃ©placer le script
    if ($AutoApply) {
        try {
            # CrÃ©er le dossier cible s'il n'existe pas
            $TargetDir = Split-Path -Path $TargetPath -Parent
            if (-not (Test-Path -Path $TargetDir)) {
                New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
                Write-Host "  Dossier crÃ©Ã©: $TargetDir" -ForegroundColor Green
            }
            
            # DÃ©placer le script
            Move-Item -Path $SourcePath -Destination $TargetPath -Force
            
            # Mettre Ã  jour l'objet de rÃ©sultat
            $OrganizationResult.Success = $true
            
            Write-Host "  DÃ©placement rÃ©ussi" -ForegroundColor Green
        } catch {
            # Mettre Ã  jour l'objet de rÃ©sultat
            $OrganizationResult.Success = $false
            $OrganizationResult.Error = $_.Exception.Message
            
            Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  Simulation: le script ne sera pas dÃ©placÃ©" -ForegroundColor Cyan
    }
    
    # Ajouter l'objet au tableau
    $OrganizationResults += $OrganizationResult
}

Write-Progress -Activity "Organisation des scripts" -Completed

# CrÃ©er un objet avec les rÃ©sultats de l'organisation
$Organization = [PSCustomObject]@{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalScripts = $ScriptsToMove.Count
    SuccessCount = ($OrganizationResults | Where-Object { $_.Success } | Measure-Object).Count
    ErrorCount = ($OrganizationResults | Where-Object { -not $_.Success } | Measure-Object).Count
    AutoApply = $AutoApply
    Results = $OrganizationResults
}

# Convertir l'objet en JSON et l'enregistrer dans un fichier
$OutputPath = "..\D"
$Organization | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath

Write-Host ""
Write-Host "=== Organisation terminÃ©e ===" -ForegroundColor Green
Write-Host "Nombre total de scripts Ã  dÃ©placer: $($Organization.TotalScripts)" -ForegroundColor Cyan
Write-Host "Nombre de scripts dÃ©placÃ©s avec succÃ¨s: $($Organization.SuccessCount)" -ForegroundColor Green
Write-Host "Nombre d'erreurs: $($Organization.ErrorCount)" -ForegroundColor Red

Write-Host ""
Write-Host "RÃ©sultats enregistrÃ©s dans: $OutputPath" -ForegroundColor Green

# Si AutoApply n'est pas activÃ©, afficher un message pour expliquer comment appliquer les recommandations
if (-not $AutoApply) {
    Write-Host ""
    Write-Host "Pour appliquer les recommandations d'organisation, exÃ©cutez la commande suivante:" -ForegroundColor Yellow
    Write-Host ".\Organize-Scripts.ps1 -AutoApply" -ForegroundColor Cyan
}


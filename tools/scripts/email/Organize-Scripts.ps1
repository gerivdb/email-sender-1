<#
.SYNOPSIS
    Organisation des scripts du projet
.DESCRIPTION
    Ce script organise les scripts du projet en fonction des résultats de l'analyse.
    Il crée les dossiers nécessaires et déplace les scripts dans les dossiers appropriés.
.PARAMETER AnalysisPath
    Chemin du fichier d'analyse (par défaut : ..\D)
.PARAMETER AutoApply
    Applique automatiquement les recommandations d'organisation
.PARAMETER Verbose
    Affiche des informations détaillées
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

# Vérifier si le fichier d'analyse existe
if (-not (Test-Path -Path $AnalysisPath)) {
    Write-Host "Fichier d'analyse non trouvé: $AnalysisPath" -ForegroundColor Red
    exit 1
}

# Charger l'analyse
$Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json

# Afficher la bannière
Write-Host "=== Organisation des scripts ===" -ForegroundColor Cyan
Write-Host "Fichier d'analyse: $AnalysisPath" -ForegroundColor Yellow
Write-Host "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -ForegroundColor Yellow
Write-Host ""

# Afficher les statistiques par catégorie
Write-Host "Statistiques par catégorie:" -ForegroundColor Yellow
foreach ($CategoryStat in $Analysis.ScriptsByCategory) {
    Write-Host "- $($CategoryStat.Category): $($CategoryStat.Count) script(s)" -ForegroundColor Cyan
}

# Afficher le nombre de scripts à déplacer
Write-Host ""
Write-Host "Nombre de scripts à déplacer: $($Analysis.ScriptsToMove)" -ForegroundColor Magenta
Write-Host ""

# Créer un tableau pour stocker les résultats de l'organisation
$OrganizationResults = @()

# Traiter chaque script qui doit être déplacé
$ScriptsToMove = $Analysis.Scripts | Where-Object { $_.NeedsMove }
$Counter = 0
$Total = $ScriptsToMove.Count

foreach ($Script in $ScriptsToMove) {
    $Counter++
    $Progress = [math]::Round(($Counter / $Total) * 100)
    Write-Progress -Activity "Organisation des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
    
    # Déterminer le chemin source et le chemin cible
    $SourcePath = $Script.Path
    $TargetFolder = $Script.TargetFolder
    $TargetPath = Join-Path -Path $TargetFolder -ChildPath $Script.Name
    
    # Créer un objet avec les résultats de l'organisation
    $OrganizationResult = [PSCustomObject]@{
        Name = $Script.Name
        SourcePath = $SourcePath
        TargetPath = $TargetPath
        Category = $Script.Category
        SubCategory = $Script.SubCategory
        Success = $false
        Error = $null
    }
    
    # Afficher les informations sur le déplacement
    Write-Host "Déplacement de $SourcePath vers $TargetPath" -ForegroundColor Yellow
    
    # Si AutoApply est activé, déplacer le script
    if ($AutoApply) {
        try {
            # Créer le dossier cible s'il n'existe pas
            $TargetDir = Split-Path -Path $TargetPath -Parent
            if (-not (Test-Path -Path $TargetDir)) {
                New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
                Write-Host "  Dossier créé: $TargetDir" -ForegroundColor Green
            }
            
            # Déplacer le script
            Move-Item -Path $SourcePath -Destination $TargetPath -Force
            
            # Mettre à jour l'objet de résultat
            $OrganizationResult.Success = $true
            
            Write-Host "  Déplacement réussi" -ForegroundColor Green
        } catch {
            # Mettre à jour l'objet de résultat
            $OrganizationResult.Success = $false
            $OrganizationResult.Error = $_.Exception.Message
            
            Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  Simulation: le script ne sera pas déplacé" -ForegroundColor Cyan
    }
    
    # Ajouter l'objet au tableau
    $OrganizationResults += $OrganizationResult
}

Write-Progress -Activity "Organisation des scripts" -Completed

# Créer un objet avec les résultats de l'organisation
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
Write-Host "=== Organisation terminée ===" -ForegroundColor Green
Write-Host "Nombre total de scripts à déplacer: $($Organization.TotalScripts)" -ForegroundColor Cyan
Write-Host "Nombre de scripts déplacés avec succès: $($Organization.SuccessCount)" -ForegroundColor Green
Write-Host "Nombre d'erreurs: $($Organization.ErrorCount)" -ForegroundColor Red

Write-Host ""
Write-Host "Résultats enregistrés dans: $OutputPath" -ForegroundColor Green

# Si AutoApply n'est pas activé, afficher un message pour expliquer comment appliquer les recommandations
if (-not $AutoApply) {
    Write-Host ""
    Write-Host "Pour appliquer les recommandations d'organisation, exécutez la commande suivante:" -ForegroundColor Yellow
    Write-Host ".\Organize-Scripts.ps1 -AutoApply" -ForegroundColor Cyan
}


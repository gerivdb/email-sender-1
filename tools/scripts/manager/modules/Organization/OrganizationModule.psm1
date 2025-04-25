# Module d'organisation pour le Script Manager
# Ce module coordonne l'organisation des scripts
# Author: Script Manager
# Version: 1.0
# Tags: organization, scripts, manager

# Importer les sous-modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SubModules = @(
    "ClassificationEngine.psm1",
    "ScriptMover.psm1",
    "ReferenceUpdater.psm1",
    "FolderStructureCreator.psm1"
)

foreach ($Module in $SubModules) {
    $ModulePath = Join-Path -Path $ScriptPath -ChildPath $Module
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        Write-Warning "Module $Module not found at $ModulePath"
    }
}

function Invoke-ScriptOrganization {
    <#
    .SYNOPSIS
        Organise les scripts selon les règles définies
    .DESCRIPTION
        Analyse, classe et déplace les scripts selon les règles de classification
    .PARAMETER AnalysisPath
        Chemin vers le fichier d'analyse JSON
    .PARAMETER RulesPath
        Chemin vers le fichier de règles JSON
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de l'organisation
    .PARAMETER AutoApply
        Applique automatiquement les recommandations d'organisation
    .EXAMPLE
        Invoke-ScriptOrganization -AnalysisPath "data\analysis.json" -RulesPath "config\rules.json" -OutputPath "data\organization.json"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$AnalysisPath,
        
        [Parameter(Mandatory=$true)]
        [string]$RulesPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [switch]$AutoApply
    )
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path -Path $AnalysisPath)) {
        Write-Error "Fichier d'analyse non trouvé: $AnalysisPath"
        return $null
    }
    
    if (-not (Test-Path -Path $RulesPath)) {
        Write-Error "Fichier de règles non trouvé: $RulesPath"
        return $null
    }
    
    # Charger l'analyse et les règles
    try {
        $Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
        $Rules = Get-Content -Path $RulesPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement des fichiers: $_"
        return $null
    }
    
    Write-Host "Organisation des scripts en cours..." -ForegroundColor Cyan
    Write-Host "Nombre de scripts à analyser: $($Analysis.TotalScripts)" -ForegroundColor Cyan
    Write-Host "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -ForegroundColor Yellow
    
    # Créer un tableau pour stocker les résultats de l'organisation
    $OrganizationResults = @()
    
    # Créer la structure de dossiers selon les principes SOLID
    $FolderStructure = New-FolderStructure -Rules $Rules -AutoApply:$AutoApply
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Analysis.Scripts.Count
    
    foreach ($Script in $Analysis.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "Organisation des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # Classifier le script selon les règles
        $Classification = Get-ScriptClassification -Script $Script -Rules $Rules
        
        # Déterminer le chemin cible
        $TargetPath = Get-TargetPath -Script $Script -Classification $Classification
        
        # Vérifier si le script doit être déplacé
        $NeedsMove = $Script.Path -ne $TargetPath
        
        if ($NeedsMove) {
            # Créer un objet avec les informations sur le déplacement
            $MoveInfo = [PSCustomObject]@{
                SourcePath = $Script.Path
                TargetPath = $TargetPath
                Classification = $Classification
                Dependencies = $Script.Dependencies
            }
            
            # Déplacer le script si AutoApply est activé
            $MoveResult = $null
            if ($AutoApply) {
                $MoveResult = Move-Script -MoveInfo $MoveInfo
                
                # Mettre à jour les références si le déplacement a réussi
                if ($MoveResult.Success) {
                    Update-References -Script $Script -OldPath $Script.Path -NewPath $TargetPath
                }
            } else {
                $MoveResult = [PSCustomObject]@{
                    Success = $true
                    Message = "Simulation: le script ne sera pas déplacé"
                }
            }
            
            # Ajouter le résultat au tableau
            $OrganizationResults += [PSCustomObject]@{
                Path = $Script.Path
                Name = $Script.Name
                Type = $Script.Type
                Classification = $Classification
                TargetPath = $TargetPath
                NeedsMove = $NeedsMove
                Moved = if ($AutoApply) { $MoveResult.Success } else { $false }
                Message = $MoveResult.Message
            }
        } else {
            # Le script est déjà au bon endroit
            $OrganizationResults += [PSCustomObject]@{
                Path = $Script.Path
                Name = $Script.Name
                Type = $Script.Type
                Classification = $Classification
                TargetPath = $TargetPath
                NeedsMove = $false
                Moved = $false
                Message = "Le script est déjà au bon endroit"
            }
        }
    }
    
    Write-Progress -Activity "Organisation des scripts" -Completed
    
    # Créer un objet avec les résultats de l'organisation
    $Organization = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        ScriptsToMove = ($OrganizationResults | Where-Object { $_.NeedsMove } | Measure-Object).Count
        ScriptsMoved = ($OrganizationResults | Where-Object { $_.Moved } | Measure-Object).Count
        AutoApply = $AutoApply
        FolderStructure = $FolderStructure
        Results = $OrganizationResults
    }
    
    # Convertir l'objet en JSON et l'enregistrer dans un fichier
    $Organization | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    Write-Host "Organisation terminée. Résultats enregistrés dans: $OutputPath" -ForegroundColor Green
    
    return $Organization
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ScriptOrganization

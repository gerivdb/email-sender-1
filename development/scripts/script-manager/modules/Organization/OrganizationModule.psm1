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
        Organise les scripts selon les rÃ¨gles dÃ©finies
    .DESCRIPTION
        Analyse, classe et dÃ©place les scripts selon les rÃ¨gles de classification
    .PARAMETER AnalysisPath
        Chemin vers le fichier d'analyse JSON
    .PARAMETER RulesPath
        Chemin vers le fichier de rÃ¨gles JSON
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats de l'organisation
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
    
    # VÃ©rifier si les fichiers existent
    if (-not (Test-Path -Path $AnalysisPath)) {
        Write-Error "Fichier d'analyse non trouvÃ©: $AnalysisPath"
        return $null
    }
    
    if (-not (Test-Path -Path $RulesPath)) {
        Write-Error "Fichier de rÃ¨gles non trouvÃ©: $RulesPath"
        return $null
    }
    
    # Charger l'analyse et les rÃ¨gles
    try {
        $Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
        $Rules = Get-Content -Path $RulesPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement des fichiers: $_"
        return $null
    }
    
    Write-Host "Organisation des scripts en cours..." -ForegroundColor Cyan
    Write-Host "Nombre de scripts Ã  analyser: $($Analysis.TotalScripts)" -ForegroundColor Cyan
    Write-Host "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -ForegroundColor Yellow
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats de l'organisation
    $OrganizationResults = @()
    
    # CrÃ©er la structure de dossiers selon les principes SOLID
    $FolderStructure = New-FolderStructure -Rules $Rules -AutoApply:$AutoApply
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Analysis.Scripts.Count
    
    foreach ($Script in $Analysis.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "Organisation des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # Classifier le script selon les rÃ¨gles
        $Classification = Get-ScriptClassification -Script $Script -Rules $Rules
        
        # DÃ©terminer le chemin cible
        $TargetPath = Get-TargetPath -Script $Script -Classification $Classification
        
        # VÃ©rifier si le script doit Ãªtre dÃ©placÃ©
        $NeedsMove = $Script.Path -ne $TargetPath
        
        if ($NeedsMove) {
            # CrÃ©er un objet avec les informations sur le dÃ©placement
            $MoveInfo = [PSCustomObject]@{
                SourcePath = $Script.Path
                TargetPath = $TargetPath
                Classification = $Classification
                Dependencies = $Script.Dependencies
            }
            
            # DÃ©placer le script si AutoApply est activÃ©
            $MoveResult = $null
            if ($AutoApply) {
                $MoveResult = Move-Script -MoveInfo $MoveInfo
                
                # Mettre Ã  jour les rÃ©fÃ©rences si le dÃ©placement a rÃ©ussi
                if ($MoveResult.Success) {
                    Update-References -Script $Script -OldPath $Script.Path -NewPath $TargetPath
                }
            } else {
                $MoveResult = [PSCustomObject]@{
                    Success = $true
                    Message = "Simulation: le script ne sera pas dÃ©placÃ©"
                }
            }
            
            # Ajouter le rÃ©sultat au tableau
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
            # Le script est dÃ©jÃ  au bon endroit
            $OrganizationResults += [PSCustomObject]@{
                Path = $Script.Path
                Name = $Script.Name
                Type = $Script.Type
                Classification = $Classification
                TargetPath = $TargetPath
                NeedsMove = $false
                Moved = $false
                Message = "Le script est dÃ©jÃ  au bon endroit"
            }
        }
    }
    
    Write-Progress -Activity "Organisation des scripts" -Completed
    
    # CrÃ©er un objet avec les rÃ©sultats de l'organisation
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
    
    Write-Host "Organisation terminÃ©e. RÃ©sultats enregistrÃ©s dans: $OutputPath" -ForegroundColor Green
    
    return $Organization
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ScriptOrganization

# Module d'apprentissage des modèles de code pour le Script Manager
# Ce module apprend les modèles de code utilisés dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, learning, scripts

function Start-CodeLearning {
    <#
    .SYNOPSIS
        Démarre l'apprentissage des modèles de code
    .DESCRIPTION
        Analyse les scripts pour apprendre les modèles de code utilisés
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de l'apprentissage
    .EXAMPLE
        Start-CodeLearning -Analysis $analysis -OutputPath "optimization"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le dossier d'apprentissage
    $LearningPath = Join-Path -Path $OutputPath -ChildPath "learning"
    if (-not (Test-Path -Path $LearningPath)) {
        New-Item -ItemType Directory -Path $LearningPath -Force | Out-Null
    }
    
    Write-Host "Apprentissage des modèles de code..." -ForegroundColor Cyan
    
    # Créer un modèle pour chaque type de script
    $Models = @{}
    
    # Regrouper les scripts par type
    $ScriptsByType = $Analysis.Scripts | Group-Object -Property Type
    
    foreach ($TypeGroup in $ScriptsByType) {
        $Type = $TypeGroup.Name
        $Scripts = $TypeGroup.Group
        
        Write-Host "  Apprentissage des modèles pour les scripts $Type..." -ForegroundColor Yellow
        
        # Créer un modèle pour ce type de script
        $Model = Learn-CodePatterns -Scripts $Scripts -ScriptType $Type
        $Models[$Type] = $Model
        
        # Enregistrer le modèle
        $ModelPath = Join-Path -Path $LearningPath -ChildPath "$Type`_model.json"
        $Model | ConvertTo-Json -Depth 10 | Set-Content -Path $ModelPath
        
        Write-Host "  Modèle $Type enregistré: $ModelPath" -ForegroundColor Green
    }
    
    # Créer un modèle global
    $GlobalModel = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        Models = $Models
    }
    
    # Enregistrer le modèle global
    $GlobalModelPath = Join-Path -Path $LearningPath -ChildPath "global_model.json"
    $GlobalModel | ConvertTo-Json -Depth 10 | Set-Content -Path $GlobalModelPath
    
    Write-Host "  Modèle global enregistré: $GlobalModelPath" -ForegroundColor Green
    
    return $GlobalModel
}

function Learn-CodePatterns {
    <#
    .SYNOPSIS
        Apprend les modèles de code pour un type de script
    .DESCRIPTION
        Analyse les scripts d'un type donné pour apprendre les modèles de code
    .PARAMETER Scripts
        Scripts à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Learn-CodePatterns -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un modèle vide
    $Model = [PSCustomObject]@{
        ScriptType = $ScriptType
        ScriptCount = $Scripts.Count
        NamingPatterns = @{}
        StructurePatterns = @{}
        StylePatterns = @{}
        CommonFunctions = @{}
        CommonImports = @{}
        ErrorHandlingPatterns = @{}
    }
    
    # Apprendre les modèles de nommage
    $Model.NamingPatterns = Learn-NamingPatterns -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les modèles de structure
    $Model.StructurePatterns = Learn-StructurePatterns -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les modèles de style
    $Model.StylePatterns = Learn-StylePatterns -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les fonctions communes
    $Model.CommonFunctions = Learn-CommonFunctions -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les imports communs
    $Model.CommonImports = Learn-CommonImports -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les modèles de gestion des erreurs
    $Model.ErrorHandlingPatterns = Learn-ErrorHandlingPatterns -Scripts $Scripts -ScriptType $ScriptType
    
    return $Model
}

# Exporter les fonctions
Export-ModuleMember -Function Start-CodeLearning

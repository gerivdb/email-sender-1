# Module d'apprentissage des modÃ¨les de code pour le Script Manager
# Ce module apprend les modÃ¨les de code utilisÃ©s dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, learning, scripts

function Start-CodeLearning {
    <#
    .SYNOPSIS
        DÃ©marre l'apprentissage des modÃ¨les de code
    .DESCRIPTION
        Analyse les scripts pour apprendre les modÃ¨les de code utilisÃ©s
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats de l'apprentissage
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
    
    # CrÃ©er le dossier d'apprentissage
    $LearningPath = Join-Path -Path $OutputPath -ChildPath "learning"
    if (-not (Test-Path -Path $LearningPath)) {
        New-Item -ItemType Directory -Path $LearningPath -Force | Out-Null
    }
    
    Write-Host "Apprentissage des modÃ¨les de code..." -ForegroundColor Cyan
    
    # CrÃ©er un modÃ¨le pour chaque type de script
    $Models = @{}
    
    # Regrouper les scripts par type
    $ScriptsByType = $Analysis.Scripts | Group-Object -Property Type
    
    foreach ($TypeGroup in $ScriptsByType) {
        $Type = $TypeGroup.Name
        $Scripts = $TypeGroup.Group
        
        Write-Host "  Apprentissage des modÃ¨les pour les scripts $Type..." -ForegroundColor Yellow
        
        # CrÃ©er un modÃ¨le pour ce type de script
        $Model = Learn-CodePatterns -Scripts $Scripts -ScriptType $Type
        $Models[$Type] = $Model
        
        # Enregistrer le modÃ¨le
        $ModelPath = Join-Path -Path $LearningPath -ChildPath "$Type`_model.json"
        $Model | ConvertTo-Json -Depth 10 | Set-Content -Path $ModelPath
        
        Write-Host "  ModÃ¨le $Type enregistrÃ©: $ModelPath" -ForegroundColor Green
    }
    
    # CrÃ©er un modÃ¨le global
    $GlobalModel = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        Models = $Models
    }
    
    # Enregistrer le modÃ¨le global
    $GlobalModelPath = Join-Path -Path $LearningPath -ChildPath "global_model.json"
    $GlobalModel | ConvertTo-Json -Depth 10 | Set-Content -Path $GlobalModelPath
    
    Write-Host "  ModÃ¨le global enregistrÃ©: $GlobalModelPath" -ForegroundColor Green
    
    return $GlobalModel
}

function Learn-CodePatterns {
    <#
    .SYNOPSIS
        Apprend les modÃ¨les de code pour un type de script
    .DESCRIPTION
        Analyse les scripts d'un type donnÃ© pour apprendre les modÃ¨les de code
    .PARAMETER Scripts
        Scripts Ã  analyser
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
    
    # CrÃ©er un modÃ¨le vide
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
    
    # Apprendre les modÃ¨les de nommage
    $Model.NamingPatterns = Learn-NamingPatterns -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les modÃ¨les de structure
    $Model.StructurePatterns = Learn-StructurePatterns -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les modÃ¨les de style
    $Model.StylePatterns = Learn-StylePatterns -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les fonctions communes
    $Model.CommonFunctions = Learn-CommonFunctions -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les imports communs
    $Model.CommonImports = Learn-CommonImports -Scripts $Scripts -ScriptType $ScriptType
    
    # Apprendre les modÃ¨les de gestion des erreurs
    $Model.ErrorHandlingPatterns = Learn-ErrorHandlingPatterns -Scripts $Scripts -ScriptType $ScriptType
    
    return $Model
}

# Exporter les fonctions
Export-ModuleMember -Function Start-CodeLearning

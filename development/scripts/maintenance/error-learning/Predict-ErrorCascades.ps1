#Requires -Version 5.1
<#
.SYNOPSIS
    PrÃ©dit les erreurs en cascade Ã  partir des patterns d'erreurs connus.
.DESCRIPTION
    Ce script analyse les corrÃ©lations entre les patterns d'erreurs pour prÃ©dire
    les erreurs en cascade et anticiper les problÃ¨mes potentiels.
.PARAMETER DatabasePath
    Chemin vers la base de donnÃ©es d'erreurs.
.PARAMETER ModelPath
    Chemin vers le modÃ¨le de classification des erreurs.
.PARAMETER ReportPath
    Chemin oÃ¹ enregistrer le rapport de prÃ©diction.
.PARAMETER CorrelationThreshold
    Seuil de corrÃ©lation pour considÃ©rer deux erreurs comme liÃ©es.
.EXAMPLE
    .\Predict-ErrorCascades.ps1 -CorrelationThreshold 0.7
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = (Join-Path -Path $PSScriptRoot -ChildPath "error_database.json"),

    [Parameter(Mandatory = $false)]
    [string]$ModelPath = (Join-Path -Path $PSScriptRoot -ChildPath "error_pattern_model.xml"),

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "error_cascade_prediction.md"),

    [Parameter(Mandatory = $false)]
    [double]$CorrelationThreshold = 0.6
)

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorPatternAnalyzer.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module ErrorPatternAnalyzer non trouvÃ©: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour charger le modÃ¨le de classification
function Import-ErrorModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelPath
    )

    if (-not (Test-Path -Path $ModelPath)) {
        Write-Warning "ModÃ¨le non trouvÃ©: $ModelPath"
        return $null
    }

    try {
        # Charger le modÃ¨le depuis le fichier XML
        $xmlDocument = New-Object System.Xml.XmlDocument
        $xmlDocument.Load($ModelPath)

        # CrÃ©er un nouveau modÃ¨le
        $model = @{
            Weights          = @{
                ExceptionType  = @{}
                ErrorId        = @{}
                MessagePattern = @{}
                ScriptContext  = @{}
                LinePattern    = @{}
                Occurrences    = 0.0
            }
            Bias             = 0.0
            LearningRate     = 0.01
            Iterations       = 0
            TrainingAccuracy = 0.0
        }

        # Charger les mÃ©tadonnÃ©es
        $model.Iterations = [int]$xmlDocument.SelectSingleNode("/ErrorPatternModel/Metadata/Iterations").InnerText
        $model.LearningRate = [double]$xmlDocument.SelectSingleNode("/ErrorPatternModel/Metadata/LearningRate").InnerText
        $model.TrainingAccuracy = [double]$xmlDocument.SelectSingleNode("/ErrorPatternModel/Metadata/TrainingAccuracy").InnerText

        # Charger les poids
        $model.Bias = [double]$xmlDocument.SelectSingleNode("/ErrorPatternModel/Weights/Bias").InnerText
        $model.Weights.Occurrences = [double]$xmlDocument.SelectSingleNode("/ErrorPatternModel/Weights/Occurrences").InnerText

        # Charger les poids catÃ©goriels
        $exceptionTypes = $xmlDocument.SelectNodes("/ErrorPatternModel/Weights/ExceptionTypes/ExceptionType")
        foreach ($exceptionType in $exceptionTypes) {
            $name = $exceptionType.GetAttribute("name")
            $weight = [double]$exceptionType.GetAttribute("weight")
            $model.Weights.ExceptionType[$name] = $weight
        }

        $errorIds = $xmlDocument.SelectNodes("/ErrorPatternModel/Weights/ErrorIds/ErrorId")
        foreach ($errorId in $errorIds) {
            $name = $errorId.GetAttribute("name")
            $weight = [double]$errorId.GetAttribute("weight")
            $model.Weights.ErrorId[$name] = $weight
        }

        $scriptContexts = $xmlDocument.SelectNodes("/ErrorPatternModel/Weights/ScriptContexts/ScriptContext")
        foreach ($scriptContext in $scriptContexts) {
            $name = $scriptContext.GetAttribute("name")
            $weight = [double]$scriptContext.GetAttribute("weight")
            $model.Weights.ScriptContext[$name] = $weight
        }

        Write-Verbose "ModÃ¨le chargÃ©: $ModelPath"

        return $model
    } catch {
        Write-Warning "Erreur lors du chargement du modÃ¨le: $_"
        return $null
    }
}

# Fonction pour construire un graphe de dÃ©pendances d'erreurs
function New-ErrorDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Patterns,

        [Parameter(Mandatory = $true)]
        [array]$Correlations,

        [Parameter(Mandatory = $false)]
        [double]$CorrelationThreshold = 0.6
    )

    # CrÃ©er un graphe de dÃ©pendances
    $graph = @{}

    # Initialiser le graphe avec tous les patterns
    foreach ($pattern in $Patterns) {
        $graph[$pattern.Id] = @{
            Pattern      = $pattern
            Dependencies = @()
            DependedBy   = @()
        }
    }

    # Ajouter les dÃ©pendances
    foreach ($correlation in $Correlations) {
        if ($correlation.Similarity -ge $CorrelationThreshold) {
            $patternId1 = $correlation.PatternId1
            $patternId2 = $correlation.PatternId2

            # VÃ©rifier que les deux patterns existent dans le graphe
            if ($graph.ContainsKey($patternId1) -and $graph.ContainsKey($patternId2)) {
                # Ajouter la dÃ©pendance dans les deux sens
                $graph[$patternId1].Dependencies += @{
                    PatternId    = $patternId2
                    Similarity   = $correlation.Similarity
                    Relationship = $correlation.Relationship
                }

                $graph[$patternId2].DependedBy += @{
                    PatternId    = $patternId1
                    Similarity   = $correlation.Similarity
                    Relationship = $correlation.Relationship
                }
            }
        }
    }

    return $graph
}

# Fonction pour identifier les patterns racines
function Get-RootPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )

    $rootPatterns = @()

    foreach ($patternId in $Graph.Keys) {
        $node = $Graph[$patternId]

        # Un pattern racine a des dÃ©pendances mais n'est pas dÃ©pendant d'autres patterns
        if ($node.Dependencies.Count -gt 0 -and $node.DependedBy.Count -eq 0) {
            $rootPatterns += $patternId
        }
    }

    return $rootPatterns
}

# Fonction pour identifier les patterns feuilles
function Get-LeafPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )

    $leafPatterns = @()

    foreach ($patternId in $Graph.Keys) {
        $node = $Graph[$patternId]

        # Un pattern feuille est dÃ©pendant d'autres patterns mais n'a pas de dÃ©pendances
        if ($node.Dependencies.Count -eq 0 -and $node.DependedBy.Count -gt 0) {
            $leafPatterns += $patternId
        }
    }

    return $leafPatterns
}

# Fonction pour identifier les chemins de cascade
function Get-CascadePaths {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [array]$RootPatterns
    )

    $cascadePaths = @()

    foreach ($rootPattern in $RootPatterns) {
        $paths = Find-PathsFromRoot -Graph $Graph -RootPatternId $rootPattern
        $cascadePaths += $paths
    }

    return $cascadePaths
}

# Fonction rÃ©cursive pour trouver les chemins Ã  partir d'un pattern racine
function Find-PathsFromRoot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [string]$RootPatternId,

        [Parameter(Mandatory = $false)]
        [array]$CurrentPath = @()
    )

    # Ajouter le pattern actuel au chemin
    $newPath = $CurrentPath + $RootPatternId

    # Obtenir les dÃ©pendances du pattern actuel
    $dependencies = $Graph[$RootPatternId].Dependencies

    # Si le pattern n'a pas de dÃ©pendances, retourner le chemin actuel
    if ($dependencies.Count -eq 0) {
        return @($newPath)
    }

    # Sinon, explorer les dÃ©pendances
    $paths = @()

    foreach ($dependency in $dependencies) {
        # Ã‰viter les cycles
        if ($newPath -notcontains $dependency.PatternId) {
            $subPaths = Find-PathsFromRoot -Graph $Graph -RootPatternId $dependency.PatternId -CurrentPath $newPath
            $paths += $subPaths
        }
    }

    return $paths
}

# Fonction pour calculer la probabilitÃ© d'une cascade
function Measure-CascadeProbability {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [array]$Path
    )

    # Initialiser la probabilitÃ© Ã  1
    $probability = 1.0

    # Calculer la probabilitÃ© de la cascade
    for ($i = 0; $i -lt $Path.Count - 1; $i++) {
        $patternId1 = $Path[$i]
        $patternId2 = $Path[$i + 1]

        # Trouver la dÃ©pendance entre les deux patterns
        $dependency = $Graph[$patternId1].Dependencies | Where-Object { $_.PatternId -eq $patternId2 } | Select-Object -First 1

        if ($dependency) {
            # Utiliser la similaritÃ© comme probabilitÃ© de transition
            $probability *= $dependency.Similarity
        } else {
            # Si la dÃ©pendance n'est pas trouvÃ©e, utiliser une probabilitÃ© faible
            $probability *= 0.1
        }
    }

    return $probability
}

# Fonction pour gÃ©nÃ©rer un rapport de prÃ©diction des erreurs en cascade
function New-CascadePredictionReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [array]$CascadePaths,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )

    # Trier les chemins par probabilitÃ©
    $cascadePathsWithProbability = @()

    foreach ($path in $CascadePaths) {
        $probability = Measure-CascadeProbability -Graph $Graph -Path $path

        $cascadePathsWithProbability += @{
            Path        = $path
            Probability = $probability
        }
    }

    $sortedPaths = $cascadePathsWithProbability | Sort-Object -Property Probability -Descending

    # CrÃ©er le rapport
    $report = @"
# Rapport de prÃ©diction des erreurs en cascade
*GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## RÃ©sumÃ©
- Nombre de patterns d'erreur: $($Graph.Count)
- Nombre de chemins de cascade: $($CascadePaths.Count)
- Seuil de corrÃ©lation: $CorrelationThreshold

## Cascades d'erreurs les plus probables
$(foreach ($pathInfo in ($sortedPaths | Select-Object -First 10)) {
    $pathText = "### Cascade avec probabilitÃ© de $([Math]::Round($pathInfo.Probability * 100, 2))%`n`n"
    $pathText += "```mermaid`nflowchart LR`n"

    for ($i = 0; $i -lt $pathInfo.Path.Count - 1; $i++) {
        $patternId1 = $pathInfo.Path[$i]
        $patternId2 = $pathInfo.Path[$i + 1]

        $pattern1 = $Graph[$patternId1].Pattern
        $pattern2 = $Graph[$patternId2].Pattern

        $dependency = $Graph[$patternId1].Dependencies | Where-Object { $_.PatternId -eq $patternId2 } | Select-Object -First 1

        $pathText += "    $($patternId1.Substring(0, 8))[$($pattern1.Name)] -->|$([Math]::Round($dependency.Similarity * 100, 0))%| $($patternId2.Substring(0, 8))[$($pattern2.Name)]`n"
    }

    $pathText += "````n`n"

    $pathText += "#### Description de la cascade`n`n"

    for ($i = 0; $i -lt $pathInfo.Path.Count; $i++) {
        $patternId = $pathInfo.Path[$i]
        $pattern = $Graph[$patternId].Pattern

        $pathText += "$($i + 1). **$($pattern.Name)**: $($pattern.Description)`n"

        if ($i -lt $pathInfo.Path.Count - 1) {
            $patternId2 = $pathInfo.Path[$i + 1]
            $dependency = $Graph[$patternId].Dependencies | Where-Object { $_.PatternId -eq $patternId2 } | Select-Object -First 1

            $pathText += "   - Relation: $($dependency.Relationship) (SimilaritÃ©: $([Math]::Round($dependency.Similarity * 100, 0))%)`n"
        }
    }

    $pathText += "`n"
    $pathText
})

## Patterns d'erreur racines
Les patterns d'erreur racines sont ceux qui dÃ©clenchent des cascades d'erreurs mais ne sont pas dÃ©clenchÃ©s par d'autres erreurs.

$(foreach ($patternId in $Graph.Keys) {
    $node = $Graph[$patternId]

    if ($node.Dependencies.Count -gt 0 -and $node.DependedBy.Count -eq 0) {
        $pattern = $node.Pattern

        "### $($pattern.Name)`n"
        "- **Description**: $($pattern.Description)`n"
        "- **Occurrences**: $($pattern.Occurrences)`n"
        "- **DÃ©pendances**: $($node.Dependencies.Count)`n`n"

        "#### Erreurs dÃ©clenchÃ©es`n"
        foreach ($dependency in $node.Dependencies) {
            $dependentPattern = $Graph[$dependency.PatternId].Pattern
            "- **$($dependentPattern.Name)** (SimilaritÃ©: $([Math]::Round($dependency.Similarity * 100, 0))%)`n"
        }

        "`n"
    }
})

## Recommandations pour prÃ©venir les cascades d'erreurs
1. **AmÃ©liorer la gestion des erreurs racines**
   - Concentrer les efforts sur la prÃ©vention des erreurs racines pour Ã©viter les cascades
   - ImplÃ©menter des mÃ©canismes de dÃ©tection prÃ©coce pour les patterns racines

2. **Renforcer les points de dÃ©faillance critiques**
   - Identifier les patterns qui apparaissent dans plusieurs cascades
   - AmÃ©liorer la robustesse du code dans ces zones critiques

3. **Mettre en place des barriÃ¨res de sÃ©curitÃ©**
   - ImplÃ©menter des mÃ©canismes de rÃ©cupÃ©ration pour interrompre les cascades
   - Utiliser des techniques de cloisonnement pour Ã©viter la propagation des erreurs

4. **Surveiller les indicateurs prÃ©coces**
   - Mettre en place une surveillance des patterns racines
   - Alerter lorsque des patterns racines sont dÃ©tectÃ©s pour prÃ©venir les cascades
"@

    $report | Out-File -FilePath $ReportPath -Encoding utf8

    Write-Host "Rapport de prÃ©diction gÃ©nÃ©rÃ©: $ReportPath" -ForegroundColor Green

    return $ReportPath
}

# ExÃ©cution principale
Write-Host "PrÃ©diction des erreurs en cascade" -ForegroundColor Cyan

# VÃ©rifier si la base de donnÃ©es existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Error "Base de donnÃ©es non trouvÃ©e: $DatabasePath"
    exit 1
}

# Charger la base de donnÃ©es
$database = Get-Content -Path $DatabasePath -Raw | ConvertFrom-Json

# VÃ©rifier si la base de donnÃ©es contient des patterns et des corrÃ©lations
if (-not $database.Patterns -or $database.Patterns.Count -eq 0) {
    Write-Error "La base de donnÃ©es ne contient pas de patterns d'erreur."
    exit 1
}

if (-not $database.Correlations -or $database.Correlations.Count -eq 0) {
    Write-Warning "La base de donnÃ©es ne contient pas de corrÃ©lations entre patterns."
    Write-Host "ExÃ©cution de l'analyse des corrÃ©lations..." -ForegroundColor Yellow

    # Analyser les corrÃ©lations entre patterns
    foreach ($pattern in $database.Patterns) {
        Find-ErrorCorrelations -PatternId $pattern.Id
    }

    # Sauvegarder la base de donnÃ©es
    Save-ErrorDatabase -DatabasePath $DatabasePath

    # Recharger la base de donnÃ©es
    $database = Get-Content -Path $DatabasePath -Raw | ConvertFrom-Json
}

# Charger le modÃ¨le de classification
$model = Import-ErrorModel -ModelPath $ModelPath

# Construire le graphe de dÃ©pendances
$graph = New-ErrorDependencyGraph -Patterns $database.Patterns -Correlations $database.Correlations -CorrelationThreshold $CorrelationThreshold

Write-Host "Graphe de dÃ©pendances construit avec $($graph.Count) patterns" -ForegroundColor Yellow

# Identifier les patterns racines
$rootPatterns = Get-RootPatterns -Graph $graph

Write-Host "Nombre de patterns racines: $($rootPatterns.Count)" -ForegroundColor Yellow

# Identifier les patterns feuilles
$leafPatterns = Get-LeafPatterns -Graph $graph

Write-Host "Nombre de patterns feuilles: $($leafPatterns.Count)" -ForegroundColor Yellow

# Identifier les chemins de cascade
$cascadePaths = Get-CascadePaths -Graph $graph -RootPatterns $rootPatterns

Write-Host "Nombre de chemins de cascade: $($cascadePaths.Count)" -ForegroundColor Yellow

# GÃ©nÃ©rer un rapport de prÃ©diction
$reportPath = New-CascadePredictionReport -Graph $graph -CascadePaths $cascadePaths -ReportPath $ReportPath

Write-Host "PrÃ©diction des erreurs en cascade terminÃ©e avec succÃ¨s." -ForegroundColor Green
Write-Host "Rapport de prÃ©diction: $ReportPath" -ForegroundColor Green


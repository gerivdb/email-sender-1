#Requires -Version 5.1
<#
.SYNOPSIS
    EntraÃ®ne un modÃ¨le d'apprentissage pour amÃ©liorer la classification des patterns d'erreurs.
.DESCRIPTION
    Ce script entraÃ®ne un modÃ¨le d'apprentissage automatique pour amÃ©liorer la classification
    des patterns d'erreurs et la dÃ©tection des patterns inÃ©dits.
.PARAMETER DatabasePath
    Chemin vers la base de donnÃ©es d'erreurs.
.PARAMETER ModelPath
    Chemin oÃ¹ enregistrer le modÃ¨le entraÃ®nÃ©.
.PARAMETER TrainingIterations
    Nombre d'itÃ©rations d'entraÃ®nement.
.EXAMPLE
    .\Train-ErrorPatternModel.ps1 -TrainingIterations 100
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
    [int]$TrainingIterations = 50
)

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorPatternAnalyzer.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module ErrorPatternAnalyzer non trouvÃ©: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour extraire les caractÃ©ristiques d'un pattern d'erreur
function Get-PatternFeatures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Pattern
    )

    $features = @{
        ExceptionType    = $Pattern.Features.ExceptionType
        ErrorId          = $Pattern.Features.ErrorId
        MessagePattern   = $Pattern.Features.MessagePattern
        ScriptContext    = $Pattern.Features.ScriptContext
        LinePattern      = $Pattern.Features.LinePattern
        Occurrences      = $Pattern.Occurrences
        IsInedited       = [int]$Pattern.IsInedited
        ValidationStatus = $Pattern.ValidationStatus
    }

    return $features
}

# Fonction pour normaliser les caractÃ©ristiques
function ConvertTo-NormalizedFeatures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Patterns
    )

    # Extraire les caractÃ©ristiques de tous les patterns
    $allFeatures = @()

    foreach ($pattern in $Patterns) {
        $features = Get-PatternFeatures -Pattern $pattern
        $allFeatures += $features
    }

    # Normaliser les caractÃ©ristiques numÃ©riques
    $maxOccurrences = ($allFeatures | Measure-Object -Property Occurrences -Maximum).Maximum

    if ($maxOccurrences -eq 0) {
        $maxOccurrences = 1
    }

    # Normaliser les caractÃ©ristiques de chaque pattern
    $normalizedPatterns = @()

    foreach ($pattern in $Patterns) {
        $features = Get-PatternFeatures -Pattern $pattern

        # Normaliser les occurrences
        $features.Occurrences = $features.Occurrences / $maxOccurrences

        # Ajouter le pattern normalisÃ©
        $normalizedPattern = @{
            Id               = $pattern.Id
            Features         = $features
            IsInedited       = $pattern.IsInedited
            ValidationStatus = $pattern.ValidationStatus
        }

        $normalizedPatterns += $normalizedPattern
    }

    return $normalizedPatterns
}

# Fonction pour diviser les donnÃ©es en ensembles d'entraÃ®nement et de test
function Split-TrainingData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Patterns,

        [Parameter(Mandatory = $false)]
        [double]$TrainingRatio = 0.8
    )

    # MÃ©langer les patterns
    $shuffledPatterns = $Patterns | Sort-Object { Get-Random }

    # Calculer la taille de l'ensemble d'entraÃ®nement
    $trainingSize = [Math]::Floor($shuffledPatterns.Count * $TrainingRatio)

    # Diviser les donnÃ©es
    $trainingSet = $shuffledPatterns | Select-Object -First $trainingSize
    $testSet = $shuffledPatterns | Select-Object -Skip $trainingSize

    return @{
        TrainingSet = $trainingSet
        TestSet     = $testSet
    }
}

# Fonction pour entraÃ®ner un modÃ¨le de classification
function Start-ModelTraining {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$TrainingSet,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 50
    )

    # Initialiser le modÃ¨le
    $model = @{
        Weights          = @{
            ExceptionType  = @{}
            ErrorId        = @{}
            MessagePattern = @{}
            ScriptContext  = @{}
            LinePattern    = @{}
            Occurrences    = 0.5
        }
        Bias             = 0.0
        LearningRate     = 0.01
        Iterations       = $Iterations
        TrainingAccuracy = 0.0
    }

    # EntraÃ®ner le modÃ¨le
    for ($i = 0; $i -lt $Iterations; $i++) {
        $correctPredictions = 0

        foreach ($pattern in $TrainingSet) {
            # Calculer la prÃ©diction
            $prediction = Get-PatternClass -Model $model -Features $pattern.Features

            # Calculer l'erreur
            $target = [int]$pattern.IsInedited
            $errorDelta = $target - $prediction

            # Mettre Ã  jour les poids
            $model.Bias += $model.LearningRate * $errorDelta
            $model.Weights.Occurrences += $model.LearningRate * $errorDelta * $pattern.Features.Occurrences

            # Mettre Ã  jour les poids des caractÃ©ristiques catÃ©gorielles
            $exceptionType = $pattern.Features.ExceptionType
            if (-not $model.Weights.ExceptionType.ContainsKey($exceptionType)) {
                $model.Weights.ExceptionType[$exceptionType] = 0.0
            }
            $model.Weights.ExceptionType[$exceptionType] += $model.LearningRate * $errorDelta

            $errorId = $pattern.Features.ErrorId
            if (-not $model.Weights.ErrorId.ContainsKey($errorId)) {
                $model.Weights.ErrorId[$errorId] = 0.0
            }
            $model.Weights.ErrorId[$errorId] += $model.LearningRate * $errorDelta

            $scriptContext = $pattern.Features.ScriptContext
            if (-not $model.Weights.ScriptContext.ContainsKey($scriptContext)) {
                $model.Weights.ScriptContext[$scriptContext] = 0.0
            }
            $model.Weights.ScriptContext[$scriptContext] += $model.LearningRate * $errorDelta

            # VÃ©rifier si la prÃ©diction est correcte
            $predictedClass = if ($prediction -ge 0.5) { 1 } else { 0 }
            if ($predictedClass -eq $target) {
                $correctPredictions++
            }
        }

        # Calculer la prÃ©cision
        $accuracy = $correctPredictions / $TrainingSet.Count

        Write-Verbose "ItÃ©ration $($i + 1)/$Iterations - PrÃ©cision: $([Math]::Round($accuracy * 100, 2))%"
    }

    # Enregistrer la prÃ©cision finale
    $model.TrainingAccuracy = $correctPredictions / $TrainingSet.Count

    return $model
}

# Fonction pour prÃ©dire la classe d'un pattern
function Get-PatternClass {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,

        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )

    # Initialiser la somme pondÃ©rÃ©e
    $weightedSum = $Model.Bias

    # Ajouter la contribution des caractÃ©ristiques numÃ©riques
    $weightedSum += $Model.Weights.Occurrences * $Features.Occurrences

    # Ajouter la contribution des caractÃ©ristiques catÃ©gorielles
    $exceptionType = $Features.ExceptionType
    if ($Model.Weights.ExceptionType.ContainsKey($exceptionType)) {
        $weightedSum += $Model.Weights.ExceptionType[$exceptionType]
    }

    $errorId = $Features.ErrorId
    if ($Model.Weights.ErrorId.ContainsKey($errorId)) {
        $weightedSum += $Model.Weights.ErrorId[$errorId]
    }

    $scriptContext = $Features.ScriptContext
    if ($Model.Weights.ScriptContext.ContainsKey($scriptContext)) {
        $weightedSum += $Model.Weights.ScriptContext[$scriptContext]
    }

    # Appliquer la fonction sigmoÃ¯de
    $prediction = 1 / (1 + [Math]::Exp(-$weightedSum))

    return $prediction
}

# Fonction pour Ã©valuer le modÃ¨le
function Test-ErrorModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,

        [Parameter(Mandatory = $true)]
        [array]$TestSet
    )

    $correctPredictions = 0
    $truePositives = 0
    $falsePositives = 0
    $trueNegatives = 0
    $falseNegatives = 0

    foreach ($pattern in $TestSet) {
        # Calculer la prÃ©diction
        $prediction = Get-PatternClass -Model $Model -Features $pattern.Features

        # Convertir la prÃ©diction en classe
        $predictedClass = if ($prediction -ge 0.5) { 1 } else { 0 }

        # VÃ©rifier si la prÃ©diction est correcte
        $target = [int]$pattern.IsInedited

        if ($predictedClass -eq $target) {
            $correctPredictions++

            if ($target -eq 1) {
                $truePositives++
            } else {
                $trueNegatives++
            }
        } else {
            if ($predictedClass -eq 1) {
                $falsePositives++
            } else {
                $falseNegatives++
            }
        }
    }

    # Calculer les mÃ©triques
    $accuracy = $correctPredictions / $TestSet.Count
    $precision = if ($truePositives + $falsePositives -eq 0) { 0 } else { $truePositives / ($truePositives + $falsePositives) }
    $recall = if ($truePositives + $falseNegatives -eq 0) { 0 } else { $truePositives / ($truePositives + $falseNegatives) }
    $f1Score = if ($precision + $recall -eq 0) { 0 } else { 2 * $precision * $recall / ($precision + $recall) }

    $metrics = @{
        Accuracy       = $accuracy
        Precision      = $precision
        Recall         = $recall
        F1Score        = $f1Score
        TruePositives  = $truePositives
        FalsePositives = $falsePositives
        TrueNegatives  = $trueNegatives
        FalseNegatives = $falseNegatives
    }

    return $metrics
}

# Fonction pour sauvegarder le modÃ¨le
function Save-Model {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,

        [Parameter(Mandatory = $true)]
        [string]$ModelPath
    )

    # Convertir le modÃ¨le en XML
    $xmlWriter = New-Object System.Xml.XmlTextWriter($ModelPath, [System.Text.Encoding]::UTF8)
    $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
    $xmlWriter.Indentation = 4

    $xmlWriter.WriteStartDocument()
    $xmlWriter.WriteStartElement("ErrorPatternModel")

    # Ã‰crire les mÃ©tadonnÃ©es
    $xmlWriter.WriteStartElement("Metadata")
    $xmlWriter.WriteElementString("CreatedAt", (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"))
    $xmlWriter.WriteElementString("Iterations", $Model.Iterations.ToString())
    $xmlWriter.WriteElementString("LearningRate", $Model.LearningRate.ToString())
    $xmlWriter.WriteElementString("TrainingAccuracy", $Model.TrainingAccuracy.ToString())
    $xmlWriter.WriteEndElement() # Metadata

    # Ã‰crire les poids
    $xmlWriter.WriteStartElement("Weights")

    # Ã‰crire le biais
    $xmlWriter.WriteElementString("Bias", $Model.Bias.ToString())

    # Ã‰crire les poids numÃ©riques
    $xmlWriter.WriteElementString("Occurrences", $Model.Weights.Occurrences.ToString())

    # Ã‰crire les poids catÃ©goriels
    $xmlWriter.WriteStartElement("ExceptionTypes")
    foreach ($key in $Model.Weights.ExceptionType.Keys) {
        $xmlWriter.WriteStartElement("ExceptionType")
        $xmlWriter.WriteAttributeString("name", $key)
        $xmlWriter.WriteAttributeString("weight", $Model.Weights.ExceptionType[$key].ToString())
        $xmlWriter.WriteEndElement() # ExceptionType
    }
    $xmlWriter.WriteEndElement() # ExceptionTypes

    $xmlWriter.WriteStartElement("ErrorIds")
    foreach ($key in $Model.Weights.ErrorId.Keys) {
        $xmlWriter.WriteStartElement("ErrorId")
        $xmlWriter.WriteAttributeString("name", $key)
        $xmlWriter.WriteAttributeString("weight", $Model.Weights.ErrorId[$key].ToString())
        $xmlWriter.WriteEndElement() # ErrorId
    }
    $xmlWriter.WriteEndElement() # ErrorIds

    $xmlWriter.WriteStartElement("ScriptContexts")
    foreach ($key in $Model.Weights.ScriptContext.Keys) {
        $xmlWriter.WriteStartElement("ScriptContext")
        $xmlWriter.WriteAttributeString("name", $key)
        $xmlWriter.WriteAttributeString("weight", $Model.Weights.ScriptContext[$key].ToString())
        $xmlWriter.WriteEndElement() # ScriptContext
    }
    $xmlWriter.WriteEndElement() # ScriptContexts

    $xmlWriter.WriteEndElement() # Weights

    $xmlWriter.WriteEndElement() # ErrorPatternModel
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()

    Write-Host "ModÃ¨le sauvegardÃ©: $ModelPath" -ForegroundColor Green
}

# Fonction pour charger un modÃ¨le
function Import-ErrorModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelPath
    )

    if (-not (Test-Path -Path $ModelPath)) {
        Write-Error "ModÃ¨le non trouvÃ©: $ModelPath"
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

        Write-Host "ModÃ¨le chargÃ©: $ModelPath" -ForegroundColor Green

        return $model
    } catch {
        Write-Error "Erreur lors du chargement du modÃ¨le: $_"
        return $null
    }
}

# Fonction pour crÃ©er un rapport d'entraÃ®nement
function New-TrainingReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,

        [Parameter(Mandatory = $true)]
        [hashtable]$Metrics,

        [Parameter(Mandatory = $false)]
        [string]$ReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "training_report.md")
    )

    # CrÃ©er le rapport
    $report = @"
# Rapport d'entraÃ®nement du modÃ¨le de classification des patterns d'erreur
*GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## ParamÃ¨tres d'entraÃ®nement
- Nombre d'itÃ©rations: $($Model.Iterations)
- Taux d'apprentissage: $($Model.LearningRate)
- PrÃ©cision d'entraÃ®nement: $([Math]::Round($Model.TrainingAccuracy * 100, 2))%

## MÃ©triques d'Ã©valuation
- PrÃ©cision: $([Math]::Round($Metrics.Accuracy * 100, 2))%
- PrÃ©cision (Precision): $([Math]::Round($Metrics.Precision * 100, 2))%
- Rappel (Recall): $([Math]::Round($Metrics.Recall * 100, 2))%
- Score F1: $([Math]::Round($Metrics.F1Score * 100, 2))%

### Matrice de confusion
|               | PrÃ©dit InÃ©dit | PrÃ©dit Non-InÃ©dit |
|---------------|---------------|-------------------|
| RÃ©el InÃ©dit   | $($Metrics.TruePositives) | $($Metrics.FalseNegatives) |
| RÃ©el Non-InÃ©dit | $($Metrics.FalsePositives) | $($Metrics.TrueNegatives) |

## CaractÃ©ristiques importantes
### Types d'exception
$(foreach ($key in ($Model.Weights.ExceptionType.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10)) {
    "- $($key.Key): $([Math]::Round($key.Value, 4))"
})

### IDs d'erreur
$(foreach ($key in ($Model.Weights.ErrorId.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10)) {
    "- $($key.Key): $([Math]::Round($key.Value, 4))"
})

### Contextes de script
$(foreach ($key in ($Model.Weights.ScriptContext.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10)) {
    "- $($key.Key): $([Math]::Round($key.Value, 4))"
})

## Recommandations
- Surveiller les types d'exception avec des poids Ã©levÃ©s
- AmÃ©liorer la gestion des erreurs dans les contextes de script avec des poids Ã©levÃ©s
- Continuer Ã  collecter des donnÃ©es pour amÃ©liorer le modÃ¨le
"@

    $report | Out-File -FilePath $ReportPath -Encoding utf8

    Write-Host "Rapport d'entraÃ®nement gÃ©nÃ©rÃ©: $ReportPath" -ForegroundColor Green

    return $ReportPath
}

# ExÃ©cution principale
Write-Host "EntraÃ®nement du modÃ¨le de classification des patterns d'erreur" -ForegroundColor Cyan

# VÃ©rifier si la base de donnÃ©es existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Error "Base de donnÃ©es non trouvÃ©e: $DatabasePath"
    exit 1
}

# Charger la base de donnÃ©es
$database = Get-Content -Path $DatabasePath -Raw | ConvertFrom-Json

# VÃ©rifier si la base de donnÃ©es contient des patterns
if (-not $database.Patterns -or $database.Patterns.Count -eq 0) {
    Write-Error "La base de donnÃ©es ne contient pas de patterns d'erreur."
    exit 1
}

# Normaliser les patterns
$normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $database.Patterns

# Diviser les donnÃ©es en ensembles d'entraÃ®nement et de test
$dataSets = Split-TrainingData -Patterns $normalizedPatterns

Write-Host "Nombre de patterns d'entraÃ®nement: $($dataSets.TrainingSet.Count)" -ForegroundColor Yellow
Write-Host "Nombre de patterns de test: $($dataSets.TestSet.Count)" -ForegroundColor Yellow

# EntraÃ®ner le modÃ¨le
$model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations $TrainingIterations

Write-Host "ModÃ¨le entraÃ®nÃ© avec une prÃ©cision de $([Math]::Round($model.TrainingAccuracy * 100, 2))%" -ForegroundColor Green

# Ã‰valuer le modÃ¨le
$metrics = Test-ErrorModel -Model $model -TestSet $dataSets.TestSet

Write-Host "Ã‰valuation du modÃ¨le:" -ForegroundColor Cyan
Write-Host "- PrÃ©cision: $([Math]::Round($metrics.Accuracy * 100, 2))%" -ForegroundColor Yellow
Write-Host "- PrÃ©cision (Precision): $([Math]::Round($metrics.Precision * 100, 2))%" -ForegroundColor Yellow
Write-Host "- Rappel (Recall): $([Math]::Round($metrics.Recall * 100, 2))%" -ForegroundColor Yellow
Write-Host "- Score F1: $([Math]::Round($metrics.F1Score * 100, 2))%" -ForegroundColor Yellow

# Sauvegarder le modÃ¨le
Save-Model -Model $model -ModelPath $ModelPath

# CrÃ©er un rapport d'entraÃ®nement
$reportPath = New-TrainingReport -Model $model -Metrics $metrics

Write-Host "EntraÃ®nement terminÃ© avec succÃ¨s." -ForegroundColor Green
Write-Host "ModÃ¨le sauvegardÃ©: $ModelPath" -ForegroundColor Green
Write-Host "Rapport d'entraÃ®nement: $reportPath" -ForegroundColor Green

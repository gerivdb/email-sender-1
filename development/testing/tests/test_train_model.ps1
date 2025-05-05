# Importer le script
. (Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\Train-ErrorPatternModel.ps1")

# CrÃ©er des donnÃ©es de test
$patterns = @(
    @{
        Id = [guid]::NewGuid().ToString()
        Name = "Pattern-1"
        Description = "Test pattern 1"
        Features = @{
            ExceptionType = "System.NullReferenceException"
            ErrorId = "NullReference"
            MessagePattern = "Test message pattern 1"
            ScriptContext = "Test-Script1.ps1"
            LinePattern = "Test line pattern 1"
        }
        FirstOccurrence = (Get-Date).AddDays(-10).ToString("yyyy-MM-ddTHH:mm:ss")
        LastOccurrence = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        Occurrences = 5
        Examples = @(
            @{
                Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                ErrorId = "NullReference"
                Exception = "System.NullReferenceException"
                Message = "Test error message 1"
                ScriptName = "Test-Script1.ps1"
                ScriptLineNumber = 42
                Line = "Test line 1"
                PositionMessage = "At Test-Script1.ps1:42"
                StackTrace = "at <ScriptBlock>, Test-Script1.ps1: line 42"
                Context = "Test"
                Source = "Test"
                Tags = @("Test")
                CategoryInfo = "InvalidOperation"
            }
        )
        IsInedited = $true
        ValidationStatus = "Valid"
        RelatedPatterns = @()
    },
    @{
        Id = [guid]::NewGuid().ToString()
        Name = "Pattern-2"
        Description = "Test pattern 2"
        Features = @{
            ExceptionType = "System.IndexOutOfRangeException"
            ErrorId = "IndexOutOfRange"
            MessagePattern = "Test message pattern 2"
            ScriptContext = "Test-Script2.ps1"
            LinePattern = "Test line pattern 2"
        }
        FirstOccurrence = (Get-Date).AddDays(-5).ToString("yyyy-MM-ddTHH:mm:ss")
        LastOccurrence = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        Occurrences = 3
        Examples = @(
            @{
                Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                ErrorId = "IndexOutOfRange"
                Exception = "System.IndexOutOfRangeException"
                Message = "Test error message 2"
                ScriptName = "Test-Script2.ps1"
                ScriptLineNumber = 24
                Line = "Test line 2"
                PositionMessage = "At Test-Script2.ps1:24"
                StackTrace = "at <ScriptBlock>, Test-Script2.ps1: line 24"
                Context = "Test"
                Source = "Test"
                Tags = @("Test")
                CategoryInfo = "InvalidOperation"
            }
        )
        IsInedited = $false
        ValidationStatus = "Invalid"
        RelatedPatterns = @()
    }
)

# Tester la fonction Get-PatternFeatures
Write-Host "Tester Get-PatternFeatures:"
$features = Get-PatternFeatures -Pattern $patterns[0]
Write-Host "Features pour Pattern-1:"
$features | Format-Table -AutoSize

# Tester la fonction ConvertTo-NormalizedFeatures
Write-Host "`nTester ConvertTo-NormalizedFeatures:"
$normalizedPatterns = ConvertTo-NormalizedFeatures -Patterns $patterns
Write-Host "Patterns normalisÃ©s:"
$normalizedPatterns | ForEach-Object { Write-Host "Pattern: $($_.Name), Occurrences normalisÃ©es: $($_.Features.Occurrences)" }

# Tester la fonction Split-TrainingData
Write-Host "`nTester Split-TrainingData:"
$dataSets = Split-TrainingData -Patterns $normalizedPatterns -TrainingRatio 0.5
Write-Host "Ensemble d'entraÃ®nement: $($dataSets.TrainingSet.Count) patterns"
Write-Host "Ensemble de test: $($dataSets.TestSet.Count) patterns"

# Tester la fonction Start-ModelTraining
Write-Host "`nTester Start-ModelTraining:"
$model = Start-ModelTraining -TrainingSet $dataSets.TrainingSet -Iterations 5
Write-Host "ModÃ¨le entraÃ®nÃ©:"
Write-Host "Poids: $($model.Weights.Count) caractÃ©ristiques"
Write-Host "Biais: $($model.Bias)"
Write-Host "Taux d'apprentissage: $($model.LearningRate)"
Write-Host "ItÃ©rations: $($model.Iterations)"
Write-Host "PrÃ©cision d'entraÃ®nement: $($model.TrainingAccuracy)"

# Tester la fonction Get-PatternClass
Write-Host "`nTester Get-PatternClass:"
$prediction = Get-PatternClass -Model $model -Features $dataSets.TestSet[0].Features
Write-Host "PrÃ©diction pour $($dataSets.TestSet[0].Name): $prediction"

# Tester la fonction Test-ErrorModel
Write-Host "`nTester Test-ErrorModel:"
$metrics = Test-ErrorModel -Model $model -TestSet $dataSets.TestSet
Write-Host "MÃ©triques d'Ã©valuation:"
Write-Host "PrÃ©cision: $($metrics.Accuracy)"
Write-Host "Rappel: $($metrics.Recall)"
Write-Host "F1-Score: $($metrics.F1Score)"

# Tester la fonction Save-Model et Import-ErrorModel
Write-Host "`nTester Save-Model et Import-ErrorModel:"
$modelPath = Join-Path -Path $TestDrive -ChildPath "test_model.xml"
Save-Model -Model $model -ModelPath $modelPath
Write-Host "ModÃ¨le sauvegardÃ© dans $modelPath"

$loadedModel = Import-ErrorModel -ModelPath $modelPath
Write-Host "ModÃ¨le chargÃ©:"
Write-Host "Poids: $($loadedModel.Weights.Count) caractÃ©ristiques"
Write-Host "Biais: $($loadedModel.Bias)"
Write-Host "Taux d'apprentissage: $($loadedModel.LearningRate)"
Write-Host "ItÃ©rations: $($loadedModel.Iterations)"
Write-Host "PrÃ©cision d'entraÃ®nement: $($loadedModel.TrainingAccuracy)"

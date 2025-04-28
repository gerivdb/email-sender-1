# Importer le script
. (Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\Predict-ErrorCascades.ps1")

# CrÃ©er des donnÃ©es de test
$patterns = @(
    @{
        Id = "pattern1"
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
        RelatedPatterns = @("pattern2")
    },
    @{
        Id = "pattern2"
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
        RelatedPatterns = @("pattern3")
    },
    @{
        Id = "pattern3"
        Name = "Pattern-3"
        Description = "Test pattern 3"
        Features = @{
            ExceptionType = "System.ArgumentException"
            ErrorId = "ArgumentError"
            MessagePattern = "Test message pattern 3"
            ScriptContext = "Test-Script3.ps1"
            LinePattern = "Test line pattern 3"
        }
        FirstOccurrence = (Get-Date).AddDays(-2).ToString("yyyy-MM-ddTHH:mm:ss")
        LastOccurrence = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        Occurrences = 2
        Examples = @(
            @{
                Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                ErrorId = "ArgumentError"
                Exception = "System.ArgumentException"
                Message = "Test error message 3"
                ScriptName = "Test-Script3.ps1"
                ScriptLineNumber = 15
                Line = "Test line 3"
                PositionMessage = "At Test-Script3.ps1:15"
                StackTrace = "at <ScriptBlock>, Test-Script3.ps1: line 15"
                Context = "Test"
                Source = "Test"
                Tags = @("Test")
                CategoryInfo = "InvalidOperation"
            }
        )
        IsInedited = $true
        ValidationStatus = "Valid"
        RelatedPatterns = @()
    }
)

$correlations = @(
    @{
        PatternId1 = "pattern1"
        PatternId2 = "pattern2"
        Similarity = 0.8
        Relationship = "Similar"
        Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    },
    @{
        PatternId1 = "pattern2"
        PatternId2 = "pattern3"
        Similarity = 0.7
        Relationship = "Similar"
        Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    }
)

# Tester la fonction Build-ErrorDependencyGraph
Write-Host "Tester Build-ErrorDependencyGraph:"
$graph = Build-ErrorDependencyGraph -Patterns $patterns -Correlations $correlations -CorrelationThreshold 0.6
Write-Host "Graphe de dÃ©pendances:"
$graph.Keys | ForEach-Object {
    Write-Host "Pattern: $_, DÃ©pendances: $($graph[$_].Dependencies.Count)"
}

# Tester la fonction Get-RootPatterns
Write-Host "`nTester Get-RootPatterns:"
$rootPatterns = Get-RootPatterns -Graph $graph
Write-Host "Patterns racines: $($rootPatterns -join ', ')"

# Tester la fonction Get-LeafPatterns
Write-Host "`nTester Get-LeafPatterns:"
$leafPatterns = Get-LeafPatterns -Graph $graph
Write-Host "Patterns feuilles: $($leafPatterns -join ', ')"

# Tester la fonction Get-CascadePaths
Write-Host "`nTester Get-CascadePaths:"
$cascadePaths = Get-CascadePaths -Graph $graph -RootPatterns $rootPatterns
Write-Host "Chemins de cascade:"
$cascadePaths | ForEach-Object {
    Write-Host "Chemin: $($_ -join ' -> ')"
}

# Tester la fonction Measure-CascadeProbability
Write-Host "`nTester Measure-CascadeProbability:"
if ($cascadePaths.Count -gt 0) {
    $probability = Measure-CascadeProbability -Graph $graph -Path $cascadePaths[0]
    Write-Host "ProbabilitÃ© de cascade pour le chemin $($cascadePaths[0] -join ' -> '): $probability"
}

# Tester la fonction New-CascadePredictionReport
Write-Host "`nTester New-CascadePredictionReport:"
$reportPath = Join-Path -Path $PSScriptRoot -ChildPath "test_cascade_report.md"
$result = New-CascadePredictionReport -Graph $graph -CascadePaths $cascadePaths -ReportPath $reportPath
Write-Host "Rapport de prÃ©diction gÃ©nÃ©rÃ©: $result"

#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests de performance dans un environnement CI/CD.
.DESCRIPTION
    Ce script est conÃ§u pour Ãªtre exÃ©cutÃ© dans un pipeline CI/CD. Il exÃ©cute des tests
    de performance, compare les rÃ©sultats avec une rÃ©fÃ©rence, et fait Ã©chouer le build
    si des rÃ©gressions de performance sont dÃ©tectÃ©es.
.PARAMETER BaselinePath
    Chemin vers le fichier JSON de rÃ©sultats de rÃ©fÃ©rence. Si non spÃ©cifiÃ©, le script
    cherchera un fichier baseline.json dans le rÃ©pertoire de sortie.
.PARAMETER OutputDir
    RÃ©pertoire oÃ¹ enregistrer les rÃ©sultats des tests. Par dÃ©faut: "./perf-results".
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation du temps de rÃ©ponse considÃ©rÃ© comme une rÃ©gression.
    Par dÃ©faut: 10%.
.PARAMETER RpsThresholdPercent
    Pourcentage de diminution des requÃªtes par seconde considÃ©rÃ© comme une rÃ©gression.
    Par dÃ©faut: 10%.
.PARAMETER TestDuration
    DurÃ©e des tests en secondes. Par dÃ©faut: 30.
.PARAMETER Concurrency
    Nombre d'exÃ©cutions concurrentes. Par dÃ©faut: 3.
.PARAMETER UpdateBaseline
    Si spÃ©cifiÃ©, met Ã  jour le fichier de rÃ©fÃ©rence avec les rÃ©sultats actuels.
.PARAMETER GenerateReport
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.PARAMETER FailOnRegression
    Si spÃ©cifiÃ©, fait Ã©chouer le script si des rÃ©gressions sont dÃ©tectÃ©es.
.PARAMETER GitHubActions
    Si spÃ©cifiÃ©, gÃ©nÃ¨re des annotations pour GitHub Actions.
.PARAMETER AzureDevOps
    Si spÃ©cifiÃ©, gÃ©nÃ¨re des annotations pour Azure DevOps.
.EXAMPLE
    .\Invoke-CIPerfTest.ps1 -BaselinePath "baseline.json" -ThresholdPercent 5 -FailOnRegression
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$BaselinePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "./perf-results",
    
    [Parameter(Mandatory = $false)]
    [double]$ThresholdPercent = 10.0,
    
    [Parameter(Mandatory = $false)]
    [double]$RpsThresholdPercent = 10.0,
    
    [Parameter(Mandatory = $false)]
    [int]$TestDuration = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$Concurrency = 3,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateBaseline,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [switch]$FailOnRegression,
    
    [Parameter(Mandatory = $false)]
    [switch]$GitHubActions,
    
    [Parameter(Mandatory = $false)]
    [switch]$AzureDevOps
)

# Fonction pour crÃ©er une annotation GitHub Actions
function Write-GitHubAnnotation {
    param (
        [string]$Type,
        [string]$Message,
        [string]$File = "",
        [int]$Line = 0,
        [int]$Column = 0
    )
    
    if (-not $GitHubActions) {
        return
    }
    
    $annotation = "::$Type"
    
    if ($File -ne "") {
        $annotation += " file=$File"
        
        if ($Line -gt 0) {
            $annotation += ",line=$Line"
            
            if ($Column -gt 0) {
                $annotation += ",col=$Column"
            }
        }
    }
    
    $annotation += "::$Message"
    Write-Host $annotation
}

# Fonction pour crÃ©er une annotation Azure DevOps
function Write-AzureDevOpsAnnotation {
    param (
        [string]$Type,
        [string]$Message,
        [string]$File = "",
        [int]$Line = 0,
        [int]$Column = 0
    )
    
    if (-not $AzureDevOps) {
        return
    }
    
    $severity = switch ($Type) {
        "warning" { "warning" }
        "error" { "error" }
        default { "warning" }
    }
    
    $location = ""
    if ($File -ne "") {
        $location = "$File"
        
        if ($Line -gt 0) {
            $location += "($Line"
            
            if ($Column -gt 0) {
                $location += ",$Column"
            }
            
            $location += ")"
        }
    }
    
    if ($location -ne "") {
        Write-Host "##vso[task.logissue type=$severity;sourcepath=$File;linenumber=$Line;columnnumber=$Column]$Message"
    } else {
        Write-Host "##vso[task.logissue type=$severity]$Message"
    }
}

# Fonction pour Ã©crire un message de log avec annotations CI/CD
function Write-CILog {
    param (
        [string]$Message,
        [string]$Type = "info",
        [string]$File = "",
        [int]$Line = 0,
        [int]$Column = 0
    )
    
    switch ($Type) {
        "info" {
            Write-Host $Message -ForegroundColor Cyan
        }
        "warning" {
            Write-Host $Message -ForegroundColor Yellow
            Write-GitHubAnnotation -Type "warning" -Message $Message -File $File -Line $Line -Column $Column
            Write-AzureDevOpsAnnotation -Type "warning" -Message $Message -File $File -Line $Line -Column $Column
        }
        "error" {
            Write-Host $Message -ForegroundColor Red
            Write-GitHubAnnotation -Type "error" -Message $Message -File $File -Line $Line -Column $Column
            Write-AzureDevOpsAnnotation -Type "error" -Message $Message -File $File -Line $Line -Column $Column
        }
        "success" {
            Write-Host $Message -ForegroundColor Green
        }
    }
}

# Fonction pour dÃ©finir une variable de sortie GitHub Actions
function Set-GitHubOutput {
    param (
        [string]$Name,
        [string]$Value
    )
    
    if (-not $GitHubActions) {
        return
    }
    
    $githubOutput = $env:GITHUB_OUTPUT
    if ($githubOutput) {
        "$Name=$Value" | Out-File -FilePath $githubOutput -Encoding utf8 -Append
    } else {
        Write-Host "::set-output name=$Name::$Value"
    }
}

# Fonction pour dÃ©finir une variable de sortie Azure DevOps
function Set-AzureDevOpsVariable {
    param (
        [string]$Name,
        [string]$Value
    )
    
    if (-not $AzureDevOps) {
        return
    }
    
    Write-Host "##vso[task.setvariable variable=$Name;isOutput=true]$Value"
}

# Fonction pour dÃ©finir une variable de sortie CI
function Set-CIVariable {
    param (
        [string]$Name,
        [string]$Value
    )
    
    Set-GitHubOutput -Name $Name -Value $Value
    Set-AzureDevOpsVariable -Name $Name -Value $Value
}

# Fonction principale
function Main {
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDir)) {
        if ($PSCmdlet.ShouldProcess($OutputDir, "CrÃ©er le rÃ©pertoire")) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
            Write-CILog "RÃ©pertoire de sortie crÃ©Ã©: $OutputDir"
        }
    }
    
    # DÃ©finir les chemins des fichiers
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $currentResultsPath = Join-Path -Path $OutputDir -ChildPath "results_$timestamp.json"
    $summaryPath = Join-Path -Path $OutputDir -ChildPath "summary_$timestamp.md"
    $reportPath = Join-Path -Path $OutputDir -ChildPath "report_$timestamp.html"
    
    if (-not $BaselinePath) {
        $BaselinePath = Join-Path -Path $OutputDir -ChildPath "baseline.json"
        Write-CILog "Aucun fichier de rÃ©fÃ©rence spÃ©cifiÃ©, utilisation de: $BaselinePath"
    }
    
    # ExÃ©cuter les tests de performance
    Write-CILog "ExÃ©cution des tests de performance..."
    Write-CILog "  DurÃ©e: $TestDuration secondes"
    Write-CILog "  Concurrence: $Concurrency"
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Simple-PRLoadTest.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-CILog "Script de test de performance non trouvÃ©: $scriptPath" -Type "error"
        exit 1
    }
    
    try {
        & $scriptPath -Duration $TestDuration -Concurrency $Concurrency -OutputPath $currentResultsPath -Verbose
        
        if (-not (Test-Path -Path $currentResultsPath)) {
            Write-CILog "Les tests de performance n'ont pas gÃ©nÃ©rÃ© de rÃ©sultats." -Type "error"
            exit 1
        }
        
        Write-CILog "Tests de performance terminÃ©s. RÃ©sultats enregistrÃ©s: $currentResultsPath" -Type "success"
    }
    catch {
        Write-CILog "Erreur lors de l'exÃ©cution des tests de performance: $_" -Type "error"
        exit 1
    }
    
    # Charger les rÃ©sultats actuels
    $currentResults = Get-Content -Path $currentResultsPath -Raw | ConvertFrom-Json
    
    # VÃ©rifier si un fichier de rÃ©fÃ©rence existe
    $hasBaseline = Test-Path -Path $BaselinePath
    $comparisonResults = $null
    
    if ($hasBaseline) {
        Write-CILog "Comparaison avec le fichier de rÃ©fÃ©rence: $BaselinePath"
        
        try {
            $baselineResults = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
            
            # Comparer les rÃ©sultats
            $avgResponseTimeDiff = ($currentResults.AvgResponseMs - $baselineResults.AvgResponseMs) / $baselineResults.AvgResponseMs * 100
            $p95ResponseTimeDiff = ($currentResults.P95ResponseMs - $baselineResults.P95ResponseMs) / $baselineResults.P95ResponseMs * 100
            $rpsCurrentValue = if ($currentResults.PSObject.Properties.Name -contains "RequestsPerSecond") { $currentResults.RequestsPerSecond } else { $currentResults.TotalRequests / $currentResults.TotalExecTime }
            $rpsBaselineValue = if ($baselineResults.PSObject.Properties.Name -contains "RequestsPerSecond") { $baselineResults.RequestsPerSecond } else { $baselineResults.TotalRequests / $baselineResults.TotalExecTime }
            $rpsDiff = ($rpsCurrentValue - $rpsBaselineValue) / $rpsBaselineValue * 100
            
            $comparisonResults = [PSCustomObject]@{
                AvgResponseTimeDiff = $avgResponseTimeDiff
                P95ResponseTimeDiff = $p95ResponseTimeDiff
                RpsDiff = $rpsDiff
                HasRegression = $false
                Regressions = @()
            }
            
            # VÃ©rifier les rÃ©gressions
            if ($avgResponseTimeDiff -gt $ThresholdPercent) {
                $message = "RÃ©gression dÃ©tectÃ©e: Temps de rÃ©ponse moyen augmentÃ© de $([Math]::Round($avgResponseTimeDiff, 2))% (seuil: $ThresholdPercent%)"
                Write-CILog $message -Type "warning"
                $comparisonResults.Regressions += $message
                $comparisonResults.HasRegression = $true
            }
            
            if ($p95ResponseTimeDiff -gt $ThresholdPercent) {
                $message = "RÃ©gression dÃ©tectÃ©e: P95 augmentÃ© de $([Math]::Round($p95ResponseTimeDiff, 2))% (seuil: $ThresholdPercent%)"
                Write-CILog $message -Type "warning"
                $comparisonResults.Regressions += $message
                $comparisonResults.HasRegression = $true
            }
            
            if ($rpsDiff -lt -$RpsThresholdPercent) {
                $message = "RÃ©gression dÃ©tectÃ©e: RequÃªtes par seconde diminuÃ©es de $([Math]::Round(-$rpsDiff, 2))% (seuil: $RpsThresholdPercent%)"
                Write-CILog $message -Type "warning"
                $comparisonResults.Regressions += $message
                $comparisonResults.HasRegression = $true
            }
            
            if (-not $comparisonResults.HasRegression) {
                Write-CILog "Aucune rÃ©gression dÃ©tectÃ©e." -Type "success"
            }
        }
        catch {
            Write-CILog "Erreur lors de la comparaison des rÃ©sultats: $_" -Type "error"
        }
    }
    else {
        Write-CILog "Aucun fichier de rÃ©fÃ©rence trouvÃ©. Impossible de dÃ©tecter les rÃ©gressions."
    }
    
    # Mettre Ã  jour le fichier de rÃ©fÃ©rence si demandÃ©
    if ($UpdateBaseline -or (-not $hasBaseline)) {
        if ($PSCmdlet.ShouldProcess($BaselinePath, "Mettre Ã  jour le fichier de rÃ©fÃ©rence")) {
            Copy-Item -Path $currentResultsPath -Destination $BaselinePath -Force
            Write-CILog "Fichier de rÃ©fÃ©rence mis Ã  jour: $BaselinePath" -Type "success"
        }
    }
    
    # GÃ©nÃ©rer un rapport HTML si demandÃ©
    if ($GenerateReport) {
        Write-CILog "GÃ©nÃ©ration du rapport HTML..."
        
        $reportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-PerformanceReport.ps1"
        
        if (Test-Path -Path $reportScriptPath) {
            try {
                if ($hasBaseline) {
                    & $reportScriptPath -ResultsPath @($BaselinePath, $currentResultsPath) -OutputPath $reportPath -Title "Rapport de performance CI/CD" -CompareMode
                }
                else {
                    & $reportScriptPath -ResultsPath $currentResultsPath -OutputPath $reportPath -Title "Rapport de performance CI/CD"
                }
                
                Write-CILog "Rapport HTML gÃ©nÃ©rÃ©: $reportPath" -Type "success"
            }
            catch {
                Write-CILog "Erreur lors de la gÃ©nÃ©ration du rapport HTML: $_" -Type "error"
            }
        }
        else {
            Write-CILog "Script de gÃ©nÃ©ration de rapport non trouvÃ©: $reportScriptPath" -Type "warning"
        }
    }
    
    # GÃ©nÃ©rer un rÃ©sumÃ© Markdown
    $summary = @"
# RÃ©sumÃ© des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- DurÃ©e: $TestDuration secondes
- Concurrence: $Concurrency
- Seuil de rÃ©gression (temps de rÃ©ponse): $ThresholdPercent%
- Seuil de rÃ©gression (RPS): $RpsThresholdPercent%

## RÃ©sultats actuels

- RequÃªtes totales: $($currentResults.TotalRequests)
- RequÃªtes par seconde: $([Math]::Round($currentResults.RequestsPerSecond, 2))
- Temps de rÃ©ponse moyen: $([Math]::Round($currentResults.AvgResponseMs, 2)) ms
- P95: $([Math]::Round($currentResults.P95ResponseMs, 2)) ms

"@

    if ($comparisonResults) {
        $summary += @"
## Comparaison avec la rÃ©fÃ©rence

- DiffÃ©rence de temps de rÃ©ponse moyen: $([Math]::Round($comparisonResults.AvgResponseTimeDiff, 2))%
- DiffÃ©rence de P95: $([Math]::Round($comparisonResults.P95ResponseTimeDiff, 2))%
- DiffÃ©rence de requÃªtes par seconde: $([Math]::Round($comparisonResults.RpsDiff, 2))%

"@

        if ($comparisonResults.HasRegression) {
            $summary += "## RÃ©gressions dÃ©tectÃ©es\n\n"
            
            foreach ($regression in $comparisonResults.Regressions) {
                $summary += "- $regression\n"
            }
        }
        else {
            $summary += "## Aucune rÃ©gression dÃ©tectÃ©e\n"
        }
    }
    
    $summary += @"

## Fichiers gÃ©nÃ©rÃ©s

- RÃ©sultats: $currentResultsPath
"@

    if ($GenerateReport) {
        $summary += @"
- Rapport HTML: $reportPath
"@
    }
    
    $summary | Set-Content -Path $summaryPath -Encoding UTF8
    Write-CILog "RÃ©sumÃ© gÃ©nÃ©rÃ©: $summaryPath"
    
    # DÃ©finir les variables de sortie CI
    Set-CIVariable -Name "perf_test_results_path" -Value $currentResultsPath
    Set-CIVariable -Name "perf_test_summary_path" -Value $summaryPath
    
    if ($GenerateReport) {
        Set-CIVariable -Name "perf_test_report_path" -Value $reportPath
    }
    
    if ($comparisonResults -and $comparisonResults.HasRegression) {
        Set-CIVariable -Name "perf_test_has_regression" -Value "true"
        
        if ($FailOnRegression) {
            Write-CILog "Des rÃ©gressions de performance ont Ã©tÃ© dÃ©tectÃ©es. Le pipeline a Ã©chouÃ©." -Type "error"
            exit 1
        }
    }
    else {
        Set-CIVariable -Name "perf_test_has_regression" -Value "false"
    }
    
    Write-CILog "Tests de performance CI/CD terminÃ©s avec succÃ¨s." -Type "success"
}

# ExÃ©cuter le script
Main

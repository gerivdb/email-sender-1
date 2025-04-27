#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure les performances du systÃ¨me d'analyse des pull requests.

.DESCRIPTION
    Ce script mesure les performances du systÃ¨me d'analyse des pull requests
    en collectant des mÃ©triques sur les temps d'exÃ©cution, la prÃ©cision des
    dÃ©tections d'erreurs et l'utilisation des ressources.

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t de test.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numÃ©ro de la pull request Ã  analyser.
    Si non spÃ©cifiÃ©, la derniÃ¨re pull request sera utilisÃ©e.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer le rapport de performances.
    Par dÃ©faut: "reports\pr-analysis"

.PARAMETER DetailedReport
    Indique s'il faut gÃ©nÃ©rer un rapport dÃ©taillÃ©.
    Par dÃ©faut: $true

.EXAMPLE
    .\Measure-PRAnalysisPerformance.ps1
    Mesure les performances de l'analyse de la derniÃ¨re pull request.

.EXAMPLE
    .\Measure-PRAnalysisPerformance.ps1 -PullRequestNumber 42 -DetailedReport $true
    Mesure les performances de l'analyse de la pull request #42 et gÃ©nÃ¨re un rapport dÃ©taillÃ©.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",

    [Parameter()]
    [int]$PullRequestNumber = 0,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis",

    [Parameter()]
    [bool]$DetailedReport = $true
)

# Fonction pour obtenir les informations sur la pull request
function Get-PullRequestInfo {
    param (
        [string]$RepositoryPath,
        [int]$PullRequestNumber
    )

    Write-Host "RÃ©cupÃ©ration des informations sur la pull request..." -ForegroundColor Cyan

    Push-Location $RepositoryPath
    try {
        # VÃ©rifier si gh CLI est installÃ©
        $ghInstalled = $null -ne (Get-Command -Name gh -ErrorAction SilentlyContinue)

        if (-not $ghInstalled) {
            Write-Warning "GitHub CLI (gh) n'est pas installÃ©. Impossible de rÃ©cupÃ©rer les informations sur la pull request."
            return $null
        }

        # Si aucun numÃ©ro de PR n'est spÃ©cifiÃ©, obtenir la derniÃ¨re PR
        if ($PullRequestNumber -eq 0) {
            $prList = gh pr list --limit 1 --json number, title, headRefName, baseRefName, createdAt | ConvertFrom-Json

            if ($prList.Count -eq 0) {
                Write-Warning "Aucune pull request trouvÃ©e."
                return $null
            }

            $pr = $prList[0]
            $PullRequestNumber = $pr.number
        } else {
            $pr = gh pr view $PullRequestNumber --json number, title, headRefName, baseRefName, createdAt | ConvertFrom-Json

            if ($null -eq $pr) {
                Write-Warning "Pull request #$PullRequestNumber non trouvÃ©e."
                return $null
            }
        }

        # Obtenir les fichiers modifiÃ©s
        $files = gh pr view $PullRequestNumber --json files | ConvertFrom-Json

        # CrÃ©er l'objet d'informations sur la PR
        $prInfo = [PSCustomObject]@{
            Number     = $pr.number
            Title      = $pr.title
            HeadBranch = $pr.headRefName
            BaseBranch = $pr.baseRefName
            CreatedAt  = $pr.createdAt
            Files      = $files.files
            FileCount  = $files.files.Count
            Additions  = ($files.files | Measure-Object additions -Sum).Sum
            Deletions  = ($files.files | Measure-Object deletions -Sum).Sum
            Changes    = ($files.files | Measure-Object additions, deletions -Sum).Sum
        }

        Write-Host "Informations rÃ©cupÃ©rÃ©es pour la pull request #$($prInfo.Number): $($prInfo.Title)" -ForegroundColor Green
        return $prInfo
    } catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration des informations sur la pull request: $_"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour exÃ©cuter l'analyse de la pull request
function Invoke-PRAnalysis {
    param (
        [PSCustomObject]$PullRequestInfo
    )

    Write-Host "ExÃ©cution de l'analyse de la pull request #$($PullRequestInfo.Number)..." -ForegroundColor Cyan

    # CrÃ©er un objet pour stocker les mÃ©triques
    $metrics = [PSCustomObject]@{
        PullRequestNumber       = $PullRequestInfo.Number
        StartTime               = Get-Date
        EndTime                 = $null
        TotalDuration           = $null
        FileAnalysisDurations   = @()
        ErrorsDetected          = @()
        ErrorCount              = 0
        MemoryUsageBefore       = [System.GC]::GetTotalMemory($true)
        MemoryUsageAfter        = $null
        MemoryUsageDelta        = $null
        CPUUsage                = @()
        AverageFileAnalysisTime = $null
        MaxFileAnalysisTime     = $null
        MinFileAnalysisTime     = $null
    }

    # Simuler l'analyse de chaque fichier
    foreach ($file in $PullRequestInfo.Files) {
        if ($file.path -like "*.ps1") {
            Write-Host "  Analyse du fichier: $($file.path)" -ForegroundColor Yellow

            # Mesurer le temps d'analyse
            $startTime = Get-Date

            # Simuler l'analyse du fichier
            $analysisResult = Invoke-FileAnalysis -FilePath $file.path -PullRequestInfo $PullRequestInfo

            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalMilliseconds

            # Enregistrer les mÃ©triques
            $metrics.FileAnalysisDurations += [PSCustomObject]@{
                FilePath  = $file.path
                Duration  = $duration
                Additions = $file.additions
                Deletions = $file.deletions
                Changes   = $file.additions + $file.deletions
            }

            # Enregistrer les erreurs dÃ©tectÃ©es
            $metrics.ErrorsDetected += $analysisResult
            $metrics.ErrorCount += $analysisResult.Count

            # Mesurer l'utilisation du CPU
            $cpuUsage = Get-Process -Id $PID | Select-Object -ExpandProperty CPU
            $metrics.CPUUsage += $cpuUsage

            Write-Host "    Analyse terminÃ©e en $([Math]::Round($duration, 2)) ms, $($analysisResult.Count) erreurs dÃ©tectÃ©es." -ForegroundColor Yellow
        }
    }

    # Finaliser les mÃ©triques
    $metrics.EndTime = Get-Date
    $metrics.TotalDuration = ($metrics.EndTime - $metrics.StartTime).TotalMilliseconds
    $metrics.MemoryUsageAfter = [System.GC]::GetTotalMemory($true)
    $metrics.MemoryUsageDelta = $metrics.MemoryUsageAfter - $metrics.MemoryUsageBefore

    # Calculer les statistiques
    if ($metrics.FileAnalysisDurations.Count -gt 0) {
        $metrics.AverageFileAnalysisTime = ($metrics.FileAnalysisDurations | Measure-Object -Property Duration -Average).Average
        $metrics.MaxFileAnalysisTime = ($metrics.FileAnalysisDurations | Measure-Object -Property Duration -Maximum).Maximum
        $metrics.MinFileAnalysisTime = ($metrics.FileAnalysisDurations | Measure-Object -Property Duration -Minimum).Minimum
    }

    Write-Host "Analyse terminÃ©e en $([Math]::Round($metrics.TotalDuration, 2)) ms, $($metrics.ErrorCount) erreurs dÃ©tectÃ©es au total." -ForegroundColor Green

    return $metrics
}

# Fonction pour simuler l'analyse d'un fichier
function Invoke-FileAnalysis {
    param (
        [string]$FilePath,
        [PSCustomObject]$PullRequestInfo
    )

    # Cette fonction simule l'analyse d'un fichier et retourne des erreurs dÃ©tectÃ©es
    # Dans une implÃ©mentation rÃ©elle, elle appellerait le vÃ©ritable analyseur de code

    # Simuler un dÃ©lai d'analyse proportionnel Ã  la taille du fichier
    $fileSize = ($PullRequestInfo.Files | Where-Object { $_.path -eq $FilePath } | Select-Object -First 1)
    $delay = [Math]::Max(100, ($fileSize.additions + $fileSize.deletions) * 5)
    Start-Sleep -Milliseconds $delay

    # Simuler la dÃ©tection d'erreurs
    $errorTypes = @("Syntax", "Style", "Performance", "Security")
    $errorCount = Get-Random -Minimum 0 -Maximum 10

    $errors = @()

    for ($i = 0; $i -lt $errorCount; $i++) {
        $errorType = $errorTypes | Get-Random
        $lineNumber = Get-Random -Minimum 1 -Maximum 100

        $errors += [PSCustomObject]@{
            FilePath   = $FilePath
            LineNumber = $lineNumber
            ErrorType  = $errorType
            Message    = "Simulated $errorType error at line $lineNumber"
            Severity   = switch ($errorType) {
                "Syntax" { "Error" }
                "Security" { "Error" }
                "Performance" { "Warning" }
                "Style" { "Information" }
                default { "Warning" }
            }
        }
    }

    return $errors
}

# Fonction pour gÃ©nÃ©rer un rapport de performances
function New-PerformanceReport {
    param (
        [PSCustomObject]$Metrics,
        [PSCustomObject]$PullRequestInfo,
        [string]$OutputPath,
        [bool]$DetailedReport
    )

    Write-Host "GÃ©nÃ©ration du rapport de performances..." -ForegroundColor Cyan

    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    # DÃ©finir le chemin du rapport
    $reportPath = Join-Path -Path $OutputPath -ChildPath "PR-$($PullRequestInfo.Number)-Analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

    # GÃ©nÃ©rer le contenu du rapport
    $reportContent = @"
# Rapport d'analyse de performance - Pull Request #$($PullRequestInfo.Number)

## Informations sur la Pull Request

- **Titre**: $($PullRequestInfo.Title)
- **Branche source**: $($PullRequestInfo.HeadBranch)
- **Branche cible**: $($PullRequestInfo.BaseBranch)
- **CrÃ©Ã©e le**: $($PullRequestInfo.CreatedAt)
- **Nombre de fichiers**: $($PullRequestInfo.FileCount)
- **Ajouts**: $($PullRequestInfo.Additions) lignes
- **Suppressions**: $($PullRequestInfo.Deletions) lignes
- **Modifications totales**: $($PullRequestInfo.Changes) lignes

## RÃ©sumÃ© des performances

- **DurÃ©e totale de l'analyse**: $([Math]::Round($Metrics.TotalDuration, 2)) ms
- **Nombre d'erreurs dÃ©tectÃ©es**: $($Metrics.ErrorCount)
- **Temps moyen par fichier**: $([Math]::Round($Metrics.AverageFileAnalysisTime, 2)) ms
- **Temps maximum par fichier**: $([Math]::Round($Metrics.MaxFileAnalysisTime, 2)) ms
- **Temps minimum par fichier**: $([Math]::Round($Metrics.MinFileAnalysisTime, 2)) ms
- **Utilisation mÃ©moire**: $([Math]::Round($Metrics.MemoryUsageDelta / 1MB, 2)) MB

## RÃ©partition des erreurs par type

$(
    $errorsByType = $Metrics.ErrorsDetected | Group-Object -Property ErrorType
    $errorsByType | ForEach-Object {
        "- **$($_.Name)**: $($_.Count) erreurs"
    }
)

## RÃ©partition des erreurs par sÃ©vÃ©ritÃ©

$(
    $errorsBySeverity = $Metrics.ErrorsDetected | Group-Object -Property Severity
    $errorsBySeverity | ForEach-Object {
        "- **$($_.Name)**: $($_.Count) erreurs"
    }
)

"@

    # Ajouter les dÃ©tails si demandÃ©
    if ($DetailedReport) {
        $reportContent += @"

## DÃ©tails des performances par fichier

| Fichier | DurÃ©e (ms) | Ajouts | Suppressions | Erreurs |
|---------|------------|--------|--------------|---------|
$(
    $Metrics.FileAnalysisDurations | ForEach-Object {
        $fileErrors = ($Metrics.ErrorsDetected | Where-Object { $_.FilePath -eq $_.FilePath }).Count
        "| $($_.FilePath) | $([Math]::Round($_.Duration, 2)) | $($_.Additions) | $($_.Deletions) | $fileErrors |"
    }
)

## DÃ©tails des erreurs dÃ©tectÃ©es

$(
    $Metrics.ErrorsDetected | ForEach-Object {
        "### $($_.FilePath):$($_.LineNumber) - $($_.ErrorType) ($($_.Severity))`n`n$($_.Message)`n"
    }
)

"@
    }

    # Ajouter les recommandations
    $reportContent += @"

## Recommandations

$(
    if ($Metrics.AverageFileAnalysisTime -gt 1000) {
        "- **Optimisation des performances**: Le temps moyen d'analyse par fichier est Ã©levÃ©. Envisagez d'optimiser l'algorithme d'analyse ou d'implÃ©menter un systÃ¨me de cache."
    }

    if ($Metrics.ErrorCount -gt 20) {
        "- **AmÃ©lioration de la qualitÃ© du code**: Un nombre Ã©levÃ© d'erreurs a Ã©tÃ© dÃ©tectÃ©. Envisagez d'implÃ©menter des vÃ©rifications prÃ©-commit pour rÃ©duire le nombre d'erreurs."
    }

    if ($Metrics.MemoryUsageDelta / 1MB -gt 100) {
        "- **Optimisation de la mÃ©moire**: L'utilisation de la mÃ©moire est Ã©levÃ©e. Envisagez d'optimiser la gestion de la mÃ©moire dans l'analyseur."
    }
)

## Conclusion

Cette analyse a Ã©tÃ© gÃ©nÃ©rÃ©e automatiquement par Measure-PRAnalysisPerformance.ps1 le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss").
"@

    # Ã‰crire le rapport dans le fichier
    Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8

    Write-Host "Rapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green

    return $reportPath
}

# Fonction principale
function Measure-PRAnalysisPerformance {
    # Obtenir les informations sur la pull request
    $prInfo = Get-PullRequestInfo -RepositoryPath $RepositoryPath -PullRequestNumber $PullRequestNumber

    if ($null -eq $prInfo) {
        return
    }

    # ExÃ©cuter l'analyse
    $metrics = Invoke-PRAnalysis -PullRequestInfo $prInfo

    # GÃ©nÃ©rer le rapport
    $reportPath = New-PerformanceReport -Metrics $metrics -PullRequestInfo $prInfo -OutputPath $OutputPath -DetailedReport $DetailedReport

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de l'analyse:" -ForegroundColor Cyan
    Write-Host "  Pull Request: #$($prInfo.Number) - $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Fichiers analysÃ©s: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  DurÃ©e totale: $([Math]::Round($metrics.TotalDuration, 2)) ms" -ForegroundColor White
    Write-Host "  Erreurs dÃ©tectÃ©es: $($metrics.ErrorCount)" -ForegroundColor White
    Write-Host "  Rapport: $reportPath" -ForegroundColor White
}

# Exporter la fonction principale
Export-ModuleMember -Function Measure-PRAnalysisPerformance

# Si le script est exÃ©cutÃ© directement (pas importÃ© comme module)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # ExÃ©cuter la fonction principale
    Measure-PRAnalysisPerformance
}

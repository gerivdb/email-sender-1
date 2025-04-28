#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©marre le profilage du systÃ¨me d'analyse des pull requests.

.DESCRIPTION
    Ce script lance un profilage complet du systÃ¨me d'analyse des pull requests
    pour identifier les goulots d'Ã©tranglement et les opportunitÃ©s d'optimisation.
    Il prend en charge plusieurs types de traceurs et gÃ©nÃ¨re des rapports dÃ©taillÃ©s.

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t Ã  analyser.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numÃ©ro de la pull request Ã  analyser.
    Si non spÃ©cifiÃ©, la derniÃ¨re pull request sera utilisÃ©e.

.PARAMETER TracerTypes
    Les types de traceurs Ã  utiliser pour le profilage.
    Valeurs possibles: "CPU", "Memory", "IO", "All"
    Par dÃ©faut: "All"

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rÃ©sultats du profilage.
    Par dÃ©faut: "reports\pr-analysis\profiling"

.PARAMETER DetailLevel
    Le niveau de dÃ©tail du profilage.
    Valeurs possibles: "Basic", "Detailed", "Comprehensive"
    Par dÃ©faut: "Detailed"

.PARAMETER GenerateFlameGraph
    Indique s'il faut gÃ©nÃ©rer un graphique de flamme (flamegraph).
    Par dÃ©faut: $true

.EXAMPLE
    .\Start-PRAnalysisProfiler.ps1
    DÃ©marre le profilage de la derniÃ¨re pull request avec tous les traceurs.

.EXAMPLE
    .\Start-PRAnalysisProfiler.ps1 -PullRequestNumber 42 -TracerTypes "CPU", "Memory" -DetailLevel "Comprehensive"
    DÃ©marre un profilage dÃ©taillÃ© de la pull request #42 avec les traceurs CPU et mÃ©moire.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",

    [Parameter()]
    [int]$PullRequestNumber = 0,

    [Parameter()]
    [ValidateSet("CPU", "Memory", "IO", "All")]
    [string[]]$TracerTypes = @("All"),

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis\profiling",

    [Parameter()]
    [ValidateSet("Basic", "Detailed", "Comprehensive")]
    [string]$DetailLevel = "Detailed",

    [Parameter()]
    [bool]$GenerateFlameGraph = $true
)

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\PRPerformanceTracer.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module PRPerformanceTracer non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# Fonction pour obtenir les informations sur la pull request
function Get-PullRequestInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,
        
        [Parameter()]
        [int]$PRNumber = 0
    )

    try {
        # VÃ©rifier si le dÃ©pÃ´t existe
        if (-not (Test-Path -Path $RepoPath)) {
            throw "Le dÃ©pÃ´t n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $RepoPath"
        }

        # Changer de rÃ©pertoire vers le dÃ©pÃ´t
        Push-Location -Path $RepoPath

        try {
            # Si aucun numÃ©ro de PR n'est spÃ©cifiÃ©, utiliser la derniÃ¨re PR
            if ($PRNumber -eq 0) {
                $prs = gh pr list --json number,title,headRefName,baseRefName,createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvÃ©e dans le dÃ©pÃ´t."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number,title,headRefName,baseRefName,createdAt | ConvertFrom-Json
                if ($null -eq $pr) {
                    throw "Pull request #$PRNumber non trouvÃ©e."
                }
            }

            # Obtenir les fichiers modifiÃ©s
            $files = gh pr view $pr.number --json files | ConvertFrom-Json

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

            return $prInfo
        } finally {
            # Revenir au rÃ©pertoire prÃ©cÃ©dent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration des informations sur la pull request: $_"
        return $null
    }
}

# Fonction pour dÃ©marrer le profilage
function Start-Profiling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PullRequestInfo,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Tracers,
        
        [Parameter(Mandatory = $true)]
        [string]$Detail,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )

    try {
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }

        # DÃ©terminer les traceurs Ã  utiliser
        $enabledTracers = @()
        if ($Tracers -contains "All") {
            $enabledTracers = @("CPU", "Memory", "IO")
        } else {
            $enabledTracers = $Tracers
        }

        Write-Host "DÃ©marrage du profilage de la pull request #$($PullRequestInfo.Number) avec les traceurs: $($enabledTracers -join ', ')" -ForegroundColor Cyan

        # Initialiser le traceur de performance
        $tracer = New-PRPerformanceTracer -TracerTypes $enabledTracers -DetailLevel $Detail -OutputPath $OutputDir

        # DÃ©marrer le traÃ§age
        $tracer.Start()

        # Simuler l'analyse de la pull request
        $analysisResults = Invoke-PRAnalysisWithTracing -PullRequestInfo $PullRequestInfo -Tracer $tracer

        # ArrÃªter le traÃ§age
        $tracer.Stop()

        # GÃ©nÃ©rer le rapport de performance
        $reportPath = Join-Path -Path $OutputDir -ChildPath "performance_report_pr$($PullRequestInfo.Number).html"
        $report = Export-PRPerformanceReport -Tracer $tracer -OutputPath $reportPath -PullRequestInfo $PullRequestInfo

        # GÃ©nÃ©rer le flamegraph si demandÃ©
        if ($GenerateFlameGraph) {
            $flamegraphPath = Join-Path -Path $OutputDir -ChildPath "flamegraph_pr$($PullRequestInfo.Number).html"
            Export-PRPerformanceFlameGraph -Tracer $tracer -OutputPath $flamegraphPath
        }

        # Mesurer l'utilisation des ressources
        $resourceUsagePath = Join-Path -Path $OutputDir -ChildPath "resource_usage_pr$($PullRequestInfo.Number).json"
        Measure-PRResourceUsage -Tracer $tracer -OutputPath $resourceUsagePath

        return @{
            Tracer = $tracer
            Report = $report
            AnalysisResults = $analysisResults
        }
    } catch {
        Write-Error "Erreur lors du profilage: $_"
        return $null
    }
}

# Fonction pour simuler l'analyse d'une pull request avec traÃ§age
function Invoke-PRAnalysisWithTracing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PullRequestInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Tracer
    )

    try {
        Write-Host "ExÃ©cution de l'analyse de la pull request #$($PullRequestInfo.Number) avec traÃ§age..." -ForegroundColor Yellow

        # CrÃ©er un objet pour stocker les rÃ©sultats
        $results = [PSCustomObject]@{
            PullRequestNumber = $PullRequestInfo.Number
            FileResults = @()
            TotalIssues = 0
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
        }

        # DÃ©marrer le traÃ§age de l'opÃ©ration principale
        $Tracer.StartOperation("AnalysePR", "Analyse complÃ¨te de la PR #$($PullRequestInfo.Number)")

        # Analyser chaque fichier
        foreach ($file in $PullRequestInfo.Files) {
            # DÃ©marrer le traÃ§age pour ce fichier
            $Tracer.StartOperation("AnalyseFichier", "Analyse du fichier: $($file.path)")

            # Simuler l'analyse du fichier
            $fileResult = Invoke-FileAnalysisWithTracing -FilePath $file.path -PullRequestInfo $PullRequestInfo -Tracer $Tracer

            # Ajouter les rÃ©sultats
            $results.FileResults += $fileResult
            $results.TotalIssues += $fileResult.Issues.Count

            # ArrÃªter le traÃ§age pour ce fichier
            $Tracer.StopOperation("AnalyseFichier")
        }

        # Finaliser les rÃ©sultats
        $results.EndTime = Get-Date
        $results.Duration = $results.EndTime - $results.StartTime

        # ArrÃªter le traÃ§age de l'opÃ©ration principale
        $Tracer.StopOperation("AnalysePR")

        return $results
    } catch {
        Write-Error "Erreur lors de l'analyse avec traÃ§age: $_"
        return $null
    }
}

# Fonction pour simuler l'analyse d'un fichier avec traÃ§age
function Invoke-FileAnalysisWithTracing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PullRequestInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Tracer
    )

    try {
        # CrÃ©er un objet pour stocker les rÃ©sultats
        $fileResult = [PSCustomObject]@{
            FilePath = $FilePath
            Issues = @()
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
        }

        # Simuler diffÃ©rentes Ã©tapes d'analyse avec traÃ§age
        
        # 1. Lecture du fichier
        $Tracer.StartOperation("LectureFichier", "Lecture du fichier: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50) # Simuler le temps de lecture
        $Tracer.StopOperation("LectureFichier")

        # 2. Analyse syntaxique
        $Tracer.StartOperation("AnalyseSyntaxique", "Analyse syntaxique: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200) # Simuler le temps d'analyse
        
        # Simuler la dÃ©tection d'erreurs syntaxiques
        $syntaxIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 7) {
            $syntaxIssues = Get-Random -Minimum 1 -Maximum 3
            for ($i = 0; $i -lt $syntaxIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Syntax"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "Erreur de syntaxe: $((Get-Random -InputObject @("ParenthÃ¨se manquante", "Accolade non fermÃ©e", "Point-virgule manquant")))"
                    Severity = "Error"
                }
            }
        }
        $Tracer.StopOperation("AnalyseSyntaxique")

        # 3. Analyse de style
        $Tracer.StartOperation("AnalyseStyle", "Analyse de style: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 30 -Maximum 150) # Simuler le temps d'analyse
        
        # Simuler la dÃ©tection de problÃ¨mes de style
        $styleIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 5) {
            $styleIssues = Get-Random -Minimum 1 -Maximum 5
            for ($i = 0; $i -lt $styleIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Style"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "ProblÃ¨me de style: $((Get-Random -InputObject @("Indentation incorrecte", "Ligne trop longue", "Nom de variable non conforme")))"
                    Severity = "Warning"
                }
            }
        }
        $Tracer.StopOperation("AnalyseStyle")

        # 4. Analyse de performance
        $Tracer.StartOperation("AnalysePerformance", "Analyse de performance: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 40 -Maximum 180) # Simuler le temps d'analyse
        
        # Simuler la dÃ©tection de problÃ¨mes de performance
        $perfIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 6) {
            $perfIssues = Get-Random -Minimum 1 -Maximum 3
            for ($i = 0; $i -lt $perfIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Performance"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "ProblÃ¨me de performance: $((Get-Random -InputObject @("Boucle inefficace", "Allocation mÃ©moire excessive", "OpÃ©ration I/O dans une boucle")))"
                    Severity = "Warning"
                }
            }
        }
        $Tracer.StopOperation("AnalysePerformance")

        # 5. Analyse de sÃ©curitÃ©
        $Tracer.StartOperation("AnalyseSÃ©curitÃ©", "Analyse de sÃ©curitÃ©: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 60 -Maximum 250) # Simuler le temps d'analyse
        
        # Simuler la dÃ©tection de problÃ¨mes de sÃ©curitÃ©
        $secIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 8) {
            $secIssues = Get-Random -Minimum 1 -Maximum 2
            for ($i = 0; $i -lt $secIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Security"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "ProblÃ¨me de sÃ©curitÃ©: $((Get-Random -InputObject @("Injection possible", "Identifiants en clair", "Validation d'entrÃ©e manquante")))"
                    Severity = "Critical"
                }
            }
        }
        $Tracer.StopOperation("AnalyseSÃ©curitÃ©")

        # Finaliser les rÃ©sultats
        $fileResult.EndTime = Get-Date
        $fileResult.Duration = $fileResult.EndTime - $fileResult.StartTime

        return $fileResult
    } catch {
        Write-Error "Erreur lors de l'analyse du fichier avec traÃ§age: $_"
        return $null
    }
}

# Point d'entrÃ©e principal
try {
    # Obtenir les informations sur la pull request
    $prInfo = Get-PullRequestInfo -RepoPath $RepositoryPath -PRNumber $PullRequestNumber
    if ($null -eq $prInfo) {
        Write-Error "Impossible d'obtenir les informations sur la pull request."
        exit 1
    }

    # Afficher les informations sur la pull request
    Write-Host "Informations sur la pull request:" -ForegroundColor Cyan
    Write-Host "  NumÃ©ro: #$($prInfo.Number)" -ForegroundColor White
    Write-Host "  Titre: $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Branche source: $($prInfo.HeadBranch)" -ForegroundColor White
    Write-Host "  Branche cible: $($prInfo.BaseBranch)" -ForegroundColor White
    Write-Host "  Fichiers modifiÃ©s: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  Ajouts: $($prInfo.Additions)" -ForegroundColor White
    Write-Host "  Suppressions: $($prInfo.Deletions)" -ForegroundColor White
    Write-Host "  Modifications totales: $($prInfo.Changes)" -ForegroundColor White

    # DÃ©marrer le profilage
    $profilingResults = Start-Profiling -PullRequestInfo $prInfo -Tracers $TracerTypes -Detail $DetailLevel -OutputDir $OutputPath
    if ($null -eq $profilingResults) {
        Write-Error "Ã‰chec du profilage."
        exit 1
    }

    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Host "`nRÃ©sumÃ© du profilage:" -ForegroundColor Cyan
    Write-Host "  Pull Request: #$($prInfo.Number) - $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Fichiers analysÃ©s: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  ProblÃ¨mes dÃ©tectÃ©s: $($profilingResults.AnalysisResults.TotalIssues)" -ForegroundColor White
    Write-Host "  DurÃ©e totale: $($profilingResults.AnalysisResults.Duration.TotalSeconds) secondes" -ForegroundColor White
    Write-Host "  Rapport de performance: $($profilingResults.Report)" -ForegroundColor White

    # Ouvrir le rapport dans le navigateur par dÃ©faut
    if (Test-Path -Path $profilingResults.Report) {
        Start-Process $profilingResults.Report
    }
} catch {
    Write-Error "Erreur lors de l'exÃ©cution du profilage: $_"
    exit 1
}

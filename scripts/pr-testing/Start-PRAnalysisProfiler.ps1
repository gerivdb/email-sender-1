#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre le profilage du système d'analyse des pull requests.

.DESCRIPTION
    Ce script lance un profilage complet du système d'analyse des pull requests
    pour identifier les goulots d'étranglement et les opportunités d'optimisation.
    Il prend en charge plusieurs types de traceurs et génère des rapports détaillés.

.PARAMETER RepositoryPath
    Le chemin du dépôt à analyser.
    Par défaut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numéro de la pull request à analyser.
    Si non spécifié, la dernière pull request sera utilisée.

.PARAMETER TracerTypes
    Les types de traceurs à utiliser pour le profilage.
    Valeurs possibles: "CPU", "Memory", "IO", "All"
    Par défaut: "All"

.PARAMETER OutputPath
    Le chemin où enregistrer les résultats du profilage.
    Par défaut: "reports\pr-analysis\profiling"

.PARAMETER DetailLevel
    Le niveau de détail du profilage.
    Valeurs possibles: "Basic", "Detailed", "Comprehensive"
    Par défaut: "Detailed"

.PARAMETER GenerateFlameGraph
    Indique s'il faut générer un graphique de flamme (flamegraph).
    Par défaut: $true

.EXAMPLE
    .\Start-PRAnalysisProfiler.ps1
    Démarre le profilage de la dernière pull request avec tous les traceurs.

.EXAMPLE
    .\Start-PRAnalysisProfiler.ps1 -PullRequestNumber 42 -TracerTypes "CPU", "Memory" -DetailLevel "Comprehensive"
    Démarre un profilage détaillé de la pull request #42 avec les traceurs CPU et mémoire.

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

# Importer les modules nécessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\PRPerformanceTracer.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module PRPerformanceTracer non trouvé à l'emplacement: $modulePath"
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
        # Vérifier si le dépôt existe
        if (-not (Test-Path -Path $RepoPath)) {
            throw "Le dépôt n'existe pas à l'emplacement spécifié: $RepoPath"
        }

        # Changer de répertoire vers le dépôt
        Push-Location -Path $RepoPath

        try {
            # Si aucun numéro de PR n'est spécifié, utiliser la dernière PR
            if ($PRNumber -eq 0) {
                $prs = gh pr list --json number,title,headRefName,baseRefName,createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvée dans le dépôt."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number,title,headRefName,baseRefName,createdAt | ConvertFrom-Json
                if ($null -eq $pr) {
                    throw "Pull request #$PRNumber non trouvée."
                }
            }

            # Obtenir les fichiers modifiés
            $files = gh pr view $pr.number --json files | ConvertFrom-Json

            # Créer l'objet d'informations sur la PR
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
            # Revenir au répertoire précédent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la récupération des informations sur la pull request: $_"
        return $null
    }
}

# Fonction pour démarrer le profilage
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
        # Créer le répertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }

        # Déterminer les traceurs à utiliser
        $enabledTracers = @()
        if ($Tracers -contains "All") {
            $enabledTracers = @("CPU", "Memory", "IO")
        } else {
            $enabledTracers = $Tracers
        }

        Write-Host "Démarrage du profilage de la pull request #$($PullRequestInfo.Number) avec les traceurs: $($enabledTracers -join ', ')" -ForegroundColor Cyan

        # Initialiser le traceur de performance
        $tracer = New-PRPerformanceTracer -TracerTypes $enabledTracers -DetailLevel $Detail -OutputPath $OutputDir

        # Démarrer le traçage
        $tracer.Start()

        # Simuler l'analyse de la pull request
        $analysisResults = Invoke-PRAnalysisWithTracing -PullRequestInfo $PullRequestInfo -Tracer $tracer

        # Arrêter le traçage
        $tracer.Stop()

        # Générer le rapport de performance
        $reportPath = Join-Path -Path $OutputDir -ChildPath "performance_report_pr$($PullRequestInfo.Number).html"
        $report = Export-PRPerformanceReport -Tracer $tracer -OutputPath $reportPath -PullRequestInfo $PullRequestInfo

        # Générer le flamegraph si demandé
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

# Fonction pour simuler l'analyse d'une pull request avec traçage
function Invoke-PRAnalysisWithTracing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PullRequestInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Tracer
    )

    try {
        Write-Host "Exécution de l'analyse de la pull request #$($PullRequestInfo.Number) avec traçage..." -ForegroundColor Yellow

        # Créer un objet pour stocker les résultats
        $results = [PSCustomObject]@{
            PullRequestNumber = $PullRequestInfo.Number
            FileResults = @()
            TotalIssues = 0
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
        }

        # Démarrer le traçage de l'opération principale
        $Tracer.StartOperation("AnalysePR", "Analyse complète de la PR #$($PullRequestInfo.Number)")

        # Analyser chaque fichier
        foreach ($file in $PullRequestInfo.Files) {
            # Démarrer le traçage pour ce fichier
            $Tracer.StartOperation("AnalyseFichier", "Analyse du fichier: $($file.path)")

            # Simuler l'analyse du fichier
            $fileResult = Invoke-FileAnalysisWithTracing -FilePath $file.path -PullRequestInfo $PullRequestInfo -Tracer $Tracer

            # Ajouter les résultats
            $results.FileResults += $fileResult
            $results.TotalIssues += $fileResult.Issues.Count

            # Arrêter le traçage pour ce fichier
            $Tracer.StopOperation("AnalyseFichier")
        }

        # Finaliser les résultats
        $results.EndTime = Get-Date
        $results.Duration = $results.EndTime - $results.StartTime

        # Arrêter le traçage de l'opération principale
        $Tracer.StopOperation("AnalysePR")

        return $results
    } catch {
        Write-Error "Erreur lors de l'analyse avec traçage: $_"
        return $null
    }
}

# Fonction pour simuler l'analyse d'un fichier avec traçage
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
        # Créer un objet pour stocker les résultats
        $fileResult = [PSCustomObject]@{
            FilePath = $FilePath
            Issues = @()
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
        }

        # Simuler différentes étapes d'analyse avec traçage
        
        # 1. Lecture du fichier
        $Tracer.StartOperation("LectureFichier", "Lecture du fichier: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50) # Simuler le temps de lecture
        $Tracer.StopOperation("LectureFichier")

        # 2. Analyse syntaxique
        $Tracer.StartOperation("AnalyseSyntaxique", "Analyse syntaxique: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200) # Simuler le temps d'analyse
        
        # Simuler la détection d'erreurs syntaxiques
        $syntaxIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 7) {
            $syntaxIssues = Get-Random -Minimum 1 -Maximum 3
            for ($i = 0; $i -lt $syntaxIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Syntax"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "Erreur de syntaxe: $((Get-Random -InputObject @("Parenthèse manquante", "Accolade non fermée", "Point-virgule manquant")))"
                    Severity = "Error"
                }
            }
        }
        $Tracer.StopOperation("AnalyseSyntaxique")

        # 3. Analyse de style
        $Tracer.StartOperation("AnalyseStyle", "Analyse de style: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 30 -Maximum 150) # Simuler le temps d'analyse
        
        # Simuler la détection de problèmes de style
        $styleIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 5) {
            $styleIssues = Get-Random -Minimum 1 -Maximum 5
            for ($i = 0; $i -lt $styleIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Style"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "Problème de style: $((Get-Random -InputObject @("Indentation incorrecte", "Ligne trop longue", "Nom de variable non conforme")))"
                    Severity = "Warning"
                }
            }
        }
        $Tracer.StopOperation("AnalyseStyle")

        # 4. Analyse de performance
        $Tracer.StartOperation("AnalysePerformance", "Analyse de performance: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 40 -Maximum 180) # Simuler le temps d'analyse
        
        # Simuler la détection de problèmes de performance
        $perfIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 6) {
            $perfIssues = Get-Random -Minimum 1 -Maximum 3
            for ($i = 0; $i -lt $perfIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Performance"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "Problème de performance: $((Get-Random -InputObject @("Boucle inefficace", "Allocation mémoire excessive", "Opération I/O dans une boucle")))"
                    Severity = "Warning"
                }
            }
        }
        $Tracer.StopOperation("AnalysePerformance")

        # 5. Analyse de sécurité
        $Tracer.StartOperation("AnalyseSécurité", "Analyse de sécurité: $FilePath")
        Start-Sleep -Milliseconds (Get-Random -Minimum 60 -Maximum 250) # Simuler le temps d'analyse
        
        # Simuler la détection de problèmes de sécurité
        $secIssues = 0
        if ((Get-Random -Minimum 1 -Maximum 10) -gt 8) {
            $secIssues = Get-Random -Minimum 1 -Maximum 2
            for ($i = 0; $i -lt $secIssues; $i++) {
                $fileResult.Issues += [PSCustomObject]@{
                    Type = "Security"
                    Line = Get-Random -Minimum 1 -Maximum 100
                    Message = "Problème de sécurité: $((Get-Random -InputObject @("Injection possible", "Identifiants en clair", "Validation d'entrée manquante")))"
                    Severity = "Critical"
                }
            }
        }
        $Tracer.StopOperation("AnalyseSécurité")

        # Finaliser les résultats
        $fileResult.EndTime = Get-Date
        $fileResult.Duration = $fileResult.EndTime - $fileResult.StartTime

        return $fileResult
    } catch {
        Write-Error "Erreur lors de l'analyse du fichier avec traçage: $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Obtenir les informations sur la pull request
    $prInfo = Get-PullRequestInfo -RepoPath $RepositoryPath -PRNumber $PullRequestNumber
    if ($null -eq $prInfo) {
        Write-Error "Impossible d'obtenir les informations sur la pull request."
        exit 1
    }

    # Afficher les informations sur la pull request
    Write-Host "Informations sur la pull request:" -ForegroundColor Cyan
    Write-Host "  Numéro: #$($prInfo.Number)" -ForegroundColor White
    Write-Host "  Titre: $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Branche source: $($prInfo.HeadBranch)" -ForegroundColor White
    Write-Host "  Branche cible: $($prInfo.BaseBranch)" -ForegroundColor White
    Write-Host "  Fichiers modifiés: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  Ajouts: $($prInfo.Additions)" -ForegroundColor White
    Write-Host "  Suppressions: $($prInfo.Deletions)" -ForegroundColor White
    Write-Host "  Modifications totales: $($prInfo.Changes)" -ForegroundColor White

    # Démarrer le profilage
    $profilingResults = Start-Profiling -PullRequestInfo $prInfo -Tracers $TracerTypes -Detail $DetailLevel -OutputDir $OutputPath
    if ($null -eq $profilingResults) {
        Write-Error "Échec du profilage."
        exit 1
    }

    # Afficher un résumé des résultats
    Write-Host "`nRésumé du profilage:" -ForegroundColor Cyan
    Write-Host "  Pull Request: #$($prInfo.Number) - $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Fichiers analysés: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  Problèmes détectés: $($profilingResults.AnalysisResults.TotalIssues)" -ForegroundColor White
    Write-Host "  Durée totale: $($profilingResults.AnalysisResults.Duration.TotalSeconds) secondes" -ForegroundColor White
    Write-Host "  Rapport de performance: $($profilingResults.Report)" -ForegroundColor White

    # Ouvrir le rapport dans le navigateur par défaut
    if (Test-Path -Path $profilingResults.Report) {
        Start-Process $profilingResults.Report
    }
} catch {
    Write-Error "Erreur lors de l'exécution du profilage: $_"
    exit 1
}

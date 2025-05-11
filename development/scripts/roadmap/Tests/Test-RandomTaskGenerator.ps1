﻿# Test-RandomTaskGenerator.ps1
# Script pour tester la génération de tâches aléatoires
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Small", "Medium", "Large", "All")]
    [string]$TestSize = "All",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Balanced", "Flat", "Deep", "All")]
    [string]$HierarchyType = "All",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "development/scripts/roadmap/tests/data/synthetic",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeMetadata,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeDependencies,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer le module de génération de tâches aléatoires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"
$randomTasksModulePath = Join-Path -Path $utilsPath -ChildPath "Generate-RandomTasks.ps1"

if (-not (Test-Path -Path $randomTasksModulePath)) {
    Write-Error "Module de génération de tâches aléatoires non trouvé: $randomTasksModulePath"
    exit 1
}

. $randomTasksModulePath

# Importer les fonctions utilitaires si elles existent
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"
if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"

        switch ($Level) {
            "Error" { Write-Host $logMessage -ForegroundColor Red }
            "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
            "Success" { Write-Host $logMessage -ForegroundColor Green }
            default { Write-Host $logMessage }
        }
    }
}

# Fonction pour exécuter un test de génération de tâches
function Invoke-TaskGenerationTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [int]$TaskCount,

        [Parameter(Mandatory = $true)]
        [int]$MaxDepth,

        [Parameter(Mandatory = $true)]
        [string]$HierarchyType,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-Log "Exécution du test '$TestName'..." -Level Info

    # Mesurer le temps d'exécution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Générer les tâches
    $tasks = New-RandomTaskSet -TaskCount $TaskCount -MaxDepth $MaxDepth -HierarchyType $HierarchyType -WithMetadata:$IncludeMetadata -WithDependencies:$IncludeDependencies

    $generationTime = $stopwatch.ElapsedMilliseconds

    # Vérifier les résultats
    $actualTaskCount = $tasks.Count
    $rootTaskCount = ($tasks | Where-Object { $_.IndentLevel -eq 0 }).Count
    $maxActualDepth = ($tasks | Measure-Object -Property IndentLevel -Maximum).Maximum
    $tasksWithMetadata = ($tasks | Where-Object { $_.Metadata.Count -gt 0 }).Count
    $tasksWithDependencies = ($tasks | Where-Object { $_.Dependencies.Count -gt 0 }).Count

    Write-Log "Génération terminée en $generationTime ms" -Level Success
    Write-Log "Nombre de tâches générées: $actualTaskCount (demandé: $TaskCount)" -Level Info
    Write-Log "Nombre de tâches racines: $rootTaskCount" -Level Info
    Write-Log "Profondeur maximale: $maxActualDepth (demandé: $MaxDepth)" -Level Info
    Write-Log "Tâches avec métadonnées: $tasksWithMetadata" -Level Info
    Write-Log "Tâches avec dépendances: $tasksWithDependencies" -Level Info

    # Sauvegarder les tâches dans un fichier markdown
    $outputFileName = "roadmap_${TestName}_${HierarchyType}_${TaskCount}.md"
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath $outputFileName

    $title = "Roadmap de test - $TestName - $HierarchyType - $TaskCount tâches"

    $stopwatch.Restart()
    $result = Save-MarkdownRoadmap -Tasks $tasks -OutputPath $outputPath -Title $title -IncludeMetadata:$IncludeMetadata -IncludeDependencies:$IncludeDependencies -Force:$Force
    $saveTime = $stopwatch.ElapsedMilliseconds

    if ($result) {
        Write-Log "Roadmap sauvegardé dans $outputPath en $saveTime ms" -Level Success
    } else {
        Write-Log "Échec de la sauvegarde du roadmap" -Level Error
    }

    # Retourner les résultats du test
    return [PSCustomObject]@{
        TestName              = $TestName
        HierarchyType         = $HierarchyType
        RequestedTaskCount    = $TaskCount
        ActualTaskCount       = $actualTaskCount
        MaxDepth              = $MaxDepth
        ActualMaxDepth        = $maxActualDepth
        RootTaskCount         = $rootTaskCount
        TasksWithMetadata     = $tasksWithMetadata
        TasksWithDependencies = $tasksWithDependencies
        GenerationTimeMs      = $generationTime
        SaveTimeMs            = $saveTime
        OutputPath            = $outputPath
        Success               = $true
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestSize,

        [Parameter(Mandatory = $true)]
        [string]$HierarchyType,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $results = @()

    # Définir les tailles de test
    $testSizes = @()

    if ($TestSize -eq "All" -or $TestSize -eq "Small") {
        $testSizes += [PSCustomObject]@{
            Name      = "Small"
            TaskCount = 50
            MaxDepth  = 2
        }
    }

    if ($TestSize -eq "All" -or $TestSize -eq "Medium") {
        $testSizes += [PSCustomObject]@{
            Name      = "Medium"
            TaskCount = 200
            MaxDepth  = 3
        }
    }

    if ($TestSize -eq "All" -or $TestSize -eq "Large") {
        $testSizes += [PSCustomObject]@{
            Name      = "Large"
            TaskCount = 1000
            MaxDepth  = 4
        }
    }

    # Définir les types de hiérarchie
    $hierarchyTypes = @()

    if ($HierarchyType -eq "All" -or $HierarchyType -eq "Balanced") {
        $hierarchyTypes += "Balanced"
    }

    if ($HierarchyType -eq "All" -or $HierarchyType -eq "Flat") {
        $hierarchyTypes += "Flat"
    }

    if ($HierarchyType -eq "All" -or $HierarchyType -eq "Deep") {
        $hierarchyTypes += "Deep"
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire de sortie créé: $OutputDirectory" -Level Info
    }

    # Exécuter les tests pour chaque combinaison de taille et de type de hiérarchie
    foreach ($size in $testSizes) {
        foreach ($type in $hierarchyTypes) {
            $result = Invoke-TaskGenerationTest -TestName $size.Name -TaskCount $size.TaskCount -MaxDepth $size.MaxDepth -HierarchyType $type -OutputDirectory $OutputDirectory -IncludeMetadata:$IncludeMetadata -IncludeDependencies:$IncludeDependencies -Force:$Force
            $results += $result
        }
    }

    return $results
}

# Fonction pour générer un rapport de test
function New-TestReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    $report = @()
    $report += "# Rapport de test de génération de tâches aléatoires"
    $report += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Nombre de tests: $($Results.Count)"
    $report += ""

    $report += "## Résumé"
    $report += "| Test | Hiérarchie | Tâches | Profondeur | Racines | Génération (ms) | Sauvegarde (ms) |"
    $report += "|------|------------|--------|------------|---------|-----------------|-----------------|"

    foreach ($result in $Results) {
        $report += "| $($result.TestName) | $($result.HierarchyType) | $($result.ActualTaskCount) | $($result.ActualMaxDepth) | $($result.RootTaskCount) | $($result.GenerationTimeMs) | $($result.SaveTimeMs) |"
    }

    $report += ""
    $report += "## Détails des tests"

    foreach ($result in $Results) {
        $report += "### Test: $($result.TestName) - $($result.HierarchyType)"
        $report += "- **Tâches demandées**: $($result.RequestedTaskCount)"
        $report += "- **Tâches générées**: $($result.ActualTaskCount)"
        $report += "- **Profondeur maximale**: $($result.ActualMaxDepth) (demandé: $($result.MaxDepth))"
        $report += "- **Tâches racines**: $($result.RootTaskCount)"
        $report += "- **Tâches avec métadonnées**: $($result.TasksWithMetadata)"
        $report += "- **Tâches avec dépendances**: $($result.TasksWithDependencies)"
        $report += "- **Temps de génération**: $($result.GenerationTimeMs) ms"
        $report += "- **Temps de sauvegarde**: $($result.SaveTimeMs) ms"
        $report += "- **Fichier de sortie**: $($result.OutputPath)"
        $report += ""
    }

    $reportText = $report -join "`n"

    if ($OutputPath) {
        $reportText | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Rapport de test sauvegardé dans $OutputPath" -Level Success
    }

    return $reportText
}

# Exécution principale
try {
    Write-Log "Démarrage des tests de génération de tâches aléatoires..." -Level Info

    $results = Invoke-AllTests -TestSize $TestSize -HierarchyType $HierarchyType -OutputDirectory $OutputDirectory -IncludeMetadata:$IncludeMetadata -IncludeDependencies:$IncludeDependencies -Force:$Force

    $reportPath = Join-Path -Path $OutputDirectory -ChildPath "test_report.md"
    $report = New-TestReport -Results $results -OutputPath $reportPath

    Write-Log "Tests terminés avec succès" -Level Success

    return $results
} catch {
    Write-Log "Erreur lors de l'exécution des tests: $_" -Level Error
    exit 1
}

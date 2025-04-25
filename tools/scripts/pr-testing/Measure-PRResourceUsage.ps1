#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure l'utilisation des ressources pendant l'analyse des pull requests.

.DESCRIPTION
    Ce script analyse les données de traçage pour mesurer l'utilisation des ressources
    (CPU, mémoire, I/O) pendant l'analyse des pull requests.

.PARAMETER Tracer
    L'objet traceur contenant les données de traçage.

.PARAMETER OutputPath
    Le chemin où enregistrer les résultats de l'analyse.
    Par défaut: "reports\pr-analysis\profiling\resource_usage.json"

.EXAMPLE
    Measure-PRResourceUsage -Tracer $tracer -OutputPath "reports\resource_usage_pr42.json"
    Mesure l'utilisation des ressources à partir des données du traceur et enregistre les résultats.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [object]$Tracer,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis\profiling\resource_usage.json"
)

# Fonction pour analyser l'utilisation des ressources
function Get-ResourceUsageAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TracingData
    )

    try {
        # Analyser les instantanés de ressources
        $snapshots = $TracingData.ResourceSnapshots

        # Calculer les statistiques d'utilisation du CPU
        $cpuUsage = $snapshots | ForEach-Object { $_.CPU }
        $cpuStats = [PSCustomObject]@{
            Min     = ($cpuUsage | Measure-Object -Minimum).Minimum
            Max     = ($cpuUsage | Measure-Object -Maximum).Maximum
            Average = ($cpuUsage | Measure-Object -Average).Average
            Start   = $snapshots[0].CPU
            End     = $snapshots[-1].CPU
            Delta   = $snapshots[-1].CPU - $snapshots[0].CPU
        }

        # Calculer les statistiques d'utilisation de la mémoire
        $memoryUsage = $snapshots | ForEach-Object { $_.WorkingSet / 1MB }
        $memoryStats = [PSCustomObject]@{
            MinMB     = ($memoryUsage | Measure-Object -Minimum).Minimum
            MaxMB     = ($memoryUsage | Measure-Object -Maximum).Maximum
            AverageMB = ($memoryUsage | Measure-Object -Average).Average
            StartMB   = $snapshots[0].WorkingSet / 1MB
            EndMB     = $snapshots[-1].WorkingSet / 1MB
            DeltaMB   = ($snapshots[-1].WorkingSet - $snapshots[0].WorkingSet) / 1MB
        }

        # Calculer les statistiques d'utilisation de la mémoire privée
        $privateMemoryUsage = $snapshots | ForEach-Object { $_.PrivateMemory / 1MB }
        $privateMemoryStats = [PSCustomObject]@{
            MinMB     = ($privateMemoryUsage | Measure-Object -Minimum).Minimum
            MaxMB     = ($privateMemoryUsage | Measure-Object -Maximum).Maximum
            AverageMB = ($privateMemoryUsage | Measure-Object -Average).Average
            StartMB   = $snapshots[0].PrivateMemory / 1MB
            EndMB     = $snapshots[-1].PrivateMemory / 1MB
            DeltaMB   = ($snapshots[-1].PrivateMemory - $snapshots[0].PrivateMemory) / 1MB
        }

        # Calculer les statistiques d'utilisation des handles
        $handleUsage = $snapshots | ForEach-Object { $_.HandleCount }
        $handleStats = [PSCustomObject]@{
            Min     = ($handleUsage | Measure-Object -Minimum).Minimum
            Max     = ($handleUsage | Measure-Object -Maximum).Maximum
            Average = ($handleUsage | Measure-Object -Average).Average
            Start   = $snapshots[0].HandleCount
            End     = $snapshots[-1].HandleCount
            Delta   = $snapshots[-1].HandleCount - $snapshots[0].HandleCount
        }

        # Analyser l'utilisation des ressources par opération
        $operationResourceUsage = @()
        foreach ($operation in $TracingData.Operations) {
            if ($null -ne $operation.ResourceUsage) {
                $operationResourceUsage += [PSCustomObject]@{
                    Name                 = $operation.Name
                    Description          = $operation.Description
                    DurationMS           = $operation.Duration.TotalMilliseconds
                    CPUDelta             = $operation.ResourceUsage.Delta.CPU
                    WorkingSetDeltaMB    = $operation.ResourceUsage.Delta.WorkingSet / 1MB
                    PrivateMemoryDeltaMB = $operation.ResourceUsage.Delta.PrivateMemory / 1MB
                    HandleCountDelta     = $operation.ResourceUsage.Delta.HandleCount
                }
            }
        }

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            TotalDurationMS        = $TracingData.Duration.TotalMilliseconds
            CPU                    = $cpuStats
            Memory                 = $memoryStats
            PrivateMemory          = $privateMemoryStats
            Handles                = $handleStats
            OperationResourceUsage = $operationResourceUsage
            ResourceSnapshots      = $snapshots
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'analyse de l'utilisation des ressources: $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Vérifier que le traceur est valide
    if ($null -eq $Tracer) {
        throw "L'objet traceur est null."
    }

    # Obtenir les données de traçage
    $tracingData = $Tracer.GetTracingData()
    if ($null -eq $tracingData) {
        throw "Impossible d'obtenir les données de traçage."
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Analyser l'utilisation des ressources
    $resourceUsage = Get-ResourceUsageAnalysis -TracingData $tracingData

    # Enregistrer les résultats au format JSON
    $resourceUsage | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    Write-Host "Analyse de l'utilisation des ressources terminée: $OutputPath" -ForegroundColor Green
    return $OutputPath
} catch {
    Write-Error "Erreur lors de la mesure de l'utilisation des ressources: $_"
    return $null
}

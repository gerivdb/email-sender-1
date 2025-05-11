﻿# Measure-ViewLoadTime.ps1
# Script pour mesurer le temps de chargement initial des vues de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("HTML", "Markdown", "D3", "Mermaid")]
    [string]$ViewType = "HTML",

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeMemoryUsage,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "CSV", "JSON", "HTML")]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"

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

# Fonction pour obtenir l'utilisation mémoire actuelle du processus PowerShell
function Get-CurrentMemoryUsage {
    $process = Get-Process -Id $PID
    return [math]::Round($process.WorkingSet64 / 1MB, 2)
}

# Fonction pour mesurer le temps de chargement d'une vue
function Measure-ViewLoadTime {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ViewType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMemoryUsage
    )

    $results = @{
        StartTime    = Get-Date
        EndTime      = $null
        ElapsedMs    = 0
        MemoryBefore = if ($IncludeMemoryUsage) { Get-CurrentMemoryUsage } else { 0 }
        MemoryAfter  = 0
        MemoryDelta  = 0
        Success      = $false
        Error        = $null
    }

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Exécuter la commande appropriée selon le type de vue
        switch ($ViewType) {
            "HTML" {
                # Utiliser le script de visualisation HTML
                $visualizationScript = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Invoke-RoadmapVisualization.ps1"
                if (Test-Path -Path $visualizationScript) {
                    $tempOutputDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
                    New-Item -Path $tempOutputDir -ItemType Directory -Force | Out-Null

                    & $visualizationScript -RoadmapPath $RoadmapPath -OutputDirectory $tempOutputDir -VisualizationType "HTML" -Force

                    # Nettoyer le répertoire temporaire
                    if (Test-Path -Path $tempOutputDir) {
                        Remove-Item -Path $tempOutputDir -Recurse -Force
                    }
                } else {
                    throw "Script de visualisation HTML non trouvé: $visualizationScript"
                }
            }
            "Markdown" {
                # Utiliser le script de visualisation Markdown
                $parserScript = Join-Path -Path $utilsPath -ChildPath "Parse-Markdown.ps1"
                if (Test-Path -Path $parserScript) {
                    . $parserScript
                    $content = Get-Content -Path $RoadmapPath -Raw
                    $tasks = Parse-MarkdownTasks -Content $content
                } else {
                    throw "Script de parsing Markdown non trouvé: $parserScript"
                }
            }
            "D3" {
                # Utiliser le script de visualisation D3
                $visualizationScript = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Invoke-RoadmapVisualization.ps1"
                if (Test-Path -Path $visualizationScript) {
                    $tempOutputDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
                    New-Item -Path $tempOutputDir -ItemType Directory -Force | Out-Null

                    & $visualizationScript -RoadmapPath $RoadmapPath -OutputDirectory $tempOutputDir -VisualizationType "D3" -Force

                    # Nettoyer le répertoire temporaire
                    if (Test-Path -Path $tempOutputDir) {
                        Remove-Item -Path $tempOutputDir -Recurse -Force
                    }
                } else {
                    throw "Script de visualisation D3 non trouvé: $visualizationScript"
                }
            }
            "Mermaid" {
                # Utiliser le script de visualisation Mermaid
                $visualizationScript = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Invoke-RoadmapVisualization.ps1"
                if (Test-Path -Path $visualizationScript) {
                    $tempOutputDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
                    New-Item -Path $tempOutputDir -ItemType Directory -Force | Out-Null

                    & $visualizationScript -RoadmapPath $RoadmapPath -OutputDirectory $tempOutputDir -VisualizationType "Mermaid" -Force

                    # Nettoyer le répertoire temporaire
                    if (Test-Path -Path $tempOutputDir) {
                        Remove-Item -Path $tempOutputDir -Recurse -Force
                    }
                } else {
                    throw "Script de visualisation Mermaid non trouvé: $visualizationScript"
                }
            }
            default {
                throw "Type de vue non supporté: $ViewType"
            }
        }

        $stopwatch.Stop()
        $results.ElapsedMs = $stopwatch.ElapsedMilliseconds
        $results.EndTime = Get-Date
        $results.Success = $true

        if ($IncludeMemoryUsage) {
            $results.MemoryAfter = Get-CurrentMemoryUsage
            $results.MemoryDelta = $results.MemoryAfter - $results.MemoryBefore
        }
    } catch {
        $results.EndTime = Get-Date
        $results.Error = $_.Exception.Message
        $results.Success = $false

        if ($IncludeMemoryUsage) {
            $results.MemoryAfter = Get-CurrentMemoryUsage
            $results.MemoryDelta = $results.MemoryAfter - $results.MemoryBefore
        }

        Write-Log "Erreur lors de la mesure du temps de chargement: $_" -Level Error
    }

    return $results
}

# Fonction pour formater les résultats en texte
function Format-ResultsAsText {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ViewType,

        [Parameter(Mandatory = $true)]
        [int]$Iterations,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMemoryUsage
    )

    $output = @()
    $output += "=== RAPPORT DE PERFORMANCE ==="
    $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "Roadmap: $RoadmapPath"
    $output += "Type de vue: $ViewType"
    $output += "Nombre d'itérations: $Iterations"
    $output += ""

    $successfulResults = $Results | Where-Object { $_.Success }
    $failedResults = $Results | Where-Object { -not $_.Success }

    if ($successfulResults.Count -gt 0) {
        $avgTime = [math]::Round(($successfulResults | Measure-Object -Property ElapsedMs -Average).Average, 2)
        $minTime = [math]::Round(($successfulResults | Measure-Object -Property ElapsedMs -Minimum).Minimum, 2)
        $maxTime = [math]::Round(($successfulResults | Measure-Object -Property ElapsedMs -Maximum).Maximum, 2)
        $stdDev = [math]::Round([Math]::Sqrt(($successfulResults | ForEach-Object { [Math]::Pow($_.ElapsedMs - $avgTime, 2) } | Measure-Object -Average).Average), 2)

        $output += "--- RÉSULTATS DE TEMPS DE CHARGEMENT ---"
        $output += "Temps moyen: $avgTime ms"
        $output += "Temps minimum: $minTime ms"
        $output += "Temps maximum: $maxTime ms"
        $output += "Écart type: $stdDev ms"
        $output += "Coefficient de variation: $([math]::Round(($stdDev / $avgTime) * 100, 2))%"
        $output += ""

        if ($IncludeMemoryUsage) {
            $avgMemoryDelta = [math]::Round(($successfulResults | Measure-Object -Property MemoryDelta -Average).Average, 2)
            $maxMemoryDelta = [math]::Round(($successfulResults | Measure-Object -Property MemoryDelta -Maximum).Maximum, 2)

            $output += "--- RÉSULTATS D'UTILISATION MÉMOIRE ---"
            $output += "Augmentation moyenne: $avgMemoryDelta MB"
            $output += "Augmentation maximale: $maxMemoryDelta MB"
            $output += ""
        }
    }

    if ($failedResults.Count -gt 0) {
        $output += "--- ERREURS ($($failedResults.Count)) ---"
        foreach ($result in $failedResults) {
            $output += "Itération $(($Results.IndexOf($result) + 1)): $($result.Error)"
        }
        $output += ""
    }

    $output += "--- DÉTAILS DES ITÉRATIONS ---"
    for ($i = 0; $i -lt $Results.Count; $i++) {
        $result = $Results[$i]
        $status = $result.Success ? "Réussi" : "Échec"
        $output += "Itération $($i + 1): $status - $($result.ElapsedMs) ms"

        if ($IncludeMemoryUsage) {
            $output += "  Mémoire: $($result.MemoryBefore) MB -> $($result.MemoryAfter) MB (Delta: $($result.MemoryDelta) MB)"
        }

        if (-not $result.Success) {
            $output += "  Erreur: $($result.Error)"
        }
    }

    return $output -join "`n"
}

# Fonction principale
function Invoke-ViewLoadTimeMeasurement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ViewType,

        [Parameter(Mandatory = $true)]
        [int]$Iterations,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMemoryUsage,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputFormat
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Fichier de roadmap non trouvé: $RoadmapPath" -Level Error
        return $false
    }

    Write-Log "Démarrage des mesures de performance pour $RoadmapPath (Type: $ViewType, Itérations: $Iterations)" -Level Info

    $results = @()

    # Exécuter les mesures pour chaque itération
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "Exécution de l'itération $i/$Iterations..." -Level Info
        $result = Measure-ViewLoadTime -RoadmapPath $RoadmapPath -ViewType $ViewType -IncludeMemoryUsage:$IncludeMemoryUsage
        $results += $result

        $status = $result.Success ? "réussie" : "échouée"
        $timeInfo = $result.Success ? "$($result.ElapsedMs) ms" : "N/A"
        $memoryInfo = ""

        if ($IncludeMemoryUsage) {
            $memoryInfo = ", Delta mémoire: $($result.MemoryDelta) MB"
        }

        Write-Log "Itération $i/$Iterations $status (Temps: $timeInfo$memoryInfo)" -Level ($result.Success ? "Success" : "Error")

        # Petite pause entre les itérations pour stabiliser la mémoire
        Start-Sleep -Milliseconds 500
    }

    # Formater et enregistrer les résultats
    $formattedResults = Format-ResultsAsText -Results $results -RoadmapPath $RoadmapPath -ViewType $ViewType -Iterations $Iterations -IncludeMemoryUsage:$IncludeMemoryUsage

    if ($OutputPath) {
        $formattedResults | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Résultats enregistrés dans: $OutputPath" -Level Success
    } else {
        Write-Output $formattedResults
    }

    return $results
}

# Exécution principale
try {
    $result = Invoke-ViewLoadTimeMeasurement -RoadmapPath $RoadmapPath -ViewType $ViewType -Iterations $Iterations -IncludeMemoryUsage:$IncludeMemoryUsage -OutputPath $OutputPath -OutputFormat $OutputFormat

    if ($result) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-Log "Erreur lors de l'exécution des mesures de performance: $_" -Level Error
    exit 2
}

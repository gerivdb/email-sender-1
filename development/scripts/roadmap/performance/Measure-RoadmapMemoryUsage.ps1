﻿# Measure-RoadmapMemoryUsage.ps1
# Script pour mesurer l'utilisation mémoire des opérations sur les roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Parsing", "Vectorization", "Visualization", "Search", "All")]
    [string]$OperationType = "All",

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false)]
    [ValidateSet("KB", "MB", "GB")]
    [string]$Unit = "MB",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "CSV", "JSON", "HTML")]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [switch]$DetailedReport,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"

# Importer le module de mesure de mémoire
$memoryModulePath = Join-Path -Path $utilsPath -ChildPath "Measure-Memory.ps1"
if (Test-Path -Path $memoryModulePath) {
    . $memoryModulePath
} else {
    Write-Error "Module de mesure de mémoire non trouvé: $memoryModulePath"
    exit 1
}

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

# Fonction pour mesurer l'utilisation mémoire du parsing de roadmap
function Measure-RoadmapParsing {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$Unit = "MB",

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )

    Write-Log "Mesure de l'utilisation mémoire du parsing de roadmap ($Iterations itérations)..." -Level Info

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "Exécution de l'itération $i/$Iterations..." -Level Info

        $parserScript = Join-Path -Path $utilsPath -ChildPath "Parse-Markdown.ps1"

        if (Test-Path -Path $parserScript) {
            # Mesurer l'utilisation mémoire du parsing
            $result = Measure-ScriptMemoryUsage -ScriptBlock {
                param($parserScript, $roadmapPath)

                # Importer le script de parsing
                . $parserScript

                # Lire le contenu du fichier
                $content = Get-Content -Path $roadmapPath -Raw

                # Parser le contenu
                $tasks = Parse-MarkdownTasks -Content $content

                return $tasks
            } -Arguments @($parserScript, $RoadmapPath) -SampleInterval 100 -Unit $Unit

            $taskCount = $result.Result.Count

            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name TaskCount -Value $taskCount
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name MemoryPerTask -Value ([math]::Round($result.MemoryStatistics.PeakPrivateMemory / $taskCount, 4))
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name OperationType -Value "Parsing"
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name Iteration -Value $i

            $results += $result.MemoryStatistics

            Write-Log "Itération $i/$Iterations terminée. Pic mémoire: $($result.MemoryStatistics.PeakPrivateMemory) $Unit, $taskCount tâches" -Level Success
        } else {
            Write-Log "Script de parsing non trouvé: $parserScript" -Level Error
            return $null
        }

        # Forcer le garbage collector
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Start-Sleep -Seconds 1
    }

    return $results
}

# Fonction pour mesurer l'utilisation mémoire de la vectorisation
function Measure-RoadmapVectorization {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$Unit = "MB",

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )

    Write-Log "Mesure de l'utilisation mémoire de la vectorisation de roadmap ($Iterations itérations)..." -Level Info

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "Exécution de l'itération $i/$Iterations..." -Level Info

        $vectorizationScript = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Invoke-RoadmapVectorSync.ps1"

        if (Test-Path -Path $vectorizationScript) {
            # Créer un répertoire temporaire pour les tests
            $tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            # Mesurer l'utilisation mémoire de la vectorisation
            $result = Measure-ScriptMemoryUsage -ScriptBlock {
                param($vectorizationScript, $roadmapPath, $tempDir)

                # Exécuter le script de vectorisation en mode simulation
                $output = & $vectorizationScript -RoadmapPath $roadmapPath -OutputDirectory $tempDir -SimulateOnly

                return $output
            } -Arguments @($vectorizationScript, $RoadmapPath, $tempDir) -SampleInterval 100 -Unit $Unit

            # Nettoyer le répertoire temporaire
            if (Test-Path -Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }

            $taskCount = if ($result.Result -is [array]) { $result.Result.Count } else { 0 }

            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name TaskCount -Value $taskCount
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name MemoryPerTask -Value (if ($taskCount -gt 0) { [math]::Round($result.MemoryStatistics.PeakPrivateMemory / $taskCount, 4) } else { 0 })
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name OperationType -Value "Vectorization"
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name Iteration -Value $i

            $results += $result.MemoryStatistics

            Write-Log "Itération $i/$Iterations terminée. Pic mémoire: $($result.MemoryStatistics.PeakPrivateMemory) $Unit" -Level Success
        } else {
            Write-Log "Script de vectorisation non trouvé: $vectorizationScript" -Level Error
            return $null
        }

        # Forcer le garbage collector
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Start-Sleep -Seconds 1
    }

    return $results
}

# Fonction pour mesurer l'utilisation mémoire de la visualisation
function Measure-RoadmapVisualization {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$Unit = "MB",

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )

    Write-Log "Mesure de l'utilisation mémoire de la visualisation de roadmap ($Iterations itérations)..." -Level Info

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "Exécution de l'itération $i/$Iterations..." -Level Info

        $visualizationScript = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Invoke-RoadmapVisualization.ps1"

        if (Test-Path -Path $visualizationScript) {
            # Créer un répertoire temporaire pour les tests
            $tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            # Mesurer l'utilisation mémoire de la visualisation
            $result = Measure-ScriptMemoryUsage -ScriptBlock {
                param($visualizationScript, $roadmapPath, $tempDir)

                # Exécuter le script de visualisation
                & $visualizationScript -RoadmapPath $roadmapPath -OutputDirectory $tempDir -VisualizationType "HTML" -Force

                # Compter les fichiers générés
                $files = Get-ChildItem -Path $tempDir -Recurse -File

                return $files
            } -Arguments @($visualizationScript, $RoadmapPath, $tempDir) -SampleInterval 100 -Unit $Unit

            # Nettoyer le répertoire temporaire
            if (Test-Path -Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }

            $fileCount = $result.Result.Count

            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name FileCount -Value $fileCount
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name MemoryPerFile -Value (if ($fileCount -gt 0) { [math]::Round($result.MemoryStatistics.PeakPrivateMemory / $fileCount, 4) } else { 0 })
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name OperationType -Value "Visualization"
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name Iteration -Value $i

            $results += $result.MemoryStatistics

            Write-Log "Itération $i/$Iterations terminée. Pic mémoire: $($result.MemoryStatistics.PeakPrivateMemory) $Unit, $fileCount fichiers générés" -Level Success
        } else {
            Write-Log "Script de visualisation non trouvé: $visualizationScript" -Level Error
            return $null
        }

        # Forcer le garbage collector
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Start-Sleep -Seconds 1
    }

    return $results
}

# Fonction pour mesurer l'utilisation mémoire de la recherche
function Measure-RoadmapSearch {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$Unit = "MB",

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )

    Write-Log "Mesure de l'utilisation mémoire de la recherche dans les roadmaps ($Iterations itérations)..." -Level Info

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "Exécution de l'itération $i/$Iterations..." -Level Info

        $searchScript = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Search-RoadmapVectors.ps1"

        if (Test-Path -Path $searchScript) {
            # Créer un répertoire temporaire pour les tests
            $tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            $tempOutputPath = Join-Path -Path $tempDir -ChildPath "search_results.json"

            # Générer une requête de recherche aléatoire basée sur le contenu du fichier
            $content = Get-Content -Path $RoadmapPath -Raw
            $words = $content -split '\W+' | Where-Object { $_.Length -gt 4 } | Select-Object -Unique
            $randomWords = $words | Get-Random -Count 3
            $searchQuery = $randomWords -join " "

            # Mesurer l'utilisation mémoire de la recherche
            $result = Measure-ScriptMemoryUsage -ScriptBlock {
                param($searchScript, $searchQuery, $tempOutputPath)

                # Exécuter le script de recherche en mode simulation
                $output = & $searchScript -Query $searchQuery -OutputPath $tempOutputPath -OutputFormat "JSON" -SimulateOnly

                return $output
            } -Arguments @($searchScript, $searchQuery, $tempOutputPath) -SampleInterval 100 -Unit $Unit

            # Nettoyer le répertoire temporaire
            if (Test-Path -Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }

            $resultCount = if ($result.Result -is [array]) { $result.Result.Count } else { 0 }

            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name ResultCount -Value $resultCount
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name SearchQuery -Value $searchQuery
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name OperationType -Value "Search"
            $result.MemoryStatistics | Add-Member -MemberType NoteProperty -Name Iteration -Value $i

            $results += $result.MemoryStatistics

            Write-Log "Itération $i/$Iterations terminée. Pic mémoire: $($result.MemoryStatistics.PeakPrivateMemory) $Unit, Requête: '$searchQuery'" -Level Success
        } else {
            Write-Log "Script de recherche non trouvé: $searchScript" -Level Error
            return $null
        }

        # Forcer le garbage collector
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Start-Sleep -Seconds 1
    }

    return $results
}

# Fonction pour formater les résultats en texte
function Format-MemoryResultsAsText {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedReport
    )

    $output = @()
    $output += "=== RAPPORT D'UTILISATION MÉMOIRE DES OPÉRATIONS SUR LES ROADMAPS ==="
    $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "Roadmap: $RoadmapPath"
    $output += ""

    # Regrouper les résultats par type d'opération
    $groupedResults = $Results | Group-Object -Property OperationType

    foreach ($group in $groupedResults) {
        $operationType = $group.Name
        $operationResults = $group.Group

        $avgPeakMemory = [math]::Round(($operationResults | Measure-Object -Property PeakPrivateMemory -Average).Average, 2)
        $maxPeakMemory = [math]::Round(($operationResults | Measure-Object -Property PeakPrivateMemory -Maximum).Maximum, 2)
        $avgMemoryDelta = [math]::Round(($operationResults | Measure-Object -Property PrivateMemoryDelta -Average).Average, 2)
        $avgRetainedMemory = [math]::Round(($operationResults | Measure-Object -Property RetainedPrivateMemory -Average).Average, 2)
        $avgExecutionTime = [math]::Round(($operationResults | Measure-Object -Property ExecutionTime -Average).Average, 2)

        $output += "--- OPÉRATION: $operationType ---"
        $output += "Pic mémoire moyen: $avgPeakMemory $($operationResults[0].Unit)"
        $output += "Pic mémoire maximum: $maxPeakMemory $($operationResults[0].Unit)"
        $output += "Delta mémoire moyen: $avgMemoryDelta $($operationResults[0].Unit)"
        $output += "Mémoire conservée moyenne: $avgRetainedMemory $($operationResults[0].Unit)"
        $output += "Temps d'exécution moyen: $avgExecutionTime secondes"

        if ($operationType -eq "Parsing" -or $operationType -eq "Vectorization") {
            $avgTaskCount = [math]::Round(($operationResults | Measure-Object -Property TaskCount -Average).Average, 0)
            $avgMemoryPerTask = [math]::Round(($operationResults | Measure-Object -Property MemoryPerTask -Average).Average, 4)

            $output += "Nombre moyen de tâches: $avgTaskCount"
            $output += "Mémoire moyenne par tâche: $avgMemoryPerTask $($operationResults[0].Unit)"
        } elseif ($operationType -eq "Visualization") {
            $avgFileCount = [math]::Round(($operationResults | Measure-Object -Property FileCount -Average).Average, 0)
            $avgMemoryPerFile = [math]::Round(($operationResults | Measure-Object -Property MemoryPerFile -Average).Average, 4)

            $output += "Nombre moyen de fichiers générés: $avgFileCount"
            $output += "Mémoire moyenne par fichier: $avgMemoryPerFile $($operationResults[0].Unit)"
        } elseif ($operationType -eq "Search") {
            $avgResultCount = [math]::Round(($operationResults | Measure-Object -Property ResultCount -Average).Average, 0)

            $output += "Nombre moyen de résultats: $avgResultCount"
        }

        if ($DetailedReport) {
            $output += ""
            $output += "Détails des itérations:"

            for ($i = 0; $i -lt $operationResults.Count; $i++) {
                $result = $operationResults[$i]

                $output += "  Itération $($i + 1):"
                $output += "    Pic mémoire: $($result.PeakPrivateMemory) $($result.Unit)"
                $output += "    Delta mémoire: $($result.PrivateMemoryDelta) $($result.Unit)"
                $output += "    Mémoire conservée: $($result.RetainedPrivateMemory) $($result.Unit)"
                $output += "    Temps d'exécution: $($result.ExecutionTime) secondes"

                if ($operationType -eq "Parsing" -or $operationType -eq "Vectorization") {
                    $output += "    Nombre de tâches: $($result.TaskCount)"
                    $output += "    Mémoire par tâche: $($result.MemoryPerTask) $($result.Unit)"
                } elseif ($operationType -eq "Visualization") {
                    $output += "    Nombre de fichiers générés: $($result.FileCount)"
                    $output += "    Mémoire par fichier: $($result.MemoryPerFile) $($result.Unit)"
                } elseif ($operationType -eq "Search") {
                    $output += "    Nombre de résultats: $($result.ResultCount)"
                    $output += "    Requête: $($result.SearchQuery)"
                }
            }
        }

        $output += ""
    }

    return $output -join "`n"
}

# Fonction principale
function Invoke-RoadmapMemoryUsageMeasurement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$OperationType,

        [Parameter(Mandatory = $true)]
        [int]$Iterations,

        [Parameter(Mandatory = $true)]
        [string]$Unit,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedReport
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Fichier de roadmap non trouvé: $RoadmapPath" -Level Error
        return $false
    }

    Write-Log "Démarrage des mesures d'utilisation mémoire pour $RoadmapPath (Type: $OperationType, Itérations: $Iterations)" -Level Info

    $allResults = @()

    # Exécuter les mesures selon le type d'opération
    switch ($OperationType) {
        "Parsing" {
            $results = Measure-RoadmapParsing -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($results) {
                $allResults += $results
            }
        }
        "Vectorization" {
            $results = Measure-RoadmapVectorization -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($results) {
                $allResults += $results
            }
        }
        "Visualization" {
            $results = Measure-RoadmapVisualization -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($results) {
                $allResults += $results
            }
        }
        "Search" {
            $results = Measure-RoadmapSearch -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($results) {
                $allResults += $results
            }
        }
        "All" {
            # Exécuter toutes les mesures
            $parsingResults = Measure-RoadmapParsing -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($parsingResults) {
                $allResults += $parsingResults
            }

            $vectorizationResults = Measure-RoadmapVectorization -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($vectorizationResults) {
                $allResults += $vectorizationResults
            }

            $visualizationResults = Measure-RoadmapVisualization -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($visualizationResults) {
                $allResults += $visualizationResults
            }

            $searchResults = Measure-RoadmapSearch -RoadmapPath $RoadmapPath -Unit $Unit -Iterations $Iterations
            if ($searchResults) {
                $allResults += $searchResults
            }
        }
    }

    # Formater et enregistrer les résultats
    if ($allResults.Count -gt 0) {
        $formattedResults = Format-MemoryResultsAsText -Results $allResults -RoadmapPath $RoadmapPath -DetailedReport:$DetailedReport

        if ($OutputPath) {
            $formattedResults | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Résultats enregistrés dans: $OutputPath" -Level Success
        } else {
            Write-Output $formattedResults
        }
    } else {
        Write-Log "Aucun résultat obtenu." -Level Warning
    }

    return $allResults
}

# Exécution principale
try {
    $result = Invoke-RoadmapMemoryUsageMeasurement -RoadmapPath $RoadmapPath -OperationType $OperationType -Iterations $Iterations -Unit $Unit -OutputPath $OutputPath -OutputFormat $OutputFormat -DetailedReport:$DetailedReport

    if ($result) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-Log "Erreur lors de l'exécution des mesures d'utilisation mémoire: $_" -Level Error
    exit 2
}

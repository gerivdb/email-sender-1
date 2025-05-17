﻿# Verify-RoadmapVectorization.ps1
# Script pour vérifier que la vectorisation des tâches de roadmap dans Qdrant est complète

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapDir = "projet\roadmaps\plans\consolidated",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "projet\roadmaps\analysis\verification_report.md",

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "..\utils\Common-Utils.ps1"

if (Test-Path -Path $utilsPath) {
    . $utilsPath
} else {
    Write-Error "Le fichier d'utilitaires communs est introuvable: $utilsPath"
    exit 1
}

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour analyser un fichier Markdown et extraire les tâches
function Get-MarkdownTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Extraire les tâches avec regex
        $taskPattern = '- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'
        $matches = [regex]::Matches($content, $taskPattern)

        $tasks = @()
        foreach ($match in $matches) {
            $status = $match.Groups[1].Value
            $taskId = $match.Groups[2].Value
            $description = $match.Groups[3].Value.Trim()

            $tasks += [PSCustomObject]@{
                TaskId      = $taskId
                Description = $description
                Status      = if ($status -match '[xX]') { "completed" } else { "pending" }
                FilePath    = $FilePath
            }
        }

        return $tasks
    } catch {
        Write-Log "Erreur lors de l'analyse du fichier $FilePath : $_" -Level Error
        return @()
    }
}

# Fonction pour vérifier l'état de Qdrant
function Test-QdrantConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        return $true
    } catch {
        Write-Log "Erreur de connexion à Qdrant: $_" -Level Error
        return $false
    }
}

# Fonction pour vérifier si une collection existe
function Test-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        $collections = $response.result.collections
        return $collections | Where-Object { $_.name -eq $CollectionName }
    } catch {
        Write-Log "Erreur lors de la vérification de la collection: $_" -Level Error
        return $null
    }
}

# Fonction pour récupérer les tâches vectorisées dans Qdrant
function Get-QdrantTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    try {
        # Créer un script Python temporaire pour récupérer les tâches
        $tempScript = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

        $scriptContent = @"
import json
import requests
import sys

def main():
    qdrant_url = "$QdrantUrl"
    collection_name = "$CollectionName"

    try:
        # Récupérer les informations sur la collection
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"Erreur lors de la récupération des informations sur la collection: {response.text}")
            return 1

        collection_info = response.json()["result"]
        vectors_count = collection_info["vectors_count"]

        if vectors_count == 0:
            print(json.dumps([]))
            return 0

        # Récupérer tous les points
        scroll_response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={"limit": vectors_count, "with_payload": True, "with_vectors": False}
        )

        if scroll_response.status_code != 200:
            print(f"Erreur lors de la récupération des points: {scroll_response.text}")
            return 1

        points = scroll_response.json()["result"]["points"]

        # Extraire les tâches
        tasks = []
        for point in points:
            if "taskId" in point["payload"]:
                task = {
                    "TaskId": point["payload"]["taskId"],
                    "Description": point["payload"].get("description", ""),
                    "Status": point["payload"].get("status", ""),
                    "QdrantId": point["id"]
                }
                tasks.append(task)

        print(json.dumps(tasks))
        return 0

    except Exception as e:
        print(f"Exception: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
"@

        $scriptContent | Set-Content -Path $tempScript -Encoding UTF8

        # Exécuter le script Python
        $result = python $tempScript 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de la récupération des tâches depuis Qdrant" -Level Error
            Write-Log $result -Level Error
            return @()
        }

        # Convertir le résultat JSON en objets PowerShell
        $tasks = $result | ConvertFrom-Json
        return $tasks
    } catch {
        Write-Log "Exception lors de la récupération des tâches: $_" -Level Error
        return @()
    } finally {
        # Supprimer le script temporaire
        if (Test-Path -Path $tempScript) {
            Remove-Item -Path $tempScript -Force
        }
    }
}

# Fonction principale
function Start-Verification {
    [CmdletBinding()]
    param()

    # Vérifier la connexion à Qdrant
    Write-Log "Vérification de la connexion à Qdrant..." -Level Info
    $connected = Test-QdrantConnection -QdrantUrl $QdrantUrl

    if (-not $connected) {
        Write-Log "Impossible de se connecter à Qdrant. Vérifiez que le conteneur est en cours d'exécution." -Level Error
        return
    }

    Write-Log "Connexion à Qdrant établie." -Level Success

    # Vérifier l'existence de la collection
    Write-Log "Vérification de l'existence de la collection $CollectionName..." -Level Info
    $collection = Test-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    if ($null -eq $collection) {
        Write-Log "La collection $CollectionName n'existe pas." -Level Error
        return
    }

    Write-Log "Collection $CollectionName trouvée." -Level Success

    # Analyser les fichiers Markdown
    Write-Log "Analyse des fichiers Markdown dans $RoadmapDir..." -Level Info
    $files = Get-ChildItem -Path $RoadmapDir -Filter "*.md" -Recurse

    if ($files.Count -eq 0) {
        Write-Log "Aucun fichier Markdown trouvé dans $RoadmapDir" -Level Warning
        return
    }

    Write-Log "Nombre de fichiers Markdown trouvés: $($files.Count)" -Level Info

    $allTasks = @()
    foreach ($file in $files) {
        Write-Log "Analyse du fichier $($file.Name)..." -Level Info
        $tasks = Get-MarkdownTasks -FilePath $file.FullName
        Write-Log "  - $($tasks.Count) tâches trouvées" -Level Info
        $allTasks += $tasks
    }

    Write-Log "Nombre total de tâches trouvées: $($allTasks.Count)" -Level Info

    # Récupérer les tâches vectorisées dans Qdrant
    Write-Log "Récupération des tâches vectorisées dans Qdrant..." -Level Info
    $qdrantTasks = Get-QdrantTasks -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    Write-Log "Nombre de tâches vectorisées dans Qdrant: $($qdrantTasks.Count)" -Level Info

    # Comparer les tâches
    $markdownTaskIds = $allTasks | ForEach-Object { $_.TaskId }
    $qdrantTaskIds = $qdrantTasks | ForEach-Object { $_.TaskId }

    $missingTasks = $markdownTaskIds | Where-Object { $_ -notin $qdrantTaskIds }
    $extraTasks = $qdrantTaskIds | Where-Object { $_ -notin $markdownTaskIds }

    if ($missingTasks.Count -eq 0 -and $extraTasks.Count -eq 0) {
        Write-Log "Vectorisation complète: toutes les tâches sont correctement vectorisées." -Level Success
        $verificationStatus = "SUCCESS"
    } else {
        if ($missingTasks.Count -gt 0) {
            Write-Log "Tâches manquantes dans Qdrant: $($missingTasks.Count)" -Level Warning
            Write-Log "Exemples de tâches manquantes: $($missingTasks | Select-Object -First 5)" -Level Warning
        }

        if ($extraTasks.Count -gt 0) {
            Write-Log "Tâches supplémentaires dans Qdrant: $($extraTasks.Count)" -Level Warning
            Write-Log "Exemples de tâches supplémentaires: $($extraTasks | Select-Object -First 5)" -Level Warning
        }

        $verificationStatus = "FAILURE"
    }

    # Générer un rapport détaillé si demandé
    if ($GenerateReport) {
        $reportDir = Split-Path -Parent $ReportPath

        if (-not (Test-Path -Path $reportDir)) {
            New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
        }

        $report = @"
# Rapport de vérification de vectorisation
*Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## Résumé

- **Statut de la vérification**: $verificationStatus
- **Nombre total de fichiers Markdown**: $($files.Count)
- **Nombre total de tâches dans les fichiers**: $($allTasks.Count)
- **Nombre de tâches vectorisées dans Qdrant**: $($qdrantTasks.Count)
- **Tâches manquantes dans Qdrant**: $($missingTasks.Count)
- **Tâches supplémentaires dans Qdrant**: $($extraTasks.Count)

## Détails des tâches manquantes

"@

        if ($missingTasks.Count -gt 0) {
            $report += "| ID de tâche | Description | Fichier |\n|------------|-------------|--------|\n"

            foreach ($taskId in $missingTasks) {
                $task = $allTasks | Where-Object { $_.TaskId -eq $taskId } | Select-Object -First 1
                $fileName = Split-Path -Leaf $task.FilePath
                $report += "| $($task.TaskId) | $($task.Description) | $fileName |\n"
            }
        } else {
            $report += "Aucune tâche manquante.\n"
        }

        $report += @"

## Détails des tâches supplémentaires

"@

        if ($extraTasks.Count -gt 0) {
            $report += "| ID de tâche | Description | ID Qdrant |\n|------------|-------------|----------|\n"

            foreach ($taskId in $extraTasks) {
                $task = $qdrantTasks | Where-Object { $_.TaskId -eq $taskId } | Select-Object -First 1
                $report += "| $($task.TaskId) | $($task.Description) | $($task.QdrantId) |\n"
            }
        } else {
            $report += "Aucune tâche supplémentaire.\n"
        }

        $report | Set-Content -Path $ReportPath -Encoding UTF8
        Write-Log "Rapport de vérification généré: $ReportPath" -Level Success
    }

    # Retourner le statut de la vérification
    return $verificationStatus -eq "SUCCESS"
}

# Exécuter la vérification
$result = Start-Verification
exit [int](!$result)

# Update-TaskStatusQdrant.ps1
# Script pour mettre à jour le statut des tâches dans Qdrant et dans le fichier Markdown
# Version: 1.0
# Date: 2025-05-02

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Completed", "Incomplete")]
    [string]$Status,
    
    [Parameter()]
    [string]$RoadmapPath = "projet\roadmaps\active\roadmap_active.md",
    
    [Parameter()]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter()]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter()]
    [string]$Comment = "",
    
    [Parameter()]
    [switch]$Force
)

# Importer les modules communs
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$commonPath = Join-Path -Path $scriptPath -ChildPath "..\common"
$modulePath = Join-Path -Path $commonPath -ChildPath "RoadmapModule.psm1"

if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module commun introuvable: $modulePath"
    exit 1
}

function Test-QdrantConnection {
    param (
        [string]$Url
    )

    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -ErrorAction Stop
        Write-Log "Qdrant est accessible à l'URL: $Url" -Level Success
        return $true
    } catch {
        Write-Log "Impossible de se connecter à Qdrant à l'URL: $Url" -Level Error
        Write-Log "Erreur: $_" -Level Error
        return $false
    }
}

function Get-PythonUpdateScript {
    param (
        [string]$TaskId,
        [string]$Status,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$Comment,
        [bool]$Force
    )

    $pythonScript = @"
import os
import sys
import json
import requests
from datetime import datetime

# Configuration
qdrant_url = r'$QdrantUrl'
collection_name = '$CollectionName'
task_id = r'$TaskId'
status = r'$Status'
comment = r'$Comment'
force = $($Force.ToString().ToLower() -replace "true", "True" -replace "false", "False")

# Fonction pour mettre à jour le statut d'une tâche dans Qdrant
def update_task_status():
    try:
        # Vérifier si Qdrant est accessible
        try:
            response = requests.get(f"{qdrant_url}/collections")
            if response.status_code != 200:
                print(f"Erreur lors de la connexion à Qdrant: {response.status_code}")
                return False
        except Exception as e:
            print(f"Erreur lors de la connexion à Qdrant: {str(e)}")
            return False
            
        # Vérifier si la collection existe
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"La collection {collection_name} n'existe pas dans Qdrant.")
            return False
            
        # Rechercher la tâche par son ID
        search_request = {
            "filter": {
                "must": [
                    {
                        "key": "originalId",
                        "match": {"value": task_id}
                    }
                ]
            },
            "limit": 1,
            "with_payload": True,
            "with_vector": False
        }
        
        response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json=search_request
        )
        
        if response.status_code != 200:
            print(f"Erreur lors de la recherche de la tâche: {response.status_code}")
            print(response.text)
            return False
            
        # Vérifier si la tâche a été trouvée
        result = response.json()
        if not result['result']['points']:
            print(f"Tâche avec ID '{task_id}' non trouvée dans Qdrant.")
            return False
            
        # Récupérer le point
        point = result['result']['points'][0]
        point_id = point['id']
        payload = point['payload']
        
        # Vérifier si le statut est déjà celui demandé
        if payload.get('status') == status and not force:
            print(f"La tâche '{task_id}' a déjà le statut '{status}'.")
            return True
            
        # Mettre à jour le statut
        old_status = payload.get('status', 'Unknown')
        payload['status'] = status
        
        # Ajouter l'historique des modifications
        if 'history' not in payload:
            payload['history'] = []
            
        # Ajouter l'entrée d'historique
        history_entry = {
            'timestamp': datetime.now().isoformat(),
            'old_status': old_status,
            'new_status': status,
            'comment': comment,
            'user': os.environ.get('USERNAME', 'unknown')
        }
        
        payload['history'].append(history_entry)
        
        # Mettre à jour la date de dernière modification
        payload['lastUpdated'] = datetime.now().strftime('%Y-%m-%d')
        
        # Mettre à jour le texte
        payload['text'] = f"ID: {task_id} | Description: {payload.get('description', 'N/A')} | Section: {payload.get('section', 'N/A')} | Status: {status}"
        
        # Mettre à jour le point dans Qdrant
        update_request = {
            "points": [
                {
                    "id": point_id,
                    "payload": payload
                }
            ]
        }
        
        response = requests.put(
            f"{qdrant_url}/collections/{collection_name}/points",
            json=update_request
        )
        
        if response.status_code != 200:
            print(f"Erreur lors de la mise à jour du statut: {response.status_code}")
            print(response.text)
            return False
            
        # Préparer le résultat
        result = {
            "taskId": task_id,
            "description": payload.get("description", ""),
            "oldStatus": old_status,
            "newStatus": status,
            "lastUpdated": payload['lastUpdated'],
            "historyEntryAdded": True
        }
        
        # Afficher le résultat au format JSON
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return True
        
    except Exception as e:
        print(f"Erreur lors de la mise à jour du statut: {str(e)}")
        return False

if __name__ == "__main__":
    if not task_id:
        print("Veuillez spécifier un ID de tâche avec le paramètre -TaskId.")
        sys.exit(1)
        
    print(f"Mise à jour du statut de la tâche '{task_id}' à '{status}'...")
    
    if update_task_status():
        print("Mise à jour réussie dans Qdrant.")
        sys.exit(0)
    else:
        print("Échec de la mise à jour dans Qdrant.")
        sys.exit(1)
"@

    return $pythonScript
}

function Update-TaskStatusInQdrant {
    param (
        [string]$TaskId,
        [string]$Status,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$Comment,
        [bool]$Force
    )
    
    # Créer le script Python pour la mise à jour
    Write-Log "Création du script Python pour la mise à jour du statut..." -Level Info
    $pythonScript = Get-PythonUpdateScript -TaskId $TaskId -Status $Status -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Comment $Comment -Force $Force
    
    # Créer un fichier temporaire pour le script Python
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8
    
    # Exécuter le script Python
    Write-Log "Exécution du script Python pour la mise à jour du statut..." -Level Info
    $output = python $tempFile 2>&1
    $exitCode = $LASTEXITCODE
    
    # Supprimer le fichier temporaire
    Remove-Item -Path $tempFile -Force
    
    # Vérifier le résultat
    if ($exitCode -eq 0) {
        # Extraire les résultats JSON de la sortie
        $jsonStartIndex = $output.IndexOf("{")
        $jsonEndIndex = $output.LastIndexOf("}")
        
        if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
            $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
            $result = $jsonString | ConvertFrom-Json
            
            # Afficher le résultat
            Write-Host "`nMise à jour du statut effectuée avec succès:" -ForegroundColor Green
            Write-Host "ID de la tâche: $($result.taskId)" -ForegroundColor Cyan
            Write-Host "Description: $($result.description)" -ForegroundColor Cyan
            Write-Host "Ancien statut: $($result.oldStatus)" -ForegroundColor Yellow
            Write-Host "Nouveau statut: $($result.newStatus)" -ForegroundColor Green
            Write-Host "Dernière mise à jour: $($result.lastUpdated)" -ForegroundColor Cyan
            
            Write-Log "Mise à jour du statut réussie dans Qdrant." -Level Success
            return $true
        } else {
            Write-Log "Impossible d'extraire les résultats JSON de la sortie." -Level Warning
            Write-Log "Sortie: $output" -Level Info
            return $true
        }
    } else {
        Write-Log "Échec de la mise à jour du statut dans Qdrant." -Level Error
        Write-Log "Sortie: $output" -Level Error
        return $false
    }
}

function Update-TaskStatusInMarkdown {
    param (
        [string]$TaskId,
        [string]$Status,
        [string]$RoadmapPath,
        [bool]$Force
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-FileExists -FilePath $RoadmapPath)) {
        return $false
    }
    
    # Mettre à jour le statut dans le fichier Markdown
    $checkbox = if ($Status -eq 'Completed') { 'x' } else { ' ' }
    $content = Get-Content -Path $RoadmapPath -Raw
    
    $pattern = "- \[([ x])\] \*\*$([regex]::Escape($TaskId))\*\*"
    $replacement = "- [$checkbox] **$TaskId**"
    
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    
    if ($content -ne $newContent) {
        Set-Content -Path $RoadmapPath -Value $newContent -Encoding UTF8
        Write-Log "Statut de la tâche $TaskId mis à jour à $Status dans le fichier Markdown." -Level Success
        return $true
    } else {
        Write-Log "Tâche $TaskId non trouvée ou déjà dans l'état $Status dans le fichier Markdown." -Level Warning
        return $false
    }
}

function Save-TaskStatusHistory {
    param (
        [string]$TaskId,
        [string]$OldStatus,
        [string]$NewStatus,
        [string]$Comment
    )
    
    # Créer le répertoire d'historique s'il n'existe pas
    $historyDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\projet\logs\task_history"
    if (-not (Test-Path -Path $historyDir)) {
        New-Item -Path $historyDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer le fichier d'historique pour la tâche
    $historyFile = Join-Path -Path $historyDir -ChildPath "$TaskId.json"
    
    # Créer l'entrée d'historique
    $historyEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        old_status = $OldStatus
        new_status = $NewStatus
        comment = $Comment
        user = $env:USERNAME
    }
    
    # Charger l'historique existant ou créer un nouveau
    if (Test-Path -Path $historyFile) {
        $history = Get-Content -Path $historyFile -Raw | ConvertFrom-Json
    } else {
        $history = @()
    }
    
    # Ajouter la nouvelle entrée
    $history += $historyEntry
    
    # Enregistrer l'historique
    $history | ConvertTo-Json -Depth 10 | Set-Content -Path $historyFile -Encoding UTF8
    
    Write-Log "Historique de la tâche $TaskId mis à jour." -Level Success
    return $true
}

# Fonction principale
function Invoke-TaskStatusUpdate {
    # Vérifier la connexion à Qdrant
    if (-not (Test-QdrantConnection -Url $QdrantUrl)) {
        return
    }
    
    # Mettre à jour le statut dans Qdrant
    $qdrantResult = Update-TaskStatusInQdrant -TaskId $TaskId -Status $Status -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Comment $Comment -Force $Force
    
    # Mettre à jour le statut dans le fichier Markdown
    $markdownResult = Update-TaskStatusInMarkdown -TaskId $TaskId -Status $Status -RoadmapPath $RoadmapPath -Force $Force
    
    # Enregistrer l'historique des modifications
    $oldStatus = if ($Status -eq "Completed") { "Incomplete" } else { "Completed" }
    $historyResult = Save-TaskStatusHistory -TaskId $TaskId -OldStatus $oldStatus -NewStatus $Status -Comment $Comment
    
    # Afficher le résultat
    if ($qdrantResult -and $markdownResult -and $historyResult) {
        Write-Log "Mise à jour du statut de la tâche $TaskId réussie." -Level Success
    } else {
        Write-Log "Mise à jour du statut de la tâche $TaskId partiellement réussie." -Level Warning
    }
}

# Exécuter la fonction principale
Invoke-TaskStatusUpdate

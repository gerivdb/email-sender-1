# Update-TaskStatusQdrant.ps1
# Script pour mettre Ã  jour le statut des tÃ¢ches dans Qdrant et dans le fichier Markdown
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
        Write-Log "Qdrant est accessible Ã  l'URL: $Url" -Level Success
        return $true
    } catch {
        Write-Log "Impossible de se connecter Ã  Qdrant Ã  l'URL: $Url" -Level Error
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

# Fonction pour mettre Ã  jour le statut d'une tÃ¢che dans Qdrant
def update_task_status():
    try:
        # VÃ©rifier si Qdrant est accessible
        try:
            response = requests.get(f"{qdrant_url}/collections")
            if response.status_code != 200:
                print(f"Erreur lors de la connexion Ã  Qdrant: {response.status_code}")
                return False
        except Exception as e:
            print(f"Erreur lors de la connexion Ã  Qdrant: {str(e)}")
            return False
            
        # VÃ©rifier si la collection existe
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"La collection {collection_name} n'existe pas dans Qdrant.")
            return False
            
        # Rechercher la tÃ¢che par son ID
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
            print(f"Erreur lors de la recherche de la tÃ¢che: {response.status_code}")
            print(response.text)
            return False
            
        # VÃ©rifier si la tÃ¢che a Ã©tÃ© trouvÃ©e
        result = response.json()
        if not result['result']['points']:
            print(f"TÃ¢che avec ID '{task_id}' non trouvÃ©e dans Qdrant.")
            return False
            
        # RÃ©cupÃ©rer le point
        point = result['result']['points'][0]
        point_id = point['id']
        payload = point['payload']
        
        # VÃ©rifier si le statut est dÃ©jÃ  celui demandÃ©
        if payload.get('status') == status and not force:
            print(f"La tÃ¢che '{task_id}' a dÃ©jÃ  le statut '{status}'.")
            return True
            
        # Mettre Ã  jour le statut
        old_status = payload.get('status', 'Unknown')
        payload['status'] = status
        
        # Ajouter l'historique des modifications
        if 'history' not in payload:
            payload['history'] = []
            
        # Ajouter l'entrÃ©e d'historique
        history_entry = {
            'timestamp': datetime.now().isoformat(),
            'old_status': old_status,
            'new_status': status,
            'comment': comment,
            'user': os.environ.get('USERNAME', 'unknown')
        }
        
        payload['history'].append(history_entry)
        
        # Mettre Ã  jour la date de derniÃ¨re modification
        payload['lastUpdated'] = datetime.now().strftime('%Y-%m-%d')
        
        # Mettre Ã  jour le texte
        payload['text'] = f"ID: {task_id} | Description: {payload.get('description', 'N/A')} | Section: {payload.get('section', 'N/A')} | Status: {status}"
        
        # Mettre Ã  jour le point dans Qdrant
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
            print(f"Erreur lors de la mise Ã  jour du statut: {response.status_code}")
            print(response.text)
            return False
            
        # PrÃ©parer le rÃ©sultat
        result = {
            "taskId": task_id,
            "description": payload.get("description", ""),
            "oldStatus": old_status,
            "newStatus": status,
            "lastUpdated": payload['lastUpdated'],
            "historyEntryAdded": True
        }
        
        # Afficher le rÃ©sultat au format JSON
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return True
        
    except Exception as e:
        print(f"Erreur lors de la mise Ã  jour du statut: {str(e)}")
        return False

if __name__ == "__main__":
    if not task_id:
        print("Veuillez spÃ©cifier un ID de tÃ¢che avec le paramÃ¨tre -TaskId.")
        sys.exit(1)
        
    print(f"Mise Ã  jour du statut de la tÃ¢che '{task_id}' Ã  '{status}'...")
    
    if update_task_status():
        print("Mise Ã  jour rÃ©ussie dans Qdrant.")
        sys.exit(0)
    else:
        print("Ã‰chec de la mise Ã  jour dans Qdrant.")
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
    
    # CrÃ©er le script Python pour la mise Ã  jour
    Write-Log "CrÃ©ation du script Python pour la mise Ã  jour du statut..." -Level Info
    $pythonScript = Get-PythonUpdateScript -TaskId $TaskId -Status $Status -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Comment $Comment -Force $Force
    
    # CrÃ©er un fichier temporaire pour le script Python
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8
    
    # ExÃ©cuter le script Python
    Write-Log "ExÃ©cution du script Python pour la mise Ã  jour du statut..." -Level Info
    $output = python $tempFile 2>&1
    $exitCode = $LASTEXITCODE
    
    # Supprimer le fichier temporaire
    Remove-Item -Path $tempFile -Force
    
    # VÃ©rifier le rÃ©sultat
    if ($exitCode -eq 0) {
        # Extraire les rÃ©sultats JSON de la sortie
        $jsonStartIndex = $output.IndexOf("{")
        $jsonEndIndex = $output.LastIndexOf("}")
        
        if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
            $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
            $result = $jsonString | ConvertFrom-Json
            
            # Afficher le rÃ©sultat
            Write-Host "`nMise Ã  jour du statut effectuÃ©e avec succÃ¨s:" -ForegroundColor Green
            Write-Host "ID de la tÃ¢che: $($result.taskId)" -ForegroundColor Cyan
            Write-Host "Description: $($result.description)" -ForegroundColor Cyan
            Write-Host "Ancien statut: $($result.oldStatus)" -ForegroundColor Yellow
            Write-Host "Nouveau statut: $($result.newStatus)" -ForegroundColor Green
            Write-Host "DerniÃ¨re mise Ã  jour: $($result.lastUpdated)" -ForegroundColor Cyan
            
            Write-Log "Mise Ã  jour du statut rÃ©ussie dans Qdrant." -Level Success
            return $true
        } else {
            Write-Log "Impossible d'extraire les rÃ©sultats JSON de la sortie." -Level Warning
            Write-Log "Sortie: $output" -Level Info
            return $true
        }
    } else {
        Write-Log "Ã‰chec de la mise Ã  jour du statut dans Qdrant." -Level Error
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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-FileExists -FilePath $RoadmapPath)) {
        return $false
    }
    
    # Mettre Ã  jour le statut dans le fichier Markdown
    $checkbox = if ($Status -eq 'Completed') { 'x' } else { ' ' }
    $content = Get-Content -Path $RoadmapPath -Raw
    
    $pattern = "- \[([ x])\] \*\*$([regex]::Escape($TaskId))\*\*"
    $replacement = "- [$checkbox] **$TaskId**"
    
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    
    if ($content -ne $newContent) {
        Set-Content -Path $RoadmapPath -Value $newContent -Encoding UTF8
        Write-Log "Statut de la tÃ¢che $TaskId mis Ã  jour Ã  $Status dans le fichier Markdown." -Level Success
        return $true
    } else {
        Write-Log "TÃ¢che $TaskId non trouvÃ©e ou dÃ©jÃ  dans l'Ã©tat $Status dans le fichier Markdown." -Level Warning
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
    
    # CrÃ©er le rÃ©pertoire d'historique s'il n'existe pas
    $historyDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\projet\logs\task_history"
    if (-not (Test-Path -Path $historyDir)) {
        New-Item -Path $historyDir -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le fichier d'historique pour la tÃ¢che
    $historyFile = Join-Path -Path $historyDir -ChildPath "$TaskId.json"
    
    # CrÃ©er l'entrÃ©e d'historique
    $historyEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        old_status = $OldStatus
        new_status = $NewStatus
        comment = $Comment
        user = $env:USERNAME
    }
    
    # Charger l'historique existant ou crÃ©er un nouveau
    if (Test-Path -Path $historyFile) {
        $history = Get-Content -Path $historyFile -Raw | ConvertFrom-Json
    } else {
        $history = @()
    }
    
    # Ajouter la nouvelle entrÃ©e
    $history += $historyEntry
    
    # Enregistrer l'historique
    $history | ConvertTo-Json -Depth 10 | Set-Content -Path $historyFile -Encoding UTF8
    
    Write-Log "Historique de la tÃ¢che $TaskId mis Ã  jour." -Level Success
    return $true
}

# Fonction principale
function Invoke-TaskStatusUpdate {
    # VÃ©rifier la connexion Ã  Qdrant
    if (-not (Test-QdrantConnection -Url $QdrantUrl)) {
        return
    }
    
    # Mettre Ã  jour le statut dans Qdrant
    $qdrantResult = Update-TaskStatusInQdrant -TaskId $TaskId -Status $Status -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Comment $Comment -Force $Force
    
    # Mettre Ã  jour le statut dans le fichier Markdown
    $markdownResult = Update-TaskStatusInMarkdown -TaskId $TaskId -Status $Status -RoadmapPath $RoadmapPath -Force $Force
    
    # Enregistrer l'historique des modifications
    $oldStatus = if ($Status -eq "Completed") { "Incomplete" } else { "Completed" }
    $historyResult = Save-TaskStatusHistory -TaskId $TaskId -OldStatus $oldStatus -NewStatus $Status -Comment $Comment
    
    # Afficher le rÃ©sultat
    if ($qdrantResult -and $markdownResult -and $historyResult) {
        Write-Log "Mise Ã  jour du statut de la tÃ¢che $TaskId rÃ©ussie." -Level Success
    } else {
        Write-Log "Mise Ã  jour du statut de la tÃ¢che $TaskId partiellement rÃ©ussie." -Level Warning
    }
}

# ExÃ©cuter la fonction principale
Invoke-TaskStatusUpdate

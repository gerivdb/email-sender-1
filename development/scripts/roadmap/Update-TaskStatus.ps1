# Update-TaskStatus.ps1
# Script pour mettre Ã  jour le statut des tÃ¢ches avec historique

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Complete", "Incomplete", "InProgress", "Blocked", "Deferred")]
    [string]$Status,
    
    [Parameter(Mandatory = $false)]
    [string]$Comment,
    
    [Parameter(Mandatory = $false)]
    [string]$Assignee,
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet\roadmaps\active\roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$HistoryPath = "projet\roadmaps\history\task_history.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateRoadmap,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Fonction pour vÃ©rifier si Python est installÃ©
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            Write-Log "Python $($Matches[1]) dÃ©tectÃ©." -Level Info
            return $true
        }
        else {
            Write-Log "Python n'est pas correctement installÃ©." -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Python n'est pas installÃ© ou n'est pas dans le PATH." -Level Error
        return $false
    }
}

# Fonction pour vÃ©rifier si les packages Python nÃ©cessaires sont installÃ©s
function Test-PythonPackages {
    $requiredPackages = @("chromadb", "json", "datetime")
    $missingPackages = @()
    
    foreach ($package in $requiredPackages) {
        $checkPackage = python -c "import $package" 2>&1
        if ($LASTEXITCODE -ne 0) {
            $missingPackages += $package
        }
    }
    
    if ($missingPackages.Count -gt 0) {
        Write-Log "Packages Python manquants: $($missingPackages -join ', ')" -Level Warning
        
        $installPackages = Read-Host "Voulez-vous installer les packages manquants? (O/N)"
        if ($installPackages -eq "O" -or $installPackages -eq "o") {
            foreach ($package in $missingPackages) {
                Write-Log "Installation du package $package..." -Level Info
                python -m pip install $package
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "Ã‰chec de l'installation du package $package." -Level Error
                    return $false
                }
            }
            Write-Log "Tous les packages ont Ã©tÃ© installÃ©s avec succÃ¨s." -Level Success
            return $true
        }
        else {
            Write-Log "Installation des packages annulÃ©e. Le script ne peut pas continuer." -Level Error
            return $false
        }
    }
    
    Write-Log "Tous les packages Python requis sont installÃ©s." -Level Success
    return $true
}

# Fonction pour crÃ©er un script Python temporaire pour la mise Ã  jour du statut
function New-StatusUpdateScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskId,
        
        [Parameter(Mandatory = $true)]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [string]$Comment,
        
        [Parameter(Mandatory = $false)]
        [string]$Assignee,
        
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$HistoryPath
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import json
import chromadb
import os
import sys
from datetime import datetime

def main():
    # ParamÃ¨tres
    task_id = r'$TaskId'
    new_status = r'$Status'
    comment = r'$Comment'
    assignee = r'$Assignee'
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    history_path = r'$HistoryPath'
    
    # Initialiser le client Chroma
    try:
        client = chromadb.PersistentClient(path=chroma_db_path)
    except Exception as e:
        print(f"Erreur lors de la connexion Ã  la base Chroma: {e}")
        sys.exit(1)
    
    # VÃ©rifier si la collection existe
    try:
        existing_collections = client.list_collections()
        collection_exists = any(c.name == collection_name for c in existing_collections)
        
        if not collection_exists:
            print(f"La collection {collection_name} n'existe pas dans la base Chroma.")
            sys.exit(1)
        
        # RÃ©cupÃ©rer la collection
        collection = client.get_collection(name=collection_name)
        
        # VÃ©rifier si la tÃ¢che existe
        try:
            task_result = collection.get(ids=[task_id])
            
            if not task_result['ids']:
                print(f"La tÃ¢che avec l'ID {task_id} n'existe pas.")
                sys.exit(1)
            
            # RÃ©cupÃ©rer les mÃ©tadonnÃ©es actuelles
            current_metadata = task_result['metadatas'][0]
            current_status = current_metadata.get('status', 'Unknown')
            
            # CrÃ©er les nouvelles mÃ©tadonnÃ©es
            new_metadata = current_metadata.copy()
            new_metadata['status'] = new_status
            new_metadata['lastUpdated'] = datetime.now().strftime("%Y-%m-%d")
            
            if assignee:
                new_metadata['assignee'] = assignee
            
            # Mettre Ã  jour les mÃ©tadonnÃ©es dans la collection
            collection.update(
                ids=[task_id],
                metadatas=[new_metadata]
            )
            
            # CrÃ©er l'entrÃ©e d'historique
            history_entry = {
                "taskId": task_id,
                "timestamp": datetime.now().isoformat(),
                "oldStatus": current_status,
                "newStatus": new_status,
                "comment": comment if comment else "",
                "assignee": assignee if assignee else new_metadata.get('assignee', ""),
                "user": os.environ.get('USERNAME', 'unknown')
            }
            
            # Charger l'historique existant ou crÃ©er un nouveau
            history_data = {}
            if os.path.exists(history_path):
                try:
                    with open(history_path, 'r', encoding='utf-8') as f:
                        history_data = json.load(f)
                except Exception as e:
                    print(f"Erreur lors du chargement de l'historique: {e}")
                    history_data = {"tasks": {}}
            else:
                # CrÃ©er le dossier si nÃ©cessaire
                os.makedirs(os.path.dirname(history_path), exist_ok=True)
                history_data = {"tasks": {}}
            
            # Ajouter l'entrÃ©e Ã  l'historique
            if task_id not in history_data["tasks"]:
                history_data["tasks"][task_id] = []
            
            history_data["tasks"][task_id].append(history_entry)
            
            # Sauvegarder l'historique
            with open(history_path, 'w', encoding='utf-8') as f:
                json.dump(history_data, f, indent=2, ensure_ascii=False)
            
            # PrÃ©parer le rÃ©sultat
            result = {
                "taskId": task_id,
                "description": current_metadata.get("description", ""),
                "oldStatus": current_status,
                "newStatus": new_status,
                "lastUpdated": new_metadata['lastUpdated'],
                "assignee": new_metadata.get('assignee', ""),
                "historyEntryAdded": True
            }
            
            # Afficher le rÃ©sultat au format JSON
            print(json.dumps(result, indent=2, ensure_ascii=False))
            
        except Exception as e:
            print(f"Erreur lors de la mise Ã  jour du statut: {e}")
            sys.exit(1)
        
    except Exception as e:
        print(f"Erreur lors de l'accÃ¨s Ã  la collection: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction pour mettre Ã  jour le fichier Markdown de la roadmap
function Update-RoadmapMarkdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskId,
        
        [Parameter(Mandatory = $true)]
        [string]$Status
    )
    
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap $RoadmapPath n'existe pas." -Level Error
        return $false
    }
    
    try {
        $content = Get-Content -Path $RoadmapPath -Encoding UTF8 -Raw
        $lines = $content -split "`r?`n"
        $updated = $false
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^\s*-\s+\[([ xX])\]\s+\*\*$TaskId\*\*") {
                $checkbox = switch ($Status) {
                    "Complete" { "x" }
                    "Incomplete" { " " }
                    "InProgress" { "o" }  # Utiliser 'o' pour en cours
                    "Blocked" { "!" }     # Utiliser '!' pour bloquÃ©
                    "Deferred" { ">" }    # Utiliser '>' pour reportÃ©
                    default { " " }
                }
                
                $lines[$i] = $lines[$i] -replace "^\s*-\s+\[([ xX!o>])\]", "- [$checkbox]"
                $updated = $true
                break
            }
        }
        
        if ($updated) {
            $newContent = $lines -join "`r`n"
            Set-Content -Path $RoadmapPath -Value $newContent -Encoding UTF8
            Write-Log "Statut de la tÃ¢che $TaskId mis Ã  jour dans le fichier roadmap." -Level Success
            return $true
        }
        else {
            Write-Log "TÃ¢che $TaskId non trouvÃ©e dans le fichier roadmap." -Level Warning
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la mise Ã  jour du fichier roadmap: $_" -Level Error
        return $false
    }
}

# Fonction principale
function Main {
    # VÃ©rifier si la base Chroma existe
    if (-not (Test-Path -Path $ChromaDbPath)) {
        Write-Log "La base Chroma $ChromaDbPath n'existe pas." -Level Error
        return
    }
    
    # VÃ©rifier si Python est installÃ©
    if (-not (Test-PythonInstalled)) {
        Write-Log "Python est requis pour ce script. Veuillez installer Python et rÃ©essayer." -Level Error
        return
    }
    
    # VÃ©rifier si les packages Python nÃ©cessaires sont installÃ©s
    if (-not (Test-PythonPackages)) {
        Write-Log "Les packages Python requis ne sont pas tous installÃ©s. Le script ne peut pas continuer." -Level Error
        return
    }
    
    # CrÃ©er le dossier d'historique s'il n'existe pas
    $historyFolder = Split-Path -Path $HistoryPath -Parent
    if (-not (Test-Path -Path $historyFolder)) {
        New-Item -Path $historyFolder -ItemType Directory -Force | Out-Null
        Write-Log "Dossier d'historique crÃ©Ã©: $historyFolder" -Level Info
    }
    
    # CrÃ©er le script Python temporaire
    Write-Log "CrÃ©ation du script Python pour la mise Ã  jour du statut..." -Level Info
    $pythonScript = New-StatusUpdateScript -TaskId $TaskId -Status $Status -Comment $Comment -Assignee $Assignee -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -HistoryPath $HistoryPath
    
    # ExÃ©cuter le script Python et capturer la sortie JSON
    Write-Log "Mise Ã  jour du statut de la tÃ¢che $TaskId vers '$Status'..." -Level Info
    $output = python $pythonScript 2>&1
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    # Extraire les rÃ©sultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("{")
    $jsonEndIndex = $output.LastIndexOf("}")
    
    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $result = $jsonString | ConvertFrom-Json
        
        # Mettre Ã  jour le fichier Markdown si demandÃ©
        if ($UpdateRoadmap) {
            $markdownUpdated = Update-RoadmapMarkdown -RoadmapPath $RoadmapPath -TaskId $TaskId -Status $Status
            
            if ($markdownUpdated) {
                Write-Log "Fichier Markdown de la roadmap mis Ã  jour avec succÃ¨s." -Level Success
            }
            else {
                Write-Log "Ã‰chec de la mise Ã  jour du fichier Markdown de la roadmap." -Level Warning
            }
        }
        
        # Afficher le rÃ©sultat
        Write-Host "`nMise Ã  jour du statut effectuÃ©e avec succÃ¨s:" -ForegroundColor Green
        Write-Host "ID de la tÃ¢che: $($result.taskId)" -ForegroundColor Cyan
        Write-Host "Description: $($result.description)" -ForegroundColor Cyan
        Write-Host "Ancien statut: $($result.oldStatus)" -ForegroundColor Yellow
        Write-Host "Nouveau statut: $($result.newStatus)" -ForegroundColor Green
        Write-Host "DerniÃ¨re mise Ã  jour: $($result.lastUpdated)" -ForegroundColor Cyan
        
        if ($result.assignee) {
            Write-Host "AssignÃ© Ã : $($result.assignee)" -ForegroundColor Cyan
        }
        
        Write-Log "Mise Ã  jour du statut terminÃ©e avec succÃ¨s." -Level Success
    }
    else {
        Write-Log "Erreur lors de la mise Ã  jour du statut." -Level Error
    }
}

# ExÃ©cuter la fonction principale
Main

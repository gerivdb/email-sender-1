# Update-TaskStatus.ps1
# Script pour mettre à jour le statut des tâches avec historique

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

# Fonction pour écrire des messages de log
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

# Fonction pour vérifier si Python est installé
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            Write-Log "Python $($Matches[1]) détecté." -Level Info
            return $true
        }
        else {
            Write-Log "Python n'est pas correctement installé." -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Python n'est pas installé ou n'est pas dans le PATH." -Level Error
        return $false
    }
}

# Fonction pour vérifier si les packages Python nécessaires sont installés
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
                    Write-Log "Échec de l'installation du package $package." -Level Error
                    return $false
                }
            }
            Write-Log "Tous les packages ont été installés avec succès." -Level Success
            return $true
        }
        else {
            Write-Log "Installation des packages annulée. Le script ne peut pas continuer." -Level Error
            return $false
        }
    }
    
    Write-Log "Tous les packages Python requis sont installés." -Level Success
    return $true
}

# Fonction pour créer un script Python temporaire pour la mise à jour du statut
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
    # Paramètres
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
        print(f"Erreur lors de la connexion à la base Chroma: {e}")
        sys.exit(1)
    
    # Vérifier si la collection existe
    try:
        existing_collections = client.list_collections()
        collection_exists = any(c.name == collection_name for c in existing_collections)
        
        if not collection_exists:
            print(f"La collection {collection_name} n'existe pas dans la base Chroma.")
            sys.exit(1)
        
        # Récupérer la collection
        collection = client.get_collection(name=collection_name)
        
        # Vérifier si la tâche existe
        try:
            task_result = collection.get(ids=[task_id])
            
            if not task_result['ids']:
                print(f"La tâche avec l'ID {task_id} n'existe pas.")
                sys.exit(1)
            
            # Récupérer les métadonnées actuelles
            current_metadata = task_result['metadatas'][0]
            current_status = current_metadata.get('status', 'Unknown')
            
            # Créer les nouvelles métadonnées
            new_metadata = current_metadata.copy()
            new_metadata['status'] = new_status
            new_metadata['lastUpdated'] = datetime.now().strftime("%Y-%m-%d")
            
            if assignee:
                new_metadata['assignee'] = assignee
            
            # Mettre à jour les métadonnées dans la collection
            collection.update(
                ids=[task_id],
                metadatas=[new_metadata]
            )
            
            # Créer l'entrée d'historique
            history_entry = {
                "taskId": task_id,
                "timestamp": datetime.now().isoformat(),
                "oldStatus": current_status,
                "newStatus": new_status,
                "comment": comment if comment else "",
                "assignee": assignee if assignee else new_metadata.get('assignee', ""),
                "user": os.environ.get('USERNAME', 'unknown')
            }
            
            # Charger l'historique existant ou créer un nouveau
            history_data = {}
            if os.path.exists(history_path):
                try:
                    with open(history_path, 'r', encoding='utf-8') as f:
                        history_data = json.load(f)
                except Exception as e:
                    print(f"Erreur lors du chargement de l'historique: {e}")
                    history_data = {"tasks": {}}
            else:
                # Créer le dossier si nécessaire
                os.makedirs(os.path.dirname(history_path), exist_ok=True)
                history_data = {"tasks": {}}
            
            # Ajouter l'entrée à l'historique
            if task_id not in history_data["tasks"]:
                history_data["tasks"][task_id] = []
            
            history_data["tasks"][task_id].append(history_entry)
            
            # Sauvegarder l'historique
            with open(history_path, 'w', encoding='utf-8') as f:
                json.dump(history_data, f, indent=2, ensure_ascii=False)
            
            # Préparer le résultat
            result = {
                "taskId": task_id,
                "description": current_metadata.get("description", ""),
                "oldStatus": current_status,
                "newStatus": new_status,
                "lastUpdated": new_metadata['lastUpdated'],
                "assignee": new_metadata.get('assignee', ""),
                "historyEntryAdded": True
            }
            
            # Afficher le résultat au format JSON
            print(json.dumps(result, indent=2, ensure_ascii=False))
            
        except Exception as e:
            print(f"Erreur lors de la mise à jour du statut: {e}")
            sys.exit(1)
        
    except Exception as e:
        print(f"Erreur lors de l'accès à la collection: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction pour mettre à jour le fichier Markdown de la roadmap
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
                    "Blocked" { "!" }     # Utiliser '!' pour bloqué
                    "Deferred" { ">" }    # Utiliser '>' pour reporté
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
            Write-Log "Statut de la tâche $TaskId mis à jour dans le fichier roadmap." -Level Success
            return $true
        }
        else {
            Write-Log "Tâche $TaskId non trouvée dans le fichier roadmap." -Level Warning
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la mise à jour du fichier roadmap: $_" -Level Error
        return $false
    }
}

# Fonction principale
function Main {
    # Vérifier si la base Chroma existe
    if (-not (Test-Path -Path $ChromaDbPath)) {
        Write-Log "La base Chroma $ChromaDbPath n'existe pas." -Level Error
        return
    }
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        Write-Log "Python est requis pour ce script. Veuillez installer Python et réessayer." -Level Error
        return
    }
    
    # Vérifier si les packages Python nécessaires sont installés
    if (-not (Test-PythonPackages)) {
        Write-Log "Les packages Python requis ne sont pas tous installés. Le script ne peut pas continuer." -Level Error
        return
    }
    
    # Créer le dossier d'historique s'il n'existe pas
    $historyFolder = Split-Path -Path $HistoryPath -Parent
    if (-not (Test-Path -Path $historyFolder)) {
        New-Item -Path $historyFolder -ItemType Directory -Force | Out-Null
        Write-Log "Dossier d'historique créé: $historyFolder" -Level Info
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour la mise à jour du statut..." -Level Info
    $pythonScript = New-StatusUpdateScript -TaskId $TaskId -Status $Status -Comment $Comment -Assignee $Assignee -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -HistoryPath $HistoryPath
    
    # Exécuter le script Python et capturer la sortie JSON
    Write-Log "Mise à jour du statut de la tâche $TaskId vers '$Status'..." -Level Info
    $output = python $pythonScript 2>&1
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    # Extraire les résultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("{")
    $jsonEndIndex = $output.LastIndexOf("}")
    
    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $result = $jsonString | ConvertFrom-Json
        
        # Mettre à jour le fichier Markdown si demandé
        if ($UpdateRoadmap) {
            $markdownUpdated = Update-RoadmapMarkdown -RoadmapPath $RoadmapPath -TaskId $TaskId -Status $Status
            
            if ($markdownUpdated) {
                Write-Log "Fichier Markdown de la roadmap mis à jour avec succès." -Level Success
            }
            else {
                Write-Log "Échec de la mise à jour du fichier Markdown de la roadmap." -Level Warning
            }
        }
        
        # Afficher le résultat
        Write-Host "`nMise à jour du statut effectuée avec succès:" -ForegroundColor Green
        Write-Host "ID de la tâche: $($result.taskId)" -ForegroundColor Cyan
        Write-Host "Description: $($result.description)" -ForegroundColor Cyan
        Write-Host "Ancien statut: $($result.oldStatus)" -ForegroundColor Yellow
        Write-Host "Nouveau statut: $($result.newStatus)" -ForegroundColor Green
        Write-Host "Dernière mise à jour: $($result.lastUpdated)" -ForegroundColor Cyan
        
        if ($result.assignee) {
            Write-Host "Assigné à: $($result.assignee)" -ForegroundColor Cyan
        }
        
        Write-Log "Mise à jour du statut terminée avec succès." -Level Success
    }
    else {
        Write-Log "Erreur lors de la mise à jour du statut." -Level Error
    }
}

# Exécuter la fonction principale
Main

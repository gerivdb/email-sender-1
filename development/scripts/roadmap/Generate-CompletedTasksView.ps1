# Generate-CompletedTasksView.ps1
# Script pour générer une vue des tâches récemment terminées

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$HistoryPath = "projet\roadmaps\history\task_history.json",
    
    [Parameter(Mandatory = $false)]
    [int]$DaysBack = 7,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxTasks = 20,
    
    [Parameter(Mandatory = $false)]
    [string]$SectionFilter,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("markdown", "html", "json")]
    [string]$OutputFormat = "markdown",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeMetadata,
    
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

# Fonction pour créer un script Python temporaire pour générer la vue des tâches récemment terminées
function New-CompletedTasksViewScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$HistoryPath,
        
        [Parameter(Mandatory = $true)]
        [int]$DaysBack,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxTasks,
        
        [Parameter(Mandatory = $false)]
        [string]$SectionFilter,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeMetadata
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import json
import chromadb
import os
import sys
from datetime import datetime, timedelta
from collections import defaultdict

def main():
    # Paramètres
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    history_path = r'$HistoryPath'
    days_back = $DaysBack
    max_tasks = $MaxTasks
    section_filter = r'$SectionFilter'
    include_metadata = $($IncludeMetadata.ToString().ToLower())
    
    # Vérifier si le fichier d'historique existe
    if not os.path.exists(history_path):
        print(f"Le fichier d'historique {history_path} n'existe pas.")
        sys.exit(1)
    
    # Charger l'historique
    try:
        with open(history_path, 'r', encoding='utf-8') as f:
            history_data = json.load(f)
    except Exception as e:
        print(f"Erreur lors du chargement du fichier d'historique: {e}")
        sys.exit(1)
    
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
        
        # Calculer la date limite
        cutoff_date = datetime.now() - timedelta(days=days_back)
        
        # Trouver les tâches récemment terminées
        recently_completed_tasks = []
        
        for task_id, entries in history_data.get("tasks", {}).items():
            # Trier les entrées par date (la plus récente en premier)
            sorted_entries = sorted(entries, key=lambda x: x.get("timestamp", ""), reverse=True)
            
            for entry in sorted_entries:
                # Vérifier si c'est une transition vers "Complete"
                if entry.get("newStatus") == "Complete" and entry.get("oldStatus") != "Complete":
                    # Vérifier si c'est dans la période spécifiée
                    try:
                        entry_date = datetime.fromisoformat(entry.get("timestamp"))
                        if entry_date >= cutoff_date:
                            # Ajouter la tâche à la liste
                            recently_completed_tasks.append({
                                "taskId": task_id,
                                "completedAt": entry.get("timestamp"),
                                "completedBy": entry.get("user", "unknown"),
                                "comment": entry.get("comment", ""),
                                "assignee": entry.get("assignee", "")
                            })
                            break  # Passer à la tâche suivante
                    except (ValueError, TypeError):
                        # Ignorer les dates invalides
                        continue
        
        # Trier par date de complétion (la plus récente en premier)
        recently_completed_tasks.sort(key=lambda x: x.get("completedAt", ""), reverse=True)
        
        # Limiter le nombre de tâches
        recently_completed_tasks = recently_completed_tasks[:max_tasks]
        
        # Récupérer les détails des tâches depuis Chroma
        task_ids = [task["taskId"] for task in recently_completed_tasks]
        
        if not task_ids:
            print("Aucune tâche récemment terminée trouvée.")
            sys.exit(0)
        
        # Récupérer les détails des tâches
        task_details = collection.get(ids=task_ids)
        
        # Créer un dictionnaire pour un accès facile aux détails
        task_details_dict = {}
        for i, task_id in enumerate(task_details['ids']):
            task_details_dict[task_id] = {
                "metadata": task_details['metadatas'][i],
                "document": task_details['documents'][i]
            }
        
        # Enrichir les tâches avec les détails
        enriched_tasks = []
        for task in recently_completed_tasks:
            task_id = task["taskId"]
            if task_id in task_details_dict:
                details = task_details_dict[task_id]
                metadata = details["metadata"]
                
                # Filtrer par section si nécessaire
                if section_filter and section_filter.lower() not in metadata.get("section", "").lower():
                    continue
                
                enriched_task = {
                    "taskId": task_id,
                    "description": metadata.get("description", ""),
                    "section": metadata.get("section", ""),
                    "completedAt": task["completedAt"],
                    "completedBy": task["completedBy"],
                    "comment": task["comment"],
                    "assignee": task["assignee"] or metadata.get("assignee", "")
                }
                
                # Ajouter d'autres métadonnées si demandé
                if include_metadata:
                    for key, value in metadata.items():
                        if key not in enriched_task:
                            enriched_task[key] = value
                
                enriched_tasks.append(enriched_task)
        
        # Générer la vue Markdown
        markdown_lines = []
        markdown_lines.append("# Tâches Récemment Terminées")
        markdown_lines.append("")
        markdown_lines.append(f"Générée le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        markdown_lines.append(f"Période: derniers {days_back} jours")
        markdown_lines.append("")
        
        if section_filter:
            markdown_lines.append(f"Filtré par section: {section_filter}")
            markdown_lines.append("")
        
        if not enriched_tasks:
            markdown_lines.append("Aucune tâche récemment terminée trouvée.")
        else:
            markdown_lines.append(f"## {len(enriched_tasks)} tâches terminées")
            markdown_lines.append("")
            
            # Grouper par date
            tasks_by_date = defaultdict(list)
            for task in enriched_tasks:
                try:
                    date_str = datetime.fromisoformat(task["completedAt"]).strftime("%Y-%m-%d")
                    tasks_by_date[date_str].append(task)
                except (ValueError, TypeError):
                    tasks_by_date["Date inconnue"].append(task)
            
            # Afficher par date
            for date_str, tasks in sorted(tasks_by_date.items(), reverse=True):
                markdown_lines.append(f"### {date_str}")
                markdown_lines.append("")
                
                for task in tasks:
                    markdown_lines.append(f"- [x] **{task['taskId']}** {task['description']}")
                    
                    # Ajouter les métadonnées
                    metadata_parts = []
                    if task["section"]:
                        metadata_parts.append(f"Section: {task['section']}")
                    
                    time_str = ""
                    try:
                        time_str = datetime.fromisoformat(task["completedAt"]).strftime("%H:%M")
                        metadata_parts.append(f"Terminée à: {time_str}")
                    except (ValueError, TypeError):
                        pass
                    
                    if task["completedBy"]:
                        metadata_parts.append(f"Par: {task['completedBy']}")
                    
                    if task["assignee"]:
                        metadata_parts.append(f"Assignée à: {task['assignee']}")
                    
                    if task["comment"]:
                        metadata_parts.append(f"Commentaire: {task['comment']}")
                    
                    if metadata_parts:
                        markdown_lines.append(f"  _{', '.join(metadata_parts)}_")
                    
                    # Ajouter d'autres métadonnées si demandé
                    if include_metadata:
                        other_metadata = [f"{key}: {value}" for key, value in task.items() 
                                        if key not in ["taskId", "description", "section", "completedAt", 
                                                    "completedBy", "comment", "assignee"]]
                        if other_metadata:
                            markdown_lines.append(f"  _{', '.join(other_metadata)}_")
                
                markdown_lines.append("")
        
        # Joindre les lignes
        markdown_content = "\n".join(markdown_lines)
        
        # Créer un objet résultat
        result = {
            "markdown": markdown_content,
            "tasks": enriched_tasks,
            "metadata": {
                "generatedAt": datetime.now().isoformat(),
                "daysBack": days_back,
                "maxTasks": max_tasks,
                "sectionFilter": section_filter,
                "taskCount": len(enriched_tasks)
            }
        }
        
        # Afficher le résultat au format JSON
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors de la génération de la vue des tâches récemment terminées: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction pour convertir le Markdown en HTML
function Convert-MarkdownToHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Markdown
    )
    
    # Style CSS simple
    $css = @"
<style>
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    max-width: 900px;
    margin: 0 auto;
    padding: 20px;
}
h1, h2, h3, h4 {
    color: #333;
    margin-top: 20px;
}
h1 {
    border-bottom: 2px solid #333;
    padding-bottom: 10px;
}
h2 {
    border-bottom: 1px solid #ccc;
    padding-bottom: 5px;
}
h3 {
    color: #2980b9;
}
ul {
    padding-left: 20px;
}
li {
    margin-bottom: 5px;
}
code {
    background-color: #f5f5f5;
    padding: 2px 4px;
    border-radius: 3px;
}
.task-complete {
    color: #2ecc71;
}
.metadata {
    font-style: italic;
    color: #7f8c8d;
    font-size: 0.9em;
    margin-top: 2px;
    margin-bottom: 10px;
}
</style>
"@
    
    # Convertir les titres
    $html = $Markdown -replace '^# (.*?)$', '<h1>$1</h1>'
    $html = $html -replace '^## (.*?)$', '<h2>$1</h2>'
    $html = $html -replace '^### (.*?)$', '<h3>$1</h3>'
    $html = $html -replace '^#### (.*?)$', '<h4>$1</h4>'
    
    # Convertir les listes et les tâches
    $html = $html -replace '^\s*- \[x\] \*\*(.*?)\*\* (.*?)$', '<li class="task-complete"><input type="checkbox" checked disabled> <strong>$1</strong> $2</li>'
    
    # Convertir les métadonnées en italique
    $html = $html -replace '^\s*_(.*?)_$', '<div class="metadata">$1</div>'
    
    # Convertir les sauts de ligne
    $html = $html -replace "`r?`n`r?`n", "</p><p>"
    $html = $html -replace "`r?`n", "<br>"
    
    # Envelopper dans des balises HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tâches Récemment Terminées</title>
    $css
</head>
<body>
    <p>$html</p>
</body>
</html>
"@
    
    return $html
}

# Fonction principale
function Main {
    # Vérifier si la base Chroma existe
    if (-not (Test-Path -Path $ChromaDbPath)) {
        Write-Log "La base Chroma $ChromaDbPath n'existe pas." -Level Error
        return
    }
    
    # Vérifier si le fichier d'historique existe
    if (-not (Test-Path -Path $HistoryPath)) {
        Write-Log "Le fichier d'historique $HistoryPath n'existe pas." -Level Error
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
    
    # Vérifier si le fichier de sortie existe déjà
    if ($OutputPath -and (Test-Path -Path $OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie $OutputPath existe déjà. Utilisez -Force pour l'écraser." -Level Warning
        return
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour générer la vue des tâches récemment terminées..." -Level Info
    $pythonScript = New-CompletedTasksViewScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -HistoryPath $HistoryPath -DaysBack $DaysBack -MaxTasks $MaxTasks -SectionFilter $SectionFilter -IncludeMetadata $IncludeMetadata
    
    # Exécuter le script Python et capturer la sortie JSON
    Write-Log "Génération de la vue des tâches récemment terminées..." -Level Info
    $output = python $pythonScript 2>&1
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    # Extraire les résultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("{")
    $jsonEndIndex = $output.LastIndexOf("}")
    
    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $result = $jsonString | ConvertFrom-Json
        
        # Traiter les résultats selon le format demandé
        switch ($OutputFormat) {
            "markdown" {
                $content = $result.markdown
                
                if ($OutputPath) {
                    $content | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des tâches récemment terminées sauvegardée au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $content
                }
            }
            "html" {
                $html = Convert-MarkdownToHtml -Markdown $result.markdown
                
                if ($OutputPath) {
                    $html | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des tâches récemment terminées sauvegardée au format HTML dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $html
                }
            }
            "json" {
                if ($OutputPath) {
                    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des tâches récemment terminées sauvegardée au format JSON dans $OutputPath" -Level Success
                }
                else {
                    $result | ConvertTo-Json -Depth 10
                }
            }
        }
        
        Write-Log "Génération de la vue terminée. $($result.metadata.taskCount) tâches incluses." -Level Success
    }
    else {
        Write-Log "Erreur lors de la génération de la vue des tâches récemment terminées." -Level Error
    }
}

# Exécuter la fonction principale
Main

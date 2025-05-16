# Generate-CompletedTasksView.ps1
# Script pour gÃ©nÃ©rer une vue des tÃ¢ches rÃ©cemment terminÃ©es

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

# Fonction pour crÃ©er un script Python temporaire pour gÃ©nÃ©rer la vue des tÃ¢ches rÃ©cemment terminÃ©es
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
    # ParamÃ¨tres
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    history_path = r'$HistoryPath'
    days_back = $DaysBack
    max_tasks = $MaxTasks
    section_filter = r'$SectionFilter'
    include_metadata = $($IncludeMetadata.ToString().ToLower())
    
    # VÃ©rifier si le fichier d'historique existe
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
        
        # Calculer la date limite
        cutoff_date = datetime.now() - timedelta(days=days_back)
        
        # Trouver les tÃ¢ches rÃ©cemment terminÃ©es
        recently_completed_tasks = []
        
        for task_id, entries in history_data.get("tasks", {}).items():
            # Trier les entrÃ©es par date (la plus rÃ©cente en premier)
            sorted_entries = sorted(entries, key=lambda x: x.get("timestamp", ""), reverse=True)
            
            for entry in sorted_entries:
                # VÃ©rifier si c'est une transition vers "Complete"
                if entry.get("newStatus") == "Complete" and entry.get("oldStatus") != "Complete":
                    # VÃ©rifier si c'est dans la pÃ©riode spÃ©cifiÃ©e
                    try:
                        entry_date = datetime.fromisoformat(entry.get("timestamp"))
                        if entry_date >= cutoff_date:
                            # Ajouter la tÃ¢che Ã  la liste
                            recently_completed_tasks.append({
                                "taskId": task_id,
                                "completedAt": entry.get("timestamp"),
                                "completedBy": entry.get("user", "unknown"),
                                "comment": entry.get("comment", ""),
                                "assignee": entry.get("assignee", "")
                            })
                            break  # Passer Ã  la tÃ¢che suivante
                    except (ValueError, TypeError):
                        # Ignorer les dates invalides
                        continue
        
        # Trier par date de complÃ©tion (la plus rÃ©cente en premier)
        recently_completed_tasks.sort(key=lambda x: x.get("completedAt", ""), reverse=True)
        
        # Limiter le nombre de tÃ¢ches
        recently_completed_tasks = recently_completed_tasks[:max_tasks]
        
        # RÃ©cupÃ©rer les dÃ©tails des tÃ¢ches depuis Chroma
        task_ids = [task["taskId"] for task in recently_completed_tasks]
        
        if not task_ids:
            print("Aucune tÃ¢che rÃ©cemment terminÃ©e trouvÃ©e.")
            sys.exit(0)
        
        # RÃ©cupÃ©rer les dÃ©tails des tÃ¢ches
        task_details = collection.get(ids=task_ids)
        
        # CrÃ©er un dictionnaire pour un accÃ¨s facile aux dÃ©tails
        task_details_dict = {}
        for i, task_id in enumerate(task_details['ids']):
            task_details_dict[task_id] = {
                "metadata": task_details['metadatas'][i],
                "document": task_details['documents'][i]
            }
        
        # Enrichir les tÃ¢ches avec les dÃ©tails
        enriched_tasks = []
        for task in recently_completed_tasks:
            task_id = task["taskId"]
            if task_id in task_details_dict:
                details = task_details_dict[task_id]
                metadata = details["metadata"]
                
                # Filtrer par section si nÃ©cessaire
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
                
                # Ajouter d'autres mÃ©tadonnÃ©es si demandÃ©
                if include_metadata:
                    for key, value in metadata.items():
                        if key not in enriched_task:
                            enriched_task[key] = value
                
                enriched_tasks.append(enriched_task)
        
        # GÃ©nÃ©rer la vue Markdown
        markdown_lines = []
        markdown_lines.append("# TÃ¢ches RÃ©cemment TerminÃ©es")
        markdown_lines.append("")
        markdown_lines.append(f"GÃ©nÃ©rÃ©e le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        markdown_lines.append(f"PÃ©riode: derniers {days_back} jours")
        markdown_lines.append("")
        
        if section_filter:
            markdown_lines.append(f"FiltrÃ© par section: {section_filter}")
            markdown_lines.append("")
        
        if not enriched_tasks:
            markdown_lines.append("Aucune tÃ¢che rÃ©cemment terminÃ©e trouvÃ©e.")
        else:
            markdown_lines.append(f"## {len(enriched_tasks)} tÃ¢ches terminÃ©es")
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
                    
                    # Ajouter les mÃ©tadonnÃ©es
                    metadata_parts = []
                    if task["section"]:
                        metadata_parts.append(f"Section: {task['section']}")
                    
                    time_str = ""
                    try:
                        time_str = datetime.fromisoformat(task["completedAt"]).strftime("%H:%M")
                        metadata_parts.append(f"TerminÃ©e Ã : {time_str}")
                    except (ValueError, TypeError):
                        pass
                    
                    if task["completedBy"]:
                        metadata_parts.append(f"Par: {task['completedBy']}")
                    
                    if task["assignee"]:
                        metadata_parts.append(f"AssignÃ©e Ã : {task['assignee']}")
                    
                    if task["comment"]:
                        metadata_parts.append(f"Commentaire: {task['comment']}")
                    
                    if metadata_parts:
                        markdown_lines.append(f"  _{', '.join(metadata_parts)}_")
                    
                    # Ajouter d'autres mÃ©tadonnÃ©es si demandÃ©
                    if include_metadata:
                        other_metadata = [f"{key}: {value}" for key, value in task.items() 
                                        if key not in ["taskId", "description", "section", "completedAt", 
                                                    "completedBy", "comment", "assignee"]]
                        if other_metadata:
                            markdown_lines.append(f"  _{', '.join(other_metadata)}_")
                
                markdown_lines.append("")
        
        # Joindre les lignes
        markdown_content = "\n".join(markdown_lines)
        
        # CrÃ©er un objet rÃ©sultat
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
        
        # Afficher le rÃ©sultat au format JSON
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors de la gÃ©nÃ©ration de la vue des tÃ¢ches rÃ©cemment terminÃ©es: {e}")
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
    
    # Convertir les listes et les tÃ¢ches
    $html = $html -replace '^\s*- \[x\] \*\*(.*?)\*\* (.*?)$', '<li class="task-complete"><input type="checkbox" checked disabled> <strong>$1</strong> $2</li>'
    
    # Convertir les mÃ©tadonnÃ©es en italique
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
    <title>TÃ¢ches RÃ©cemment TerminÃ©es</title>
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
    # VÃ©rifier si la base Chroma existe
    if (-not (Test-Path -Path $ChromaDbPath)) {
        Write-Log "La base Chroma $ChromaDbPath n'existe pas." -Level Error
        return
    }
    
    # VÃ©rifier si le fichier d'historique existe
    if (-not (Test-Path -Path $HistoryPath)) {
        Write-Log "Le fichier d'historique $HistoryPath n'existe pas." -Level Error
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
    
    # VÃ©rifier si le fichier de sortie existe dÃ©jÃ 
    if ($OutputPath -and (Test-Path -Path $OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie $OutputPath existe dÃ©jÃ . Utilisez -Force pour l'Ã©craser." -Level Warning
        return
    }
    
    # CrÃ©er le script Python temporaire
    Write-Log "CrÃ©ation du script Python pour gÃ©nÃ©rer la vue des tÃ¢ches rÃ©cemment terminÃ©es..." -Level Info
    $pythonScript = New-CompletedTasksViewScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -HistoryPath $HistoryPath -DaysBack $DaysBack -MaxTasks $MaxTasks -SectionFilter $SectionFilter -IncludeMetadata $IncludeMetadata
    
    # ExÃ©cuter le script Python et capturer la sortie JSON
    Write-Log "GÃ©nÃ©ration de la vue des tÃ¢ches rÃ©cemment terminÃ©es..." -Level Info
    $output = python $pythonScript 2>&1
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    # Extraire les rÃ©sultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("{")
    $jsonEndIndex = $output.LastIndexOf("}")
    
    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $result = $jsonString | ConvertFrom-Json
        
        # Traiter les rÃ©sultats selon le format demandÃ©
        switch ($OutputFormat) {
            "markdown" {
                $content = $result.markdown
                
                if ($OutputPath) {
                    $content | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des tÃ¢ches rÃ©cemment terminÃ©es sauvegardÃ©e au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $content
                }
            }
            "html" {
                $html = Convert-MarkdownToHtml -Markdown $result.markdown
                
                if ($OutputPath) {
                    $html | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des tÃ¢ches rÃ©cemment terminÃ©es sauvegardÃ©e au format HTML dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $html
                }
            }
            "json" {
                if ($OutputPath) {
                    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des tÃ¢ches rÃ©cemment terminÃ©es sauvegardÃ©e au format JSON dans $OutputPath" -Level Success
                }
                else {
                    $result | ConvertTo-Json -Depth 10
                }
            }
        }
        
        Write-Log "GÃ©nÃ©ration de la vue terminÃ©e. $($result.metadata.taskCount) tÃ¢ches incluses." -Level Success
    }
    else {
        Write-Log "Erreur lors de la gÃ©nÃ©ration de la vue des tÃ¢ches rÃ©cemment terminÃ©es." -Level Error
    }
}

# ExÃ©cuter la fonction principale
Main

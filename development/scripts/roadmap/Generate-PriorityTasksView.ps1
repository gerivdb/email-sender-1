# Generate-PriorityTasksView.ps1
# Script pour gÃ©nÃ©rer une vue des prochaines Ã©tapes prioritaires

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxTasks = 10,
    
    [Parameter(Mandatory = $false)]
    [string]$SectionFilter,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Manual", "Dependencies", "Chronological")]
    [string]$PriorityMethod = "Auto",
    
    [Parameter(Mandatory = $false)]
    [string]$PriorityConfigPath = "projet\roadmaps\config\priority_config.json",
    
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

# Fonction pour crÃ©er un script Python temporaire pour gÃ©nÃ©rer la vue des prochaines Ã©tapes prioritaires
function New-PriorityTasksViewScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxTasks,
        
        [Parameter(Mandatory = $false)]
        [string]$SectionFilter,
        
        [Parameter(Mandatory = $true)]
        [string]$PriorityMethod,
        
        [Parameter(Mandatory = $true)]
        [string]$PriorityConfigPath,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeMetadata
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import json
import chromadb
import os
import sys
from datetime import datetime
from collections import defaultdict

def get_task_level(task_id):
    """DÃ©terminer le niveau hiÃ©rarchique d'une tÃ¢che Ã  partir de son ID"""
    return len(task_id.split('.'))

def get_parent_id(task_id):
    """Obtenir l'ID parent d'une tÃ¢che"""
    parts = task_id.split('.')
    if len(parts) <= 1:
        return ""
    return '.'.join(parts[:-1])

def calculate_priority_auto(tasks):
    """Calculer la prioritÃ© automatiquement en fonction de plusieurs facteurs"""
    # CrÃ©er un dictionnaire des tÃ¢ches pour un accÃ¨s facile
    task_dict = {task["id"]: task for task in tasks}
    
    # Calculer les scores de prioritÃ©
    for task in tasks:
        # Initialiser le score
        score = 0
        
        # Facteur 1: Niveau hiÃ©rarchique (les tÃ¢ches de plus haut niveau sont plus prioritaires)
        level = get_task_level(task["id"])
        score += (5 - min(level, 5)) * 10  # Max 40 points
        
        # Facteur 2: DÃ©pendances (les tÃ¢ches sans dÃ©pendances sont plus prioritaires)
        parent_id = get_parent_id(task["id"])
        if parent_id and parent_id in task_dict:
            parent_status = task_dict[parent_id].get("status", "")
            if parent_status == "Complete":
                score += 30  # Parent terminÃ© = bonne prioritÃ©
            elif parent_status == "InProgress":
                score += 20  # Parent en cours = prioritÃ© moyenne
            else:
                score += 0   # Parent non commencÃ© = faible prioritÃ©
        else:
            score += 30  # Pas de parent = bonne prioritÃ©
        
        # Facteur 3: Statut (les tÃ¢ches en cours sont plus prioritaires)
        if task.get("status") == "InProgress":
            score += 20
        
        # Facteur 4: Assignation (les tÃ¢ches assignÃ©es sont plus prioritaires)
        if task.get("assignee"):
            score += 10
        
        # Stocker le score
        task["priority_score"] = score
    
    # Trier par score de prioritÃ© (dÃ©croissant)
    return sorted(tasks, key=lambda x: x.get("priority_score", 0), reverse=True)

def calculate_priority_dependencies(tasks):
    """Calculer la prioritÃ© en fonction des dÃ©pendances"""
    # CrÃ©er un dictionnaire des tÃ¢ches pour un accÃ¨s facile
    task_dict = {task["id"]: task for task in tasks}
    
    # Calculer les scores de prioritÃ©
    for task in tasks:
        # Initialiser le score
        score = 0
        
        # Facteur principal: DÃ©pendances
        parent_id = get_parent_id(task["id"])
        if parent_id and parent_id in task_dict:
            parent_status = task_dict[parent_id].get("status", "")
            if parent_status == "Complete":
                score += 100  # Parent terminÃ© = haute prioritÃ©
            elif parent_status == "InProgress":
                score += 50   # Parent en cours = prioritÃ© moyenne
            else:
                score += 0    # Parent non commencÃ© = faible prioritÃ©
        else:
            score += 80  # Pas de parent = bonne prioritÃ©
        
        # Facteur secondaire: Niveau hiÃ©rarchique
        level = get_task_level(task["id"])
        score += (5 - min(level, 5)) * 5  # Max 20 points
        
        # Stocker le score
        task["priority_score"] = score
    
    # Trier par score de prioritÃ© (dÃ©croissant)
    return sorted(tasks, key=lambda x: x.get("priority_score", 0), reverse=True)

def calculate_priority_chronological(tasks):
    """Calculer la prioritÃ© en fonction de l'ordre chronologique des IDs"""
    # Trier par ID (ordre numÃ©rique)
    return sorted(tasks, key=lambda x: [int(p) if p.isdigit() else p for p in x["id"].split('.')])

def calculate_priority_manual(tasks, config_path):
    """Calculer la prioritÃ© en fonction de la configuration manuelle"""
    # Charger la configuration de prioritÃ©
    priority_config = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                priority_config = json.load(f)
        except Exception as e:
            print(f"Erreur lors du chargement de la configuration de prioritÃ©: {e}")
    
    # Obtenir les prioritÃ©s manuelles
    manual_priorities = priority_config.get("taskPriorities", {})
    
    # Assigner les scores de prioritÃ©
    for task in tasks:
        task_id = task["id"]
        if task_id in manual_priorities:
            task["priority_score"] = manual_priorities[task_id]
        else:
            # PrioritÃ© par dÃ©faut pour les tÃ¢ches non configurÃ©es
            task["priority_score"] = 0
    
    # Trier par score de prioritÃ© (dÃ©croissant)
    return sorted(tasks, key=lambda x: x.get("priority_score", 0), reverse=True)

def main():
    # ParamÃ¨tres
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    max_tasks = $MaxTasks
    section_filter = r'$SectionFilter'
    priority_method = '$PriorityMethod'
    priority_config_path = r'$PriorityConfigPath'
    include_metadata = $($IncludeMetadata.ToString().ToLower())
    
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
        
        # RÃ©cupÃ©rer les tÃ¢ches incomplÃ¨tes
        result = collection.get(
            where={"status": {"$ne": "Complete"}}
        )
        
        if not result['ids']:
            print("Aucune tÃ¢che incomplÃ¨te trouvÃ©e.")
            sys.exit(0)
        
        # Filtrer par section si nÃ©cessaire
        filtered_indices = []
        if section_filter:
            for i, metadata in enumerate(result['metadatas']):
                section = metadata.get('section', '')
                if section_filter.lower() in section.lower():
                    filtered_indices.append(i)
        else:
            filtered_indices = list(range(len(result['ids'])))
        
        # CrÃ©er une liste de tÃ¢ches
        tasks = []
        for i in filtered_indices:
            task_id = result['ids'][i]
            metadata = result['metadatas'][i]
            
            task = {
                "id": task_id,
                "description": metadata.get("description", ""),
                "status": metadata.get("status", "Incomplete"),
                "section": metadata.get("section", ""),
                "indentLevel": metadata.get("indentLevel", 0),
                "lastUpdated": metadata.get("lastUpdated", ""),
                "parentId": metadata.get("parentId", ""),
                "level": get_task_level(task_id)
            }
            
            # Ajouter l'assignÃ© s'il existe
            if "assignee" in metadata:
                task["assignee"] = metadata["assignee"]
            
            # Ajouter d'autres mÃ©tadonnÃ©es si demandÃ©
            if include_metadata:
                for key, value in metadata.items():
                    if key not in task:
                        task[key] = value
            
            tasks.append(task)
        
        # Calculer les prioritÃ©s selon la mÃ©thode choisie
        if priority_method == "Manual":
            prioritized_tasks = calculate_priority_manual(tasks, priority_config_path)
        elif priority_method == "Dependencies":
            prioritized_tasks = calculate_priority_dependencies(tasks)
        elif priority_method == "Chronological":
            prioritized_tasks = calculate_priority_chronological(tasks)
        else:  # Auto ou autre
            prioritized_tasks = calculate_priority_auto(tasks)
        
        # Limiter le nombre de tÃ¢ches
        prioritized_tasks = prioritized_tasks[:max_tasks]
        
        # GÃ©nÃ©rer la vue Markdown
        markdown_lines = []
        markdown_lines.append("# Prochaines Ã‰tapes Prioritaires")
        markdown_lines.append("")
        markdown_lines.append(f"GÃ©nÃ©rÃ©e le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        markdown_lines.append(f"MÃ©thode de prioritÃ©: {priority_method}")
        markdown_lines.append("")
        
        if section_filter:
            markdown_lines.append(f"FiltrÃ© par section: {section_filter}")
            markdown_lines.append("")
        
        if not prioritized_tasks:
            markdown_lines.append("Aucune tÃ¢che prioritaire trouvÃ©e.")
        else:
            markdown_lines.append(f"## Top {len(prioritized_tasks)} tÃ¢ches prioritaires")
            markdown_lines.append("")
            
            for i, task in enumerate(prioritized_tasks):
                # DÃ©terminer le symbole de statut
                status_symbol = " "
                if task["status"] == "InProgress":
                    status_symbol = "o"
                elif task["status"] == "Blocked":
                    status_symbol = "!"
                elif task["status"] == "Deferred":
                    status_symbol = ">"
                
                # Ajouter la tÃ¢che
                markdown_lines.append(f"{i+1}. [{status_symbol}] **{task['id']}** {task['description']}")
                
                # Ajouter les mÃ©tadonnÃ©es
                metadata_parts = []
                if task["section"]:
                    metadata_parts.append(f"Section: {task['section']}")
                
                if task.get("assignee"):
                    metadata_parts.append(f"AssignÃ©e Ã : {task['assignee']}")
                
                if task.get("lastUpdated"):
                    metadata_parts.append(f"Mise Ã  jour: {task['lastUpdated']}")
                
                if "priority_score" in task:
                    metadata_parts.append(f"Score de prioritÃ©: {task['priority_score']}")
                
                if metadata_parts:
                    markdown_lines.append(f"   _{', '.join(metadata_parts)}_")
                
                # Ajouter d'autres mÃ©tadonnÃ©es si demandÃ©
                if include_metadata:
                    other_metadata = [f"{key}: {value}" for key, value in task.items() 
                                    if key not in ["id", "description", "section", "status", 
                                                "assignee", "lastUpdated", "priority_score", 
                                                "parentId", "indentLevel", "level"]]
                    if other_metadata:
                        markdown_lines.append(f"   _{', '.join(other_metadata)}_")
                
                markdown_lines.append("")
        
        # Joindre les lignes
        markdown_content = "\n".join(markdown_lines)
        
        # CrÃ©er un objet rÃ©sultat
        result = {
            "markdown": markdown_content,
            "tasks": prioritized_tasks,
            "metadata": {
                "generatedAt": datetime.now().isoformat(),
                "priorityMethod": priority_method,
                "maxTasks": max_tasks,
                "sectionFilter": section_filter,
                "taskCount": len(prioritized_tasks)
            }
        }
        
        # Afficher le rÃ©sultat au format JSON
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors de la gÃ©nÃ©ration de la vue des prochaines Ã©tapes prioritaires: {e}")
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
ol {
    padding-left: 20px;
}
li {
    margin-bottom: 15px;
}
code {
    background-color: #f5f5f5;
    padding: 2px 4px;
    border-radius: 3px;
}
.task-incomplete {
    color: #333;
}
.task-inprogress {
    color: #3498db;
}
.task-blocked {
    color: #e74c3c;
}
.task-deferred {
    color: #95a5a6;
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
    
    # Convertir les listes numÃ©rotÃ©es et les tÃ¢ches
    $html = $html -replace '^(\d+)\. \[ \] \*\*(.*?)\*\* (.*?)$', '<li class="task-incomplete"><span class="number">$1.</span> <input type="checkbox" disabled> <strong>$2</strong> $3</li>'
    $html = $html -replace '^(\d+)\. \[o\] \*\*(.*?)\*\* (.*?)$', '<li class="task-inprogress"><span class="number">$1.</span> <input type="checkbox" disabled> <strong>$2</strong> $3 (En cours)</li>'
    $html = $html -replace '^(\d+)\. \[!\] \*\*(.*?)\*\* (.*?)$', '<li class="task-blocked"><span class="number">$1.</span> <input type="checkbox" disabled> <strong>$2</strong> $3 (BloquÃ©)</li>'
    $html = $html -replace '^(\d+)\. \[>\] \*\*(.*?)\*\* (.*?)$', '<li class="task-deferred"><span class="number">$1.</span> <input type="checkbox" disabled> <strong>$2</strong> $3 (ReportÃ©)</li>'
    
    # Convertir les mÃ©tadonnÃ©es en italique
    $html = $html -replace '^\s*_(.*?)_$', '<div class="metadata">$1</div>'
    
    # Envelopper les listes numÃ©rotÃ©es
    $html = $html -replace '(<li class="task-.*?">.*?</li>)', '<ol>$1</ol>'
    $html = $html -replace '<ol>(.*?)</ol>', {
        param($match)
        $content = $match.Groups[1].Value
        $items = $content -split '(?=<li class="task-)'
        $items = $items | Where-Object { $_ -match '<li' }
        "<ol>`n" + ($items -join "`n") + "`n</ol>"
    }
    
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
    <title>Prochaines Ã‰tapes Prioritaires</title>
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
    Write-Log "CrÃ©ation du script Python pour gÃ©nÃ©rer la vue des prochaines Ã©tapes prioritaires..." -Level Info
    $pythonScript = New-PriorityTasksViewScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -MaxTasks $MaxTasks -SectionFilter $SectionFilter -PriorityMethod $PriorityMethod -PriorityConfigPath $PriorityConfigPath -IncludeMetadata $IncludeMetadata
    
    # ExÃ©cuter le script Python et capturer la sortie JSON
    Write-Log "GÃ©nÃ©ration de la vue des prochaines Ã©tapes prioritaires..." -Level Info
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
                    Write-Log "Vue des prochaines Ã©tapes prioritaires sauvegardÃ©e au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $content
                }
            }
            "html" {
                $html = Convert-MarkdownToHtml -Markdown $result.markdown
                
                if ($OutputPath) {
                    $html | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des prochaines Ã©tapes prioritaires sauvegardÃ©e au format HTML dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $html
                }
            }
            "json" {
                if ($OutputPath) {
                    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue des prochaines Ã©tapes prioritaires sauvegardÃ©e au format JSON dans $OutputPath" -Level Success
                }
                else {
                    $result | ConvertTo-Json -Depth 10
                }
            }
        }
        
        Write-Log "GÃ©nÃ©ration de la vue terminÃ©e. $($result.metadata.taskCount) tÃ¢ches incluses." -Level Success
    }
    else {
        Write-Log "Erreur lors de la gÃ©nÃ©ration de la vue des prochaines Ã©tapes prioritaires." -Level Error
    }
}

# ExÃ©cuter la fonction principale
Main

# Generate-ActiveRoadmapView.ps1
# Script pour gÃ©nÃ©rer une vue de la roadmap active Ã  la demande

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Complete", "Incomplete", "InProgress", "Blocked", "Deferred")]
    [string]$StatusFilter = "Incomplete",
    
    [Parameter(Mandatory = $false)]
    [string]$SectionFilter,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxDepth = 0,
    
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

# Fonction pour crÃ©er un script Python temporaire pour gÃ©nÃ©rer la vue de la roadmap active
function New-ActiveRoadmapViewScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$StatusFilter,
        
        [Parameter(Mandatory = $false)]
        [string]$SectionFilter,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth,
        
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

def get_status_symbol(status):
    """Obtenir le symbole de statut pour le markdown"""
    if status == "Complete":
        return "x"
    elif status == "InProgress":
        return "o"
    elif status == "Blocked":
        return "!"
    elif status == "Deferred":
        return ">"
    else:
        return " "

def main():
    # ParamÃ¨tres
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    status_filter = '$StatusFilter'
    section_filter = r'$SectionFilter'
    max_depth = $MaxDepth
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
        
        # Construire la requÃªte pour rÃ©cupÃ©rer les tÃ¢ches
        where_clause = {}
        
        if status_filter != "All":
            where_clause["status"] = status_filter
        
        if section_filter:
            # Utiliser une requÃªte plus complexe pour la section
            # Ceci est une simplification, car Chroma ne supporte pas les recherches partielles dans les mÃ©tadonnÃ©es
            pass
        
        # RÃ©cupÃ©rer toutes les tÃ¢ches
        result = collection.get(
            where=where_clause if where_clause else None
        )
        
        if not result['ids']:
            print("Aucune tÃ¢che ne correspond aux critÃ¨res.")
            sys.exit(0)
        
        # Filtrer par section si nÃ©cessaire (post-traitement)
        filtered_indices = []
        if section_filter:
            for i, metadata in enumerate(result['metadatas']):
                section = metadata.get('section', '')
                if section_filter.lower() in section.lower():
                    filtered_indices.append(i)
        else:
            filtered_indices = list(range(len(result['ids'])))
        
        # CrÃ©er une structure de donnÃ©es pour les tÃ¢ches
        tasks = []
        for i in filtered_indices:
            task_id = result['ids'][i]
            metadata = result['metadatas'][i]
            
            # Filtrer par profondeur si nÃ©cessaire
            if max_depth > 0 and get_task_level(task_id) > max_depth:
                continue
            
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
            
            # Ajouter d'autres mÃ©tadonnÃ©es si demandÃ©
            if include_metadata:
                for key, value in metadata.items():
                    if key not in task:
                        task[key] = value
            
            tasks.append(task)
        
        # Trier les tÃ¢ches par ID
        tasks.sort(key=lambda x: [int(p) if p.isdigit() else p for p in x["id"].split('.')])
        
        # Construire une structure hiÃ©rarchique
        task_hierarchy = defaultdict(list)
        root_tasks = []
        
        for task in tasks:
            parent_id = task["parentId"]
            if not parent_id:
                root_tasks.append(task)
            else:
                task_hierarchy[parent_id].append(task)
        
        # GÃ©nÃ©rer la vue Markdown
        markdown_lines = []
        markdown_lines.append("# Roadmap Active")
        markdown_lines.append("")
        markdown_lines.append(f"GÃ©nÃ©rÃ©e le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        markdown_lines.append("")
        
        if status_filter != "All":
            markdown_lines.append(f"FiltrÃ© par statut: {status_filter}")
        
        if section_filter:
            markdown_lines.append(f"FiltrÃ© par section: {section_filter}")
        
        if max_depth > 0:
            markdown_lines.append(f"Profondeur maximale: {max_depth}")
        
        markdown_lines.append("")
        markdown_lines.append("## TÃ¢ches")
        markdown_lines.append("")
        
        # Fonction rÃ©cursive pour ajouter les tÃ¢ches Ã  la vue
        def add_tasks_to_view(tasks_list, indent=0):
            for task in tasks_list:
                # Ajouter la tÃ¢che actuelle
                status_symbol = get_status_symbol(task["status"])
                indent_str = "  " * indent
                markdown_lines.append(f"{indent_str}- [{status_symbol}] **{task['id']}** {task['description']}")
                
                # Ajouter les mÃ©tadonnÃ©es si demandÃ©
                if include_metadata:
                    metadata_str = ", ".join([f"{key}: {value}" for key, value in task.items() 
                                            if key not in ["id", "description", "parentId", "indentLevel", "level"]])
                    if metadata_str:
                        markdown_lines.append(f"{indent_str}  _{metadata_str}_")
                
                # Ajouter les tÃ¢ches enfants
                if task["id"] in task_hierarchy:
                    add_tasks_to_view(task_hierarchy[task["id"]], indent + 1)
        
        # GÃ©nÃ©rer la vue
        add_tasks_to_view(root_tasks)
        
        # Joindre les lignes et afficher le rÃ©sultat
        markdown_content = "\n".join(markdown_lines)
        
        # CrÃ©er un objet rÃ©sultat
        result = {
            "markdown": markdown_content,
            "tasks": tasks,
            "metadata": {
                "generatedAt": datetime.now().isoformat(),
                "statusFilter": status_filter,
                "sectionFilter": section_filter,
                "maxDepth": max_depth,
                "taskCount": len(tasks)
            }
        }
        
        # Afficher le rÃ©sultat au format JSON
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors de la gÃ©nÃ©ration de la vue de la roadmap: {e}")
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
    text-decoration: line-through;
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
    $html = $html -replace '^\s*- \[ \] \*\*(.*?)\*\* (.*?)$', '<li class="task-incomplete"><input type="checkbox" disabled> <strong>$1</strong> $2</li>'
    $html = $html -replace '^\s*- \[o\] \*\*(.*?)\*\* (.*?)$', '<li class="task-inprogress"><input type="checkbox" disabled> <strong>$1</strong> $2 (En cours)</li>'
    $html = $html -replace '^\s*- \[!\] \*\*(.*?)\*\* (.*?)$', '<li class="task-blocked"><input type="checkbox" disabled> <strong>$1</strong> $2 (BloquÃ©)</li>'
    $html = $html -replace '^\s*- \[>\] \*\*(.*?)\*\* (.*?)$', '<li class="task-deferred"><input type="checkbox" disabled> <strong>$1</strong> $2 (ReportÃ©)</li>'
    
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
    <title>Roadmap Active</title>
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
    Write-Log "CrÃ©ation du script Python pour gÃ©nÃ©rer la vue de la roadmap active..." -Level Info
    $pythonScript = New-ActiveRoadmapViewScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -StatusFilter $StatusFilter -SectionFilter $SectionFilter -MaxDepth $MaxDepth -IncludeMetadata $IncludeMetadata
    
    # ExÃ©cuter le script Python et capturer la sortie JSON
    Write-Log "GÃ©nÃ©ration de la vue de la roadmap active..." -Level Info
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
                    Write-Log "Vue de la roadmap active sauvegardÃ©e au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $content
                }
            }
            "html" {
                $html = Convert-MarkdownToHtml -Markdown $result.markdown
                
                if ($OutputPath) {
                    $html | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue de la roadmap active sauvegardÃ©e au format HTML dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $html
                }
            }
            "json" {
                if ($OutputPath) {
                    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue de la roadmap active sauvegardÃ©e au format JSON dans $OutputPath" -Level Success
                }
                else {
                    $result | ConvertTo-Json -Depth 10
                }
            }
        }
        
        Write-Log "GÃ©nÃ©ration de la vue terminÃ©e. $($result.metadata.taskCount) tÃ¢ches incluses." -Level Success
    }
    else {
        Write-Log "Erreur lors de la gÃ©nÃ©ration de la vue de la roadmap active." -Level Error
    }
}

# ExÃ©cuter la fonction principale
Main

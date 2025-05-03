# Generate-ActiveRoadmapView.ps1
# Script pour générer une vue de la roadmap active à la demande

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

# Fonction pour créer un script Python temporaire pour générer la vue de la roadmap active
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
    """Déterminer le niveau hiérarchique d'une tâche à partir de son ID"""
    return len(task_id.split('.'))

def get_parent_id(task_id):
    """Obtenir l'ID parent d'une tâche"""
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
    # Paramètres
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
        
        # Construire la requête pour récupérer les tâches
        where_clause = {}
        
        if status_filter != "All":
            where_clause["status"] = status_filter
        
        if section_filter:
            # Utiliser une requête plus complexe pour la section
            # Ceci est une simplification, car Chroma ne supporte pas les recherches partielles dans les métadonnées
            pass
        
        # Récupérer toutes les tâches
        result = collection.get(
            where=where_clause if where_clause else None
        )
        
        if not result['ids']:
            print("Aucune tâche ne correspond aux critères.")
            sys.exit(0)
        
        # Filtrer par section si nécessaire (post-traitement)
        filtered_indices = []
        if section_filter:
            for i, metadata in enumerate(result['metadatas']):
                section = metadata.get('section', '')
                if section_filter.lower() in section.lower():
                    filtered_indices.append(i)
        else:
            filtered_indices = list(range(len(result['ids'])))
        
        # Créer une structure de données pour les tâches
        tasks = []
        for i in filtered_indices:
            task_id = result['ids'][i]
            metadata = result['metadatas'][i]
            
            # Filtrer par profondeur si nécessaire
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
            
            # Ajouter d'autres métadonnées si demandé
            if include_metadata:
                for key, value in metadata.items():
                    if key not in task:
                        task[key] = value
            
            tasks.append(task)
        
        # Trier les tâches par ID
        tasks.sort(key=lambda x: [int(p) if p.isdigit() else p for p in x["id"].split('.')])
        
        # Construire une structure hiérarchique
        task_hierarchy = defaultdict(list)
        root_tasks = []
        
        for task in tasks:
            parent_id = task["parentId"]
            if not parent_id:
                root_tasks.append(task)
            else:
                task_hierarchy[parent_id].append(task)
        
        # Générer la vue Markdown
        markdown_lines = []
        markdown_lines.append("# Roadmap Active")
        markdown_lines.append("")
        markdown_lines.append(f"Générée le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        markdown_lines.append("")
        
        if status_filter != "All":
            markdown_lines.append(f"Filtré par statut: {status_filter}")
        
        if section_filter:
            markdown_lines.append(f"Filtré par section: {section_filter}")
        
        if max_depth > 0:
            markdown_lines.append(f"Profondeur maximale: {max_depth}")
        
        markdown_lines.append("")
        markdown_lines.append("## Tâches")
        markdown_lines.append("")
        
        # Fonction récursive pour ajouter les tâches à la vue
        def add_tasks_to_view(tasks_list, indent=0):
            for task in tasks_list:
                # Ajouter la tâche actuelle
                status_symbol = get_status_symbol(task["status"])
                indent_str = "  " * indent
                markdown_lines.append(f"{indent_str}- [{status_symbol}] **{task['id']}** {task['description']}")
                
                # Ajouter les métadonnées si demandé
                if include_metadata:
                    metadata_str = ", ".join([f"{key}: {value}" for key, value in task.items() 
                                            if key not in ["id", "description", "parentId", "indentLevel", "level"]])
                    if metadata_str:
                        markdown_lines.append(f"{indent_str}  _{metadata_str}_")
                
                # Ajouter les tâches enfants
                if task["id"] in task_hierarchy:
                    add_tasks_to_view(task_hierarchy[task["id"]], indent + 1)
        
        # Générer la vue
        add_tasks_to_view(root_tasks)
        
        # Joindre les lignes et afficher le résultat
        markdown_content = "\n".join(markdown_lines)
        
        # Créer un objet résultat
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
        
        # Afficher le résultat au format JSON
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors de la génération de la vue de la roadmap: {e}")
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
    
    # Convertir les listes et les tâches
    $html = $html -replace '^\s*- \[x\] \*\*(.*?)\*\* (.*?)$', '<li class="task-complete"><input type="checkbox" checked disabled> <strong>$1</strong> $2</li>'
    $html = $html -replace '^\s*- \[ \] \*\*(.*?)\*\* (.*?)$', '<li class="task-incomplete"><input type="checkbox" disabled> <strong>$1</strong> $2</li>'
    $html = $html -replace '^\s*- \[o\] \*\*(.*?)\*\* (.*?)$', '<li class="task-inprogress"><input type="checkbox" disabled> <strong>$1</strong> $2 (En cours)</li>'
    $html = $html -replace '^\s*- \[!\] \*\*(.*?)\*\* (.*?)$', '<li class="task-blocked"><input type="checkbox" disabled> <strong>$1</strong> $2 (Bloqué)</li>'
    $html = $html -replace '^\s*- \[>\] \*\*(.*?)\*\* (.*?)$', '<li class="task-deferred"><input type="checkbox" disabled> <strong>$1</strong> $2 (Reporté)</li>'
    
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
    
    # Vérifier si le fichier de sortie existe déjà
    if ($OutputPath -and (Test-Path -Path $OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie $OutputPath existe déjà. Utilisez -Force pour l'écraser." -Level Warning
        return
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour générer la vue de la roadmap active..." -Level Info
    $pythonScript = New-ActiveRoadmapViewScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -StatusFilter $StatusFilter -SectionFilter $SectionFilter -MaxDepth $MaxDepth -IncludeMetadata $IncludeMetadata
    
    # Exécuter le script Python et capturer la sortie JSON
    Write-Log "Génération de la vue de la roadmap active..." -Level Info
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
                    Write-Log "Vue de la roadmap active sauvegardée au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $content
                }
            }
            "html" {
                $html = Convert-MarkdownToHtml -Markdown $result.markdown
                
                if ($OutputPath) {
                    $html | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue de la roadmap active sauvegardée au format HTML dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $html
                }
            }
            "json" {
                if ($OutputPath) {
                    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Vue de la roadmap active sauvegardée au format JSON dans $OutputPath" -Level Success
                }
                else {
                    $result | ConvertTo-Json -Depth 10
                }
            }
        }
        
        Write-Log "Génération de la vue terminée. $($result.metadata.taskCount) tâches incluses." -Level Success
    }
    else {
        Write-Log "Erreur lors de la génération de la vue de la roadmap active." -Level Error
    }
}

# Exécuter la fonction principale
Main

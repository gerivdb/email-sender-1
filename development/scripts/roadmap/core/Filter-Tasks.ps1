# Filter-Tasks.ps1
# Script pour filtrer les tÃ¢ches de la roadmap selon diffÃ©rents critÃ¨res

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$IndexPath = "projet\roadmaps\vectors\task_indexes.json",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Complete", "Incomplete", "All")]
    [string]$Status = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$Section,
    
    [Parameter(Mandatory = $false)]
    [string]$ParentId,
    
    [Parameter(Mandatory = $false)]
    [int]$IndentLevel = -1,
    
    [Parameter(Mandatory = $false)]
    [string]$LastUpdatedBefore,
    
    [Parameter(Mandatory = $false)]
    [string]$LastUpdatedAfter,
    
    [Parameter(Mandatory = $false)]
    [string]$Assignee,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("console", "json", "markdown")]
    [string]$OutputFormat = "console",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
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

# Fonction pour crÃ©er un script Python temporaire pour le filtrage des tÃ¢ches
function New-TaskFilterScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$IndexPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [string]$Section,
        
        [Parameter(Mandatory = $false)]
        [string]$ParentId,
        
        [Parameter(Mandatory = $false)]
        [int]$IndentLevel,
        
        [Parameter(Mandatory = $false)]
        [string]$LastUpdatedBefore,
        
        [Parameter(Mandatory = $false)]
        [string]$LastUpdatedAfter,
        
        [Parameter(Mandatory = $false)]
        [string]$Assignee
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import json
import chromadb
import os
import sys
from datetime import datetime

def parse_date(date_str):
    """Parse a date string in YYYY-MM-DD format"""
    if not date_str:
        return None
    try:
        return datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        print(f"Format de date invalide: {date_str}. Utilisez le format YYYY-MM-DD.")
        return None

def main():
    # ParamÃ¨tres
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    index_path = r'$IndexPath'
    status_filter = '$Status'
    section_filter = r'$Section'
    parent_id_filter = r'$ParentId'
    indent_level_filter = $IndentLevel
    last_updated_before = r'$LastUpdatedBefore'
    last_updated_after = r'$LastUpdatedAfter'
    assignee_filter = r'$Assignee'
    
    # VÃ©rifier si le fichier d'index existe
    if not os.path.exists(index_path):
        print(f"Le fichier d'index {index_path} n'existe pas.")
        sys.exit(1)
    
    # Charger les index
    try:
        with open(index_path, 'r', encoding='utf-8') as f:
            indexes = json.load(f)
    except Exception as e:
        print(f"Erreur lors du chargement du fichier d'index: {e}")
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
        
        # PrÃ©parer les filtres
        task_ids = set()
        
        # Filtrer par statut
        if status_filter != "All":
            if status_filter in indexes['indexes']['byStatus']:
                task_ids.update(indexes['indexes']['byStatus'][status_filter])
            else:
                print(f"Aucune tÃ¢che avec le statut '{status_filter}' trouvÃ©e.")
                if not task_ids:  # Si c'est le premier filtre, on initialise avec un ensemble vide
                    task_ids = set()
        else:
            # Si pas de filtre de statut, inclure toutes les tÃ¢ches
            task_ids = set(indexes['indexes']['byId'].keys())
        
        # Filtrer par section
        if section_filter:
            section_tasks = set()
            for section, tasks in indexes['indexes']['bySection'].items():
                if section_filter.lower() in section.lower():
                    section_tasks.update(tasks)
            
            if section_tasks:
                if task_ids:
                    task_ids = task_ids.intersection(section_tasks)
                else:
                    task_ids = section_tasks
            else:
                print(f"Aucune tÃ¢che dans la section '{section_filter}' trouvÃ©e.")
                task_ids = set()  # Aucune correspondance, ensemble vide
        
        # Filtrer par ID parent
        if parent_id_filter:
            if parent_id_filter in indexes['indexes']['byParentId']:
                parent_tasks = set(indexes['indexes']['byParentId'][parent_id_filter])
                if task_ids:
                    task_ids = task_ids.intersection(parent_tasks)
                else:
                    task_ids = parent_tasks
            else:
                print(f"Aucune tÃ¢che avec l'ID parent '{parent_id_filter}' trouvÃ©e.")
                task_ids = set()  # Aucune correspondance, ensemble vide
        
        # Filtrer par niveau d'indentation
        if indent_level_filter >= 0:
            indent_tasks = set()
            if str(indent_level_filter) in indexes['indexes']['byIndentLevel']:
                indent_tasks = set(indexes['indexes']['byIndentLevel'][str(indent_level_filter)])
            
            if indent_tasks:
                if task_ids:
                    task_ids = task_ids.intersection(indent_tasks)
                else:
                    task_ids = indent_tasks
            else:
                print(f"Aucune tÃ¢che avec le niveau d'indentation {indent_level_filter} trouvÃ©e.")
                task_ids = set()  # Aucune correspondance, ensemble vide
        
        # Convertir les dates pour le filtrage
        before_date = parse_date(last_updated_before)
        after_date = parse_date(last_updated_after)
        
        # Si des filtres de date sont spÃ©cifiÃ©s, nous devons rÃ©cupÃ©rer les mÃ©tadonnÃ©es des tÃ¢ches
        if before_date or after_date or assignee_filter:
            # RÃ©cupÃ©rer les mÃ©tadonnÃ©es des tÃ¢ches filtrÃ©es jusqu'Ã  prÃ©sent
            filtered_task_ids = list(task_ids)
            
            if filtered_task_ids:
                # RÃ©cupÃ©rer les mÃ©tadonnÃ©es des tÃ¢ches
                result = collection.get(ids=filtered_task_ids)
                
                # Appliquer les filtres de date et d'assignÃ©
                date_filtered_ids = set()
                
                for i, task_id in enumerate(result['ids']):
                    metadata = result['metadatas'][i]
                    
                    # Filtrer par date de mise Ã  jour
                    if before_date or after_date:
                        task_date_str = metadata.get('lastUpdated', '')
                        if task_date_str:
                            try:
                                task_date = datetime.strptime(task_date_str, "%Y-%m-%d")
                                
                                if before_date and task_date > before_date:
                                    continue
                                
                                if after_date and task_date < after_date:
                                    continue
                            except ValueError:
                                # Ignorer les dates invalides
                                pass
                    
                    # Filtrer par assignÃ©
                    if assignee_filter:
                        task_assignee = metadata.get('assignee', '')
                        if not task_assignee or assignee_filter.lower() not in task_assignee.lower():
                            continue
                    
                    # Si la tÃ¢che passe tous les filtres, l'ajouter Ã  l'ensemble filtrÃ©
                    date_filtered_ids.add(task_id)
                
                # Mettre Ã  jour l'ensemble des IDs filtrÃ©s
                task_ids = date_filtered_ids
        
        # Convertir l'ensemble en liste pour le tri
        filtered_task_ids = list(task_ids)
        
        if not filtered_task_ids:
            print("Aucune tÃ¢che ne correspond aux critÃ¨res de filtrage.")
            sys.exit(0)
        
        # RÃ©cupÃ©rer les dÃ©tails des tÃ¢ches filtrÃ©es
        result = collection.get(ids=filtered_task_ids)
        
        # PrÃ©parer les rÃ©sultats
        filtered_results = []
        
        for i, task_id in enumerate(result['ids']):
            metadata = result['metadatas'][i]
            document = result['documents'][i]
            
            task_result = {
                "taskId": task_id,
                "description": metadata.get("description", ""),
                "status": metadata.get("status", ""),
                "section": metadata.get("section", ""),
                "indentLevel": metadata.get("indentLevel", 0),
                "lastUpdated": metadata.get("lastUpdated", ""),
                "parentId": metadata.get("parentId", ""),
                "document": document
            }
            
            # Ajouter l'assignÃ© s'il existe
            if 'assignee' in metadata:
                task_result["assignee"] = metadata["assignee"]
            
            filtered_results.append(task_result)
        
        # Trier les rÃ©sultats par ID de tÃ¢che
        filtered_results.sort(key=lambda x: x["taskId"])
        
        # Afficher les rÃ©sultats au format JSON
        print(json.dumps(filtered_results, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors du filtrage des tÃ¢ches: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction pour formater les rÃ©sultats en Markdown
function Format-ResultsAsMarkdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Filters
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Construire la description des filtres
    $filterDescription = "**Filtres appliquÃ©s:**"
    foreach ($key in $Filters.Keys) {
        if ($Filters[$key]) {
            $filterDescription += "`n- $key : $($Filters[$key])"
        }
    }
    
    $markdown = @"
# RÃ©sultats de filtrage des tÃ¢ches

**Date:** $timestamp  
**Nombre de rÃ©sultats:** $($Results.Count)

$filterDescription

## RÃ©sultats

| ID | Description | Section | Statut | DerniÃ¨re mise Ã  jour |
|---|---|---|---|---|
"@
    
    foreach ($result in $Results) {
        $markdown += "`n| **$($result.taskId)** | $($result.description) | $($result.section) | $($result.status) | $($result.lastUpdated) |"
    }
    
    $markdown += @"

## DÃ©tails des rÃ©sultats

"@
    
    foreach ($result in $Results) {
        $markdown += @"

### $($result.taskId) - $($result.description)

- **Statut:** $($result.status)
- **Section:** $($result.section)
- **DerniÃ¨re mise Ã  jour:** $($result.lastUpdated)
- **ID parent:** $($result.parentId)
- **Niveau d'indentation:** $($result.indentLevel)

"@
        
        if ($result.assignee) {
            $markdown += "- **AssignÃ© Ã :** $($result.assignee)`n"
        }
    }
    
    return $markdown
}

# Fonction pour afficher les rÃ©sultats dans la console
function Show-ResultsInConsole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Filters
    )
    
    Write-Host "`nRÃ©sultats du filtrage des tÃ¢ches" -ForegroundColor Cyan
    Write-Host "Nombre de rÃ©sultats: $($Results.Count)" -ForegroundColor Cyan
    
    # Afficher les filtres appliquÃ©s
    Write-Host "`nFiltres appliquÃ©s:" -ForegroundColor Yellow
    foreach ($key in $Filters.Keys) {
        if ($Filters[$key]) {
            Write-Host "- $key : $($Filters[$key])" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n------------------------------------------------------------" -ForegroundColor Cyan
    
    foreach ($result in $Results) {
        Write-Host "ID: " -NoNewline
        Write-Host "$($result.taskId)" -ForegroundColor Yellow
        
        Write-Host "Description: $($result.description)"
        Write-Host "Section: $($result.section)"
        Write-Host "Statut: $($result.status)"
        Write-Host "DerniÃ¨re mise Ã  jour: $($result.lastUpdated)"
        
        if ($result.assignee) {
            Write-Host "AssignÃ© Ã : $($result.assignee)"
        }
        
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
    }
}

# Fonction principale
function Main {
    # VÃ©rifier si la base Chroma existe
    if (-not (Test-Path -Path $ChromaDbPath)) {
        Write-Log "La base Chroma $ChromaDbPath n'existe pas." -Level Error
        return
    }
    
    # VÃ©rifier si le fichier d'index existe
    if (-not (Test-Path -Path $IndexPath)) {
        Write-Log "Le fichier d'index $IndexPath n'existe pas." -Level Error
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
    
    # CrÃ©er le script Python temporaire
    Write-Log "CrÃ©ation du script Python pour le filtrage des tÃ¢ches..." -Level Info
    $pythonScript = New-TaskFilterScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -IndexPath $IndexPath -Status $Status -Section $Section -ParentId $ParentId -IndentLevel $IndentLevel -LastUpdatedBefore $LastUpdatedBefore -LastUpdatedAfter $LastUpdatedAfter -Assignee $Assignee
    
    # ExÃ©cuter le script Python et capturer la sortie JSON
    Write-Log "ExÃ©cution du filtrage des tÃ¢ches..." -Level Info
    $output = python $pythonScript 2>&1
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    # Extraire les rÃ©sultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("[")
    $jsonEndIndex = $output.LastIndexOf("]")
    
    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $results = $jsonString | ConvertFrom-Json
        
        # CrÃ©er un hashtable des filtres appliquÃ©s
        $filters = @{
            "Statut" = $Status
            "Section" = $Section
            "ID parent" = $ParentId
            "Niveau d'indentation" = if ($IndentLevel -ge 0) { $IndentLevel } else { $null }
            "Mise Ã  jour avant" = $LastUpdatedBefore
            "Mise Ã  jour aprÃ¨s" = $LastUpdatedAfter
            "AssignÃ© Ã " = $Assignee
        }
        
        # Traiter les rÃ©sultats selon le format demandÃ©
        switch ($OutputFormat) {
            "console" {
                Show-ResultsInConsole -Results $results -Filters $filters
            }
            "json" {
                $jsonOutput = @{
                    filters = $filters
                    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    results = $results
                } | ConvertTo-Json -Depth 10
                
                if ($OutputPath) {
                    $jsonOutput | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "RÃ©sultats sauvegardÃ©s au format JSON dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $jsonOutput
                }
            }
            "markdown" {
                $markdownOutput = Format-ResultsAsMarkdown -Results $results -Filters $filters
                
                if ($OutputPath) {
                    $markdownOutput | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "RÃ©sultats sauvegardÃ©s au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $markdownOutput
                }
            }
        }
        
        Write-Log "Filtrage terminÃ©. $($results.Count) rÃ©sultats trouvÃ©s." -Level Success
    }
    else {
        Write-Log "Aucun rÃ©sultat trouvÃ© ou erreur lors du filtrage." -Level Warning
    }
}

# ExÃ©cuter la fonction principale
Main

# Filter-Tasks.ps1
# Script pour filtrer les tâches de la roadmap selon différents critères

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

# Fonction pour créer un script Python temporaire pour le filtrage des tâches
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
    # Paramètres
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
    
    # Vérifier si le fichier d'index existe
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
        
        # Préparer les filtres
        task_ids = set()
        
        # Filtrer par statut
        if status_filter != "All":
            if status_filter in indexes['indexes']['byStatus']:
                task_ids.update(indexes['indexes']['byStatus'][status_filter])
            else:
                print(f"Aucune tâche avec le statut '{status_filter}' trouvée.")
                if not task_ids:  # Si c'est le premier filtre, on initialise avec un ensemble vide
                    task_ids = set()
        else:
            # Si pas de filtre de statut, inclure toutes les tâches
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
                print(f"Aucune tâche dans la section '{section_filter}' trouvée.")
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
                print(f"Aucune tâche avec l'ID parent '{parent_id_filter}' trouvée.")
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
                print(f"Aucune tâche avec le niveau d'indentation {indent_level_filter} trouvée.")
                task_ids = set()  # Aucune correspondance, ensemble vide
        
        # Convertir les dates pour le filtrage
        before_date = parse_date(last_updated_before)
        after_date = parse_date(last_updated_after)
        
        # Si des filtres de date sont spécifiés, nous devons récupérer les métadonnées des tâches
        if before_date or after_date or assignee_filter:
            # Récupérer les métadonnées des tâches filtrées jusqu'à présent
            filtered_task_ids = list(task_ids)
            
            if filtered_task_ids:
                # Récupérer les métadonnées des tâches
                result = collection.get(ids=filtered_task_ids)
                
                # Appliquer les filtres de date et d'assigné
                date_filtered_ids = set()
                
                for i, task_id in enumerate(result['ids']):
                    metadata = result['metadatas'][i]
                    
                    # Filtrer par date de mise à jour
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
                    
                    # Filtrer par assigné
                    if assignee_filter:
                        task_assignee = metadata.get('assignee', '')
                        if not task_assignee or assignee_filter.lower() not in task_assignee.lower():
                            continue
                    
                    # Si la tâche passe tous les filtres, l'ajouter à l'ensemble filtré
                    date_filtered_ids.add(task_id)
                
                # Mettre à jour l'ensemble des IDs filtrés
                task_ids = date_filtered_ids
        
        # Convertir l'ensemble en liste pour le tri
        filtered_task_ids = list(task_ids)
        
        if not filtered_task_ids:
            print("Aucune tâche ne correspond aux critères de filtrage.")
            sys.exit(0)
        
        # Récupérer les détails des tâches filtrées
        result = collection.get(ids=filtered_task_ids)
        
        # Préparer les résultats
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
            
            # Ajouter l'assigné s'il existe
            if 'assignee' in metadata:
                task_result["assignee"] = metadata["assignee"]
            
            filtered_results.append(task_result)
        
        # Trier les résultats par ID de tâche
        filtered_results.sort(key=lambda x: x["taskId"])
        
        # Afficher les résultats au format JSON
        print(json.dumps(filtered_results, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors du filtrage des tâches: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction pour formater les résultats en Markdown
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
    $filterDescription = "**Filtres appliqués:**"
    foreach ($key in $Filters.Keys) {
        if ($Filters[$key]) {
            $filterDescription += "`n- $key : $($Filters[$key])"
        }
    }
    
    $markdown = @"
# Résultats de filtrage des tâches

**Date:** $timestamp  
**Nombre de résultats:** $($Results.Count)

$filterDescription

## Résultats

| ID | Description | Section | Statut | Dernière mise à jour |
|---|---|---|---|---|
"@
    
    foreach ($result in $Results) {
        $markdown += "`n| **$($result.taskId)** | $($result.description) | $($result.section) | $($result.status) | $($result.lastUpdated) |"
    }
    
    $markdown += @"

## Détails des résultats

"@
    
    foreach ($result in $Results) {
        $markdown += @"

### $($result.taskId) - $($result.description)

- **Statut:** $($result.status)
- **Section:** $($result.section)
- **Dernière mise à jour:** $($result.lastUpdated)
- **ID parent:** $($result.parentId)
- **Niveau d'indentation:** $($result.indentLevel)

"@
        
        if ($result.assignee) {
            $markdown += "- **Assigné à:** $($result.assignee)`n"
        }
    }
    
    return $markdown
}

# Fonction pour afficher les résultats dans la console
function Show-ResultsInConsole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Filters
    )
    
    Write-Host "`nRésultats du filtrage des tâches" -ForegroundColor Cyan
    Write-Host "Nombre de résultats: $($Results.Count)" -ForegroundColor Cyan
    
    # Afficher les filtres appliqués
    Write-Host "`nFiltres appliqués:" -ForegroundColor Yellow
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
        Write-Host "Dernière mise à jour: $($result.lastUpdated)"
        
        if ($result.assignee) {
            Write-Host "Assigné à: $($result.assignee)"
        }
        
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
    }
}

# Fonction principale
function Main {
    # Vérifier si la base Chroma existe
    if (-not (Test-Path -Path $ChromaDbPath)) {
        Write-Log "La base Chroma $ChromaDbPath n'existe pas." -Level Error
        return
    }
    
    # Vérifier si le fichier d'index existe
    if (-not (Test-Path -Path $IndexPath)) {
        Write-Log "Le fichier d'index $IndexPath n'existe pas." -Level Error
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
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour le filtrage des tâches..." -Level Info
    $pythonScript = New-TaskFilterScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -IndexPath $IndexPath -Status $Status -Section $Section -ParentId $ParentId -IndentLevel $IndentLevel -LastUpdatedBefore $LastUpdatedBefore -LastUpdatedAfter $LastUpdatedAfter -Assignee $Assignee
    
    # Exécuter le script Python et capturer la sortie JSON
    Write-Log "Exécution du filtrage des tâches..." -Level Info
    $output = python $pythonScript 2>&1
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    # Extraire les résultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("[")
    $jsonEndIndex = $output.LastIndexOf("]")
    
    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $results = $jsonString | ConvertFrom-Json
        
        # Créer un hashtable des filtres appliqués
        $filters = @{
            "Statut" = $Status
            "Section" = $Section
            "ID parent" = $ParentId
            "Niveau d'indentation" = if ($IndentLevel -ge 0) { $IndentLevel } else { $null }
            "Mise à jour avant" = $LastUpdatedBefore
            "Mise à jour après" = $LastUpdatedAfter
            "Assigné à" = $Assignee
        }
        
        # Traiter les résultats selon le format demandé
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
                    Write-Log "Résultats sauvegardés au format JSON dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $jsonOutput
                }
            }
            "markdown" {
                $markdownOutput = Format-ResultsAsMarkdown -Results $results -Filters $filters
                
                if ($OutputPath) {
                    $markdownOutput | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Résultats sauvegardés au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $markdownOutput
                }
            }
        }
        
        Write-Log "Filtrage terminé. $($results.Count) résultats trouvés." -Level Success
    }
    else {
        Write-Log "Aucun résultat trouvé ou erreur lors du filtrage." -Level Warning
    }
}

# Exécuter la fonction principale
Main

# Index-TaskVectors.ps1
# Script pour indexer les vecteurs de tâches par identifiant, statut, date, etc.

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$IndexOutputPath = "projet\roadmaps\vectors\task_indexes.json",
    
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
    $requiredPackages = @("chromadb", "numpy", "pandas")
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

# Fonction pour créer un script Python temporaire pour indexer les vecteurs
function New-TaskIndexScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$IndexOutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import json
import chromadb
import os
import sys
from datetime import datetime
from collections import defaultdict

def main():
    # Paramètres
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    index_output_path = r'$IndexOutputPath'
    force = $($Force.ToString().ToLower())
    
    # Vérifier si le fichier d'index existe déjà
    if os.path.exists(index_output_path) and not force:
        print(f"Le fichier d'index {index_output_path} existe déjà. Utilisez -Force pour l'écraser.")
        sys.exit(0)
    
    # Créer le dossier de sortie s'il n'existe pas
    os.makedirs(os.path.dirname(index_output_path), exist_ok=True)
    
    # Initialiser le client Chroma
    print(f"Connexion à la base Chroma dans {chroma_db_path}...")
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
        
        # Récupérer toutes les données
        print("Récupération des données de la collection...")
        result = collection.get()
        
        if not result['ids']:
            print("La collection est vide.")
            sys.exit(0)
        
        # Créer les index
        print("Création des index...")
        
        # Index par ID
        id_index = {task_id: i for i, task_id in enumerate(result['ids'])}
        
        # Index par statut
        status_index = defaultdict(list)
        for i, metadata in enumerate(result['metadatas']):
            status = metadata.get('status', 'Unknown')
            status_index[status].append(result['ids'][i])
        
        # Index par section
        section_index = defaultdict(list)
        for i, metadata in enumerate(result['metadatas']):
            section = metadata.get('section', 'Unknown')
            section_index[section].append(result['ids'][i])
        
        # Index par niveau d'indentation
        indent_index = defaultdict(list)
        for i, metadata in enumerate(result['metadatas']):
            indent = metadata.get('indentLevel', 0)
            indent_index[str(indent)].append(result['ids'][i])
        
        # Index par date de mise à jour
        date_index = defaultdict(list)
        for i, metadata in enumerate(result['metadatas']):
            date = metadata.get('lastUpdated', 'Unknown')
            date_index[date].append(result['ids'][i])
        
        # Index par ID parent
        parent_index = defaultdict(list)
        for i, metadata in enumerate(result['metadatas']):
            parent = metadata.get('parentId', '')
            if parent:  # Ne pas indexer les tâches sans parent
                parent_index[parent].append(result['ids'][i])
        
        # Créer l'objet d'index complet
        indexes = {
            'metadata': {
                'created': datetime.now().isoformat(),
                'collection': collection_name,
                'taskCount': len(result['ids'])
            },
            'indexes': {
                'byId': id_index,
                'byStatus': dict(status_index),
                'bySection': dict(section_index),
                'byIndentLevel': dict(indent_index),
                'byDate': dict(date_index),
                'byParentId': dict(parent_index)
            }
        }
        
        # Sauvegarder les index dans un fichier JSON
        print(f"Sauvegarde des index dans {index_output_path}...")
        with open(index_output_path, 'w', encoding='utf-8') as f:
            json.dump(indexes, f, indent=2, ensure_ascii=False)
        
        print(f"Indexation terminée. Les index ont été sauvegardés dans {index_output_path}.")
        print(f"Statistiques des index:")
        print(f"  - Nombre total de tâches: {len(result['ids'])}")
        print(f"  - Nombre de statuts différents: {len(status_index)}")
        print(f"  - Nombre de sections différentes: {len(section_index)}")
        print(f"  - Nombre de niveaux d'indentation: {len(indent_index)}")
        print(f"  - Nombre de dates de mise à jour: {len(date_index)}")
        print(f"  - Nombre de tâches avec parent: {sum(len(tasks) for tasks in parent_index.values())}")
        
    except Exception as e:
        print(f"Erreur lors de l'indexation des tâches: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction principale
function Main {
    # Vérifier si la base Chroma existe
    if (-not (Test-Path -Path $ChromaDbPath)) {
        Write-Log "La base Chroma $ChromaDbPath n'existe pas." -Level Error
        return
    }
    
    # Vérifier si le fichier d'index existe déjà
    if ((Test-Path -Path $IndexOutputPath) -and -not $Force) {
        Write-Log "Le fichier d'index $IndexOutputPath existe déjà. Utilisez -Force pour l'écraser." -Level Warning
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
    Write-Log "Création du script Python pour l'indexation des tâches..." -Level Info
    $pythonScript = New-TaskIndexScript -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -IndexOutputPath $IndexOutputPath -Force:$Force
    
    # Exécuter le script Python
    Write-Log "Exécution du script Python pour l'indexation des tâches..." -Level Info
    python $pythonScript
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    Write-Log "Opération terminée." -Level Success
}

# Exécuter la fonction principale
Main

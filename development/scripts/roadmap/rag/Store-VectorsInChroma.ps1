# Store-VectorsInChroma.ps1
# Script pour stocker les vecteurs de tÃ¢ches dans une base vectorielle Chroma

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VectorsPath = "projet\roadmaps\vectors\task_vectors.json",
    
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
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

# Fonction pour crÃ©er un script Python temporaire pour stocker les vecteurs dans Chroma
function New-ChromaStorageScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VectorsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import json
import chromadb
import numpy as np
import os
import sys
from datetime import datetime

def main():
    # Charger les vecteurs depuis le fichier JSON
    vectors_path = r'$VectorsPath'
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    force = $($Force.ToString().ToLower())
    
    print(f"Chargement des vecteurs depuis {vectors_path}...")
    
    try:
        with open(vectors_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Erreur lors du chargement du fichier JSON: {e}")
        sys.exit(1)
    
    # CrÃ©er le dossier de la base Chroma s'il n'existe pas
    os.makedirs(chroma_db_path, exist_ok=True)
    
    # Initialiser le client Chroma
    print(f"Initialisation de la base Chroma dans {chroma_db_path}...")
    client = chromadb.PersistentClient(path=chroma_db_path)
    
    # VÃ©rifier si la collection existe dÃ©jÃ 
    try:
        existing_collections = client.list_collections()
        collection_exists = any(c.name == collection_name for c in existing_collections)
        
        if collection_exists and force:
            print(f"Suppression de la collection existante {collection_name}...")
            client.delete_collection(collection_name)
            collection_exists = False
        
        if collection_exists and not force:
            print(f"La collection {collection_name} existe dÃ©jÃ . Utilisez -Force pour la remplacer.")
            sys.exit(0)
        
        # CrÃ©er la collection
        collection = client.create_collection(
            name=collection_name,
            metadata={"description": "Roadmap tasks vectors", "created": datetime.now().isoformat()}
        )
        
        # PrÃ©parer les donnÃ©es pour l'insertion
        ids = []
        embeddings = []
        metadatas = []
        documents = []
        
        for task in data['tasks']:
            ids.append(task['TaskId'])
            embeddings.append(task['Vector'])
            
            # PrÃ©parer les mÃ©tadonnÃ©es
            metadata = {
                "description": task['Description'],
                "status": task['Status'],
                "section": task['Section'],
                "indentLevel": task['IndentLevel'],
                "lastUpdated": task['LastUpdated'],
                "parentId": task['ParentId']
            }
            metadatas.append(metadata)
            
            # PrÃ©parer le document (texte)
            document = f"ID: {task['TaskId']} | Description: {task['Description']} | Section: {task['Section']} | Status: {task['Status']}"
            documents.append(document)
        
        # InsÃ©rer les donnÃ©es par lots
        batch_size = 100
        total_tasks = len(ids)
        
        for i in range(0, total_tasks, batch_size):
            end_idx = min(i + batch_size, total_tasks)
            print(f"Insertion des tÃ¢ches {i+1} Ã  {end_idx} sur {total_tasks}...")
            
            collection.add(
                ids=ids[i:end_idx],
                embeddings=embeddings[i:end_idx],
                metadatas=metadatas[i:end_idx],
                documents=documents[i:end_idx]
            )
        
        print(f"Stockage terminÃ©. {total_tasks} tÃ¢ches ont Ã©tÃ© stockÃ©es dans la collection {collection_name}.")
        
        # VÃ©rifier que les donnÃ©es ont Ã©tÃ© correctement stockÃ©es
        count = collection.count()
        print(f"Nombre d'Ã©lÃ©ments dans la collection: {count}")
        
        if count == total_tasks:
            print("Toutes les tÃ¢ches ont Ã©tÃ© correctement stockÃ©es.")
        else:
            print(f"Attention: {total_tasks - count} tÃ¢ches n'ont pas Ã©tÃ© stockÃ©es.")
        
    except Exception as e:
        print(f"Erreur lors du stockage des vecteurs dans Chroma: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction principale
function Main {
    # VÃ©rifier si le fichier de vecteurs existe
    if (-not (Test-Path -Path $VectorsPath)) {
        Write-Log "Le fichier de vecteurs $VectorsPath n'existe pas." -Level Error
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
    Write-Log "CrÃ©ation du script Python pour le stockage dans Chroma..." -Level Info
    $pythonScript = New-ChromaStorageScript -VectorsPath $VectorsPath -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -Force:$Force
    
    # ExÃ©cuter le script Python
    Write-Log "ExÃ©cution du script Python pour le stockage dans Chroma..." -Level Info
    python $pythonScript
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    Write-Log "OpÃ©ration terminÃ©e." -Level Success
}

# ExÃ©cuter la fonction principale
Main

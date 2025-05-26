# MIGRATED TO QDRANT STANDALONE - 2025-05-25
# Index-PlanDevQdrant.ps1
# Script pour indexer les plans de développement dans Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$PlansPath = "projet/roadmaps/plans",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "plan_dev_docs",

    [Parameter(Mandatory = $false)]
    [string]$ModelEndpoint = "https://api.openrouter.ai/api/v1/embeddings",

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY,

    [Parameter(Mandatory = $false)]
    [string]$ModelName = "qwen/qwen2-7b",

    [Parameter(Mandatory = $false)]
    [int]$VectorDimension = 1536,

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
        } else {
            Write-Log "Python n'est pas correctement installé." -Level Error
            return $false
        }
    } catch {
        Write-Log "Python n'est pas installé ou n'est pas dans le PATH." -Level Error
        return $false
    }
}

# Fonction pour vérifier si les packages Python nécessaires sont installés
function Test-PythonPackages {
    $requiredPackages = @("qdrant_client", "numpy", "requests")
    $missingPackages = @()

    foreach ($package in $requiredPackages) {
        python -c "import $package" 2>&1 | Out-Null
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
        } else {
            Write-Log "Installation des packages annulée. Le script ne peut pas continuer." -Level Error
            return $false
        }
    }

    Write-Log "Tous les packages Python requis sont installés." -Level Success
    return $true
}

# Fonction pour créer un script Python temporaire pour indexer les plans de développement
function New-PlanDevIndexScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PlansPath,

        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [string]$ModelEndpoint,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $true)]
        [string]$ModelName,

        [Parameter(Mandatory = $true)]
        [int]$VectorDimension,

        [Parameter(Mandatory = $false)]
        [bool]$Force
    )

    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $scriptContent = @"
import json
import os
import sys
import glob
import re
import requests
import numpy as np
from datetime import datetime
from qdrant_client import QdrantClient
from qdrant_client.http import models
from qdrant_client.http.exceptions import UnexpectedResponse

# Configuration
plans_path = r'$PlansPath'
qdrant_url = r'$QdrantUrl'
collection_name = '$CollectionName'
model_endpoint = r'$ModelEndpoint'
api_key = r'$ApiKey'
model_name = '$ModelName'
vector_dimension = $VectorDimension
force = $($Force.ToString().ToLower() -replace "true", "True" -replace "false", "False")

def get_embedding(text, api_key, endpoint, model):
    """Obtenir un vecteur d'embedding via l'API OpenRouter"""
    if not api_key:
        # Générer un vecteur aléatoire si pas de clé API
        print("Clé API non fournie. Génération d'un vecteur aléatoire.")
        return np.random.uniform(-1, 1, vector_dimension).tolist()

    try:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }

        data = {
            "model": model,
            "input": text
        }

        response = requests.post(endpoint, headers=headers, json=data)
        response.raise_for_status()

        result = response.json()

        if 'data' in result and len(result['data']) > 0 and 'embedding' in result['data'][0]:
            return result['data'][0]['embedding']
        else:
            print("Réponse API invalide. Génération d'un vecteur aléatoire.")
            return np.random.uniform(-1, 1, vector_dimension).tolist()
    except Exception as e:
        print(f"Erreur lors de l'appel à l'API d'embedding: {e}")
        return np.random.uniform(-1, 1, vector_dimension).tolist()

def extract_metadata_from_plan(content, filename):
    """Extraire les métadonnées d'un plan de développement"""
    metadata = {
        "filename": filename,
        "title": "",
        "version": "",
        "date": "",
        "progress": 0,
        "sections": [],
        "tasks_total": 0,
        "tasks_completed": 0
    }
    
    # Extraire le titre
    title_match = re.search(r'^# (.+)$', content, re.MULTILINE)
    if title_match:
        metadata["title"] = title_match.group(1)
    
    # Extraire la version et la date
    version_match = re.search(r'\*Version ([0-9.]+) - ([0-9-]+) - Progression globale : ([0-9]+)%\*', content)
    if version_match:
        metadata["version"] = version_match.group(1)
        metadata["date"] = version_match.group(2)
        metadata["progress"] = int(version_match.group(3))
    
    # Extraire les sections
    section_matches = re.findall(r'^## (.+)$', content, re.MULTILINE)
    metadata["sections"] = section_matches
    
    # Compter les tâches
    completed_tasks = len(re.findall(r'- \[x\]', content))
    total_tasks = len(re.findall(r'- \[[x ]\]', content))
    
    metadata["tasks_completed"] = completed_tasks
    metadata["tasks_total"] = total_tasks
    
    return metadata

def chunk_document(content, chunk_size=1000, overlap=200):
    """Diviser un document en chunks avec chevauchement"""
    # Diviser le contenu en paragraphes
    paragraphs = re.split(r'\n\n+', content)
    
    chunks = []
    current_chunk = ""
    current_size = 0
    
    for paragraph in paragraphs:
        paragraph_size = len(paragraph)
        
        if current_size + paragraph_size <= chunk_size:
            # Ajouter le paragraphe au chunk actuel
            if current_chunk:
                current_chunk += "\n\n" + paragraph
            else:
                current_chunk = paragraph
            current_size += paragraph_size
        else:
            # Sauvegarder le chunk actuel et commencer un nouveau
            if current_chunk:
                chunks.append(current_chunk)
                
                # Créer un chevauchement en prenant les derniers paragraphes
                overlap_text = ""
                overlap_paragraphs = current_chunk.split("\n\n")[-3:]  # Prendre les 3 derniers paragraphes
                if overlap_paragraphs:
                    overlap_text = "\n\n".join(overlap_paragraphs)
                
                current_chunk = overlap_text + "\n\n" + paragraph
                current_size = len(current_chunk)
            else:
                chunks.append(paragraph)
                current_chunk = ""
                current_size = 0
    
    # Ajouter le dernier chunk s'il n'est pas vide
    if current_chunk:
        chunks.append(current_chunk)
    
    return chunks

def main():
    # Vérifier si Python est installé
    print(f"Python {sys.version} détecté.")
    
    # Initialiser le client Qdrant
    try:
        print(f"Connexion à Qdrant sur {qdrant_url}...")
        client = QdrantClient(url=qdrant_url)
        
        # Vérifier si Qdrant est accessible
        client.get_collections()
    except Exception as e:
        print(f"Erreur lors de la connexion à Qdrant: {e}")
        print("Assurez-vous que Qdrant est en cours d'exécution et accessible à l'URL spécifiée.")
        sys.exit(1)
    
    # Vérifier si la collection existe
    collections = client.get_collections().collections
    collection_exists = any(c.name == collection_name for c in collections)
    
    if collection_exists:
        if force:
            print(f"Suppression de la collection existante {collection_name}...")
            client.delete_collection(collection_name=collection_name)
        else:
            print(f"La collection {collection_name} existe déjà. Utilisez -Force pour la recréer.")
            sys.exit(0)
    
    # Créer la collection
    print(f"Création de la collection {collection_name}...")
    client.create_collection(
        collection_name=collection_name,
        vectors_config=models.VectorParams(
            size=vector_dimension,
            distance=models.Distance.COSINE
        )
    )
    
    # Trouver tous les fichiers plan-dev-v*.md
    plan_files = glob.glob(os.path.join(plans_path, "plan-dev-v*.md"))
    print(f"Trouvé {len(plan_files)} fichiers de plan de développement.")
    
    # Indexer chaque fichier
    for i, plan_file in enumerate(plan_files):
        filename = os.path.basename(plan_file)
        print(f"[{i+1}/{len(plan_files)}] Indexation de {filename}...")
        
        try:
            # Lire le contenu du fichier
            with open(plan_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraire les métadonnées
            metadata = extract_metadata_from_plan(content, filename)
            print(f"  Titre: {metadata['title']}")
            print(f"  Version: {metadata['version']}, Date: {metadata['date']}, Progression: {metadata['progress']}%")
            print(f"  Tâches: {metadata['tasks_completed']}/{metadata['tasks_total']}")
            
            # Diviser le document en chunks
            chunks = chunk_document(content)
            print(f"  Document divisé en {len(chunks)} chunks.")
            
            # Créer un point pour le document entier
            doc_embedding = get_embedding(content[:4000], api_key, model_endpoint, model_name)
            
            doc_point = models.PointStruct(
                id=f"{filename.replace('.', '_')}_full",
                vector=doc_embedding,
                payload={
                    "filename": filename,
                    "title": metadata["title"],
                    "version": metadata["version"],
                    "date": metadata["date"],
                    "progress": metadata["progress"],
                    "sections": metadata["sections"],
                    "tasks_completed": metadata["tasks_completed"],
                    "tasks_total": metadata["tasks_total"],
                    "content_type": "full_document",
                    "content": content[:4000],  # Limiter la taille pour éviter les problèmes
                    "chunk_index": -1,
                    "total_chunks": len(chunks)
                }
            )
            
            # Ajouter le point du document entier
            client.upsert(
                collection_name=collection_name,
                points=[doc_point]
            )
            
            # Créer et ajouter les points pour chaque chunk
            chunk_points = []
            for j, chunk in enumerate(chunks):
                # Générer l'embedding pour le chunk
                chunk_embedding = get_embedding(chunk, api_key, model_endpoint, model_name)
                
                # Créer le point
                chunk_point = models.PointStruct(
                    id=f"{filename.replace('.', '_')}_chunk_{j}",
                    vector=chunk_embedding,
                    payload={
                        "filename": filename,
                        "title": metadata["title"],
                        "version": metadata["version"],
                        "date": metadata["date"],
                        "progress": metadata["progress"],
                        "content_type": "chunk",
                        "content": chunk,
                        "chunk_index": j,
                        "total_chunks": len(chunks)
                    }
                )
                
                chunk_points.append(chunk_point)
                
                # Ajouter les points par lots de 10
                if len(chunk_points) >= 10 or j == len(chunks) - 1:
                    client.upsert(
                        collection_name=collection_name,
                        points=chunk_points
                    )
                    chunk_points = []
            
            print(f"  Document et {len(chunks)} chunks indexés avec succès.")
            
        except Exception as e:
            print(f"Erreur lors de l'indexation de {filename}: {e}")
    
    # Vérifier que les documents ont été correctement indexés
    collection_info = client.get_collection(collection_name=collection_name)
    count = collection_info.vectors_count
    
    print(f"\nIndexation terminée. {count} points ont été indexés dans la collection {collection_name}.")
    print(f"Vous pouvez maintenant rechercher dans les plans de développement avec Search-PlanDevQdrant.ps1.")

if __name__ == "__main__":
    main()
"@

    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
}

# Fonction pour vérifier et démarrer le conteneur Docker de Qdrant
function Start-QdrantContainerIfNeeded {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$QdrantUrl = "http://localhost:6333",

        [Parameter(Mandatory = $false)]
        [string]$DataPath = "..\..\data\qdrant",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le conteneur est accessible
    try {
        $testUrl = "$QdrantUrl/dashboard"
        $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue

        if ($response.StatusCode -eq 200) {
            Write-Log "Qdrant est accessible à l'URL: $QdrantUrl" -Level Success
            return $true
        }
    } catch {
        Write-Log "Qdrant n'est pas accessible à l'URL: $QdrantUrl" -Level Warning
    }

    # Tenter de démarrer le conteneur Docker
    Write-Log "Tentative de démarrage du conteneur Docker pour Qdrant..." -Level Info

    $qdrantContainerScript = Join-Path $PSScriptRoot "..\..\tools\qdrant\Start-QdrantStandalone.ps1"
    if (Test-Path -Path $qdrantContainerScript) {
        & $qdrantContainerScript -Action Start -DataPath $DataPath -Force:$Force

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Conteneur Docker pour Qdrant démarré avec succès." -Level Success

            # Attendre que le service soit prêt
            Write-Log "Attente du démarrage du service Qdrant..." -Level Info
            $maxRetries = 10
            $retryCount = 0
            $serviceReady = $false

            while (-not $serviceReady -and $retryCount -lt $maxRetries) {
                Start-Sleep -Seconds 2
                $retryCount++

                try {
                    $testUrl = "$QdrantUrl/dashboard"
                    $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue

                    if ($response.StatusCode -eq 200) {
                        $serviceReady = $true
                        Write-Log "Service Qdrant prêt après $retryCount tentatives." -Level Success
                    }
                } catch {
                    Write-Log "Tentative $retryCount sur $maxRetries - Service Qdrant pas encore prêt..." -Level Info
                }
            }

            if ($serviceReady) {
                return $true
            } else {
                Write-Log "Le service Qdrant n'est pas devenu accessible après $maxRetries tentatives." -Level Warning
                return $false
            }
        } else {
            Write-Log "Erreur lors du démarrage du conteneur Docker pour Qdrant." -Level Error
            Write-Log "Assurez-vous que Docker est installé et en cours d'exécution." -Level Error
            return $false
        }
    } else {
        Write-Log "Script de gestion du conteneur Docker pour Qdrant non trouvé: $qdrantContainerScript" -Level Error
        Write-Log "Veuillez démarrer le conteneur manuellement avec Docker:" -Level Error
        Write-Log "# MIGRATED: docker run -d -p 6333:6333 -p 6334:6334 -v `"$(Resolve-Path $DataPath):/qdrant/storage`" qdrant/qdrant" -Level Error
        return $false
    }
}

# Fonction principale
function Main {
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

    # Vérifier et démarrer le conteneur Docker de Qdrant si nécessaire
    $qdrantDataPath = "..\..\data\qdrant"
    if (-not (Start-QdrantContainerIfNeeded -QdrantUrl $QdrantUrl -DataPath $qdrantDataPath -Force:$Force)) {
        Write-Log "Impossible d'assurer que le conteneur Docker de Qdrant est en cours d'exécution. Le script ne peut pas continuer." -Level Error
        return
    }

    # Créer le script Python temporaire
    Write-Log "Création du script Python pour l'indexation des plans de développement..." -Level Info
    $pythonScript = New-PlanDevIndexScript -PlansPath $PlansPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelEndpoint $ModelEndpoint -ApiKey $ApiKey -ModelName $ModelName -VectorDimension $VectorDimension -Force:$Force

    # Exécuter le script Python
    Write-Log "Exécution du script Python pour l'indexation des plans de développement..." -Level Info
    python $pythonScript

    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force

    Write-Log "Opération terminée." -Level Success
}

# Exécuter la fonction principale
Main


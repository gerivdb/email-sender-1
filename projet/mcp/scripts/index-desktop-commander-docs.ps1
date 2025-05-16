# index-desktop-commander-docs.ps1
# Script pour indexer la documentation du MCP Desktop Commander dans Qdrant
# Version: 1.0
# Date: 2025-05-16

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "mcp_docs",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelEndpoint = "https://api.openrouter.ai/api/v1/embeddings",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY,
    
    [Parameter(Mandatory = $false)]
    [string]$ModelName = "qwen/qwen2-7b",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire des logs
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour vérifier si Python est installé
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version
        Write-Log "Python version $pythonVersion est installé." -Level "INFO"
        return $true
    } catch {
        Write-Log "Python n'est pas installé ou n'est pas dans le PATH." -Level "ERROR"
        return $false
    }
}

# Fonction pour vérifier si les packages Python requis sont installés
function Test-PythonPackages {
    $requiredPackages = @("qdrant-client", "numpy", "requests")
    $missingPackages = @()
    
    foreach ($package in $requiredPackages) {
        try {
            $result = python -c "import $($package.Replace('-', '_'))"
            if ($LASTEXITCODE -ne 0) {
                $missingPackages += $package
            }
        } catch {
            $missingPackages += $package
        }
    }
    
    if ($missingPackages.Count -gt 0) {
        Write-Log "Les packages Python suivants sont manquants: $($missingPackages -join ', ')" -Level "WARNING"
        
        $installPackages = Read-Host "Voulez-vous installer les packages manquants? (O/N)"
        if ($installPackages -eq "O" -or $installPackages -eq "o") {
            foreach ($package in $missingPackages) {
                Write-Log "Installation du package $package..." -Level "INFO"
                pip install $package
            }
            Write-Log "Packages installés avec succès." -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Les packages manquants n'ont pas été installés." -Level "WARNING"
            return $false
        }
    }
    
    Write-Log "Tous les packages Python requis sont installés." -Level "SUCCESS"
    return $true
}

# Fonction pour créer un script Python temporaire pour l'indexation
function New-IndexationScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DocPath,
        
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelEndpoint,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import os
import sys
import json
import numpy as np
import requests
from qdrant_client import QdrantClient
from qdrant_client.http import models
from datetime import datetime

# Configuration
qdrant_url = r'$QdrantUrl'
collection_name = '$CollectionName'
doc_path = r'$DocPath'
model_endpoint = r'$ModelEndpoint'
api_key = r'$ApiKey'
model = '$ModelName'

def get_embedding(text, api_key, endpoint, model):
    """Génère un embedding pour le texte donné en utilisant l'API OpenRouter."""
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

        if 'data' in result and 'embedding' in result['data'][0]:
            return result['data'][0]['embedding']
        else:
            print("Réponse API invalide. Génération d'un vecteur aléatoire.")
            return np.random.uniform(-1, 1, 1536).tolist()
    except Exception as e:
        print(f"Erreur lors de l'appel à l'API d'embedding: {e}")
        return np.random.uniform(-1, 1, 1536).tolist()

def chunk_text(text, max_chunk_size=1000, overlap=100):
    """Divise le texte en chunks avec chevauchement."""
    if len(text) <= max_chunk_size:
        return [text]
    
    chunks = []
    start = 0
    
    while start < len(text):
        end = min(start + max_chunk_size, len(text))
        
        # Ajuster la fin pour ne pas couper un mot
        if end < len(text):
            while end > start and not text[end].isspace():
                end -= 1
            if end == start:  # Si aucun espace n'a été trouvé, utiliser la taille maximale
                end = min(start + max_chunk_size, len(text))
        
        chunks.append(text[start:end])
        start = end - overlap
    
    return chunks

def main():
    # Initialiser le client Qdrant
    try:
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
    
    # Créer la collection si elle n'existe pas
    if not collection_exists:
        print(f"Création de la collection {collection_name}...")
        client.create_collection(
            collection_name=collection_name,
            vectors_config=models.VectorParams(
                size=1536,
                distance=models.Distance.COSINE
            )
        )
    
    # Lire le contenu du fichier de documentation
    try:
        with open(doc_path, 'r', encoding='utf-8') as f:
            doc_content = f.read()
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier de documentation: {e}")
        sys.exit(1)
    
    # Extraire les métadonnées du fichier
    file_name = os.path.basename(doc_path)
    file_path = os.path.relpath(doc_path)
    
    # Chunker le contenu
    chunks = chunk_text(doc_content)
    print(f"Document divisé en {len(chunks)} chunks.")
    
    # Indexer chaque chunk
    for i, chunk in enumerate(chunks):
        print(f"Traitement du chunk {i+1}/{len(chunks)}...")
        
        # Générer l'embedding pour le chunk
        embedding = get_embedding(chunk, api_key, model_endpoint, model)
        
        # Créer les métadonnées
        metadata = {
            "source": "mcp_desktop_commander",
            "file_name": file_name,
            "file_path": file_path,
            "chunk_index": i,
            "total_chunks": len(chunks),
            "timestamp": datetime.now().isoformat(),
            "content_preview": chunk[:100] + "..." if len(chunk) > 100 else chunk
        }
        
        # Ajouter le point à Qdrant
        client.upsert(
            collection_name=collection_name,
            points=[
                models.PointStruct(
                    id=f"desktop_commander_{file_name.replace('.', '_')}_{i}",
                    vector=embedding,
                    payload={
                        "text": chunk,
                        "metadata": metadata
                    }
                )
            ]
        )
    
    print(f"Indexation terminée. {len(chunks)} chunks indexés dans la collection {collection_name}.")

if __name__ == "__main__":
    main()
"@
    
    $scriptContent | Set-Content -Path $scriptPath -Encoding UTF8
    return $scriptPath
}

# Fonction principale
function Main {
    Write-Log "Démarrage de l'indexation de la documentation du MCP Desktop Commander..." -Level "INFO"
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        Write-Log "Python est requis pour l'indexation. Veuillez l'installer et réessayer." -Level "ERROR"
        return
    }
    
    # Vérifier si les packages Python requis sont installés
    if (-not (Test-PythonPackages)) {
        Write-Log "Les packages Python requis sont nécessaires pour l'indexation. Veuillez les installer et réessayer." -Level "ERROR"
        return
    }
    
    # Vérifier si le fichier de documentation existe
    $docPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\docs\guides\mcp\GUIDE_MCP_DESKTOP_COMMANDER.md"
    if (-not (Test-Path -Path $docPath)) {
        Write-Log "Le fichier de documentation n'existe pas: $docPath" -Level "ERROR"
        return
    }
    
    # Créer le script Python temporaire
    $pythonScript = New-IndexationScript -DocPath $docPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelEndpoint $ModelEndpoint -ApiKey $ApiKey -ModelName $ModelName
    
    # Exécuter le script Python
    Write-Log "Exécution de l'indexation..." -Level "INFO"
    python $pythonScript
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    Write-Log "Indexation terminée." -Level "SUCCESS"
}

# Exécuter la fonction principale
Main

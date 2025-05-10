# Optimize-QdrantBatchOperations.ps1
# Script pour optimiser les opérations batch pour Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 100,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxConcurrentBatches = 4,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Upsert", "Update", "Delete", "Search")]
    [string]$OperationType = "Upsert",
    
    [Parameter(Mandatory = $false)]
    [string]$InputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        Write-Host "[$Level] $Message"
    }
}

# Fonction pour vérifier si Qdrant est en cours d'exécution
function Test-QdrantRunning {
    param (
        [string]$Host = "localhost",
        [int]$Port = 6333
    )
    
    try {
        $response = Invoke-RestMethod -Uri "http://$Host`:$Port/collections" -Method Get -ErrorAction Stop
        return $true
    }
    catch {
        Write-Log "Impossible de se connecter à Qdrant ($Host`:$Port): $_" -Level "Error"
        return $false
    }
}

# Fonction pour créer un script Python temporaire
function New-PythonBatchScript {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [int]$BatchSize,
        [int]$MaxConcurrentBatches,
        [string]$OperationType,
        [string]$InputPath,
        [string]$OutputPath,
        [bool]$Force
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $pythonScript = @"
# Script Python temporaire pour les opérations batch optimisées
import os
import json
import logging
import sys
import time
import asyncio
import aiohttp
from datetime import datetime
from typing import Dict, List, Any, Optional
from concurrent.futures import ThreadPoolExecutor

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    from qdrant_client.http.exceptions import UnexpectedResponse
except ImportError:
    logger.error("Dépendances manquantes. Installez-les avec: pip install qdrant-client")
    sys.exit(1)

# Paramètres
qdrant_url = "$QdrantUrl"
collection_name = "$CollectionName"
batch_size = $BatchSize
max_concurrent_batches = $MaxConcurrentBatches
operation_type = "$OperationType"
input_path = "$InputPath"
output_path = "$OutputPath"
force = $($Force.ToString().ToLower())

# Classe pour les opérations batch optimisées
class BatchOperationOptimizer:
    def __init__(self, url, collection_name, batch_size, max_concurrent_batches):
        self.url = url
        self.collection_name = collection_name
        self.batch_size = batch_size
        self.max_concurrent_batches = max_concurrent_batches
        self.client = QdrantClient(url=url)
        
        # Vérifier si la collection existe
        collections = self.client.get_collections().collections
        collection_exists = any(c.name == collection_name for c in collections)
        
        if not collection_exists:
            logger.error(f"La collection {collection_name} n'existe pas.")
            sys.exit(1)
    
    async def _process_batch(self, session, batch, operation, batch_index):
        """Traite un lot de points avec l'opération spécifiée"""
        start_time = time.time()
        
        try:
            if operation == "Upsert":
                endpoint = f"{self.url}/collections/{self.collection_name}/points"
                payload = {"points": batch}
                async with session.put(endpoint, json=payload) as response:
                    if response.status != 200:
                        logger.error(f"Erreur lors de l'upsert du lot {batch_index}: {response.status}")
                        return False
            
            elif operation == "Update":
                endpoint = f"{self.url}/collections/{self.collection_name}/points/payload"
                payload = {"payload": batch["payload"], "points": batch["points"]}
                async with session.post(endpoint, json=payload) as response:
                    if response.status != 200:
                        logger.error(f"Erreur lors de la mise à jour du lot {batch_index}: {response.status}")
                        return False
            
            elif operation == "Delete":
                endpoint = f"{self.url}/collections/{self.collection_name}/points/delete"
                payload = {"points": batch}
                async with session.post(endpoint, json=payload) as response:
                    if response.status != 200:
                        logger.error(f"Erreur lors de la suppression du lot {batch_index}: {response.status}")
                        return False
            
            elif operation == "Search":
                endpoint = f"{self.url}/collections/{self.collection_name}/points/search"
                payload = batch
                async with session.post(endpoint, json=payload) as response:
                    if response.status != 200:
                        logger.error(f"Erreur lors de la recherche du lot {batch_index}: {response.status}")
                        return False
                    result = await response.json()
                    return result
            
            elapsed = time.time() - start_time
            logger.info(f"Lot {batch_index} traité en {elapsed:.2f} secondes")
            return True
        
        except Exception as e:
            logger.error(f"Erreur lors du traitement du lot {batch_index}: {str(e)}")
            return False
    
    async def process_batches(self, batches, operation):
        """Traite plusieurs lots en parallèle"""
        results = []
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            for i, batch in enumerate(batches):
                task = asyncio.create_task(self._process_batch(session, batch, operation, i))
                tasks.append(task)
                
                # Limiter le nombre de tâches concurrentes
                if len(tasks) >= self.max_concurrent_batches:
                    # Attendre qu'une tâche se termine
                    done, tasks = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
                    results.extend([t.result() for t in done])
            
            # Attendre les tâches restantes
            if tasks:
                done, _ = await asyncio.wait(tasks)
                results.extend([t.result() for t in done])
        
        return results
    
    def split_into_batches(self, data):
        """Divise les données en lots"""
        batches = []
        
        if operation_type == "Upsert":
            # Diviser les points en lots
            for i in range(0, len(data), self.batch_size):
                batch = data[i:i+self.batch_size]
                batches.append(batch)
        
        elif operation_type == "Update":
            # Diviser les points en lots pour la mise à jour
            for i in range(0, len(data["points"]), self.batch_size):
                batch = {
                    "payload": data["payload"],
                    "points": data["points"][i:i+self.batch_size]
                }
                batches.append(batch)
        
        elif operation_type == "Delete":
            # Diviser les points en lots pour la suppression
            for i in range(0, len(data), self.batch_size):
                batch = data[i:i+self.batch_size]
                batches.append(batch)
        
        elif operation_type == "Search":
            # Pour la recherche, chaque requête est un lot
            if isinstance(data, list):
                batches = data
            else:
                batches = [data]
        
        return batches
    
    def run_batch_operation(self, data):
        """Exécute l'opération batch"""
        batches = self.split_into_batches(data)
        logger.info(f"Traitement de {len(batches)} lots de taille {self.batch_size}")
        
        start_time = time.time()
        results = asyncio.run(self.process_batches(batches, operation_type))
        elapsed = time.time() - start_time
        
        success_count = sum(1 for r in results if r)
        logger.info(f"Opération terminée en {elapsed:.2f} secondes")
        logger.info(f"Lots réussis: {success_count}/{len(batches)}")
        
        return results

# Fonction principale
def main():
    # Vérifier si le fichier d'entrée existe
    if input_path and not os.path.exists(input_path):
        logger.error(f"Le fichier d'entrée n'existe pas: {input_path}")
        sys.exit(1)
    
    # Vérifier si le fichier de sortie existe déjà
    if output_path and os.path.exists(output_path) and not force:
        logger.error(f"Le fichier de sortie existe déjà: {output_path}. Utilisez -Force pour l'écraser.")
        sys.exit(1)
    
    # Charger les données d'entrée
    data = None
    if input_path:
        with open(input_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    else:
        # Exemple de données pour les tests
        if operation_type == "Upsert":
            data = [
                {
                    "id": f"test_{i}",
                    "vector": [0.1, 0.2, 0.3],
                    "payload": {"text": f"Test {i}"}
                }
                for i in range(10)
            ]
        elif operation_type == "Update":
            data = {
                "payload": {"status": "Completed"},
                "points": [f"test_{i}" for i in range(10)]
            }
        elif operation_type == "Delete":
            data = [f"test_{i}" for i in range(10)]
        elif operation_type == "Search":
            data = {
                "vector": [0.1, 0.2, 0.3],
                "limit": 10
            }
    
    # Créer l'optimiseur
    optimizer = BatchOperationOptimizer(
        url=qdrant_url,
        collection_name=collection_name,
        batch_size=batch_size,
        max_concurrent_batches=max_concurrent_batches
    )
    
    # Exécuter l'opération batch
    results = optimizer.run_batch_operation(data)
    
    # Enregistrer les résultats si demandé
    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2)
        logger.info(f"Résultats enregistrés dans {output_path}")

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8
    return $tempFile
}

# Fonction principale
function Optimize-QdrantBatchOperations {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [int]$BatchSize,
        [int]$MaxConcurrentBatches,
        [string]$OperationType,
        [string]$InputPath,
        [string]$OutputPath,
        [switch]$Force
    )
    
    # Vérifier si le fichier d'entrée existe
    if ($InputPath -and -not (Test-Path -Path $InputPath)) {
        Write-Log "Le fichier d'entrée n'existe pas: $InputPath" -Level "Error"
        return $false
    }
    
    # Vérifier si le fichier de sortie existe déjà
    if ($OutputPath -and (Test-Path -Path $OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie existe déjà: $OutputPath. Utilisez -Force pour l'écraser." -Level "Error"
        return $false
    }
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour les opérations batch optimisées..." -Level "Info"
    $pythonScript = New-PythonBatchScript -QdrantUrl $QdrantUrl -CollectionName $CollectionName -BatchSize $BatchSize -MaxConcurrentBatches $MaxConcurrentBatches -OperationType $OperationType -InputPath $InputPath -OutputPath $OutputPath -Force $Force
    
    # Exécuter le script Python
    Write-Log "Exécution du script Python pour les opérations batch optimisées..." -Level "Info"
    python $pythonScript
    
    # Vérifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Opérations batch optimisées terminées avec succès." -Level "Success"
        $result = $true
    } else {
        Write-Log "Erreur lors des opérations batch optimisées." -Level "Error"
        $result = $false
    }
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    return $result
}

# Exécuter la fonction principale
Optimize-QdrantBatchOperations -QdrantUrl $QdrantUrl -CollectionName $CollectionName -BatchSize $BatchSize -MaxConcurrentBatches $MaxConcurrentBatches -OperationType $OperationType -InputPath $InputPath -OutputPath $OutputPath -Force:$Force

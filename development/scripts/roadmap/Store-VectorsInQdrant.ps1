# Store-VectorsInQdrant.ps1
# Script pour stocker les vecteurs de tâches dans une base vectorielle Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VectorsPath = "projet\roadmaps\vectors\task_vectors.json",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",

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

# Fonction pour créer un script Python temporaire pour stocker les vecteurs dans Qdrant
function New-QdrantStorageScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VectorsPath,

        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [int]$VectorDimension,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $scriptContent = @"
import json
import numpy as np
import os
import sys
import requests
from datetime import datetime
from qdrant_client import QdrantClient
from qdrant_client.http import models
from qdrant_client.http.exceptions import UnexpectedResponse

def main():
    # Charger les vecteurs depuis le fichier JSON
    vectors_path = r'$VectorsPath'
    qdrant_url = r'$QdrantUrl'
    collection_name = '$CollectionName'
    vector_dimension = $VectorDimension
    force = $($Force.ToString().ToLower() -replace "true", "True" -replace "false", "False")

    print(f"Chargement des vecteurs depuis {vectors_path}...")

    try:
        with open(vectors_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Erreur lors du chargement du fichier JSON: {e}")
        sys.exit(1)

    # Initialiser le client Qdrant
    print(f"Connexion à Qdrant sur {qdrant_url}...")
    try:
        client = QdrantClient(url=qdrant_url)

        # Vérifier si Qdrant est accessible
        client.get_collections()
    except Exception as e:
        print(f"Erreur lors de la connexion à Qdrant: {e}")
        print("Assurez-vous que Qdrant est en cours d'exécution et accessible à l'URL spécifiée.")
        sys.exit(1)

    # Vérifier si la collection existe déjà
    try:
        collections = client.get_collections().collections
        collection_exists = any(c.name == collection_name for c in collections)

        if collection_exists and force:
            print(f"Suppression de la collection existante {collection_name}...")
            client.delete_collection(collection_name=collection_name)
            collection_exists = False

        if collection_exists and not force:
            print(f"La collection {collection_name} existe déjà. Utilisez -Force pour la remplacer.")
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

        # Préparer les données pour l'insertion
        points = []
        total_tasks = len(data['tasks'])

        for i, task in enumerate(data['tasks']):
            # Préparer les métadonnées
            payload = {
                "description": task['Description'],
                "status": task['Status'],
                "section": task['Section'],
                "indentLevel": task['IndentLevel'],
                "lastUpdated": task['LastUpdated'],
                "parentId": task['ParentId'],
                "text": f"ID: {task['TaskId']} | Description: {task['Description']} | Section: {task['Section']} | Status: {task['Status']}"
            }

            # Utiliser un identifiant numérique pour Qdrant
            # Stocker l'ID original dans les métadonnées
            payload["originalId"] = task['TaskId']

            # Convertir l'ID de tâche en un entier pour Qdrant
            # Si l'ID n'est pas un nombre, utiliser l'index comme ID
            try:
                # Remplacer les points par des tirets pour créer un ID numérique
                task_id_str = str(task['TaskId']).replace('.', '')
                # Utiliser seulement les 8 premiers caractères pour éviter les dépassements d'entier
                task_id_int = int(task_id_str[:8]) if task_id_str.isdigit() else i
            except (ValueError, TypeError):
                task_id_int = i

            point = models.PointStruct(
                id=task_id_int,  # Utiliser un ID numérique
                vector=task['Vector'],
                payload=payload
            )

            points.append(point)

        # Insérer les données par lots
        batch_size = 100

        for i in range(0, total_tasks, batch_size):
            end_idx = min(i + batch_size, total_tasks)
            print(f"Insertion des tâches {i+1} à {end_idx} sur {total_tasks}...")

            batch_points = points[i:end_idx]
            client.upsert(
                collection_name=collection_name,
                points=batch_points
            )

        # Vérifier que les données ont été correctement stockées
        collection_info = client.get_collection(collection_name=collection_name)
        count = collection_info.vectors_count

        print(f"Stockage terminé. {count} tâches ont été stockées dans la collection {collection_name}.")

        if count == total_tasks:
            print("Toutes les tâches ont été correctement stockées.")
        else:
            print(f"Attention: {total_tasks - count} tâches n'ont pas été stockées.")

    except Exception as e:
        print(f"Erreur lors du stockage des vecteurs dans Qdrant: {e}")
        sys.exit(1)

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
        [string]$DataPath = "projet\roadmaps\vectors\qdrant_data",

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

    $qdrantContainerScript = Join-Path -Path $PSScriptRoot -ChildPath "Start-QdrantContainer.ps1"
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
        Write-Log "docker run -d -p 6333:6333 -p 6334:6334 -v `"$(Resolve-Path $DataPath):/qdrant/storage`" qdrant/qdrant" -Level Error
        return $false
    }
}

# Fonction principale
function Main {
    # Vérifier si le fichier de vecteurs existe
    if (-not (Test-Path -Path $VectorsPath)) {
        Write-Log "Le fichier de vecteurs $VectorsPath n'existe pas." -Level Error
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

    # Vérifier et démarrer le conteneur Docker de Qdrant si nécessaire
    if (-not (Start-QdrantContainerIfNeeded -QdrantUrl $QdrantUrl -DataPath (Join-Path -Path (Split-Path -Parent $VectorsPath) -ChildPath "qdrant_data") -Force:$Force)) {
        Write-Log "Impossible d'assurer que le conteneur Docker de Qdrant est en cours d'exécution. Le script ne peut pas continuer." -Level Error
        return
    }

    # Créer le script Python temporaire
    Write-Log "Création du script Python pour le stockage dans Qdrant..." -Level Info
    $pythonScript = New-QdrantStorageScript -VectorsPath $VectorsPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VectorDimension $VectorDimension -Force:$Force

    # Exécuter le script Python
    Write-Log "Exécution du script Python pour le stockage dans Qdrant..." -Level Info
    python $pythonScript

    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force

    Write-Log "Opération terminée." -Level Success
}

# Exécuter la fonction principale
Main

# Search-PlanDevQdrant.ps1
# Script pour rechercher dans les plans de développement indexés dans Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Query,

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
    [int]$MaxResults = 10,

    [Parameter(Mandatory = $false)]
    [ValidateSet("console", "json", "markdown")]
    [string]$OutputFormat = "console",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]$MinProgress,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]$MaxProgress,

    [Parameter(Mandatory = $false)]
    [switch]$FullDocumentsOnly
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

# Fonction pour créer un script Python temporaire pour la recherche sémantique
function New-PlanDevSearchScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,

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
        [int]$MaxResults,

        [Parameter(Mandatory = $false)]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [int]$MinProgress,

        [Parameter(Mandatory = $false)]
        [int]$MaxProgress,

        [Parameter(Mandatory = $false)]
        [bool]$FullDocumentsOnly
    )

    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $scriptContent = @"
import json
import os
import sys
import requests
import numpy as np
from datetime import datetime
from qdrant_client import QdrantClient
from qdrant_client.http import models
from qdrant_client.http.exceptions import UnexpectedResponse

# Configuration
query = r'$Query'
qdrant_url = r'$QdrantUrl'
collection_name = '$CollectionName'
model_endpoint = r'$ModelEndpoint'
api_key = r'$ApiKey'
model_name = '$ModelName'
max_results = $MaxResults
version_filter = r'$Version'
min_progress = $MinProgress
max_progress = $MaxProgress
full_documents_only = $($FullDocumentsOnly.ToString().ToLower() -replace "true", "True" -replace "false", "False")

def get_embedding(text, api_key, endpoint, model):
    """Obtenir un vecteur d'embedding via l'API OpenRouter"""
    if not api_key:
        # Générer un vecteur aléatoire si pas de clé API
        print("Clé API non fournie. Génération d'un vecteur aléatoire.")
        return np.random.uniform(-1, 1, 1536).tolist()

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
            return np.random.uniform(-1, 1, 1536).tolist()
    except Exception as e:
        print(f"Erreur lors de l'appel à l'API d'embedding: {e}")
        return np.random.uniform(-1, 1, 1536).tolist()

def main():
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
    
    if not collection_exists:
        print(f"La collection {collection_name} n'existe pas dans Qdrant.")
        print("Exécutez d'abord Index-PlanDevQdrant.ps1 pour indexer les plans de développement.")
        sys.exit(1)
    
    # Générer l'embedding pour la requête
    print("Génération de l'embedding pour la requête...")
    query_embedding = get_embedding(query, api_key, model_endpoint, model)
    
    # Préparer les filtres
    filter_conditions = []
    
    if full_documents_only:
        filter_conditions.append(
            models.FieldCondition(
                key="content_type",
                match=models.MatchValue(value="full_document")
            )
        )
    
    if version_filter:
        filter_conditions.append(
            models.FieldCondition(
                key="version",
                match=models.MatchValue(value=version_filter)
            )
        )
    
    if min_progress > 0:
        filter_conditions.append(
            models.FieldCondition(
                key="progress",
                range=models.Range(
                    gte=min_progress
                )
            )
        )
    
    if max_progress < 100:
        filter_conditions.append(
            models.FieldCondition(
                key="progress",
                range=models.Range(
                    lte=max_progress
                )
            )
        )
    
    # Construire le filtre
    search_filter = None
    if filter_conditions:
        search_filter = models.Filter(
            must=filter_conditions
        )
    
    # Effectuer la recherche
    print(f"Recherche des {max_results} documents les plus pertinents...")
    search_results = client.search(
        collection_name=collection_name,
        query_vector=query_embedding,
        limit=max_results,
        query_filter=search_filter,
        with_payload=True
    )
    
    # Préparer les résultats
    results = []
    
    for i, point in enumerate(search_results):
        payload = point.payload
        similarity = point.score  # Qdrant retourne déjà un score de similarité
        
        result = {
            "rank": i + 1,
            "id": point.id,
            "filename": payload.get("filename", ""),
            "title": payload.get("title", ""),
            "version": payload.get("version", ""),
            "progress": payload.get("progress", 0),
            "tasks_completed": payload.get("tasks_completed", 0),
            "tasks_total": payload.get("tasks_total", 0),
            "content_type": payload.get("content_type", ""),
            "chunk_index": payload.get("chunk_index", -1),
            "total_chunks": payload.get("total_chunks", 0),
            "content": payload.get("content", "")[:500] + "..." if len(payload.get("content", "")) > 500 else payload.get("content", ""),
            "similarity": round(similarity * 100, 2)  # Pourcentage de similarité
        }
        
        results.append(result)
    
    # Afficher les résultats au format JSON
    print(json.dumps(results, indent=2, ensure_ascii=False))

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
        [string]$Query
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $markdown = @"
# Résultats de recherche sémantique

**Requête:** "$Query"
**Date:** $timestamp
**Nombre de résultats:** $($Results.Count)

## Résultats

| Rang | Plan | Version | Progression | Similarité |
|---|---|---|---|---|
"@

    foreach ($result in $Results) {
        $markdown += "`n| **$($result.rank)** | $($result.title) | $($result.version) | $($result.progress)% | $($result.similarity)% |"
    }

    $markdown += @"

## Détails des résultats

"@

    foreach ($result in $Results) {
        $markdown += @"

### $($result.rank). $($result.title) - v$($result.version)

- **Fichier:** $($result.filename)
- **Similarité:** $($result.similarity)%
- **Progression:** $($result.progress)% ($($result.tasks_completed)/$($result.tasks_total) tâches)
- **Type de contenu:** $($result.content_type)

#### Extrait:

```
$($result.content)
```

"@
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
        [string]$Query
    )

    Write-Host "`nRésultats de recherche sémantique pour: '$Query'" -ForegroundColor Cyan
    Write-Host "Nombre de résultats: $($Results.Count)" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor Cyan

    foreach ($result in $Results) {
        Write-Host "Rang: " -NoNewline
        Write-Host "$($result.rank)" -ForegroundColor Yellow -NoNewline
        Write-Host " - Similarité: " -NoNewline
        Write-Host "$($result.similarity)%" -ForegroundColor Green

        Write-Host "Plan: $($result.title) (v$($result.version))"
        Write-Host "Progression: $($result.progress)% ($($result.tasks_completed)/$($result.tasks_total) tâches)"
        Write-Host "Fichier: $($result.filename)"
        
        if ($result.content_type -eq "chunk") {
            Write-Host "Type: Extrait (chunk $($result.chunk_index + 1)/$($result.total_chunks))"
        } else {
            Write-Host "Type: Document complet"
        }
        
        Write-Host "Extrait:"
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host $result.content
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
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

    # Vérifier si Qdrant est accessible
    try {
        $testUrl = "$QdrantUrl/dashboard"
        $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue

        if ($response.StatusCode -eq 200) {
            Write-Log "Qdrant est accessible à l'URL: $QdrantUrl" -Level Success
        } else {
            Write-Log "Qdrant n'est pas accessible à l'URL: $QdrantUrl" -Level Error
            return
        }
    } catch {
        Write-Log "Qdrant n'est pas accessible à l'URL: $QdrantUrl" -Level Error
        Write-Log "Assurez-vous que le conteneur Docker Qdrant est en cours d'exécution." -Level Error
        return
    }

    # Créer le script Python temporaire
    Write-Log "Création du script Python pour la recherche sémantique..." -Level Info
    $pythonScript = New-PlanDevSearchScript -Query $Query -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelEndpoint $ModelEndpoint -ApiKey $ApiKey -ModelName $ModelName -MaxResults $MaxResults -Version $Version -MinProgress $MinProgress -MaxProgress $MaxProgress -FullDocumentsOnly $FullDocumentsOnly

    # Exécuter le script Python et capturer la sortie JSON
    Write-Log "Exécution de la recherche sémantique pour: '$Query'..." -Level Info
    $output = python $pythonScript 2>&1

    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force

    # Extraire les résultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("[")
    $jsonEndIndex = $output.LastIndexOf("]")

    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $results = $jsonString | ConvertFrom-Json

        # Traiter les résultats selon le format demandé
        switch ($OutputFormat) {
            "console" {
                Show-ResultsInConsole -Results $results -Query $Query
            }
            "json" {
                $jsonOutput = @{
                    query     = $Query
                    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    results   = $results
                } | ConvertTo-Json -Depth 10

                if ($OutputPath) {
                    $jsonOutput | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Résultats sauvegardés au format JSON dans $OutputPath" -Level Success
                } else {
                    Write-Output $jsonOutput
                }
            }
            "markdown" {
                $markdownOutput = Format-ResultsAsMarkdown -Results $results -Query $Query

                if ($OutputPath) {
                    $markdownOutput | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Résultats sauvegardés au format Markdown dans $OutputPath" -Level Success
                } else {
                    Write-Output $markdownOutput
                }
            }
        }

        Write-Log "Recherche terminée. $($results.Count) résultats trouvés." -Level Success
    } else {
        Write-Log "Aucun résultat trouvé ou erreur lors de la recherche." -Level Warning
        Write-Log "Sortie du script Python:" -Level Info
        Write-Output $output
    }
}

# Exécuter la fonction principale
Main

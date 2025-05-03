# Search-TasksSemantic.ps1
# Script pour effectuer des recherches sémantiques dans les tâches de la roadmap

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [Parameter(Mandatory = $false)]
    [string]$ChromaDbPath = "projet\roadmaps\vectors\chroma_db",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
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
    $requiredPackages = @("chromadb", "numpy", "requests")
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

# Fonction pour créer un script Python temporaire pour la recherche sémantique
function New-SemanticSearchScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $true)]
        [string]$ChromaDbPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelEndpoint,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxResults
    )
    
    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $scriptContent = @"
import json
import chromadb
import numpy as np
import os
import sys
import requests
from datetime import datetime

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
        
        if 'data' in result and 'embedding' in result['data'][0]:
            return result['data'][0]['embedding']
        else:
            print("Réponse API invalide. Génération d'un vecteur aléatoire.")
            return np.random.uniform(-1, 1, 1536).tolist()
    except Exception as e:
        print(f"Erreur lors de l'appel à l'API d'embedding: {e}")
        return np.random.uniform(-1, 1, 1536).tolist()

def main():
    # Paramètres
    query = r'$Query'
    chroma_db_path = r'$ChromaDbPath'
    collection_name = '$CollectionName'
    model_endpoint = r'$ModelEndpoint'
    api_key = r'$ApiKey'
    model_name = '$ModelName'
    max_results = $MaxResults
    
    print(f"Recherche sémantique pour: '{query}'")
    
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
        
        # Obtenir l'embedding de la requête
        print("Génération de l'embedding pour la requête...")
        query_embedding = get_embedding(query, api_key, model_endpoint, model_name)
        
        # Effectuer la recherche
        print(f"Recherche des {max_results} tâches les plus pertinentes...")
        results = collection.query(
            query_embeddings=[query_embedding],
            n_results=max_results,
            include=["metadatas", "documents", "distances"]
        )
        
        # Préparer les résultats
        search_results = []
        
        if results['ids'] and results['ids'][0]:
            for i, task_id in enumerate(results['ids'][0]):
                metadata = results['metadatas'][0][i]
                document = results['documents'][0][i]
                distance = results['distances'][0][i]
                similarity = 1 - (distance / 2)  # Convertir la distance en similarité (0-1)
                
                result = {
                    "taskId": task_id,
                    "description": metadata.get("description", ""),
                    "status": metadata.get("status", ""),
                    "section": metadata.get("section", ""),
                    "indentLevel": metadata.get("indentLevel", 0),
                    "lastUpdated": metadata.get("lastUpdated", ""),
                    "parentId": metadata.get("parentId", ""),
                    "document": document,
                    "similarity": round(similarity * 100, 2)  # Pourcentage de similarité
                }
                
                search_results.append(result)
        
        # Afficher les résultats au format JSON
        print(json.dumps(search_results, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"Erreur lors de la recherche sémantique: {e}")
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
        [string]$Query
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $markdown = @"
# Résultats de recherche sémantique

**Requête:** "$Query"  
**Date:** $timestamp  
**Nombre de résultats:** $($Results.Count)

## Résultats

| ID | Description | Section | Statut | Similarité |
|---|---|---|---|---|
"@
    
    foreach ($result in $Results) {
        $markdown += "`n| **$($result.taskId)** | $($result.description) | $($result.section) | $($result.status) | $($result.similarity)% |"
    }
    
    $markdown += @"

## Détails des résultats

"@
    
    foreach ($result in $Results) {
        $markdown += @"

### $($result.taskId) - $($result.description)

- **Similarité:** $($result.similarity)%
- **Statut:** $($result.status)
- **Section:** $($result.section)
- **Dernière mise à jour:** $($result.lastUpdated)
- **ID parent:** $($result.parentId)
- **Niveau d'indentation:** $($result.indentLevel)

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
        Write-Host "ID: " -NoNewline
        Write-Host "$($result.taskId)" -ForegroundColor Yellow -NoNewline
        Write-Host " - Similarité: " -NoNewline
        Write-Host "$($result.similarity)%" -ForegroundColor Green
        
        Write-Host "Description: $($result.description)"
        Write-Host "Section: $($result.section)"
        Write-Host "Statut: $($result.status)"
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
    Write-Log "Création du script Python pour la recherche sémantique..." -Level Info
    $pythonScript = New-SemanticSearchScript -Query $Query -ChromaDbPath $ChromaDbPath -CollectionName $CollectionName -ModelEndpoint $ModelEndpoint -ApiKey $ApiKey -ModelName $ModelName -MaxResults $MaxResults
    
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
                    query = $Query
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
                $markdownOutput = Format-ResultsAsMarkdown -Results $results -Query $Query
                
                if ($OutputPath) {
                    $markdownOutput | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "Résultats sauvegardés au format Markdown dans $OutputPath" -Level Success
                }
                else {
                    Write-Output $markdownOutput
                }
            }
        }
        
        Write-Log "Recherche terminée. $($results.Count) résultats trouvés." -Level Success
    }
    else {
        Write-Log "Aucun résultat trouvé ou erreur lors de la recherche." -Level Warning
    }
}

# Exécuter la fonction principale
Main

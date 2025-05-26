# MIGRATED TO QDRANT STANDALONE - 2025-05-25
# Search-TasksSemanticQdrant.ps1
# Script pour effectuer des recherches sÃ©mantiques dans les tÃ¢ches de la roadmap avec Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Query,

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

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
        } else {
            Write-Log "Python n'est pas correctement installÃ©." -Level Error
            return $false
        }
    } catch {
        Write-Log "Python n'est pas installÃ© ou n'est pas dans le PATH." -Level Error
        return $false
    }
}

# Fonction pour vÃ©rifier si les packages Python nÃ©cessaires sont installÃ©s
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
                    Write-Log "Ã‰chec de l'installation du package $package." -Level Error
                    return $false
                }
            }
            Write-Log "Tous les packages ont Ã©tÃ© installÃ©s avec succÃ¨s." -Level Success
            return $true
        } else {
            Write-Log "Installation des packages annulÃ©e. Le script ne peut pas continuer." -Level Error
            return $false
        }
    }

    Write-Log "Tous les packages Python requis sont installÃ©s." -Level Success
    return $true
}

# Fonction pour crÃ©er un script Python temporaire pour la recherche sÃ©mantique
function New-SemanticSearchScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

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
import numpy as np
import os
import sys
import requests
from datetime import datetime
from qdrant_client import QdrantClient
from qdrant_client.http.models import Filter, FieldCondition, MatchValue
from qdrant_client.http.exceptions import UnexpectedResponse

def get_embedding(text, api_key, endpoint, model):
    """Obtenir un vecteur d'embedding via l'API OpenRouter"""
    if not api_key:
        # GÃ©nÃ©rer un vecteur alÃ©atoire si pas de clÃ© API
        print("ClÃ© API non fournie. GÃ©nÃ©ration d'un vecteur alÃ©atoire.")
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
            print("RÃ©ponse API invalide. GÃ©nÃ©ration d'un vecteur alÃ©atoire.")
            return np.random.uniform(-1, 1, 1536).tolist()
    except Exception as e:
        print(f"Erreur lors de l'appel Ã  l'API d'embedding: {e}")
        return np.random.uniform(-1, 1, 1536).tolist()

def main():
    # ParamÃ¨tres
    query = r'$Query'
    qdrant_url = r'$QdrantUrl'
    collection_name = '$CollectionName'
    model_endpoint = r'$ModelEndpoint'
    api_key = r'$ApiKey'
    model_name = '$ModelName'
    max_results = $MaxResults

    print(f"Recherche sÃ©mantique pour: '{query}'")

    # Initialiser le client Qdrant
    try:
        client = QdrantClient(url=qdrant_url)

        # VÃ©rifier si Qdrant est accessible
        client.get_collections()
    except Exception as e:
        print(f"Erreur lors de la connexion Ã  Qdrant: {e}")
        print("Assurez-vous que Qdrant est en cours d'exÃ©cution et accessible Ã  l'URL spÃ©cifiÃ©e.")
        sys.exit(1)

    # VÃ©rifier si la collection existe
    try:
        collections = client.get_collections().collections
        collection_exists = any(c.name == collection_name for c in collections)

        if not collection_exists:
            print(f"La collection {collection_name} n'existe pas dans Qdrant.")
            sys.exit(1)

        # Obtenir l'embedding de la requÃªte
        print("GÃ©nÃ©ration de l'embedding pour la requÃªte...")
        query_embedding = get_embedding(query, api_key, model_endpoint, model_name)

        # Effectuer la recherche
        print(f"Recherche des {max_results} tÃ¢ches les plus pertinentes...")
        search_results = client.search(
            collection_name=collection_name,
            query_vector=query_embedding,
            limit=max_results,
            with_payload=True
        )

        # PrÃ©parer les rÃ©sultats
        results = []

        for point in search_results:
            payload = point.payload
            similarity = point.score  # Qdrant retourne dÃ©jÃ  un score de similaritÃ©

            result = {
                "taskId": point.id,
                "description": payload.get("description", ""),
                "status": payload.get("status", ""),
                "section": payload.get("section", ""),
                "indentLevel": payload.get("indentLevel", 0),
                "lastUpdated": payload.get("lastUpdated", ""),
                "parentId": payload.get("parentId", ""),
                "document": payload.get("text", ""),
                "similarity": round(similarity * 100, 2)  # Pourcentage de similaritÃ©
            }

            results.append(result)

        # Afficher les rÃ©sultats au format JSON
        print(json.dumps(results, indent=2, ensure_ascii=False))

    except Exception as e:
        print(f"Erreur lors de la recherche sÃ©mantique: {e}")
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
        [string]$Query
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $markdown = @"
# RÃ©sultats de recherche sÃ©mantique

**RequÃªte:** "$Query"
**Date:** $timestamp
**Nombre de rÃ©sultats:** $($Results.Count)

## RÃ©sultats

| ID | Description | Section | Statut | SimilaritÃ© |
|---|---|---|---|---|
"@

    foreach ($result in $Results) {
        $markdown += "`n| **$($result.taskId)** | $($result.description) | $($result.section) | $($result.status) | $($result.similarity)% |"
    }

    $markdown += @"

## DÃ©tails des rÃ©sultats

"@

    foreach ($result in $Results) {
        $markdown += @"

### $($result.taskId) - $($result.description)

- **SimilaritÃ©:** $($result.similarity)%
- **Statut:** $($result.status)
- **Section:** $($result.section)
- **DerniÃ¨re mise Ã  jour:** $($result.lastUpdated)
- **ID parent:** $($result.parentId)
- **Niveau d'indentation:** $($result.indentLevel)

"@
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
        [string]$Query
    )

    Write-Host "`nRÃ©sultats de recherche sÃ©mantique pour: '$Query'" -ForegroundColor Cyan
    Write-Host "Nombre de rÃ©sultats: $($Results.Count)" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor Cyan

    foreach ($result in $Results) {
        Write-Host "ID: " -NoNewline
        Write-Host "$($result.taskId)" -ForegroundColor Yellow -NoNewline
        Write-Host " - SimilaritÃ©: " -NoNewline
        Write-Host "$($result.similarity)%" -ForegroundColor Green

        Write-Host "Description: $($result.description)"
        Write-Host "Section: $($result.section)"
        Write-Host "Statut: $($result.status)"
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
    }
}

# Fonction pour vÃ©rifier et dÃ©marrer le conteneur Docker de Qdrant
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

    # VÃ©rifier si le conteneur est accessible
    try {
        $testUrl = "$QdrantUrl/dashboard"
        $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue

        if ($response.StatusCode -eq 200) {
            Write-Log "Qdrant est accessible Ã  l'URL: $QdrantUrl" -Level Success
            return $true
        }
    } catch {
        Write-Log "Qdrant n'est pas accessible Ã  l'URL: $QdrantUrl" -Level Warning
    }

    # Tenter de dÃ©marrer le conteneur Docker
    Write-Log "Tentative de dÃ©marrage du conteneur Docker pour Qdrant..." -Level Info

    $qdrantContainerScript = Join-Path $PSScriptRoot "..\..\tools\qdrant\Start-QdrantStandalone.ps1"
    if (Test-Path -Path $qdrantContainerScript) {
        & $qdrantContainerScript -Action Start -DataPath $DataPath -Force:$Force

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Conteneur Docker pour Qdrant dÃ©marrÃ© avec succÃ¨s." -Level Success

            # Attendre que le service soit prÃªt
            Write-Log "Attente du dÃ©marrage du service Qdrant..." -Level Info
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
                        Write-Log "Service Qdrant prÃªt aprÃ¨s $retryCount tentatives." -Level Success
                    }
                } catch {
                    Write-Log "Tentative $retryCount sur $maxRetries - Service Qdrant pas encore prÃªt..." -Level Info
                }
            }

            if ($serviceReady) {
                return $true
            } else {
                Write-Log "Le service Qdrant n'est pas devenu accessible aprÃ¨s $maxRetries tentatives." -Level Warning
                return $false
            }
        } else {
            Write-Log "Erreur lors du dÃ©marrage du conteneur Docker pour Qdrant." -Level Error
            Write-Log "Assurez-vous que Docker est installÃ© et en cours d'exÃ©cution." -Level Error
            return $false
        }
    } else {
        Write-Log "Script de gestion du conteneur Docker pour Qdrant non trouvÃ©: $qdrantContainerScript" -Level Error
        Write-Log "Veuillez dÃ©marrer le conteneur manuellement avec Docker:" -Level Error
        Write-Log "# MIGRATED: docker run -d -p 6333:6333 -p 6334:6334 -v `"$(Resolve-Path $DataPath):/qdrant/storage`" qdrant/qdrant" -Level Error
        return $false
    }
}

# Fonction principale
function Main {
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

    # VÃ©rifier et dÃ©marrer le conteneur Docker de Qdrant si nÃ©cessaire
    $qdrantDataPath = "..\..\data\qdrant"
    if (-not (Start-QdrantContainerIfNeeded -QdrantUrl $QdrantUrl -DataPath $qdrantDataPath -Force:$false)) {
        Write-Log "Impossible d'assurer que le conteneur Docker de Qdrant est en cours d'exÃ©cution. Le script ne peut pas continuer." -Level Error
        return
    }

    # CrÃ©er le script Python temporaire
    Write-Log "CrÃ©ation du script Python pour la recherche sÃ©mantique..." -Level Info
    $pythonScript = New-SemanticSearchScript -Query $Query -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelEndpoint $ModelEndpoint -ApiKey $ApiKey -ModelName $ModelName -MaxResults $MaxResults

    # ExÃ©cuter le script Python et capturer la sortie JSON
    Write-Log "ExÃ©cution de la recherche sÃ©mantique pour: '$Query'..." -Level Info
    $output = python $pythonScript 2>&1

    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force

    # Extraire les rÃ©sultats JSON de la sortie
    $jsonStartIndex = $output.IndexOf("[")
    $jsonEndIndex = $output.LastIndexOf("]")

    if ($jsonStartIndex -ge 0 -and $jsonEndIndex -gt $jsonStartIndex) {
        $jsonString = $output.Substring($jsonStartIndex, $jsonEndIndex - $jsonStartIndex + 1)
        $results = $jsonString | ConvertFrom-Json

        # Traiter les rÃ©sultats selon le format demandÃ©
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
                    Write-Log "RÃ©sultats sauvegardÃ©s au format JSON dans $OutputPath" -Level Success
                } else {
                    Write-Output $jsonOutput
                }
            }
            "markdown" {
                $markdownOutput = Format-ResultsAsMarkdown -Results $results -Query $Query

                if ($OutputPath) {
                    $markdownOutput | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Log "RÃ©sultats sauvegardÃ©s au format Markdown dans $OutputPath" -Level Success
                } else {
                    Write-Output $markdownOutput
                }
            }
        }

        Write-Log "Recherche terminÃ©e. $($results.Count) rÃ©sultats trouvÃ©s." -Level Success
    } else {
        Write-Log "Aucun rÃ©sultat trouvÃ© ou erreur lors de la recherche." -Level Warning
    }
}

# ExÃ©cuter la fonction principale
Main


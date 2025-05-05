# Search-TasksQdrant.ps1
# Script pour rechercher des tÃ¢ches dans Qdrant par contenu sÃ©mantique
# Version: 1.0
# Date: 2025-05-02

[CmdletBinding()]
param (
    [Parameter()]
    [string]$Query = "",

    [Parameter()]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter()]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter()]
    [int]$Limit = 10,

    [Parameter()]
    [ValidateSet("Completed", "Incomplete", "")]
    [string]$Status,

    [Parameter()]
    [string]$Section,

    [Parameter()]
    [string]$ParentId,

    [Parameter()]
    [int]$IndentLevel,

    [Parameter()]
    [string]$LastUpdated,

    [Parameter()]
    [switch]$Force
)

# Importer les modules communs
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$commonPath = Join-Path -Path $scriptPath -ChildPath "..\common"
$modulePath = Join-Path -Path $commonPath -ChildPath "RoadmapModule.psm1"

if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module commun introuvable: $modulePath"
    exit 1
}

function Test-PythonPackages {
    $requiredPackages = @("requests", "numpy", "openai")
    $missingPackages = @()

    foreach ($package in $requiredPackages) {
        $checkCmd = "python -c 'import $package' 2>&1"
        $result = Invoke-Expression $checkCmd
        if ($LASTEXITCODE -ne 0) {
            $missingPackages += $package
        }
    }

    if ($missingPackages.Count -gt 0) {
        Write-Log "Installation des packages Python manquants: $($missingPackages -join ', ')" -Level Info
        foreach ($package in $missingPackages) {
            python -m pip install $package
        }
    }

    return $true
}

function Test-QdrantConnection {
    param (
        [string]$Url
    )

    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -ErrorAction Stop
        Write-Log "Qdrant est accessible Ã  l'URL: $Url" -Level Success
        return $true
    } catch {
        Write-Log "Impossible de se connecter Ã  Qdrant Ã  l'URL: $Url" -Level Error
        Write-Log "Erreur: $_" -Level Error
        return $false
    }
}

function Get-PythonSearchScript {
    param (
        [string]$Query,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [int]$Limit,
        [string]$Status,
        [string]$Section,
        [string]$ParentId,
        [int]$IndentLevel,
        [string]$LastUpdated,
        [bool]$Force
    )

    $pythonScript = @"
import os
import sys
import json
import requests
import numpy as np
from datetime import datetime

# Configuration
qdrant_url = r'$QdrantUrl'
collection_name = '$CollectionName'
query = r'$Query'
limit = $Limit
status_filter = r'$Status'
section_filter = r'$Section'
parent_id_filter = r'$ParentId'
indent_level_filter = $($IndentLevel -gt 0 ? $IndentLevel.ToString() : "None")
last_updated_filter = r'$LastUpdated'
force = $($Force.ToString().ToLower() -replace "true", "True" -replace "false", "False")

# Fonction pour gÃ©nÃ©rer un embedding Ã  partir du texte
def generate_embedding(text):
    try:
        # Essayer d'utiliser OpenAI pour gÃ©nÃ©rer un embedding
        import openai

        # VÃ©rifier si la clÃ© API est dÃ©finie
        api_key = os.environ.get('OPENROUTER_API_KEY')
        if not api_key:
            print("ClÃ© API OpenRouter non trouvÃ©e dans les variables d'environnement.")
            print("Tentative de rÃ©cupÃ©ration depuis le fichier de credentials...")

            # Essayer de rÃ©cupÃ©rer la clÃ© depuis le fichier de credentials
            credentials_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
                                          "tools", "security", "credentials.json")
            if os.path.exists(credentials_file):
                try:
                    import json
                    with open(credentials_file, 'r') as f:
                        credentials = json.load(f)
                    if 'OPENROUTER_API_KEY' in credentials:
                        api_key = credentials['OPENROUTER_API_KEY']
                        print("ClÃ© API OpenRouter rÃ©cupÃ©rÃ©e depuis le fichier de credentials.")
                except Exception as e:
                    print(f"Erreur lors de la lecture du fichier de credentials: {str(e)}")

            if not api_key:
                print("ClÃ© API OpenRouter non trouvÃ©e. Utilisation d'un embedding alÃ©atoire.")
                return generate_random_embedding()

        # Configurer le client OpenAI avec OpenRouter
        client = openai.OpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=api_key
        )

        # GÃ©nÃ©rer l'embedding
        response = client.embeddings.create(
            model="qwen/qwen1.5-7b-chat",
            input=text
        )

        # Extraire le vecteur d'embedding
        embedding = response.data[0].embedding
        return embedding

    except Exception as e:
        print(f"Erreur lors de la gÃ©nÃ©ration de l'embedding: {str(e)}")
        print("Utilisation d'un embedding alÃ©atoire Ã  la place.")
        return generate_random_embedding()

# Fonction pour gÃ©nÃ©rer un embedding alÃ©atoire (fallback)
def generate_random_embedding(dimension=1536):
    # GÃ©nÃ©rer un vecteur alÃ©atoire
    random_vector = np.random.rand(dimension)
    # Normaliser le vecteur
    normalized_vector = random_vector / np.linalg.norm(random_vector)
    return normalized_vector.tolist()

# Fonction pour rechercher des tÃ¢ches similaires dans Qdrant
def search_tasks():
    try:
        # VÃ©rifier si Qdrant est accessible
        try:
            response = requests.get(f"{qdrant_url}/collections")
            if response.status_code != 200:
                print(f"Erreur lors de la connexion Ã  Qdrant: {response.status_code}")
                return
        except Exception as e:
            print(f"Erreur lors de la connexion Ã  Qdrant: {str(e)}")
            return

        # VÃ©rifier si la collection existe
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"La collection {collection_name} n'existe pas dans Qdrant.")
            return

        # GÃ©nÃ©rer l'embedding pour la requÃªte
        query_embedding = generate_embedding(query)

        # PrÃ©parer les filtres
        filter_conditions = []

        if status_filter:
            filter_conditions.append({
                "key": "status",
                "match": {"value": status_filter}
            })

        if section_filter:
            filter_conditions.append({
                "key": "section",
                "match": {"value": section_filter}
            })

        if parent_id_filter:
            filter_conditions.append({
                "key": "parentId",
                "match": {"value": parent_id_filter}
            })

        if indent_level_filter != "None":
            try:
                indent_level_value = int(indent_level_filter)
                filter_conditions.append({
                    "key": "indentLevel",
                    "match": {"value": indent_level_value}
                })
            except (ValueError, TypeError):
                print(f"Avertissement: Niveau d'indentation invalide: {indent_level_filter}")

        if last_updated_filter:
            filter_conditions.append({
                "key": "lastUpdated",
                "match": {"value": last_updated_filter}
            })

        # Construire la requÃªte de recherche
        search_request = {
            "vector": query_embedding,
            "limit": limit,
            "with_payload": True
        }

        # Ajouter les filtres si nÃ©cessaire
        if filter_conditions:
            search_request["filter"] = {
                "must": filter_conditions
            }

        # Effectuer la recherche
        response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/search",
            json=search_request
        )

        if response.status_code != 200:
            print(f"Erreur lors de la recherche: {response.status_code}")
            print(response.text)
            return

        # Traiter les rÃ©sultats
        results = response.json()

        # Afficher les rÃ©sultats
        print(f"RÃ©sultats de recherche pour: '{query}'")
        print(f"Nombre de rÃ©sultats: {len(results['result'])}")
        print("-" * 80)

        for i, result in enumerate(results['result']):
            print(f"{i+1}. Score: {result['score']:.4f}")
            if 'payload' in result:
                print(f"   ID: {result['payload'].get('originalId', 'N/A')}")
                print(f"   Description: {result['payload'].get('description', 'N/A')}")
                print(f"   Section: {result['payload'].get('section', 'N/A')}")
                print(f"   Status: {result['payload'].get('status', 'N/A')}")
            else:
                print(f"   Pas de payload disponible pour ce rÃ©sultat")
            print("-" * 80)

        return results

    except Exception as e:
        print(f"Erreur lors de la recherche des tÃ¢ches: {str(e)}")
        return None

if __name__ == "__main__":
    if not query:
        print("Veuillez spÃ©cifier une requÃªte de recherche avec le paramÃ¨tre -Query.")
        sys.exit(1)

    print(f"Recherche de tÃ¢ches similaires Ã : '{query}'")

    # Afficher les filtres actifs
    active_filters = []
    if status_filter:
        active_filters.append(f"Statut: {status_filter}")
    if section_filter:
        active_filters.append(f"Section: {section_filter}")
    if parent_id_filter:
        active_filters.append(f"Parent ID: {parent_id_filter}")
    if indent_level_filter != "None":
        active_filters.append(f"Niveau d'indentation: {indent_level_filter}")
    if last_updated_filter:
        active_filters.append(f"Date de mise Ã  jour: {last_updated_filter}")

    if active_filters:
        print("Filtres actifs:")
        for filter_info in active_filters:
            print(f"- {filter_info}")

    search_tasks()
"@

    return $pythonScript
}

# Fonction principale
function Invoke-TaskSearch {
    # VÃ©rifier la version de Python
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
        Write-Log "Python $($matches[1]) dÃ©tectÃ©." -Level Info
    } else {
        Write-Log "Python non dÃ©tectÃ©. Veuillez installer Python 3.6 ou supÃ©rieur." -Level Error
        return
    }

    # VÃ©rifier les packages Python requis
    if (-not (Test-PythonPackages)) {
        Write-Log "Impossible d'installer les packages Python requis." -Level Error
        return
    }

    # VÃ©rifier la connexion Ã  Qdrant
    if (-not (Test-QdrantConnection -Url $QdrantUrl)) {
        return
    }

    # Essayer de rÃ©cupÃ©rer la clÃ© API OpenRouter depuis le gestionnaire de credentials
    $credentialManagerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\tools\security\credential-manager.ps1"
    if (Test-Path -Path $credentialManagerPath) {
        try {
            # Importer le module de gestion des credentials
            . $credentialManagerPath

            # RÃ©cupÃ©rer la clÃ© API
            $apiKey = Get-SecureCredential -Name "OPENROUTER_API_KEY"

            if ($apiKey) {
                Write-Log "ClÃ© API OpenRouter rÃ©cupÃ©rÃ©e depuis le gestionnaire de credentials." -Level Info
                # DÃ©finir la variable d'environnement pour le script Python
                [Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $apiKey, "Process")
            } else {
                Write-Log "ClÃ© API OpenRouter non trouvÃ©e dans le gestionnaire de credentials." -Level Warning
            }
        } catch {
            Write-Log "Erreur lors de la rÃ©cupÃ©ration de la clÃ© API OpenRouter: $_" -Level Warning
        }
    } else {
        Write-Log "Gestionnaire de credentials non trouvÃ© Ã  l'emplacement: $credentialManagerPath" -Level Warning
    }

    # CrÃ©er le script Python pour la recherche
    Write-Log "CrÃ©ation du script Python pour la recherche de tÃ¢ches..." -Level Info
    $pythonScript = Get-PythonSearchScript -Query $Query -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Limit $Limit -Status $Status -Section $Section -ParentId $ParentId -IndentLevel $IndentLevel -LastUpdated $LastUpdated -Force $Force

    # ExÃ©cuter le script Python
    Write-Log "ExÃ©cution du script Python pour la recherche de tÃ¢ches..." -Level Info
    $pythonScript | python -

    Write-Log "OpÃ©ration terminÃ©e." -Level Success
}

# ExÃ©cuter la fonction principale
Invoke-TaskSearch

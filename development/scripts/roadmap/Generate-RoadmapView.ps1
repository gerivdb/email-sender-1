# Generate-RoadmapView.ps1
# Script pour générer des vues dynamiques de la roadmap à partir des données stockées dans Qdrant
# Version: 1.0
# Date: 2025-05-02

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("ActiveRoadmap", "RecentlyCompleted", "NextPriorities")]
    [string]$ViewType = "ActiveRoadmap",

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter()]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter()]
    [int]$Limit = 100,

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

function Test-QdrantConnection {
    param (
        [string]$Url
    )

    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -ErrorAction Stop
        Write-Log "Qdrant est accessible à l'URL: $Url" -Level Success
        return $true
    } catch {
        Write-Log "Impossible de se connecter à Qdrant à l'URL: $Url" -Level Error
        Write-Log "Erreur: $_" -Level Error
        return $false
    }
}

function Get-PythonGenerateViewScript {
    param (
        [string]$ViewType,
        [string]$OutputPath,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [int]$Limit,
        [bool]$Force
    )

    $pythonScript = @"
import os
import sys
import json
import requests
from datetime import datetime, timedelta

# Configuration
view_type = '$ViewType'
output_path = r'$OutputPath'
qdrant_url = r'$QdrantUrl'
collection_name = '$CollectionName'
limit = $Limit
force = $($Force.ToString().ToLower() -replace "true", "True" -replace "false", "False")

# Fonction pour générer une vue de la roadmap
def generate_roadmap_view():
    try:
        # Vérifier si Qdrant est accessible
        try:
            response = requests.get(f"{qdrant_url}/collections")
            if response.status_code != 200:
                print(f"Erreur lors de la connexion à Qdrant: {response.status_code}")
                return False
        except Exception as e:
            print(f"Erreur lors de la connexion à Qdrant: {str(e)}")
            return False

        # Vérifier si la collection existe
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"La collection {collection_name} n'existe pas dans Qdrant.")
            return False

        # Préparer les filtres en fonction du type de vue
        filter_conditions = []

        if view_type == "ActiveRoadmap":
            # Vue de la roadmap active (tâches non terminées)
            filter_conditions.append({
                "key": "status",
                "match": {"value": "Incomplete"}
            })
        elif view_type == "RecentlyCompleted":
            # Vue des tâches récemment terminées (dans les 7 derniers jours)
            seven_days_ago = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
            filter_conditions.append({
                "key": "status",
                "match": {"value": "Completed"}
            })
            filter_conditions.append({
                "key": "lastUpdated",
                "range": {
                    "gte": seven_days_ago
                }
            })
        elif view_type == "NextPriorities":
            # Vue des prochaines tâches prioritaires (non terminées)
            # Pour l'instant, on se contente des tâches non terminées
            # car nous n'avons pas encore implémenté la priorité
            filter_conditions.append({
                "key": "status",
                "match": {"value": "Incomplete"}
            })

        # Construire la requête de recherche
        search_request = {
            "filter": {
                "must": filter_conditions
            },
            "limit": limit,
            "with_payload": True,
            "with_vector": False
        }

        # Effectuer la recherche
        response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json=search_request
        )

        if response.status_code != 200:
            print(f"Erreur lors de la recherche: {response.status_code}")
            print(response.text)
            return False

        # Traiter les résultats
        results = response.json()

        if not results['result']['points']:
            print(f"Aucune tâche trouvée pour la vue '{view_type}'.")
            return False

        # Extraire les tâches
        tasks = []
        for point in results['result']['points']:
            if 'payload' in point:
                task = {
                    'id': point['payload'].get('originalId', 'N/A'),
                    'description': point['payload'].get('description', 'N/A'),
                    'status': point['payload'].get('status', 'N/A'),
                    'level': point['payload'].get('indentLevel', 0),
                    'section': point['payload'].get('section', 'N/A'),
                    'lastUpdated': point['payload'].get('lastUpdated', 'N/A')
                }
                tasks.append(task)

        # Trier les tâches par ID
        tasks.sort(key=lambda x: x['id'])

        # Générer le contenu Markdown
        markdown_content = f"# {view_type} - Générée le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"

        for task in tasks:
            checkbox = "x" if task['status'] == "Completed" else " "
            indent = "  " * task['level']
            markdown_content += f"{indent}- [{checkbox}] **{task['id']}** {task['description']}\n"

        # Écrire le contenu dans le fichier de sortie
        if output_path:
            os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(markdown_content)
            print(f"Vue '{view_type}' générée avec succès et enregistrée dans: {output_path}")
        else:
            print(markdown_content)

        return True

    except Exception as e:
        print(f"Erreur lors de la génération de la vue: {str(e)}")
        return False

if __name__ == "__main__":
    print(f"Génération de la vue '{view_type}'...")

    if generate_roadmap_view():
        print("Génération de la vue réussie.")
        sys.exit(0)
    else:
        print("Échec de la génération de la vue.")
        sys.exit(1)
"@

    return $pythonScript
}

function Invoke-GenerateView {
    # Vérifier la connexion à Qdrant
    if (-not (Test-QdrantConnection -Url $QdrantUrl)) {
        return
    }

    # Définir le chemin de sortie par défaut si non spécifié
    if (-not $OutputPath) {
        $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\projet\roadmaps\views\$ViewType.md"
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Créer le script Python pour la génération de la vue
    Write-Log "Création du script Python pour la génération de la vue '$ViewType'..." -Level Info
    $pythonScript = Get-PythonGenerateViewScript -ViewType $ViewType -OutputPath $OutputPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Limit $Limit -Force $Force

    # Créer un fichier temporaire pour le script Python
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8

    # Exécuter le script Python
    Write-Log "Exécution du script Python pour la génération de la vue '$ViewType'..." -Level Info
    $output = python $tempFile 2>&1
    $exitCode = $LASTEXITCODE

    # Supprimer le fichier temporaire
    Remove-Item -Path $tempFile -Force

    # Vérifier le résultat
    if ($exitCode -eq 0) {
        Write-Log "Génération de la vue '$ViewType' réussie." -Level Success
        Write-Log "Vue enregistrée dans: $OutputPath" -Level Info

        # Afficher un aperçu de la vue générée
        if (Test-Path -Path $OutputPath) {
            Write-Log "Aperçu de la vue générée:" -Level Info
            Get-Content -Path $OutputPath -TotalCount 20 | ForEach-Object { Write-Host $_ }

            if ((Get-Content -Path $OutputPath | Measure-Object -Line).Lines -gt 20) {
                Write-Host "..."
            }
        }

        return $true
    } else {
        Write-Log "Échec de la génération de la vue '$ViewType'." -Level Error
        Write-Log "Sortie: $output" -Level Error
        return $false
    }
}

# Exécuter la fonction principale
Invoke-GenerateView

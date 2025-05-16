# Generate-RoadmapView.ps1
# Script pour gÃ©nÃ©rer des vues dynamiques de la roadmap Ã  partir des donnÃ©es stockÃ©es dans Qdrant
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
        Write-Log "Qdrant est accessible Ã  l'URL: $Url" -Level Success
        return $true
    } catch {
        Write-Log "Impossible de se connecter Ã  Qdrant Ã  l'URL: $Url" -Level Error
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

# Fonction pour gÃ©nÃ©rer une vue de la roadmap
def generate_roadmap_view():
    try:
        # VÃ©rifier si Qdrant est accessible
        try:
            response = requests.get(f"{qdrant_url}/collections")
            if response.status_code != 200:
                print(f"Erreur lors de la connexion Ã  Qdrant: {response.status_code}")
                return False
        except Exception as e:
            print(f"Erreur lors de la connexion Ã  Qdrant: {str(e)}")
            return False

        # VÃ©rifier si la collection existe
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"La collection {collection_name} n'existe pas dans Qdrant.")
            return False

        # PrÃ©parer les filtres en fonction du type de vue
        filter_conditions = []

        if view_type == "ActiveRoadmap":
            # Vue de la roadmap active (tÃ¢ches non terminÃ©es)
            filter_conditions.append({
                "key": "status",
                "match": {"value": "Incomplete"}
            })
        elif view_type == "RecentlyCompleted":
            # Vue des tÃ¢ches rÃ©cemment terminÃ©es (dans les 7 derniers jours)
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
            # Vue des prochaines tÃ¢ches prioritaires (non terminÃ©es)
            # Pour l'instant, on se contente des tÃ¢ches non terminÃ©es
            # car nous n'avons pas encore implÃ©mentÃ© la prioritÃ©
            filter_conditions.append({
                "key": "status",
                "match": {"value": "Incomplete"}
            })

        # Construire la requÃªte de recherche
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

        # Traiter les rÃ©sultats
        results = response.json()

        if not results['result']['points']:
            print(f"Aucune tÃ¢che trouvÃ©e pour la vue '{view_type}'.")
            return False

        # Extraire les tÃ¢ches
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

        # Trier les tÃ¢ches par ID
        tasks.sort(key=lambda x: x['id'])

        # GÃ©nÃ©rer le contenu Markdown
        markdown_content = f"# {view_type} - GÃ©nÃ©rÃ©e le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"

        for task in tasks:
            checkbox = "x" if task['status'] == "Completed" else " "
            indent = "  " * task['level']
            markdown_content += f"{indent}- [{checkbox}] **{task['id']}** {task['description']}\n"

        # Ã‰crire le contenu dans le fichier de sortie
        if output_path:
            os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(markdown_content)
            print(f"Vue '{view_type}' gÃ©nÃ©rÃ©e avec succÃ¨s et enregistrÃ©e dans: {output_path}")
        else:
            print(markdown_content)

        return True

    except Exception as e:
        print(f"Erreur lors de la gÃ©nÃ©ration de la vue: {str(e)}")
        return False

if __name__ == "__main__":
    print(f"GÃ©nÃ©ration de la vue '{view_type}'...")

    if generate_roadmap_view():
        print("GÃ©nÃ©ration de la vue rÃ©ussie.")
        sys.exit(0)
    else:
        print("Ã‰chec de la gÃ©nÃ©ration de la vue.")
        sys.exit(1)
"@

    return $pythonScript
}

function Invoke-GenerateView {
    # VÃ©rifier la connexion Ã  Qdrant
    if (-not (Test-QdrantConnection -Url $QdrantUrl)) {
        return
    }

    # DÃ©finir le chemin de sortie par dÃ©faut si non spÃ©cifiÃ©
    if (-not $OutputPath) {
        $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\projet\roadmaps\views\$ViewType.md"
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er le script Python pour la gÃ©nÃ©ration de la vue
    Write-Log "CrÃ©ation du script Python pour la gÃ©nÃ©ration de la vue '$ViewType'..." -Level Info
    $pythonScript = Get-PythonGenerateViewScript -ViewType $ViewType -OutputPath $OutputPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Limit $Limit -Force $Force

    # CrÃ©er un fichier temporaire pour le script Python
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8

    # ExÃ©cuter le script Python
    Write-Log "ExÃ©cution du script Python pour la gÃ©nÃ©ration de la vue '$ViewType'..." -Level Info
    $output = python $tempFile 2>&1
    $exitCode = $LASTEXITCODE

    # Supprimer le fichier temporaire
    Remove-Item -Path $tempFile -Force

    # VÃ©rifier le rÃ©sultat
    if ($exitCode -eq 0) {
        Write-Log "GÃ©nÃ©ration de la vue '$ViewType' rÃ©ussie." -Level Success
        Write-Log "Vue enregistrÃ©e dans: $OutputPath" -Level Info

        # Afficher un aperÃ§u de la vue gÃ©nÃ©rÃ©e
        if (Test-Path -Path $OutputPath) {
            Write-Log "AperÃ§u de la vue gÃ©nÃ©rÃ©e:" -Level Info
            Get-Content -Path $OutputPath -TotalCount 20 | ForEach-Object { Write-Host $_ }

            if ((Get-Content -Path $OutputPath | Measure-Object -Line).Lines -gt 20) {
                Write-Host "..."
            }
        }

        return $true
    } else {
        Write-Log "Ã‰chec de la gÃ©nÃ©ration de la vue '$ViewType'." -Level Error
        Write-Log "Sortie: $output" -Level Error
        return $false
    }
}

# ExÃ©cuter la fonction principale
Invoke-GenerateView

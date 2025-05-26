# MIGRATED TO QDRANT STANDALONE - 2025-05-25
# Index-TaskVectorsQdrant.ps1
# Script pour indexer les vecteurs de tÃ¢ches par identifiant, statut, date, etc. dans Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter(Mandatory = $false)]
    [string]$IndexOutputPath = "projet\roadmaps\vectors\task_indexes.json",

    [Parameter(Mandatory = $false)]
    [switch]$Force
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
    $requiredPackages = @("qdrant_client", "json", "datetime")
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

# Fonction pour crÃ©er un script Python temporaire pour indexer les vecteurs
function New-TaskIndexScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [string]$IndexOutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $scriptPath = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $scriptContent = @"
import json
import os
import sys
from datetime import datetime
from collections import defaultdict
from qdrant_client import QdrantClient
from qdrant_client.http.exceptions import UnexpectedResponse

def main():
    # ParamÃ¨tres
    qdrant_url = r'$QdrantUrl'
    collection_name = '$CollectionName'
    index_output_path = r'$IndexOutputPath'
    force = $($Force.ToString().ToLower() -replace "true", "True" -replace "false", "False")

    # VÃ©rifier si le fichier d'index existe dÃ©jÃ 
    if os.path.exists(index_output_path) and not force:
        print(f"Le fichier d'index {index_output_path} existe dÃ©jÃ . Utilisez -Force pour l'Ã©craser.")
        sys.exit(0)

    # CrÃ©er le dossier de sortie s'il n'existe pas
    os.makedirs(os.path.dirname(index_output_path), exist_ok=True)

    # Initialiser le client Qdrant
    print(f"Connexion Ã  Qdrant sur {qdrant_url}...")
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

        # RÃ©cupÃ©rer toutes les tÃ¢ches
        print("RÃ©cupÃ©ration des donnÃ©es de la collection...")

        # RÃ©cupÃ©rer les informations sur la collection
        collection_info = client.get_collection(collection_name=collection_name)
        total_points = collection_info.vectors_count

        if total_points == 0:
            print("La collection est vide.")
            sys.exit(0)

        # RÃ©cupÃ©rer tous les points (tÃ¢ches)
        scroll_result = client.scroll(
            collection_name=collection_name,
            limit=total_points,
            with_payload=True,
            with_vectors=False
        )

        points = scroll_result[0]

        if not points:
            print("Aucune tÃ¢che trouvÃ©e dans la collection.")
            sys.exit(0)

        # CrÃ©er les index
        print("CrÃ©ation des index...")

        # Index par ID
        id_index = {point.id: i for i, point in enumerate(points)}

        # Index par statut
        status_index = defaultdict(list)
        for point in points:
            status = point.payload.get('status', 'Unknown')
            status_index[status].append(point.id)

        # Index par section
        section_index = defaultdict(list)
        for point in points:
            section = point.payload.get('section', 'Unknown')
            section_index[section].append(point.id)

        # Index par niveau d'indentation
        indent_index = defaultdict(list)
        for point in points:
            indent = point.payload.get('indentLevel', 0)
            indent_index[str(indent)].append(point.id)

        # Index par date de mise Ã  jour
        date_index = defaultdict(list)
        for point in points:
            date = point.payload.get('lastUpdated', 'Unknown')
            date_index[date].append(point.id)

        # Index par ID parent
        parent_index = defaultdict(list)
        for point in points:
            parent = point.payload.get('parentId', '')
            if parent:  # Ne pas indexer les tÃ¢ches sans parent
                parent_index[parent].append(point.id)

        # CrÃ©er l'objet d'index complet
        indexes = {
            'metadata': {
                'created': datetime.now().isoformat(),
                'collection': collection_name,
                'taskCount': len(points)
            },
            'indexes': {
                'byId': id_index,
                'byStatus': dict(status_index),
                'bySection': dict(section_index),
                'byIndentLevel': dict(indent_index),
                'byDate': dict(date_index),
                'byParentId': dict(parent_index)
            }
        }

        # Sauvegarder les index dans un fichier JSON
        print(f"Sauvegarde des index dans {index_output_path}...")
        with open(index_output_path, 'w', encoding='utf-8') as f:
            json.dump(indexes, f, indent=2, ensure_ascii=False)

        print(f"Indexation terminÃ©e. Les index ont Ã©tÃ© sauvegardÃ©s dans {index_output_path}.")
        print(f"Statistiques des index:")
        print(f"  - Nombre total de tÃ¢ches: {len(points)}")
        print(f"  - Nombre de statuts diffÃ©rents: {len(status_index)}")
        print(f"  - Nombre de sections diffÃ©rentes: {len(section_index)}")
        print(f"  - Nombre de niveaux d'indentation: {len(indent_index)}")
        print(f"  - Nombre de dates de mise Ã  jour: {len(date_index)}")
        print(f"  - Nombre de tÃ¢ches avec parent: {sum(len(tasks) for tasks in parent_index.values())}")

    except Exception as e:
        print(f"Erreur lors de l'indexation des tÃ¢ches: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
"@

    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    return $scriptPath
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
    # VÃ©rifier si le fichier d'index existe dÃ©jÃ 
    if ((Test-Path -Path $IndexOutputPath) -and -not $Force) {
        Write-Log "Le fichier d'index $IndexOutputPath existe dÃ©jÃ . Utilisez -Force pour l'Ã©craser." -Level Warning
        return
    }

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
    $qdrantDataPath = Join-Path -Path (Split-Path -Parent $IndexOutputPath) -ChildPath "qdrant_data"
    if (-not (Start-QdrantContainerIfNeeded -QdrantUrl $QdrantUrl -DataPath $qdrantDataPath -Force:$Force)) {
        Write-Log "Impossible d'assurer que le conteneur Docker de Qdrant est en cours d'exÃ©cution. Le script ne peut pas continuer." -Level Error
        return
    }

    # CrÃ©er le script Python temporaire
    Write-Log "CrÃ©ation du script Python pour l'indexation des tÃ¢ches..." -Level Info
    $pythonScript = New-TaskIndexScript -QdrantUrl $QdrantUrl -CollectionName $CollectionName -IndexOutputPath $IndexOutputPath -Force:$Force

    # ExÃ©cuter le script Python
    Write-Log "ExÃ©cution du script Python pour l'indexation des tÃ¢ches..." -Level Info
    python $pythonScript

    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force

    Write-Log "OpÃ©ration terminÃ©e." -Level Success
}

# ExÃ©cuter la fonction principale
Main


# Test-TagsQdrantIntegration.ps1
# Script de test pour l'intégration du système de tags avec Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Index", "Search", "All")]
    [string]$TestType = "All",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "..\config\tag-formats\TagFormats.config.json",

    [Parameter(Mandatory = $false)]
    [string]$RoadmapsPath = "..\..\..\..\..\..\projet\roadmaps\plans",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tags_test",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$metadataDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "metadata"
$utilsDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "utils"

# Importer les modules
. (Join-Path -Path $utilsDir -ChildPath "Write-Log.ps1")
. (Join-Path -Path $metadataDir -ChildPath "Index-TagsInQdrant.ps1")
. (Join-Path -Path $metadataDir -ChildPath "Search-TasksByTags.ps1")

# Fonction pour tester l'indexation des tags
function Test-IndexTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapsPath,

        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-Log "Test d'indexation des tags dans Qdrant" -Level Info

    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Le fichier de configuration n'existe pas: $ConfigPath" -Level Error
        return $false
    }

    # Vérifier si le dossier des roadmaps existe
    if (-not (Test-Path -Path $RoadmapsPath -PathType Container)) {
        Write-Log "Le dossier des roadmaps n'existe pas: $RoadmapsPath" -Level Error
        return $false
    }

    # Exécuter l'indexation des tags
    & $metadataDir\Index-TagsInQdrant.ps1 -ConfigPath $ConfigPath -RoadmapsPath $RoadmapsPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Force:$Force

    # Vérifier si l'indexation a réussi
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Get

        if ($response.result.status -eq "green") {
            Write-Log "Indexation des tags réussie" -Level Success
            return $true
        } else {
            Write-Log "Indexation des tags échouée: $($response.result.status)" -Level Error
            return $false
        }
    } catch {
        Write-Log "Erreur lors de la vérification de l'indexation des tags: $_" -Level Error
        return $false
    }
}

# Fonction pour tester la recherche de tâches par tags
function Test-SearchTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    Write-Log "Test de recherche de tâches par tags dans Qdrant" -Level Info

    # Vérifier si la collection existe
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Get

        if ($response.result.status -ne "green") {
            Write-Log "La collection n'est pas prête: $($response.result.status)" -Level Error
            return $false
        }
    } catch {
        Write-Log "Erreur lors de la vérification de la collection: $_" -Level Error
        return $false
    }

    # Exécuter la recherche de tâches
    $queries = @(
        "Tâches liées à l'intégration avec Qdrant",
        "Tâches prioritaires",
        "Tâches avec une estimation de temps élevée",
        "Tâches liées à la visualisation"
    )

    $success = $true

    foreach ($query in $queries) {
        Write-Log "Recherche de tâches pour la requête: $query" -Level Info

        try {
            & $metadataDir\Search-TasksByTags.ps1 -Query $query -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Limit 5 -OutputFormat "Table"
        } catch {
            Write-Log "Erreur lors de la recherche de tâches: $_" -Level Error
            $success = $false
        }
    }

    if ($success) {
        Write-Log "Recherche de tâches réussie" -Level Success
    } else {
        Write-Log "Recherche de tâches échouée" -Level Error
    }

    return $success
}

# Fonction principale
function Main {
    Write-Log "Début des tests d'intégration du système de tags avec Qdrant" -Level Info

    $success = $true

    # Tester l'indexation des tags
    if ($TestType -eq "Index" -or $TestType -eq "All") {
        $indexSuccess = Test-IndexTags -ConfigPath $ConfigPath -RoadmapsPath $RoadmapsPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Force:$Force

        if (-not $indexSuccess) {
            $success = $false
        }
    }

    # Tester la recherche de tâches par tags
    if ($TestType -eq "Search" -or $TestType -eq "All") {
        $searchSuccess = Test-SearchTasks -QdrantUrl $QdrantUrl -CollectionName $CollectionName

        if (-not $searchSuccess) {
            $success = $false
        }
    }

    # Afficher le résultat final
    if ($success) {
        Write-Log "Tous les tests ont réussi" -Level Success
    } else {
        Write-Log "Certains tests ont échoué" -Level Error
    }

    return $success
}

# Exécuter la fonction principale
Main

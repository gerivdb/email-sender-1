# Mock-QdrantService.ps1
# Script pour simuler le service Qdrant pour les tests
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Start", "Stop", "Status")]
    [string]$Action = "Start",
    
    [Parameter(Mandatory = $false)]
    [string]$MockDataPath = "projet/roadmaps/analysis/test/mock_data",
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 6333,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour créer le répertoire de données simulées
function New-MockDataDirectory {
    param (
        [string]$MockDataPath
    )
    
    if (-not (Test-Path -Path $MockDataPath)) {
        New-Item -Path $MockDataPath -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire de données simulées créé: $MockDataPath" -Level "Success"
    }
    
    # Créer les sous-répertoires
    $collectionsPath = Join-Path -Path $MockDataPath -ChildPath "collections"
    if (-not (Test-Path -Path $collectionsPath)) {
        New-Item -Path $collectionsPath -ItemType Directory -Force | Out-Null
    }
    
    $pointsPath = Join-Path -Path $MockDataPath -ChildPath "points"
    if (-not (Test-Path -Path $pointsPath)) {
        New-Item -Path $pointsPath -ItemType Directory -Force | Out-Null
    }
    
    $versionsPath = Join-Path -Path $MockDataPath -ChildPath "versions"
    if (-not (Test-Path -Path $versionsPath)) {
        New-Item -Path $versionsPath -ItemType Directory -Force | Out-Null
    }
    
    $snapshotsPath = Join-Path -Path $MockDataPath -ChildPath "snapshots"
    if (-not (Test-Path -Path $snapshotsPath)) {
        New-Item -Path $snapshotsPath -ItemType Directory -Force | Out-Null
    }
    
    return $true
}

# Fonction pour créer une collection simulée
function New-MockCollection {
    param (
        [string]$MockDataPath,
        [string]$CollectionName,
        [int]$VectorSize = 384,
        [string]$Distance = "Cosine"
    )
    
    $collectionsPath = Join-Path -Path $MockDataPath -ChildPath "collections"
    $collectionPath = Join-Path -Path $collectionsPath -ChildPath "$CollectionName.json"
    
    $collection = @{
        name = $CollectionName
        config = @{
            params = @{
                vectors = @{
                    size = $VectorSize
                    distance = $Distance
                }
            }
        }
        vectors_count = 0
        created_at = (Get-Date).ToString("o")
    }
    
    $collection | ConvertTo-Json -Depth 10 | Set-Content -Path $collectionPath -Encoding UTF8
    
    # Créer le répertoire pour les points de cette collection
    $pointsPath = Join-Path -Path $MockDataPath -ChildPath "points\$CollectionName"
    if (-not (Test-Path -Path $pointsPath)) {
        New-Item -Path $pointsPath -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "Collection simulée créée: $CollectionName" -Level "Success"
    return $true
}

# Fonction pour ajouter des points à une collection simulée
function Add-MockPoints {
    param (
        [string]$MockDataPath,
        [string]$CollectionName,
        [array]$Points
    )
    
    $collectionsPath = Join-Path -Path $MockDataPath -ChildPath "collections"
    $collectionPath = Join-Path -Path $collectionsPath -ChildPath "$CollectionName.json"
    
    if (-not (Test-Path -Path $collectionPath)) {
        Write-Log "La collection $CollectionName n'existe pas." -Level "Error"
        return $false
    }
    
    $collection = Get-Content -Path $collectionPath -Raw | ConvertFrom-Json
    
    $pointsPath = Join-Path -Path $MockDataPath -ChildPath "points\$CollectionName"
    
    foreach ($point in $Points) {
        $pointId = $point.id
        $pointPath = Join-Path -Path $pointsPath -ChildPath "$pointId.json"
        
        $point | ConvertTo-Json -Depth 10 | Set-Content -Path $pointPath -Encoding UTF8
    }
    
    # Mettre à jour le nombre de points dans la collection
    $collection.vectors_count += $Points.Count
    $collection | ConvertTo-Json -Depth 10 | Set-Content -Path $collectionPath -Encoding UTF8
    
    Write-Log "$($Points.Count) points ajoutés à la collection $CollectionName" -Level "Success"
    return $true
}

# Fonction pour créer une version simulée
function New-MockVersion {
    param (
        [string]$MockDataPath,
        [string]$CollectionName,
        [string]$ModelName,
        [string]$ModelVersion
    )
    
    $versionsPath = Join-Path -Path $MockDataPath -ChildPath "versions"
    $versionsFile = Join-Path -Path $versionsPath -ChildPath "embedding_versions.json"
    
    if (Test-Path -Path $versionsFile) {
        $versions = Get-Content -Path $versionsFile -Raw | ConvertFrom-Json
    } else {
        $versions = @{
            versions = @()
            current_version = $null
        }
    }
    
    $versionId = "$($ModelName.Replace('-', '_'))_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)"
    
    $newVersion = @{
        id = $versionId
        model_name = $ModelName
        model_version = $ModelVersion
        created_at = (Get-Date).ToString("o")
        collection_name = $CollectionName
        vector_size = 384
        vector_distance = "Cosine"
        point_count = 0
    }
    
    $versions.versions += $newVersion
    $versions.current_version = $versionId
    
    $versions | ConvertTo-Json -Depth 10 | Set-Content -Path $versionsFile -Encoding UTF8
    
    Write-Log "Version simulée créée: $versionId" -Level "Success"
    return $versionId
}

# Fonction pour créer un snapshot simulé
function New-MockSnapshot {
    param (
        [string]$MockDataPath,
        [string]$VersionId,
        [string]$SnapshotPath
    )
    
    $versionsPath = Join-Path -Path $MockDataPath -ChildPath "versions"
    $versionsFile = Join-Path -Path $versionsPath -ChildPath "embedding_versions.json"
    
    if (-not (Test-Path -Path $versionsFile)) {
        Write-Log "Aucune version trouvée." -Level "Error"
        return $false
    }
    
    $versions = Get-Content -Path $versionsFile -Raw | ConvertFrom-Json
    
    $version = $versions.versions | Where-Object { $_.id -eq $VersionId }
    
    if (-not $version) {
        $version = $versions.versions | Where-Object { $_.id -eq $versions.current_version }
        
        if (-not $version) {
            Write-Log "Version non trouvée." -Level "Error"
            return $false
        }
    }
    
    $collectionName = $version.collection_name
    $pointsPath = Join-Path -Path $MockDataPath -ChildPath "points\$collectionName"
    
    if (-not (Test-Path -Path $pointsPath)) {
        Write-Log "Points de la collection non trouvés." -Level "Error"
        return $false
    }
    
    $points = @()
    $pointFiles = Get-ChildItem -Path $pointsPath -Filter "*.json"
    
    foreach ($pointFile in $pointFiles) {
        $point = Get-Content -Path $pointFile.FullName -Raw | ConvertFrom-Json
        $points += $point
    }
    
    $snapshot = @{
        version = $version
        created_at = (Get-Date).ToString("o")
        points_count = $points.Count
        points = $points
    }
    
    # Créer le répertoire parent si nécessaire
    $snapshotDir = Split-Path -Parent $SnapshotPath
    if (-not (Test-Path -Path $snapshotDir)) {
        New-Item -Path $snapshotDir -ItemType Directory -Force | Out-Null
    }
    
    $snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $SnapshotPath -Encoding UTF8
    
    # Mettre à jour la version avec le chemin du snapshot
    foreach ($v in $versions.versions) {
        if ($v.id -eq $version.id) {
            $v | Add-Member -NotePropertyName "snapshot_path" -NotePropertyValue $SnapshotPath -Force
            $v | Add-Member -NotePropertyName "snapshot_created_at" -NotePropertyValue (Get-Date).ToString("o") -Force
            break
        }
    }
    
    $versions | ConvertTo-Json -Depth 10 | Set-Content -Path $versionsFile -Encoding UTF8
    
    Write-Log "Snapshot simulé créé: $SnapshotPath" -Level "Success"
    return $true
}

# Fonction pour démarrer le service simulé
function Start-MockQdrantService {
    param (
        [string]$MockDataPath,
        [int]$Port
    )
    
    # Créer le répertoire de données simulées
    $result = New-MockDataDirectory -MockDataPath $MockDataPath
    
    if (-not $result) {
        Write-Log "Erreur lors de la création du répertoire de données simulées." -Level "Error"
        return $false
    }
    
    # Créer un fichier de statut pour indiquer que le service est en cours d'exécution
    $statusFile = Join-Path -Path $MockDataPath -ChildPath "status.json"
    
    $status = @{
        running = $true
        port = $Port
        started_at = (Get-Date).ToString("o")
    }
    
    $status | ConvertTo-Json | Set-Content -Path $statusFile -Encoding UTF8
    
    Write-Log "Service Qdrant simulé démarré sur le port $Port" -Level "Success"
    Write-Log "Données simulées stockées dans $MockDataPath" -Level "Info"
    
    return $true
}

# Fonction pour arrêter le service simulé
function Stop-MockQdrantService {
    param (
        [string]$MockDataPath
    )
    
    $statusFile = Join-Path -Path $MockDataPath -ChildPath "status.json"
    
    if (Test-Path -Path $statusFile) {
        $status = Get-Content -Path $statusFile -Raw | ConvertFrom-Json
        $status.running = $false
        $status.stopped_at = (Get-Date).ToString("o")
        
        $status | ConvertTo-Json | Set-Content -Path $statusFile -Encoding UTF8
        
        Write-Log "Service Qdrant simulé arrêté" -Level "Success"
        return $true
    } else {
        Write-Log "Le service Qdrant simulé n'est pas en cours d'exécution." -Level "Warning"
        return $false
    }
}

# Fonction pour vérifier le statut du service simulé
function Get-MockQdrantServiceStatus {
    param (
        [string]$MockDataPath
    )
    
    $statusFile = Join-Path -Path $MockDataPath -ChildPath "status.json"
    
    if (Test-Path -Path $statusFile) {
        $status = Get-Content -Path $statusFile -Raw | ConvertFrom-Json
        
        if ($status.running) {
            Write-Log "Service Qdrant simulé en cours d'exécution sur le port $($status.port)" -Level "Success"
            Write-Log "Démarré le $($status.started_at)" -Level "Info"
        } else {
            Write-Log "Service Qdrant simulé arrêté" -Level "Warning"
            Write-Log "Arrêté le $($status.stopped_at)" -Level "Info"
        }
        
        return $status.running
    } else {
        Write-Log "Le service Qdrant simulé n'a jamais été démarré." -Level "Warning"
        return $false
    }
}

# Fonction principale
function Main {
    switch ($Action) {
        "Start" {
            return Start-MockQdrantService -MockDataPath $MockDataPath -Port $Port
        }
        "Stop" {
            return Stop-MockQdrantService -MockDataPath $MockDataPath
        }
        "Status" {
            return Get-MockQdrantServiceStatus -MockDataPath $MockDataPath
        }
        default {
            Write-Log "Action non reconnue: $Action" -Level "Error"
            return $false
        }
    }
}

# Exécuter la fonction principale
Main

# Explore-QdrantWebUI.ps1
# Script pour explorer l'interface web de Qdrant
# Version: 1.0
# Date: 2025-05-02

[CmdletBinding()]
param (
    [Parameter()]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter()]
    [switch]$OpenBrowser
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
        Write-Log "Version de Qdrant: $($response.version)" -Level Info
        return $true
    } catch {
        Write-Log "Impossible de se connecter Ã  Qdrant Ã  l'URL: $Url" -Level Error
        Write-Log "Erreur: $_" -Level Error
        return $false
    }
}

function Get-QdrantCollections {
    param (
        [string]$Url
    )

    try {
        $response = Invoke-RestMethod -Uri "$Url/collections" -Method Get -ErrorAction Stop
        Write-Log "Collections disponibles dans Qdrant:" -Level Info
        
        if ($response.result.collections.Count -eq 0) {
            Write-Log "Aucune collection trouvÃ©e." -Level Warning
        } else {
            foreach ($collection in $response.result.collections) {
                Write-Log "- $($collection.name)" -Level Info
            }
        }
        
        return $response.result.collections
    } catch {
        Write-Log "Erreur lors de la rÃ©cupÃ©ration des collections: $_" -Level Error
        return $null
    }
}

function Get-QdrantCollectionInfo {
    param (
        [string]$Url,
        [string]$CollectionName
    )

    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$CollectionName" -Method Get -ErrorAction Stop
        Write-Log "Informations sur la collection '$CollectionName':" -Level Info
        Write-Log "- Nombre de vecteurs: $($response.result.vectors_count)" -Level Info
        Write-Log "- Dimension des vecteurs: $($response.result.config.params.vectors.size)" -Level Info
        Write-Log "- Distance: $($response.result.config.params.vectors.distance)" -Level Info
        
        return $response.result
    } catch {
        Write-Log "Erreur lors de la rÃ©cupÃ©ration des informations sur la collection '$CollectionName': $_" -Level Error
        return $null
    }
}

function Get-QdrantCollectionPoints {
    param (
        [string]$Url,
        [string]$CollectionName,
        [int]$Limit = 5
    )

    try {
        $body = @{
            limit = $Limit
            with_payload = $true
            with_vector = $false
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$Url/collections/$CollectionName/points/scroll" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        
        Write-Log "Points dans la collection '$CollectionName':" -Level Info
        
        if ($response.result.points.Count -eq 0) {
            Write-Log "Aucun point trouvÃ©." -Level Warning
        } else {
            foreach ($point in $response.result.points) {
                Write-Log "- ID: $($point.id)" -Level Info
                Write-Log "  Payload: $($point.payload | ConvertTo-Json -Depth 3)" -Level Info
                Write-Log "" -Level Info
            }
            
            if ($response.result.next_page_offset) {
                Write-Log "Il y a plus de points disponibles. Utilisez l'offset: $($response.result.next_page_offset)" -Level Info
            }
        }
        
        return $response.result.points
    } catch {
        Write-Log "Erreur lors de la rÃ©cupÃ©ration des points de la collection '$CollectionName': $_" -Level Error
        return $null
    }
}

function Open-QdrantWebUI {
    param (
        [string]$Url
    )
    
    try {
        $webUIUrl = $Url.TrimEnd('/') + "/dashboard"
        Write-Log "Ouverture de l'interface web de Qdrant Ã  l'URL: $webUIUrl" -Level Info
        Start-Process $webUIUrl
    } catch {
        Write-Log "Erreur lors de l'ouverture de l'interface web de Qdrant: $_" -Level Error
    }
}

function Get-QdrantInfo {
    param (
        [string]$Url
    )
    
    # VÃ©rifier la connexion Ã  Qdrant
    if (-not (Test-QdrantConnection -Url $Url)) {
        return
    }
    
    # RÃ©cupÃ©rer les collections
    $collections = Get-QdrantCollections -Url $Url
    
    # Si des collections sont trouvÃ©es, rÃ©cupÃ©rer les informations sur chaque collection
    if ($collections) {
        foreach ($collection in $collections) {
            Get-QdrantCollectionInfo -Url $Url -CollectionName $collection.name
            
            # RÃ©cupÃ©rer quelques points de la collection
            Get-QdrantCollectionPoints -Url $Url -CollectionName $collection.name -Limit 5
        }
    }
    
    # Ouvrir l'interface web de Qdrant si demandÃ©
    if ($OpenBrowser) {
        Open-QdrantWebUI -Url $Url
    }
    
    Write-Log "Exploration de Qdrant terminÃ©e." -Level Success
}

# ExÃ©cuter la fonction principale
Get-QdrantInfo -Url $QdrantUrl

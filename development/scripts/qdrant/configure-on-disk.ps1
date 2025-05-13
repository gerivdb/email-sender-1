# Script pour configurer on_disk:true pour les vecteurs originaux dans Qdrant

param (
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$CollectionName = "roadmap_tasks_test_vector_update"
)

# Fonction pour configurer on_disk
function Set-QdrantOnDisk {
    param (
        [string]$Url,
        [string]$Collection,
        [bool]$OnDisk = $true
    )
    
    # Configurer on_disk pour les vecteurs originaux
    $body = @{
        hnsw_config = @{
            on_disk = $OnDisk
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "Configuration de on_disk=$OnDisk pour les vecteurs originaux..."
        $uri = "$Url/collections/$Collection"
        Invoke-RestMethod -Uri $uri -Method Patch -Body $body -ContentType "application/json" | Out-Null
        Write-Host "Configuration on_disk réussie"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la configuration on_disk: $_"
        return $false
    }
}

# Fonction pour obtenir la configuration actuelle
function Get-QdrantCollectionConfig {
    param (
        [string]$Url,
        [string]$Collection
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Get
        return $response.result.config
    }
    catch {
        Write-Error "Erreur lors de la récupération de la configuration: $_"
        return $null
    }
}

# Fonction principale
function Main {
    # Obtenir la configuration actuelle
    $config = Get-QdrantCollectionConfig -Url $QdrantUrl -Collection $CollectionName
    
    if ($null -eq $config) {
        Write-Error "Impossible de récupérer la configuration de la collection"
        return
    }
    
    # Vérifier si on_disk est déjà configuré
    if ($config.hnsw_config.on_disk) {
        Write-Host "on_disk est déjà configuré à $($config.hnsw_config.on_disk) pour cette collection"
        return
    }
    
    # Configurer on_disk
    $success = Set-QdrantOnDisk -Url $QdrantUrl -Collection $CollectionName
    
    if ($success) {
        # Vérifier la nouvelle configuration
        $newConfig = Get-QdrantCollectionConfig -Url $QdrantUrl -Collection $CollectionName
        
        if ($null -ne $newConfig) {
            Write-Host "`nNouvelle configuration:"
            Write-Host "- on_disk: $($newConfig.hnsw_config.on_disk)"
        }
    }
}

# Exécuter la fonction principale
Main

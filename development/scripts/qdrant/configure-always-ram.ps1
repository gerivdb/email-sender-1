# Script pour configurer always_ram:true pour les vecteurs quantifiés dans Qdrant

param (
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$CollectionName = "roadmap_tasks_test_vector_update"
)

# Fonction pour configurer always_ram
function Set-QdrantAlwaysRam {
    param (
        [string]$Url,
        [string]$Collection,
        [bool]$AlwaysRam = $true
    )
    
    # Vérifier si la quantification est configurée
    $config = Get-QdrantCollectionConfig -Url $Url -Collection $Collection
    
    if ($null -eq $config.quantization_config) {
        Write-Error "La quantification n'est pas configurée pour cette collection"
        return $false
    }
    
    # Configurer always_ram pour les vecteurs quantifiés
    $body = @{
        quantization_config = @{
            scalar = @{
                always_ram = $AlwaysRam
            }
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "Configuration de always_ram=$AlwaysRam pour les vecteurs quantifiés..."
        $uri = "$Url/collections/$Collection"
        Invoke-RestMethod -Uri $uri -Method Patch -Body $body -ContentType "application/json" | Out-Null
        Write-Host "Configuration always_ram réussie"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la configuration always_ram: $_"
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
    
    # Vérifier si la quantification est configurée
    if ($null -eq $config.quantization_config) {
        Write-Error "La quantification n'est pas configurée pour cette collection"
        return
    }
    
    # Vérifier si always_ram est déjà configuré
    if ($config.quantization_config.scalar.always_ram) {
        Write-Host "always_ram est déjà configuré à $($config.quantization_config.scalar.always_ram) pour cette collection"
        return
    }
    
    # Configurer always_ram
    $success = Set-QdrantAlwaysRam -Url $QdrantUrl -Collection $CollectionName
    
    if ($success) {
        # Vérifier la nouvelle configuration
        $newConfig = Get-QdrantCollectionConfig -Url $QdrantUrl -Collection $CollectionName
        
        if ($null -ne $newConfig) {
            Write-Host "`nNouvelle configuration:"
            Write-Host "- always_ram: $($newConfig.quantization_config.scalar.always_ram)"
        }
    }
}

# Exécuter la fonction principale
Main

# Script pour configurer la quantification scalaire dans Qdrant
# Ce script configure la quantification scalaire int8 avec rescoring pour une collection existante

param (
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$CollectionName = "roadmap_tasks_test_vector_update",
    [switch]$CreateTestCollection = $false,
    [string]$TestCollectionName = "roadmap_tasks_test_quantization"
)

# Fonction pour vérifier si une collection existe
function Test-QdrantCollection {
    param (
        [string]$Url,
        [string]$Collection
    )

    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Get
        return $true
    } catch {
        return $false
    }
}

# Fonction pour créer une collection de test
function New-QdrantTestCollection {
    param (
        [string]$Url,
        [string]$Collection,
        [int]$VectorSize = 384,
        [string]$Distance = "Cosine"
    )

    $body = @{
        vectors = @{
            size     = $VectorSize
            distance = $Distance
        }
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Put -Body $body -ContentType "application/json"
        Write-Host "Collection de test '$Collection' créée avec succès"
        return $true
    } catch {
        Write-Error "Erreur lors de la création de la collection de test: $_"
        return $false
    }
}

# Fonction pour configurer la quantification scalaire
function Set-QdrantQuantization {
    param (
        [string]$Url,
        [string]$Collection,
        [string]$QuantizationType = "int8",
        [bool]$AlwaysRam = $true,
        [bool]$Rescore = $true
    )

    $body = @{
        quantization_config = @{
            scalar = @{
                type       = $QuantizationType
                always_ram = $AlwaysRam
                quantile   = 0.99  # Valeur recommandée pour la plupart des cas
                rescore    = $Rescore
            }
        }
    } | ConvertTo-Json -Depth 10

    try {
        $uri = "$Url/collections/$Collection"
        Write-Host "URI: $uri"
        Write-Host "Body: $($body | Out-String)"
        $response = Invoke-RestMethod -Uri $uri -Method Patch -Body $body -ContentType "application/json"
        Write-Host "Quantification scalaire configurée avec succès pour la collection '$Collection'"
        return $true
    } catch {
        Write-Error "Erreur lors de la configuration de la quantification: $_"
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
    } catch {
        Write-Error "Erreur lors de la récupération de la configuration: $_"
        return $null
    }
}

# Fonction principale
function Main {
    # Vérifier si la collection existe
    $collectionExists = Test-QdrantCollection -Url $QdrantUrl -Collection $CollectionName

    if (-not $collectionExists) {
        Write-Error "La collection '$CollectionName' n'existe pas"
        return
    }

    # Obtenir la configuration actuelle
    $config = Get-QdrantCollectionConfig -Url $QdrantUrl -Collection $CollectionName

    if ($null -eq $config) {
        Write-Error "Impossible de récupérer la configuration de la collection"
        return
    }

    # Vérifier si la quantification est déjà configurée
    if ($null -ne $config.quantization_config) {
        Write-Host "La quantification est déjà configurée pour cette collection:"
        Write-Host ($config.quantization_config | ConvertTo-Json -Depth 10)

        $confirmUpdate = Read-Host "Voulez-vous mettre à jour la configuration de quantification? (O/N)"
        if ($confirmUpdate -ne "O") {
            Write-Host "Opération annulée"
            return
        }
    }

    # Configurer la quantification
    $success = Set-QdrantQuantization -Url $QdrantUrl -Collection $CollectionName

    if ($success) {
        # Vérifier la nouvelle configuration
        $newConfig = Get-QdrantCollectionConfig -Url $QdrantUrl -Collection $CollectionName

        if ($null -ne $newConfig) {
            Write-Host "Nouvelle configuration de quantification:"
            Write-Host ($newConfig.quantization_config | ConvertTo-Json -Depth 10)
        }
    }

    # Créer une collection de test si demandé
    if ($CreateTestCollection) {
        $testCollectionExists = Test-QdrantCollection -Url $QdrantUrl -Collection $TestCollectionName

        if ($testCollectionExists) {
            Write-Host "La collection de test '$TestCollectionName' existe déjà"
        } else {
            $success = New-QdrantTestCollection -Url $QdrantUrl -Collection $TestCollectionName

            if ($success) {
                # Configurer la quantification pour la collection de test
                $success = Set-QdrantQuantization -Url $QdrantUrl -Collection $TestCollectionName

                if ($success) {
                    Write-Host "Collection de test créée et configurée avec succès"
                }
            }
        }
    }
}

# Exécuter la fonction principale
Main

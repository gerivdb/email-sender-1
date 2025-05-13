# Script pour configurer le mode hybride dans Qdrant
# Ce script configure on_disk:true pour les vecteurs originaux et always_ram:true pour les vecteurs quantifiés

param (
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$CollectionName = "roadmap_tasks_test_vector_update",
    [switch]$CreateTestCollection = $false,
    [string]$TestCollectionName = "roadmap_tasks_test_hybrid"
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

# Fonction pour configurer le mode hybride
function Set-QdrantHybridMode {
    param (
        [string]$Url,
        [string]$Collection,
        [bool]$OnDisk = $true,
        [string]$QuantizationType = "int8",
        [bool]$AlwaysRam = $true
    )

    # Configurer on_disk pour les vecteurs originaux
    $bodyHnsw = @{
        hnsw_config = @{
            on_disk = $OnDisk
        }
    } | ConvertTo-Json -Depth 10

    try {
        Write-Host "Configuration de on_disk=$OnDisk pour les vecteurs originaux..."
        $uri = "$Url/collections/$Collection"
        $response = Invoke-RestMethod -Uri $uri -Method Patch -Body $bodyHnsw -ContentType "application/json"
        Write-Host "Configuration on_disk réussie"
    } catch {
        Write-Error "Erreur lors de la configuration on_disk: $_"
        return $false
    }

    # Configurer la quantification avec always_ram
    $bodyQuant = @{
        quantization_config = @{
            scalar = @{
                type       = $QuantizationType
                always_ram = $AlwaysRam
                quantile   = 0.99
                rescore    = $true
            }
        }
    } | ConvertTo-Json -Depth 10

    try {
        Write-Host "Configuration de always_ram=$AlwaysRam pour les vecteurs quantifiés..."
        $uri = "$Url/collections/$Collection"
        $response = Invoke-RestMethod -Uri $uri -Method Patch -Body $bodyQuant -ContentType "application/json"
        Write-Host "Configuration always_ram réussie"
        return $true
    } catch {
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

    # Vérifier si le mode hybride est déjà configuré
    $isHybridConfigured = $config.hnsw_config.on_disk -and
                         ($null -ne $config.quantization_config) -and
                         ($null -ne $config.quantization_config.scalar) -and
    $config.quantization_config.scalar.always_ram

    if ($isHybridConfigured) {
        Write-Host "Le mode hybride est déjà configuré pour cette collection:"
        Write-Host "- on_disk: $($config.hnsw_config.on_disk)"
        Write-Host "- quantization: $($null -ne $config.quantization_config)"
        Write-Host "- always_ram: $($config.quantization_config.scalar.always_ram)"

        $confirmUpdate = Read-Host "Voulez-vous mettre à jour la configuration du mode hybride? (O/N)"
        if ($confirmUpdate -ne "O") {
            Write-Host "Opération annulée"
            return
        }
    }

    # Configurer le mode hybride
    $success = Set-QdrantHybridMode -Url $QdrantUrl -Collection $CollectionName

    if ($success) {
        # Vérifier la nouvelle configuration
        $newConfig = Get-QdrantCollectionConfig -Url $QdrantUrl -Collection $CollectionName

        if ($null -ne $newConfig) {
            Write-Host "`nNouvelle configuration du mode hybride:"
            Write-Host "- on_disk: $($newConfig.hnsw_config.on_disk)"
            Write-Host "- quantization: $($null -ne $newConfig.quantization_config)"
            if ($null -ne $newConfig.quantization_config -and $null -ne $newConfig.quantization_config.scalar) {
                Write-Host "- always_ram: $($newConfig.quantization_config.scalar.always_ram)"
                Write-Host "- type: $($newConfig.quantization_config.scalar.type)"
            }
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
                # Configurer le mode hybride pour la collection de test
                $success = Set-QdrantHybridMode -Url $QdrantUrl -Collection $TestCollectionName

                if ($success) {
                    Write-Host "Collection de test créée et configurée en mode hybride avec succès"
                }
            }
        }
    }

    # Générer un rapport de configuration
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $report = @"
# Configuration du mode hybride pour Qdrant
*Généré le $dateStr*

## Collection: $CollectionName

### Configuration actuelle
- **on_disk**: $($newConfig.hnsw_config.on_disk)
- **Quantification**: $($null -ne $newConfig.quantization_config)
- **Type de quantification**: $($newConfig.quantization_config.scalar.type)
- **always_ram**: $($newConfig.quantization_config.scalar.always_ram)

## Avantages du mode hybride

Le mode hybride combine les avantages de la quantification et du stockage sur disque:

1. **Réduction de l'empreinte mémoire**: Les vecteurs originaux sont stockés sur disque
2. **Performances de recherche optimales**: Les vecteurs quantifiés sont maintenus en RAM
3. **Précision préservée**: Possibilité d'utiliser le rescoring avec les vecteurs originaux

## Recommandations d'utilisation

- Pour les collections de grande taille (>1M vecteurs), le mode hybride est fortement recommandé
- Pour les vecteurs de grande dimension (>500), le mode hybride offre un excellent compromis
- Surveiller l'utilisation de la mémoire et ajuster les paramètres si nécessaire

## Configuration recommandée

```json
{
    "hnsw_config": {
        "on_disk": true
    },
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true,
            "quantile": 0.99,
            "rescore": true
        }
    }
}
```
"@

    $reportPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\guides\mcp\CONFIGURATION_MODE_HYBRIDE.md"
    $report | Out-File -FilePath $reportPath -Encoding utf8

    Write-Host "`nRapport de configuration généré: $reportPath"
}

# Exécuter la fonction principale
Main

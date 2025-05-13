# Script d'analyse de la configuration Qdrant
# Ce script analyse la configuration actuelle de Qdrant et génère un rapport
# avec des recommandations d'optimisation basées sur les bonnes pratiques.

param (
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$CollectionName = "roadmap_tasks_test_vector_update",
    [string]$OutputPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\guides\mcp\ANALYSE_QDRANT_CONFIG.md"
)

# Fonction pour obtenir les informations de la collection
function Get-QdrantCollectionInfo {
    param (
        [string]$Url,
        [string]$Collection
    )

    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Get
        return $response.result
    } catch {
        Write-Error "Erreur lors de la récupération des informations de la collection: $_"
        return $null
    }
}

# Fonction pour analyser la configuration HNSW
function Test-HnswConfig {
    param (
        [PSCustomObject]$Config
    )

    $hnswConfig = $Config.hnsw_config
    $vectorSize = $Config.params.vectors.size

    $recommendations = @()

    # Analyse du paramètre m
    if ($hnswConfig.m -lt 12) {
        $recommendations += "Augmenter le paramètre m (actuellement $($hnswConfig.m)) à au moins 12 pour améliorer la précision"
    } elseif ($hnswConfig.m -gt 64) {
        $recommendations += "Réduire le paramètre m (actuellement $($hnswConfig.m)) à un maximum de 64 pour optimiser les performances"
    }

    # Analyse du paramètre ef_construct
    if ($hnswConfig.ef_construct -lt 100) {
        $recommendations += "Augmenter le paramètre ef_construct (actuellement $($hnswConfig.ef_construct)) à au moins 100 pour améliorer la précision"
    } elseif ($hnswConfig.ef_construct -gt 500 -and $vectorSize -lt 500) {
        $recommendations += "Réduire le paramètre ef_construct (actuellement $($hnswConfig.ef_construct)) pour les vecteurs de petite dimension ($vectorSize)"
    }

    # Analyse du paramètre on_disk
    if (-not $hnswConfig.on_disk -and $vectorSize -gt 500) {
        $recommendations += "Activer on_disk pour les vecteurs de grande dimension ($vectorSize) afin de réduire l'utilisation de la mémoire"
    }

    return $recommendations
}

# Fonction pour analyser la configuration de quantification
function Test-QuantizationConfig {
    param (
        [PSCustomObject]$Config
    )

    $quantizationConfig = $Config.quantization_config
    $vectorSize = $Config.params.vectors.size
    $distance = $Config.params.vectors.distance

    $recommendations = @()

    # Vérifier si la quantification est configurée
    if ($null -eq $quantizationConfig) {
        $recommendations += "Activer la quantification scalaire pour réduire l'empreinte mémoire et accélérer les recherches"

        # Recommandations spécifiques basées sur la distance et la taille des vecteurs
        if ($distance -eq "Cosine" -or $distance -eq "Dot") {
            $recommendations += "Utiliser la quantification scalaire de type int8 pour la distance $distance"
        }

        if ($vectorSize -gt 500) {
            $recommendations += "Pour les vecteurs de grande dimension ($vectorSize), configurer always_ram=true pour les vecteurs quantifiés"
        }
    } else {
        # Analyser la configuration de quantification existante
        if ($quantizationConfig.scalar) {
            if ($quantizationConfig.scalar.type -ne "int8") {
                $recommendations += "Utiliser la quantification scalaire de type int8 pour un meilleur équilibre précision/performance"
            }

            if (-not $quantizationConfig.scalar.always_ram) {
                $recommendations += "Configurer always_ram=true pour les vecteurs quantifiés afin d'améliorer les performances de recherche"
            }
        } elseif ($quantizationConfig.product) {
            $recommendations += "La quantification par produit offre une compression maximale mais au détriment de la précision. Envisager la quantification scalaire pour un meilleur équilibre"
        } elseif ($quantizationConfig.binary) {
            if ($distance -ne "Cosine" -and $distance -ne "Dot") {
                $recommendations += "La quantification binaire est optimale pour les distances Cosine et Dot. Pour $distance, envisager la quantification scalaire"
            }
        }
    }

    return $recommendations
}

# Fonction pour analyser la configuration d'optimisation
function Test-OptimizerConfig {
    param (
        [PSCustomObject]$Config
    )

    $optimizerConfig = $Config.optimizer_config

    $recommendations = @()

    # Analyse du nombre de segments
    if ($optimizerConfig.default_segment_number -eq 0) {
        $recommendations += "Configurer default_segment_number en fonction du nombre de cœurs CPU disponibles pour optimiser la parallélisation"
    } elseif ($optimizerConfig.default_segment_number -gt 16) {
        $recommendations += "Réduire default_segment_number (actuellement $($optimizerConfig.default_segment_number)) pour équilibrer latence et débit"
    }

    return $recommendations
}

# Fonction principale
function Main {
    # Récupérer les informations de la collection
    $collectionInfo = Get-QdrantCollectionInfo -Url $QdrantUrl -Collection $CollectionName

    if ($null -eq $collectionInfo) {
        Write-Error "Impossible d'analyser la configuration de Qdrant"
        return
    }

    # Analyser les différentes configurations
    $hnswRecommendations = Test-HnswConfig -Config $collectionInfo.config
    $quantizationRecommendations = Test-QuantizationConfig -Config $collectionInfo.config
    $optimizerRecommendations = Test-OptimizerConfig -Config $collectionInfo.config

    # Générer le rapport
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $report = @"
# Analyse de la configuration Qdrant
*Générée le $dateStr*

## Configuration actuelle

Collection: **$CollectionName**

### Paramètres des vecteurs
- **Dimension**: $($collectionInfo.config.params.vectors.size)
- **Distance**: $($collectionInfo.config.params.vectors.distance)
- **Payload sur disque**: $($collectionInfo.config.params.on_disk_payload)

### Configuration HNSW
- **m**: $($collectionInfo.config.hnsw_config.m)
- **ef_construct**: $($collectionInfo.config.hnsw_config.ef_construct)
- **full_scan_threshold**: $($collectionInfo.config.hnsw_config.full_scan_threshold)
- **on_disk**: $($collectionInfo.config.hnsw_config.on_disk)

### Configuration de quantification
$($null -eq $collectionInfo.config.quantization_config ? "Non configurée" : "Configurée")

### Configuration d'optimisation
- **default_segment_number**: $($collectionInfo.config.optimizer_config.default_segment_number)
- **indexing_threshold**: $($collectionInfo.config.optimizer_config.indexing_threshold)

## Recommandations

### HNSW
$($hnswRecommendations.Count -eq 0 ? "✅ Configuration HNSW optimale" : ($hnswRecommendations | ForEach-Object { "- $($_)" } | Out-String))

### Quantification
$($quantizationRecommendations.Count -eq 0 ? "✅ Configuration de quantification optimale" : ($quantizationRecommendations | ForEach-Object { "- $($_)" } | Out-String))

### Optimisation
$($optimizerRecommendations.Count -eq 0 ? "✅ Configuration d'optimisation optimale" : ($optimizerRecommendations | ForEach-Object { "- $($_)" } | Out-String))

## Configuration recommandée

```json
{
    "vectors": {
        "size": $($collectionInfo.config.params.vectors.size),
        "distance": "$($collectionInfo.config.params.vectors.distance)",
        "on_disk": true
    },
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true
        }
    },
    "hnsw_config": {
        "m": $($collectionInfo.config.hnsw_config.m),
        "ef_construct": $($collectionInfo.config.hnsw_config.ef_construct),
        "on_disk": $($collectionInfo.config.params.vectors.size -gt 500)
    },
    "optimizer_config": {
        "default_segment_number": 8
    }
}
```
"@

    # Enregistrer le rapport
    $report | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "Rapport d'analyse généré avec succès: $OutputPath"
}

# Exécuter la fonction principale
Main

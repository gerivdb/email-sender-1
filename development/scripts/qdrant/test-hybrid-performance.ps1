# Script pour tester les performances du mode hybride dans Qdrant
# Ce script compare les performances de recherche avec différentes configurations et tailles de collections

param (
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$CollectionPrefix = "roadmap_tasks_test_hybrid",
    [array]$CollectionSizes = @(100, 500, 1000),
    [int]$NumQueries = 5,
    [int]$VectorSize = 384,
    [int]$TopK = 10
)

# Fonction pour générer un vecteur aléatoire normalisé
function New-RandomVector {
    param (
        [int]$Size
    )

    # Générer des valeurs aléatoires
    $vector = @()
    $sum = 0

    for ($i = 0; $i -lt $Size; $i++) {
        $value = [double](Get-Random -Minimum -100 -Maximum 100) / 100
        $vector += $value
        $sum += $value * $value
    }

    # Normaliser le vecteur (pour la distance cosinus)
    $magnitude = [Math]::Sqrt($sum)

    if ($magnitude -gt 0) {
        for ($i = 0; $i -lt $Size; $i++) {
            $vector[$i] = $vector[$i] / $magnitude
        }
    }

    return $vector
}

# Fonction pour créer une collection avec une configuration spécifique
function New-QdrantTestCollection {
    param (
        [string]$Url,
        [string]$Collection,
        [int]$VectorSize,
        [string]$Distance = "Cosine",
        [bool]$UseQuantization = $false,
        [bool]$UseOnDisk = $false,
        [bool]$UseAlwaysRam = $false
    )

    # Vérifier si la collection existe déjà
    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Get

        # Supprimer la collection existante
        Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Delete | Out-Null
        Write-Host "Collection existante '$Collection' supprimée"
    } catch {
        # La collection n'existe pas, c'est normal
    }

    # Créer la configuration de base
    $config = @{
        vectors     = @{
            size     = $VectorSize
            distance = $Distance
        }
        hnsw_config = @{
            m            = 16
            ef_construct = 100
            on_disk      = $UseOnDisk
        }
    }

    # Ajouter la configuration de quantification si demandé
    if ($UseQuantization) {
        $config.quantization_config = @{
            scalar = @{
                type       = "int8"
                always_ram = $UseAlwaysRam
                quantile   = 0.99
            }
        }
    }

    $body = $config | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Put -Body $body -ContentType "application/json" | Out-Null

        $configDesc = "Configuration: "
        if ($UseOnDisk) { $configDesc += "on_disk=true, " }
        if ($UseQuantization) { $configDesc += "quantization=true, " }
        if ($UseAlwaysRam) { $configDesc += "always_ram=true" }

        Write-Host "Collection '$Collection' créée avec succès ($configDesc)"
        return $true
    } catch {
        Write-Error "Erreur lors de la création de la collection: $_"
        return $false
    }
}

# Fonction pour insérer des vecteurs dans une collection
function Add-QdrantVectors {
    param (
        [string]$Url,
        [string]$Collection,
        [array]$Vectors,
        [int]$BatchSize = 100
    )

    $totalVectors = $Vectors.Count
    $batches = [Math]::Ceiling($totalVectors / $BatchSize)

    for ($i = 0; $i -lt $batches; $i++) {
        $start = $i * $BatchSize
        $end = [Math]::Min(($i + 1) * $BatchSize, $totalVectors) - 1
        $batchVectors = $Vectors[$start..$end]

        $points = @()

        for ($j = 0; $j -lt $batchVectors.Count; $j++) {
            $points += @{
                id      = [int]($start + $j)
                vector  = $batchVectors[$j]
                payload = @{
                    index = $start + $j
                }
            }
        }

        $body = @{
            points = $points
        } | ConvertTo-Json -Depth 10

        try {
            Invoke-RestMethod -Uri "$Url/collections/$Collection/points" -Method Put -Body $body -ContentType "application/json" | Out-Null
            Write-Host "Lot $($i+1)/$batches inséré ($($batchVectors.Count) vecteurs)"
        } catch {
            Write-Error "Erreur lors de l'insertion des vecteurs: $_"
            return $false
        }
    }

    return $true
}

# Fonction pour effectuer une recherche
function Search-QdrantVectors {
    param (
        [string]$Url,
        [string]$Collection,
        [array]$QueryVector,
        [int]$Limit = 10
    )

    $body = @{
        vector = $QueryVector
        limit  = $Limit
    } | ConvertTo-Json -Depth 10

    try {
        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection/points/search" -Method Post -Body $body -ContentType "application/json"
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds

        return @{
            Results  = $response.result
            Duration = $duration
        }
    } catch {
        Write-Error "Erreur lors de la recherche: $_"
        return $null
    }
}

# Fonction principale
function Main {
    # Configurations à tester
    $configs = @(
        @{ Name = "standard"; OnDisk = $false; Quantization = $false; AlwaysRam = $false },
        @{ Name = "on_disk"; OnDisk = $true; Quantization = $false; AlwaysRam = $false },
        @{ Name = "quantization"; OnDisk = $false; Quantization = $true; AlwaysRam = $false },
        @{ Name = "hybrid"; OnDisk = $true; Quantization = $true; AlwaysRam = $true }
    )

    # Résultats des tests
    $results = @{}

    # Pour chaque taille de collection
    foreach ($size in $CollectionSizes) {
        Write-Host "`n=== Test avec $size vecteurs ==="

        # Générer des vecteurs aléatoires
        Write-Host "Génération de $size vecteurs aléatoires de dimension $VectorSize..."
        $vectors = @()

        for ($i = 0; $i -lt $size; $i++) {
            $vectors += (New-RandomVector -Size $VectorSize)

            if (($i + 1) % 100 -eq 0) {
                Write-Host "  $($i + 1) vecteurs générés"
            }
        }

        # Générer des vecteurs de requête
        Write-Host "Génération de $NumQueries vecteurs de requête..."
        $queryVectors = @()

        for ($i = 0; $i -lt $NumQueries; $i++) {
            $queryVectors += (New-RandomVector -Size $VectorSize)
        }

        # Pour chaque configuration
        foreach ($config in $configs) {
            $collectionName = "${CollectionPrefix}_${size}_$($config.Name)"

            # Créer la collection
            $success = New-QdrantTestCollection -Url $QdrantUrl -Collection $collectionName -VectorSize $VectorSize `
                -UseOnDisk $config.OnDisk -UseQuantization $config.Quantization -UseAlwaysRam $config.AlwaysRam

            if (-not $success) {
                Write-Error "Impossible de créer la collection $collectionName"
                continue
            }

            # Insérer les vecteurs
            Write-Host "Insertion des vecteurs dans la collection $collectionName..."
            $success = Add-QdrantVectors -Url $QdrantUrl -Collection $collectionName -Vectors $vectors

            if (-not $success) {
                Write-Error "Échec de l'insertion des vecteurs dans la collection $collectionName"
                continue
            }

            # Effectuer les recherches
            Write-Host "Exécution des requêtes de recherche..."

            $durations = @()

            for ($i = 0; $i -lt $NumQueries; $i++) {
                $result = Search-QdrantVectors -Url $QdrantUrl -Collection $collectionName -QueryVector $queryVectors[$i] -Limit $TopK

                if ($null -ne $result) {
                    $durations += $result.Duration
                }

                Write-Host "  Requête $($i + 1)/$NumQueries exécutée"
            }

            # Calculer les statistiques
            $avg = ($durations | Measure-Object -Average).Average
            $min = ($durations | Measure-Object -Minimum).Minimum
            $max = ($durations | Measure-Object -Maximum).Maximum

            # Stocker les résultats
            if (-not $results.ContainsKey($size)) {
                $results[$size] = @{}
            }

            $results[$size][$config.Name] = @{
                Average = $avg
                Minimum = $min
                Maximum = $max
            }

            # Afficher les résultats
            Write-Host "Résultats pour la collection: $collectionName"
            Write-Host "  Temps moyen: $($avg.ToString("F2")) ms"
            Write-Host "  Temps minimum: $($min.ToString("F2")) ms"
            Write-Host "  Temps maximum: $($max.ToString("F2")) ms"
        }
    }

    # Générer un rapport
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $report = @"
# Rapport de test de performance du mode hybride Qdrant
*Généré le $dateStr*

## Configuration du test
- Dimensions des vecteurs: $VectorSize
- Nombre de requêtes par test: $NumQueries
- Top-K: $TopK
- Tailles de collections testées: $($CollectionSizes -join ", ")

## Résultats

"@

    foreach ($size in $CollectionSizes) {
        $report += @"
### Collection de $size vecteurs

| Configuration | Temps moyen (ms) | Temps min (ms) | Temps max (ms) | Accélération |
|---------------|------------------|----------------|----------------|--------------|
"@

        $standardTime = $results[$size]["standard"].Average

        foreach ($config in $configs) {
            $avg = $results[$size][$config.Name].Average
            $min = $results[$size][$config.Name].Minimum
            $max = $results[$size][$config.Name].Maximum
            $speedup = $standardTime / $avg

            $report += "| $($config.Name) | $($avg.ToString("F2")) | $($min.ToString("F2")) | $($max.ToString("F2")) | $($speedup.ToString("F2"))x |`n"
        }

        $report += "`n"
    }

    $report += @"
## Analyse

### Impact de la taille de la collection
"@

    foreach ($config in $configs) {
        $report += "`n#### Configuration $($config.Name)`n`n"
        $report += "| Taille | Temps moyen (ms) | Facteur d'augmentation |`n"
        $report += "|--------|------------------|------------------------|`n"

        $baseTime = $results[$CollectionSizes[0]][$config.Name].Average

        foreach ($size in $CollectionSizes) {
            $avg = $results[$size][$config.Name].Average
            $factor = $avg / $baseTime

            $report += "| $size | $($avg.ToString("F2")) | $($factor.ToString("F2"))x |`n"
        }
    }

    $report += @"

## Recommandations

"@

    # Déterminer la meilleure configuration pour chaque taille
    foreach ($size in $CollectionSizes) {
        $bestConfig = $configs[0].Name
        $bestTime = $results[$size][$configs[0].Name].Average

        foreach ($config in $configs) {
            if ($results[$size][$config.Name].Average -lt $bestTime) {
                $bestTime = $results[$size][$config.Name].Average
                $bestConfig = $config.Name
            }
        }

        $report += "- Pour les collections de $size vecteurs: configuration **$bestConfig** recommandée`n"
    }

    $report += @"

### Recommandation générale

$(
    if ($results[$CollectionSizes[-1]]["hybrid"].Average -lt $results[$CollectionSizes[-1]]["standard"].Average) {
        "Le mode hybride (on_disk=true + quantization=true + always_ram=true) offre les meilleures performances pour les collections de grande taille. Il est recommandé pour les collections de production."
    } else {
        "Le mode standard offre de bonnes performances pour les collections de petite taille. Pour les collections plus importantes, envisager d'autres configurations."
    }
)

## Configuration recommandée

```json
{
    "hnsw_config": {
        "m": 16,
        "ef_construct": 100,
        "on_disk": true
    },
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true,
            "quantile": 0.99
        }
    }
}
```
"@

    $reportPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\guides\mcp\RAPPORT_PERFORMANCE_MODE_HYBRIDE.md"
    $report | Out-File -FilePath $reportPath -Encoding utf8

    Write-Host "`nRapport de performance généré: $reportPath"
}

# Exécuter la fonction principale
Main

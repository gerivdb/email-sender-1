# Script pour tester les performances de la quantification dans Qdrant
# Ce script génère des vecteurs aléatoires, les insère dans une collection de test,
# puis compare les performances de recherche avec et sans quantification

param (
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$CollectionName = "roadmap_tasks_test_quantization",
    [int]$NumVectors = 1000,
    [int]$NumQueries = 10,
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

# Fonction pour créer une collection avec quantification
function New-QdrantCollectionWithQuantization {
    param (
        [string]$Url,
        [string]$Collection,
        [int]$VectorSize,
        [string]$Distance = "Cosine",
        [bool]$UseQuantization = $true
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
        vectors = @{
            size     = $VectorSize
            distance = $Distance
        }
    }

    # Ajouter la configuration de quantification si demandé
    if ($UseQuantization) {
        $config.quantization_config = @{
            scalar = @{
                type       = "int8"
                always_ram = $true
                quantile   = 0.99
            }
        }
    }

    $body = $config | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri "$Url/collections/$Collection" -Method Put -Body $body -ContentType "application/json"
        Write-Host "Collection '$Collection' créée avec succès $(if ($UseQuantization) { 'avec' } else { 'sans' }) quantification"
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
            $response = Invoke-RestMethod -Uri "$Url/collections/$Collection/points" -Method Put -Body $body -ContentType "application/json"
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
    # Générer des vecteurs aléatoires
    Write-Host "Génération de $NumVectors vecteurs aléatoires de dimension $VectorSize..."
    $vectors = @()

    for ($i = 0; $i -lt $NumVectors; $i++) {
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

    # Créer une collection sans quantification
    $collectionNoQuant = "${CollectionName}_no_quant"
    $success = New-QdrantCollectionWithQuantization -Url $QdrantUrl -Collection $collectionNoQuant -VectorSize $VectorSize -UseQuantization $false

    if (-not $success) {
        Write-Error "Impossible de créer la collection sans quantification"
        return
    }

    # Créer une collection avec quantification
    $collectionWithQuant = "${CollectionName}_with_quant"
    $success = New-QdrantCollectionWithQuantization -Url $QdrantUrl -Collection $collectionWithQuant -VectorSize $VectorSize -UseQuantification $true

    if (-not $success) {
        Write-Error "Impossible de créer la collection avec quantification"
        return
    }

    # Insérer les vecteurs dans les deux collections
    Write-Host "Insertion des vecteurs dans la collection sans quantification..."
    $success = Add-QdrantVectors -Url $QdrantUrl -Collection $collectionNoQuant -Vectors $vectors

    if (-not $success) {
        Write-Error "Échec de l'insertion des vecteurs dans la collection sans quantification"
        return
    }

    Write-Host "Insertion des vecteurs dans la collection avec quantification..."
    $success = Add-QdrantVectors -Url $QdrantUrl -Collection $collectionWithQuant -Vectors $vectors

    if (-not $success) {
        Write-Error "Échec de l'insertion des vecteurs dans la collection avec quantification"
        return
    }

    # Effectuer les recherches
    Write-Host "Exécution des requêtes de recherche..."

    $durationsNoQuant = @()
    $durationsWithQuant = @()

    for ($i = 0; $i -lt $NumQueries; $i++) {
        # Recherche sans quantification
        $resultNoQuant = Search-QdrantVectors -Url $QdrantUrl -Collection $collectionNoQuant -QueryVector $queryVectors[$i] -Limit $TopK

        if ($null -ne $resultNoQuant) {
            $durationsNoQuant += $resultNoQuant.Duration
        }

        # Recherche avec quantification
        $resultWithQuant = Search-QdrantVectors -Url $QdrantUrl -Collection $collectionWithQuant -QueryVector $queryVectors[$i] -Limit $TopK

        if ($null -ne $resultWithQuant) {
            $durationsWithQuant += $resultWithQuant.Duration
        }

        Write-Host "  Requête $($i + 1)/$NumQueries exécutée"
    }

    # Calculer les statistiques
    $avgNoQuant = ($durationsNoQuant | Measure-Object -Average).Average
    $avgWithQuant = ($durationsWithQuant | Measure-Object -Average).Average
    $minNoQuant = ($durationsNoQuant | Measure-Object -Minimum).Minimum
    $minWithQuant = ($durationsWithQuant | Measure-Object -Minimum).Minimum
    $maxNoQuant = ($durationsNoQuant | Measure-Object -Maximum).Maximum
    $maxWithQuant = ($durationsWithQuant | Measure-Object -Maximum).Maximum

    # Afficher les résultats
    Write-Host "`nRésultats des tests de performance:"
    Write-Host "----------------------------------------"
    Write-Host "Sans quantification:"
    Write-Host "  Temps moyen: $($avgNoQuant.ToString("F2")) ms"
    Write-Host "  Temps minimum: $($minNoQuant.ToString("F2")) ms"
    Write-Host "  Temps maximum: $($maxNoQuant.ToString("F2")) ms"
    Write-Host ""
    Write-Host "Avec quantification (int8):"
    Write-Host "  Temps moyen: $($avgWithQuant.ToString("F2")) ms"
    Write-Host "  Temps minimum: $($minWithQuant.ToString("F2")) ms"
    Write-Host "  Temps maximum: $($maxWithQuant.ToString("F2")) ms"
    Write-Host ""

    $speedup = $avgNoQuant / $avgWithQuant
    Write-Host "Accélération: ${speedup}x"

    # Générer un rapport
    $report = @"
# Rapport de test de performance de quantification Qdrant
*Généré le $(Get-Date -Format "yyyy-MM-dd")*

## Configuration du test
- Nombre de vecteurs: $NumVectors
- Dimension des vecteurs: $VectorSize
- Nombre de requêtes: $NumQueries
- Top-K: $TopK

## Résultats

### Sans quantification
- Temps moyen: $($avgNoQuant.ToString("F2")) ms
- Temps minimum: $($minNoQuant.ToString("F2")) ms
- Temps maximum: $($maxNoQuant.ToString("F2")) ms

### Avec quantification (int8)
- Temps moyen: $($avgWithQuant.ToString("F2")) ms
- Temps minimum: $($minWithQuant.ToString("F2")) ms
- Temps maximum: $($maxWithQuant.ToString("F2")) ms

## Analyse
- Accélération: ${speedup}x
- Réduction du temps de recherche: $([Math]::Round((1 - 1/$speedup) * 100, 2))%

## Recommandations
$(if ($speedup -gt 1.5) {
"- La quantification scalaire int8 offre une amélioration significative des performances pour les vecteurs de dimension $VectorSize
- Recommandation: Utiliser la quantification scalaire int8 avec always_ram=true pour les collections de production"
} else {
"- La quantification scalaire int8 n'offre pas d'amélioration significative des performances pour les vecteurs de dimension $VectorSize
- Recommandation: Effectuer des tests supplémentaires avec différents paramètres ou envisager d'autres optimisations"
})
"@

    $reportPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\guides\mcp\RAPPORT_PERFORMANCE_QUANTIFICATION.md"
    $report | Out-File -FilePath $reportPath -Encoding utf8

    Write-Host "Rapport de performance généré: $reportPath"
}

# Exécuter la fonction principale
Main

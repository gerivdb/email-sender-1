# Test-FilteringByConfidenceScore.ps1
# Test d'intégration pour le filtrage par score de confiance

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de filtrage par score de confiance
Write-Host "Test du workflow de filtrage par score de confiance" -ForegroundColor Cyan

# Étape 1: Créer une collection avec des éléments ayant différents scores de confiance
Write-Host "Étape 1: Créer une collection avec des éléments ayant différents scores de confiance" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "ConfidenceScoreFilteringTestCollection"

# Créer des informations extraites avec différents scores de confiance
# Scores très bas (0-20)
$veryLowInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$veryLowInfo1.ProcessingState = "Failed"
$veryLowInfo1.ConfidenceScore = 5
$veryLowInfo1 = Add-ExtractedInfoMetadata -Info $veryLowInfo1 -Key "ScoreCategory" -Value "VeryLow"

$veryLowInfo2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Very low confidence text" -Language "en"
$veryLowInfo2.ProcessingState = "Failed"
$veryLowInfo2.ConfidenceScore = 15
$veryLowInfo2 = Add-ExtractedInfoMetadata -Info $veryLowInfo2 -Key "ScoreCategory" -Value "VeryLow"

# Scores bas (21-40)
$lowInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$lowInfo1.ProcessingState = "Raw"
$lowInfo1.ConfidenceScore = 25
$lowInfo1 = Add-ExtractedInfoMetadata -Info $lowInfo1 -Key "ScoreCategory" -Value "Low"

$lowInfo2 = New-StructuredDataExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Data @{
    Quality = "Low"
} -DataFormat "Hashtable"
$lowInfo2.ProcessingState = "Raw"
$lowInfo2.ConfidenceScore = 35
$lowInfo2 = Add-ExtractedInfoMetadata -Info $lowInfo2 -Key "ScoreCategory" -Value "Low"

# Scores moyens (41-60)
$mediumInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$mediumInfo1.ProcessingState = "Processing"
$mediumInfo1.ConfidenceScore = 45
$mediumInfo1 = Add-ExtractedInfoMetadata -Info $mediumInfo1 -Key "ScoreCategory" -Value "Medium"

$mediumInfo2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Medium confidence text" -Language "en"
$mediumInfo2.ProcessingState = "Processing"
$mediumInfo2.ConfidenceScore = 55
$mediumInfo2 = Add-ExtractedInfoMetadata -Info $mediumInfo2 -Key "ScoreCategory" -Value "Medium"

# Scores élevés (61-80)
$highInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$highInfo1.ProcessingState = "Processed"
$highInfo1.ConfidenceScore = 65
$highInfo1 = Add-ExtractedInfoMetadata -Info $highInfo1 -Key "ScoreCategory" -Value "High"

$highInfo2 = New-MediaExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -MediaPath "image.jpg" -MediaType "Image"
$highInfo2.ProcessingState = "Processed"
$highInfo2.ConfidenceScore = 75
$highInfo2 = Add-ExtractedInfoMetadata -Info $highInfo2 -Key "ScoreCategory" -Value "High"

# Scores très élevés (81-100)
$veryHighInfo1 = New-TextExtractedInfo -Source "Source1" -ExtractorName "Extractor1" -Text "Very high confidence text" -Language "en"
$veryHighInfo1.ProcessingState = "Processed"
$veryHighInfo1.ConfidenceScore = 85
$veryHighInfo1 = Add-ExtractedInfoMetadata -Info $veryHighInfo1 -Key "ScoreCategory" -Value "VeryHigh"

$veryHighInfo2 = New-StructuredDataExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Data @{
    Quality = "VeryHigh"
} -DataFormat "Hashtable"
$veryHighInfo2.ProcessingState = "Processed"
$veryHighInfo2.ConfidenceScore = 95
$veryHighInfo2 = Add-ExtractedInfoMetadata -Info $veryHighInfo2 -Key "ScoreCategory" -Value "VeryHigh"

# Ajouter toutes les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $veryLowInfo1, $veryLowInfo2,
    $lowInfo1, $lowInfo2,
    $mediumInfo1, $mediumInfo2,
    $highInfo1, $highInfo2,
    $veryHighInfo1, $veryHighInfo2
)

# Vérifier que la collection a été créée correctement
$tests1 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 10 éléments"; Condition = $collection.Items.Count -eq 10 }
    @{ Test = "La collection contient 2 éléments avec score très bas (0-20)"; Condition = ($collection.Items | Where-Object { $_.ConfidenceScore -ge 0 -and $_.ConfidenceScore -le 20 }).Count -eq 2 }
    @{ Test = "La collection contient 2 éléments avec score bas (21-40)"; Condition = ($collection.Items | Where-Object { $_.ConfidenceScore -gt 20 -and $_.ConfidenceScore -le 40 }).Count -eq 2 }
    @{ Test = "La collection contient 2 éléments avec score moyen (41-60)"; Condition = ($collection.Items | Where-Object { $_.ConfidenceScore -gt 40 -and $_.ConfidenceScore -le 60 }).Count -eq 2 }
    @{ Test = "La collection contient 2 éléments avec score élevé (61-80)"; Condition = ($collection.Items | Where-Object { $_.ConfidenceScore -gt 60 -and $_.ConfidenceScore -le 80 }).Count -eq 2 }
    @{ Test = "La collection contient 2 éléments avec score très élevé (81-100)"; Condition = ($collection.Items | Where-Object { $_.ConfidenceScore -gt 80 -and $_.ConfidenceScore -le 100 }).Count -eq 2 }
)

$success1 = $true
foreach ($test in $tests1) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success1 = $false
    }
}

# Étape 2: Filtrer les éléments avec un score très bas (0-20)
Write-Host "Étape 2: Filtrer les éléments avec un score très bas (0-20)" -ForegroundColor Cyan
$veryLowItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ConfidenceScore -ge 0 -and $_.ConfidenceScore -le 20 }

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $veryLowItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $veryLowItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont un score entre 0 et 20"; Condition = ($veryLowItems | Where-Object { $_.ConfidenceScore -ge 0 -and $_.ConfidenceScore -le 20 }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($veryLowItems | Where-Object { $_.Id -eq $veryLowInfo1.Id -or $_.Id -eq $veryLowInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées ScoreCategory avec valeur 'VeryLow'"; Condition = ($veryLowItems | Where-Object { $_.Metadata["ScoreCategory"] -eq "VeryLow" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont l'état 'Failed'"; Condition = ($veryLowItems | Where-Object { $_.ProcessingState -eq "Failed" }).Count -eq 2 }
)

$success2 = $true
foreach ($test in $tests2) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success2 = $false
    }
}

# Étape 3: Filtrer les éléments avec un score bas (21-40)
Write-Host "Étape 3: Filtrer les éléments avec un score bas (21-40)" -ForegroundColor Cyan
$lowItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ConfidenceScore -gt 20 -and $_.ConfidenceScore -le 40 }

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $lowItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $lowItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont un score entre 21 et 40"; Condition = ($lowItems | Where-Object { $_.ConfidenceScore -gt 20 -and $_.ConfidenceScore -le 40 }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($lowItems | Where-Object { $_.Id -eq $lowInfo1.Id -or $_.Id -eq $lowInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées ScoreCategory avec valeur 'Low'"; Condition = ($lowItems | Where-Object { $_.Metadata["ScoreCategory"] -eq "Low" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont l'état 'Raw'"; Condition = ($lowItems | Where-Object { $_.ProcessingState -eq "Raw" }).Count -eq 2 }
)

$success3 = $true
foreach ($test in $tests3) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success3 = $false
    }
}

# Étape 4: Filtrer les éléments avec un score moyen (41-60)
Write-Host "Étape 4: Filtrer les éléments avec un score moyen (41-60)" -ForegroundColor Cyan
$mediumItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ConfidenceScore -gt 40 -and $_.ConfidenceScore -le 60 }

$tests4 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $mediumItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $mediumItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont un score entre 41 et 60"; Condition = ($mediumItems | Where-Object { $_.ConfidenceScore -gt 40 -and $_.ConfidenceScore -le 60 }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($mediumItems | Where-Object { $_.Id -eq $mediumInfo1.Id -or $_.Id -eq $mediumInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées ScoreCategory avec valeur 'Medium'"; Condition = ($mediumItems | Where-Object { $_.Metadata["ScoreCategory"] -eq "Medium" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont l'état 'Processing'"; Condition = ($mediumItems | Where-Object { $_.ProcessingState -eq "Processing" }).Count -eq 2 }
)

$success4 = $true
foreach ($test in $tests4) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success4 = $false
    }
}

# Étape 5: Filtrer les éléments avec un score élevé (61-80)
Write-Host "Étape 5: Filtrer les éléments avec un score élevé (61-80)" -ForegroundColor Cyan
$highItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ConfidenceScore -gt 60 -and $_.ConfidenceScore -le 80 }

$tests5 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $highItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $highItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont un score entre 61 et 80"; Condition = ($highItems | Where-Object { $_.ConfidenceScore -gt 60 -and $_.ConfidenceScore -le 80 }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($highItems | Where-Object { $_.Id -eq $highInfo1.Id -or $_.Id -eq $highInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées ScoreCategory avec valeur 'High'"; Condition = ($highItems | Where-Object { $_.Metadata["ScoreCategory"] -eq "High" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont l'état 'Processed'"; Condition = ($highItems | Where-Object { $_.ProcessingState -eq "Processed" }).Count -eq 2 }
)

$success5 = $true
foreach ($test in $tests5) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success5 = $false
    }
}

# Étape 6: Filtrer les éléments avec un score très élevé (81-100)
Write-Host "Étape 6: Filtrer les éléments avec un score très élevé (81-100)" -ForegroundColor Cyan
$veryHighItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ConfidenceScore -gt 80 -and $_.ConfidenceScore -le 100 }

$tests6 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $veryHighItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $veryHighItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont un score entre 81 et 100"; Condition = ($veryHighItems | Where-Object { $_.ConfidenceScore -gt 80 -and $_.ConfidenceScore -le 100 }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($veryHighItems | Where-Object { $_.Id -eq $veryHighInfo1.Id -or $_.Id -eq $veryHighInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées ScoreCategory avec valeur 'VeryHigh'"; Condition = ($veryHighItems | Where-Object { $_.Metadata["ScoreCategory"] -eq "VeryHigh" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont l'état 'Processed'"; Condition = ($veryHighItems | Where-Object { $_.ProcessingState -eq "Processed" }).Count -eq 2 }
)

$success6 = $true
foreach ($test in $tests6) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success6 = $false
    }
}

# Étape 7: Filtrer les éléments avec un score supérieur à un seuil (par exemple, 70)
Write-Host "Étape 7: Filtrer les éléments avec un score supérieur à un seuil (70)" -ForegroundColor Cyan
$thresholdItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ConfidenceScore -gt 70 }

$tests7 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $thresholdItems }
    @{ Test = "Le résultat contient 4 éléments"; Condition = $thresholdItems.Count -eq 4 }
    @{ Test = "Tous les éléments ont un score > 70"; Condition = ($thresholdItems | Where-Object { $_.ConfidenceScore -gt 70 }).Count -eq 4 }
    @{ Test = "Les éléments incluent ceux avec score élevé et très élevé"; Condition = ($thresholdItems | Where-Object { 
        $_.Id -eq $highInfo2.Id -or 
        $_.Id -eq $veryHighInfo1.Id -or 
        $_.Id -eq $veryHighInfo2.Id 
    }).Count -eq 3 }
    @{ Test = "Tous les éléments ont l'état 'Processed'"; Condition = ($thresholdItems | Where-Object { $_.ProcessingState -eq "Processed" }).Count -eq 4 }
)

$success7 = $true
foreach ($test in $tests7) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success7 = $false
    }
}

# Étape 8: Obtenir des statistiques sur la collection
Write-Host "Étape 8: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

$tests8 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques indiquent 10 éléments au total"; Condition = $stats.TotalCount -eq 10 }
    @{ Test = "Les statistiques indiquent une confiance moyenne correcte"; Condition = $stats.AverageConfidence -gt 0 }
    @{ Test = "La confiance moyenne est proche de 50"; Condition = $stats.AverageConfidence -ge 45 -and $stats.AverageConfidence -le 55 }
)

$success8 = $true
foreach ($test in $tests8) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success8 = $false
    }
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $success6 -and $success7 -and $success8

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

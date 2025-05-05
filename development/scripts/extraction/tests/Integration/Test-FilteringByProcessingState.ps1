# Test-FilteringByProcessingState.ps1
# Test d'intégration pour le filtrage par état de traitement

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de filtrage par état de traitement
Write-Host "Test du workflow de filtrage par état de traitement" -ForegroundColor Cyan

# Étape 1: Créer une collection avec des éléments ayant différents états de traitement
Write-Host "Étape 1: Créer une collection avec des éléments ayant différents états de traitement" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "ProcessingStateFilteringTestCollection"

# Créer des informations extraites avec différents états de traitement
# État "Raw"
$rawInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$rawInfo1.ProcessingState = "Raw"
$rawInfo1.ConfidenceScore = 30
$rawInfo1 = Add-ExtractedInfoMetadata -Info $rawInfo1 -Key "State" -Value "Raw"

$rawInfo2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Raw text" -Language "en"
$rawInfo2.ProcessingState = "Raw"
$rawInfo2.ConfidenceScore = 40
$rawInfo2 = Add-ExtractedInfoMetadata -Info $rawInfo2 -Key "State" -Value "Raw"

$rawInfo3 = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "Extractor3" -Data @{
    Status = "Unprocessed"
} -DataFormat "Hashtable"
$rawInfo3.ProcessingState = "Raw"
$rawInfo3.ConfidenceScore = 35
$rawInfo3 = Add-ExtractedInfoMetadata -Info $rawInfo3 -Key "State" -Value "Raw"

# État "Processing"
$processingInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$processingInfo1.ProcessingState = "Processing"
$processingInfo1.ConfidenceScore = 50
$processingInfo1 = Add-ExtractedInfoMetadata -Info $processingInfo1 -Key "State" -Value "Processing"

$processingInfo2 = New-MediaExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -MediaPath "image.jpg" -MediaType "Image"
$processingInfo2.ProcessingState = "Processing"
$processingInfo2.ConfidenceScore = 55
$processingInfo2 = Add-ExtractedInfoMetadata -Info $processingInfo2 -Key "State" -Value "Processing"

# État "Processed"
$processedInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$processedInfo1.ProcessingState = "Processed"
$processedInfo1.ConfidenceScore = 80
$processedInfo1 = Add-ExtractedInfoMetadata -Info $processedInfo1 -Key "State" -Value "Processed"

$processedInfo2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Processed text" -Language "en"
$processedInfo2.ProcessingState = "Processed"
$processedInfo2.ConfidenceScore = 85
$processedInfo2 = Add-ExtractedInfoMetadata -Info $processedInfo2 -Key "State" -Value "Processed"

$processedInfo3 = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "Extractor3" -Data @{
    Status = "Processed"
} -DataFormat "Hashtable"
$processedInfo3.ProcessingState = "Processed"
$processedInfo3.ConfidenceScore = 90
$processedInfo3 = Add-ExtractedInfoMetadata -Info $processedInfo3 -Key "State" -Value "Processed"

$processedInfo4 = New-MediaExtractedInfo -Source "Source4" -ExtractorName "Extractor4" -MediaPath "video.mp4" -MediaType "Video"
$processedInfo4.ProcessingState = "Processed"
$processedInfo4.ConfidenceScore = 95
$processedInfo4 = Add-ExtractedInfoMetadata -Info $processedInfo4 -Key "State" -Value "Processed"

# État "Failed"
$failedInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$failedInfo1.ProcessingState = "Failed"
$failedInfo1.ConfidenceScore = 10
$failedInfo1 = Add-ExtractedInfoMetadata -Info $failedInfo1 -Key "State" -Value "Failed"
$failedInfo1 = Add-ExtractedInfoMetadata -Info $failedInfo1 -Key "ErrorMessage" -Value "Processing failed due to invalid input"

$failedInfo2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "Extractor2" -Text "Failed text" -Language "en"
$failedInfo2.ProcessingState = "Failed"
$failedInfo2.ConfidenceScore = 15
$failedInfo2 = Add-ExtractedInfoMetadata -Info $failedInfo2 -Key "State" -Value "Failed"
$failedInfo2 = Add-ExtractedInfoMetadata -Info $failedInfo2 -Key "ErrorMessage" -Value "Processing failed due to text encoding issues"

# Ajouter toutes les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $rawInfo1, $rawInfo2, $rawInfo3,
    $processingInfo1, $processingInfo2,
    $processedInfo1, $processedInfo2, $processedInfo3, $processedInfo4,
    $failedInfo1, $failedInfo2
)

# Vérifier que la collection a été créée correctement
$tests1 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 11 éléments"; Condition = $collection.Items.Count -eq 11 }
    @{ Test = "La collection contient 3 éléments avec état 'Raw'"; Condition = ($collection.Items | Where-Object { $_.ProcessingState -eq "Raw" }).Count -eq 3 }
    @{ Test = "La collection contient 2 éléments avec état 'Processing'"; Condition = ($collection.Items | Where-Object { $_.ProcessingState -eq "Processing" }).Count -eq 2 }
    @{ Test = "La collection contient 4 éléments avec état 'Processed'"; Condition = ($collection.Items | Where-Object { $_.ProcessingState -eq "Processed" }).Count -eq 4 }
    @{ Test = "La collection contient 2 éléments avec état 'Failed'"; Condition = ($collection.Items | Where-Object { $_.ProcessingState -eq "Failed" }).Count -eq 2 }
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

# Étape 2: Filtrer les éléments par état "Raw"
Write-Host "Étape 2: Filtrer les éléments par état 'Raw'" -ForegroundColor Cyan
$rawItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ProcessingState -eq "Raw" }

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $rawItems }
    @{ Test = "Le résultat contient 3 éléments"; Condition = $rawItems.Count -eq 3 }
    @{ Test = "Tous les éléments ont l'état 'Raw'"; Condition = ($rawItems | Where-Object { $_.ProcessingState -eq "Raw" }).Count -eq 3 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($rawItems | Where-Object { $_.Id -eq $rawInfo1.Id -or $_.Id -eq $rawInfo2.Id -or $_.Id -eq $rawInfo3.Id }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées State avec valeur 'Raw'"; Condition = ($rawItems | Where-Object { $_.Metadata["State"] -eq "Raw" }).Count -eq 3 }
    @{ Test = "Tous les éléments ont un score de confiance < 50"; Condition = ($rawItems | Where-Object { $_.ConfidenceScore -lt 50 }).Count -eq 3 }
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

# Étape 3: Filtrer les éléments par état "Processing"
Write-Host "Étape 3: Filtrer les éléments par état 'Processing'" -ForegroundColor Cyan
$processingItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ProcessingState -eq "Processing" }

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $processingItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $processingItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont l'état 'Processing'"; Condition = ($processingItems | Where-Object { $_.ProcessingState -eq "Processing" }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($processingItems | Where-Object { $_.Id -eq $processingInfo1.Id -or $_.Id -eq $processingInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées State avec valeur 'Processing'"; Condition = ($processingItems | Where-Object { $_.Metadata["State"] -eq "Processing" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont un score de confiance entre 50 et 60"; Condition = ($processingItems | Where-Object { $_.ConfidenceScore -ge 50 -and $_.ConfidenceScore -lt 60 }).Count -eq 2 }
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

# Étape 4: Filtrer les éléments par état "Processed"
Write-Host "Étape 4: Filtrer les éléments par état 'Processed'" -ForegroundColor Cyan
$processedItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ProcessingState -eq "Processed" }

$tests4 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $processedItems }
    @{ Test = "Le résultat contient 4 éléments"; Condition = $processedItems.Count -eq 4 }
    @{ Test = "Tous les éléments ont l'état 'Processed'"; Condition = ($processedItems | Where-Object { $_.ProcessingState -eq "Processed" }).Count -eq 4 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($processedItems | Where-Object { 
        $_.Id -eq $processedInfo1.Id -or 
        $_.Id -eq $processedInfo2.Id -or 
        $_.Id -eq $processedInfo3.Id -or 
        $_.Id -eq $processedInfo4.Id 
    }).Count -eq 4 }
    @{ Test = "Tous les éléments ont des métadonnées State avec valeur 'Processed'"; Condition = ($processedItems | Where-Object { $_.Metadata["State"] -eq "Processed" }).Count -eq 4 }
    @{ Test = "Tous les éléments ont un score de confiance >= 80"; Condition = ($processedItems | Where-Object { $_.ConfidenceScore -ge 80 }).Count -eq 4 }
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

# Étape 5: Filtrer les éléments par état "Failed"
Write-Host "Étape 5: Filtrer les éléments par état 'Failed'" -ForegroundColor Cyan
$failedItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ProcessingState -eq "Failed" }

$tests5 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $failedItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $failedItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont l'état 'Failed'"; Condition = ($failedItems | Where-Object { $_.ProcessingState -eq "Failed" }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($failedItems | Where-Object { $_.Id -eq $failedInfo1.Id -or $_.Id -eq $failedInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées State avec valeur 'Failed'"; Condition = ($failedItems | Where-Object { $_.Metadata["State"] -eq "Failed" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées ErrorMessage"; Condition = ($failedItems | Where-Object { $_.Metadata.ContainsKey("ErrorMessage") }).Count -eq 2 }
    @{ Test = "Tous les éléments ont un score de confiance < 20"; Condition = ($failedItems | Where-Object { $_.ConfidenceScore -lt 20 }).Count -eq 2 }
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

# Étape 6: Filtrer par un état inexistant
Write-Host "Étape 6: Filtrer par un état inexistant" -ForegroundColor Cyan
$nonExistentItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.ProcessingState -eq "NonExistentState" }

$tests6 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $nonExistentItems }
    @{ Test = "Le résultat est un tableau vide"; Condition = $nonExistentItems.Count -eq 0 }
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

# Étape 7: Obtenir des statistiques sur la distribution des états
Write-Host "Étape 7: Obtenir des statistiques sur la distribution des états" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

$tests7 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques contiennent la distribution par état"; Condition = $null -ne $stats.StateDistribution }
    @{ Test = "La distribution par état contient 4 états"; Condition = $stats.StateDistribution.Count -eq 4 }
    @{ Test = "L'état 'Raw' a 3 éléments"; Condition = $stats.StateDistribution["Raw"] -eq 3 }
    @{ Test = "L'état 'Processing' a 2 éléments"; Condition = $stats.StateDistribution["Processing"] -eq 2 }
    @{ Test = "L'état 'Processed' a 4 éléments"; Condition = $stats.StateDistribution["Processed"] -eq 4 }
    @{ Test = "L'état 'Failed' a 2 éléments"; Condition = $stats.StateDistribution["Failed"] -eq 2 }
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

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $success6 -and $success7

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

# Test-FilteringByType.ps1
# Test d'intégration pour le filtrage par type d'information

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de filtrage par type d'information
Write-Host "Test du workflow de filtrage par type d'information" -ForegroundColor Cyan

# Étape 1: Créer une collection avec des éléments de différents types
Write-Host "Étape 1: Créer une collection avec des éléments de différents types" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "TypeFilteringTestCollection"

# Créer des informations extraites de base (ExtractedInfo)
$baseInfo1 = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$baseInfo1.ProcessingState = "Processed"
$baseInfo1.ConfidenceScore = 75
$baseInfo1 = Add-ExtractedInfoMetadata -Info $baseInfo1 -Key "Category" -Value "Base"

$baseInfo2 = New-ExtractedInfo -Source "Source2" -ExtractorName "BaseExtractor"
$baseInfo2.ProcessingState = "Raw"
$baseInfo2.ConfidenceScore = 60
$baseInfo2 = Add-ExtractedInfoMetadata -Info $baseInfo2 -Key "Category" -Value "Base"

# Créer des informations extraites de texte (TextExtractedInfo)
$textInfo1 = New-TextExtractedInfo -Source "Source1" -ExtractorName "TextExtractor" -Text "This is the first test text" -Language "en"
$textInfo1.ProcessingState = "Processed"
$textInfo1.ConfidenceScore = 85
$textInfo1 = Add-ExtractedInfoMetadata -Info $textInfo1 -Key "Category" -Value "Text"

$textInfo2 = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is the second test text" -Language "fr"
$textInfo2.ProcessingState = "Processed"
$textInfo2.ConfidenceScore = 80
$textInfo2 = Add-ExtractedInfoMetadata -Info $textInfo2 -Key "Category" -Value "Text"

$textInfo3 = New-TextExtractedInfo -Source "Source3" -ExtractorName "TextExtractor" -Text "This is the third test text" -Language "de"
$textInfo3.ProcessingState = "Raw"
$textInfo3.ConfidenceScore = 70
$textInfo3 = Add-ExtractedInfoMetadata -Info $textInfo3 -Key "Category" -Value "Text"

# Créer des informations extraites de données structurées (StructuredDataExtractedInfo)
$dataInfo1 = New-StructuredDataExtractedInfo -Source "Source1" -ExtractorName "DataExtractor" -Data @{
    Name = "Data 1"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$dataInfo1.ProcessingState = "Processed"
$dataInfo1.ConfidenceScore = 90
$dataInfo1 = Add-ExtractedInfoMetadata -Info $dataInfo1 -Key "Category" -Value "Data"

$dataInfo2 = New-StructuredDataExtractedInfo -Source "Source2" -ExtractorName "DataExtractor" -Data @{
    Name = "Data 2"
    Value = 456
    IsActive = $false
} -DataFormat "Hashtable"
$dataInfo2.ProcessingState = "Failed"
$dataInfo2.ConfidenceScore = 50
$dataInfo2 = Add-ExtractedInfoMetadata -Info $dataInfo2 -Key "Category" -Value "Data"

# Créer des informations extraites de média (MediaExtractedInfo)
$mediaInfo1 = New-MediaExtractedInfo -Source "Source1" -ExtractorName "MediaExtractor" -MediaPath "image1.jpg" -MediaType "Image"
$mediaInfo1.ProcessingState = "Processed"
$mediaInfo1.ConfidenceScore = 95
$mediaInfo1 = Add-ExtractedInfoMetadata -Info $mediaInfo1 -Key "Category" -Value "Media"

$mediaInfo2 = New-MediaExtractedInfo -Source "Source2" -ExtractorName "MediaExtractor" -MediaPath "video1.mp4" -MediaType "Video"
$mediaInfo2.ProcessingState = "Processed"
$mediaInfo2.ConfidenceScore = 85
$mediaInfo2 = Add-ExtractedInfoMetadata -Info $mediaInfo2 -Key "Category" -Value "Media"

# Ajouter toutes les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $baseInfo1, $baseInfo2,
    $textInfo1, $textInfo2, $textInfo3,
    $dataInfo1, $dataInfo2,
    $mediaInfo1, $mediaInfo2
)

# Vérifier que la collection a été créée correctement
$tests1 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 9 éléments"; Condition = $collection.Items.Count -eq 9 }
    @{ Test = "La collection contient 2 éléments de type ExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "ExtractedInfo" }).Count -eq 2 }
    @{ Test = "La collection contient 3 éléments de type TextExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 3 }
    @{ Test = "La collection contient 2 éléments de type StructuredDataExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 2 }
    @{ Test = "La collection contient 2 éléments de type MediaExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 2 }
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

# Étape 2: Filtrer les éléments par type "ExtractedInfo" (base)
Write-Host "Étape 2: Filtrer les éléments par type 'ExtractedInfo' (base)" -ForegroundColor Cyan
$baseItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_._Type -eq "ExtractedInfo" }

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $baseItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $baseItems.Count -eq 2 }
    @{ Test = "Tous les éléments sont de type 'ExtractedInfo'"; Condition = ($baseItems | Where-Object { $_._Type -eq "ExtractedInfo" }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($baseItems | Where-Object { $_.Id -eq $baseInfo1.Id -or $_.Id -eq $baseInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées Category avec valeur 'Base'"; Condition = ($baseItems | Where-Object { $_.Metadata["Category"] -eq "Base" }).Count -eq 2 }
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

# Étape 3: Filtrer les éléments par type "TextExtractedInfo"
Write-Host "Étape 3: Filtrer les éléments par type 'TextExtractedInfo'" -ForegroundColor Cyan
$textItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_._Type -eq "TextExtractedInfo" }

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $textItems }
    @{ Test = "Le résultat contient 3 éléments"; Condition = $textItems.Count -eq 3 }
    @{ Test = "Tous les éléments sont de type 'TextExtractedInfo'"; Condition = ($textItems | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 3 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($textItems | Where-Object { $_.Id -eq $textInfo1.Id -or $_.Id -eq $textInfo2.Id -or $_.Id -eq $textInfo3.Id }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées Category avec valeur 'Text'"; Condition = ($textItems | Where-Object { $_.Metadata["Category"] -eq "Text" }).Count -eq 3 }
    @{ Test = "Tous les éléments ont une propriété Text"; Condition = ($textItems | Where-Object { -not [string]::IsNullOrEmpty($_.Text) }).Count -eq 3 }
    @{ Test = "Tous les éléments ont une propriété Language"; Condition = ($textItems | Where-Object { -not [string]::IsNullOrEmpty($_.Language) }).Count -eq 3 }
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

# Étape 4: Filtrer les éléments par type "StructuredDataExtractedInfo"
Write-Host "Étape 4: Filtrer les éléments par type 'StructuredDataExtractedInfo'" -ForegroundColor Cyan
$dataItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }

$tests4 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $dataItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $dataItems.Count -eq 2 }
    @{ Test = "Tous les éléments sont de type 'StructuredDataExtractedInfo'"; Condition = ($dataItems | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($dataItems | Where-Object { $_.Id -eq $dataInfo1.Id -or $_.Id -eq $dataInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées Category avec valeur 'Data'"; Condition = ($dataItems | Where-Object { $_.Metadata["Category"] -eq "Data" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont une propriété Data"; Condition = ($dataItems | Where-Object { $null -ne $_.Data }).Count -eq 2 }
    @{ Test = "Tous les éléments ont une propriété DataFormat"; Condition = ($dataItems | Where-Object { -not [string]::IsNullOrEmpty($_.DataFormat) }).Count -eq 2 }
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

# Étape 5: Filtrer les éléments par type "MediaExtractedInfo"
Write-Host "Étape 5: Filtrer les éléments par type 'MediaExtractedInfo'" -ForegroundColor Cyan
$mediaItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_._Type -eq "MediaExtractedInfo" }

$tests5 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $mediaItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $mediaItems.Count -eq 2 }
    @{ Test = "Tous les éléments sont de type 'MediaExtractedInfo'"; Condition = ($mediaItems | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($mediaItems | Where-Object { $_.Id -eq $mediaInfo1.Id -or $_.Id -eq $mediaInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées Category avec valeur 'Media'"; Condition = ($mediaItems | Where-Object { $_.Metadata["Category"] -eq "Media" }).Count -eq 2 }
    @{ Test = "Tous les éléments ont une propriété MediaPath"; Condition = ($mediaItems | Where-Object { -not [string]::IsNullOrEmpty($_.MediaPath) }).Count -eq 2 }
    @{ Test = "Tous les éléments ont une propriété MediaType"; Condition = ($mediaItems | Where-Object { -not [string]::IsNullOrEmpty($_.MediaType) }).Count -eq 2 }
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

# Étape 6: Filtrer par un type inexistant
Write-Host "Étape 6: Filtrer par un type inexistant" -ForegroundColor Cyan
$nonExistentItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_._Type -eq "NonExistentType" }

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

# Étape 7: Obtenir des statistiques sur la distribution des types
Write-Host "Étape 7: Obtenir des statistiques sur la distribution des types" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

$tests7 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques contiennent la distribution par type"; Condition = $null -ne $stats.TypeDistribution }
    @{ Test = "La distribution par type contient 4 types"; Condition = $stats.TypeDistribution.Count -eq 4 }
    @{ Test = "Le type 'ExtractedInfo' a 2 éléments"; Condition = $stats.TypeDistribution["ExtractedInfo"] -eq 2 }
    @{ Test = "Le type 'TextExtractedInfo' a 3 éléments"; Condition = $stats.TypeDistribution["TextExtractedInfo"] -eq 3 }
    @{ Test = "Le type 'StructuredDataExtractedInfo' a 2 éléments"; Condition = $stats.TypeDistribution["StructuredDataExtractedInfo"] -eq 2 }
    @{ Test = "Le type 'MediaExtractedInfo' a 2 éléments"; Condition = $stats.TypeDistribution["MediaExtractedInfo"] -eq 2 }
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

# Test-CollectionCreation.ps1
# Test d'intégration pour la création d'une collection avec plusieurs éléments

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de création de collection
Write-Host "Test du workflow de création de collection avec plusieurs éléments" -ForegroundColor Cyan

# Étape 1: Créer une collection vide
Write-Host "Étape 1: Créer une collection vide" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "TestCollection"

# Vérifier que la collection a été créée correctement
$tests1 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "Le nom de la collection est correct"; Condition = $collection.Name -eq "TestCollection" }
    @{ Test = "La date de création est définie"; Condition = $null -ne $collection.CreatedAt }
    @{ Test = "Le tableau d'éléments est vide"; Condition = $collection.Items.Count -eq 0 }
    @{ Test = "Les métadonnées ne sont pas nulles"; Condition = $null -ne $collection.Metadata }
    @{ Test = "Le type est 'ExtractedInfoCollection'"; Condition = $collection._Type -eq "ExtractedInfoCollection" }
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

# Étape 2: Créer différents types d'informations extraites
Write-Host "Étape 2: Créer différents types d'informations extraites" -ForegroundColor Cyan

# Créer une information de base
$baseInfo = New-ExtractedInfo -Source "BaseSource" -ExtractorName "BaseExtractor"
$baseInfo.ProcessingState = "Raw"
$baseInfo.ConfidenceScore = 50
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "Category" -Value "Base"

# Créer une information de texte
$textInfo = New-TextExtractedInfo -Source "TextSource" -ExtractorName "TextExtractor" -Text "This is a test text" -Language "en"
$textInfo.ProcessingState = "Processed"
$textInfo.ConfidenceScore = 80
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "Category" -Value "Text"

# Créer une information de données structurées
$dataInfo = New-StructuredDataExtractedInfo -Source "DataSource" -ExtractorName "DataExtractor" -Data @{
    Name = "Test"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$dataInfo.ProcessingState = "Processed"
$dataInfo.ConfidenceScore = 90
$dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "Category" -Value "Data"

# Créer une information de média
$mediaInfo = New-MediaExtractedInfo -Source "MediaSource" -ExtractorName "MediaExtractor" -MediaPath "test.jpg" -MediaType "Image"
$mediaInfo.ProcessingState = "Processed"
$mediaInfo.ConfidenceScore = 70
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Category" -Value "Media"

# Vérifier que les informations ont été créées correctement
$tests2 = @(
    @{ Test = "L'information de base n'est pas nulle"; Condition = $null -ne $baseInfo }
    @{ Test = "L'information de texte n'est pas nulle"; Condition = $null -ne $textInfo }
    @{ Test = "L'information de données structurées n'est pas nulle"; Condition = $null -ne $dataInfo }
    @{ Test = "L'information de média n'est pas nulle"; Condition = $null -ne $mediaInfo }
    @{ Test = "L'information de base a un ID valide"; Condition = [guid]::TryParse($baseInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de texte a un ID valide"; Condition = [guid]::TryParse($textInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de données structurées a un ID valide"; Condition = [guid]::TryParse($dataInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de média a un ID valide"; Condition = [guid]::TryParse($mediaInfo.Id, [ref][guid]::Empty) }
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

# Étape 3: Ajouter les informations à la collection une par une
Write-Host "Étape 3: Ajouter les informations à la collection une par une" -ForegroundColor Cyan

# Ajouter l'information de base
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $baseInfo
$tests3a = @(
    @{ Test = "La collection contient 1 élément après l'ajout de l'information de base"; Condition = $collection.Items.Count -eq 1 }
    @{ Test = "L'élément ajouté est l'information de base"; Condition = $collection.Items[0].Id -eq $baseInfo.Id }
)

$success3a = $true
foreach ($test in $tests3a) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success3a = $false
    }
}

# Ajouter l'information de texte
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $textInfo
$tests3b = @(
    @{ Test = "La collection contient 2 éléments après l'ajout de l'information de texte"; Condition = $collection.Items.Count -eq 2 }
    @{ Test = "Le deuxième élément ajouté est l'information de texte"; Condition = $collection.Items[1].Id -eq $textInfo.Id }
)

$success3b = $true
foreach ($test in $tests3b) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success3b = $false
    }
}

# Étape 4: Ajouter plusieurs informations à la fois
Write-Host "Étape 4: Ajouter plusieurs informations à la fois" -ForegroundColor Cyan
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($dataInfo, $mediaInfo)

$tests4 = @(
    @{ Test = "La collection contient 4 éléments après l'ajout de plusieurs informations"; Condition = $collection.Items.Count -eq 4 }
    @{ Test = "Le troisième élément ajouté est l'information de données structurées"; Condition = $collection.Items[2].Id -eq $dataInfo.Id }
    @{ Test = "Le quatrième élément ajouté est l'information de média"; Condition = $collection.Items[3].Id -eq $mediaInfo.Id }
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

# Étape 5: Vérifier les métadonnées de la collection
Write-Host "Étape 5: Vérifier les métadonnées de la collection" -ForegroundColor Cyan
$tests5 = @(
    @{ Test = "Les métadonnées contiennent _CreatedBy"; Condition = $collection.Metadata.ContainsKey("_CreatedBy") }
    @{ Test = "Les métadonnées contiennent _CreatedAt"; Condition = $collection.Metadata.ContainsKey("_CreatedAt") }
    @{ Test = "Les métadonnées contiennent _Version"; Condition = $collection.Metadata.ContainsKey("_Version") }
    @{ Test = "Les métadonnées contiennent _LastModified"; Condition = $collection.Metadata.ContainsKey("_LastModified") }
    @{ Test = "Les métadonnées contiennent _ItemCount"; Condition = $collection.Metadata.ContainsKey("_ItemCount") }
    @{ Test = "Le nombre d'éléments dans les métadonnées est correct"; Condition = $collection.Metadata["_ItemCount"] -eq 4 }
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

# Étape 6: Obtenir des statistiques sur la collection
Write-Host "Étape 6: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

$tests6 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques indiquent 4 éléments au total"; Condition = $stats.TotalCount -eq 4 }
    @{ Test = "Les statistiques indiquent 3 éléments valides"; Condition = $stats.ValidCount -eq 3 }
    @{ Test = "Les statistiques indiquent 1 élément invalide"; Condition = $stats.InvalidCount -eq 1 }
    @{ Test = "Les statistiques indiquent une confiance moyenne correcte"; Condition = $stats.AverageConfidence -gt 0 }
    @{ Test = "Les statistiques contiennent la distribution par source"; Condition = $stats.SourceDistribution.Count -eq 4 }
    @{ Test = "Les statistiques contiennent la distribution par état"; Condition = $stats.StateDistribution.Count -eq 2 }
    @{ Test = "Les statistiques contiennent la distribution par type"; Condition = $stats.TypeDistribution.Count -eq 4 }
    @{ Test = "Les statistiques indiquent 1 élément de type ExtractedInfo"; Condition = $stats.TypeDistribution.ContainsKey("ExtractedInfo") -and $stats.TypeDistribution["ExtractedInfo"] -eq 1 }
    @{ Test = "Les statistiques indiquent 1 élément de type TextExtractedInfo"; Condition = $stats.TypeDistribution.ContainsKey("TextExtractedInfo") -and $stats.TypeDistribution["TextExtractedInfo"] -eq 1 }
    @{ Test = "Les statistiques indiquent 1 élément de type StructuredDataExtractedInfo"; Condition = $stats.TypeDistribution.ContainsKey("StructuredDataExtractedInfo") -and $stats.TypeDistribution["StructuredDataExtractedInfo"] -eq 1 }
    @{ Test = "Les statistiques indiquent 1 élément de type MediaExtractedInfo"; Condition = $stats.TypeDistribution.ContainsKey("MediaExtractedInfo") -and $stats.TypeDistribution["MediaExtractedInfo"] -eq 1 }
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

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3a -and $success3b -and $success4 -and $success5 -and $success6

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

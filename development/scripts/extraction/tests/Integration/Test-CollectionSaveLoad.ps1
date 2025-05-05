# Test-CollectionSaveLoad.ps1
# Test d'intégration pour la sauvegarde et le chargement d'une collection complète

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Test du workflow de sauvegarde et chargement d'une collection complète
Write-Host "Test du workflow de sauvegarde et chargement d'une collection complète" -ForegroundColor Cyan

# Étape 1: Créer une collection avec différents types d'informations
Write-Host "Étape 1: Créer une collection avec différents types d'informations" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "TestCollection"

# Créer une information de base
$baseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$baseInfo.ProcessingState = "Processed"
$baseInfo.ConfidenceScore = 75
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "Category" -Value "Base"
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "TestKey" -Value "TestValue"

# Créer une information de texte
$textInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is a test text with special characters: éèàçù" -Language "fr"
$textInfo.ProcessingState = "Processed"
$textInfo.ConfidenceScore = 85
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "Category" -Value "Text"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "WordCount" -Value 10

# Créer une information de données structurées
$dataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data @{
    Name = "Test Product"
    Price = 19.99
    InStock = $true
    Categories = @("Category1", "Category2")
    Specifications = @{
        Weight = "1.5kg"
        Dimensions = "10x20x30cm"
        Color = "Blue"
    }
} -DataFormat "Hashtable"
$dataInfo.ProcessingState = "Processed"
$dataInfo.ConfidenceScore = 90
$dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "Category" -Value "Data"
$dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "DataSource" -Value "Product Catalog"

# Créer une information de média
$mediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "test.jpg" -MediaType "Image"
$mediaInfo.ProcessingState = "Processed"
$mediaInfo.ConfidenceScore = 80
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Category" -Value "Media"
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Resolution" -Value "1920x1080"
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "FileSize" -Value 1024000

# Ajouter les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($baseInfo, $textInfo, $dataInfo, $mediaInfo)

# Vérifier que la collection a été créée correctement
$tests1 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 4 éléments"; Condition = $collection.Items.Count -eq 4 }
    @{ Test = "La collection contient 1 élément de type ExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "ExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection contient 1 élément de type TextExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection contient 1 élément de type StructuredDataExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection contient 1 élément de type MediaExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 1 }
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

# Étape 2: Sérialiser la collection en JSON
Write-Host "Étape 2: Sérialiser la collection en JSON" -ForegroundColor Cyan
$jsonString = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 10

# Vérifier que la sérialisation a fonctionné correctement
$tests2 = @(
    @{ Test = "Le JSON n'est pas null"; Condition = $null -ne $jsonString }
    @{ Test = "Le JSON est une chaîne de caractères"; Condition = $jsonString -is [string] }
    @{ Test = "Le JSON n'est pas vide"; Condition = $jsonString.Length -gt 0 }
    @{ Test = "Le JSON contient le nom de la collection"; Condition = $jsonString -match [regex]::Escape($collection.Name) }
    @{ Test = "Le JSON contient le type de la collection"; Condition = $jsonString -match [regex]::Escape($collection._Type) }
    @{ Test = "Le JSON contient l'ID de l'élément de base"; Condition = $jsonString -match [regex]::Escape($baseInfo.Id) }
    @{ Test = "Le JSON contient l'ID de l'élément de texte"; Condition = $jsonString -match [regex]::Escape($textInfo.Id) }
    @{ Test = "Le JSON contient l'ID de l'élément de données"; Condition = $jsonString -match [regex]::Escape($dataInfo.Id) }
    @{ Test = "Le JSON contient l'ID de l'élément de média"; Condition = $jsonString -match [regex]::Escape($mediaInfo.Id) }
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

# Étape 3: Sauvegarder la collection dans un fichier
Write-Host "Étape 3: Sauvegarder la collection dans un fichier" -ForegroundColor Cyan
$collectionFilePath = Join-Path -Path $testDir -ChildPath "collection.json"
Set-Content -Path $collectionFilePath -Value $jsonString

# Vérifier que le fichier a été créé correctement
$tests3 = @(
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $collectionFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $collectionFilePath).Length -gt 0 }
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

# Étape 4: Charger la collection depuis le fichier
Write-Host "Étape 4: Charger la collection depuis le fichier" -ForegroundColor Cyan
$jsonContent = Get-Content -Path $collectionFilePath -Raw
$loadedCollection = ConvertFrom-ExtractedInfoJson -Json $jsonContent

# Vérifier que le chargement a fonctionné correctement
$tests4 = @(
    @{ Test = "La collection chargée n'est pas nulle"; Condition = $null -ne $loadedCollection }
    @{ Test = "La collection chargée a le même nom"; Condition = $loadedCollection.Name -eq $collection.Name }
    @{ Test = "La collection chargée a le même type"; Condition = $loadedCollection._Type -eq $collection._Type }
    @{ Test = "La collection chargée contient 4 éléments"; Condition = $loadedCollection.Items.Count -eq 4 }
    @{ Test = "La collection chargée contient 1 élément de type ExtractedInfo"; Condition = ($loadedCollection.Items | Where-Object { $_._Type -eq "ExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection chargée contient 1 élément de type TextExtractedInfo"; Condition = ($loadedCollection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection chargée contient 1 élément de type StructuredDataExtractedInfo"; Condition = ($loadedCollection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection chargée contient 1 élément de type MediaExtractedInfo"; Condition = ($loadedCollection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 1 }
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

# Étape 5: Vérifier que les éléments de la collection chargée sont identiques aux originaux
Write-Host "Étape 5: Vérifier que les éléments de la collection chargée sont identiques aux originaux" -ForegroundColor Cyan

# Récupérer les éléments chargés
$loadedBaseInfo = $loadedCollection.Items | Where-Object { $_._Type -eq "ExtractedInfo" } | Select-Object -First 1
$loadedTextInfo = $loadedCollection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" } | Select-Object -First 1
$loadedDataInfo = $loadedCollection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Select-Object -First 1
$loadedMediaInfo = $loadedCollection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" } | Select-Object -First 1

$tests5 = @(
    # Vérification de l'élément de base
    @{ Test = "L'élément de base chargé a le même ID"; Condition = $loadedBaseInfo.Id -eq $baseInfo.Id }
    @{ Test = "L'élément de base chargé a la même source"; Condition = $loadedBaseInfo.Source -eq $baseInfo.Source }
    @{ Test = "L'élément de base chargé a le même extracteur"; Condition = $loadedBaseInfo.ExtractorName -eq $baseInfo.ExtractorName }
    @{ Test = "L'élément de base chargé a le même état de traitement"; Condition = $loadedBaseInfo.ProcessingState -eq $baseInfo.ProcessingState }
    @{ Test = "L'élément de base chargé a le même score de confiance"; Condition = $loadedBaseInfo.ConfidenceScore -eq $baseInfo.ConfidenceScore }
    @{ Test = "L'élément de base chargé a la même métadonnée Category"; Condition = $loadedBaseInfo.Metadata["Category"] -eq $baseInfo.Metadata["Category"] }
    @{ Test = "L'élément de base chargé a la même métadonnée TestKey"; Condition = $loadedBaseInfo.Metadata["TestKey"] -eq $baseInfo.Metadata["TestKey"] }
    
    # Vérification de l'élément de texte
    @{ Test = "L'élément de texte chargé a le même ID"; Condition = $loadedTextInfo.Id -eq $textInfo.Id }
    @{ Test = "L'élément de texte chargé a la même source"; Condition = $loadedTextInfo.Source -eq $textInfo.Source }
    @{ Test = "L'élément de texte chargé a le même extracteur"; Condition = $loadedTextInfo.ExtractorName -eq $textInfo.ExtractorName }
    @{ Test = "L'élément de texte chargé a le même texte"; Condition = $loadedTextInfo.Text -eq $textInfo.Text }
    @{ Test = "L'élément de texte chargé a la même langue"; Condition = $loadedTextInfo.Language -eq $textInfo.Language }
    @{ Test = "L'élément de texte chargé a le même état de traitement"; Condition = $loadedTextInfo.ProcessingState -eq $textInfo.ProcessingState }
    @{ Test = "L'élément de texte chargé a le même score de confiance"; Condition = $loadedTextInfo.ConfidenceScore -eq $textInfo.ConfidenceScore }
    @{ Test = "L'élément de texte chargé a la même métadonnée Category"; Condition = $loadedTextInfo.Metadata["Category"] -eq $textInfo.Metadata["Category"] }
    @{ Test = "L'élément de texte chargé a la même métadonnée WordCount"; Condition = $loadedTextInfo.Metadata["WordCount"] -eq $textInfo.Metadata["WordCount"] }
    
    # Vérification de l'élément de données
    @{ Test = "L'élément de données chargé a le même ID"; Condition = $loadedDataInfo.Id -eq $dataInfo.Id }
    @{ Test = "L'élément de données chargé a la même source"; Condition = $loadedDataInfo.Source -eq $dataInfo.Source }
    @{ Test = "L'élément de données chargé a le même extracteur"; Condition = $loadedDataInfo.ExtractorName -eq $dataInfo.ExtractorName }
    @{ Test = "L'élément de données chargé a le même format de données"; Condition = $loadedDataInfo.DataFormat -eq $dataInfo.DataFormat }
    @{ Test = "L'élément de données chargé a des données non nulles"; Condition = $null -ne $loadedDataInfo.Data }
    @{ Test = "L'élément de données chargé a le même état de traitement"; Condition = $loadedDataInfo.ProcessingState -eq $dataInfo.ProcessingState }
    @{ Test = "L'élément de données chargé a le même score de confiance"; Condition = $loadedDataInfo.ConfidenceScore -eq $dataInfo.ConfidenceScore }
    @{ Test = "L'élément de données chargé a la même métadonnée Category"; Condition = $loadedDataInfo.Metadata["Category"] -eq $dataInfo.Metadata["Category"] }
    @{ Test = "L'élément de données chargé a la même métadonnée DataSource"; Condition = $loadedDataInfo.Metadata["DataSource"] -eq $dataInfo.Metadata["DataSource"] }
    
    # Vérification de l'élément de média
    @{ Test = "L'élément de média chargé a le même ID"; Condition = $loadedMediaInfo.Id -eq $mediaInfo.Id }
    @{ Test = "L'élément de média chargé a la même source"; Condition = $loadedMediaInfo.Source -eq $mediaInfo.Source }
    @{ Test = "L'élément de média chargé a le même extracteur"; Condition = $loadedMediaInfo.ExtractorName -eq $mediaInfo.ExtractorName }
    @{ Test = "L'élément de média chargé a le même chemin de média"; Condition = $loadedMediaInfo.MediaPath -eq $mediaInfo.MediaPath }
    @{ Test = "L'élément de média chargé a le même type de média"; Condition = $loadedMediaInfo.MediaType -eq $mediaInfo.MediaType }
    @{ Test = "L'élément de média chargé a le même état de traitement"; Condition = $loadedMediaInfo.ProcessingState -eq $mediaInfo.ProcessingState }
    @{ Test = "L'élément de média chargé a le même score de confiance"; Condition = $loadedMediaInfo.ConfidenceScore -eq $mediaInfo.ConfidenceScore }
    @{ Test = "L'élément de média chargé a la même métadonnée Category"; Condition = $loadedMediaInfo.Metadata["Category"] -eq $mediaInfo.Metadata["Category"] }
    @{ Test = "L'élément de média chargé a la même métadonnée Resolution"; Condition = $loadedMediaInfo.Metadata["Resolution"] -eq $mediaInfo.Metadata["Resolution"] }
    @{ Test = "L'élément de média chargé a la même métadonnée FileSize"; Condition = $loadedMediaInfo.Metadata["FileSize"] -eq $mediaInfo.Metadata["FileSize"] }
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

# Étape 6: Tester la sauvegarde et le chargement d'une collection avec les fonctions intégrées
Write-Host "Étape 6: Tester la sauvegarde et le chargement d'une collection avec les fonctions intégrées" -ForegroundColor Cyan
$integratedFilePath = Join-Path -Path $testDir -ChildPath "collection_integrated.json"

# Sauvegarder la collection dans un fichier
$saveResult = Save-ExtractedInfoToFile -Info $collection -FilePath $integratedFilePath

# Charger la collection depuis le fichier
$integratedLoadedCollection = Import-ExtractedInfoFromFile -FilePath $integratedFilePath

# Vérifier que les opérations intégrées ont fonctionné correctement
$tests6 = @(
    @{ Test = "La sauvegarde a réussi"; Condition = $saveResult -eq $true }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $integratedFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $integratedFilePath).Length -gt 0 }
    @{ Test = "La collection chargée n'est pas nulle"; Condition = $null -ne $integratedLoadedCollection }
    @{ Test = "La collection chargée a le même nom"; Condition = $integratedLoadedCollection.Name -eq $collection.Name }
    @{ Test = "La collection chargée a le même type"; Condition = $integratedLoadedCollection._Type -eq $collection._Type }
    @{ Test = "La collection chargée contient 4 éléments"; Condition = $integratedLoadedCollection.Items.Count -eq 4 }
    @{ Test = "La collection chargée contient 1 élément de type ExtractedInfo"; Condition = ($integratedLoadedCollection.Items | Where-Object { $_._Type -eq "ExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection chargée contient 1 élément de type TextExtractedInfo"; Condition = ($integratedLoadedCollection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection chargée contient 1 élément de type StructuredDataExtractedInfo"; Condition = ($integratedLoadedCollection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection chargée contient 1 élément de type MediaExtractedInfo"; Condition = ($integratedLoadedCollection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 1 }
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

# Nettoyer les fichiers temporaires
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $success6

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

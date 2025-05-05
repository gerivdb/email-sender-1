# Test-CollectionSerialization.ps1
# Test d'intégration pour la sérialisation d'une collection en JSON

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Test du workflow de sérialisation d'une collection
Write-Host "Test du workflow de sérialisation d'une collection en JSON" -ForegroundColor Cyan

# Étape 1: Créer une collection avec différents types d'informations
Write-Host "Étape 1: Créer une collection avec différents types d'informations" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "TestCollection"

# Créer une information de base
$baseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$baseInfo.ProcessingState = "Processed"
$baseInfo.ConfidenceScore = 75
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "Category" -Value "Base"

# Créer une information de texte
$textInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is a test text" -Language "en"
$textInfo.ProcessingState = "Processed"
$textInfo.ConfidenceScore = 85
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "Category" -Value "Text"

# Créer une information de données structurées
$dataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data @{
    Name = "Test"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$dataInfo.ProcessingState = "Processed"
$dataInfo.ConfidenceScore = 90
$dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "Category" -Value "Data"

# Créer une information de média
$mediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "test.jpg" -MediaType "Image"
$mediaInfo.ProcessingState = "Processed"
$mediaInfo.ConfidenceScore = 80
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Category" -Value "Media"

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
    @{ Test = "Le JSON contient le texte de l'élément de texte"; Condition = $jsonString -match [regex]::Escape($textInfo.Text) }
    @{ Test = "Le JSON contient le chemin de l'élément de média"; Condition = $jsonString -match [regex]::Escape($mediaInfo.MediaPath) }
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

# Étape 3: Sauvegarder le JSON dans un fichier
Write-Host "Étape 3: Sauvegarder le JSON dans un fichier" -ForegroundColor Cyan
$jsonFilePath = Join-Path -Path $testDir -ChildPath "collection.json"
Set-Content -Path $jsonFilePath -Value $jsonString

# Vérifier que le fichier a été créé correctement
$tests3 = @(
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $jsonFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $jsonFilePath).Length -gt 0 }
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

# Étape 4: Désérialiser le JSON en objet
Write-Host "Étape 4: Désérialiser le JSON en objet" -ForegroundColor Cyan
$jsonContent = Get-Content -Path $jsonFilePath -Raw
$deserializedCollection = ConvertFrom-ExtractedInfoJson -Json $jsonContent

# Vérifier que la désérialisation a fonctionné correctement
$tests4 = @(
    @{ Test = "L'objet désérialisé n'est pas null"; Condition = $null -ne $deserializedCollection }
    @{ Test = "L'objet désérialisé est une collection"; Condition = $deserializedCollection._Type -eq "ExtractedInfoCollection" }
    @{ Test = "L'objet désérialisé a le même nom"; Condition = $deserializedCollection.Name -eq $collection.Name }
    @{ Test = "L'objet désérialisé contient 4 éléments"; Condition = $deserializedCollection.Items.Count -eq 4 }
    @{ Test = "L'objet désérialisé contient 1 élément de type ExtractedInfo"; Condition = ($deserializedCollection.Items | Where-Object { $_._Type -eq "ExtractedInfo" }).Count -eq 1 }
    @{ Test = "L'objet désérialisé contient 1 élément de type TextExtractedInfo"; Condition = ($deserializedCollection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 1 }
    @{ Test = "L'objet désérialisé contient 1 élément de type StructuredDataExtractedInfo"; Condition = ($deserializedCollection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 1 }
    @{ Test = "L'objet désérialisé contient 1 élément de type MediaExtractedInfo"; Condition = ($deserializedCollection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 1 }
    @{ Test = "L'élément de base a le même ID"; Condition = ($deserializedCollection.Items | Where-Object { $_.Id -eq $baseInfo.Id }).Count -eq 1 }
    @{ Test = "L'élément de texte a le même ID"; Condition = ($deserializedCollection.Items | Where-Object { $_.Id -eq $textInfo.Id }).Count -eq 1 }
    @{ Test = "L'élément de données a le même ID"; Condition = ($deserializedCollection.Items | Where-Object { $_.Id -eq $dataInfo.Id }).Count -eq 1 }
    @{ Test = "L'élément de média a le même ID"; Condition = ($deserializedCollection.Items | Where-Object { $_.Id -eq $mediaInfo.Id }).Count -eq 1 }
    @{ Test = "L'élément de texte a le même texte"; Condition = ($deserializedCollection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" -and $_.Text -eq $textInfo.Text }).Count -eq 1 }
    @{ Test = "L'élément de média a le même chemin"; Condition = ($deserializedCollection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" -and $_.MediaPath -eq $mediaInfo.MediaPath }).Count -eq 1 }
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

# Étape 5: Tester la sérialisation avec différentes profondeurs
Write-Host "Étape 5: Tester la sérialisation avec différentes profondeurs" -ForegroundColor Cyan

# Sérialiser avec une profondeur limitée
$jsonStringDepth1 = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 1
$jsonStringDepth3 = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 3
$jsonStringDepth5 = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 5

# Vérifier que les sérialisations avec différentes profondeurs ont fonctionné correctement
$tests5 = @(
    @{ Test = "Le JSON avec profondeur 1 n'est pas null"; Condition = $null -ne $jsonStringDepth1 }
    @{ Test = "Le JSON avec profondeur 3 n'est pas null"; Condition = $null -ne $jsonStringDepth3 }
    @{ Test = "Le JSON avec profondeur 5 n'est pas null"; Condition = $null -ne $jsonStringDepth5 }
    @{ Test = "Le JSON avec profondeur 1 est plus court que celui avec profondeur 3"; Condition = $jsonStringDepth1.Length -lt $jsonStringDepth3.Length }
    @{ Test = "Le JSON avec profondeur 3 est plus court ou égal à celui avec profondeur 5"; Condition = $jsonStringDepth3.Length -le $jsonStringDepth5.Length }
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

# Nettoyer les fichiers temporaires
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

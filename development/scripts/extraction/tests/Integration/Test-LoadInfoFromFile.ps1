# Test-LoadInfoFromFile.ps1
# Test d'intégration pour le chargement d'une information depuis un fichier

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Test du workflow de chargement d'une information depuis un fichier
Write-Host "Test du workflow de chargement d'une information depuis un fichier" -ForegroundColor Cyan

# Étape 1: Créer différents types d'informations extraites et les sauvegarder dans des fichiers
Write-Host "Étape 1: Créer différents types d'informations extraites et les sauvegarder dans des fichiers" -ForegroundColor Cyan

# Créer une information de base
$baseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$baseInfo.ProcessingState = "Processed"
$baseInfo.ConfidenceScore = 75
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "Category" -Value "Base"
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "TestKey" -Value "TestValue"
$baseFilePath = Join-Path -Path $testDir -ChildPath "baseInfo.json"
$baseSaveResult = Save-ExtractedInfoToFile -Info $baseInfo -FilePath $baseFilePath

# Créer une information de texte
$textInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is a test text with special characters: éèàçù" -Language "fr"
$textInfo.ProcessingState = "Processed"
$textInfo.ConfidenceScore = 85
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "Category" -Value "Text"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "WordCount" -Value 10
$textFilePath = Join-Path -Path $testDir -ChildPath "textInfo.json"
$textSaveResult = Save-ExtractedInfoToFile -Info $textInfo -FilePath $textFilePath

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
$dataFilePath = Join-Path -Path $testDir -ChildPath "dataInfo.json"
$dataSaveResult = Save-ExtractedInfoToFile -Info $dataInfo -FilePath $dataFilePath

# Créer une information de média
$mediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "test.jpg" -MediaType "Image"
$mediaInfo.ProcessingState = "Processed"
$mediaInfo.ConfidenceScore = 80
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Category" -Value "Media"
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Resolution" -Value "1920x1080"
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "FileSize" -Value 1024000
$mediaFilePath = Join-Path -Path $testDir -ChildPath "mediaInfo.json"
$mediaSaveResult = Save-ExtractedInfoToFile -Info $mediaInfo -FilePath $mediaFilePath

# Vérifier que les fichiers ont été créés correctement
$tests1 = @(
    @{ Test = "Le fichier de l'information de base existe"; Condition = Test-Path -Path $baseFilePath }
    @{ Test = "Le fichier de l'information de texte existe"; Condition = Test-Path -Path $textFilePath }
    @{ Test = "Le fichier de l'information de données existe"; Condition = Test-Path -Path $dataFilePath }
    @{ Test = "Le fichier de l'information de média existe"; Condition = Test-Path -Path $mediaFilePath }
    @{ Test = "Le fichier de l'information de base n'est pas vide"; Condition = (Get-Item -Path $baseFilePath).Length -gt 0 }
    @{ Test = "Le fichier de l'information de texte n'est pas vide"; Condition = (Get-Item -Path $textFilePath).Length -gt 0 }
    @{ Test = "Le fichier de l'information de données n'est pas vide"; Condition = (Get-Item -Path $dataFilePath).Length -gt 0 }
    @{ Test = "Le fichier de l'information de média n'est pas vide"; Condition = (Get-Item -Path $mediaFilePath).Length -gt 0 }
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

# Étape 2: Charger l'information de base depuis le fichier
Write-Host "Étape 2: Charger l'information de base depuis le fichier" -ForegroundColor Cyan
$loadedBaseInfo = Import-ExtractedInfoFromFile -FilePath $baseFilePath

# Vérifier que le chargement a fonctionné correctement
$tests2 = @(
    @{ Test = "L'information chargée n'est pas nulle"; Condition = $null -ne $loadedBaseInfo }
    @{ Test = "L'information chargée a le même ID"; Condition = $loadedBaseInfo.Id -eq $baseInfo.Id }
    @{ Test = "L'information chargée a la même source"; Condition = $loadedBaseInfo.Source -eq $baseInfo.Source }
    @{ Test = "L'information chargée a le même extracteur"; Condition = $loadedBaseInfo.ExtractorName -eq $baseInfo.ExtractorName }
    @{ Test = "L'information chargée a le même état de traitement"; Condition = $loadedBaseInfo.ProcessingState -eq $baseInfo.ProcessingState }
    @{ Test = "L'information chargée a le même score de confiance"; Condition = $loadedBaseInfo.ConfidenceScore -eq $baseInfo.ConfidenceScore }
    @{ Test = "L'information chargée a la même métadonnée Category"; Condition = $loadedBaseInfo.Metadata["Category"] -eq $baseInfo.Metadata["Category"] }
    @{ Test = "L'information chargée a la même métadonnée TestKey"; Condition = $loadedBaseInfo.Metadata["TestKey"] -eq $baseInfo.Metadata["TestKey"] }
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

# Étape 3: Charger l'information de texte depuis le fichier
Write-Host "Étape 3: Charger l'information de texte depuis le fichier" -ForegroundColor Cyan
$loadedTextInfo = Import-ExtractedInfoFromFile -FilePath $textFilePath

# Vérifier que le chargement a fonctionné correctement
$tests3 = @(
    @{ Test = "L'information chargée n'est pas nulle"; Condition = $null -ne $loadedTextInfo }
    @{ Test = "L'information chargée a le même ID"; Condition = $loadedTextInfo.Id -eq $textInfo.Id }
    @{ Test = "L'information chargée a la même source"; Condition = $loadedTextInfo.Source -eq $textInfo.Source }
    @{ Test = "L'information chargée a le même extracteur"; Condition = $loadedTextInfo.ExtractorName -eq $textInfo.ExtractorName }
    @{ Test = "L'information chargée a le même texte"; Condition = $loadedTextInfo.Text -eq $textInfo.Text }
    @{ Test = "L'information chargée a la même langue"; Condition = $loadedTextInfo.Language -eq $textInfo.Language }
    @{ Test = "L'information chargée a le même état de traitement"; Condition = $loadedTextInfo.ProcessingState -eq $textInfo.ProcessingState }
    @{ Test = "L'information chargée a le même score de confiance"; Condition = $loadedTextInfo.ConfidenceScore -eq $textInfo.ConfidenceScore }
    @{ Test = "L'information chargée a la même métadonnée Category"; Condition = $loadedTextInfo.Metadata["Category"] -eq $textInfo.Metadata["Category"] }
    @{ Test = "L'information chargée a la même métadonnée WordCount"; Condition = $loadedTextInfo.Metadata["WordCount"] -eq $textInfo.Metadata["WordCount"] }
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

# Étape 4: Charger l'information de données structurées depuis le fichier
Write-Host "Étape 4: Charger l'information de données structurées depuis le fichier" -ForegroundColor Cyan
$loadedDataInfo = Import-ExtractedInfoFromFile -FilePath $dataFilePath

# Vérifier que le chargement a fonctionné correctement
$tests4 = @(
    @{ Test = "L'information chargée n'est pas nulle"; Condition = $null -ne $loadedDataInfo }
    @{ Test = "L'information chargée a le même ID"; Condition = $loadedDataInfo.Id -eq $dataInfo.Id }
    @{ Test = "L'information chargée a la même source"; Condition = $loadedDataInfo.Source -eq $dataInfo.Source }
    @{ Test = "L'information chargée a le même extracteur"; Condition = $loadedDataInfo.ExtractorName -eq $dataInfo.ExtractorName }
    @{ Test = "L'information chargée a le même format de données"; Condition = $loadedDataInfo.DataFormat -eq $dataInfo.DataFormat }
    @{ Test = "L'information chargée a des données non nulles"; Condition = $null -ne $loadedDataInfo.Data }
    @{ Test = "L'information chargée a le même état de traitement"; Condition = $loadedDataInfo.ProcessingState -eq $dataInfo.ProcessingState }
    @{ Test = "L'information chargée a le même score de confiance"; Condition = $loadedDataInfo.ConfidenceScore -eq $dataInfo.ConfidenceScore }
    @{ Test = "L'information chargée a la même métadonnée Category"; Condition = $loadedDataInfo.Metadata["Category"] -eq $dataInfo.Metadata["Category"] }
    @{ Test = "L'information chargée a la même métadonnée DataSource"; Condition = $loadedDataInfo.Metadata["DataSource"] -eq $dataInfo.Metadata["DataSource"] }
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

# Étape 5: Charger l'information de média depuis le fichier
Write-Host "Étape 5: Charger l'information de média depuis le fichier" -ForegroundColor Cyan
$loadedMediaInfo = Import-ExtractedInfoFromFile -FilePath $mediaFilePath

# Vérifier que le chargement a fonctionné correctement
$tests5 = @(
    @{ Test = "L'information chargée n'est pas nulle"; Condition = $null -ne $loadedMediaInfo }
    @{ Test = "L'information chargée a le même ID"; Condition = $loadedMediaInfo.Id -eq $mediaInfo.Id }
    @{ Test = "L'information chargée a la même source"; Condition = $loadedMediaInfo.Source -eq $mediaInfo.Source }
    @{ Test = "L'information chargée a le même extracteur"; Condition = $loadedMediaInfo.ExtractorName -eq $mediaInfo.ExtractorName }
    @{ Test = "L'information chargée a le même chemin de média"; Condition = $loadedMediaInfo.MediaPath -eq $mediaInfo.MediaPath }
    @{ Test = "L'information chargée a le même type de média"; Condition = $loadedMediaInfo.MediaType -eq $mediaInfo.MediaType }
    @{ Test = "L'information chargée a le même état de traitement"; Condition = $loadedMediaInfo.ProcessingState -eq $mediaInfo.ProcessingState }
    @{ Test = "L'information chargée a le même score de confiance"; Condition = $loadedMediaInfo.ConfidenceScore -eq $mediaInfo.ConfidenceScore }
    @{ Test = "L'information chargée a la même métadonnée Category"; Condition = $loadedMediaInfo.Metadata["Category"] -eq $mediaInfo.Metadata["Category"] }
    @{ Test = "L'information chargée a la même métadonnée Resolution"; Condition = $loadedMediaInfo.Metadata["Resolution"] -eq $mediaInfo.Metadata["Resolution"] }
    @{ Test = "L'information chargée a la même métadonnée FileSize"; Condition = $loadedMediaInfo.Metadata["FileSize"] -eq $mediaInfo.Metadata["FileSize"] }
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

# Étape 6: Tester le chargement d'un fichier inexistant
Write-Host "Étape 6: Tester le chargement d'un fichier inexistant" -ForegroundColor Cyan
$nonExistentFilePath = Join-Path -Path $testDir -ChildPath "nonExistent.json"
$nonExistentSuccess = $false

try {
    $loadedNonExistentInfo = Import-ExtractedInfoFromFile -FilePath $nonExistentFilePath
    Write-Host "  [ÉCHEC] Le chargement d'un fichier inexistant n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] Le chargement d'un fichier inexistant a échoué comme prévu" -ForegroundColor Green
    $nonExistentSuccess = $true
}

# Étape 7: Tester le chargement d'un fichier avec un contenu invalide
Write-Host "Étape 7: Tester le chargement d'un fichier avec un contenu invalide" -ForegroundColor Cyan
$invalidFilePath = Join-Path -Path $testDir -ChildPath "invalid.json"
Set-Content -Path $invalidFilePath -Value "{ This is not valid JSON }"
$invalidSuccess = $false

try {
    $loadedInvalidInfo = Import-ExtractedInfoFromFile -FilePath $invalidFilePath
    Write-Host "  [ÉCHEC] Le chargement d'un fichier avec un contenu invalide n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] Le chargement d'un fichier avec un contenu invalide a échoué comme prévu" -ForegroundColor Green
    $invalidSuccess = $true
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $nonExistentSuccess -and $invalidSuccess

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

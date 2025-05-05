# Test-SaveInfoToFile.ps1
# Test d'intégration pour la sauvegarde d'une information dans un fichier

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Test du workflow de sauvegarde d'une information dans un fichier
Write-Host "Test du workflow de sauvegarde d'une information dans un fichier" -ForegroundColor Cyan

# Étape 1: Créer différents types d'informations extraites
Write-Host "Étape 1: Créer différents types d'informations extraites" -ForegroundColor Cyan

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

# Vérifier que les informations ont été créées correctement
$tests1 = @(
    @{ Test = "L'information de base n'est pas nulle"; Condition = $null -ne $baseInfo }
    @{ Test = "L'information de texte n'est pas nulle"; Condition = $null -ne $textInfo }
    @{ Test = "L'information de données n'est pas nulle"; Condition = $null -ne $dataInfo }
    @{ Test = "L'information de média n'est pas nulle"; Condition = $null -ne $mediaInfo }
    @{ Test = "L'information de base a un ID valide"; Condition = [guid]::TryParse($baseInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de texte a un ID valide"; Condition = [guid]::TryParse($textInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de données a un ID valide"; Condition = [guid]::TryParse($dataInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de média a un ID valide"; Condition = [guid]::TryParse($mediaInfo.Id, [ref][guid]::Empty) }
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

# Étape 2: Sauvegarder l'information de base dans un fichier
Write-Host "Étape 2: Sauvegarder l'information de base dans un fichier" -ForegroundColor Cyan
$baseFilePath = Join-Path -Path $testDir -ChildPath "baseInfo.json"
$baseSaveResult = Save-ExtractedInfoToFile -Info $baseInfo -FilePath $baseFilePath

# Vérifier que la sauvegarde a fonctionné correctement
$tests2 = @(
    @{ Test = "Le résultat de la sauvegarde est vrai"; Condition = $baseSaveResult -eq $true }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $baseFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $baseFilePath).Length -gt 0 }
    @{ Test = "Le contenu du fichier contient l'ID"; Condition = (Get-Content -Path $baseFilePath -Raw) -match [regex]::Escape($baseInfo.Id) }
    @{ Test = "Le contenu du fichier contient la source"; Condition = (Get-Content -Path $baseFilePath -Raw) -match [regex]::Escape($baseInfo.Source) }
    @{ Test = "Le contenu du fichier contient l'extracteur"; Condition = (Get-Content -Path $baseFilePath -Raw) -match [regex]::Escape($baseInfo.ExtractorName) }
    @{ Test = "Le contenu du fichier contient la métadonnée TestKey"; Condition = (Get-Content -Path $baseFilePath -Raw) -match [regex]::Escape("TestKey") -and (Get-Content -Path $baseFilePath -Raw) -match [regex]::Escape("TestValue") }
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

# Étape 3: Sauvegarder l'information de texte dans un fichier
Write-Host "Étape 3: Sauvegarder l'information de texte dans un fichier" -ForegroundColor Cyan
$textFilePath = Join-Path -Path $testDir -ChildPath "textInfo.json"
$textSaveResult = Save-ExtractedInfoToFile -Info $textInfo -FilePath $textFilePath

# Vérifier que la sauvegarde a fonctionné correctement
$tests3 = @(
    @{ Test = "Le résultat de la sauvegarde est vrai"; Condition = $textSaveResult -eq $true }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $textFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $textFilePath).Length -gt 0 }
    @{ Test = "Le contenu du fichier contient l'ID"; Condition = (Get-Content -Path $textFilePath -Raw) -match [regex]::Escape($textInfo.Id) }
    @{ Test = "Le contenu du fichier contient le texte"; Condition = (Get-Content -Path $textFilePath -Raw) -match [regex]::Escape($textInfo.Text) }
    @{ Test = "Le contenu du fichier contient la langue"; Condition = (Get-Content -Path $textFilePath -Raw) -match [regex]::Escape($textInfo.Language) }
    @{ Test = "Le contenu du fichier contient la métadonnée WordCount"; Condition = (Get-Content -Path $textFilePath -Raw) -match [regex]::Escape("WordCount") -and (Get-Content -Path $textFilePath -Raw) -match [regex]::Escape("10") }
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

# Étape 4: Sauvegarder l'information de données structurées dans un fichier
Write-Host "Étape 4: Sauvegarder l'information de données structurées dans un fichier" -ForegroundColor Cyan
$dataFilePath = Join-Path -Path $testDir -ChildPath "dataInfo.json"
$dataSaveResult = Save-ExtractedInfoToFile -Info $dataInfo -FilePath $dataFilePath

# Vérifier que la sauvegarde a fonctionné correctement
$tests4 = @(
    @{ Test = "Le résultat de la sauvegarde est vrai"; Condition = $dataSaveResult -eq $true }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $dataFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $dataFilePath).Length -gt 0 }
    @{ Test = "Le contenu du fichier contient l'ID"; Condition = (Get-Content -Path $dataFilePath -Raw) -match [regex]::Escape($dataInfo.Id) }
    @{ Test = "Le contenu du fichier contient le format des données"; Condition = (Get-Content -Path $dataFilePath -Raw) -match [regex]::Escape($dataInfo.DataFormat) }
    @{ Test = "Le contenu du fichier contient le nom du produit"; Condition = (Get-Content -Path $dataFilePath -Raw) -match [regex]::Escape("Test Product") }
    @{ Test = "Le contenu du fichier contient le prix"; Condition = (Get-Content -Path $dataFilePath -Raw) -match [regex]::Escape("19.99") }
    @{ Test = "Le contenu du fichier contient la métadonnée DataSource"; Condition = (Get-Content -Path $dataFilePath -Raw) -match [regex]::Escape("DataSource") -and (Get-Content -Path $dataFilePath -Raw) -match [regex]::Escape("Product Catalog") }
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

# Étape 5: Sauvegarder l'information de média dans un fichier
Write-Host "Étape 5: Sauvegarder l'information de média dans un fichier" -ForegroundColor Cyan
$mediaFilePath = Join-Path -Path $testDir -ChildPath "mediaInfo.json"
$mediaSaveResult = Save-ExtractedInfoToFile -Info $mediaInfo -FilePath $mediaFilePath

# Vérifier que la sauvegarde a fonctionné correctement
$tests5 = @(
    @{ Test = "Le résultat de la sauvegarde est vrai"; Condition = $mediaSaveResult -eq $true }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $mediaFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $mediaFilePath).Length -gt 0 }
    @{ Test = "Le contenu du fichier contient l'ID"; Condition = (Get-Content -Path $mediaFilePath -Raw) -match [regex]::Escape($mediaInfo.Id) }
    @{ Test = "Le contenu du fichier contient le chemin du média"; Condition = (Get-Content -Path $mediaFilePath -Raw) -match [regex]::Escape($mediaInfo.MediaPath) }
    @{ Test = "Le contenu du fichier contient le type de média"; Condition = (Get-Content -Path $mediaFilePath -Raw) -match [regex]::Escape($mediaInfo.MediaType) }
    @{ Test = "Le contenu du fichier contient la métadonnée Resolution"; Condition = (Get-Content -Path $mediaFilePath -Raw) -match [regex]::Escape("Resolution") -and (Get-Content -Path $mediaFilePath -Raw) -match [regex]::Escape("1920x1080") }
    @{ Test = "Le contenu du fichier contient la métadonnée FileSize"; Condition = (Get-Content -Path $mediaFilePath -Raw) -match [regex]::Escape("FileSize") -and (Get-Content -Path $mediaFilePath -Raw) -match [regex]::Escape("1024000") }
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

# Étape 6: Sauvegarder dans un répertoire inexistant (création automatique)
Write-Host "Étape 6: Sauvegarder dans un répertoire inexistant (création automatique)" -ForegroundColor Cyan
$nestedDir = Join-Path -Path $testDir -ChildPath "Nested\DeepNested"
$nestedFilePath = Join-Path -Path $nestedDir -ChildPath "nestedInfo.json"
$nestedSaveResult = Save-ExtractedInfoToFile -Info $baseInfo -FilePath $nestedFilePath

# Vérifier que la sauvegarde a fonctionné correctement
$tests6 = @(
    @{ Test = "Le résultat de la sauvegarde est vrai"; Condition = $nestedSaveResult -eq $true }
    @{ Test = "Le répertoire a été créé"; Condition = Test-Path -Path $nestedDir -PathType Container }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $nestedFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $nestedFilePath).Length -gt 0 }
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

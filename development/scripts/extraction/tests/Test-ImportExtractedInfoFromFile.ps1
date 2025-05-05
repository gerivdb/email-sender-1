# Test-ImportExtractedInfoFromFile.ps1
# Test de la fonction Import-ExtractedInfoFromFile pour vérifier l'intégrité des données

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer des objets de test
$simpleInfo = New-ExtractedInfo -Source "SimpleSource" -ExtractorName "SimpleExtractor"
$simpleInfo = Add-ExtractedInfoMetadata -Info $simpleInfo -Key "SimpleKey" -Value "SimpleValue"

$textInfo = New-TextExtractedInfo -Source "TextSource" -ExtractorName "TextExtractor" -Text "This is a test text" -Language "en"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "TextKey" -Value "TextValue"

$dataInfo = New-StructuredDataExtractedInfo -Source "DataSource" -ExtractorName "DataExtractor" -Data @{
    Name = "Test"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "DataKey" -Value "DataValue"

# Créer des chemins de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"

# Nettoyer les répertoires de test s'ils existent
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Créer le répertoire de test
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Test 1: Sauvegarder et charger un objet simple
Write-Host "Test 1: Sauvegarder et charger un objet simple" -ForegroundColor Cyan
$filePath1 = Join-Path -Path $testDir -ChildPath "simpleInfo.json"
$saveResult1 = Save-ExtractedInfoToFile -Info $simpleInfo -FilePath $filePath1
$loadedInfo1 = Import-ExtractedInfoFromFile -FilePath $filePath1

$tests1 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $loadedInfo1 }
    @{ Test = "L'ID est correct"; Condition = $loadedInfo1.Id -eq $simpleInfo.Id }
    @{ Test = "La source est correcte"; Condition = $loadedInfo1.Source -eq $simpleInfo.Source }
    @{ Test = "L'extracteur est correct"; Condition = $loadedInfo1.ExtractorName -eq $simpleInfo.ExtractorName }
    @{ Test = "Le type est correct"; Condition = $loadedInfo1._Type -eq $simpleInfo._Type }
    @{ Test = "Les métadonnées contiennent la clé"; Condition = $loadedInfo1.Metadata.ContainsKey("SimpleKey") }
    @{ Test = "La valeur de la métadonnée est correcte"; Condition = $loadedInfo1.Metadata["SimpleKey"] -eq "SimpleValue" }
)

$test1Success = $true
foreach ($test in $tests1) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test1Success = $false
    }
}

# Test 2: Sauvegarder et charger un objet texte
Write-Host "Test 2: Sauvegarder et charger un objet texte" -ForegroundColor Cyan
$filePath2 = Join-Path -Path $testDir -ChildPath "textInfo.json"
$saveResult2 = Save-ExtractedInfoToFile -Info $textInfo -FilePath $filePath2
$loadedInfo2 = Import-ExtractedInfoFromFile -FilePath $filePath2

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $loadedInfo2 }
    @{ Test = "L'ID est correct"; Condition = $loadedInfo2.Id -eq $textInfo.Id }
    @{ Test = "La source est correcte"; Condition = $loadedInfo2.Source -eq $textInfo.Source }
    @{ Test = "L'extracteur est correct"; Condition = $loadedInfo2.ExtractorName -eq $textInfo.ExtractorName }
    @{ Test = "Le type est correct"; Condition = $loadedInfo2._Type -eq $textInfo._Type }
    @{ Test = "Le texte est correct"; Condition = $loadedInfo2.Text -eq $textInfo.Text }
    @{ Test = "La langue est correcte"; Condition = $loadedInfo2.Language -eq $textInfo.Language }
    @{ Test = "Les métadonnées contiennent la clé"; Condition = $loadedInfo2.Metadata.ContainsKey("TextKey") }
    @{ Test = "La valeur de la métadonnée est correcte"; Condition = $loadedInfo2.Metadata["TextKey"] -eq "TextValue" }
)

$test2Success = $true
foreach ($test in $tests2) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test2Success = $false
    }
}

# Test 3: Sauvegarder et charger un objet données structurées
Write-Host "Test 3: Sauvegarder et charger un objet données structurées" -ForegroundColor Cyan
$filePath3 = Join-Path -Path $testDir -ChildPath "dataInfo.json"
$saveResult3 = Save-ExtractedInfoToFile -Info $dataInfo -FilePath $filePath3
$loadedInfo3 = Import-ExtractedInfoFromFile -FilePath $filePath3

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $loadedInfo3 }
    @{ Test = "L'ID est correct"; Condition = $loadedInfo3.Id -eq $dataInfo.Id }
    @{ Test = "La source est correcte"; Condition = $loadedInfo3.Source -eq $dataInfo.Source }
    @{ Test = "L'extracteur est correct"; Condition = $loadedInfo3.ExtractorName -eq $dataInfo.ExtractorName }
    @{ Test = "Le type est correct"; Condition = $loadedInfo3._Type -eq $dataInfo._Type }
    @{ Test = "Le format des données est correct"; Condition = $loadedInfo3.DataFormat -eq $dataInfo.DataFormat }
    @{ Test = "Les données ne sont pas nulles"; Condition = $null -ne $loadedInfo3.Data }
    @{ Test = "Les métadonnées contiennent la clé"; Condition = $loadedInfo3.Metadata.ContainsKey("DataKey") }
    @{ Test = "La valeur de la métadonnée est correcte"; Condition = $loadedInfo3.Metadata["DataKey"] -eq "DataValue" }
)

$test3Success = $true
foreach ($test in $tests3) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test3Success = $false
    }
}

# Test 4: Charger un fichier inexistant
Write-Host "Test 4: Charger un fichier inexistant" -ForegroundColor Cyan
$nonExistentPath = Join-Path -Path $testDir -ChildPath "nonexistent.json"
$nonExistentSuccess = $false

try {
    $loadedInfo4 = Import-ExtractedInfoFromFile -FilePath $nonExistentPath
    Write-Host "  [ÉCHEC] Le chargement d'un fichier inexistant n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] Le chargement d'un fichier inexistant a échoué comme prévu" -ForegroundColor Green
    $nonExistentSuccess = $true
}

# Test 5: Charger un fichier avec un format non supporté
Write-Host "Test 5: Charger un fichier avec un format non supporté" -ForegroundColor Cyan
$unsupportedPath = Join-Path -Path $testDir -ChildPath "unsupported.txt"
Set-Content -Path $unsupportedPath -Value "This is not a JSON file"
$unsupportedSuccess = $false

try {
    $loadedInfo5 = Import-ExtractedInfoFromFile -FilePath $unsupportedPath -Format "Xml"
    Write-Host "  [ÉCHEC] Le chargement avec un format non supporté n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] Le chargement avec un format non supporté a échoué comme prévu" -ForegroundColor Green
    $unsupportedSuccess = $true
}

# Test 6: Charger un fichier JSON invalide
Write-Host "Test 6: Charger un fichier JSON invalide" -ForegroundColor Cyan
$invalidJsonPath = Join-Path -Path $testDir -ChildPath "invalid.json"
Set-Content -Path $invalidJsonPath -Value "{ This is not valid JSON }"
$invalidJsonSuccess = $false

try {
    $loadedInfo6 = Import-ExtractedInfoFromFile -FilePath $invalidJsonPath
    Write-Host "  [ÉCHEC] Le chargement d'un JSON invalide n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] Le chargement d'un JSON invalide a échoué comme prévu" -ForegroundColor Green
    $invalidJsonSuccess = $true
}

# Nettoyer les répertoires de test
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $nonExistentSuccess -and $unsupportedSuccess -and $invalidJsonSuccess

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

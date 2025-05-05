# Test-ConvertFromExtractedInfoJson.ps1
# Test de la fonction ConvertFrom-ExtractedInfoJson pour différentes structures

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer des objets de test
# Objet simple
$simpleInfo = New-ExtractedInfo -Source "SimpleSource" -ExtractorName "SimpleExtractor"
$simpleInfo = Add-ExtractedInfoMetadata -Info $simpleInfo -Key "SimpleKey" -Value "SimpleValue"

# Objet texte
$textInfo = New-TextExtractedInfo -Source "TextSource" -ExtractorName "TextExtractor" -Text "This is a test text" -Language "en"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "TextKey" -Value "TextValue"

# Objet données structurées
$dataInfo = New-StructuredDataExtractedInfo -Source "DataSource" -ExtractorName "DataExtractor" -Data @{
    Name = "Test"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "DataKey" -Value "DataValue"

# Collection
$collection = New-ExtractedInfoCollection -Name "TestCollection"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($simpleInfo, $textInfo, $dataInfo)

# Convertir les objets en JSON
$simpleJson = ConvertTo-ExtractedInfoJson -InputObject $simpleInfo
$textJson = ConvertTo-ExtractedInfoJson -InputObject $textInfo
$dataJson = ConvertTo-ExtractedInfoJson -InputObject $dataInfo
$collectionJson = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 10

# Test 1: Convertir un JSON d'objet simple en objet
Write-Host "Test 1: Convertir un JSON d'objet simple en objet" -ForegroundColor Cyan
$simpleObj = ConvertFrom-ExtractedInfoJson -Json $simpleJson

$tests1 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $simpleObj }
    @{ Test = "L'ID est correct"; Condition = $simpleObj.Id -eq $simpleInfo.Id }
    @{ Test = "La source est correcte"; Condition = $simpleObj.Source -eq $simpleInfo.Source }
    @{ Test = "L'extracteur est correct"; Condition = $simpleObj.ExtractorName -eq $simpleInfo.ExtractorName }
    @{ Test = "Le type est correct"; Condition = $simpleObj._Type -eq $simpleInfo._Type }
    @{ Test = "Les métadonnées contiennent la clé"; Condition = $simpleObj.Metadata.ContainsKey("SimpleKey") }
    @{ Test = "La valeur de la métadonnée est correcte"; Condition = $simpleObj.Metadata["SimpleKey"] -eq "SimpleValue" }
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

# Test 2: Convertir un JSON d'objet texte en objet
Write-Host "Test 2: Convertir un JSON d'objet texte en objet" -ForegroundColor Cyan
$textObj = ConvertFrom-ExtractedInfoJson -Json $textJson

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $textObj }
    @{ Test = "L'ID est correct"; Condition = $textObj.Id -eq $textInfo.Id }
    @{ Test = "La source est correcte"; Condition = $textObj.Source -eq $textInfo.Source }
    @{ Test = "L'extracteur est correct"; Condition = $textObj.ExtractorName -eq $textInfo.ExtractorName }
    @{ Test = "Le type est correct"; Condition = $textObj._Type -eq $textInfo._Type }
    @{ Test = "Le texte est correct"; Condition = $textObj.Text -eq $textInfo.Text }
    @{ Test = "La langue est correcte"; Condition = $textObj.Language -eq $textInfo.Language }
    @{ Test = "Les métadonnées contiennent la clé"; Condition = $textObj.Metadata.ContainsKey("TextKey") }
    @{ Test = "La valeur de la métadonnée est correcte"; Condition = $textObj.Metadata["TextKey"] -eq "TextValue" }
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

# Test 3: Convertir un JSON d'objet données structurées en objet
Write-Host "Test 3: Convertir un JSON d'objet données structurées en objet" -ForegroundColor Cyan
$dataObj = ConvertFrom-ExtractedInfoJson -Json $dataJson

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $dataObj }
    @{ Test = "L'ID est correct"; Condition = $dataObj.Id -eq $dataInfo.Id }
    @{ Test = "La source est correcte"; Condition = $dataObj.Source -eq $dataInfo.Source }
    @{ Test = "L'extracteur est correct"; Condition = $dataObj.ExtractorName -eq $dataInfo.ExtractorName }
    @{ Test = "Le type est correct"; Condition = $dataObj._Type -eq $dataInfo._Type }
    @{ Test = "Le format des données est correct"; Condition = $dataObj.DataFormat -eq $dataInfo.DataFormat }
    @{ Test = "Les données ne sont pas nulles"; Condition = $null -ne $dataObj.Data }
    @{ Test = "Les métadonnées contiennent la clé"; Condition = $dataObj.Metadata.ContainsKey("DataKey") }
    @{ Test = "La valeur de la métadonnée est correcte"; Condition = $dataObj.Metadata["DataKey"] -eq "DataValue" }
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

# Test 4: Convertir un JSON de collection en objet
Write-Host "Test 4: Convertir un JSON de collection en objet" -ForegroundColor Cyan
$collectionObj = ConvertFrom-ExtractedInfoJson -Json $collectionJson

$tests4 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $collectionObj }
    @{ Test = "Le nom est correct"; Condition = $collectionObj.Name -eq $collection.Name }
    @{ Test = "Le type est correct"; Condition = $collectionObj._Type -eq $collection._Type }
    @{ Test = "Les éléments ne sont pas nuls"; Condition = $null -ne $collectionObj.Items }
    @{ Test = "Le nombre d'éléments est correct"; Condition = $collectionObj.Items.Count -eq $collection.Items.Count }
    @{ Test = "Les métadonnées ne sont pas nulles"; Condition = $null -ne $collectionObj.Metadata }
    @{ Test = "Les métadonnées contiennent _ItemCount"; Condition = $collectionObj.Metadata.ContainsKey("_ItemCount") }
    @{ Test = "La valeur de _ItemCount est correcte"; Condition = $collectionObj.Metadata["_ItemCount"] -eq $collection.Items.Count }
)

$test4Success = $true
foreach ($test in $tests4) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test4Success = $false
    }
}

# Test 5: Convertir un JSON invalide
Write-Host "Test 5: Convertir un JSON invalide" -ForegroundColor Cyan
$invalidJson = "{ This is not valid JSON }"
$invalidSuccess = $false

try {
    $invalidObj = ConvertFrom-ExtractedInfoJson -Json $invalidJson
    Write-Host "  [ÉCHEC] La conversion d'un JSON invalide n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] La conversion d'un JSON invalide a échoué comme prévu" -ForegroundColor Green
    $invalidSuccess = $true
}

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and $invalidSuccess

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

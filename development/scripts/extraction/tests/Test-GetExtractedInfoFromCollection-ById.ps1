# Test-GetExtractedInfoFromCollection-ById.ps1
# Test de la fonction Get-ExtractedInfoFromCollection par ID

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer une collection pour les tests
$collection = New-ExtractedInfoCollection -Name "TestCollection"

# Créer plusieurs informations extraites pour les tests
$info1 = New-ExtractedInfo -Source "TestSource1" -ExtractorName "TestExtractor1"
$info1 = Add-ExtractedInfoMetadata -Info $info1 -Key "TestKey1" -Value "TestValue1"

$info2 = New-TextExtractedInfo -Source "TestSource2" -ExtractorName "TestExtractor2" -Text "Test text" -Language "en"
$info2 = Add-ExtractedInfoMetadata -Info $info2 -Key "TestKey2" -Value "TestValue2"

$info3 = New-StructuredDataExtractedInfo -Source "TestSource3" -ExtractorName "TestExtractor3" -Data @{Name = "Test"; Value = 123} -DataFormat "Hashtable"
$info3 = Add-ExtractedInfoMetadata -Info $info3 -Key "TestKey3" -Value "TestValue3"

# Ajouter les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($info1, $info2, $info3)

# Test 1: Récupérer une information par ID existant
Write-Host "Test 1: Récupérer une information par ID existant" -ForegroundColor Cyan
$retrievedInfo1 = Get-ExtractedInfoFromCollection -Collection $collection -Id $info1.Id

$tests1 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $retrievedInfo1 }
    @{ Test = "Le résultat est un tableau"; Condition = $retrievedInfo1 -is [array] }
    @{ Test = "Le tableau contient un seul élément"; Condition = $retrievedInfo1.Count -eq 1 }
    @{ Test = "L'ID de l'élément récupéré est correct"; Condition = $retrievedInfo1[0].Id -eq $info1.Id }
    @{ Test = "La source de l'élément récupéré est correcte"; Condition = $retrievedInfo1[0].Source -eq $info1.Source }
    @{ Test = "L'extracteur de l'élément récupéré est correct"; Condition = $retrievedInfo1[0].ExtractorName -eq $info1.ExtractorName }
    @{ Test = "Les métadonnées de l'élément récupéré sont correctes"; Condition = $retrievedInfo1[0].Metadata["TestKey1"] -eq "TestValue1" }
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

# Test 2: Récupérer une information par ID inexistant
Write-Host "Test 2: Récupérer une information par ID inexistant" -ForegroundColor Cyan
$nonExistentId = [guid]::NewGuid().ToString()
$retrievedInfo2 = Get-ExtractedInfoFromCollection -Collection $collection -Id $nonExistentId

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $retrievedInfo2 }
    @{ Test = "Le résultat est un tableau"; Condition = $retrievedInfo2 -is [array] }
    @{ Test = "Le tableau est vide"; Condition = $retrievedInfo2.Count -eq 0 }
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

# Test 3: Récupérer une information par ID d'un type spécifique
Write-Host "Test 3: Récupérer une information par ID d'un type spécifique" -ForegroundColor Cyan
$retrievedInfo3 = Get-ExtractedInfoFromCollection -Collection $collection -Id $info2.Id

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $retrievedInfo3 }
    @{ Test = "Le résultat est un tableau"; Condition = $retrievedInfo3 -is [array] }
    @{ Test = "Le tableau contient un seul élément"; Condition = $retrievedInfo3.Count -eq 1 }
    @{ Test = "L'ID de l'élément récupéré est correct"; Condition = $retrievedInfo3[0].Id -eq $info2.Id }
    @{ Test = "Le type de l'élément récupéré est correct"; Condition = $retrievedInfo3[0]._Type -eq "TextExtractedInfo" }
    @{ Test = "Le texte de l'élément récupéré est correct"; Condition = $retrievedInfo3[0].Text -eq "Test text" }
    @{ Test = "La langue de l'élément récupéré est correcte"; Condition = $retrievedInfo3[0].Language -eq "en" }
    @{ Test = "Les métadonnées de l'élément récupéré sont correctes"; Condition = $retrievedInfo3[0].Metadata["TestKey2"] -eq "TestValue2" }
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

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

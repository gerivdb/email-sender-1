<#
.SYNOPSIS
    Test des fonctions de base du module ExtractedInfo.
.DESCRIPTION
    VÃ©rifie le bon fonctionnement des fonctions de base et de collection.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModule.psm1"
Import-Module $modulePath -Force

# Fonction pour exÃ©cuter un test
function Test-Feature {
    param (
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Test: $Name" -ForegroundColor Cyan
    try {
        & $Test
        Write-Host "  [SUCCÃˆS]" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  [Ã‰CHEC] $_" -ForegroundColor Red
        return $false
    }
}

# Compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: CrÃ©ation d'une information de base
$totalTests++
$result = Test-Feature -Name "CrÃ©ation d'une information de base" -Test {
    $info = New-BaseExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
    if ($info.Source -ne "TestSource") {
        throw "La source n'est pas correcte"
    }
    if ($info.ExtractorName -ne "TestExtractor") {
        throw "Le nom de l'extracteur n'est pas correct"
    }
    if ($info._Type -ne "BaseExtractedInfo") {
        throw "Le type n'est pas correct"
    }
}
if ($result) { $passedTests++ }

# Test 2: Gestion des mÃ©tadonnÃ©es
$totalTests++
$result = Test-Feature -Name "Gestion des mÃ©tadonnÃ©es" -Test {
    $info = New-BaseExtractedInfo
    $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
    $value = Get-ExtractedInfoMetadata -Info $info -Key "TestKey"
    if ($value -ne "TestValue") {
        throw "La valeur de la mÃ©tadonnÃ©e n'est pas correcte"
    }
    $info = Remove-ExtractedInfoMetadata -Info $info -Key "TestKey"
    $value = Get-ExtractedInfoMetadata -Info $info -Key "TestKey"
    if ($null -ne $value) {
        throw "La mÃ©tadonnÃ©e n'a pas Ã©tÃ© supprimÃ©e"
    }
}
if ($result) { $passedTests++ }

# Test 3: Obtention du rÃ©sumÃ©
$totalTests++
$result = Test-Feature -Name "Obtention du rÃ©sumÃ©" -Test {
    $info = New-BaseExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
    $summary = Get-ExtractedInfoSummary -Info $info
    if ($summary -notmatch "TestSource") {
        throw "Le rÃ©sumÃ© ne contient pas la source"
    }
}
if ($result) { $passedTests++ }

# Test 4: Copie d'une information
$totalTests++
$result = Test-Feature -Name "Copie d'une information" -Test {
    $info = New-BaseExtractedInfo -Source "TestSource"
    $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
    $copy = Copy-ExtractedInfo -Info $info
    if ($copy.Source -ne "TestSource") {
        throw "La source n'a pas Ã©tÃ© copiÃ©e"
    }
    $value = Get-ExtractedInfoMetadata -Info $copy -Key "TestKey"
    if ($value -ne "TestValue") {
        throw "La mÃ©tadonnÃ©e n'a pas Ã©tÃ© copiÃ©e"
    }
    if ($copy.Id -eq $info.Id) {
        throw "L'ID n'a pas Ã©tÃ© rÃ©gÃ©nÃ©rÃ©"
    }
}
if ($result) { $passedTests++ }

# Test 5: CrÃ©ation d'une collection
$totalTests++
$result = Test-Feature -Name "CrÃ©ation d'une collection" -Test {
    $collection = New-ExtractedInfoCollection -Name "TestCollection"
    if ($collection.Name -ne "TestCollection") {
        throw "Le nom de la collection n'est pas correct"
    }
    if ($collection._Type -ne "ExtractedInfoCollection") {
        throw "Le type n'est pas correct"
    }
}
if ($result) { $passedTests++ }

# Test 6: Ajout d'informations Ã  une collection
$totalTests++
$result = Test-Feature -Name "Ajout d'informations Ã  une collection" -Test {
    $collection = New-ExtractedInfoCollection
    $info1 = New-BaseExtractedInfo -Source "Source1"
    $info2 = New-BaseExtractedInfo -Source "Source2"
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1, $info2
    if ($collection.Items.Count -ne 2) {
        throw "Le nombre d'Ã©lÃ©ments dans la collection n'est pas correct"
    }
}
if ($result) { $passedTests++ }

# Test 7: RÃ©cupÃ©ration d'informations d'une collection
$totalTests++
$result = Test-Feature -Name "RÃ©cupÃ©ration d'informations d'une collection" -Test {
    $collection = New-ExtractedInfoCollection
    $info1 = New-BaseExtractedInfo -Source "Source1"
    $info2 = New-BaseExtractedInfo -Source "Source2"
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1, $info2
    $items = Get-ExtractedInfoFromCollection -Collection $collection -Source "Source1"
    if ($items.Count -ne 1 -or $items[0].Source -ne "Source1") {
        throw "La rÃ©cupÃ©ration par source a Ã©chouÃ©"
    }
    $items = Get-ExtractedInfoFromCollection -Collection $collection -Id $info2.Id
    if ($items.Count -ne 1 -or $items[0].Id -ne $info2.Id) {
        throw "La rÃ©cupÃ©ration par ID a Ã©chouÃ©"
    }
}
if ($result) { $passedTests++ }

# Test 8: Suppression d'informations d'une collection
$totalTests++
$result = Test-Feature -Name "Suppression d'informations d'une collection" -Test {
    $collection = New-ExtractedInfoCollection
    $info1 = New-BaseExtractedInfo -Source "Source1"
    $info2 = New-BaseExtractedInfo -Source "Source2"
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1, $info2
    $result = Remove-ExtractedInfoFromCollection -Collection $collection -Id $info1.Id
    if (-not $result) {
        throw "La suppression a Ã©chouÃ©"
    }
    if ($collection.Items.Count -ne 1) {
        throw "Le nombre d'Ã©lÃ©ments aprÃ¨s suppression n'est pas correct"
    }
    if ($collection.Items[0].Id -ne $info2.Id) {
        throw "Le mauvais Ã©lÃ©ment a Ã©tÃ© supprimÃ©"
    }
}
if ($result) { $passedTests++ }

# Test 9: Statistiques d'une collection
$totalTests++
$result = Test-Feature -Name "Statistiques d'une collection" -Test {
    $collection = New-ExtractedInfoCollection -Name "TestStats"
    $info1 = New-BaseExtractedInfo -Source "Source1"
    $info1.IsValid = $true
    $info1.ConfidenceScore = 80
    $info2 = New-BaseExtractedInfo -Source "Source2"
    $info2.IsValid = $false
    $info2.ConfidenceScore = 40
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1, $info2
    $stats = Get-ExtractedInfoCollectionStatistics -Collection $collection
    if ($stats.TotalCount -ne 2) {
        throw "Le nombre total d'Ã©lÃ©ments n'est pas correct"
    }
    if ($stats.ValidCount -ne 1) {
        throw "Le nombre d'Ã©lÃ©ments valides n'est pas correct"
    }
    if ($stats.InvalidCount -ne 1) {
        throw "Le nombre d'Ã©lÃ©ments invalides n'est pas correct"
    }
    if ($stats.AverageConfidence -ne 60) {
        throw "La confiance moyenne n'est pas correcte"
    }
}
if ($result) { $passedTests++ }

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Yellow
Write-Host "  Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor Yellow
Write-Host "  Tests rÃ©ussis: $passedTests" -ForegroundColor Green
if ($passedTests -lt $totalTests) {
    Write-Host "  Tests Ã©chouÃ©s: $($totalTests - $passedTests)" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  Tous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
}

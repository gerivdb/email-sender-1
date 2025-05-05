<#
.SYNOPSIS
    Tests simples pour les modÃ¨les d'informations extraites.
.DESCRIPTION
    VÃ©rifie le bon fonctionnement des classes de base, des interfaces
    et des mÃ©canismes de validation et de conversion.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$modelsPath = Join-Path -Path $rootPath -ChildPath "models"
$interfacesPath = Join-Path -Path $rootPath -ChildPath "interfaces"
$convertersPath = Join-Path -Path $rootPath -ChildPath "converters"

# Importer les classes de base
. "$modelsPath\BaseExtractedInfo.ps1"
. "$modelsPath\ExtractedInfoCollection.ps1"

# Importer les interfaces
. "$interfacesPath\ISerializable.ps1"
. "$interfacesPath\IValidatable.ps1"

# Importer les classes de sÃ©rialisation et validation
. "$modelsPath\SerializableExtractedInfo.ps1"
. "$modelsPath\ValidationRule.ps1"
. "$modelsPath\ValidatableExtractedInfo.ps1"

# Importer les classes spÃ©cifiques
. "$modelsPath\TextExtractedInfo.ps1"
. "$modelsPath\StructuredDataExtractedInfo.ps1"
. "$modelsPath\MediaExtractedInfo.ps1"

# Importer les convertisseurs
. "$convertersPath\FormatConverter.ps1"
. "$convertersPath\ExtractedInfoConverter.ps1"

# CrÃ©er un dossier temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ExtractedInfoTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory | Out-Null
}

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
    $info = [BaseExtractedInfo]::new("TestSource", "TestExtractor")
    if ($info.Source -ne "TestSource") {
        throw "La source n'est pas correcte"
    }
    if ($info.ExtractorName -ne "TestExtractor") {
        throw "Le nom de l'extracteur n'est pas correct"
    }
}
if ($result) { $passedTests++ }

# Test 2: Gestion des mÃ©tadonnÃ©es
$totalTests++
$result = Test-Feature -Name "Gestion des mÃ©tadonnÃ©es" -Test {
    $info = [BaseExtractedInfo]::new()
    $info.AddMetadata("TestKey", "TestValue")
    if (-not $info.HasMetadata("TestKey")) {
        throw "La mÃ©tadonnÃ©e n'a pas Ã©tÃ© ajoutÃ©e"
    }
    if ($info.GetMetadata("TestKey") -ne "TestValue") {
        throw "La valeur de la mÃ©tadonnÃ©e n'est pas correcte"
    }
    $info.RemoveMetadata("TestKey")
    if ($info.HasMetadata("TestKey")) {
        throw "La mÃ©tadonnÃ©e n'a pas Ã©tÃ© supprimÃ©e"
    }
}
if ($result) { $passedTests++ }

# Test 3: Collection d'informations
$totalTests++
$result = Test-Feature -Name "Collection d'informations" -Test {
    $collection = [ExtractedInfoCollection]::new("TestCollection")
    $info1 = [BaseExtractedInfo]::new("Source1")
    $info2 = [BaseExtractedInfo]::new("Source2")
    
    $collection.Add($info1)
    $collection.Add($info2)
    
    if ($collection.Count() -ne 2) {
        throw "Le nombre d'Ã©lÃ©ments dans la collection n'est pas correct"
    }
    
    $filtered = $collection.FilterBySource("Source1")
    if ($filtered.Count -ne 1 -or $filtered[0].Source -ne "Source1") {
        throw "Le filtrage par source ne fonctionne pas correctement"
    }
}
if ($result) { $passedTests++ }

# Test 4: SÃ©rialisation en JSON
$totalTests++
$result = Test-Feature -Name "SÃ©rialisation en JSON" -Test {
    $info = [SerializableExtractedInfo]::new("TestSource", "TestExtractor")
    $info.AddMetadata("TestKey", "TestValue")
    
    $json = $info.ToJson()
    if ([string]::IsNullOrEmpty($json)) {
        throw "La sÃ©rialisation JSON a Ã©chouÃ©"
    }
    
    $newInfo = [SerializableExtractedInfo]::new()
    $newInfo.FromJson($json)
    
    if ($newInfo.Source -ne "TestSource" -or $newInfo.ExtractorName -ne "TestExtractor") {
        throw "La dÃ©sÃ©rialisation JSON a Ã©chouÃ©"
    }
    
    if ($newInfo.GetMetadata("TestKey") -ne "TestValue") {
        throw "Les mÃ©tadonnÃ©es n'ont pas Ã©tÃ© correctement dÃ©sÃ©rialisÃ©es"
    }
}
if ($result) { $passedTests++ }

# Test 5: Validation des donnÃ©es
$totalTests++
$result = Test-Feature -Name "Validation des donnÃ©es" -Test {
    $info = [ValidatableExtractedInfo]::new("TestSource")
    $info.ExtractedAt = [datetime]::Now.AddDays(-1)
    $info.ProcessingState = "Raw"
    $info.ConfidenceScore = 75
    
    $valid = $info.Validate()
    if (-not $valid -or -not $info.IsValid) {
        throw "La validation a Ã©chouÃ© alors que les donnÃ©es sont valides"
    }
    
    $info.ProcessingState = "InvalidState"
    $valid = $info.Validate()
    if ($valid -or $info.IsValid) {
        throw "La validation a rÃ©ussi alors que les donnÃ©es sont invalides"
    }
    
    $errors = $info.GetValidationErrors()
    if ($errors.Count -eq 0) {
        throw "Aucune erreur de validation n'a Ã©tÃ© dÃ©tectÃ©e"
    }
}
if ($result) { $passedTests++ }

# Test 6: Informations textuelles
$totalTests++
$result = Test-Feature -Name "Informations textuelles" -Test {
    $text = "Ceci est un texte de test pour vÃ©rifier les fonctionnalitÃ©s d'extraction d'informations textuelles."
    $info = [TextExtractedInfo]::new("TestSource", "TestExtractor", $text)
    
    if ($info.Text -ne $text) {
        throw "Le texte n'a pas Ã©tÃ© correctement assignÃ©"
    }
    
    if ($info.CharacterCount -eq 0 -or $info.WordCount -eq 0) {
        throw "Les statistiques du texte n'ont pas Ã©tÃ© calculÃ©es"
    }
    
    $summary = $info.GenerateSummary(20)
    if ([string]::IsNullOrEmpty($summary)) {
        throw "Le rÃ©sumÃ© n'a pas Ã©tÃ© gÃ©nÃ©rÃ©"
    }
    
    $keywords = $info.ExtractKeywords(3)
    if ($keywords.Count -eq 0) {
        throw "Les mots-clÃ©s n'ont pas Ã©tÃ© extraits"
    }
}
if ($result) { $passedTests++ }

# Test 7: Informations structurÃ©es
$totalTests++
$result = Test-Feature -Name "Informations structurÃ©es" -Test {
    $data = @{
        Name = "Test"
        Value = 123
        IsActive = $true
        Nested = @{
            SubKey = "SubValue"
        }
    }
    
    $info = [StructuredDataExtractedInfo]::new("TestSource", "TestExtractor", $data)
    
    if ($info.DataItemCount -ne 4) {
        throw "Le nombre d'Ã©lÃ©ments dans les donnÃ©es n'est pas correct"
    }
    
    if (-not $info.IsNested) {
        throw "La dÃ©tection des donnÃ©es imbriquÃ©es a Ã©chouÃ©"
    }
    
    if ($info.MaxDepth -lt 2) {
        throw "La profondeur maximale n'a pas Ã©tÃ© correctement calculÃ©e"
    }
    
    $schema = $info.GenerateSchema()
    if ([string]::IsNullOrEmpty($schema)) {
        throw "Le schÃ©ma n'a pas Ã©tÃ© gÃ©nÃ©rÃ©"
    }
    
    if ($info.GetValue("Name") -ne "Test") {
        throw "La rÃ©cupÃ©ration de valeur a Ã©chouÃ©"
    }
    
    $info.SetValue("NewKey", "NewValue")
    if ($info.GetValue("NewKey") -ne "NewValue") {
        throw "L'ajout de valeur a Ã©chouÃ©"
    }
}
if ($result) { $passedTests++ }

# Test 8: Conversion entre formats
$totalTests++
$result = Test-Feature -Name "Conversion entre formats" -Test {
    $obj = @{
        Name = "Test"
        Value = 123
        IsActive = $true
    }
    
    $json = [FormatConverter]::ToJson($obj)
    if ([string]::IsNullOrEmpty($json)) {
        throw "La conversion en JSON a Ã©chouÃ©"
    }
    
    $xml = [FormatConverter]::ConvertJsonToXml($json)
    if ([string]::IsNullOrEmpty($xml)) {
        throw "La conversion de JSON en XML a Ã©chouÃ©"
    }
    
    $newJson = [FormatConverter]::ConvertXmlToJson($xml)
    if ([string]::IsNullOrEmpty($newJson)) {
        throw "La conversion de XML en JSON a Ã©chouÃ©"
    }
    
    $newObj = ConvertFrom-Json -InputObject $newJson
    if ($newObj.Name -ne "Test" -or $newObj.Value -ne 123) {
        throw "Les donnÃ©es ont Ã©tÃ© altÃ©rÃ©es lors des conversions"
    }
}
if ($result) { $passedTests++ }

# Test 9: Conversion entre types d'informations
$totalTests++
$result = Test-Feature -Name "Conversion entre types d'informations" -Test {
    $base = [BaseExtractedInfo]::new("TestSource", "TestExtractor")
    $base.AddMetadata("TestKey", "TestValue")
    
    $text = [ExtractedInfoConverter]::ToTextInfo($base, "Ceci est un texte de test.")
    if ($text.Source -ne "TestSource" -or $text.Text -ne "Ceci est un texte de test.") {
        throw "La conversion en TextExtractedInfo a Ã©chouÃ©"
    }
    
    $data = @{
        Name = "Test"
        Value = 123
    }
    
    $structured = [ExtractedInfoConverter]::ToStructuredDataInfo($base, $data)
    if ($structured.Source -ne "TestSource" -or $structured.GetValue("Name") -ne "Test") {
        throw "La conversion en StructuredDataExtractedInfo a Ã©chouÃ©"
    }
    
    $textToStructured = [ExtractedInfoConverter]::TextToStructuredData($text)
    if ($textToStructured.GetValue("Text") -ne "Ceci est un texte de test.") {
        throw "La conversion de TextExtractedInfo en StructuredDataExtractedInfo a Ã©chouÃ©"
    }
    
    $structuredToText = [ExtractedInfoConverter]::StructuredDataToText($structured)
    if ([string]::IsNullOrEmpty($structuredToText.Text)) {
        throw "La conversion de StructuredDataExtractedInfo en TextExtractedInfo a Ã©chouÃ©"
    }
}
if ($result) { $passedTests++ }

# Test 10: Sauvegarde et chargement depuis un fichier
$totalTests++
$result = Test-Feature -Name "Sauvegarde et chargement depuis un fichier" -Test {
    $info = [SerializableExtractedInfo]::new("TestSource", "TestExtractor")
    $info.AddMetadata("TestKey", "TestValue")
    
    $filePath = Join-Path -Path $testDir -ChildPath "test_info.json"
    $info.SaveToFile($filePath, "Json")
    
    if (-not (Test-Path -Path $filePath)) {
        throw "Le fichier n'a pas Ã©tÃ© crÃ©Ã©"
    }
    
    $newInfo = [SerializableExtractedInfo]::new()
    $newInfo.LoadFromFile($filePath, "Json")
    
    if ($newInfo.Source -ne "TestSource" -or $newInfo.ExtractorName -ne "TestExtractor") {
        throw "Le chargement depuis le fichier a Ã©chouÃ©"
    }
    
    if ($newInfo.GetMetadata("TestKey") -ne "TestValue") {
        throw "Les mÃ©tadonnÃ©es n'ont pas Ã©tÃ© correctement chargÃ©es"
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

# Nettoyer aprÃ¨s les tests
Remove-Item -Path $testDir -Recurse -Force

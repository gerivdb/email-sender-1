# Test-StructuredDataExtractedInfo.ps1
# Test de la fonction New-StructuredDataExtractedInfo avec différents types de données

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Fonction pour exécuter les tests
function Test-StructuredDataInfo {
    param (
        [string]$TestName,
        [object]$Data,
        [string]$DataFormat
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    $source = "DataSource"
    $extractorName = "DataExtractor"
    $info = New-StructuredDataExtractedInfo -Source $source -ExtractorName $extractorName -Data $Data -DataFormat $DataFormat
    
    # Vérifications
    $tests = @(
        @{ Test = "L'objet info n'est pas null"; Condition = $null -ne $info }
        @{ Test = "L'ID est un GUID valide"; Condition = [guid]::TryParse($info.Id, [ref][guid]::Empty) }
        @{ Test = "La source est correcte"; Condition = $info.Source -eq $source }
        @{ Test = "L'extracteur est correct"; Condition = $info.ExtractorName -eq $extractorName }
        @{ Test = "Les données sont correctes"; Condition = $null -ne $info.Data }
        @{ Test = "Le format des données est correct"; Condition = $info.DataFormat -eq $DataFormat }
        @{ Test = "L'état de traitement est 'Raw'"; Condition = $info.ProcessingState -eq "Raw" }
        @{ Test = "Le score de confiance est 0"; Condition = $info.ConfidenceScore -eq 0 }
        @{ Test = "L'objet n'est pas valide par défaut"; Condition = $info.IsValid -eq $false }
        @{ Test = "Le type est 'StructuredDataExtractedInfo'"; Condition = $info._Type -eq "StructuredDataExtractedInfo" }
        @{ Test = "Les métadonnées contiennent _CreatedBy"; Condition = $info.Metadata.ContainsKey("_CreatedBy") }
        @{ Test = "Les métadonnées contiennent _CreatedAt"; Condition = $info.Metadata.ContainsKey("_CreatedAt") }
        @{ Test = "Les métadonnées contiennent _Version"; Condition = $info.Metadata.ContainsKey("_Version") }
    )
    
    # Exécuter les tests
    $success = $true
    foreach ($test in $tests) {
        if ($test.Condition) {
            Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
        } else {
            Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
            $success = $false
        }
    }
    
    return $success
}

# Test 1: Hashtable simple
$hashData = @{
    Name = "Test"
    Value = 123
    IsActive = $true
}
$test1Success = Test-StructuredDataInfo -TestName "Hashtable simple" -Data $hashData -DataFormat "Hashtable"

# Test 2: Tableau simple
$arrayData = @("Item1", "Item2", "Item3")
$test2Success = Test-StructuredDataInfo -TestName "Tableau simple" -Data $arrayData -DataFormat "Array"

# Test 3: Hashtable imbriqué
$nestedHashData = @{
    Person = @{
        Name = "John"
        Age = 30
        Address = @{
            Street = "123 Main St"
            City = "Anytown"
        }
    }
    Items = @("Item1", "Item2")
}
$test3Success = Test-StructuredDataInfo -TestName "Hashtable imbriqué" -Data $nestedHashData -DataFormat "Hashtable"

# Test 4: Objet personnalisé
$customObject = [PSCustomObject]@{
    Name = "Custom Object"
    Value = 456
    IsActive = $false
}
$test4Success = Test-StructuredDataInfo -TestName "Objet personnalisé" -Data $customObject -DataFormat "PSObject"

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

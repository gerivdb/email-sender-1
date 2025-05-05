# Test-StructuredDataSimple.ps1
# Test simplifié de la fonction New-StructuredDataExtractedInfo

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test avec un hashtable simple
$source = "DataSource"
$extractorName = "DataExtractor"
$data = @{
    Name = "Test"
    Value = 123
    IsActive = $true
}
$dataFormat = "Hashtable"

$info = New-StructuredDataExtractedInfo -Source $source -ExtractorName $extractorName -Data $data -DataFormat $dataFormat

# Vérifications
$tests = @(
    @{ Test = "L'objet info n'est pas null"; Condition = $null -ne $info }
    @{ Test = "L'ID est un GUID valide"; Condition = [guid]::TryParse($info.Id, [ref][guid]::Empty) }
    @{ Test = "La source est correcte"; Condition = $info.Source -eq $source }
    @{ Test = "L'extracteur est correct"; Condition = $info.ExtractorName -eq $extractorName }
    @{ Test = "Les données sont correctes"; Condition = $null -ne $info.Data }
    @{ Test = "Le format des données est correct"; Condition = $info.DataFormat -eq $dataFormat }
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
        Write-Host "[SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "[ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success = $false
    }
}

# Résultat final
if ($success) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

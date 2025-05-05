# Test-AddExtractedInfoMetadata.ps1
# Test de la fonction Add-ExtractedInfoMetadata avec différents types de valeurs

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer une information extraite de base pour les tests
$info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"

# Fonction pour tester l'ajout de métadonnées
function Test-AddMetadata {
    param (
        [string]$TestName,
        [string]$Key,
        [object]$Value
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    # Ajouter la métadonnée
    $updatedInfo = Add-ExtractedInfoMetadata -Info $info -Key $Key -Value $Value
    
    # Vérifications
    $tests = @(
        @{ Test = "L'objet mis à jour n'est pas null"; Condition = $null -ne $updatedInfo }
        @{ Test = "L'ID reste inchangé"; Condition = $updatedInfo.Id -eq $info.Id }
        @{ Test = "La métadonnée a été ajoutée"; Condition = $updatedInfo.Metadata.ContainsKey($Key) }
        @{ Test = "La valeur de la métadonnée est correcte"; Condition = $updatedInfo.Metadata[$Key] -eq $Value }
        @{ Test = "La métadonnée _LastModified a été ajoutée"; Condition = $updatedInfo.Metadata.ContainsKey("_LastModified") }
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
    
    # Mettre à jour l'objet info pour le test suivant
    $global:info = $updatedInfo
    
    return $success
}

# Test 1: Valeur chaîne de caractères
$test1Success = Test-AddMetadata -TestName "Valeur chaîne de caractères" -Key "StringKey" -Value "StringValue"

# Test 2: Valeur numérique
$test2Success = Test-AddMetadata -TestName "Valeur numérique" -Key "NumberKey" -Value 123

# Test 3: Valeur booléenne
$test3Success = Test-AddMetadata -TestName "Valeur booléenne" -Key "BoolKey" -Value $true

# Test 4: Valeur date
$dateValue = [datetime]::Now
$test4Success = Test-AddMetadata -TestName "Valeur date" -Key "DateKey" -Value $dateValue

# Test 5: Valeur tableau
$arrayValue = @("Item1", "Item2", "Item3")
$test5Success = Test-AddMetadata -TestName "Valeur tableau" -Key "ArrayKey" -Value $arrayValue

# Test 6: Valeur hashtable
$hashValue = @{
    Name = "Test"
    Value = 123
}
$test6Success = Test-AddMetadata -TestName "Valeur hashtable" -Key "HashKey" -Value $hashValue

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and $test5Success -and $test6Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

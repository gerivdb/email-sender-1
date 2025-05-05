# Test-ExtractedInfoValid.ps1
# Test de la fonction Test-ExtractedInfo pour des informations valides

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Fonction pour tester la validation
function Test-ValidationResult {
    param (
        [string]$TestName,
        [hashtable]$Info,
        [switch]$UpdateObject
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    # Valider l'information
    $validationResult = Test-ExtractedInfo -Info $Info -UpdateObject:$UpdateObject
    
    # Vérifications
    $tests = @(
        @{ Test = "Le résultat est vrai"; Condition = $validationResult -eq $true }
    )
    
    # Si l'objet doit être mis à jour, vérifier les propriétés mises à jour
    if ($UpdateObject) {
        $tests += @(
            @{ Test = "La propriété IsValid est mise à jour"; Condition = $Info.IsValid -eq $true }
            @{ Test = "Les métadonnées contiennent _LastValidated"; Condition = $Info.Metadata.ContainsKey("_LastValidated") }
            @{ Test = "Les métadonnées contiennent _IsValid"; Condition = $Info.Metadata.ContainsKey("_IsValid") }
            @{ Test = "La valeur de _IsValid est vraie"; Condition = $Info.Metadata["_IsValid"] -eq $true }
            @{ Test = "Les métadonnées ne contiennent pas _ValidationErrors"; Condition = -not $Info.Metadata.ContainsKey("_ValidationErrors") }
        )
    }
    
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

# Créer des informations valides pour les tests
# Information de base valide
$validBaseInfo = New-ExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor"
$validBaseInfo.ConfidenceScore = 85

# Information de texte valide
$validTextInfo = New-TextExtractedInfo -Source "ValidTextSource" -ExtractorName "ValidTextExtractor" -Text "This is a valid text" -Language "en"
$validTextInfo.ConfidenceScore = 90

# Information de données structurées valide
$validDataInfo = New-StructuredDataExtractedInfo -Source "ValidDataSource" -ExtractorName "ValidDataExtractor" -Data @{
    Name = "Valid"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$validDataInfo.ConfidenceScore = 95

# Information de média valide
$tempDir = [System.IO.Path]::GetTempPath()
$mediaPath = Join-Path -Path $tempDir -ChildPath "valid_media.jpg"
Set-Content -Path $mediaPath -Value "Valid media content" -Force
$validMediaInfo = New-MediaExtractedInfo -Source "ValidMediaSource" -ExtractorName "ValidMediaExtractor" -MediaPath $mediaPath -MediaType "Image"
$validMediaInfo.ConfidenceScore = 80

# Test 1: Valider une information de base valide sans mise à jour
$test1Success = Test-ValidationResult -TestName "Valider une information de base valide sans mise à jour" -Info $validBaseInfo

# Test 2: Valider une information de base valide avec mise à jour
$test2Success = Test-ValidationResult -TestName "Valider une information de base valide avec mise à jour" -Info $validBaseInfo -UpdateObject

# Test 3: Valider une information de texte valide sans mise à jour
$test3Success = Test-ValidationResult -TestName "Valider une information de texte valide sans mise à jour" -Info $validTextInfo

# Test 4: Valider une information de texte valide avec mise à jour
$test4Success = Test-ValidationResult -TestName "Valider une information de texte valide avec mise à jour" -Info $validTextInfo -UpdateObject

# Test 5: Valider une information de données structurées valide sans mise à jour
$test5Success = Test-ValidationResult -TestName "Valider une information de données structurées valide sans mise à jour" -Info $validDataInfo

# Test 6: Valider une information de données structurées valide avec mise à jour
$test6Success = Test-ValidationResult -TestName "Valider une information de données structurées valide avec mise à jour" -Info $validDataInfo -UpdateObject

# Test 7: Valider une information de média valide sans mise à jour
$test7Success = Test-ValidationResult -TestName "Valider une information de média valide sans mise à jour" -Info $validMediaInfo

# Test 8: Valider une information de média valide avec mise à jour
$test8Success = Test-ValidationResult -TestName "Valider une information de média valide avec mise à jour" -Info $validMediaInfo -UpdateObject

# Nettoyer les fichiers temporaires
if (Test-Path -Path $mediaPath) {
    Remove-Item -Path $mediaPath -Force
}

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and $test5Success -and $test6Success -and $test7Success -and $test8Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

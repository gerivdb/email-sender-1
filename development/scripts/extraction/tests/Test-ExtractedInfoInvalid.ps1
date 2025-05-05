# Test-ExtractedInfoInvalid.ps1
# Test de la fonction Test-ExtractedInfo pour des informations invalides

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
        @{ Test = "Le résultat est faux"; Condition = $validationResult -eq $false }
    )
    
    # Si l'objet doit être mis à jour, vérifier les propriétés mises à jour
    if ($UpdateObject) {
        $tests += @(
            @{ Test = "La propriété IsValid est mise à jour"; Condition = $Info.IsValid -eq $false }
            @{ Test = "Les métadonnées contiennent _LastValidated"; Condition = $Info.Metadata.ContainsKey("_LastValidated") }
            @{ Test = "Les métadonnées contiennent _ValidationErrors"; Condition = $Info.Metadata.ContainsKey("_ValidationErrors") }
            @{ Test = "Les erreurs de validation ne sont pas vides"; Condition = $Info.Metadata["_ValidationErrors"].Count -gt 0 }
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

# Créer des informations invalides pour les tests
# Information de base avec ID vide
$invalidIdInfo = New-ExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor"
$invalidIdInfo.Id = ""

# Information de base avec source vide
$invalidSourceInfo = New-ExtractedInfo -Source "" -ExtractorName "ValidExtractor"

# Information de base avec score de confiance invalide
$invalidScoreInfo = New-ExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor"
$invalidScoreInfo.ConfidenceScore = 101

# Information de texte sans texte
$invalidTextInfo = New-TextExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -Text "" -Language "en"

# Information de texte sans langue
$invalidLanguageInfo = New-TextExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -Text "Valid text" -Language ""
$invalidLanguageInfo.Language = ""

# Information de données structurées sans données
$invalidDataInfo = New-StructuredDataExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -Data $null -DataFormat "Hashtable"

# Information de données structurées sans format
$invalidFormatInfo = New-StructuredDataExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -Data @{Name = "Test"} -DataFormat ""
$invalidFormatInfo.DataFormat = ""

# Information de média sans chemin
$invalidMediaPathInfo = New-MediaExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -MediaPath "" -MediaType "Image"

# Information de média sans type
$invalidMediaTypeInfo = New-MediaExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -MediaPath "test.jpg" -MediaType ""
$invalidMediaTypeInfo.MediaType = ""

# Test 1: Valider une information avec ID vide sans mise à jour
$test1Success = Test-ValidationResult -TestName "Valider une information avec ID vide sans mise à jour" -Info $invalidIdInfo

# Test 2: Valider une information avec ID vide avec mise à jour
$test2Success = Test-ValidationResult -TestName "Valider une information avec ID vide avec mise à jour" -Info $invalidIdInfo -UpdateObject

# Test 3: Valider une information avec source vide sans mise à jour
$test3Success = Test-ValidationResult -TestName "Valider une information avec source vide sans mise à jour" -Info $invalidSourceInfo

# Test 4: Valider une information avec source vide avec mise à jour
$test4Success = Test-ValidationResult -TestName "Valider une information avec source vide avec mise à jour" -Info $invalidSourceInfo -UpdateObject

# Test 5: Valider une information avec score de confiance invalide sans mise à jour
$test5Success = Test-ValidationResult -TestName "Valider une information avec score de confiance invalide sans mise à jour" -Info $invalidScoreInfo

# Test 6: Valider une information avec score de confiance invalide avec mise à jour
$test6Success = Test-ValidationResult -TestName "Valider une information avec score de confiance invalide avec mise à jour" -Info $invalidScoreInfo -UpdateObject

# Test 7: Valider une information de texte sans texte sans mise à jour
$test7Success = Test-ValidationResult -TestName "Valider une information de texte sans texte sans mise à jour" -Info $invalidTextInfo

# Test 8: Valider une information de texte sans texte avec mise à jour
$test8Success = Test-ValidationResult -TestName "Valider une information de texte sans texte avec mise à jour" -Info $invalidTextInfo -UpdateObject

# Test 9: Valider une information de texte sans langue sans mise à jour
$test9Success = Test-ValidationResult -TestName "Valider une information de texte sans langue sans mise à jour" -Info $invalidLanguageInfo

# Test 10: Valider une information de texte sans langue avec mise à jour
$test10Success = Test-ValidationResult -TestName "Valider une information de texte sans langue avec mise à jour" -Info $invalidLanguageInfo -UpdateObject

# Test 11: Valider une information de données structurées sans données sans mise à jour
$test11Success = Test-ValidationResult -TestName "Valider une information de données structurées sans données sans mise à jour" -Info $invalidDataInfo

# Test 12: Valider une information de données structurées sans données avec mise à jour
$test12Success = Test-ValidationResult -TestName "Valider une information de données structurées sans données avec mise à jour" -Info $invalidDataInfo -UpdateObject

# Test 13: Valider une information de données structurées sans format sans mise à jour
$test13Success = Test-ValidationResult -TestName "Valider une information de données structurées sans format sans mise à jour" -Info $invalidFormatInfo

# Test 14: Valider une information de données structurées sans format avec mise à jour
$test14Success = Test-ValidationResult -TestName "Valider une information de données structurées sans format avec mise à jour" -Info $invalidFormatInfo -UpdateObject

# Test 15: Valider une information de média sans chemin sans mise à jour
$test15Success = Test-ValidationResult -TestName "Valider une information de média sans chemin sans mise à jour" -Info $invalidMediaPathInfo

# Test 16: Valider une information de média sans chemin avec mise à jour
$test16Success = Test-ValidationResult -TestName "Valider une information de média sans chemin avec mise à jour" -Info $invalidMediaPathInfo -UpdateObject

# Test 17: Valider une information de média sans type sans mise à jour
$test17Success = Test-ValidationResult -TestName "Valider une information de média sans type sans mise à jour" -Info $invalidMediaTypeInfo

# Test 18: Valider une information de média sans type avec mise à jour
$test18Success = Test-ValidationResult -TestName "Valider une information de média sans type avec mise à jour" -Info $invalidMediaTypeInfo -UpdateObject

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and 
              $test5Success -and $test6Success -and $test7Success -and $test8Success -and 
              $test9Success -and $test10Success -and $test11Success -and $test12Success -and 
              $test13Success -and $test14Success -and $test15Success -and $test16Success -and 
              $test17Success -and $test18Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

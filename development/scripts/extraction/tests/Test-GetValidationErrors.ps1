# Test-GetValidationErrors.ps1
# Test de la fonction Get-ValidationErrors pour différents types d'erreurs

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Fonction pour tester la récupération des erreurs
function Test-ErrorRetrieval {
    param (
        [string]$TestName,
        [hashtable]$Info,
        [string[]]$ExpectedErrors
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    # Récupérer les erreurs
    $errors = Get-ValidationErrors -Info $Info
    
    # Vérifications
    $tests = @(
        @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $errors }
        @{ Test = "Le résultat est un tableau"; Condition = $errors -is [array] }
        @{ Test = "Le nombre d'erreurs est correct"; Condition = $errors.Count -eq $ExpectedErrors.Count }
    )
    
    # Vérifier chaque erreur attendue
    foreach ($expectedError in $ExpectedErrors) {
        $errorFound = $false
        foreach ($error in $errors) {
            if ($error -match $expectedError) {
                $errorFound = $true
                break
            }
        }
        $tests += @{ Test = "L'erreur '$expectedError' est présente"; Condition = $errorFound }
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
    
    # Afficher les erreurs trouvées
    if ($errors.Count -gt 0) {
        Write-Host "  Erreurs trouvées:" -ForegroundColor Cyan
        foreach ($error in $errors) {
            Write-Host "    - $error" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  Aucune erreur trouvée" -ForegroundColor Cyan
    }
    
    return $success
}

# Créer des informations avec différentes erreurs pour les tests
# Information de base avec ID vide
$invalidIdInfo = New-ExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor"
$invalidIdInfo.Id = ""

# Information de base avec source vide
$invalidSourceInfo = New-ExtractedInfo -Source "" -ExtractorName "ValidExtractor"

# Information de base avec score de confiance invalide
$invalidScoreInfo = New-ExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor"
$invalidScoreInfo.ConfidenceScore = 101

# Information avec plusieurs erreurs
$multipleErrorsInfo = New-ExtractedInfo -Source "" -ExtractorName "ValidExtractor"
$multipleErrorsInfo.Id = ""
$multipleErrorsInfo.ConfidenceScore = 101

# Information de texte sans texte et sans langue
$invalidTextInfo = New-TextExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -Text "" -Language ""

# Information de données structurées sans données et sans format
$invalidDataInfo = New-StructuredDataExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -Data $null -DataFormat ""

# Information de média sans chemin et sans type
$invalidMediaInfo = New-MediaExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor" -MediaPath "" -MediaType ""

# Information valide
$validInfo = New-ExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor"
$validInfo.ConfidenceScore = 85

# Test 1: Récupérer les erreurs d'une information avec ID vide
$test1Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information avec ID vide" -Info $invalidIdInfo -ExpectedErrors @("Missing or invalid Id")

# Test 2: Récupérer les erreurs d'une information avec source vide
$test2Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information avec source vide" -Info $invalidSourceInfo -ExpectedErrors @("Missing or invalid Source")

# Test 3: Récupérer les erreurs d'une information avec score de confiance invalide
$test3Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information avec score de confiance invalide" -Info $invalidScoreInfo -ExpectedErrors @("ConfidenceScore must be between 0 and 100")

# Test 4: Récupérer les erreurs d'une information avec plusieurs erreurs
$test4Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information avec plusieurs erreurs" -Info $multipleErrorsInfo -ExpectedErrors @("Missing or invalid Id", "Missing or invalid Source", "ConfidenceScore must be between 0 and 100")

# Test 5: Récupérer les erreurs d'une information de texte invalide
$test5Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information de texte invalide" -Info $invalidTextInfo -ExpectedErrors @("TextExtractedInfo must have a Text property", "TextExtractedInfo must have a Language property")

# Test 6: Récupérer les erreurs d'une information de données structurées invalide
$test6Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information de données structurées invalide" -Info $invalidDataInfo -ExpectedErrors @("StructuredDataExtractedInfo must have a Data property", "StructuredDataExtractedInfo must have a DataFormat property")

# Test 7: Récupérer les erreurs d'une information de média invalide
$test7Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information de média invalide" -Info $invalidMediaInfo -ExpectedErrors @("MediaExtractedInfo must have a MediaPath property", "MediaExtractedInfo must have a MediaType property")

# Test 8: Récupérer les erreurs d'une information valide
$test8Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information valide" -Info $validInfo -ExpectedErrors @()

# Test 9: Récupérer les erreurs d'une information avec validation préalable
Write-Host "Test 9: Récupérer les erreurs d'une information avec validation préalable" -ForegroundColor Cyan
$prevalidatedInfo = New-ExtractedInfo -Source "" -ExtractorName "ValidExtractor"
$prevalidatedInfo.Id = ""
$validationResult = Test-ExtractedInfo -Info $prevalidatedInfo -UpdateObject
$test9Success = Test-ErrorRetrieval -TestName "Récupérer les erreurs d'une information avec validation préalable" -Info $prevalidatedInfo -ExpectedErrors @("Missing or invalid Id", "Missing or invalid Source")

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and 
              $test5Success -and $test6Success -and $test7Success -and $test8Success -and 
              $test9Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

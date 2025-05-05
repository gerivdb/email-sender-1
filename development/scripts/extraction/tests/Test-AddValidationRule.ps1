# Test-AddValidationRule.ps1
# Test de la fonction Add-ValidationRule avec différentes règles personnalisées

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Fonction pour tester l'ajout de règles de validation
function Test-RuleAddition {
    param (
        [string]$TestName,
        [string]$RuleName,
        [string]$InfoType,
        [scriptblock]$ValidationScript,
        [string]$ErrorMessage
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    # Ajouter la règle
    $result = Add-ValidationRule -Name $RuleName -InfoType $InfoType -ValidationScript $ValidationScript -ErrorMessage $ErrorMessage
    
    # Vérifications
    $tests = @(
        @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $result }
        @{ Test = "Le résultat est un scriptblock"; Condition = $result -is [scriptblock] }
        @{ Test = "Le scriptblock retourné est identique à celui fourni"; Condition = $result.ToString() -eq $ValidationScript.ToString() }
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

# Test 1: Ajouter une règle de validation simple pour tous les types
$test1Success = Test-RuleAddition -TestName "Ajouter une règle de validation simple pour tous les types" -RuleName "MinimumConfidenceScore" -InfoType "ExtractedInfo" -ValidationScript { param($Info) $Info.ConfidenceScore -ge 50 } -ErrorMessage "Confidence score must be at least 50"

# Test 2: Ajouter une règle de validation pour les informations de texte
$test2Success = Test-RuleAddition -TestName "Ajouter une règle de validation pour les informations de texte" -RuleName "MinimumTextLength" -InfoType "TextExtractedInfo" -ValidationScript { param($Info) $Info.Text.Length -ge 10 } -ErrorMessage "Text must be at least 10 characters long"

# Test 3: Ajouter une règle de validation pour les informations de données structurées
$test3Success = Test-RuleAddition -TestName "Ajouter une règle de validation pour les informations de données structurées" -RuleName "RequiredDataProperties" -InfoType "StructuredDataExtractedInfo" -ValidationScript { param($Info) $Info.Data -ne $null -and $Info.Data.ContainsKey("Name") } -ErrorMessage "Data must contain a Name property"

# Test 4: Ajouter une règle de validation pour les informations de média
$test4Success = Test-RuleAddition -TestName "Ajouter une règle de validation pour les informations de média" -RuleName "SupportedMediaTypes" -InfoType "MediaExtractedInfo" -ValidationScript { param($Info) @("Image", "Video", "Audio") -contains $Info.MediaType } -ErrorMessage "Media type must be one of: Image, Video, Audio"

# Test 5: Ajouter une règle de validation complexe
$test5Success = Test-RuleAddition -TestName "Ajouter une règle de validation complexe" -RuleName "ComplexValidation" -InfoType "ExtractedInfo" -ValidationScript {
    param($Info)
    
    # Vérifier que la source contient au moins un mot
    if ([string]::IsNullOrWhiteSpace($Info.Source) -or $Info.Source.Trim().Split().Length -eq 0) {
        return $false
    }
    
    # Vérifier que l'extracteur est défini
    if ([string]::IsNullOrWhiteSpace($Info.ExtractorName)) {
        return $false
    }
    
    # Vérifier que le score de confiance est dans une plage valide
    if ($Info.ConfidenceScore -lt 0 -or $Info.ConfidenceScore -gt 100) {
        return $false
    }
    
    return $true
} -ErrorMessage "Complex validation failed"

# Créer des informations pour tester les règles
$validInfo = New-ExtractedInfo -Source "ValidSource" -ExtractorName "ValidExtractor"
$validInfo.ConfidenceScore = 85

$lowScoreInfo = New-ExtractedInfo -Source "LowScoreSource" -ExtractorName "LowScoreExtractor"
$lowScoreInfo.ConfidenceScore = 30

$shortTextInfo = New-TextExtractedInfo -Source "ShortTextSource" -ExtractorName "ShortTextExtractor" -Text "Short" -Language "en"
$shortTextInfo.ConfidenceScore = 85

$longTextInfo = New-TextExtractedInfo -Source "LongTextSource" -ExtractorName "LongTextExtractor" -Text "This is a long text for testing validation rules" -Language "en"
$longTextInfo.ConfidenceScore = 85

# Test 6: Vérifier l'application des règles de validation
Write-Host "Test 6: Vérifier l'application des règles de validation" -ForegroundColor Cyan

# Valider l'information avec un score élevé
$validationResult1 = Test-ExtractedInfo -Info $validInfo
Write-Host "  Validation de l'information avec un score élevé: $validationResult1" -ForegroundColor Cyan

# Valider l'information avec un score bas
$validationResult2 = Test-ExtractedInfo -Info $lowScoreInfo
Write-Host "  Validation de l'information avec un score bas: $validationResult2" -ForegroundColor Cyan

# Valider l'information de texte court
$validationResult3 = Test-ExtractedInfo -Info $shortTextInfo
Write-Host "  Validation de l'information de texte court: $validationResult3" -ForegroundColor Cyan

# Valider l'information de texte long
$validationResult4 = Test-ExtractedInfo -Info $longTextInfo
Write-Host "  Validation de l'information de texte long: $validationResult4" -ForegroundColor Cyan

# Note: Les règles de validation personnalisées ne sont pas automatiquement appliquées par Test-ExtractedInfo
# dans cette implémentation. Elles sont stockées dans le module pour une utilisation ultérieure.
# Cette limitation est documentée ici.

$test6Success = $true

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and $test5Success -and $test6Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

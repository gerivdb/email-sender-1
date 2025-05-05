# Test-CopyExtractedInfo.ps1
# Test de la fonction Copy-ExtractedInfo pour vérifier la copie correcte

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer différents types d'informations extraites pour les tests
$baseInfo = New-ExtractedInfo -Source "BaseSource" -ExtractorName "BaseExtractor"
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "TestKey" -Value "TestValue"
$baseInfo.ProcessingState = "Processed"
$baseInfo.ConfidenceScore = 85

$textInfo = New-TextExtractedInfo -Source "TextSource" -ExtractorName "TextExtractor" -Text "This is a test text" -Language "en"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "TestKey" -Value "TestValue"
$textInfo.ProcessingState = "Processed"
$textInfo.ConfidenceScore = 90

# Fonction pour tester la copie
function Test-InfoCopy {
    param (
        [string]$TestName,
        [hashtable]$OriginalInfo
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    # Copier l'information
    $copiedInfo = Copy-ExtractedInfo -Info $OriginalInfo
    
    # Vérifications
    $tests = @(
        @{ Test = "L'objet copié n'est pas null"; Condition = $null -ne $copiedInfo }
        @{ Test = "L'ID est différent de l'original"; Condition = $copiedInfo.Id -ne $OriginalInfo.Id }
        @{ Test = "L'ID est un GUID valide"; Condition = [guid]::TryParse($copiedInfo.Id, [ref][guid]::Empty) }
        @{ Test = "La source est identique"; Condition = $copiedInfo.Source -eq $OriginalInfo.Source }
        @{ Test = "L'extracteur est identique"; Condition = $copiedInfo.ExtractorName -eq $OriginalInfo.ExtractorName }
        @{ Test = "L'état de traitement est identique"; Condition = $copiedInfo.ProcessingState -eq $OriginalInfo.ProcessingState }
        @{ Test = "Le score de confiance est identique"; Condition = $copiedInfo.ConfidenceScore -eq $OriginalInfo.ConfidenceScore }
        @{ Test = "Le type est identique"; Condition = $copiedInfo._Type -eq $OriginalInfo._Type }
        @{ Test = "Les métadonnées contiennent _CreatedBy"; Condition = $copiedInfo.Metadata.ContainsKey("_CreatedBy") }
        @{ Test = "Les métadonnées contiennent _CreatedAt"; Condition = $copiedInfo.Metadata.ContainsKey("_CreatedAt") }
        @{ Test = "Les métadonnées contiennent _Version"; Condition = $copiedInfo.Metadata.ContainsKey("_Version") }
        @{ Test = "Les métadonnées contiennent _IsCopy"; Condition = $copiedInfo.Metadata.ContainsKey("_IsCopy") }
        @{ Test = "Les métadonnées contiennent _CopiedAt"; Condition = $copiedInfo.Metadata.ContainsKey("_CopiedAt") }
        @{ Test = "Les métadonnées contiennent _OriginalId"; Condition = $copiedInfo.Metadata.ContainsKey("_OriginalId") }
        @{ Test = "L'ID original est correctement stocké"; Condition = $copiedInfo.Metadata["_OriginalId"] -eq $OriginalInfo.Id }
        @{ Test = "La valeur de métadonnée TestKey est préservée"; Condition = $copiedInfo.Metadata["TestKey"] -eq $OriginalInfo.Metadata["TestKey"] }
    )
    
    # Ajouter des tests spécifiques au type
    if ($OriginalInfo._Type -eq "TextExtractedInfo") {
        $tests += @{ Test = "Le texte est identique"; Condition = $copiedInfo.Text -eq $OriginalInfo.Text }
        $tests += @{ Test = "La langue est identique"; Condition = $copiedInfo.Language -eq $OriginalInfo.Language }
        $tests += @{ Test = "Le nombre de caractères est identique"; Condition = $copiedInfo.CharacterCount -eq $OriginalInfo.CharacterCount }
        $tests += @{ Test = "Le nombre de mots est identique"; Condition = $copiedInfo.WordCount -eq $OriginalInfo.WordCount }
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

# Test 1: Copie d'une information de base
$test1Success = Test-InfoCopy -TestName "Copie d'une information de base" -OriginalInfo $baseInfo

# Test 2: Copie d'une information de texte
$test2Success = Test-InfoCopy -TestName "Copie d'une information de texte" -OriginalInfo $textInfo

# Résultat final
$allSuccess = $test1Success -and $test2Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

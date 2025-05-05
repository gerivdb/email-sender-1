# Test-GetExtractedInfoSummary.ps1
# Test de la fonction Get-ExtractedInfoSummary pour différents types d'informations

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Fonction pour tester le résumé
function Test-InfoSummary {
    param (
        [string]$TestName,
        [hashtable]$Info
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    # Obtenir le résumé
    $summary = Get-ExtractedInfoSummary -Info $Info
    
    # Vérifications
    $tests = @(
        @{ Test = "Le résumé n'est pas null"; Condition = $null -ne $summary }
        @{ Test = "Le résumé est une chaîne de caractères"; Condition = $summary -is [string] }
        @{ Test = "Le résumé contient l'ID"; Condition = $summary -match $Info.Id }
        @{ Test = "Le résumé contient la source"; Condition = $summary -match $Info.Source }
        @{ Test = "Le résumé contient l'état de traitement"; Condition = $summary -match $Info.ProcessingState }
        @{ Test = "Le résumé contient le score de confiance"; Condition = $summary -match $Info.ConfidenceScore }
    )
    
    # Ajouter des tests spécifiques au type
    switch ($Info._Type) {
        "TextExtractedInfo" {
            $tests += @{ Test = "Le résumé contient le nombre de caractères"; Condition = $summary -match "caractères" -or $summary -match "characters" }
            $tests += @{ Test = "Le résumé contient le nombre de mots"; Condition = $summary -match "mots" -or $summary -match "words" }
        }
        "StructuredDataExtractedInfo" {
            $tests += @{ Test = "Le résumé contient le nombre d'éléments"; Condition = $summary -match "items" }
            $tests += @{ Test = "Le résumé contient la profondeur maximale"; Condition = $summary -match "depth" }
        }
        "MediaExtractedInfo" {
            $tests += @{ Test = "Le résumé contient le type de média"; Condition = $summary -match $Info.MediaType }
            $tests += @{ Test = "Le résumé contient la taille"; Condition = $summary -match "Size" }
        }
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
    
    Write-Host "  Résumé: $summary" -ForegroundColor Cyan
    
    return $success
}

# Créer différents types d'informations extraites pour les tests
$baseInfo = New-ExtractedInfo -Source "BaseSource" -ExtractorName "BaseExtractor"
$baseInfo.ProcessingState = "Processed"
$baseInfo.ConfidenceScore = 85

$textInfo = New-TextExtractedInfo -Source "TextSource" -ExtractorName "TextExtractor" -Text "This is a test text with multiple words for testing the summary function." -Language "en"
$textInfo.ProcessingState = "Processed"
$textInfo.ConfidenceScore = 90

$dataInfo = New-StructuredDataExtractedInfo -Source "DataSource" -ExtractorName "DataExtractor" -Data @{
    Name = "Test"
    Value = 123
    Items = @("Item1", "Item2", "Item3")
} -DataFormat "Hashtable"
$dataInfo.ProcessingState = "Processed"
$dataInfo.ConfidenceScore = 95

# Créer un fichier temporaire pour simuler un média
$tempDir = [System.IO.Path]::GetTempPath()
$imageFile = Join-Path -Path $tempDir -ChildPath "test_image.jpg"
Set-Content -Path $imageFile -Value "Test image content" -Force

$mediaInfo = New-MediaExtractedInfo -Source "MediaSource" -ExtractorName "MediaExtractor" -MediaPath $imageFile -MediaType "Image"
$mediaInfo.ProcessingState = "Processed"
$mediaInfo.ConfidenceScore = 80

# Exécuter les tests
$test1Success = Test-InfoSummary -TestName "Résumé d'une information de base" -Info $baseInfo
$test2Success = Test-InfoSummary -TestName "Résumé d'une information de texte" -Info $textInfo
$test3Success = Test-InfoSummary -TestName "Résumé d'une information de données structurées" -Info $dataInfo
$test4Success = Test-InfoSummary -TestName "Résumé d'une information de média" -Info $mediaInfo

# Nettoyer les fichiers temporaires
Remove-Item -Path $imageFile -Force -ErrorAction SilentlyContinue

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

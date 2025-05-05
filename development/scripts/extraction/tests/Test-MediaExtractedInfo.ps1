# Test-MediaExtractedInfo.ps1
# Test de la fonction New-MediaExtractedInfo avec différents types de médias

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un fichier temporaire pour simuler un média
$tempDir = [System.IO.Path]::GetTempPath()
$imageFile = Join-Path -Path $tempDir -ChildPath "test_image.jpg"
$audioFile = Join-Path -Path $tempDir -ChildPath "test_audio.mp3"

# Créer des fichiers vides pour les tests
Set-Content -Path $imageFile -Value "Test image content" -Force
Set-Content -Path $audioFile -Value "Test audio content" -Force

# Fonction pour exécuter les tests
function Test-MediaInfo {
    param (
        [string]$TestName,
        [string]$MediaPath,
        [string]$MediaType
    )
    
    Write-Host "Test: $TestName" -ForegroundColor Cyan
    
    $source = "MediaSource"
    $extractorName = "MediaExtractor"
    $info = New-MediaExtractedInfo -Source $source -ExtractorName $extractorName -MediaPath $MediaPath -MediaType $MediaType
    
    # Vérifications
    $tests = @(
        @{ Test = "L'objet info n'est pas null"; Condition = $null -ne $info }
        @{ Test = "L'ID est un GUID valide"; Condition = [guid]::TryParse($info.Id, [ref][guid]::Empty) }
        @{ Test = "La source est correcte"; Condition = $info.Source -eq $source }
        @{ Test = "L'extracteur est correct"; Condition = $info.ExtractorName -eq $extractorName }
        @{ Test = "Le chemin du média est correct"; Condition = $info.MediaPath -eq $MediaPath }
        @{ Test = "Le type de média est correct"; Condition = $info.MediaType -eq $MediaType }
        @{ Test = "La taille du fichier est > 0"; Condition = $info.FileSize -gt 0 }
        @{ Test = "La date de création est définie"; Condition = $null -ne $info.FileCreatedDate }
        @{ Test = "L'état de traitement est 'Raw'"; Condition = $info.ProcessingState -eq "Raw" }
        @{ Test = "Le score de confiance est 0"; Condition = $info.ConfidenceScore -eq 0 }
        @{ Test = "L'objet n'est pas valide par défaut"; Condition = $info.IsValid -eq $false }
        @{ Test = "Le type est 'MediaExtractedInfo'"; Condition = $info._Type -eq "MediaExtractedInfo" }
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

# Test 1: Image
$test1Success = Test-MediaInfo -TestName "Fichier image" -MediaPath $imageFile -MediaType "Image"

# Test 2: Audio
$test2Success = Test-MediaInfo -TestName "Fichier audio" -MediaPath $audioFile -MediaType "Audio"

# Nettoyer les fichiers temporaires
Remove-Item -Path $imageFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $audioFile -Force -ErrorAction SilentlyContinue

# Résultat final
$allSuccess = $test1Success -and $test2Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

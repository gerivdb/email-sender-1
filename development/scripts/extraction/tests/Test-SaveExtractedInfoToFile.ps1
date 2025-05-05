# Test-SaveExtractedInfoToFile.ps1
# Test de la fonction Save-ExtractedInfoToFile avec différents chemins

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer des objets de test
$simpleInfo = New-ExtractedInfo -Source "SimpleSource" -ExtractorName "SimpleExtractor"
$simpleInfo = Add-ExtractedInfoMetadata -Info $simpleInfo -Key "SimpleKey" -Value "SimpleValue"

$textInfo = New-TextExtractedInfo -Source "TextSource" -ExtractorName "TextExtractor" -Text "This is a test text" -Language "en"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "TextKey" -Value "TextValue"

# Créer des chemins de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
$nestedDir = Join-Path -Path $testDir -ChildPath "Nested"
$deepNestedDir = Join-Path -Path $nestedDir -ChildPath "DeepNested"

# Nettoyer les répertoires de test s'ils existent
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Test 1: Sauvegarder un fichier dans un répertoire existant
Write-Host "Test 1: Sauvegarder un fichier dans un répertoire existant" -ForegroundColor Cyan
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$filePath1 = Join-Path -Path $testDir -ChildPath "simpleInfo.json"
$result1 = Save-ExtractedInfoToFile -Info $simpleInfo -FilePath $filePath1

$tests1 = @(
    @{ Test = "Le résultat est vrai"; Condition = $result1 -eq $true }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $filePath1 }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $filePath1).Length -gt 0 }
)

$test1Success = $true
foreach ($test in $tests1) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test1Success = $false
    }
}

# Test 2: Sauvegarder un fichier dans un répertoire inexistant (création automatique)
Write-Host "Test 2: Sauvegarder un fichier dans un répertoire inexistant (création automatique)" -ForegroundColor Cyan
$filePath2 = Join-Path -Path $nestedDir -ChildPath "textInfo.json"
$result2 = Save-ExtractedInfoToFile -Info $textInfo -FilePath $filePath2

$tests2 = @(
    @{ Test = "Le résultat est vrai"; Condition = $result2 -eq $true }
    @{ Test = "Le répertoire a été créé"; Condition = Test-Path -Path $nestedDir -PathType Container }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $filePath2 }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $filePath2).Length -gt 0 }
)

$test2Success = $true
foreach ($test in $tests2) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test2Success = $false
    }
}

# Test 3: Sauvegarder un fichier dans un répertoire profondément imbriqué
Write-Host "Test 3: Sauvegarder un fichier dans un répertoire profondément imbriqué" -ForegroundColor Cyan
$filePath3 = Join-Path -Path $deepNestedDir -ChildPath "deepInfo.json"
$result3 = Save-ExtractedInfoToFile -Info $simpleInfo -FilePath $filePath3

$tests3 = @(
    @{ Test = "Le résultat est vrai"; Condition = $result3 -eq $true }
    @{ Test = "Le répertoire a été créé"; Condition = Test-Path -Path $deepNestedDir -PathType Container }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $filePath3 }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $filePath3).Length -gt 0 }
)

$test3Success = $true
foreach ($test in $tests3) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test3Success = $false
    }
}

# Test 4: Sauvegarder un fichier avec un format non supporté
Write-Host "Test 4: Sauvegarder un fichier avec un format non supporté" -ForegroundColor Cyan
$filePath4 = Join-Path -Path $testDir -ChildPath "unsupportedFormat.xml"
$unsupportedSuccess = $false

try {
    $result4 = Save-ExtractedInfoToFile -Info $simpleInfo -FilePath $filePath4 -Format "Xml"
    Write-Host "  [ÉCHEC] La sauvegarde avec un format non supporté n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] La sauvegarde avec un format non supporté a échoué comme prévu" -ForegroundColor Green
    $unsupportedSuccess = $true
}

# Test 5: Sauvegarder un objet invalide
Write-Host "Test 5: Sauvegarder un objet invalide" -ForegroundColor Cyan
$invalidObj = @{ Name = "Invalid"; Value = 123 }
$filePath5 = Join-Path -Path $testDir -ChildPath "invalidObj.json"
$invalidSuccess = $false

try {
    $result5 = Save-ExtractedInfoToFile -Info $invalidObj -FilePath $filePath5
    Write-Host "  [ÉCHEC] La sauvegarde d'un objet invalide n'a pas échoué" -ForegroundColor Red
} catch {
    Write-Host "  [SUCCÈS] La sauvegarde d'un objet invalide a échoué comme prévu" -ForegroundColor Green
    $invalidSuccess = $true
}

# Nettoyer les répertoires de test
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $unsupportedSuccess -and $invalidSuccess

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

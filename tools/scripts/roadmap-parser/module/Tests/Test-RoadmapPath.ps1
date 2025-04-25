#
# Test-RoadmapPath.ps1
#
# Script pour tester la fonction Test-RoadmapPath
#

# Importer la fonction Test-RoadmapPath
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathManipulation\Test-RoadmapPath.ps1"

# Créer le répertoire s'il n'existe pas
$functionDir = Split-Path -Parent $functionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer la fonction
. $functionPath

Write-Host "Début des tests de la fonction Test-RoadmapPath..." -ForegroundColor Cyan

# Créer des fichiers et répertoires de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTest_$([Guid]::NewGuid().ToString())"
$testFile = Join-Path -Path $testDir -ChildPath "test.txt"
$testHiddenFile = Join-Path -Path $testDir -ChildPath "hidden.txt"
$testReadOnlyFile = Join-Path -Path $testDir -ChildPath "readonly.txt"

# Créer le répertoire de test
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Créer le fichier de test
Set-Content -Path $testFile -Value "Test content" -Force

# Créer le fichier caché
Set-Content -Path $testHiddenFile -Value "Hidden content" -Force
$hiddenFile = Get-Item -Path $testHiddenFile -Force
$hiddenFile.Attributes = $hiddenFile.Attributes -bor [System.IO.FileAttributes]::Hidden

# Créer le fichier en lecture seule
Set-Content -Path $testReadOnlyFile -Value "Read-only content" -Force
$readOnlyFile = Get-Item -Path $testReadOnlyFile -Force
$readOnlyFile.Attributes = $readOnlyFile.Attributes -bor [System.IO.FileAttributes]::ReadOnly

# Test 1: Tests de base
Write-Host "`nTest 1: Tests de base" -ForegroundColor Cyan

$testCases = @(
    @{ Path = $testDir; TestType = "Exists"; Expected = $true; Description = "Répertoire existant" }
    @{ Path = $testFile; TestType = "Exists"; Expected = $true; Description = "Fichier existant" }
    @{ Path = Join-Path -Path $testDir -ChildPath "nonexistent.txt"; TestType = "Exists"; Expected = $false; Description = "Fichier inexistant" }
    @{ Path = $testDir; TestType = "IsDirectory"; Expected = $true; Description = "Est un répertoire" }
    @{ Path = $testFile; TestType = "IsFile"; Expected = $true; Description = "Est un fichier" }
    @{ Path = $testHiddenFile; TestType = "IsHidden"; Expected = $true; Description = "Est caché" }
    @{ Path = $testFile; TestType = "IsHidden"; Expected = $false; Description = "N'est pas caché" }
    @{ Path = $testDir; TestType = "IsReadable"; Expected = $true; Description = "Répertoire lisible" }
    @{ Path = $testFile; TestType = "IsReadable"; Expected = $true; Description = "Fichier lisible" }
    @{ Path = $testDir; TestType = "IsWritable"; Expected = $true; Description = "Répertoire modifiable" }
    @{ Path = $testFile; TestType = "IsWritable"; Expected = $true; Description = "Fichier modifiable" }
    @{ Path = $testReadOnlyFile; TestType = "IsWritable"; Expected = $false; Description = "Fichier en lecture seule" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path = $testCase.Path
        TestType = $testCase.TestType
    }
    
    $result = Test-RoadmapPath @params
    
    # Vérifier le résultat
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Tests de validation
Write-Host "`nTest 2: Tests de validation" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "C:\folder\file.txt"; TestType = "IsRooted"; Expected = $true; Description = "Chemin absolu" }
    @{ Path = ".\folder\file.txt"; TestType = "IsRooted"; Expected = $false; Description = "Chemin relatif" }
    @{ Path = ".\folder\file.txt"; TestType = "IsRelative"; Expected = $true; Description = "Est relatif" }
    @{ Path = "C:\folder\file.txt"; TestType = "IsRelative"; Expected = $false; Description = "N'est pas relatif" }
    @{ Path = "C:\folder\file.txt"; TestType = "IsValid"; Expected = $true; Description = "Chemin valide" }
    @{ Path = "C:\folder\file.txt"; TestType = "HasExtension"; Expected = $true; Description = "A une extension" }
    @{ Path = "C:\folder\file"; TestType = "HasExtension"; Expected = $false; Description = "N'a pas d'extension" }
    @{ Path = "C:\folder\file.txt"; TestType = "HasExtension"; Extension = ".txt"; Expected = $true; Description = "A l'extension .txt" }
    @{ Path = "C:\folder\file.txt"; TestType = "HasExtension"; Extension = "txt"; Expected = $true; Description = "A l'extension txt" }
    @{ Path = "C:\folder\file.txt"; TestType = "HasExtension"; Extension = ".doc"; Expected = $false; Description = "N'a pas l'extension .doc" }
    @{ Path = "C:\folder\file.txt"; TestType = "HasParent"; Expected = $true; Description = "A un parent" }
    @{ Path = "C:"; TestType = "HasParent"; Expected = $false; Description = "N'a pas de parent" }
    @{ Path = "C:\folder\file.txt"; TestType = "MatchesPattern"; Pattern = "*.txt"; Expected = $true; Description = "Correspond au motif *.txt" }
    @{ Path = "C:\folder\file.txt"; TestType = "MatchesPattern"; Pattern = "*.doc"; Expected = $false; Description = "Ne correspond pas au motif *.doc" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path = $testCase.Path
        TestType = $testCase.TestType
    }
    
    if ($testCase.ContainsKey("Extension")) {
        $params["Extension"] = $testCase.Extension
    }
    
    if ($testCase.ContainsKey("Pattern")) {
        $params["Pattern"] = $testCase.Pattern
    }
    
    $result = Test-RoadmapPath @params
    
    # Vérifier le résultat
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Options
Write-Host "`nTest 3: Options" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "C:\folder\FILE.TXT"; TestType = "MatchesPattern"; Pattern = "*.txt"; IgnoreCase = $true; Expected = $true; Description = "Correspondance insensible à la casse" }
    @{ Path = "C:\folder\FILE.TXT"; TestType = "MatchesPattern"; Pattern = "*.txt"; IgnoreCase = $false; Expected = $false; Description = "Correspondance sensible à la casse" }
    @{ Path = "C:\folder\FILE.TXT"; TestType = "HasExtension"; Extension = ".txt"; IgnoreCase = $true; Expected = $true; Description = "Extension insensible à la casse" }
    @{ Path = "C:\folder\FILE.TXT"; TestType = "HasExtension"; Extension = ".txt"; IgnoreCase = $false; Expected = $false; Description = "Extension sensible à la casse" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path = $testCase.Path
        TestType = $testCase.TestType
    }
    
    if ($testCase.ContainsKey("Extension")) {
        $params["Extension"] = $testCase.Extension
    }
    
    if ($testCase.ContainsKey("Pattern")) {
        $params["Pattern"] = $testCase.Pattern
    }
    
    if ($testCase.ContainsKey("IgnoreCase")) {
        $params["IgnoreCase"] = $testCase.IgnoreCase
    }
    
    $result = Test-RoadmapPath @params
    
    # Vérifier le résultat
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Test personnalisé
Write-Host "`nTest 4: Test personnalisé" -ForegroundColor Cyan

$customTest = {
    param($Path)
    
    # Exemple : Vérifier si le chemin contient le mot "test"
    return $Path -like "*test*"
}

$testCases = @(
    @{ Path = "C:\test\file.txt"; TestType = "Custom"; CustomTest = $customTest; Expected = $true; Description = "Chemin contenant 'test'" }
    @{ Path = "C:\folder\file.txt"; TestType = "Custom"; CustomTest = $customTest; Expected = $false; Description = "Chemin ne contenant pas 'test'" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path = $testCase.Path
        TestType = $testCase.TestType
        CustomTest = $testCase.CustomTest
    }
    
    $result = Test-RoadmapPath @params
    
    # Vérifier le résultat
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: Gestion des erreurs
Write-Host "`nTest 5: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Test-RoadmapPath sans Pattern pour MatchesPattern"; Function = { Test-RoadmapPath -Path "C:\folder\file.txt" -TestType "MatchesPattern" -ThrowOnFailure }; ShouldThrow = $true; Description = "MatchesPattern sans Pattern" }
    @{ Test = "Test-RoadmapPath sans CustomTest pour Custom"; Function = { Test-RoadmapPath -Path "C:\folder\file.txt" -TestType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Custom sans CustomTest" }
    @{ Test = "Test-RoadmapPath avec erreur sans ThrowOnFailure"; Function = { 
        # Ce test est censé générer un warning, c'est normal
        Write-Host "Note: Le warning suivant est attendu dans le cadre du test:" -ForegroundColor Yellow
        $result = Test-RoadmapPath -Path "C:\folder\file.txt" -TestType "MatchesPattern"
        return $result
    }; ShouldThrow = $false; Description = "Erreur sans ThrowOnFailure" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $exceptionThrown = $false
    
    try {
        & $testCase.Function
    } catch {
        $exceptionThrown = $true
    }
    
    # Vérifier le résultat
    $success = $testCase.ShouldThrow -eq $exceptionThrown
    
    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        if ($testCase.ShouldThrow) {
            Write-Host "    Exception attendue mais non levée" -ForegroundColor Red
        } else {
            Write-Host "    Exception non attendue mais levée" -ForegroundColor Red
        }
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Nettoyer les fichiers et répertoires de test
Remove-Item -Path $testReadOnlyFile -Force
Remove-Item -Path $testHiddenFile -Force
Remove-Item -Path $testFile -Force
Remove-Item -Path $testDir -Force

Write-Host "`nTests de la fonction Test-RoadmapPath terminés." -ForegroundColor Cyan

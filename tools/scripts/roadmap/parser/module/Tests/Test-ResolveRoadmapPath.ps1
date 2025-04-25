#
# Test-ResolveRoadmapPath.ps1
#
# Script pour tester la fonction Resolve-RoadmapPath
#

# Importer la fonction Resolve-RoadmapPath
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathManipulation\Resolve-RoadmapPath.ps1"

# Créer le répertoire s'il n'existe pas
$functionDir = Split-Path -Parent $functionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer la fonction
. $functionPath

Write-Host "Début des tests de la fonction Resolve-RoadmapPath..." -ForegroundColor Cyan

# Test 1: Résolution de base
Write-Host "`nTest 1: Résolution de base" -ForegroundColor Cyan

# Obtenir le répertoire courant
$testCases = @(
    @{ Path = "file.txt"; ResolutionType = "FullPath"; Expected = Join-Path -Path "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1" -ChildPath "file.txt"; Description = "Chemin relatif simple" }
    @{ Path = "C:\folder\file.txt"; ResolutionType = "FullPath"; Expected = "C:\folder\file.txt"; Description = "Chemin absolu Windows" }
    @{ Path = ""; ResolutionType = "FullPath"; Expected = ""; Description = "Chemin vide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path           = $testCase.Path
        ResolutionType = $testCase.ResolutionType
    }

    $result = Resolve-RoadmapPath @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Résolution de parties de chemin
Write-Host "`nTest 2: Résolution de parties de chemin" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "C:\folder\file.txt"; ResolutionType = "FileName"; Expected = "file.txt"; Description = "Nom de fichier" }
    @{ Path = "C:\folder\file.txt"; ResolutionType = "FileNameWithoutExtension"; Expected = "file"; Description = "Nom de fichier sans extension" }
    @{ Path = "C:\folder\file.txt"; ResolutionType = "Extension"; Expected = ".txt"; Description = "Extension" }
    @{ Path = "C:\folder\file.txt"; ResolutionType = "DirectoryName"; Expected = "C:\folder"; Description = "Nom de répertoire" }
    @{ Path = "C:\folder\file.txt"; ResolutionType = "ParentPath"; Expected = "C:\folder"; Description = "Chemin parent" }
    @{ Path = "C:\folder\file.txt"; ResolutionType = "RootPath"; Expected = "C:\"; Description = "Chemin racine" }
    @{ Path = "C:\folder\file.txt"; ResolutionType = "PathRoot"; Expected = "C:\"; Description = "Racine du chemin" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path           = $testCase.Path
        ResolutionType = $testCase.ResolutionType
    }

    $result = Resolve-RoadmapPath @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Résolution de chemins spéciaux
Write-Host "`nTest 3: Résolution de chemins spéciaux" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "subfolder"; ResolutionType = "TempPath"; Expected = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "subfolder"; Description = "Chemin temporaire avec sous-dossier" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path           = $testCase.Path
        ResolutionType = $testCase.ResolutionType
    }

    $result = Resolve-RoadmapPath @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
    }
}

# Test pour RandomPath
$params = @{
    Path           = "test"
    ResolutionType = "RandomPath"
}

$result = Resolve-RoadmapPath @params
$tempPath = [System.IO.Path]::GetTempPath()
$success = $result -like "$tempPath*" -and $result -ne $tempPath -and $result -like "*test*"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Chemin aléatoire: $status" -ForegroundColor $color

if ($success) {
    $successCount++
} else {
    $failureCount++
    Write-Host "    Résultat attendu: Chemin temporaire avec nom aléatoire contenant 'test'" -ForegroundColor Red
    Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
}

# Test pour EnvironmentPath
$envVar = "TEMP"
$params = @{
    Path                = "test"
    ResolutionType      = "EnvironmentPath"
    EnvironmentVariable = $envVar
}

$result = Resolve-RoadmapPath @params
$expected = Join-Path -Path ([System.Environment]::GetEnvironmentVariable($envVar)) -ChildPath "test"
$success = $result -eq $expected

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Chemin d'environnement: $status" -ForegroundColor $color

if ($success) {
    $successCount++
} else {
    $failureCount++
    Write-Host "    Résultat attendu: '$expected'" -ForegroundColor Red
    Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Résolution personnalisée
Write-Host "`nTest 4: Résolution personnalisée" -ForegroundColor Cyan

$customResolution = {
    param($Path)

    # Exemple : Ajouter un préfixe "custom:" au chemin
    return "custom:$Path"
}

$result = Resolve-RoadmapPath -Path "C:\folder\file.txt" -ResolutionType "Custom" -CustomResolution $customResolution

$expected = "custom:C:\folder\file.txt"
$success = $result -eq $expected

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Résolution personnalisée: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: '$expected'" -ForegroundColor Red
    Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
}

# Test 5: Création de chemins
Write-Host "`nTest 5: Création de chemins" -ForegroundColor Cyan

$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTest_$([Guid]::NewGuid().ToString())"
$testFile = Join-Path -Path $testDir -ChildPath "test.txt"

# Test pour la création d'un répertoire
$params = @{
    Path              = $testDir
    ResolutionType    = "FullPath"
    CreateIfNotExists = $true
}

$result = Resolve-RoadmapPath @params
$success = Test-Path -Path $testDir -PathType Container

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Création de répertoire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Le répertoire '$testDir' n'a pas été créé" -ForegroundColor Red
}

# Test pour la création d'un fichier
$params = @{
    Path              = $testFile
    ResolutionType    = "FullPath"
    CreateIfNotExists = $true
}

$result = Resolve-RoadmapPath @params
$success = Test-Path -Path $testFile -PathType Leaf

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Création de fichier: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Le fichier '$testFile' n'a pas été créé" -ForegroundColor Red
}

# Nettoyer les fichiers et répertoires de test
Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $testDir -Force -ErrorAction SilentlyContinue

# Test 6: Gestion des erreurs
Write-Host "`nTest 6: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Resolve-RoadmapPath sans EnvironmentVariable pour EnvironmentPath"; Function = { Resolve-RoadmapPath -Path "C:\folder\file.txt" -ResolutionType "EnvironmentPath" -ThrowOnFailure }; ShouldThrow = $true; Description = "EnvironmentPath sans EnvironmentVariable" }
    @{ Test = "Resolve-RoadmapPath avec variable d'environnement inexistante"; Function = { Resolve-RoadmapPath -Path "C:\folder\file.txt" -ResolutionType "EnvironmentPath" -EnvironmentVariable "NONEXISTENT_VAR_$([Guid]::NewGuid().ToString())" -ThrowOnFailure }; ShouldThrow = $true; Description = "EnvironmentPath avec variable inexistante" }
    @{ Test = "Resolve-RoadmapPath sans CustomResolution pour Custom"; Function = { Resolve-RoadmapPath -Path "C:\folder\file.txt" -ResolutionType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Custom sans CustomResolution" }
    @{ Test = "Resolve-RoadmapPath avec erreur sans ThrowOnFailure"; Function = {
            # Ce test est censé générer un warning, c'est normal
            Write-Host "Note: Le warning suivant est attendu dans le cadre du test:" -ForegroundColor Yellow
            $result = Resolve-RoadmapPath -Path "C:\folder\file.txt" -ResolutionType "EnvironmentPath"
            return $result
        }; ShouldThrow = $false; Description = "Erreur sans ThrowOnFailure"
    }
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

Write-Host "`nTests de la fonction Resolve-RoadmapPath terminés." -ForegroundColor Cyan

#
# Test-NormalizeRoadmapPath.ps1
#
# Script pour tester la fonction Normalize-RoadmapPath
#

# Importer la fonction Normalize-RoadmapPath
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathManipulation\Normalize-RoadmapPath.ps1"

# CrÃ©er le rÃ©pertoire s'il n'existe pas
$functionDir = Split-Path -Parent $functionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer la fonction
. $functionPath

Write-Host "DÃ©but des tests de la fonction Normalize-RoadmapPath..." -ForegroundColor Cyan

# Test 1: Normalisation en chemin absolu
Write-Host "`nTest 1: Normalisation en chemin absolu" -ForegroundColor Cyan

$currentDir = (Get-Location).Path
$testCases = @(
    @{ Path = ".\file.txt"; NormalizationType = "FullPath"; Expected = Join-Path -Path $currentDir -ChildPath "file.txt"; Description = "Chemin relatif simple" }
    @{ Path = "..\file.txt"; NormalizationType = "FullPath"; Expected = Join-Path -Path (Split-Path -Parent $currentDir) -ChildPath "file.txt"; Description = "Chemin relatif avec parent" }
    @{ Path = "C:\folder\file.txt"; NormalizationType = "FullPath"; Expected = "C:\folder\file.txt"; Description = "Chemin absolu Windows" }
    @{ Path = ""; NormalizationType = "FullPath"; Expected = ""; Description = "Chemin vide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path              = $testCase.Path
        NormalizationType = $testCase.NormalizationType
    }

    $result = Normalize-RoadmapPath @params

    # VÃ©rifier le rÃ©sultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Normalisation en chemin relatif
Write-Host "`nTest 2: Normalisation en chemin relatif" -ForegroundColor Cyan

$basePath = "C:\base\folder"
$testCases = @(
    @{ Path = "C:\base\folder\file.txt"; NormalizationType = "RelativePath"; BasePath = $basePath; Expected = "file.txt"; Description = "Fichier dans le mÃªme rÃ©pertoire" }
    @{ Path = "C:\base\folder\subfolder\file.txt"; NormalizationType = "RelativePath"; BasePath = $basePath; Expected = "subfolder\file.txt"; Description = "Fichier dans un sous-rÃ©pertoire" }
    @{ Path = "C:\base\file.txt"; NormalizationType = "RelativePath"; BasePath = $basePath; Expected = "..\file.txt"; Description = "Fichier dans le rÃ©pertoire parent" }
    @{ Path = "D:\other\file.txt"; NormalizationType = "RelativePath"; BasePath = $basePath; Expected = "D:\other\file.txt"; Description = "Fichier sur un autre lecteur" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path              = $testCase.Path
        NormalizationType = $testCase.NormalizationType
        BasePath          = $testCase.BasePath
    }

    $result = Normalize-RoadmapPath @params

    # VÃ©rifier le rÃ©sultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Conversion de format
Write-Host "`nTest 3: Conversion de format" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "C:\folder\file.txt"; NormalizationType = "UnixPath"; Expected = "/c/folder/file.txt"; Description = "Windows vers Unix" }
    @{ Path = "/c/folder/file.txt"; NormalizationType = "WindowsPath"; Expected = "C:\folder\file.txt"; Description = "Unix vers Windows" }
    @{ Path = "C:\folder\file.txt"; NormalizationType = "UNCPath"; Expected = "\\localhost\c$\folder\file.txt"; Description = "Windows vers UNC" }
    @{ Path = "C:\folder\file.txt"; NormalizationType = "URLPath"; Expected = "file:///c/folder/file.txt"; Description = "Windows vers URL" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path              = $testCase.Path
        NormalizationType = $testCase.NormalizationType
    }

    $result = Normalize-RoadmapPath @params

    # VÃ©rifier le rÃ©sultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Options de normalisation
Write-Host "`nTest 4: Options de normalisation" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "C:\folder\"; NormalizationType = "FullPath"; RemoveTrailingSlash = $true; Expected = "C:\folder"; Description = "Suppression de la barre oblique finale" }
    @{ Path = "C:\folder\"; NormalizationType = "FullPath"; RemoveTrailingSlash = $false; Expected = "C:\folder\"; Description = "Conservation de la barre oblique finale" }
    @{ Path = "C:\Folder\File.txt"; NormalizationType = "FullPath"; NormalizeCase = $true; Expected = "c:\folder\file.txt"; Description = "Normalisation de la casse" }
    @{ Path = ".\folder\file.txt"; NormalizationType = "RelativePath"; BasePath = "."; Expected = "folder\file.txt"; Description = "Chemin relatif avec base relative" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path              = $testCase.Path
        NormalizationType = $testCase.NormalizationType
    }

    if ($testCase.ContainsKey("RemoveTrailingSlash")) {
        $params["RemoveTrailingSlash"] = $testCase.RemoveTrailingSlash
    }

    if ($testCase.ContainsKey("NormalizeCase")) {
        $params["NormalizeCase"] = $testCase.NormalizeCase
    }

    if ($testCase.ContainsKey("ResolveRelativePaths")) {
        $params["ResolveRelativePaths"] = $testCase.ResolveRelativePaths
    }

    if ($testCase.ContainsKey("BasePath")) {
        $params["BasePath"] = $testCase.BasePath
    }

    $result = Normalize-RoadmapPath @params

    # VÃ©rifier le rÃ©sultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: Normalisation personnalisÃ©e
Write-Host "`nTest 5: Normalisation personnalisÃ©e" -ForegroundColor Cyan

$customNormalization = {
    param($Path)

    # Exemple : Ajouter un prÃ©fixe "custom:" au chemin
    return "custom:$Path"
}

$result = Normalize-RoadmapPath -Path "C:\folder\file.txt" -NormalizationType "Custom" -CustomNormalization $customNormalization

$expected = "custom:C:\folder\file.txt"
$success = $result -eq $expected

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Normalisation personnalisÃ©e: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: '$expected'" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: '$result'" -ForegroundColor Red
}

# Test 6: Gestion des erreurs
Write-Host "`nTest 6: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Normalize-RoadmapPath sans CustomNormalization pour Custom"; Function = { Normalize-RoadmapPath -Path "C:\folder\file.txt" -NormalizationType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Normalisation personnalisÃ©e sans CustomNormalization" }
    @{ Test = "Normalize-RoadmapPath avec erreur sans ThrowOnFailure"; Function = {
            # Ce test est censÃ© gÃ©nÃ©rer un warning, c'est normal
            Write-Host "Note: Le warning suivant est attendu dans le cadre du test:" -ForegroundColor Yellow
            $result = Normalize-RoadmapPath -Path "C:\folder\file.txt" -NormalizationType "Custom"
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

    # VÃ©rifier le rÃ©sultat
    $success = $testCase.ShouldThrow -eq $exceptionThrown

    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        if ($testCase.ShouldThrow) {
            Write-Host "    Exception attendue mais non levÃ©e" -ForegroundColor Red
        } else {
            Write-Host "    Exception non attendue mais levÃ©e" -ForegroundColor Red
        }
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

Write-Host "`nTests de la fonction Normalize-RoadmapPath terminÃ©s." -ForegroundColor Cyan

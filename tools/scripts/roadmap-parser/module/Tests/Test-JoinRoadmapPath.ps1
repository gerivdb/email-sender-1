#
# Test-JoinRoadmapPath.ps1
#
# Script pour tester la fonction Join-RoadmapPath
#

# Importer la fonction Join-RoadmapPath
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathManipulation\Join-RoadmapPath.ps1"

# CrÃ©er le rÃ©pertoire s'il n'existe pas
$functionDir = Split-Path -Parent $functionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer la fonction
. $functionPath

Write-Host "DÃ©but des tests de la fonction Join-RoadmapPath..." -ForegroundColor Cyan

# Test 1: Jointure simple
Write-Host "`nTest 1: Jointure simple" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "C:\folder"; ChildPath = @("file.txt"); JoinType = "Simple"; Expected = "C:\folder\file.txt"; Description = "Chemin simple" }
    @{ Path = "C:\folder"; ChildPath = @("subfolder", "file.txt"); JoinType = "Simple"; Expected = "C:\folder\subfolder\file.txt"; Description = "Chemin avec sous-dossier" }
    @{ Path = ""; ChildPath = @("file.txt"); JoinType = "Simple"; Expected = "file.txt"; Description = "Chemin vide" }
    @{ Path = "C:\folder"; ChildPath = @(""); JoinType = "Simple"; Expected = "C:\folder"; Description = "Chemin enfant vide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path      = $testCase.Path
        ChildPath = $testCase.ChildPath
        JoinType  = $testCase.JoinType
    }

    $result = Join-RoadmapPath @params

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

# Test 2: Jointure avec diffÃ©rents types
Write-Host "`nTest 2: Jointure avec diffÃ©rents types" -ForegroundColor Cyan

$testCases = @(
    @{ Path = "C:\folder"; ChildPath = @("file.txt"); JoinType = "Normalized"; Expected = "C:\folder\file.txt"; Description = "Jointure normalisÃ©e" }
    @{ Path = "C:\folder"; ChildPath = @("file.txt"); JoinType = "Relative"; Expected = "C:\folder\file.txt"; Description = "Jointure relative" }
    @{ Path = ".\folder"; ChildPath = @("file.txt"); JoinType = "Absolute"; Expected = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\folder\file.txt"; Description = "Jointure absolue" }
    @{ Path = "C:\folder"; ChildPath = @("file.txt"); JoinType = "Unix"; Expected = "C:/folder/file.txt"; Description = "Jointure Unix" }
    @{ Path = "/c/folder"; ChildPath = @("file.txt"); JoinType = "Windows"; Expected = "C:\folder\file.txt"; Description = "Jointure Windows" }
    @{ Path = "C:\folder"; ChildPath = @("file.txt"); JoinType = "UNC"; Expected = "\\localhost\c$\folder\file.txt"; Description = "Jointure UNC" }
    @{ Path = "C:\folder"; ChildPath = @("file.txt"); JoinType = "URL"; Expected = "file:///c/folder/file.txt"; Description = "Jointure URL" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path      = $testCase.Path
        ChildPath = $testCase.ChildPath
        JoinType  = $testCase.JoinType
    }

    $result = Join-RoadmapPath @params

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

# Test 3: Jointure avec options
Write-Host "`nTest 3: Jointure avec options" -ForegroundColor Cyan

$testCases = @(
    @{ Path = ".\folder"; ChildPath = @("file.txt"); JoinType = "Simple"; NormalizePaths = $true; Expected = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\folder\file.txt"; Description = "Normalisation des chemins" }
    @{ Path = ".\folder"; ChildPath = @("file.txt"); JoinType = "Simple"; ResolveRelativePaths = $true; Expected = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\folder\file.txt"; Description = "RÃ©solution des chemins relatifs" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Path      = $testCase.Path
        ChildPath = $testCase.ChildPath
        JoinType  = $testCase.JoinType
    }

    if ($testCase.ContainsKey("NormalizePaths")) {
        $params["NormalizePaths"] = $testCase.NormalizePaths
    }

    if ($testCase.ContainsKey("ResolveRelativePaths")) {
        $params["ResolveRelativePaths"] = $testCase.ResolveRelativePaths
    }

    $result = Join-RoadmapPath @params

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

# Test 4: Jointure personnalisÃ©e
Write-Host "`nTest 4: Jointure personnalisÃ©e" -ForegroundColor Cyan

$customJoin = {
    param($Path, $ChildPaths)

    # Exemple : Ajouter un prÃ©fixe "custom:" au chemin
    $result = "custom:$Path"

    foreach ($childPath in $ChildPaths) {
        if (-not [string]::IsNullOrEmpty($childPath)) {
            $result = "$result/$childPath"
        }
    }

    return $result
}

$result = Join-RoadmapPath -Path "C:\folder" -ChildPath "file.txt" -JoinType "Custom" -CustomJoin $customJoin

$expected = "custom:C:\folder/file.txt"
$success = $result -eq $expected

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Jointure personnalisÃ©e: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: '$expected'" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: '$result'" -ForegroundColor Red
}

# Test 5: Gestion des erreurs
Write-Host "`nTest 5: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Join-RoadmapPath sans CustomJoin pour Custom"; Function = { Join-RoadmapPath -Path "C:\folder" -ChildPath "file.txt" -JoinType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Jointure personnalisÃ©e sans CustomJoin" }
    @{ Test = "Join-RoadmapPath avec chemin vide pour UNC"; Function = { Join-RoadmapPath -Path "" -ChildPath "file.txt" -JoinType "UNC" -ThrowOnFailure }; ShouldThrow = $true; Description = "Jointure UNC avec chemin vide" }
    @{ Test = "Join-RoadmapPath avec chemin sans lettre de lecteur pour UNC"; Function = { Join-RoadmapPath -Path "folder" -ChildPath "file.txt" -JoinType "UNC" -ThrowOnFailure }; ShouldThrow = $true; Description = "Jointure UNC avec chemin sans lettre de lecteur" }
    @{ Test = "Join-RoadmapPath avec erreur sans ThrowOnFailure"; Function = {
            # Ce test est censÃ© gÃ©nÃ©rer un warning, c'est normal
            Write-Host "Note: Le warning suivant est attendu dans le cadre du test:" -ForegroundColor Yellow
            $result = Join-RoadmapPath -Path "C:\folder" -ChildPath "file.txt" -JoinType "Custom"
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

Write-Host "`nTests de la fonction Join-RoadmapPath terminÃ©s." -ForegroundColor Cyan

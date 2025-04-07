# test-path-utils-improved.ps1
# Script de test ameliore pour les utilitaires de gestion des chemins

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tools\path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Importer le script d'utilitaires pour les chemins
$PathUtilsScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "scripts\utils\path-utils.ps1"
if (Test-Path -Path $PathUtilsScript) {
    . $PathUtilsScript
} else {
    Write-Error "Script path-utils.ps1 non trouve: $PathUtilsScript"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Variables pour les tests
$TestsTotal = 0
$TestsPassed = 0
$TestsFailed = 0

# Fonction pour executer un test
function Test-PathFunction {
    param (
        [string]$Name,
        [scriptblock]$Test,
        [string]$Expected
    )

    $global:TestsTotal++
    
    try {
        $result = & $Test
        
        if ($result -eq $Expected) {
            Write-Host "[OK] Test $($Name): Reussi" -ForegroundColor Green
            $global:TestsPassed++
        } else {
            Write-Host "[KO] Test $($Name): Echoue" -ForegroundColor Red
            Write-Host "   Resultat: $result" -ForegroundColor Red
            Write-Host "   Attendu: $Expected" -ForegroundColor Red
            $global:TestsFailed++
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "[KO] Test $($Name): Erreur - $errorMessage" -ForegroundColor Red
        $global:TestsFailed++
    }
}

# Fonction pour executer un test avec une condition personnalisee
function Test-PathFunctionCustom {
    param (
        [string]$Name,
        [scriptblock]$Test,
        [scriptblock]$Condition
    )

    $global:TestsTotal++
    
    try {
        $result = & $Test
        $condition = & $Condition $result
        
        if ($condition) {
            Write-Host "[OK] Test $($Name): Reussi" -ForegroundColor Green
            $global:TestsPassed++
        } else {
            Write-Host "[KO] Test $($Name): Echoue" -ForegroundColor Red
            Write-Host "   Resultat: $result" -ForegroundColor Red
            $global:TestsFailed++
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "[KO] Test $($Name): Erreur - $errorMessage" -ForegroundColor Red
        $global:TestsFailed++
    }
}

# Fonction pour executer les tests
function Start-PathTests {
    Write-Host "=== Tests des utilitaires de gestion des chemins ===" -ForegroundColor Cyan
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "Repertoire de travail: $(Get-Location)" -ForegroundColor Cyan
    Write-Host ""

    # Test 1: Get-ProjectPath
    Test-PathFunctionCustom -Name "Get-ProjectPath" -Test {
        $relativePath = "scripts\utils\path-utils.ps1"
        $absolutePath = Get-ProjectPath -RelativePath $relativePath
        return $absolutePath
    } -Condition {
        param($result)
        return (Test-Path -Path $result) -and ($result -like "*\scripts\utils\path-utils.ps1")
    }

    # Test 2: Get-RelativePath
    Test-PathFunction -Name "Get-RelativePath" -Test {
        $absolutePath = Join-Path -Path (Get-Location).Path -ChildPath "scripts\utils\path-utils.ps1"
        $relativePath = Get-RelativePath -AbsolutePath $absolutePath
        return $relativePath
    } -Expected "scripts\utils\path-utils.ps1"

    # Test 3: Normalize-Path
    Test-PathFunction -Name "Normalize-Path" -Test {
        $path = "scripts/utils/path-utils.ps1"
        $normalizedPath = Normalize-Path -Path $path
        return $normalizedPath
    } -Expected "scripts\utils\path-utils.ps1"

    # Test 4: Normalize-Path avec ForceWindowsStyle
    Test-PathFunction -Name "Normalize-Path avec ForceWindowsStyle" -Test {
        $path = "scripts/utils/path-utils.ps1"
        $normalizedPath = Normalize-Path -Path $path -ForceWindowsStyle
        return $normalizedPath
    } -Expected "scripts\utils\path-utils.ps1"

    # Test 5: Normalize-Path avec ForceUnixStyle
    Test-PathFunction -Name "Normalize-Path avec ForceUnixStyle" -Test {
        $path = "scripts\utils\path-utils.ps1"
        $normalizedPath = Normalize-Path -Path $path -ForceUnixStyle
        return $normalizedPath
    } -Expected "scripts/utils/path-utils.ps1"

    # Test 6: Remove-PathAccents
    Test-PathFunction -Name "Remove-PathAccents" -Test {
        $path = "scripts/utilités/path-utils.ps1"
        $pathWithoutAccents = Remove-PathAccents -Path $path
        return $pathWithoutAccents
    } -Expected "scripts/utilites/path-utils.ps1"

    # Test 7: ConvertTo-PathWithoutSpaces
    Test-PathFunction -Name "ConvertTo-PathWithoutSpaces" -Test {
        $path = "scripts/utils test/path-utils.ps1"
        $pathWithoutSpaces = ConvertTo-PathWithoutSpaces -Path $path
        return $pathWithoutSpaces
    } -Expected "scripts/utils_test/path-utils.ps1"

    # Test 8: ConvertTo-NormalizedPath
    Test-PathFunction -Name "ConvertTo-NormalizedPath" -Test {
        $path = "scripts/utilités test/path-utils.ps1"
        $normalizedPath = ConvertTo-NormalizedPath -Path $path
        return $normalizedPath
    } -Expected "scripts\utilites_test\path-utils.ps1"

    # Test 9: Test-PathAccents
    Test-PathFunction -Name "Test-PathAccents avec accents" -Test {
        $pathWithAccents = "scripts/utilités/path-utils.ps1"
        $hasAccents = Test-PathAccents -Path $pathWithAccents
        return $hasAccents
    } -Expected "True"

    # Test 10: Test-PathAccents sans accents
    Test-PathFunction -Name "Test-PathAccents sans accents" -Test {
        $pathWithoutAccents = "scripts/utilities/path-utils.ps1"
        $hasAccents = Test-PathAccents -Path $pathWithoutAccents
        return $hasAccents
    } -Expected "False"

    # Test 11: Test-PathSpaces avec espaces
    Test-PathFunction -Name "Test-PathSpaces avec espaces" -Test {
        $pathWithSpaces = "scripts/utils test/path-utils.ps1"
        $hasSpaces = Test-PathSpaces -Path $pathWithSpaces
        return $hasSpaces
    } -Expected "True"

    # Test 12: Test-PathSpaces sans espaces
    Test-PathFunction -Name "Test-PathSpaces sans espaces" -Test {
        $pathWithoutSpaces = "scripts/utils_test/path-utils.ps1"
        $hasSpaces = Test-PathSpaces -Path $pathWithoutSpaces
        return $hasSpaces
    } -Expected "False"

    # Test 13: Find-ProjectFiles
    Test-PathFunctionCustom -Name "Find-ProjectFiles" -Test {
        $files = Find-ProjectFiles -Directory "scripts" -Pattern "*.ps1" -Recurse
        return $files
    } -Condition {
        param($result)
        return $result -is [array] -and $result.Count -gt 0
    }

    # Test 14: Add-PathMapping
    Test-PathFunctionCustom -Name "Add-PathMapping" -Test {
        Add-PathMapping -Name "test-mapping" -Path "tests\path-utils"
        $mappings = Get-PathMappings
        return $mappings["test-mapping"]
    } -Condition {
        param($result)
        return $result -like "*\tests\path-utils"
    }

    # Test 15: Test-RelativePath avec chemin relatif
    Test-PathFunction -Name "Test-RelativePath avec chemin relatif" -Test {
        $relativePath = "scripts\utils\path-utils.ps1"
        $isRelative = Test-RelativePath -Path $relativePath
        return $isRelative
    } -Expected "True"

    # Test 16: Test-RelativePath avec chemin absolu
    Test-PathFunction -Name "Test-RelativePath avec chemin absolu" -Test {
        $absolutePath = "C:\Windows\System32\notepad.exe"
        $isRelative = Test-RelativePath -Path $absolutePath
        return $isRelative
    } -Expected "False"

    # Afficher les resultats
    Write-Host ""
    Write-Host "=== Resultats des tests ===" -ForegroundColor Cyan
    Write-Host "Tests executes: $TestsTotal" -ForegroundColor White
    Write-Host "Tests reussis: $TestsPassed" -ForegroundColor Green
    Write-Host "Tests echoues: $TestsFailed" -ForegroundColor Red
    
    # Calculer le pourcentage de reussite
    $successRate = [math]::Round(($TestsPassed / $TestsTotal) * 100, 2)
    Write-Host "Taux de reussite: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
    
    Write-Host ""
    Write-Host "=== Fin des tests ===" -ForegroundColor Cyan
}

# Executer les tests
Start-PathTests

#
# Test-LoggingLevels.ps1
#
# Script pour tester les niveaux de journalisation
#

# Importer le script des niveaux de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$loggingLevelsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Logging\LoggingLevels.ps1"

# CrÃ©er le rÃ©pertoire s'il n'existe pas
$loggingLevelsDir = Split-Path -Parent $loggingLevelsPath
if (-not (Test-Path -Path $loggingLevelsDir)) {
    New-Item -Path $loggingLevelsDir -ItemType Directory -Force | Out-Null
}

# Importer le script
. $loggingLevelsPath

Write-Host "DÃ©but des tests des niveaux de journalisation..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que l'Ã©numÃ©ration LogLevel est dÃ©finie
Write-Host "`nTest 1: VÃ©rifier que l'Ã©numÃ©ration LogLevel est dÃ©finie" -ForegroundColor Cyan

$logLevelType = [RoadmapParser.Logging.LogLevel]
$success = $null -ne $logLevelType

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  VÃ©rification de l'Ã©numÃ©ration LogLevel: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    L'Ã©numÃ©ration LogLevel n'est pas dÃ©finie" -ForegroundColor Red
}

# Test 2: VÃ©rifier que les constantes sont dÃ©finies
Write-Host "`nTest 2: VÃ©rifier que les constantes sont dÃ©finies" -ForegroundColor Cyan

$constants = @(
    "LogLevelNone",
    "LogLevelDebug",
    "LogLevelVerbose",
    "LogLevelInformation",
    "LogLevelWarning",
    "LogLevelError",
    "LogLevelCritical",
    "LogLevelAll"
)

$successCount = 0
$failureCount = 0

foreach ($constant in $constants) {
    $value = Get-Variable -Name $constant -Scope Script -ErrorAction SilentlyContinue
    $success = $null -ne $value
    
    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  VÃ©rification de la constante $constant : $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    La constante $constant n'est pas dÃ©finie" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Tester la fonction Test-LogLevel
Write-Host "`nTest 3: Tester la fonction Test-LogLevel" -ForegroundColor Cyan

$testCases = @(
    @{ Value = $LogLevelDebug; Expected = $true; Description = "Instance de LogLevel" },
    @{ Value = "Debug"; Expected = $true; Description = "ChaÃ®ne de caractÃ¨res valide" },
    @{ Value = 1; Expected = $true; Description = "Entier valide" },
    @{ Value = "InvalidLevel"; Expected = $false; Description = "ChaÃ®ne de caractÃ¨res invalide" },
    @{ Value = 100; Expected = $false; Description = "Entier invalide" },
    @{ Value = $null; Expected = $false; Description = "Valeur null" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-LogLevel -LogLevel $testCase.Value
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  Test avec $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Tester la fonction ConvertTo-LogLevel
Write-Host "`nTest 4: Tester la fonction ConvertTo-LogLevel" -ForegroundColor Cyan

$testCases = @(
    @{ Value = $LogLevelDebug; Expected = $LogLevelDebug; Description = "Instance de LogLevel" },
    @{ Value = "Debug"; Expected = $LogLevelDebug; Description = "ChaÃ®ne de caractÃ¨res valide" },
    @{ Value = 1; Expected = $LogLevelDebug; Description = "Entier valide" },
    @{ Value = "InvalidLevel"; Expected = $LogLevelInformation; Description = "ChaÃ®ne de caractÃ¨res invalide avec valeur par dÃ©faut" },
    @{ Value = 100; Expected = $LogLevelInformation; Description = "Entier invalide avec valeur par dÃ©faut" },
    @{ Value = "InvalidLevel"; Expected = $LogLevelError; DefaultValue = $LogLevelError; Description = "ChaÃ®ne de caractÃ¨res invalide avec valeur par dÃ©faut personnalisÃ©e" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Value = $testCase.Value
    }
    
    if ($testCase.ContainsKey("DefaultValue")) {
        $params["DefaultValue"] = $testCase.DefaultValue
    }
    
    $result = ConvertTo-LogLevel @params
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  Test avec $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: Tester la fonction Get-LogLevelName
Write-Host "`nTest 5: Tester la fonction Get-LogLevelName" -ForegroundColor Cyan

$testCases = @(
    @{ Value = $LogLevelDebug; Expected = "Debug"; Description = "Instance de LogLevel" },
    @{ Value = "Debug"; Expected = "Debug"; Description = "ChaÃ®ne de caractÃ¨res valide" },
    @{ Value = 1; Expected = "Debug"; Description = "Entier valide" },
    @{ Value = "InvalidLevel"; Expected = "Information"; Description = "ChaÃ®ne de caractÃ¨res invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Get-LogLevelName -LogLevel $testCase.Value
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  Test avec $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 6: Tester la fonction Get-LogLevelColor
Write-Host "`nTest 6: Tester la fonction Get-LogLevelColor" -ForegroundColor Cyan

$testCases = @(
    @{ Value = $LogLevelDebug; Expected = "Gray"; Description = "Instance de LogLevel" },
    @{ Value = "Debug"; Expected = "Gray"; Description = "ChaÃ®ne de caractÃ¨res valide" },
    @{ Value = 1; Expected = "Gray"; Description = "Entier valide" },
    @{ Value = "InvalidLevel"; Expected = "Green"; Description = "ChaÃ®ne de caractÃ¨res invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Get-LogLevelColor -LogLevel $testCase.Value
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  Test avec $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 7: Tester la fonction Get-LogLevelPrefix
Write-Host "`nTest 7: Tester la fonction Get-LogLevelPrefix" -ForegroundColor Cyan

$testCases = @(
    @{ Value = $LogLevelDebug; Expected = "[DEBUG] "; Description = "Instance de LogLevel" },
    @{ Value = "Debug"; Expected = "[DEBUG] "; Description = "ChaÃ®ne de caractÃ¨res valide" },
    @{ Value = 1; Expected = "[DEBUG] "; Description = "Entier valide" },
    @{ Value = "InvalidLevel"; Expected = "[INFO] "; Description = "ChaÃ®ne de caractÃ¨res invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Get-LogLevelPrefix -LogLevel $testCase.Value
    $success = $result -eq $testCase.Expected
    
    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  Test avec $($testCase.Description): $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    RÃ©sultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    RÃ©sultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

Write-Host "`nTests des niveaux de journalisation terminÃ©s." -ForegroundColor Cyan

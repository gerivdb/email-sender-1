#
# Test-InputValidation.ps1
#
# Script pour tester les fonctions de validation d'entrÃ©es
#

# Importer le module
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $modulePath
Import-Module -Name "$modulePath\RoadmapParser.psd1" -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $modulePath -ChildPath "Tests\Temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de test
$testFilePath = Join-Path -Path $testDir -ChildPath "test.txt"
"Test" | Out-File -FilePath $testFilePath -Encoding utf8

Write-Host "DÃ©but des tests de validation d'entrÃ©es..." -ForegroundColor Cyan

# Test 1: Validation de type de donnÃ©es
Write-Host "`nTest 1: Validation de type de donnÃ©es" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "Hello"; Type = "String"; Expected = $true; Description = "ChaÃ®ne valide" }
    @{ Value = 42; Type = "Integer"; Expected = $true; Description = "Entier valide" }
    @{ Value = 3.14; Type = "Decimal"; Expected = $true; Description = "DÃ©cimal valide" }
    @{ Value = $true; Type = "Boolean"; Expected = $true; Description = "BoolÃ©en valide" }
    @{ Value = (Get-Date); Type = "DateTime"; Expected = $true; Description = "DateTime valide" }
    @{ Value = @(1, 2, 3); Type = "Array"; Expected = $true; Description = "Tableau valide" }
    @{ Value = @{ Key = "Value" }; Type = "Hashtable"; Expected = $true; Description = "Hashtable valide" }
    @{ Value = [PSCustomObject]@{ Property = "Value" }; Type = "PSObject"; Expected = $true; Description = "PSObject valide" }
    @{ Value = { Write-Host "Test" }; Type = "ScriptBlock"; Expected = $true; Description = "ScriptBlock valide" }
    @{ Value = $null; Type = "Null"; Expected = $true; Description = "Null valide" }
    @{ Value = "Not null"; Type = "NotNull"; Expected = $true; Description = "NotNull valide" }
    @{ Value = ""; Type = "Empty"; Expected = $true; Description = "ChaÃ®ne vide valide" }
    @{ Value = "Not empty"; Type = "NotEmpty"; Expected = $true; Description = "ChaÃ®ne non vide valide" }
    @{ Value = 42; Type = "String"; Expected = $false; Description = "Entier invalide pour String" }
    @{ Value = "Hello"; Type = "Integer"; Expected = $false; Description = "ChaÃ®ne invalide pour Integer" }
    @{ Value = $null; Type = "NotNull"; Expected = $false; Description = "Null invalide pour NotNull" }
    @{ Value = "Not empty"; Type = "Empty"; Expected = $false; Description = "ChaÃ®ne non vide invalide pour Empty" }
    @{ Value = ""; Type = "NotEmpty"; Expected = $false; Description = "ChaÃ®ne vide invalide pour NotEmpty" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-RoadmapInput -Value $testCase.Value -Type $testCase.Type
    $status = if ($result -eq $testCase.Expected) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Validation de format
Write-Host "`nTest 2: Validation de format" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "user@example.com"; Format = "Email"; Expected = $true; Description = "Email valide" }
    @{ Value = "https://www.example.com"; Format = "URL"; Expected = $true; Description = "URL valide" }
    @{ Value = "192.168.1.1"; Format = "IPAddress"; Expected = $true; Description = "Adresse IP valide" }
    @{ Value = "123-456-7890"; Format = "PhoneNumber"; Expected = $true; Description = "NumÃ©ro de tÃ©lÃ©phone valide" }
    @{ Value = "12345"; Format = "ZipCode"; Expected = $true; Description = "Code postal valide" }
    @{ Value = "01/01/2023"; Format = "Date"; Expected = $true; Description = "Date valide" }
    @{ Value = "12:34:56"; Format = "Time"; Expected = $true; Description = "Heure valide" }
    @{ Value = "01/01/2023 12:34:56"; Format = "DateTime"; Expected = $true; Description = "DateTime valide" }
    @{ Value = "123e4567-e89b-12d3-a456-426614174000"; Format = "Guid"; Expected = $true; Description = "GUID valide" }
    @{ Value = "C:\Windows\System32"; Format = "DirectoryPath"; Expected = $true; Description = "Chemin de rÃ©pertoire valide" }
    @{ Value = "abc123"; Format = "Custom"; Pattern = "^[a-z]+[0-9]+$"; Expected = $true; Description = "Format personnalisÃ© valide" }
    @{ Value = "invalid@"; Format = "Email"; Expected = $false; Description = "Email invalide" }
    @{ Value = "not a url"; Format = "URL"; Expected = $false; Description = "URL invalide" }
    @{ Value = "300.400.500.600"; Format = "IPAddress"; Expected = $false; Description = "Adresse IP invalide" }
    @{ Value = "123abc"; Format = "Custom"; Pattern = "^[0-9]+$"; Expected = $false; Description = "Format personnalisÃ© invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Value = $testCase.Value
        Format = $testCase.Format
    }
    
    if ($testCase.Format -eq "Custom") {
        $params["Pattern"] = $testCase.Pattern
    }
    
    $result = Test-RoadmapInput @params
    $status = if ($result -eq $testCase.Expected) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Validation de plage
Write-Host "`nTest 3: Validation de plage" -ForegroundColor Cyan

$testCases = @(
    @{ Value = 42; Min = 0; Max = 100; Expected = $true; Description = "Valeur dans la plage" }
    @{ Value = 0; Min = 0; Max = 100; Expected = $true; Description = "Valeur Ã©gale Ã  la borne infÃ©rieure" }
    @{ Value = 100; Min = 0; Max = 100; Expected = $true; Description = "Valeur Ã©gale Ã  la borne supÃ©rieure" }
    @{ Value = -1; Min = 0; Max = 100; Expected = $false; Description = "Valeur infÃ©rieure Ã  la borne infÃ©rieure" }
    @{ Value = 101; Min = 0; Max = 100; Expected = $false; Description = "Valeur supÃ©rieure Ã  la borne supÃ©rieure" }
    @{ Value = "Hello"; MinLength = 3; MaxLength = 10; Expected = $true; Description = "ChaÃ®ne de longueur valide" }
    @{ Value = "Hi"; MinLength = 3; MaxLength = 10; Expected = $false; Description = "ChaÃ®ne trop courte" }
    @{ Value = "Hello World!"; MinLength = 3; MaxLength = 10; Expected = $false; Description = "ChaÃ®ne trop longue" }
    @{ Value = @(1, 2, 3); MinCount = 1; MaxCount = 5; Expected = $true; Description = "Tableau de taille valide" }
    @{ Value = @(); MinCount = 1; MaxCount = 5; Expected = $false; Description = "Tableau vide" }
    @{ Value = @(1, 2, 3, 4, 5, 6); MinCount = 1; MaxCount = 5; Expected = $false; Description = "Tableau trop grand" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Value = $testCase.Value
    }
    
    if ($testCase.ContainsKey("Min")) { $params["Min"] = $testCase.Min }
    if ($testCase.ContainsKey("Max")) { $params["Max"] = $testCase.Max }
    if ($testCase.ContainsKey("MinLength")) { $params["MinLength"] = $testCase.MinLength }
    if ($testCase.ContainsKey("MaxLength")) { $params["MaxLength"] = $testCase.MaxLength }
    if ($testCase.ContainsKey("MinCount")) { $params["MinCount"] = $testCase.MinCount }
    if ($testCase.ContainsKey("MaxCount")) { $params["MaxCount"] = $testCase.MaxCount }
    
    $result = Test-RoadmapInput @params
    $status = if ($result -eq $testCase.Expected) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Validation personnalisÃ©e
Write-Host "`nTest 4: Validation personnalisÃ©e" -ForegroundColor Cyan

$testCases = @(
    @{ Value = 42; ValidationFunction = { param($val) $val -gt 0 -and $val -lt 100 }; Expected = $true; Description = "Fonction de validation valide" }
    @{ Value = -1; ValidationFunction = { param($val) $val -gt 0 -and $val -lt 100 }; Expected = $false; Description = "Fonction de validation invalide" }
    @{ Value = "Hello"; ValidationScript = { param($val) $val.Length -gt 3 }; Expected = $true; Description = "Script de validation valide" }
    @{ Value = "Hi"; ValidationScript = { param($val) $val.Length -gt 3 }; Expected = $false; Description = "Script de validation invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Value = $testCase.Value
    }
    
    if ($testCase.ContainsKey("ValidationFunction")) {
        $params["ValidationFunction"] = $testCase.ValidationFunction
    } elseif ($testCase.ContainsKey("ValidationScript")) {
        $params["ValidationScript"] = $testCase.ValidationScript
    }
    
    $result = Test-RoadmapInput @params
    $status = if ($result -eq $testCase.Expected) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: Validation combinÃ©e
Write-Host "`nTest 5: Validation combinÃ©e" -ForegroundColor Cyan

$testCases = @(
    @{
        Value = "user@example.com"
        Type = "String"
        Format = "Email"
        MinLength = 5
        MaxLength = 50
        ValidationFunction = { param($val) $val -match "@example\.com$" }
        Expected = $true
        Description = "Email valide avec plusieurs validations"
    }
    @{
        Value = "user@invalid.com"
        Type = "String"
        Format = "Email"
        MinLength = 5
        MaxLength = 50
        ValidationFunction = { param($val) $val -match "@example\.com$" }
        Expected = $false
        Description = "Email invalide avec validation personnalisÃ©e"
    }
    @{
        Value = 42
        Type = "Integer"
        Min = 0
        Max = 100
        ValidationFunction = { param($val) $val % 2 -eq 0 }
        Expected = $true
        Description = "Entier valide avec plusieurs validations"
    }
    @{
        Value = 43
        Type = "Integer"
        Min = 0
        Max = 100
        ValidationFunction = { param($val) $val % 2 -eq 0 }
        Expected = $false
        Description = "Entier invalide avec validation personnalisÃ©e"
    }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{}
    
    foreach ($key in $testCase.Keys) {
        if ($key -ne "Expected" -and $key -ne "Description") {
            $params[$key] = $testCase[$key]
        }
    }
    
    $result = Test-RoadmapInput @params
    $status = if ($result -eq $testCase.Expected) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 6: Validation avec ThrowOnFailure
Write-Host "`nTest 6: Validation avec ThrowOnFailure" -ForegroundColor Cyan

$testCases = @(
    @{
        Value = "user@example.com"
        Type = "String"
        Format = "Email"
        ThrowOnFailure = $true
        ShouldThrow = $false
        Description = "Email valide ne devrait pas lever d'exception"
    }
    @{
        Value = "invalid"
        Type = "String"
        Format = "Email"
        ThrowOnFailure = $true
        ShouldThrow = $true
        Description = "Email invalide devrait lever une exception"
    }
    @{
        Value = 42
        Type = "Integer"
        Min = 0
        Max = 100
        ThrowOnFailure = $true
        ShouldThrow = $false
        Description = "Entier valide ne devrait pas lever d'exception"
    }
    @{
        Value = -1
        Type = "Integer"
        Min = 0
        Max = 100
        ThrowOnFailure = $true
        ShouldThrow = $true
        Description = "Entier invalide devrait lever une exception"
    }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{}
    
    foreach ($key in $testCase.Keys) {
        if ($key -ne "ShouldThrow" -and $key -ne "Description") {
            $params[$key] = $testCase[$key]
        }
    }
    
    $exceptionThrown = $false
    
    try {
        $null = Test-RoadmapInput @params
    } catch {
        $exceptionThrown = $true
    }
    
    $status = if ($exceptionThrown -eq $testCase.ShouldThrow) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($exceptionThrown -eq $testCase.ShouldThrow) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($exceptionThrown -eq $testCase.ShouldThrow) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 7: Validation avec message d'erreur personnalisÃ©
Write-Host "`nTest 7: Validation avec message d'erreur personnalisÃ©" -ForegroundColor Cyan

$customErrorMessage = "Message d'erreur personnalisÃ©"
$exceptionMessage = $null

try {
    $null = Test-RoadmapInput -Value "invalid" -Format "Email" -ErrorMessage $customErrorMessage -ThrowOnFailure
} catch {
    $exceptionMessage = $_.Exception.Message
}

if ($exceptionMessage -eq $customErrorMessage) {
    Write-Host "  Message d'erreur personnalisÃ©: RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "  Message d'erreur personnalisÃ©: Ã‰chouÃ©" -ForegroundColor Red
    Write-Host "  Message attendu: $customErrorMessage" -ForegroundColor Red
    Write-Host "  Message reÃ§u: $exceptionMessage" -ForegroundColor Red
}

# Nettoyer les fichiers de test
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

Write-Host "`nTests de validation d'entrÃ©es terminÃ©s." -ForegroundColor Cyan

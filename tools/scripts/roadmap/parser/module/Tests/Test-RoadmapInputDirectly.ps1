#
# Test-RoadmapInputDirectly.ps1
#
# Script pour tester la fonction Test-RoadmapInput directement
#

# Importer les fonctions de validation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$validationPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Validation"

# Importer les fonctions de validation
. "$validationPath\Test-DataType.ps1"
. "$validationPath\Test-Format.ps1"
. "$validationPath\Test-Range.ps1"
. "$validationPath\Test-Custom.ps1"

# Définir la fonction Test-RoadmapInput
function Test-RoadmapInput {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Null", "NotNull", "Empty", "NotEmpty")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Email", "URL", "IPAddress", "PhoneNumber", "ZipCode", "Date", "Time", "DateTime", "Guid", "FilePath", "DirectoryPath", "Custom")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        $Min,

        [Parameter(Mandatory = $false)]
        $Max,

        [Parameter(Mandatory = $false)]
        [int]$MinLength,

        [Parameter(Mandatory = $false)]
        [int]$MaxLength,

        [Parameter(Mandatory = $false)]
        [int]$MinCount,

        [Parameter(Mandatory = $false)]
        [int]$MaxCount,

        [Parameter(Mandatory = $false, ParameterSetName = "Function")]
        [scriptblock]$ValidationFunction,

        [Parameter(Mandatory = $false, ParameterSetName = "Script")]
        [scriptblock]$ValidationScript,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat de la validation
    $isValid = $true

    # Valider le type de données
    if ($PSBoundParameters.ContainsKey('Type')) {
        $dataTypeParams = @{
            Value = $Value
            Type = $Type
            ThrowOnFailure = $false
        }
        
        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $dataTypeParams['ErrorMessage'] = $ErrorMessage
        }
        
        $isValid = $isValid -and (Test-DataType @dataTypeParams)
        
        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas au type de données $Type."
            }
            
            throw $errorMsg
        }
    }

    # Valider le format
    if ($PSBoundParameters.ContainsKey('Format') -and $isValid) {
        $formatParams = @{
            Value = $Value
            Format = $Format
            ThrowOnFailure = $false
        }
        
        if ($PSBoundParameters.ContainsKey('Pattern')) {
            $formatParams['Pattern'] = $Pattern
        }
        
        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $formatParams['ErrorMessage'] = $ErrorMessage
        }
        
        $isValid = $isValid -and (Test-Format @formatParams)
        
        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas au format $Format."
            }
            
            throw $errorMsg
        }
    }

    # Valider la plage
    if (($PSBoundParameters.ContainsKey('Min') -or $PSBoundParameters.ContainsKey('Max') -or
         $PSBoundParameters.ContainsKey('MinLength') -or $PSBoundParameters.ContainsKey('MaxLength') -or
         $PSBoundParameters.ContainsKey('MinCount') -or $PSBoundParameters.ContainsKey('MaxCount')) -and $isValid) {
        $rangeParams = @{
            Value = $Value
            ThrowOnFailure = $false
        }
        
        if ($PSBoundParameters.ContainsKey('Min')) {
            $rangeParams['Min'] = $Min
        }
        
        if ($PSBoundParameters.ContainsKey('Max')) {
            $rangeParams['Max'] = $Max
        }
        
        if ($PSBoundParameters.ContainsKey('MinLength')) {
            $rangeParams['MinLength'] = $MinLength
        }
        
        if ($PSBoundParameters.ContainsKey('MaxLength')) {
            $rangeParams['MaxLength'] = $MaxLength
        }
        
        if ($PSBoundParameters.ContainsKey('MinCount')) {
            $rangeParams['MinCount'] = $MinCount
        }
        
        if ($PSBoundParameters.ContainsKey('MaxCount')) {
            $rangeParams['MaxCount'] = $MaxCount
        }
        
        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $rangeParams['ErrorMessage'] = $ErrorMessage
        }
        
        $isValid = $isValid -and (Test-Range @rangeParams)
        
        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas à la plage spécifiée."
            }
            
            throw $errorMsg
        }
    }

    # Valider avec une fonction personnalisée
    if (($PSBoundParameters.ContainsKey('ValidationFunction') -or $PSBoundParameters.ContainsKey('ValidationScript')) -and $isValid) {
        $customParams = @{
            Value = $Value
            ThrowOnFailure = $false
        }
        
        if ($PSBoundParameters.ContainsKey('ValidationFunction')) {
            $customParams['ValidationFunction'] = $ValidationFunction
        }
        
        if ($PSBoundParameters.ContainsKey('ValidationScript')) {
            $customParams['ValidationScript'] = $ValidationScript
        }
        
        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $customParams['ErrorMessage'] = $ErrorMessage
        }
        
        $isValid = $isValid -and (Test-Custom @customParams)
        
        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas aux critères de validation personnalisés."
            }
            
            throw $errorMsg
        }
    }

    return $isValid
}

Write-Host "Début des tests de la fonction Test-RoadmapInput..." -ForegroundColor Cyan

# Test 1: Validation de type de données
Write-Host "`nTest 1: Validation de type de données" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "Hello"; Type = "String"; Expected = $true; Description = "Chaîne valide" }
    @{ Value = 42; Type = "Integer"; Expected = $true; Description = "Entier valide" }
    @{ Value = 42; Type = "String"; Expected = $false; Description = "Entier invalide pour String" }
    @{ Value = "Hello"; Type = "Integer"; Expected = $false; Description = "Chaîne invalide pour Integer" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-RoadmapInput -Value $testCase.Value -Type $testCase.Type
    $status = if ($result -eq $testCase.Expected) { "Réussi" } else { "Échoué" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Validation de format
Write-Host "`nTest 2: Validation de format" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "user@example.com"; Format = "Email"; Expected = $true; Description = "Email valide" }
    @{ Value = "invalid@"; Format = "Email"; Expected = $false; Description = "Email invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-RoadmapInput -Value $testCase.Value -Format $testCase.Format
    $status = if ($result -eq $testCase.Expected) { "Réussi" } else { "Échoué" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Validation de plage
Write-Host "`nTest 3: Validation de plage" -ForegroundColor Cyan

$testCases = @(
    @{ Value = 42; Min = 0; Max = 100; Expected = $true; Description = "Valeur dans la plage" }
    @{ Value = 101; Min = 0; Max = 100; Expected = $false; Description = "Valeur hors de la plage" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-RoadmapInput -Value $testCase.Value -Min $testCase.Min -Max $testCase.Max
    $status = if ($result -eq $testCase.Expected) { "Réussi" } else { "Échoué" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Validation de longueur
Write-Host "`nTest 4: Validation de longueur" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "Hello"; MinLength = 3; MaxLength = 10; Expected = $true; Description = "Chaîne de longueur valide" }
    @{ Value = "Hi"; MinLength = 3; MaxLength = 10; Expected = $false; Description = "Chaîne trop courte" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-RoadmapInput -Value $testCase.Value -MinLength $testCase.MinLength -MaxLength $testCase.MaxLength
    $status = if ($result -eq $testCase.Expected) { "Réussi" } else { "Échoué" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: Validation personnalisée
Write-Host "`nTest 5: Validation personnalisée" -ForegroundColor Cyan

$testCases = @(
    @{ Value = 42; ValidationFunction = { param($val) $val -gt 0 -and $val -lt 100 }; Expected = $true; Description = "Fonction de validation valide" }
    @{ Value = -1; ValidationFunction = { param($val) $val -gt 0 -and $val -lt 100 }; Expected = $false; Description = "Fonction de validation invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-RoadmapInput -Value $testCase.Value -ValidationFunction $testCase.ValidationFunction
    $status = if ($result -eq $testCase.Expected) { "Réussi" } else { "Échoué" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 6: Validation combinée
Write-Host "`nTest 6: Validation combinée" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "user@example.com"; Type = "String"; Format = "Email"; MinLength = 5; MaxLength = 50; Expected = $true; Description = "Validation combinée valide" }
    @{ Value = "user@example.com"; Type = "String"; Format = "Email"; MinLength = 20; MaxLength = 50; Expected = $false; Description = "Validation combinée invalide" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $result = Test-RoadmapInput -Value $testCase.Value -Type $testCase.Type -Format $testCase.Format -MinLength $testCase.MinLength -MaxLength $testCase.MaxLength
    $status = if ($result -eq $testCase.Expected) { "Réussi" } else { "Échoué" }
    $color = if ($result -eq $testCase.Expected) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($result -eq $testCase.Expected) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 7: Validation avec ThrowOnFailure
Write-Host "`nTest 7: Validation avec ThrowOnFailure" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "user@example.com"; Format = "Email"; ThrowOnFailure = $true; ShouldThrow = $false; Description = "Email valide ne devrait pas lever d'exception" }
    @{ Value = "invalid@"; Format = "Email"; ThrowOnFailure = $true; ShouldThrow = $true; Description = "Email invalide devrait lever une exception" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $exceptionThrown = $false
    
    try {
        $null = Test-RoadmapInput -Value $testCase.Value -Format $testCase.Format -ThrowOnFailure:$testCase.ThrowOnFailure
    } catch {
        $exceptionThrown = $true
    }
    
    $status = if ($exceptionThrown -eq $testCase.ShouldThrow) { "Réussi" } else { "Échoué" }
    $color = if ($exceptionThrown -eq $testCase.ShouldThrow) { "Green" } else { "Red" }
    
    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color
    
    if ($exceptionThrown -eq $testCase.ShouldThrow) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 8: Validation avec message d'erreur personnalisé
Write-Host "`nTest 8: Validation avec message d'erreur personnalisé" -ForegroundColor Cyan

$customErrorMessage = "Message d'erreur personnalisé"
$exceptionMessage = $null

try {
    $null = Test-RoadmapInput -Value "invalid@" -Format "Email" -ErrorMessage $customErrorMessage -ThrowOnFailure
} catch {
    $exceptionMessage = $_.Exception.Message
}

if ($exceptionMessage -eq $customErrorMessage) {
    Write-Host "  Message d'erreur personnalisé: Réussi" -ForegroundColor Green
} else {
    Write-Host "  Message d'erreur personnalisé: Échoué" -ForegroundColor Red
    Write-Host "  Message attendu: $customErrorMessage" -ForegroundColor Red
    Write-Host "  Message reçu: $exceptionMessage" -ForegroundColor Red
}

Write-Host "`nTests de la fonction Test-RoadmapInput terminés." -ForegroundColor Cyan

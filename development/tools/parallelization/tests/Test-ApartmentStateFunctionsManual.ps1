# Script de test manuel pour les fonctions de conversion ApartmentState
# Ce script teste directement les fonctions sans dépendre de Pester

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Tester ConvertTo-ApartmentState
Write-Host "`n=== Tests pour ConvertTo-ApartmentState ===" -ForegroundColor Magenta
try {
    $result = ConvertTo-ApartmentState -Value "STA"
    Write-Host "ConvertTo-ApartmentState -Value 'STA' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-ApartmentState -Value "MTA"
    Write-Host "ConvertTo-ApartmentState -Value 'MTA' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-ApartmentState -Value "sta"
    Write-Host "ConvertTo-ApartmentState -Value 'sta' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-ApartmentState -Value "InvalidValue" -DefaultValue ([System.Threading.ApartmentState]::MTA)
    Write-Host "ConvertTo-ApartmentState -Value 'InvalidValue' -DefaultValue MTA = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-ApartmentState -Value "InvalidValue"
    Write-Host "ConvertTo-ApartmentState -Value 'InvalidValue' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR (attendue): $_" -ForegroundColor Yellow
}

# Tester ConvertFrom-ApartmentState
Write-Host "`n=== Tests pour ConvertFrom-ApartmentState ===" -ForegroundColor Magenta
try {
    $result = ConvertFrom-ApartmentState -EnumValue ([System.Threading.ApartmentState]::STA)
    Write-Host "ConvertFrom-ApartmentState -EnumValue STA = '$result' (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertFrom-ApartmentState -EnumValue ([System.Threading.ApartmentState]::MTA)
    Write-Host "ConvertFrom-ApartmentState -EnumValue MTA = '$result' (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertFrom-ApartmentState -EnumValue "NotAnEnum"
    Write-Host "ConvertFrom-ApartmentState -EnumValue 'NotAnEnum' = '$result' (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR (attendue): $_" -ForegroundColor Yellow
}

# Tester Test-ApartmentState
Write-Host "`n=== Tests pour Test-ApartmentState ===" -ForegroundColor Magenta
try {
    $result = Test-ApartmentState -Value ([System.Threading.ApartmentState]::STA)
    Write-Host "Test-ApartmentState -Value STA = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-ApartmentState -Value "STA"
    Write-Host "Test-ApartmentState -Value 'STA' = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-ApartmentState -Value "sta"
    Write-Host "Test-ApartmentState -Value 'sta' = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-ApartmentState -Value "sta" -IgnoreCase $false
    Write-Host "Test-ApartmentState -Value 'sta' -IgnoreCase `$false = $result" -ForegroundColor $(if (!$result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-ApartmentState -Value 0
    Write-Host "Test-ApartmentState -Value 0 = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-ApartmentState -Value 1
    Write-Host "Test-ApartmentState -Value 1 = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-ApartmentState -Value "InvalidValue"
    Write-Host "Test-ApartmentState -Value 'InvalidValue' = $result" -ForegroundColor $(if (!$result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-ApartmentState -Value 999
    Write-Host "Test-ApartmentState -Value 999 = $result" -ForegroundColor $(if (!$result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

Write-Host "`n=== Tests terminés ===" -ForegroundColor Cyan

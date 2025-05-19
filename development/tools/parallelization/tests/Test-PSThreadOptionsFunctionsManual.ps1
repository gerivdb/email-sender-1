# Script de test manuel pour les fonctions de conversion PSThreadOptions
# Ce script teste directement les fonctions sans dépendre de Pester

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Tester ConvertTo-PSThreadOptions
Write-Host "`n=== Tests pour ConvertTo-PSThreadOptions ===" -ForegroundColor Magenta
try {
    $result = ConvertTo-PSThreadOptions -Value "Default"
    Write-Host "ConvertTo-PSThreadOptions -Value 'Default' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-PSThreadOptions -Value "UseNewThread"
    Write-Host "ConvertTo-PSThreadOptions -Value 'UseNewThread' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-PSThreadOptions -Value "ReuseThread"
    Write-Host "ConvertTo-PSThreadOptions -Value 'ReuseThread' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-PSThreadOptions -Value "default"
    Write-Host "ConvertTo-PSThreadOptions -Value 'default' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-PSThreadOptions -Value "InvalidValue" -DefaultValue ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
    Write-Host "ConvertTo-PSThreadOptions -Value 'InvalidValue' -DefaultValue Default = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertTo-PSThreadOptions -Value "InvalidValue"
    Write-Host "ConvertTo-PSThreadOptions -Value 'InvalidValue' = $result (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR (attendue): $_" -ForegroundColor Yellow
}

# Tester ConvertFrom-PSThreadOptions
Write-Host "`n=== Tests pour ConvertFrom-PSThreadOptions ===" -ForegroundColor Magenta
try {
    $result = ConvertFrom-PSThreadOptions -EnumValue ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
    Write-Host "ConvertFrom-PSThreadOptions -EnumValue Default = '$result' (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertFrom-PSThreadOptions -EnumValue ([System.Management.Automation.Runspaces.PSThreadOptions]::UseNewThread)
    Write-Host "ConvertFrom-PSThreadOptions -EnumValue UseNewThread = '$result' (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertFrom-PSThreadOptions -EnumValue ([System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread)
    Write-Host "ConvertFrom-PSThreadOptions -EnumValue ReuseThread = '$result' (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = ConvertFrom-PSThreadOptions -EnumValue "NotAnEnum"
    Write-Host "ConvertFrom-PSThreadOptions -EnumValue 'NotAnEnum' = '$result' (Type: $($result.GetType().FullName))" -ForegroundColor Green
} catch {
    Write-Host "ERREUR (attendue): $_" -ForegroundColor Yellow
}

# Tester Test-PSThreadOptions
Write-Host "`n=== Tests pour Test-PSThreadOptions ===" -ForegroundColor Magenta
try {
    $result = Test-PSThreadOptions -Value ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
    Write-Host "Test-PSThreadOptions -Value Default = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value "Default"
    Write-Host "Test-PSThreadOptions -Value 'Default' = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value "default"
    Write-Host "Test-PSThreadOptions -Value 'default' = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value "default" -IgnoreCase $false
    Write-Host "Test-PSThreadOptions -Value 'default' -IgnoreCase `$false = $result" -ForegroundColor $(if (!$result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value 0
    Write-Host "Test-PSThreadOptions -Value 0 = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value 1
    Write-Host "Test-PSThreadOptions -Value 1 = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value 2
    Write-Host "Test-PSThreadOptions -Value 2 = $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value "InvalidValue"
    Write-Host "Test-PSThreadOptions -Value 'InvalidValue' = $result" -ForegroundColor $(if (!$result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

try {
    $result = Test-PSThreadOptions -Value 999
    Write-Host "Test-PSThreadOptions -Value 999 = $result" -ForegroundColor $(if (!$result) { "Green" } else { "Red" })
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

Write-Host "`n=== Tests terminés ===" -ForegroundColor Cyan

﻿# Script pour exÃ©cuter les tests avec le bon encodage de console

# Configurer l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Afficher les informations d'encodage
Write-Host "Encodage de la console configurÃ© :" -ForegroundColor Green
Write-Host "Console::OutputEncoding = $([Console]::OutputEncoding.WebName)" -ForegroundColor Cyan
Write-Host "OutputEncoding = $($OutputEncoding.WebName)" -ForegroundColor Cyan
Write-Host "PSDefaultParameterValues['Out-File:Encoding'] = $($PSDefaultParameterValues['Out-File:Encoding'])" -ForegroundColor Cyan
Write-Host ""

# Fonction pour exÃ©cuter un test avec le bon encodage
function Invoke-EncodedTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestScript
    )
    
    Write-Host "ExÃ©cution du test : $TestScript" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------" -ForegroundColor Yellow
    
    # ExÃ©cuter le script de test
    & $TestScript
    
    Write-Host "-----------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Test terminÃ© : $TestScript" -ForegroundColor Yellow
    Write-Host ""
}

# ExÃ©cuter les tests
Invoke-EncodedTest -TestScript ".\development\testing\tests\test_module_functions.ps1"
Invoke-EncodedTest -TestScript ".\development\testing\tests\test_predict_cascades.ps1"
Invoke-EncodedTest -TestScript ".\development\testing\tests\test_integrate_omnibus_direct.ps1"

# VÃ©rifier l'encodage des fichiers gÃ©nÃ©rÃ©s
Write-Host "VÃ©rification de l'encodage des fichiers gÃ©nÃ©rÃ©s :" -ForegroundColor Green
$filesToCheck = @(
    ".\development\testing\tests\test_integration_report.md",
    ".\development\testing\tests\test_cascade_report.md",
    ".\development\testing\tests\TestOmnibus\hooks\ErrorPatternAnalyzer.ps1"
)

foreach ($file in $filesToCheck) {
    if (Test-Path -Path $file) {
        # Lire les premiers octets du fichier pour dÃ©tecter le BOM
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $hasBom = $false
        
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $hasBom = $true
            $encoding = "UTF-8 with BOM"
        } else {
            $encoding = "UTF-8 without BOM or other encoding"
        }
        
        Write-Host "Fichier : $file" -ForegroundColor Cyan
        Write-Host "  Encodage : $encoding" -ForegroundColor $(if ($hasBom) { "Green" } else { "Red" })
        
        # Si le fichier n'a pas de BOM, le corriger
        if (-not $hasBom) {
            Write-Host "  Correction de l'encodage..." -ForegroundColor Yellow
            $content = Get-Content -Path $file -Raw
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText($file, $content, $utf8WithBom)
            Write-Host "  Encodage corrigÃ© en UTF-8 avec BOM" -ForegroundColor Green
        }
    } else {
        Write-Host "Fichier non trouvÃ© : $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Tous les tests ont Ã©tÃ© exÃ©cutÃ©s avec le bon encodage" -ForegroundColor Green

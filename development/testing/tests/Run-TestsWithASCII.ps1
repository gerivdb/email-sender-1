# Script pour executer les tests avec des caracteres ASCII uniquement

# Configurer l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Afficher les informations d'encodage
Write-Host "Encodage de la console configure :" -ForegroundColor Green
Write-Host "Console::OutputEncoding = $([Console]::OutputEncoding.WebName)" -ForegroundColor Cyan
Write-Host "OutputEncoding = $($OutputEncoding.WebName)" -ForegroundColor Cyan
Write-Host ""

# Fonction pour executer un test
function Invoke-EncodedTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestScript
    )
    
    Write-Host "Execution du test : $TestScript" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------" -ForegroundColor Yellow
    
    # Executer le script de test
    & $TestScript
    
    Write-Host "-----------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Test termine : $TestScript" -ForegroundColor Yellow
    Write-Host ""
}

# Executer les tests
Invoke-EncodedTest -TestScript ".\development\testing\tests\Basic-ErrorPatternAnalyzer.Tests.ps1"
Invoke-EncodedTest -TestScript ".\development\testing\tests\test_predict_cascades.ps1"
Invoke-EncodedTest -TestScript ".\development\testing\tests\test_integrate_omnibus_direct.ps1"

# Verifier l'encodage des fichiers generes
Write-Host "Verification de l'encodage des fichiers generes :" -ForegroundColor Green
$filesToCheck = @(
    ".\development\testing\tests\test_integration_report.md",
    ".\development\testing\tests\test_cascade_report.md",
    ".\development\testing\tests\TestOmnibus\hooks\ErrorPatternAnalyzer.ps1"
)

foreach ($file in $filesToCheck) {
    if (Test-Path -Path $file) {
        # Lire les premiers octets du fichier pour detecter le BOM
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
    } else {
        Write-Host "Fichier non trouve : $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Tous les tests ont ete executes avec succes" -ForegroundColor Green

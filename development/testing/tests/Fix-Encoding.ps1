# Script pour corriger l'encodage des fichiers

# Définir l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Fonction pour corriger l'encodage d'un fichier
function Fix-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    Write-Host "Correction de l'encodage du fichier: $FilePath"
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Créer un encodeur UTF-8 avec BOM
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    
    # Écrire le contenu avec le nouvel encodage
    [System.IO.File]::WriteAllText($FilePath, $content, $utf8WithBom)
    
    Write-Host "Encodage corrigé en UTF-8 avec BOM" -ForegroundColor Green
}

# Corriger l'encodage des fichiers PowerShell
$psFiles = @(
    ".\development\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1",
    ".\development\scripts\maintenance\error-learning\Train-ErrorPatternModel.ps1",
    ".\development\scripts\maintenance\error-learning\Predict-ErrorCascades.ps1",
    ".\development\scripts\maintenance\error-learning\Integrate-WithTestOmnibus.ps1",
    ".\development\testing\tests\test_module_functions.ps1",
    ".\development\testing\tests\test_predict_cascades.ps1",
    ".\development\testing\tests\test_integrate_omnibus_direct.ps1",
    ".\development\testing\tests\TestOmnibus\hooks\ErrorPatternAnalyzer.ps1"
)

foreach ($file in $psFiles) {
    if (Test-Path -Path $file) {
        Fix-FileEncoding -FilePath $file
    } else {
        Write-Host "Le fichier $file n'existe pas" -ForegroundColor Yellow
    }
}

# Corriger l'encodage des fichiers Markdown
$mdFiles = @(
    ".\development\testing\tests\test_integration_report.md",
    ".\development\testing\tests\test_cascade_report.md"
)

foreach ($file in $mdFiles) {
    if (Test-Path -Path $file) {
        Fix-FileEncoding -FilePath $file
    } else {
        Write-Host "Le fichier $file n'existe pas" -ForegroundColor Yellow
    }
}

Write-Host "Correction de l'encodage terminée" -ForegroundColor Green

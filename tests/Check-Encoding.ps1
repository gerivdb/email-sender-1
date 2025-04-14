# Script pour vérifier l'encodage des fichiers

# Définir l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Fonction pour vérifier l'encodage d'un fichier
function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Lire les premiers octets du fichier
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    
    # Vérifier la présence du BOM UTF-8
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return "UTF-8 with BOM"
    }
    
    # Vérifier la présence du BOM UTF-16 LE
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return "UTF-16 LE with BOM"
    }
    
    # Vérifier la présence du BOM UTF-16 BE
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return "UTF-16 BE with BOM"
    }
    
    # Vérifier la présence du BOM UTF-32 LE
    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
        return "UTF-32 LE with BOM"
    }
    
    # Vérifier la présence du BOM UTF-32 BE
    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
        return "UTF-32 BE with BOM"
    }
    
    # Si aucun BOM n'est détecté, essayer de déterminer l'encodage
    $encoding = "Unknown"
    
    # Vérifier si le fichier est probablement UTF-8 sans BOM
    $isUtf8 = $true
    $i = 0
    while ($i -lt $bytes.Length) {
        if ($bytes[$i] -lt 0x80) {
            $i++
        } elseif ($bytes[$i] -ge 0xC2 -and $bytes[$i] -le 0xDF -and $i + 1 -lt $bytes.Length -and $bytes[$i + 1] -ge 0x80 -and $bytes[$i + 1] -le 0xBF) {
            $i += 2
        } elseif ($bytes[$i] -ge 0xE0 -and $bytes[$i] -le 0xEF -and $i + 2 -lt $bytes.Length -and $bytes[$i + 1] -ge 0x80 -and $bytes[$i + 1] -le 0xBF -and $bytes[$i + 2] -ge 0x80 -and $bytes[$i + 2] -le 0xBF) {
            $i += 3
        } elseif ($bytes[$i] -ge 0xF0 -and $bytes[$i] -le 0xF4 -and $i + 3 -lt $bytes.Length -and $bytes[$i + 1] -ge 0x80 -and $bytes[$i + 1] -le 0xBF -and $bytes[$i + 2] -ge 0x80 -and $bytes[$i + 2] -le 0xBF -and $bytes[$i + 3] -ge 0x80 -and $bytes[$i + 3] -le 0xBF) {
            $i += 4
        } else {
            $isUtf8 = $false
            break
        }
    }
    
    if ($isUtf8) {
        $encoding = "UTF-8 without BOM"
    } else {
        $encoding = "ASCII or other"
    }
    
    return $encoding
}

# Vérifier l'encodage des fichiers PowerShell
$psFiles = @(
    ".\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1",
    ".\scripts\maintenance\error-learning\Train-ErrorPatternModel.ps1",
    ".\scripts\maintenance\error-learning\Predict-ErrorCascades.ps1",
    ".\scripts\maintenance\error-learning\Integrate-WithTestOmnibus.ps1",
    ".\tests\test_module_functions.ps1",
    ".\tests\test_predict_cascades.ps1",
    ".\tests\test_integrate_omnibus_direct.ps1",
    ".\tests\TestOmnibus\hooks\ErrorPatternAnalyzer.ps1"
)

foreach ($file in $psFiles) {
    if (Test-Path -Path $file) {
        $encoding = Get-FileEncoding -FilePath $file
        Write-Host "Encodage du fichier $file : $encoding"
    } else {
        Write-Host "Le fichier $file n'existe pas" -ForegroundColor Yellow
    }
}

# Vérifier l'encodage des fichiers Markdown
$mdFiles = @(
    ".\tests\test_integration_report.md",
    ".\tests\test_cascade_report.md"
)

foreach ($file in $mdFiles) {
    if (Test-Path -Path $file) {
        $encoding = Get-FileEncoding -FilePath $file
        Write-Host "Encodage du fichier $file : $encoding"
    } else {
        Write-Host "Le fichier $file n'existe pas" -ForegroundColor Yellow
    }
}

Write-Host "Vérification de l'encodage terminée" -ForegroundColor Green

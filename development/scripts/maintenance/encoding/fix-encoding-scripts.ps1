# Script pour corriger l'encodage des fichiers PowerShell
# Ce script convertit tous les fichiers .ps1 en UTF-8 avec BOM pour assurer la compatibilitÃ© avec les caractÃ¨res franÃ§ais

Write-Host "=== Correction de l'encodage des fichiers PowerShell ===" -ForegroundColor Cyan

# Fonction pour convertir un fichier en UTF-8 avec BOM
function ConvertTo-UTF8WithBOM {
    param (
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fichier converti: $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la conversion du fichier $FilePath : $_" -ForegroundColor Red
    }
}

# Rechercher tous les fichiers PowerShell dans le projet
$scriptFiles = Get-ChildItem -Path . -Filter "*.ps1" -Recurse

Write-Host "Conversion de $($scriptFiles.Count) fichiers PowerShell en UTF-8 avec BOM..." -ForegroundColor Yellow

foreach ($file in $scriptFiles) {
    ConvertTo-UTF8WithBOM -FilePath $file.FullName
}

Write-Host "`n=== Correction de l'encodage des fichiers PowerShell terminÃ©e ===" -ForegroundColor Cyan

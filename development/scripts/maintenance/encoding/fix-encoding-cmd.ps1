# Script pour corriger l'encodage des fichiers CMD
# Ce script convertit tous les fichiers .cmd en ANSI (Windows-1252) pour assurer la compatibilitÃ© avec cmd.exe

Write-Host "=== Correction de l'encodage des fichiers CMD ===" -ForegroundColor Cyan

# Fonction pour convertir un fichier en ANSI (Windows-1252)
function ConvertTo-ANSI {
    param (
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $ansi = [System.Text.Encoding]::GetEncoding(1252)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $ansiBytes = [System.Text.Encoding]::Convert([System.Text.Encoding]::UTF8, $ansi, $bytes)
        $ansiContent = $ansi.GetString($ansiBytes)
        [System.IO.File]::WriteAllText($FilePath, $ansiContent, $ansi)
        Write-Host "Fichier converti: $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la conversion du fichier $FilePath : $_" -ForegroundColor Red
    }
}

# Rechercher tous les fichiers CMD dans le projet
$cmdFiles = Get-ChildItem -Path . -Filter "*.cmd" -Recurse

Write-Host "Conversion de $($cmdFiles.Count) fichiers CMD en ANSI (Windows-1252)..." -ForegroundColor Yellow

foreach ($file in $cmdFiles) {
    ConvertTo-ANSI -FilePath $file.FullName
}

Write-Host "`n=== Correction de l'encodage des fichiers CMD terminÃ©e ===" -ForegroundColor Cyan

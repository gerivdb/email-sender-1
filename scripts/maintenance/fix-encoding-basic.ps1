# Script pour corriger les problemes d'encodage dans les scripts PowerShell

Write-Host "=== Correction des problemes d'encodage dans les scripts PowerShell ===" -ForegroundColor Cyan

# Rechercher tous les scripts PowerShell
$scriptFiles = Get-ChildItem -Path "." -Recurse -Filter "*.ps1" -File

Write-Host "Traitement de $($scriptFiles.Count) scripts PowerShell..." -ForegroundColor Yellow

$modifiedCount = 0
foreach ($file in $scriptFiles) {
    # Lire le contenu du fichier
    $content = Get-Content -Path $file.FullName -Raw
    
    # Remplacer les caracteres accentues
    $newContent = $content -replace "e", "e" -replace "e", "e" -replace "e", "e" -replace "e", "e"
    $newContent = $newContent -replace "a", "a" -replace "a", "a" -replace "a", "a"
    $newContent = $newContent -replace "i", "i" -replace "i", "i"
    $newContent = $newContent -replace "o", "o" -replace "o", "o"
    $newContent = $newContent -replace "u", "u" -replace "u", "u" -replace "u", "u"
    $newContent = $newContent -replace "c", "c"
    $newContent = $newContent -replace "Ã‰", "E" -replace "Ãˆ", "E" -replace "ÃŠ", "E" -replace "Ã‹", "E"
    $newContent = $newContent -replace "Ã€", "A" -replace "Ã‚", "A" -replace "Ã„", "A"
    $newContent = $newContent -replace "ÃŽ", "I" -replace "Ã", "I"
    $newContent = $newContent -replace "Ã”", "O" -replace "Ã–", "O"
    $newContent = $newContent -replace "Ã™", "U" -replace "Ã›", "U" -replace "Ãœ", "U"
    $newContent = $newContent -replace "Ã‡", "C"
    
    # Verifier si le contenu a ete modifie
    if ($newContent -ne $content) {
        # Enregistrer le nouveau contenu
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Fichier $($file.FullName) corrige" -ForegroundColor Green
        $modifiedCount++
    }
}

Write-Host "`n$modifiedCount fichiers ont ete corriges" -ForegroundColor Green

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan
Write-Host "Les problemes d'encodage ont ete corriges dans les scripts PowerShell."
Write-Host "Desormais, tous les scripts devraient s'afficher correctement dans le terminal."


# Script pour corriger les problemes d'encodage dans les scripts PowerShell
# Ce script remplace les caracteres accentues par leurs equivalents non accentues

Write-Host "=== Correction des problemes d'encodage dans les scripts PowerShell ===" -ForegroundColor Cyan

# Rechercher tous les scripts PowerShell
$scriptFiles = Get-ChildItem -Path "." -Recurse -Filter "*.ps1" -File

Write-Host "Traitement de $($scriptFiles.Count) scripts PowerShell..." -ForegroundColor Yellow

$modifiedCount = 0
foreach ($file in $scriptFiles) {
    # Lire le contenu du fichier
    $content = Get-Content -Path $file.FullName -Raw
    
    # Remplacer les caracteres accentues
    $newContent = $content -replace "e", "e" -replace "e", "e" -replace "e", "e" -replace "e", "e" `
                          -replace "a", "a" -replace "a", "a" -replace "a", "a" `
                          -replace "i", "i" -replace "i", "i" `
                          -replace "o", "o" -replace "o", "o" `
                          -replace "u", "u" -replace "u", "u" -replace "u", "u" `
                          -replace "c", "c" `
                          -replace "Ã‰", "E" -replace "Ãˆ", "E" -replace "ÃŠ", "E" -replace "Ã‹", "E" `
                          -replace "Ã€", "A" -replace "Ã‚", "A" -replace "Ã„", "A" `
                          -replace "ÃŽ", "I" -replace "Ã", "I" `
                          -replace "Ã”", "O" -replace "Ã–", "O" `
                          -replace "Ã™", "U" -replace "Ã›", "U" -replace "Ãœ", "U" `
                          -replace "Ã‡", "C"
    
    # Verifier si le contenu a ete modifie
    if ($newContent -ne $content) {
        # Enregistrer le nouveau contenu
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Fichier $($file.FullName) corrige" -ForegroundColor Green
        $modifiedCount++
    }
}

Write-Host "`n$modifiedCount fichiers ont ete corriges" -ForegroundColor Green

# Rechercher tous les fichiers batch
$batchFiles = Get-ChildItem -Path "." -Recurse -Filter "*.cmd" -File

Write-Host "`nTraitement de $($batchFiles.Count) fichiers batch..." -ForegroundColor Yellow

$modifiedBatchCount = 0
foreach ($file in $batchFiles) {
    # Lire le contenu du fichier
    $content = Get-Content -Path $file.FullName -Raw
    
    # Remplacer les caracteres accentues
    $newContent = $content -replace "e", "e" -replace "e", "e" -replace "e", "e" -replace "e", "e" `
                          -replace "a", "a" -replace "a", "a" -replace "a", "a" `
                          -replace "i", "i" -replace "i", "i" `
                          -replace "o", "o" -replace "o", "o" `
                          -replace "u", "u" -replace "u", "u" -replace "u", "u" `
                          -replace "c", "c" `
                          -replace "Ã‰", "E" -replace "Ãˆ", "E" -replace "ÃŠ", "E" -replace "Ã‹", "E" `
                          -replace "Ã€", "A" -replace "Ã‚", "A" -replace "Ã„", "A" `
                          -replace "ÃŽ", "I" -replace "Ã", "I" `
                          -replace "Ã”", "O" -replace "Ã–", "O" `
                          -replace "Ã™", "U" -replace "Ã›", "U" -replace "Ãœ", "U" `
                          -replace "Ã‡", "C"
    
    # Verifier si le contenu a ete modifie
    if ($newContent -ne $content) {
        # Enregistrer le nouveau contenu
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Fichier $($file.FullName) corrige" -ForegroundColor Green
        $modifiedBatchCount++
    }
}

Write-Host "`n$modifiedBatchCount fichiers batch ont ete corriges" -ForegroundColor Green

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan
Write-Host "Les problemes d'encodage ont ete corriges dans les scripts PowerShell et les fichiers batch."
Write-Host "Desormais, tous les scripts devraient s'afficher correctement dans le terminal."


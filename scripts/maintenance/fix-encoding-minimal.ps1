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
    $newContent = $content -replace "e", "e"
    $newContent = $newContent -replace "e", "e"
    $newContent = $newContent -replace "e", "e"
    $newContent = $newContent -replace "e", "e"
    $newContent = $newContent -replace "a", "a"
    $newContent = $newContent -replace "a", "a"
    $newContent = $newContent -replace "a", "a"
    $newContent = $newContent -replace "i", "i"
    $newContent = $newContent -replace "i", "i"
    $newContent = $newContent -replace "o", "o"
    $newContent = $newContent -replace "o", "o"
    $newContent = $newContent -replace "u", "u"
    $newContent = $newContent -replace "u", "u"
    $newContent = $newContent -replace "u", "u"
    $newContent = $newContent -replace "c", "c"
    
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


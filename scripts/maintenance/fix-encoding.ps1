# Script pour corriger les problemes d'encodage dans les scripts PowerShell
# Ce script remplace les caracteres accentues par leurs equivalents non accentues

Write-Host "=== Correction des problemes d'encodage dans les scripts PowerShell ===" -ForegroundColor Cyan

# Fonction pour remplacer les caracteres accentues
function Replace-AccentedChars {
    param (
        [string]$Content
    )
    
    # Table de correspondance des caracteres accentues
    $accentedChars = @{
        'e' = 'e'; 'e' = 'e'; 'e' = 'e'; 'e' = 'e';
        'a' = 'a'; 'a' = 'a'; 'a' = 'a';
        'i' = 'i'; 'i' = 'i';
        'o' = 'o'; 'o' = 'o';
        'u' = 'u'; 'u' = 'u'; 'u' = 'u';
        'c' = 'c';
        'Ã‰' = 'E'; 'Ãˆ' = 'E'; 'ÃŠ' = 'E'; 'Ã‹' = 'E';
        'Ã€' = 'A'; 'Ã‚' = 'A'; 'Ã„' = 'A';
        'ÃŽ' = 'I'; 'Ã' = 'I';
        'Ã”' = 'O'; 'Ã–' = 'O';
        'Ã™' = 'U'; 'Ã›' = 'U'; 'Ãœ' = 'U';
        'Ã‡' = 'C'
    }
    
    # Remplacer les caracteres accentues
    foreach ($key in $accentedChars.Keys) {
        $content = $content -replace $key, $accentedChars[$key]
    }
    
    return $content
}

# Rechercher tous les scripts PowerShell
$scriptFiles = Get-ChildItem -Path "." -Recurse -Filter "*.ps1" -File

Write-Host "Traitement de $($scriptFiles.Count) scripts PowerShell..." -ForegroundColor Yellow

$modifiedCount = 0
foreach ($file in $scriptFiles) {
    # Lire le contenu du fichier
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    # Remplacer les caracteres accentues
    $newContent = Replace-AccentedChars -Content $content
    
    # Verifier si le contenu a ete modifie
    if ($newContent -ne $content) {
        # Enregistrer le nouveau contenu
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
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
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    # Remplacer les caracteres accentues
    $newContent = Replace-AccentedChars -Content $content
    
    # Verifier si le contenu a ete modifie
    if ($newContent -ne $content) {
        # Enregistrer le nouveau contenu
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Fichier $($file.FullName) corrige" -ForegroundColor Green
        $modifiedBatchCount++
    }
}

Write-Host "`n$modifiedBatchCount fichiers batch ont ete corriges" -ForegroundColor Green

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan
Write-Host "Les problemes d'encodage ont ete corriges dans les scripts PowerShell et les fichiers batch."
Write-Host "Desormais, tous les scripts devraient s'afficher correctement dans le terminal."


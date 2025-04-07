# Script pour corriger l'erreur de token $null inattendu dans RoadmapAdmin.ps1

# Chemin du fichier à corriger
$filePath = "D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1/RoadmapAdmin.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier ligne par ligne
$lines = Get-Content -Path $filePath

# Afficher la ligne problématique (ligne 435)
Write-Host "Ligne problématique (435): $($lines[434])" -ForegroundColor Yellow

# Corriger la ligne problématique
# Le problème est probablement lié à une syntaxe incorrecte dans la comparaison avec $null
if ($lines[434] -match "\$null -eq \$roadmap") {
    $lines[434] = $lines[434].Replace('$null -eq $roadmap', 'if ($null -eq $roadmap)')
    Write-Host "Ligne corrigée: $($lines[434])" -ForegroundColor Green
}
else {
    # Si le pattern exact n'est pas trouvé, essayons de corriger la syntaxe de manière plus générale
    $lines[434] = $lines[434].Replace('$null -eq', 'if ($null -eq')
    Write-Host "Ligne corrigée (méthode alternative): $($lines[434])" -ForegroundColor Green
}

# Enregistrer les modifications
Set-Content -Path $filePath -Value $lines -Encoding UTF8

Write-Host "Correction appliquée au fichier: $filePath" -ForegroundColor Green

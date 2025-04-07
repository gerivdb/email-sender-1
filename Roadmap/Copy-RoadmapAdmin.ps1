# Script pour copier le fichier RoadmapAdmin.ps1 corrigé à l'emplacement original

# Chemin du fichier source (corrigé)
$sourcePath = "D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1/Roadmap/RoadmapAdmin.ps1"

# Chemin du fichier de destination (où l'éditeur s'attend à le trouver)
$destinationPath = "D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1/RoadmapAdmin.ps1"

# Vérifier si le fichier source existe
if (-not (Test-Path -Path $sourcePath)) {
    Write-Host "Le fichier source n'existe pas: $sourcePath" -ForegroundColor Red
    exit 1
}

# Créer le fichier de destination
Copy-Item -Path $sourcePath -Destination $destinationPath -Force
Write-Host "Fichier copié avec succès: $sourcePath -> $destinationPath" -ForegroundColor Green

# Vérifier si le fichier de destination existe
if (Test-Path -Path $destinationPath) {
    Write-Host "Le fichier de destination existe maintenant: $destinationPath" -ForegroundColor Green
}
else {
    Write-Host "Échec de la copie du fichier." -ForegroundColor Red
}

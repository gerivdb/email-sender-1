# Test-FileWrite.ps1
# Script de test pour vérifier l'écriture de fichiers
# Version: 1.0
# Date: 2025-05-15

# Paramètres
$outputPath = "projet/roadmaps/analysis/test_output.json"

# Créer le dossier de sortie s'il n'existe pas
$outputDir = Split-Path -Path $outputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Créer un objet de test
$testObject = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TestValue = "Ceci est un test"
    Numbers = @(1, 2, 3, 4, 5)
}

# Exporter l'objet au format JSON
$testObject | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8

# Vérifier que le fichier a été créé
if (Test-Path -Path $outputPath) {
    Write-Host "Le fichier a été créé avec succès : $outputPath"
    Write-Host "Contenu du fichier :"
    Get-Content -Path $outputPath
}
else {
    Write-Host "Erreur : Le fichier n'a pas été créé."
}

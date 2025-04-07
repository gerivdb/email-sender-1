# Script pour mettre Ã  jour le README principal avec le README mis Ã  jour

# Chemins des fichiers
$sourceFile = "docs/journal_de_bord/README_updated.md"
$targetFile = "docs/journal_de_bord/README.md"

# VÃ©rifier que le fichier source existe
if (-not (Test-Path $sourceFile)) {
    Write-Error "Le fichier source $sourceFile n'existe pas."
    exit 1
}

# VÃ©rifier que le fichier cible existe
if (-not (Test-Path $targetFile)) {
    Write-Error "Le fichier cible $targetFile n'existe pas."
    exit 1
}

# Copier le contenu du fichier source vers le fichier cible
try {
    Copy-Item -Path $sourceFile -Destination $targetFile -Force
    Write-Host "Le fichier README a Ã©tÃ© mis Ã  jour avec succÃ¨s."
} catch {
    Write-Error "Erreur lors de la mise Ã  jour du fichier README: $_"
    exit 1
}

# Supprimer le fichier source
try {
    Remove-Item -Path $sourceFile -Force
    Write-Host "Le fichier source a Ã©tÃ© supprimÃ© avec succÃ¨s."
} catch {
    Write-Error "Erreur lors de la suppression du fichier source: $_"
    exit 1
}

Write-Host "Mise Ã  jour du README terminÃ©e."

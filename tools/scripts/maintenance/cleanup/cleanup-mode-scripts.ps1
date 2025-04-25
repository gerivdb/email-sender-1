<#
.SYNOPSIS
    Supprime les fichiers de mode originaux après leur déplacement.

.DESCRIPTION
    Ce script supprime les fichiers de mode originaux qui ont été copiés vers la nouvelle structure
    de dossiers dans roadmap-parser/modes.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Liste des fichiers à supprimer
$filesToRemove = @(
    "archi-mode.ps1",
    "check-mode.ps1",
    "debug-mode.ps1",
    "dev-r-mode.ps1",
    "gran-mode.ps1",
    "test-mode.ps1",
    "Test-GranModeComplete.ps1"
)

# Fonction pour supprimer un fichier
function Remove-FileIfExists {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        try {
            Remove-Item -Path $FilePath -Force
            Write-Host "Fichier supprimé : $FilePath" -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors de la suppression du fichier $FilePath : $_"
        }
    }
    else {
        Write-Warning "Le fichier n'existe pas : $FilePath"
    }
}

# Demander confirmation avant de supprimer les fichiers
Write-Host "Cette opération va supprimer les fichiers originaux suivants :" -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    Write-Host "  - $file"
}

$confirmation = Read-Host "Êtes-vous sûr de vouloir supprimer ces fichiers ? (O/N)"

if ($confirmation -eq "O" -or $confirmation -eq "o") {
    # Supprimer les fichiers
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
        Remove-FileIfExists -FilePath $filePath
    }
    
    Write-Host "Nettoyage terminé. Les fichiers originaux ont été supprimés." -ForegroundColor Green
}
else {
    Write-Host "Opération annulée. Aucun fichier n'a été supprimé." -ForegroundColor Yellow
}

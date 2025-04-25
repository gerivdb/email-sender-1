<#
.SYNOPSIS
    Déplace les scripts de mode du dossier principal vers la structure roadmap-parser/modes.

.DESCRIPTION
    Ce script déplace les fichiers de mode (check-mode.ps1, gran-mode.ps1, etc.) du dossier principal
    scripts vers la structure organisée dans roadmap-parser/modes.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Définir les mappages de fichiers vers les nouveaux emplacements
$fileMappings = @{
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\archi-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\archi\archi-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\check-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\check\check-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\debug-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\debug\debug-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\dev-r-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\dev-r\dev-r-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\gran-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\gran\gran-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\test-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\test\test-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\Test-GranModeComplete.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\gran\Test-GranModeComplete.ps1"
}

# Fonction pour déplacer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Warning "Le fichier source n'existe pas : $SourcePath"
        return
    }
    
    # Créer le dossier de destination s'il n'existe pas
    $destinationDir = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé : $destinationDir"
    }
    
    # Déplacer le fichier
    try {
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
        Write-Host "Fichier copié : $SourcePath -> $DestinationPath"
    }
    catch {
        Write-Error "Erreur lors de la copie du fichier $SourcePath : $_"
    }
}

# Déplacer les fichiers
foreach ($sourcePath in $fileMappings.Keys) {
    $destinationPath = $fileMappings[$sourcePath]
    Move-FileToNewLocation -SourcePath $sourcePath -DestinationPath $destinationPath
}

Write-Host "Déplacement terminé. Les fichiers de mode ont été copiés vers leurs nouveaux emplacements."
Write-Host "Vous pouvez maintenant vérifier que tout fonctionne correctement avant de supprimer les fichiers originaux."

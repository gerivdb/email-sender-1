<#
.SYNOPSIS
    DÃ©place les scripts de mode du dossier principal vers la structure roadmap-parser/modes.

.DESCRIPTION
    Ce script dÃ©place les fichiers de mode (check-mode.ps1, gran-mode.ps1, etc.) du dossier principal
    scripts vers la structure organisÃ©e dans roadmap-parser/modes.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# DÃ©finir les mappages de fichiers vers les nouveaux emplacements
$fileMappings = @{
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\archi-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\archi\archi-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\check-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\check\check-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\debug-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\debug\debug-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\dev-r-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\dev-r\dev-r-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\gran-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\gran\gran-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\test-mode.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\test\test-mode.ps1"
    "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\Test-GranModeComplete.ps1" = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\modes\gran\Test-GranModeComplete.ps1"
}

# Fonction pour dÃ©placer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    # VÃ©rifier si le fichier source existe
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Warning "Le fichier source n'existe pas : $SourcePath"
        return
    }
    
    # CrÃ©er le dossier de destination s'il n'existe pas
    $destinationDir = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        Write-Host "Dossier crÃ©Ã© : $destinationDir"
    }
    
    # DÃ©placer le fichier
    try {
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
        Write-Host "Fichier copiÃ© : $SourcePath -> $DestinationPath"
    }
    catch {
        Write-Error "Erreur lors de la copie du fichier $SourcePath : $_"
    }
}

# DÃ©placer les fichiers
foreach ($sourcePath in $fileMappings.Keys) {
    $destinationPath = $fileMappings[$sourcePath]
    Move-FileToNewLocation -SourcePath $sourcePath -DestinationPath $destinationPath
}

Write-Host "DÃ©placement terminÃ©. Les fichiers de mode ont Ã©tÃ© copiÃ©s vers leurs nouveaux emplacements."
Write-Host "Vous pouvez maintenant vÃ©rifier que tout fonctionne correctement avant de supprimer les fichiers originaux."

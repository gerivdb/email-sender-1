# Script pour supprimer les backups inutiles des fichiers roadmap
# Ce script identifie et supprime tous les fichiers de backup de roadmap

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

try {
    # Définir les patterns de recherche pour les backups
    $backupPatterns = @(
        "*roadmap_perso*.backup_*",
        "*roadmap_perso*.bak",
        "*roadmap_perso_new*.backup_*",
        "*roadmap_perso_new*.bak"
    )

    # Rechercher tous les fichiers de backup dans le projet
    $backupFiles = @()
    foreach ($pattern in $backupPatterns) {
        $backupFiles += Get-ChildItem -Path (Get-Location) -Recurse -File -Filter $pattern
    }

    # Éliminer les doublons
    $backupFiles = $backupFiles | Select-Object -Unique FullName | ForEach-Object { Get-Item -Path $_.FullName }

    Write-Host "Nombre de fichiers de backup trouvés: $($backupFiles.Count)" -ForegroundColor Yellow

    # Afficher les fichiers trouvés
    if ($backupFiles.Count -gt 0) {
        Write-Host "`nFichiers de backup trouvés:" -ForegroundColor Cyan
        foreach ($file in $backupFiles) {
            Write-Host "  - $($file.FullName)" -ForegroundColor Gray
        }

        # Supprimer les fichiers
        foreach ($file in $backupFiles) {
            Remove-Item -Path $file.FullName -Force
            Write-Host "Fichier supprimé: $($file.FullName)" -ForegroundColor Green
        }

        # Mettre à jour le journal de développement
        $journalPath = Join-Path -Path (Get-Location) -ChildPath "journal\development_log.md"
        if (Test-Path -Path $journalPath -PathType Leaf) {
            $journalEntry = @"

## $(Get-Date -Format "yyyy-MM-dd") - Nettoyage des backups de roadmap

### Actions réalisées
- Suppression de $($backupFiles.Count) fichiers de backup inutiles
- Nettoyage de l'espace disque et simplification de la structure du projet

### Problèmes résolus
- Accumulation de fichiers de backup inutiles
- Confusion due à la présence de nombreux fichiers similaires
"@

            Add-Content -Path $journalPath -Value $journalEntry -Encoding UTF8
            Write-Host "Journal de développement mis à jour: $journalPath" -ForegroundColor Green
        }

        # Afficher un résumé
        Write-Host "`nRésumé du nettoyage :" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        Write-Host "Fichiers de backup supprimés : $($backupFiles.Count)" -ForegroundColor Green
    }
    else {
        Write-Host "Aucun fichier de backup trouvé." -ForegroundColor Green
    }
}
catch {
    Write-Host "ERREUR: Une erreur critique s'est produite: $_" -ForegroundColor Red
    exit 1
}

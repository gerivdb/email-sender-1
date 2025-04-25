# Script pour mettre à jour les références aux fichiers roadmap supprimés
# Ce script recherche et remplace toutes les références aux anciens chemins

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

try {
    # Définir le nouveau chemin de la roadmap
    $newRoadmapPath = "Roadmap\"Roadmap\roadmap_perso.md""

    # Définir les anciens chemins à rechercher
    $oldPaths = @(
        ""Roadmap\roadmap_perso.md"",
        "md\"Roadmap\roadmap_perso.md"",
        "md/"Roadmap\roadmap_perso.md"",
        ""Roadmap\roadmap_perso.md"",
        ""Roadmap\roadmap_perso.md""
    )

    # Rechercher tous les fichiers dans le répertoire scripts
    $scriptFiles = Get-ChildItem -Path "scripts" -Recurse -File -Include "*.ps1", "*.bat", "*.cmd", "*.py", "*.js", "*.json"
    Write-Host "Nombre de fichiers trouvés: $($scriptFiles.Count)" -ForegroundColor Yellow

    # Compteurs pour le suivi
    $modifiedFiles = 0
    $totalReplacements = 0

    # Parcourir tous les fichiers
    foreach ($file in $scriptFiles) {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { continue }

        $originalContent = $content
        $replacementsInFile = 0

        # Rechercher et remplacer les anciens chemins
        foreach ($oldPath in $oldPaths) {
            # Échapper les caractères spéciaux pour la regex
            $escapedOldPath = [regex]::Escape($oldPath)

            # Différentes façons dont le chemin pourrait être référencé
            $patterns = @(
                $escapedOldPath,
                "`"$escapedOldPath`"",
                "'$escapedOldPath'",
                "Join-Path.*$escapedOldPath"
            )

            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    # Remplacer le chemin
                    if ($pattern -match "Join-Path") {
                        # Pour les Join-Path, remplacer toute l'expression
                        $oldContent = $content
                        $content = $content -replace "Join-Path.*$escapedOldPath", "`"$newRoadmapPath`""
                        if ($content -ne $oldContent) {
                            $replacementsInFile++
                            $totalReplacements++
                        }
                    } else {
                        # Pour les autres, remplacer juste le chemin
                        $oldContent = $content
                        $content = $content -replace $pattern, "`"$newRoadmapPath`""
                        if ($content -ne $oldContent) {
                            $replacementsInFile++
                            $totalReplacements++
                        }
                    }


                }
            }
        }

        # Si des remplacements ont été effectués, écrire le nouveau contenu
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "Fichier mis à jour: $($file.FullName) ($replacementsInFile remplacements)" -ForegroundColor Green
            $modifiedFiles++
        }
    }

    # Afficher un résumé
    Write-Host "`nRésumé de la mise à jour des références :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichiers analysés : $($scriptFiles.Count)" -ForegroundColor White
    Write-Host "Fichiers modifiés : $modifiedFiles" -ForegroundColor Green
    Write-Host "Remplacements effectués : $totalReplacements" -ForegroundColor Green

    # Mettre à jour le journal de développement
    $journalPath = Join-Path -Path (Get-Location) -ChildPath "journal\development_log.md"
    if (Test-Path -Path $journalPath -PathType Leaf) {
        $journalEntry = @"

## $(Get-Date -Format "yyyy-MM-dd") - Mise à jour des références à la roadmap

### Actions réalisées
- Recherche et remplacement de toutes les références aux anciens chemins de la roadmap
- Mise à jour de $modifiedFiles fichiers avec $totalReplacements remplacements
- Standardisation de toutes les références vers le chemin unique: $newRoadmapPath

### Problèmes résolus
- Références obsolètes vers des fichiers roadmap supprimés
- Incohérences dans les chemins utilisés pour accéder à la roadmap
"@

        Add-Content -Path $journalPath -Value $journalEntry -Encoding UTF8
        Write-Host "Journal de développement mis à jour: $journalPath" -ForegroundColor Green
    }
}
catch {
    Write-Host "ERREUR: Une erreur critique s'est produite: $_" -ForegroundColor Red
    exit 1
}

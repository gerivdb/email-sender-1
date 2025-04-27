# Script pour mettre Ã  jour les rÃ©fÃ©rences aux fichiers roadmap supprimÃ©s
# Ce script recherche et remplace toutes les rÃ©fÃ©rences aux anciens chemins

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

try {
    # DÃ©finir le nouveau chemin de la roadmap
    $newRoadmapPath = "Roadmap\"Roadmap\roadmap_perso.md""

    # DÃ©finir les anciens chemins Ã  rechercher
    $oldPaths = @(
        ""Roadmap\roadmap_perso.md"",
        "md\"Roadmap\roadmap_perso.md"",
        "md/"Roadmap\roadmap_perso.md"",
        ""Roadmap\roadmap_perso.md"",
        ""Roadmap\roadmap_perso.md""
    )

    # Rechercher tous les fichiers dans le rÃ©pertoire scripts
    $scriptFiles = Get-ChildItem -Path "scripts" -Recurse -File -Include "*.ps1", "*.bat", "*.cmd", "*.py", "*.js", "*.json"
    Write-Host "Nombre de fichiers trouvÃ©s: $($scriptFiles.Count)" -ForegroundColor Yellow

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
            # Ã‰chapper les caractÃ¨res spÃ©ciaux pour la regex
            $escapedOldPath = [regex]::Escape($oldPath)

            # DiffÃ©rentes faÃ§ons dont le chemin pourrait Ãªtre rÃ©fÃ©rencÃ©
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

        # Si des remplacements ont Ã©tÃ© effectuÃ©s, Ã©crire le nouveau contenu
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "Fichier mis Ã  jour: $($file.FullName) ($replacementsInFile remplacements)" -ForegroundColor Green
            $modifiedFiles++
        }
    }

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la mise Ã  jour des rÃ©fÃ©rences :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichiers analysÃ©s : $($scriptFiles.Count)" -ForegroundColor White
    Write-Host "Fichiers modifiÃ©s : $modifiedFiles" -ForegroundColor Green
    Write-Host "Remplacements effectuÃ©s : $totalReplacements" -ForegroundColor Green

    # Mettre Ã  jour le journal de dÃ©veloppement
    $journalPath = Join-Path -Path (Get-Location) -ChildPath "journal\development_log.md"
    if (Test-Path -Path $journalPath -PathType Leaf) {
        $journalEntry = @"

## $(Get-Date -Format "yyyy-MM-dd") - Mise Ã  jour des rÃ©fÃ©rences Ã  la roadmap

### Actions rÃ©alisÃ©es
- Recherche et remplacement de toutes les rÃ©fÃ©rences aux anciens chemins de la roadmap
- Mise Ã  jour de $modifiedFiles fichiers avec $totalReplacements remplacements
- Standardisation de toutes les rÃ©fÃ©rences vers le chemin unique: $newRoadmapPath

### ProblÃ¨mes rÃ©solus
- RÃ©fÃ©rences obsolÃ¨tes vers des fichiers roadmap supprimÃ©s
- IncohÃ©rences dans les chemins utilisÃ©s pour accÃ©der Ã  la roadmap
"@

        Add-Content -Path $journalPath -Value $journalEntry -Encoding UTF8
        Write-Host "Journal de dÃ©veloppement mis Ã  jour: $journalPath" -ForegroundColor Green
    }
}
catch {
    Write-Host "ERREUR: Une erreur critique s'est produite: $_" -ForegroundColor Red
    exit 1
}

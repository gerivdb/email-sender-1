<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences aprÃ¨s la rÃ©organisation de la structure du projet.

.DESCRIPTION
    Ce script met Ã  jour les rÃ©fÃ©rences dans les fichiers du projet aprÃ¨s la rÃ©organisation
    de la structure du projet, notamment le dÃ©placement des fichiers vers les dossiers
    'projet' et 'development'.

.EXAMPLE
    .\update-project-structure-references.ps1

.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Update-ProjectStructureReferences {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Host "Mise Ã  jour des rÃ©fÃ©rences aprÃ¨s la rÃ©organisation de la structure du projet..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # DÃ©finir les mappages de chemins
        $pathMappings = @(
            # DÃ©placement des fichiers de configuration vers le dossier projet
            @{
                OldPath     = "config"
                NewPath     = "projet/config"
                Description = "DÃ©placement du dossier config vers projet/config"
            },
            # DÃ©placement des templates vers le dossier development
            @{
                OldPath     = "templates"
                NewPath     = "development/templates"
                Description = "DÃ©placement du dossier templates vers development/templates"
            },
            @{
                OldPath     = "_templates"
                NewPath     = "development/templates"
                Description = "DÃ©placement du dossier _templates vers development/templates"
            },
            # DÃ©placement des roadmaps vers le dossier projet
            @{
                OldPath     = "Roadmap"
                NewPath     = "projet/roadmaps"
                Description = "DÃ©placement du dossier Roadmap vers projet/roadmaps"
            },
            @{
                OldPath     = "roadmap"
                NewPath     = "projet/roadmaps"
                Description = "DÃ©placement du dossier roadmap vers projet/roadmaps"
            },
            # DÃ©placement de la documentation vers le dossier development
            @{
                OldPath     = "docs"
                NewPath     = "development/docs"
                Description = "DÃ©placement du dossier docs vers development/docs"
            },
            # DÃ©placement des scripts vers le dossier development
            @{
                OldPath     = "scripts"
                NewPath     = "development/scripts"
                Description = "DÃ©placement du dossier scripts vers development/scripts"
            },
            # DÃ©placement des outils vers le dossier development
            @{
                OldPath     = "tools"
                NewPath     = "development/tools"
                Description = "DÃ©placement du dossier tools vers development/tools"
            },
            # DÃ©placement des tests vers le dossier development
            @{
                OldPath     = "tests"
                NewPath     = "development/tests"
                Description = "DÃ©placement du dossier tests vers development/tests"
            },
            @{
                OldPath     = "test-reports"
                NewPath     = "development/test-reports"
                Description = "DÃ©placement du dossier test-reports vers development/test-reports"
            }
        )
    }

    process {
        try {
            # Obtenir tous les fichiers texte du projet
            $textFiles = @()

            # Dossiers Ã  exclure
            $excludedDirs = @("node_modules", ".git", "dist", "cache", "logs", "temp", "tmp")

            # Extensions Ã  inclure
            $includedExtensions = @(".md", ".ps1", ".psm1", ".psd1", ".json", ".yaml", ".yml", ".html", ".css", ".js", ".ts", ".py", ".txt")

            # Fonction pour vÃ©rifier si un chemin contient un dossier exclu
            function Test-ExcludedPath {
                param (
                    [string]$Path
                )

                foreach ($dir in $excludedDirs) {
                    if ($Path -match "\\$dir\\") {
                        return $true
                    }
                }

                return $false
            }

            # Obtenir les fichiers de maniÃ¨re sÃ©curisÃ©e
            Get-ChildItem -Path "." -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    if (-not (Test-ExcludedPath -Path $_.FullName)) {
                        if ($includedExtensions -contains $_.Extension.ToLower()) {
                            $textFiles += $_
                        }
                    }
                } catch {
                    Write-Warning "Erreur lors du traitement du fichier $($_.FullName): $_"
                }
            }

            $totalFiles = $textFiles.Count
            $processedFiles = 0
            $updatedFiles = 0

            foreach ($file in $textFiles) {
                $processedFiles++

                # Lire le contenu du fichier
                $content = Get-Content -Path $file.FullName -Raw
                $originalContent = $content

                # Appliquer les mappages de chemins
                foreach ($mapping in $pathMappings) {
                    $oldPath = $mapping.OldPath.Replace("/", "\\")
                    $newPath = $mapping.NewPath.Replace("/", "\\")

                    # Remplacer les chemins avec des barres obliques inversÃ©es
                    $content = $content -replace [regex]::Escape($oldPath), $newPath

                    # Remplacer les chemins avec des barres obliques
                    $oldPathForward = $mapping.OldPath
                    $newPathForward = $mapping.NewPath
                    $content = $content -replace [regex]::Escape($oldPathForward), $newPathForward
                }

                # VÃ©rifier si le contenu a Ã©tÃ© modifiÃ©
                if ($content -ne $originalContent) {
                    $updatedFiles++

                    # Ã‰crire le contenu mis Ã  jour dans le fichier
                    if ($PSCmdlet.ShouldProcess($file.FullName, "Mettre Ã  jour les rÃ©fÃ©rences")) {
                        Set-Content -Path $file.FullName -Value $content -Force
                        Write-Host "  Mise Ã  jour des rÃ©fÃ©rences dans $($file.FullName)" -ForegroundColor Green
                    }
                }

                # Afficher la progression
                $progress = [math]::Round(($processedFiles / $totalFiles) * 100)
                Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences" -Status "$processedFiles / $totalFiles fichiers traitÃ©s ($progress%)" -PercentComplete $progress
            }

            Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences" -Completed

            Write-Host "
Mise Ã  jour terminÃ©e !" -ForegroundColor Cyan
            Write-Host "  $updatedFiles fichiers mis Ã  jour sur $totalFiles fichiers traitÃ©s." -ForegroundColor Cyan
        } catch {
            Write-Error "Une erreur s'est produite lors de la mise Ã  jour des rÃ©fÃ©rences : $_"
        }
    }

    end {
        Write-Host "
RÃ©capitulatif des modifications :" -ForegroundColor Yellow
        foreach ($mapping in $pathMappings) {
            Write-Host "  - $($mapping.Description) : $($mapping.OldPath) -> $($mapping.NewPath)" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-ProjectStructureReferences

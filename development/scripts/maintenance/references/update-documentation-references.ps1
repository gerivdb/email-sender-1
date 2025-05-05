<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences dans les fichiers de documentation.

.DESCRIPTION
    Ce script met Ã  jour les rÃ©fÃ©rences dans les fichiers de documentation aprÃ¨s la rÃ©organisation
    de la structure du projet, notamment les chemins vers les fichiers et dossiers.

.EXAMPLE
    .\update-documentation-references.ps1

.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Update-DocumentationReferences {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Host "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers de documentation..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # DÃ©finir les dossiers de documentation
        $documentationFolders = @(
            "development/docs",
            "projet/roadmaps"
        )

        # Extensions des fichiers de documentation
        $documentationExtensions = @(".md", ".txt", ".html", ".htm", ".rst", ".adoc", ".asciidoc")
    }

    process {
        try {
            $documentationFiles = @()

            # Obtenir tous les fichiers de documentation
            foreach ($folder in $documentationFolders) {
                if (Test-Path -Path $folder) {
                    Get-ChildItem -Path $folder -Recurse -File | ForEach-Object {
                        if ($documentationExtensions -contains $_.Extension.ToLower()) {
                            $documentationFiles += $_
                        }
                    }
                } else {
                    Write-Warning "Le dossier de documentation $folder n'existe pas."
                }
            }

            $totalFiles = $documentationFiles.Count
            $processedFiles = 0
            $updatedFiles = 0

            if ($totalFiles -eq 0) {
                Write-Warning "Aucun fichier de documentation trouvÃ©."
                return
            }

            Write-Host "  $totalFiles fichiers de documentation trouvÃ©s." -ForegroundColor Cyan

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
                },
                # Mise Ã  jour des rÃ©fÃ©rences pour les dossiers tools
                @{
                    OldPath     = "development/tools/optimization"
                    NewPath     = "development/tools/optimization-tools"
                    Description = "Renommage du dossier optimization en optimization-tools"
                },
                @{
                    OldPath     = "development/tools/swe-bench"
                    NewPath     = "development/tools/swe-bench-tools"
                    Description = "Renommage du dossier swe-bench en swe-bench-tools"
                },
                @{
                    OldPath     = "development/tools/documentation"
                    NewPath     = "development/tools/documentation-tools"
                    Description = "Renommage du dossier documentation en documentation-tools"
                },
                @{
                    OldPath     = "development/tools/dashboards"
                    NewPath     = "development/tools/dashboards-tools"
                    Description = "Renommage du dossier dashboards en dashboards-tools"
                },
                @{
                    OldPath     = "development/tools/reports"
                    NewPath     = "development/tools/reports-tools"
                    Description = "Renommage du dossier reports en reports-tools"
                },
                @{
                    OldPath     = "development/tools/path-utils"
                    NewPath     = "development/tools/path-utils-tools"
                    Description = "Renommage du dossier path-utils en path-utils-tools"
                },
                @{
                    OldPath     = "development/tools/analysis"
                    NewPath     = "development/tools/analysis-tools"
                    Description = "Renommage du dossier analysis en analysis-tools"
                },
                @{
                    OldPath     = "development/tools/converters"
                    NewPath     = "development/tools/converters-tools"
                    Description = "Renommage du dossier converters en converters-tools"
                },
                @{
                    OldPath     = "development/tools/error-handling"
                    NewPath     = "development/tools/error-handling-tools"
                    Description = "Renommage du dossier error-handling en error-handling-tools"
                },
                @{
                    OldPath     = "development/tools/detectors"
                    NewPath     = "development/tools/detectors-tools"
                    Description = "Renommage du dossier detectors en detectors-tools"
                },
                @{
                    OldPath     = "development/tools/markdown"
                    NewPath     = "development/tools/markdown-tools"
                    Description = "Renommage du dossier markdown en markdown-tools"
                },
                @{
                    OldPath     = "development/tools/examples"
                    NewPath     = "development/tools/examples-tools"
                    Description = "Renommage du dossier examples en examples-tools"
                },
                @{
                    OldPath     = "development/tools/git"
                    NewPath     = "development/tools/git-tools"
                    Description = "Renommage du dossier git en git-tools"
                },
                @{
                    OldPath     = "development/tools/journal"
                    NewPath     = "development/tools/journal-tools"
                    Description = "Renommage du dossier journal en journal-tools"
                },
                @{
                    OldPath     = "development/tools/roadmap"
                    NewPath     = "development/tools/roadmap-tools"
                    Description = "Renommage du dossier roadmap en roadmap-tools"
                },
                @{
                    OldPath     = "development/tools/generators"
                    NewPath     = "development/tools/generators-tools"
                    Description = "Renommage du dossier generators en generators-tools"
                },
                @{
                    OldPath     = "development/tools/integrations"
                    NewPath     = "development/tools/integrations-tools"
                    Description = "Renommage du dossier integrations en integrations-tools"
                },
                @{
                    OldPath     = "development/tools/insights"
                    NewPath     = "development/tools/insights-tools"
                    Description = "Renommage du dossier insights en insights-tools"
                },
                @{
                    OldPath     = "development/tools/testing"
                    NewPath     = "development/tools/testing-tools"
                    Description = "Renommage du dossier testing en testing-tools"
                },
                @{
                    OldPath     = "development/tools/cmd"
                    NewPath     = "development/tools/cmd-tools"
                    Description = "Renommage du dossier cmd en cmd-tools"
                },
                @{
                    OldPath     = "development/tools/augment"
                    NewPath     = "development/tools/augment-tools"
                    Description = "Renommage du dossier augment en augment-tools"
                },
                @{
                    OldPath     = "development/tools/json"
                    NewPath     = "development/tools/json-tools"
                    Description = "Renommage du dossier json en json-tools"
                },
                @{
                    OldPath     = "development/tools/utilities"
                    NewPath     = "development/tools/utilities-tools"
                    Description = "Renommage du dossier utilities en utilities-tools"
                },
                @{
                    OldPath     = "development/tools/cache"
                    NewPath     = "development/tools/cache-tools"
                    Description = "Renommage du dossier cache en cache-tools"
                }
            )

            # Ajouter des mappages spÃ©cifiques pour les liens Markdown
            $markdownMappings = @()
            foreach ($mapping in $pathMappings) {
                $markdownMappings += @{
                    OldPath     = "($mapping.OldPath"
                    NewPath     = "($mapping.NewPath"
                    Description = "Mise Ã  jour des liens Markdown pour $($mapping.Description)"
                }
                $markdownMappings += @{
                    OldPath     = "[$mapping.OldPath"
                    NewPath     = "[$mapping.NewPath"
                    Description = "Mise Ã  jour des liens Markdown pour $($mapping.Description)"
                }
                $markdownMappings += @{
                    OldPath     = "]($mapping.OldPath"
                    NewPath     = "]($mapping.NewPath"
                    Description = "Mise Ã  jour des liens Markdown pour $($mapping.Description)"
                }
            }

            # Fusionner les mappages
            $allMappings = $pathMappings + $markdownMappings

            foreach ($file in $documentationFiles) {
                $processedFiles++

                # Lire le contenu du fichier
                $content = Get-Content -Path $file.FullName -Raw
                $originalContent = $content

                # Appliquer les mappages de chemins
                foreach ($mapping in $allMappings) {
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
                Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers de documentation" -Status "$processedFiles / $totalFiles fichiers traitÃ©s ($progress%)" -PercentComplete $progress
            }

            Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers de documentation" -Completed

            Write-Host "
Mise Ã  jour terminÃ©e !" -ForegroundColor Cyan
            Write-Host "  $updatedFiles fichiers mis Ã  jour sur $totalFiles fichiers traitÃ©s." -ForegroundColor Cyan
        } catch {
            Write-Error "Une erreur s'est produite lors de la mise Ã  jour des rÃ©fÃ©rences dans les fichiers de documentation : $_"
        }
    }

    end {
        Write-Host "
RÃ©capitulatif des dossiers de documentation traitÃ©s :" -ForegroundColor Yellow
        foreach ($folder in $documentationFolders) {
            Write-Host "  - $folder" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-DocumentationReferences


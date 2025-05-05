﻿<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences aprÃ¨s le renommage des sous-dossiers du dossier development/tools.

.DESCRIPTION
    Ce script met Ã  jour les rÃ©fÃ©rences dans les fichiers du projet aprÃ¨s le renommage
    des sous-dossiers du dossier development/tools en ajoutant le suffixe -tools Ã  chaque nom.

.EXAMPLE
    .\update-tools-references.ps1

.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Update-ToolsReferences {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Host "Mise Ã  jour des rÃ©fÃ©rences aprÃ¨s le renommage des sous-dossiers du dossier development/tools..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # DÃ©finir les mappages de chemins
        $pathMappings = @(            @{
                OldPath     = "development/tools/optimization-tools"
                NewPath     = "development/tools/optimization-tools-tools"
                Description = "Renommage du dossier optimization en optimization-tools"
            }, @{
                OldPath     = "development/tools/swe-bench-tools"
                NewPath     = "development/tools/swe-bench-tools-tools"
                Description = "Renommage du dossier swe-bench en swe-bench-tools"
            }, @{
                OldPath     = "development/tools/documentation-tools"
                NewPath     = "development/tools/documentation-tools-tools"
                Description = "Renommage du dossier documentation en documentation-tools"
            }, @{
                OldPath     = "development/tools/dashboards-tools"
                NewPath     = "development/tools/dashboards-tools-tools"
                Description = "Renommage du dossier dashboards en dashboards-tools"
            }, @{
                OldPath     = "development/tools/reports-tools"
                NewPath     = "development/tools/reports-tools-tools"
                Description = "Renommage du dossier reports en reports-tools"
            }, @{
                OldPath     = "development/tools/path-utils-tools"
                NewPath     = "development/tools/path-utils-tools-tools"
                Description = "Renommage du dossier path-utils en path-utils-tools"
            }, @{
                OldPath     = "development/tools/analysis-tools"
                NewPath     = "development/tools/analysis-tools-tools"
                Description = "Renommage du dossier analysis en analysis-tools"
            }, @{
                OldPath     = "development/tools/converters-tools"
                NewPath     = "development/tools/converters-tools-tools"
                Description = "Renommage du dossier converters en converters-tools"
            }, @{
                OldPath     = "development/tools/error-handling-tools"
                NewPath     = "development/tools/error-handling-tools-tools"
                Description = "Renommage du dossier error-handling en error-handling-tools"
            }, @{
                OldPath     = "development/tools/detectors-tools"
                NewPath     = "development/tools/detectors-tools-tools"
                Description = "Renommage du dossier detectors en detectors-tools"
            }, @{
                OldPath     = "development/tools/markdown-tools"
                NewPath     = "development/tools/markdown-tools-tools"
                Description = "Renommage du dossier markdown en markdown-tools"
            }, @{
                OldPath     = "development/tools/examples-tools"
                NewPath     = "development/tools/examples-tools-tools"
                Description = "Renommage du dossier examples en examples-tools"
            }, @{
                OldPath     = "development/tools/git-tools"
                NewPath     = "development/tools/git-tools-tools"
                Description = "Renommage du dossier git en git-tools"
            }, @{
                OldPath     = "development/tools/journal-tools"
                NewPath     = "development/tools/journal-tools-tools"
                Description = "Renommage du dossier journal en journal-tools"
            }, @{
                OldPath     = "development/tools/roadmap-tools"
                NewPath     = "development/tools/roadmap-tools-tools"
                Description = "Renommage du dossier roadmap en roadmap-tools"
            }, @{
                OldPath     = "development/tools/generators-tools"
                NewPath     = "development/tools/generators-tools-tools"
                Description = "Renommage du dossier generators en generators-tools"
            }, @{
                OldPath     = "development/tools/integrations-tools"
                NewPath     = "development/tools/integrations-tools-tools"
                Description = "Renommage du dossier integrations en integrations-tools"
            }, @{
                OldPath     = "development/tools/insights-tools"
                NewPath     = "development/tools/insights-tools-tools"
                Description = "Renommage du dossier insights en insights-tools"
            }, @{
                OldPath     = "development/tools/testing-tools"
                NewPath     = "development/tools/testing-tools-tools"
                Description = "Renommage du dossier testing en testing-tools"
            }, @{
                OldPath     = "development/tools/cmd-tools"
                NewPath     = "development/tools/cmd-tools-tools"
                Description = "Renommage du dossier cmd en cmd-tools"
            }, @{
                OldPath     = "development/tools/augment-tools"
                NewPath     = "development/tools/augment-tools-tools"
                Description = "Renommage du dossier augment en augment-tools"
            }, @{
                OldPath     = "development/tools/json-tools"
                NewPath     = "development/tools/json-tools-tools"
                Description = "Renommage du dossier json en json-tools"
            }, @{
                OldPath     = "development/tools/utilities-tools"
                NewPath     = "development/tools/utilities-tools-tools"
                Description = "Renommage du dossier utilities en utilities-tools"
            }, @{
                OldPath     = "development/tools/cache-tools"
                NewPath     = "development/tools/cache-tools-tools"
                Description = "Renommage du dossier cache en cache-tools"
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
Update-ToolsReferences



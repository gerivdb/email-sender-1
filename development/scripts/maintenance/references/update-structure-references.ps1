<#
.SYNOPSIS
    Met à jour les références après la réorganisation de la structure du projet.

.DESCRIPTION
    Ce script met à jour les références dans les fichiers du projet après la réorganisation
    de la structure des dossiers.

.EXAMPLE
    .\update-structure-references.ps1

.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Update-StructureReferences {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Host "Mise à jour des références après la réorganisation de la structure du projet..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # Définir les mappages de chemins
        $pathMappings = @(
            @{
                OldPath     = "development/testing/tests"
                NewPath     = "development/testing/tests"
                Description = "Fusion des dossiers tests et testing"
            },
            @{
                OldPath     = "development/templates/hygen"
                NewPath     = "development/templates/hygen"
                Description = "Fusion des dossiers de templates"
            },
            @{
                OldPath     = "development/templates"
                NewPath     = "development/templates"
                Description = "Fusion des dossiers de templates"
            },
            @{
                OldPath     = "development/tools/analysis"
                NewPath     = "development/tools/analysis"
                Description = "Fusion des dossiers d'analyse"
            }
        )
    }

    process {
        try {
            # Obtenir tous les fichiers texte du projet, en excluant certains dossiers
            $textFiles = @()

            # Dossiers à exclure
            $excludedDirs = @("node_modules", ".git", "dist", "cache", "logs", "temp", "tmp")

            # Extensions à inclure
            $includedExtensions = @(".md", ".ps1", ".psm1", ".psd1", ".json", ".yaml", ".yml", ".html", ".css", ".js", ".ts", ".py", ".txt")

            # Fonction pour vérifier si un chemin contient un dossier exclu
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

            # Obtenir les fichiers de manière sécurisée
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

                    # Remplacer les chemins avec des barres obliques inversées
                    $content = $content -replace [regex]::Escape($oldPath), $newPath

                    # Remplacer les chemins avec des barres obliques
                    $oldPathForward = $mapping.OldPath
                    $newPathForward = $mapping.NewPath
                    $content = $content -replace [regex]::Escape($oldPathForward), $newPathForward
                }

                # Vérifier si le contenu a été modifié
                if ($content -ne $originalContent) {
                    $updatedFiles++

                    # Écrire le contenu mis à jour dans le fichier
                    if ($PSCmdlet.ShouldProcess($file.FullName, "Mettre à jour les références")) {
                        Set-Content -Path $file.FullName -Value $content -Force
                        Write-Host "  Mise à jour des références dans $($file.FullName)" -ForegroundColor Green
                    }
                }

                # Afficher la progression
                $progress = [math]::Round(($processedFiles / $totalFiles) * 100)
                Write-Progress -Activity "Mise à jour des références" -Status "$processedFiles / $totalFiles fichiers traités ($progress%)" -PercentComplete $progress
            }

            Write-Progress -Activity "Mise à jour des références" -Completed

            Write-Host "`nMise à jour terminée !" -ForegroundColor Cyan
            Write-Host "  $updatedFiles fichiers mis à jour sur $totalFiles fichiers traités." -ForegroundColor Cyan
        } catch {
            Write-Error "Une erreur s'est produite lors de la mise à jour des références : $_"
        }
    }

    end {
        Write-Host "`nRécapitulatif des modifications :" -ForegroundColor Yellow
        foreach ($mapping in $pathMappings) {
            Write-Host "  - $($mapping.Description) : $($mapping.OldPath) -> $($mapping.NewPath)" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-StructureReferences


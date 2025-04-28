<#
.SYNOPSIS
    Exécute tous les scripts de mise à jour des références.

.DESCRIPTION
    Ce script exécute tous les scripts de mise à jour des références pour maintenir
    la cohérence après la réorganisation de la structure du projet.

.EXAMPLE
    .\update-all-references.ps1

.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Update-AllReferences {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Host "Exécution de tous les scripts de mise à jour des références..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # Définir les scripts à exécuter
        $scripts = @(
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-tools-references.ps1"
                Description = "Mise à jour des références pour les dossiers tools"
            },
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-project-structure-references.ps1"
                Description = "Mise à jour des références pour la structure du projet"
            },
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-config-references.ps1"
                Description = "Mise à jour des références dans les fichiers de configuration"
            },
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-source-references.ps1"
                Description = "Mise à jour des références dans les fichiers de code source"
            }
        )
    }

    process {
        try {
            $totalScripts = $scripts.Count
            $processedScripts = 0
            $successfulScripts = 0

            foreach ($script in $scripts) {
                $processedScripts++

                Write-Host "
Exécution du script $processedScripts/$totalScripts : $($script.Description)" -ForegroundColor Yellow

                # Vérifier si le script existe
                if (-not (Test-Path -Path $script.Path)) {
                    Write-Warning "Le script $($script.Path) n'existe pas. Passage au script suivant."
                    continue
                }

                # Exécuter le script
                if ($PSCmdlet.ShouldProcess($script.Path, "Exécuter")) {
                    try {
                        & $script.Path
                        $successfulScripts++
                        Write-Host "  Script exécuté avec succès." -ForegroundColor Green
                    } catch {
                        Write-Error "Erreur lors de l'exécution du script $($script.Path) : $_"
                    }
                }

                # Afficher la progression
                $progress = [math]::Round(($processedScripts / $totalScripts) * 100)
                Write-Progress -Activity "Exécution des scripts de mise à jour des références" -Status "$processedScripts / $totalScripts scripts traités ($progress%)" -PercentComplete $progress
            }

            Write-Progress -Activity "Exécution des scripts de mise à jour des références" -Completed

            Write-Host "
Exécution terminée !" -ForegroundColor Cyan
            Write-Host "  $successfulScripts scripts exécutés avec succès sur $totalScripts scripts." -ForegroundColor Cyan
        } catch {
            Write-Error "Une erreur s'est produite lors de l'exécution des scripts de mise à jour des références : $_"
        }
    }

    end {
        Write-Host "
Récapitulatif des scripts exécutés :" -ForegroundColor Yellow
        foreach ($script in $scripts) {
            Write-Host "  - $($script.Description) : $($script.Path)" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-AllReferences

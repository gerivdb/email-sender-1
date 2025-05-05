<#
.SYNOPSIS
    ExÃ©cute tous les scripts de mise Ã  jour des rÃ©fÃ©rences.

.DESCRIPTION
    Ce script exÃ©cute tous les scripts de mise Ã  jour des rÃ©fÃ©rences pour maintenir
    la cohÃ©rence aprÃ¨s la rÃ©organisation de la structure du projet.

.EXAMPLE
    .\update-all-references.ps1

.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Update-AllReferences {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Host "ExÃ©cution de tous les scripts de mise Ã  jour des rÃ©fÃ©rences..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # DÃ©finir les scripts Ã  exÃ©cuter
        $scripts = @(
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-tools-references.ps1"
                Description = "Mise Ã  jour des rÃ©fÃ©rences pour les dossiers tools"
            },
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-project-structure-references.ps1"
                Description = "Mise Ã  jour des rÃ©fÃ©rences pour la structure du projet"
            },
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-config-references.ps1"
                Description = "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers de configuration"
            },
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-source-references.ps1"
                Description = "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers de code source"
            },
            @{
                Path        = Join-Path -Path $PSScriptRoot -ChildPath "update-documentation-references.ps1"
                Description = "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers de documentation"
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
ExÃ©cution du script $processedScripts/$totalScripts : $($script.Description)" -ForegroundColor Yellow

                # VÃ©rifier si le script existe
                if (-not (Test-Path -Path $script.Path)) {
                    Write-Warning "Le script $($script.Path) n'existe pas. Passage au script suivant."
                    continue
                }

                # ExÃ©cuter le script
                if ($PSCmdlet.ShouldProcess($script.Path, "ExÃ©cuter")) {
                    try {
                        & $script.Path
                        $successfulScripts++
                        Write-Host "  Script exÃ©cutÃ© avec succÃ¨s." -ForegroundColor Green
                    } catch {
                        Write-Error "Erreur lors de l'exÃ©cution du script $($script.Path) : $_"
                    }
                }

                # Afficher la progression
                $progress = [math]::Round(($processedScripts / $totalScripts) * 100)
                Write-Progress -Activity "ExÃ©cution des scripts de mise Ã  jour des rÃ©fÃ©rences" -Status "$processedScripts / $totalScripts scripts traitÃ©s ($progress%)" -PercentComplete $progress
            }

            Write-Progress -Activity "ExÃ©cution des scripts de mise Ã  jour des rÃ©fÃ©rences" -Completed

            Write-Host "
ExÃ©cution terminÃ©e !" -ForegroundColor Cyan
            Write-Host "  $successfulScripts scripts exÃ©cutÃ©s avec succÃ¨s sur $totalScripts scripts." -ForegroundColor Cyan
        } catch {
            Write-Error "Une erreur s'est produite lors de l'exÃ©cution des scripts de mise Ã  jour des rÃ©fÃ©rences : $_"
        }
    }

    end {
        Write-Host "
RÃ©capitulatif des scripts exÃ©cutÃ©s :" -ForegroundColor Yellow
        foreach ($script in $scripts) {
            Write-Host "  - $($script.Description) : $($script.Path)" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-AllReferences

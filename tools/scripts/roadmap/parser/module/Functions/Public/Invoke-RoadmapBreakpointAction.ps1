<#
.SYNOPSIS
    ExÃ©cute l'action associÃ©e Ã  un point d'arrÃªt.

.DESCRIPTION
    La fonction Invoke-RoadmapBreakpointAction exÃ©cute l'action associÃ©e Ã  un point d'arrÃªt.
    Elle prend en charge diffÃ©rentes actions comme l'interruption, la journalisation, etc.

.PARAMETER Breakpoint
    L'objet reprÃ©sentant le point d'arrÃªt.

.PARAMETER AdditionalInfo
    Informations supplÃ©mentaires Ã  inclure dans le message de journal.

.EXAMPLE
    $breakpoint = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Action = "Break"
        Message = "Point d'arrÃªt atteint"
        Category = "Breakpoint"
        LogLevel = "Debug"
    }
    Invoke-RoadmapBreakpointAction -Breakpoint $breakpoint
    ExÃ©cute l'action associÃ©e au point d'arrÃªt spÃ©cifiÃ©.

.OUTPUTS
    Aucun.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>
function Invoke-RoadmapBreakpointAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Breakpoint,

        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalInfo
    )

    # DÃ©finir une fonction Write-RoadmapLog locale si elle n'est pas dÃ©jÃ  disponible
    if (-not (Get-Command -Name Write-RoadmapLog -ErrorAction SilentlyContinue)) {
        function Write-RoadmapLog {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Message,

                [Parameter(Mandatory = $false)]
                [string]$Level = "Information",

                [Parameter(Mandatory = $false)]
                [string]$Category = "General"
            )

            Write-Verbose "[$Level] [$Category] $Message"
        }
    }

    # DÃ©finir une fonction Write-RoadmapBreakpointLog locale si elle n'est pas dÃ©jÃ  disponible
    if (-not (Get-Command -Name Write-RoadmapBreakpointLog -ErrorAction SilentlyContinue)) {
        function Write-RoadmapBreakpointLog {
            param (
                [Parameter(Mandatory = $true)]
                [PSCustomObject]$Breakpoint,

                [Parameter(Mandatory = $false)]
                [hashtable]$AdditionalInfo
            )

            $message = $Breakpoint.Message
            if ($Breakpoint.HitCount -gt 1) {
                $message += " (DÃ©clenchement #$($Breakpoint.HitCount))"
            }

            Write-RoadmapLog -Message $message -Level $Breakpoint.LogLevel -Category $Breakpoint.Category
        }
    }

    # ExÃ©cuter l'action en fonction du type
    switch ($Breakpoint.Action) {
        "Break" {
            # Journaliser le point d'arrÃªt
            Write-RoadmapBreakpointLog -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo

            # Afficher un message d'interruption
            $message = $Breakpoint.Message
            if ($Breakpoint.HitCount -gt 1) {
                $message += " (DÃ©clenchement #$($Breakpoint.HitCount))"
            }

            Write-Host "`n[POINT D'ARRÃŠT] $message" -ForegroundColor Yellow
            Write-Host "ID: $($Breakpoint.Id)" -ForegroundColor Yellow
            Write-Host "CatÃ©gorie: $($Breakpoint.Category)" -ForegroundColor Yellow
            Write-Host "Condition: $($Breakpoint.Condition)" -ForegroundColor Yellow
            Write-Host "Heure: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow

            # Afficher les informations supplÃ©mentaires
            if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
                Write-Host "Informations supplÃ©mentaires:" -ForegroundColor Yellow
                foreach ($key in $AdditionalInfo.Keys) {
                    Write-Host "  $key : $($AdditionalInfo[$key])" -ForegroundColor Yellow
                }
            }

            # Demander Ã  l'utilisateur s'il souhaite continuer
            $choices = @(
                [System.Management.Automation.Host.ChoiceDescription]::new("&Continuer", "Continue l'exÃ©cution")
                [System.Management.Automation.Host.ChoiceDescription]::new("&Examiner", "Examine les variables et l'Ã©tat actuel")
                [System.Management.Automation.Host.ChoiceDescription]::new("&Quitter", "Quitte l'exÃ©cution")
            )

            $decision = $Host.UI.PromptForChoice("Point d'arrÃªt atteint", "Que souhaitez-vous faire ?", $choices, 0)

            switch ($decision) {
                0 {
                    # Continuer l'exÃ©cution
                    Write-Host "Reprise de l'exÃ©cution..." -ForegroundColor Green
                }
                1 {
                    # Examiner les variables et l'Ã©tat actuel
                    Write-Host "Entrez des commandes PowerShell pour examiner l'Ã©tat actuel. Tapez 'exit' ou 'continue' pour reprendre l'exÃ©cution." -ForegroundColor Cyan

                    $continue = $false
                    while (-not $continue) {
                        $command = Read-Host "PS>"

                        if ($command -eq "exit" -or $command -eq "continue") {
                            $continue = $true
                        } else {
                            try {
                                Invoke-Expression $command
                            } catch {
                                Write-Host "Erreur : $_" -ForegroundColor Red
                            }
                        }
                    }

                    Write-Host "Reprise de l'exÃ©cution..." -ForegroundColor Green
                }
                2 {
                    # Quitter l'exÃ©cution
                    Write-Host "ArrÃªt de l'exÃ©cution..." -ForegroundColor Red
                    throw "ExÃ©cution interrompue par l'utilisateur au point d'arrÃªt '$($Breakpoint.Id)'."
                }
            }
        }
        "Continue" {
            # Journaliser le point d'arrÃªt et continuer
            Write-RoadmapBreakpointLog -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo

            # Afficher un message simple
            $message = $Breakpoint.Message
            if ($Breakpoint.HitCount -gt 1) {
                $message += " (DÃ©clenchement #$($Breakpoint.HitCount))"
            }

            Write-Host "[POINT D'ARRÃŠT] $message" -ForegroundColor Cyan
        }
        "Log" {
            # Journaliser le point d'arrÃªt sans affichage
            Write-RoadmapBreakpointLog -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo
        }
        "Custom" {
            # Journaliser le point d'arrÃªt
            Write-RoadmapBreakpointLog -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo

            # ExÃ©cuter l'action personnalisÃ©e
            if ($Breakpoint.CustomAction -is [scriptblock]) {
                try {
                    & $Breakpoint.CustomAction -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo
                } catch {
                    Write-RoadmapLog -Message "Erreur lors de l'exÃ©cution de l'action personnalisÃ©e : $_" -Level "Error" -Category "Breakpoint"
                }
            } else {
                Write-RoadmapLog -Message "L'action personnalisÃ©e n'est pas un ScriptBlock valide." -Level "Error" -Category "Breakpoint"
            }
        }
        default {
            # Action non reconnue, journaliser uniquement
            Write-RoadmapLog -Message "Action de point d'arrÃªt non reconnue : $($Breakpoint.Action)" -Level "Warning" -Category "Breakpoint"
            Write-RoadmapBreakpointLog -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo
        }
    }
}

<#
.SYNOPSIS
    DÃ©finit un point d'arrÃªt temporisÃ© dans le flux d'exÃ©cution.

.DESCRIPTION
    La fonction Set-RoadmapTimedBreakpoint permet de dÃ©finir un point d'arrÃªt temporisÃ©
    dans le flux d'exÃ©cution. Elle attend un dÃ©lai spÃ©cifiÃ© avant de dÃ©clencher le point d'arrÃªt.

.PARAMETER Seconds
    Le nombre de secondes Ã  attendre avant de dÃ©clencher le point d'arrÃªt.

.PARAMETER Milliseconds
    Le nombre de millisecondes Ã  attendre avant de dÃ©clencher le point d'arrÃªt.
    Ce paramÃ¨tre est ajoutÃ© au dÃ©lai spÃ©cifiÃ© par Seconds.

.PARAMETER Action
    L'action Ã  exÃ©cuter lorsque le dÃ©lai est Ã©coulÃ©. Valeurs possibles :
    - Break : Interrompt l'exÃ©cution et affiche un message (par dÃ©faut).
    - Continue : Continue l'exÃ©cution aprÃ¨s avoir journalisÃ© le point d'arrÃªt.
    - Log : Journalise le point d'arrÃªt sans interrompre l'exÃ©cution.
    - Custom : ExÃ©cute un ScriptBlock personnalisÃ©.

.PARAMETER CustomAction
    Un ScriptBlock personnalisÃ© Ã  exÃ©cuter lorsque le dÃ©lai est Ã©coulÃ© et que Action est "Custom".

.PARAMETER Message
    Un message Ã  afficher ou journaliser lorsque le point d'arrÃªt est atteint.

.PARAMETER Category
    La catÃ©gorie du point d'arrÃªt. Permet de regrouper les points d'arrÃªt par catÃ©gorie.
    Par dÃ©faut : "TimedBreakpoint".

.PARAMETER LogLevel
    Le niveau de journalisation Ã  utiliser pour le point d'arrÃªt. Valeurs possibles :
    - Debug : Message de dÃ©bogage (par dÃ©faut).
    - Verbose : Message dÃ©taillÃ©.
    - Information : Message d'information.
    - Warning : Message d'avertissement.
    - Error : Message d'erreur.
    - Critical : Message critique.

.PARAMETER PassThru
    Indique si la fonction doit retourner un objet reprÃ©sentant le point d'arrÃªt.
    Par dÃ©faut : $false.

.EXAMPLE
    Set-RoadmapTimedBreakpoint -Seconds 5 -Action Break -Message "5 secondes se sont Ã©coulÃ©es"
    DÃ©finit un point d'arrÃªt qui interrompt l'exÃ©cution aprÃ¨s 5 secondes.

.EXAMPLE
    Set-RoadmapTimedBreakpoint -Seconds 10 -Action Log -Message "10 secondes se sont Ã©coulÃ©es" -Category "Performance"
    DÃ©finit un point d'arrÃªt qui journalise un message aprÃ¨s 10 secondes.

.EXAMPLE
    Set-RoadmapTimedBreakpoint -Seconds 3 -Milliseconds 500 -Action Custom -CustomAction { Write-Host "Temps Ã©coulÃ© !" -ForegroundColor Red } -Message "3.5 secondes se sont Ã©coulÃ©es"
    DÃ©finit un point d'arrÃªt qui exÃ©cute une action personnalisÃ©e aprÃ¨s 3.5 secondes.

.OUTPUTS
    [PSCustomObject] Un objet reprÃ©sentant le point d'arrÃªt si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>
function Set-RoadmapTimedBreakpoint {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [int]$Seconds = 0,

        [Parameter(Mandatory = $false)]
        [int]$Milliseconds = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Break", "Continue", "Log", "Custom")]
        [string]$Action = "Break",

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomAction,

        [Parameter(Mandatory = $false)]
        [string]$Message = "Point d'arrÃªt temporisÃ© atteint",

        [Parameter(Mandatory = $false)]
        [string]$Category = "TimedBreakpoint",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Verbose", "Information", "Warning", "Error", "Critical")]
        [string]$LogLevel = "Debug",

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # DÃ©finir la fonction Invoke-RoadmapBreakpointAction si elle n'est pas dÃ©jÃ  disponible
    if (-not (Get-Command -Name Invoke-RoadmapBreakpointAction -ErrorAction SilentlyContinue)) {
        # Essayer d'importer la fonction depuis le fichier
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $invokeActionPath = Join-Path -Path $scriptPath -ChildPath "Invoke-RoadmapBreakpointAction.ps1"
        if (Test-Path -Path $invokeActionPath) {
            . $invokeActionPath
        } else {
            # DÃ©finir une version simplifiÃ©e de la fonction
            function Invoke-RoadmapBreakpointAction {
                param (
                    [Parameter(Mandatory = $true, Position = 0)]
                    [PSCustomObject]$Breakpoint,

                    [Parameter(Mandatory = $false)]
                    [hashtable]$AdditionalInfo
                )

                # ExÃ©cuter l'action en fonction du type
                switch ($Breakpoint.Action) {
                    "Break" {
                        # Afficher un message d'interruption
                        $message = $Breakpoint.Message
                        if ($Breakpoint.HitCount -gt 1) {
                            $message += " (DÃ©clenchement #$($Breakpoint.HitCount))"
                        }

                        Write-Host "`n[POINT D'ARRÃŠT] $message" -ForegroundColor Yellow
                    }
                    "Continue" {
                        # Afficher un message simple
                        $message = $Breakpoint.Message
                        if ($Breakpoint.HitCount -gt 1) {
                            $message += " (DÃ©clenchement #$($Breakpoint.HitCount))"
                        }

                        Write-Host "[POINT D'ARRÃŠT] $message" -ForegroundColor Cyan
                    }
                    "Log" {
                        # Journaliser le point d'arrÃªt sans affichage
                        Write-Verbose "[POINT D'ARRÃŠT] $($Breakpoint.Message)"
                    }
                    "Custom" {
                        # ExÃ©cuter l'action personnalisÃ©e
                        if ($Breakpoint.CustomAction -is [scriptblock]) {
                            try {
                                & $Breakpoint.CustomAction -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo
                            } catch {
                                Write-Warning "Erreur lors de l'exÃ©cution de l'action personnalisÃ©e : $_"
                            }
                        } else {
                            Write-Warning "L'action personnalisÃ©e n'est pas un ScriptBlock valide."
                        }
                    }
                    default {
                        # Action non reconnue, journaliser uniquement
                        Write-Warning "Action de point d'arrÃªt non reconnue : $($Breakpoint.Action)"
                    }
                }
            }
        }
    }

    # VÃ©rifier que CustomAction est fourni si Action est "Custom"
    if ($Action -eq "Custom" -and -not $CustomAction) {
        throw "Le paramÃ¨tre CustomAction est requis lorsque Action est 'Custom'."
    }

    # Calculer le dÃ©lai total en millisecondes
    $totalMilliseconds = ($Seconds * 1000) + $Milliseconds

    if ($totalMilliseconds -le 0) {
        throw "Le dÃ©lai doit Ãªtre supÃ©rieur Ã  zÃ©ro. Veuillez spÃ©cifier une valeur positive pour Seconds ou Milliseconds."
    }

    # CrÃ©er un objet reprÃ©sentant le point d'arrÃªt
    $breakpoint = [PSCustomObject]@{
        Id                     = [Guid]::NewGuid().ToString()
        DelaySeconds           = $Seconds
        DelayMilliseconds      = $Milliseconds
        TotalDelayMilliseconds = $totalMilliseconds
        Action                 = $Action
        CustomAction           = $CustomAction
        Message                = $Message
        Category               = $Category
        LogLevel               = $LogLevel
        CreatedAt              = Get-Date
        HitCount               = 0
        IsActive               = $true
        LastHitTime            = $null
    }

    # Attendre le dÃ©lai spÃ©cifiÃ©
    if ($PSCmdlet.ShouldProcess("Point d'arrÃªt temporisÃ©", "Attendre $Seconds secondes et $Milliseconds millisecondes")) {
        Write-Verbose "Attente de $Seconds secondes et $Milliseconds millisecondes..."

        # Utiliser Start-Sleep pour attendre
        if ($totalMilliseconds -ge 1000) {
            Start-Sleep -Seconds $Seconds
            if ($Milliseconds -gt 0) {
                Start-Sleep -Milliseconds $Milliseconds
            }
        } else {
            Start-Sleep -Milliseconds $totalMilliseconds
        }

        # Mettre Ã  jour le point d'arrÃªt
        $breakpoint.HitCount++
        $breakpoint.LastHitTime = Get-Date

        # ExÃ©cuter l'action
        Invoke-RoadmapBreakpointAction -Breakpoint $breakpoint
    }

    # Retourner l'objet point d'arrÃªt si PassThru est spÃ©cifiÃ©
    if ($PassThru) {
        return $breakpoint
    }
}

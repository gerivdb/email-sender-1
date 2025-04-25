<#
.SYNOPSIS
    Définit un point d'arrêt temporisé dans le flux d'exécution.

.DESCRIPTION
    La fonction Set-RoadmapTimedBreakpoint permet de définir un point d'arrêt temporisé
    dans le flux d'exécution. Elle attend un délai spécifié avant de déclencher le point d'arrêt.

.PARAMETER Seconds
    Le nombre de secondes à attendre avant de déclencher le point d'arrêt.

.PARAMETER Milliseconds
    Le nombre de millisecondes à attendre avant de déclencher le point d'arrêt.
    Ce paramètre est ajouté au délai spécifié par Seconds.

.PARAMETER Action
    L'action à exécuter lorsque le délai est écoulé. Valeurs possibles :
    - Break : Interrompt l'exécution et affiche un message (par défaut).
    - Continue : Continue l'exécution après avoir journalisé le point d'arrêt.
    - Log : Journalise le point d'arrêt sans interrompre l'exécution.
    - Custom : Exécute un ScriptBlock personnalisé.

.PARAMETER CustomAction
    Un ScriptBlock personnalisé à exécuter lorsque le délai est écoulé et que Action est "Custom".

.PARAMETER Message
    Un message à afficher ou journaliser lorsque le point d'arrêt est atteint.

.PARAMETER Category
    La catégorie du point d'arrêt. Permet de regrouper les points d'arrêt par catégorie.
    Par défaut : "TimedBreakpoint".

.PARAMETER LogLevel
    Le niveau de journalisation à utiliser pour le point d'arrêt. Valeurs possibles :
    - Debug : Message de débogage (par défaut).
    - Verbose : Message détaillé.
    - Information : Message d'information.
    - Warning : Message d'avertissement.
    - Error : Message d'erreur.
    - Critical : Message critique.

.PARAMETER PassThru
    Indique si la fonction doit retourner un objet représentant le point d'arrêt.
    Par défaut : $false.

.EXAMPLE
    Set-RoadmapTimedBreakpoint -Seconds 5 -Action Break -Message "5 secondes se sont écoulées"
    Définit un point d'arrêt qui interrompt l'exécution après 5 secondes.

.EXAMPLE
    Set-RoadmapTimedBreakpoint -Seconds 10 -Action Log -Message "10 secondes se sont écoulées" -Category "Performance"
    Définit un point d'arrêt qui journalise un message après 10 secondes.

.EXAMPLE
    Set-RoadmapTimedBreakpoint -Seconds 3 -Milliseconds 500 -Action Custom -CustomAction { Write-Host "Temps écoulé !" -ForegroundColor Red } -Message "3.5 secondes se sont écoulées"
    Définit un point d'arrêt qui exécute une action personnalisée après 3.5 secondes.

.OUTPUTS
    [PSCustomObject] Un objet représentant le point d'arrêt si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
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
        [string]$Message = "Point d'arrêt temporisé atteint",

        [Parameter(Mandatory = $false)]
        [string]$Category = "TimedBreakpoint",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Verbose", "Information", "Warning", "Error", "Critical")]
        [string]$LogLevel = "Debug",

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Définir la fonction Invoke-RoadmapBreakpointAction si elle n'est pas déjà disponible
    if (-not (Get-Command -Name Invoke-RoadmapBreakpointAction -ErrorAction SilentlyContinue)) {
        # Essayer d'importer la fonction depuis le fichier
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $invokeActionPath = Join-Path -Path $scriptPath -ChildPath "Invoke-RoadmapBreakpointAction.ps1"
        if (Test-Path -Path $invokeActionPath) {
            . $invokeActionPath
        } else {
            # Définir une version simplifiée de la fonction
            function Invoke-RoadmapBreakpointAction {
                param (
                    [Parameter(Mandatory = $true, Position = 0)]
                    [PSCustomObject]$Breakpoint,

                    [Parameter(Mandatory = $false)]
                    [hashtable]$AdditionalInfo
                )

                # Exécuter l'action en fonction du type
                switch ($Breakpoint.Action) {
                    "Break" {
                        # Afficher un message d'interruption
                        $message = $Breakpoint.Message
                        if ($Breakpoint.HitCount -gt 1) {
                            $message += " (Déclenchement #$($Breakpoint.HitCount))"
                        }

                        Write-Host "`n[POINT D'ARRÊT] $message" -ForegroundColor Yellow
                    }
                    "Continue" {
                        # Afficher un message simple
                        $message = $Breakpoint.Message
                        if ($Breakpoint.HitCount -gt 1) {
                            $message += " (Déclenchement #$($Breakpoint.HitCount))"
                        }

                        Write-Host "[POINT D'ARRÊT] $message" -ForegroundColor Cyan
                    }
                    "Log" {
                        # Journaliser le point d'arrêt sans affichage
                        Write-Verbose "[POINT D'ARRÊT] $($Breakpoint.Message)"
                    }
                    "Custom" {
                        # Exécuter l'action personnalisée
                        if ($Breakpoint.CustomAction -is [scriptblock]) {
                            try {
                                & $Breakpoint.CustomAction -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo
                            } catch {
                                Write-Warning "Erreur lors de l'exécution de l'action personnalisée : $_"
                            }
                        } else {
                            Write-Warning "L'action personnalisée n'est pas un ScriptBlock valide."
                        }
                    }
                    default {
                        # Action non reconnue, journaliser uniquement
                        Write-Warning "Action de point d'arrêt non reconnue : $($Breakpoint.Action)"
                    }
                }
            }
        }
    }

    # Vérifier que CustomAction est fourni si Action est "Custom"
    if ($Action -eq "Custom" -and -not $CustomAction) {
        throw "Le paramètre CustomAction est requis lorsque Action est 'Custom'."
    }

    # Calculer le délai total en millisecondes
    $totalMilliseconds = ($Seconds * 1000) + $Milliseconds

    if ($totalMilliseconds -le 0) {
        throw "Le délai doit être supérieur à zéro. Veuillez spécifier une valeur positive pour Seconds ou Milliseconds."
    }

    # Créer un objet représentant le point d'arrêt
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

    # Attendre le délai spécifié
    if ($PSCmdlet.ShouldProcess("Point d'arrêt temporisé", "Attendre $Seconds secondes et $Milliseconds millisecondes")) {
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

        # Mettre à jour le point d'arrêt
        $breakpoint.HitCount++
        $breakpoint.LastHitTime = Get-Date

        # Exécuter l'action
        Invoke-RoadmapBreakpointAction -Breakpoint $breakpoint
    }

    # Retourner l'objet point d'arrêt si PassThru est spécifié
    if ($PassThru) {
        return $breakpoint
    }
}

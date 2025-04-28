<#
.SYNOPSIS
    DÃ©finit un point d'arrÃªt conditionnel dans le flux d'exÃ©cution.

.DESCRIPTION
    La fonction Set-RoadmapBreakpoint permet de dÃ©finir un point d'arrÃªt conditionnel
    dans le flux d'exÃ©cution. Elle Ã©value une condition et, si celle-ci est vraie,
    exÃ©cute une action spÃ©cifiÃ©e (interruption, journalisation, etc.).

.PARAMETER Condition
    La condition Ã  Ã©valuer. Peut Ãªtre une expression PowerShell sous forme de chaÃ®ne
    ou un ScriptBlock qui retourne une valeur boolÃ©enne.

.PARAMETER Action
    L'action Ã  exÃ©cuter si la condition est vraie. Valeurs possibles :
    - Break : Interrompt l'exÃ©cution et affiche un message (par dÃ©faut).
    - Continue : Continue l'exÃ©cution aprÃ¨s avoir journalisÃ© le point d'arrÃªt.
    - Log : Journalise le point d'arrÃªt sans interrompre l'exÃ©cution.
    - Custom : ExÃ©cute un ScriptBlock personnalisÃ©.

.PARAMETER CustomAction
    Un ScriptBlock personnalisÃ© Ã  exÃ©cuter si la condition est vraie et que Action est "Custom".

.PARAMETER Message
    Un message Ã  afficher ou journaliser lorsque le point d'arrÃªt est atteint.

.PARAMETER Category
    La catÃ©gorie du point d'arrÃªt. Permet de regrouper les points d'arrÃªt par catÃ©gorie.
    Par dÃ©faut : "Breakpoint".

.PARAMETER LogLevel
    Le niveau de journalisation Ã  utiliser pour le point d'arrÃªt. Valeurs possibles :
    - Debug : Message de dÃ©bogage (par dÃ©faut).
    - Verbose : Message dÃ©taillÃ©.
    - Information : Message d'information.
    - Warning : Message d'avertissement.
    - Error : Message d'erreur.
    - Critical : Message critique.

.PARAMETER Timeout
    Le dÃ©lai en secondes aprÃ¨s lequel le point d'arrÃªt expire et n'est plus Ã©valuÃ©.
    Par dÃ©faut : 0 (pas de dÃ©lai).

.PARAMETER MaxHits
    Le nombre maximum de fois que le point d'arrÃªt peut Ãªtre atteint avant d'Ãªtre dÃ©sactivÃ©.
    Par dÃ©faut : 0 (pas de limite).

.PARAMETER PassThru
    Indique si la fonction doit retourner un objet reprÃ©sentant le point d'arrÃªt.
    Par dÃ©faut : $false.

.EXAMPLE
    Set-RoadmapBreakpoint -Condition '$i -gt 10' -Action Break -Message "La variable i a dÃ©passÃ© 10"
    DÃ©finit un point d'arrÃªt qui interrompt l'exÃ©cution lorsque la variable $i dÃ©passe 10.

.EXAMPLE
    Set-RoadmapBreakpoint -Condition { Test-Path $filePath } -Action Log -Message "Le fichier existe" -Category "FileSystem"
    DÃ©finit un point d'arrÃªt qui journalise un message lorsque le fichier spÃ©cifiÃ© existe.

.EXAMPLE
    Set-RoadmapBreakpoint -Condition '$retryCount -ge 5' -Action Custom -CustomAction { Send-Email -To "admin@example.com" -Subject "Trop de tentatives" } -Message "Trop de tentatives de connexion"
    DÃ©finit un point d'arrÃªt qui envoie un email lorsque le nombre de tentatives dÃ©passe 5.

.OUTPUTS
    [PSCustomObject] Un objet reprÃ©sentant le point d'arrÃªt si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>
function Set-RoadmapBreakpoint {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Condition,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Break", "Continue", "Log", "Custom")]
        [string]$Action = "Break",

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomAction,

        [Parameter(Mandatory = $false)]
        [string]$Message = "Point d'arrÃªt atteint",

        [Parameter(Mandatory = $false)]
        [string]$Category = "Breakpoint",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Verbose", "Information", "Warning", "Error", "Critical")]
        [string]$LogLevel = "Debug",

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxHits = 0,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # DÃ©finir la fonction Test-RoadmapBreakpointCondition si elle n'est pas dÃ©jÃ  disponible
    if (-not (Get-Command -Name Test-RoadmapBreakpointCondition -ErrorAction SilentlyContinue)) {
        # Essayer d'importer la fonction depuis le fichier
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $testConditionPath = Join-Path -Path $scriptPath -ChildPath "Test-RoadmapBreakpointCondition.ps1"
        if (Test-Path -Path $testConditionPath) {
            . $testConditionPath
        } else {
            # DÃ©finir une version simplifiÃ©e de la fonction
            function Test-RoadmapBreakpointCondition {
                param (
                    [Parameter(Mandatory = $true, Position = 0)]
                    [object]$Condition,

                    [Parameter(Mandatory = $false)]
                    [hashtable]$Variables,

                    [Parameter(Mandatory = $false)]
                    [switch]$ThrowOnError
                )

                try {
                    # DÃ©terminer le type de condition
                    if ($Condition -is [scriptblock]) {
                        # Condition sous forme de ScriptBlock
                        $result = & $Condition
                    } elseif ($Condition -is [string]) {
                        # Condition sous forme de chaÃ®ne
                        $result = Invoke-Expression $Condition
                    } else {
                        # Autre type de condition (considÃ©rer comme un boolÃ©en)
                        $result = [bool]$Condition
                    }

                    return [bool]$result
                } catch {
                    if ($ThrowOnError) {
                        throw $_
                    }

                    return $false
                }
            }
        }
    }

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

    # CrÃ©er un objet reprÃ©sentant le point d'arrÃªt
    $breakpoint = [PSCustomObject]@{
        Id           = [Guid]::NewGuid().ToString()
        Condition    = $Condition
        Action       = $Action
        CustomAction = $CustomAction
        Message      = $Message
        Category     = $Category
        LogLevel     = $LogLevel
        Timeout      = $Timeout
        MaxHits      = $MaxHits
        CreatedAt    = Get-Date
        ExpiresAt    = if ($Timeout -gt 0) { (Get-Date).AddSeconds($Timeout) } else { $null }
        HitCount     = 0
        IsActive     = $true
        LastHitTime  = $null
    }

    # Ã‰valuer la condition
    $conditionResult = Test-RoadmapBreakpointCondition -Condition $Condition

    # Si la condition est vraie, exÃ©cuter l'action
    if ($conditionResult) {
        if ($PSCmdlet.ShouldProcess("Point d'arrÃªt", "ExÃ©cuter l'action '$Action'")) {
            $breakpoint.HitCount++
            $breakpoint.LastHitTime = Get-Date

            # ExÃ©cuter l'action
            Invoke-RoadmapBreakpointAction -Breakpoint $breakpoint

            # DÃ©sactiver le point d'arrÃªt si MaxHits est atteint
            if ($MaxHits -gt 0 -and $breakpoint.HitCount -ge $MaxHits) {
                $breakpoint.IsActive = $false
                Write-Verbose "Le point d'arrÃªt a atteint le nombre maximum de dÃ©clenchements ($MaxHits) et a Ã©tÃ© dÃ©sactivÃ©."
            }
        }
    }

    # Retourner l'objet point d'arrÃªt si PassThru est spÃ©cifiÃ©
    if ($PassThru) {
        return $breakpoint
    }
}

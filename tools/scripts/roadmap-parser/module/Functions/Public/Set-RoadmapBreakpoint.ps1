<#
.SYNOPSIS
    Définit un point d'arrêt conditionnel dans le flux d'exécution.

.DESCRIPTION
    La fonction Set-RoadmapBreakpoint permet de définir un point d'arrêt conditionnel
    dans le flux d'exécution. Elle évalue une condition et, si celle-ci est vraie,
    exécute une action spécifiée (interruption, journalisation, etc.).

.PARAMETER Condition
    La condition à évaluer. Peut être une expression PowerShell sous forme de chaîne
    ou un ScriptBlock qui retourne une valeur booléenne.

.PARAMETER Action
    L'action à exécuter si la condition est vraie. Valeurs possibles :
    - Break : Interrompt l'exécution et affiche un message (par défaut).
    - Continue : Continue l'exécution après avoir journalisé le point d'arrêt.
    - Log : Journalise le point d'arrêt sans interrompre l'exécution.
    - Custom : Exécute un ScriptBlock personnalisé.

.PARAMETER CustomAction
    Un ScriptBlock personnalisé à exécuter si la condition est vraie et que Action est "Custom".

.PARAMETER Message
    Un message à afficher ou journaliser lorsque le point d'arrêt est atteint.

.PARAMETER Category
    La catégorie du point d'arrêt. Permet de regrouper les points d'arrêt par catégorie.
    Par défaut : "Breakpoint".

.PARAMETER LogLevel
    Le niveau de journalisation à utiliser pour le point d'arrêt. Valeurs possibles :
    - Debug : Message de débogage (par défaut).
    - Verbose : Message détaillé.
    - Information : Message d'information.
    - Warning : Message d'avertissement.
    - Error : Message d'erreur.
    - Critical : Message critique.

.PARAMETER Timeout
    Le délai en secondes après lequel le point d'arrêt expire et n'est plus évalué.
    Par défaut : 0 (pas de délai).

.PARAMETER MaxHits
    Le nombre maximum de fois que le point d'arrêt peut être atteint avant d'être désactivé.
    Par défaut : 0 (pas de limite).

.PARAMETER PassThru
    Indique si la fonction doit retourner un objet représentant le point d'arrêt.
    Par défaut : $false.

.EXAMPLE
    Set-RoadmapBreakpoint -Condition '$i -gt 10' -Action Break -Message "La variable i a dépassé 10"
    Définit un point d'arrêt qui interrompt l'exécution lorsque la variable $i dépasse 10.

.EXAMPLE
    Set-RoadmapBreakpoint -Condition { Test-Path $filePath } -Action Log -Message "Le fichier existe" -Category "FileSystem"
    Définit un point d'arrêt qui journalise un message lorsque le fichier spécifié existe.

.EXAMPLE
    Set-RoadmapBreakpoint -Condition '$retryCount -ge 5' -Action Custom -CustomAction { Send-Email -To "admin@example.com" -Subject "Trop de tentatives" } -Message "Trop de tentatives de connexion"
    Définit un point d'arrêt qui envoie un email lorsque le nombre de tentatives dépasse 5.

.OUTPUTS
    [PSCustomObject] Un objet représentant le point d'arrêt si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
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
        [string]$Message = "Point d'arrêt atteint",

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

    # Définir la fonction Test-RoadmapBreakpointCondition si elle n'est pas déjà disponible
    if (-not (Get-Command -Name Test-RoadmapBreakpointCondition -ErrorAction SilentlyContinue)) {
        # Essayer d'importer la fonction depuis le fichier
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $testConditionPath = Join-Path -Path $scriptPath -ChildPath "Test-RoadmapBreakpointCondition.ps1"
        if (Test-Path -Path $testConditionPath) {
            . $testConditionPath
        } else {
            # Définir une version simplifiée de la fonction
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
                    # Déterminer le type de condition
                    if ($Condition -is [scriptblock]) {
                        # Condition sous forme de ScriptBlock
                        $result = & $Condition
                    } elseif ($Condition -is [string]) {
                        # Condition sous forme de chaîne
                        $result = Invoke-Expression $Condition
                    } else {
                        # Autre type de condition (considérer comme un booléen)
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

    # Créer un objet représentant le point d'arrêt
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

    # Évaluer la condition
    $conditionResult = Test-RoadmapBreakpointCondition -Condition $Condition

    # Si la condition est vraie, exécuter l'action
    if ($conditionResult) {
        if ($PSCmdlet.ShouldProcess("Point d'arrêt", "Exécuter l'action '$Action'")) {
            $breakpoint.HitCount++
            $breakpoint.LastHitTime = Get-Date

            # Exécuter l'action
            Invoke-RoadmapBreakpointAction -Breakpoint $breakpoint

            # Désactiver le point d'arrêt si MaxHits est atteint
            if ($MaxHits -gt 0 -and $breakpoint.HitCount -ge $MaxHits) {
                $breakpoint.IsActive = $false
                Write-Verbose "Le point d'arrêt a atteint le nombre maximum de déclenchements ($MaxHits) et a été désactivé."
            }
        }
    }

    # Retourner l'objet point d'arrêt si PassThru est spécifié
    if ($PassThru) {
        return $breakpoint
    }
}

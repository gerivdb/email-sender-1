<#
.SYNOPSIS
    Fonctions de gestion des erreurs pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions de gestion des erreurs utilisÃ©es par tous les modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

<#
.SYNOPSIS
    GÃ¨re une exception et affiche un message d'erreur.

.DESCRIPTION
    Cette fonction gÃ¨re une exception et affiche un message d'erreur.

.PARAMETER Exception
    Exception Ã  gÃ©rer.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie Ã  retourner.

.PARAMETER ExitOnError
    Indique si le script doit se terminer en cas d'erreur.

.EXAMPLE
    Handle-Exception -Exception $_ -ErrorMessage "Une erreur s'est produite lors du traitement du fichier." -LogFile "logs\error.log" -ExitCode 1 -ExitOnError $true

.OUTPUTS
    None
#>
function Handle-Exception {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Une erreur s'est produite.",

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,

        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false
    )

    # Construire le message d'erreur complet
    $fullErrorMessage = "$ErrorMessage`nErreur : $($Exception.Message)`nType : $($Exception.GetType().FullName)"

    # Ajouter la trace de la pile si disponible
    if ($Exception.StackTrace) {
        $fullErrorMessage += "`nTrace de la pile :`n$($Exception.StackTrace)"
    }

    # Journaliser l'erreur
    Write-LogError $fullErrorMessage

    # Journaliser dans un fichier si spÃ©cifiÃ©
    if ($LogFile) {
        Write-LogToFile -Message $fullErrorMessage -Level "ERROR" -LogFile $LogFile
    }

    # Terminer le script si demandÃ©
    if ($ExitOnError) {
        exit $ExitCode
    }
}

<#
.SYNOPSIS
    GÃ¨re une erreur et affiche un message d'erreur.

.DESCRIPTION
    Cette fonction gÃ¨re une erreur et affiche un message d'erreur.

.PARAMETER ErrorRecord
    Enregistrement d'erreur Ã  gÃ©rer.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie Ã  retourner.

.PARAMETER ExitOnError
    Indique si le script doit se terminer en cas d'erreur.

.EXAMPLE
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du fichier." -LogFile "logs\error.log" -ExitCode 1 -ExitOnError $true

.OUTPUTS
    None
#>
function Handle-Error {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Une erreur s'est produite.",

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,

        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false
    )

    # Construire le message d'erreur complet
    $fullErrorMessage = "$ErrorMessage`nErreur : $($ErrorRecord.Exception.Message)`nType : $($ErrorRecord.Exception.GetType().FullName)`nCatÃ©gorie : $($ErrorRecord.CategoryInfo.Category)`nCible : $($ErrorRecord.CategoryInfo.TargetName)"

    # Ajouter la trace de la pile si disponible
    if ($ErrorRecord.ScriptStackTrace) {
        $fullErrorMessage += "`nTrace de la pile :`n$($ErrorRecord.ScriptStackTrace)"
    }

    # Journaliser l'erreur
    Write-LogError $fullErrorMessage

    # Journaliser dans un fichier si spÃ©cifiÃ©
    if ($LogFile) {
        Write-LogToFile -Message $fullErrorMessage -Level "ERROR" -LogFile $LogFile
    }

    # Terminer le script si demandÃ©
    if ($ExitOnError) {
        exit $ExitCode
    }
}

<#
.SYNOPSIS
    ExÃ©cute une action avec gestion des erreurs.

.DESCRIPTION
    Cette fonction exÃ©cute une action avec gestion des erreurs.

.PARAMETER Action
    Action Ã  exÃ©cuter.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie Ã  retourner.

.PARAMETER ExitOnError
    Indique si le script doit se terminer en cas d'erreur.

.EXAMPLE
    $result = Invoke-WithErrorHandling -Action { Get-Content -Path $FilePath } -ErrorMessage "Impossible de lire le fichier." -LogFile "logs\error.log" -ExitCode 1 -ExitOnError $true

.OUTPUTS
    System.Object
#>
function Invoke-WithErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Une erreur s'est produite lors de l'exÃ©cution de l'action.",

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,

        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false
    )

    try {
        # ExÃ©cuter l'action
        $result = & $Action
        return $result
    } catch {
        # GÃ©rer l'erreur
        Handle-Error -ErrorRecord $_ -ErrorMessage $ErrorMessage -LogFile $LogFile -ExitCode $ExitCode -ExitOnError $ExitOnError
    }
}

<#
.SYNOPSIS
    ExÃ©cute une action avec une nouvelle tentative en cas d'erreur.

.DESCRIPTION
    Cette fonction exÃ©cute une action avec une nouvelle tentative en cas d'erreur.

.PARAMETER Action
    Action Ã  exÃ©cuter.

.PARAMETER MaxRetries
    Nombre maximal de tentatives.

.PARAMETER RetryDelaySeconds
    DÃ©lai en secondes entre chaque tentative.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie Ã  retourner.

.PARAMETER ExitOnError
    Indique si le script doit se terminer en cas d'erreur.

.EXAMPLE
    $result = Invoke-WithRetry -Action { Invoke-RestMethod -Uri $Uri } -MaxRetries 3 -RetryDelaySeconds 5 -ErrorMessage "Impossible de se connecter au serveur." -LogFile "logs\error.log" -ExitCode 1 -ExitOnError $true

.OUTPUTS
    System.Object
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 5,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Une erreur s'est produite lors de l'exÃ©cution de l'action.",

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,

        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false
    )

    $retryCount = 0
    $success = $false
    $result = $null

    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            # ExÃ©cuter l'action
            $result = & $Action
            $success = $true
        } catch {
            $retryCount++

            if ($retryCount -ge $MaxRetries) {
                # GÃ©rer l'erreur aprÃ¨s le nombre maximal de tentatives
                Handle-Error -ErrorRecord $_ -ErrorMessage "$ErrorMessage (Tentative $retryCount/$MaxRetries)" -LogFile $LogFile -ExitCode $ExitCode -ExitOnError $ExitOnError
            } else {
                # Journaliser l'erreur et rÃ©essayer
                Write-LogWarning "Erreur lors de l'exÃ©cution de l'action : $($_.Exception.Message). Nouvelle tentative dans $RetryDelaySeconds secondes (Tentative $retryCount/$MaxRetries)."

                if ($LogFile) {
                    Write-LogToFile -Message "Erreur lors de l'exÃ©cution de l'action : $($_.Exception.Message). Nouvelle tentative dans $RetryDelaySeconds secondes (Tentative $retryCount/$MaxRetries)." -Level "WARNING" -LogFile $LogFile
                }

                # Attendre avant de rÃ©essayer
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }

    return $result
}

<#
.SYNOPSIS
    ExÃ©cute une action avec un dÃ©lai d'expiration.

.DESCRIPTION
    Cette fonction exÃ©cute une action avec un dÃ©lai d'expiration.

.PARAMETER Action
    Action Ã  exÃ©cuter.

.PARAMETER TimeoutSeconds
    DÃ©lai d'expiration en secondes.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie Ã  retourner.

.PARAMETER ExitOnError
    Indique si le script doit se terminer en cas d'erreur.

.EXAMPLE
    $result = Invoke-WithTimeout -Action { Invoke-RestMethod -Uri $Uri } -TimeoutSeconds 30 -ErrorMessage "L'opÃ©ration a expirÃ©." -LogFile "logs\error.log" -ExitCode 1 -ExitOnError $true

.OUTPUTS
    System.Object
#>
function Invoke-WithTimeout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "L'opÃ©ration a expirÃ© aprÃ¨s $TimeoutSeconds secondes.",

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,

        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false
    )

    # CrÃ©er un objet de synchronisation
    $sync = [System.Collections.Hashtable]::Synchronized(@{})
    $sync.Result = $null
    $sync.Completed = $false
    $sync.Error = $null

    # CrÃ©er un runspace pour exÃ©cuter l'action en arriÃ¨re-plan
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("action", $Action)

    # CrÃ©er et dÃ©marrer le pipeline
    $pipeline = $runspace.CreatePipeline({
            try {
                $sync.Result = & $action
                $sync.Completed = $true
            } catch {
                $sync.Error = $_
                $sync.Completed = $true
            }
        })
    $pipeline.InvokeAsync()

    # Attendre que l'action se termine ou que le dÃ©lai expire
    $startTime = Get-Date
    $timeoutReached = $false

    while (-not $sync.Completed -and -not $timeoutReached) {
        Start-Sleep -Milliseconds 100
        $elapsedTime = (Get-Date) - $startTime
        $timeoutReached = $elapsedTime.TotalSeconds -ge $TimeoutSeconds
    }

    # ArrÃªter le pipeline si le dÃ©lai a expirÃ©
    if ($timeoutReached) {
        $pipeline.Stop()
        $runspace.Close()

        # Journaliser l'erreur
        Write-LogError $ErrorMessage

        if ($LogFile) {
            Write-LogToFile -Message $ErrorMessage -Level "ERROR" -LogFile $LogFile
        }

        # Terminer le script si demandÃ©
        if ($ExitOnError) {
            exit $ExitCode
        }

        return $null
    }

    # Fermer le runspace
    $runspace.Close()

    # GÃ©rer l'erreur si elle s'est produite
    if ($sync.Error) {
        Handle-Error -ErrorRecord $sync.Error -ErrorMessage $ErrorMessage -LogFile $LogFile -ExitCode $ExitCode -ExitOnError $ExitOnError
    }

    return $sync.Result
}

# Exporter les fonctions
if ($MyInvocation.ScriptName -ne '') {
    # Nous sommes dans un module
    Export-ModuleMember -Function Handle-Exception, Handle-Error, Invoke-WithErrorHandling, Invoke-WithRetry, Invoke-WithTimeout
}

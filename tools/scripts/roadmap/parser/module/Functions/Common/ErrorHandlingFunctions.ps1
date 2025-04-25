<#
.SYNOPSIS
    Fonctions de gestion des erreurs pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions de gestion des erreurs utilisées par tous les modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

<#
.SYNOPSIS
    Gère une exception et affiche un message d'erreur.

.DESCRIPTION
    Cette fonction gère une exception et affiche un message d'erreur.

.PARAMETER Exception
    Exception à gérer.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie à retourner.

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
    
    # Journaliser dans un fichier si spécifié
    if ($LogFile) {
        Write-LogToFile -Message $fullErrorMessage -Level "ERROR" -LogFile $LogFile
    }
    
    # Terminer le script si demandé
    if ($ExitOnError) {
        exit $ExitCode
    }
}

<#
.SYNOPSIS
    Gère une erreur et affiche un message d'erreur.

.DESCRIPTION
    Cette fonction gère une erreur et affiche un message d'erreur.

.PARAMETER ErrorRecord
    Enregistrement d'erreur à gérer.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie à retourner.

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
    $fullErrorMessage = "$ErrorMessage`nErreur : $($ErrorRecord.Exception.Message)`nType : $($ErrorRecord.Exception.GetType().FullName)`nCatégorie : $($ErrorRecord.CategoryInfo.Category)`nCible : $($ErrorRecord.CategoryInfo.TargetName)"
    
    # Ajouter la trace de la pile si disponible
    if ($ErrorRecord.ScriptStackTrace) {
        $fullErrorMessage += "`nTrace de la pile :`n$($ErrorRecord.ScriptStackTrace)"
    }
    
    # Journaliser l'erreur
    Write-LogError $fullErrorMessage
    
    # Journaliser dans un fichier si spécifié
    if ($LogFile) {
        Write-LogToFile -Message $fullErrorMessage -Level "ERROR" -LogFile $LogFile
    }
    
    # Terminer le script si demandé
    if ($ExitOnError) {
        exit $ExitCode
    }
}

<#
.SYNOPSIS
    Exécute une action avec gestion des erreurs.

.DESCRIPTION
    Cette fonction exécute une action avec gestion des erreurs.

.PARAMETER Action
    Action à exécuter.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie à retourner.

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
        [string]$ErrorMessage = "Une erreur s'est produite lors de l'exécution de l'action.",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,
        
        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false
    )
    
    try {
        # Exécuter l'action
        $result = & $Action
        return $result
    } catch {
        # Gérer l'erreur
        Handle-Error -ErrorRecord $_ -ErrorMessage $ErrorMessage -LogFile $LogFile -ExitCode $ExitCode -ExitOnError $ExitOnError
    }
}

<#
.SYNOPSIS
    Exécute une action avec une nouvelle tentative en cas d'erreur.

.DESCRIPTION
    Cette fonction exécute une action avec une nouvelle tentative en cas d'erreur.

.PARAMETER Action
    Action à exécuter.

.PARAMETER MaxRetries
    Nombre maximal de tentatives.

.PARAMETER RetryDelaySeconds
    Délai en secondes entre chaque tentative.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie à retourner.

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
        [string]$ErrorMessage = "Une erreur s'est produite lors de l'exécution de l'action.",
        
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
            # Exécuter l'action
            $result = & $Action
            $success = $true
        } catch {
            $retryCount++
            
            if ($retryCount -ge $MaxRetries) {
                # Gérer l'erreur après le nombre maximal de tentatives
                Handle-Error -ErrorRecord $_ -ErrorMessage "$ErrorMessage (Tentative $retryCount/$MaxRetries)" -LogFile $LogFile -ExitCode $ExitCode -ExitOnError $ExitOnError
            } else {
                # Journaliser l'erreur et réessayer
                Write-LogWarning "Erreur lors de l'exécution de l'action : $($_.Exception.Message). Nouvelle tentative dans $RetryDelaySeconds secondes (Tentative $retryCount/$MaxRetries)."
                
                if ($LogFile) {
                    Write-LogToFile -Message "Erreur lors de l'exécution de l'action : $($_.Exception.Message). Nouvelle tentative dans $RetryDelaySeconds secondes (Tentative $retryCount/$MaxRetries)." -Level "WARNING" -LogFile $LogFile
                }
                
                # Attendre avant de réessayer
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }
    
    return $result
}

<#
.SYNOPSIS
    Exécute une action avec un délai d'expiration.

.DESCRIPTION
    Cette fonction exécute une action avec un délai d'expiration.

.PARAMETER Action
    Action à exécuter.

.PARAMETER TimeoutSeconds
    Délai d'expiration en secondes.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER ExitCode
    Code de sortie à retourner.

.PARAMETER ExitOnError
    Indique si le script doit se terminer en cas d'erreur.

.EXAMPLE
    $result = Invoke-WithTimeout -Action { Invoke-RestMethod -Uri $Uri } -TimeoutSeconds 30 -ErrorMessage "L'opération a expiré." -LogFile "logs\error.log" -ExitCode 1 -ExitOnError $true

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
        [string]$ErrorMessage = "L'opération a expiré après $TimeoutSeconds secondes.",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,
        
        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false
    )
    
    # Créer un objet de synchronisation
    $sync = [System.Collections.Hashtable]::Synchronized(@{})
    $sync.Result = $null
    $sync.Completed = $false
    $sync.Error = $null
    
    # Créer un runspace pour exécuter l'action en arrière-plan
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("action", $Action)
    
    # Créer et démarrer le pipeline
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
    
    # Attendre que l'action se termine ou que le délai expire
    $startTime = Get-Date
    $timeoutReached = $false
    
    while (-not $sync.Completed -and -not $timeoutReached) {
        Start-Sleep -Milliseconds 100
        $elapsedTime = (Get-Date) - $startTime
        $timeoutReached = $elapsedTime.TotalSeconds -ge $TimeoutSeconds
    }
    
    # Arrêter le pipeline si le délai a expiré
    if ($timeoutReached) {
        $pipeline.Stop()
        $runspace.Close()
        
        # Journaliser l'erreur
        Write-LogError $ErrorMessage
        
        if ($LogFile) {
            Write-LogToFile -Message $ErrorMessage -Level "ERROR" -LogFile $LogFile
        }
        
        # Terminer le script si demandé
        if ($ExitOnError) {
            exit $ExitCode
        }
        
        return $null
    }
    
    # Fermer le runspace
    $runspace.Close()
    
    # Gérer l'erreur si elle s'est produite
    if ($sync.Error) {
        Handle-Error -ErrorRecord $sync.Error -ErrorMessage $ErrorMessage -LogFile $LogFile -ExitCode $ExitCode -ExitOnError $ExitOnError
    }
    
    return $sync.Result
}

# Exporter les fonctions
Export-ModuleMember -Function Handle-Exception, Handle-Error, Invoke-WithErrorHandling, Invoke-WithRetry, Invoke-WithTimeout

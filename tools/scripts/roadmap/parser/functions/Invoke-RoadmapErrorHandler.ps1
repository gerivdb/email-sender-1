<#
.SYNOPSIS
    Gère les erreurs et les exceptions pour le module RoadmapParser.

.DESCRIPTION
    La fonction Invoke-RoadmapErrorHandler gère les erreurs et les exceptions pour le module RoadmapParser.
    Elle prend en charge différentes stratégies de récupération et peut journaliser les erreurs,
    les relancer, ou les ignorer selon les besoins.

.PARAMETER ErrorRecord
    L'enregistrement d'erreur à gérer.

.PARAMETER ErrorAction
    L'action à effectuer en cas d'erreur. Valeurs possibles : Continue, SilentlyContinue, Stop, Retry, Ignore.
    Par défaut : Continue.

.PARAMETER Category
    La catégorie de l'erreur. Permet de regrouper les erreurs par catégorie.
    Par défaut : General.

.PARAMETER MaxRetryCount
    Le nombre maximum de tentatives de récupération. Utilisé uniquement avec ErrorAction = Retry.
    Par défaut : 3.

.PARAMETER RetryDelaySeconds
    Le délai en secondes entre les tentatives de récupération. Utilisé uniquement avec ErrorAction = Retry.
    Par défaut : 1.

.PARAMETER LogFilePath
    Le chemin du fichier de journal. Si non spécifié, les erreurs seront journalisées uniquement dans la console.

.PARAMETER NoConsole
    Indique si les erreurs ne doivent pas être affichées dans la console.

.PARAMETER AdditionalInfo
    Informations supplémentaires à inclure dans le message d'erreur.

.PARAMETER ScriptBlock
    Le bloc de script à exécuter avec gestion des erreurs. Si spécifié, la fonction exécutera ce bloc
    et gérera les erreurs qui surviennent.

.PARAMETER ScriptBlockParams
    Les paramètres à passer au bloc de script.

.EXAMPLE
    try {
        # Code qui peut générer une erreur
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorAction Stop -Category "Parsing" -LogFilePath ".\logs\roadmap-parser.log"
    }
    Gère une erreur en la journalisant et en la relançant.

.EXAMPLE
    Invoke-RoadmapErrorHandler -ScriptBlock { Get-Content -Path $filePath } -ErrorAction Retry -MaxRetryCount 5 -Category "IO" -LogFilePath ".\logs\roadmap-parser.log"
    Exécute un bloc de script avec gestion des erreurs, en réessayant jusqu'à 5 fois en cas d'échec.

.OUTPUTS
    [PSObject] Le résultat du bloc de script si spécifié et exécuté avec succès.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-15
#>
function Invoke-RoadmapErrorHandler {
    [CmdletBinding(DefaultParameterSetName = "ErrorRecord")]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ErrorRecord")]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "SilentlyContinue", "Stop", "Retry", "Ignore")]
        [string]$ErrorHandlingAction = "Continue",

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [int]$MaxRetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 1,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]$AdditionalInfo,

        [Parameter(Mandatory = $true, ParameterSetName = "ScriptBlock")]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false, ParameterSetName = "ScriptBlock")]
        [System.Collections.Hashtable]$ScriptBlockParams
    )

    # Vérifier si les fonctions requises sont déjà chargées
    if (-not (Get-Command -Name "Write-RoadmapLog" -ErrorAction SilentlyContinue)) {
        # Importer les fonctions requises
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $logFunctionPath = Join-Path -Path $scriptPath -ChildPath "Write-RoadmapLog.ps1"

        if (Test-Path -Path $logFunctionPath) {
            . $logFunctionPath
        }
    }

    if (-not ([System.Management.Automation.PSTypeName]'RoadmapException').Type) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $exceptionPath = Join-Path -Path $scriptPath -ChildPath "exceptions\RoadmapException.ps1"

        if (Test-Path -Path $exceptionPath) {
            . $exceptionPath
        }
    }

    # Fonction pour gérer une erreur
    function Invoke-ErrorHandler {
        param (
            [System.Management.Automation.ErrorRecord]$ErrorRecord,
            [string]$ErrorHandlingAction,
            [string]$Category,
            [string]$LogFilePath,
            [switch]$NoConsole,
            [System.Collections.Hashtable]$AdditionalInfo
        )

        # Extraire l'exception
        $exception = $ErrorRecord.Exception

        # Journaliser l'erreur
        $logParams = @{
            Message   = "Une erreur est survenue: $($ErrorRecord.Exception.Message)"
            Level     = "Error"
            Category  = $Category
            Exception = $exception
            NoConsole = $NoConsole
        }

        if (-not [string]::IsNullOrEmpty($LogFilePath)) {
            $logParams["FilePath"] = $LogFilePath
        }

        if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
            $logParams["AdditionalInfo"] = $AdditionalInfo
        }

        if (Get-Command -Name "Write-RoadmapLog" -ErrorAction SilentlyContinue) {
            Write-RoadmapLog @logParams
        } else {
            # Fallback si Write-RoadmapLog n'est pas disponible
            $errorMessage = "[$Category] Error: $($ErrorRecord.Exception.Message)"
            if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
                $errorMessage += "`nAdditional Information:"
                foreach ($key in $AdditionalInfo.Keys) {
                    $errorMessage += "`n  - ${key}: $($AdditionalInfo[$key])"
                }
            }

            if (-not $NoConsole) {
                Write-Error $errorMessage
            }

            if (-not [string]::IsNullOrEmpty($LogFilePath)) {
                try {
                    $logDir = Split-Path -Path $LogFilePath -Parent
                    if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
                        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                    }

                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    "[$timestamp] [Error] $errorMessage" | Out-File -FilePath $LogFilePath -Append -Encoding UTF8
                } catch {
                    Write-Error "Erreur lors de l'écriture dans le fichier de journal '$LogFilePath': $_"
                }
            }
        }

        # Gérer l'erreur selon l'action spécifiée
        switch ($ErrorHandlingAction) {
            "Continue" {
                # Ne rien faire, l'erreur a été journalisée
            }
            "SilentlyContinue" {
                # Ne rien faire, l'erreur a été journalisée silencieusement
            }
            "Stop" {
                # Relancer l'exception
                throw $exception
            }
            "Ignore" {
                # Ne rien faire, ignorer complètement l'erreur
            }
        }
    }

    # Exécuter le bloc de script avec gestion des erreurs
    if ($PSCmdlet.ParameterSetName -eq "ScriptBlock") {
        $retryCount = 0
        $success = $false
        $result = $null

        while (-not $success -and $retryCount -le $MaxRetryCount) {
            try {
                if ($ScriptBlockParams -and $ScriptBlockParams.Count -gt 0) {
                    $result = & $ScriptBlock @ScriptBlockParams
                } else {
                    $result = & $ScriptBlock
                }

                $success = $true
            } catch {
                $retryCount++

                if ($ErrorHandlingAction -eq "Retry" -and $retryCount -le $MaxRetryCount) {
                    # Journaliser la tentative de récupération
                    $retryLogParams = @{
                        Message   = "Tentative de récupération $retryCount/$MaxRetryCount après erreur: $($_.Exception.Message)"
                        Level     = "Warning"
                        Category  = $Category
                        NoConsole = $NoConsole
                    }

                    if (-not [string]::IsNullOrEmpty($LogFilePath)) {
                        $retryLogParams["FilePath"] = $LogFilePath
                    }

                    if (Get-Command -Name "Write-RoadmapLog" -ErrorAction SilentlyContinue) {
                        Write-RoadmapLog @retryLogParams
                    } else {
                        # Fallback si Write-RoadmapLog n'est pas disponible
                        if (-not $NoConsole) {
                            Write-Warning "[$Category] Tentative de récupération $retryCount/$MaxRetryCount après erreur: $($_.Exception.Message)"
                        }
                    }

                    # Attendre avant de réessayer
                    Start-Sleep -Seconds $RetryDelaySeconds
                } else {
                    # Gérer l'erreur finale
                    Invoke-ErrorHandler -ErrorRecord $_ -ErrorHandlingAction $ErrorHandlingAction -Category $Category -LogFilePath $LogFilePath -NoConsole:$NoConsole -AdditionalInfo $AdditionalInfo

                    if ($ErrorHandlingAction -eq "Stop") {
                        # L'erreur a été relancée, sortir de la fonction
                        return
                    }
                }
            }
        }

        # Journaliser le succès après plusieurs tentatives
        if ($success -and $retryCount -gt 0) {
            $successLogParams = @{
                Message   = "Récupération réussie après $retryCount tentative(s)"
                Level     = "Info"
                Category  = $Category
                NoConsole = $NoConsole
            }

            if (-not [string]::IsNullOrEmpty($LogFilePath)) {
                $successLogParams["FilePath"] = $LogFilePath
            }

            if (Get-Command -Name "Write-RoadmapLog" -ErrorAction SilentlyContinue) {
                Write-RoadmapLog @successLogParams
            } else {
                # Fallback si Write-RoadmapLog n'est pas disponible
                if (-not $NoConsole) {
                    Write-Host "[$Category] Récupération réussie après $retryCount tentative(s)" -ForegroundColor Green
                }
            }
        }

        return $result
    } else {
        # Gérer l'erreur fournie
        Invoke-ErrorHandler -ErrorRecord $ErrorRecord -ErrorHandlingAction $ErrorHandlingAction -Category $Category -LogFilePath $LogFilePath -NoConsole:$NoConsole -AdditionalInfo $AdditionalInfo
    }
}

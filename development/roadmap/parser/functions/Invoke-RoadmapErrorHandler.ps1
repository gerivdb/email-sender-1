<#
.SYNOPSIS
    GÃ¨re les erreurs et les exceptions pour le module RoadmapParser.

.DESCRIPTION
    La fonction Invoke-RoadmapErrorHandler gÃ¨re les erreurs et les exceptions pour le module RoadmapParser.
    Elle prend en charge diffÃ©rentes stratÃ©gies de rÃ©cupÃ©ration et peut journaliser les erreurs,
    les relancer, ou les ignorer selon les besoins.

.PARAMETER ErrorRecord
    L'enregistrement d'erreur Ã  gÃ©rer.

.PARAMETER ErrorAction
    L'action Ã  effectuer en cas d'erreur. Valeurs possibles : Continue, SilentlyContinue, Stop, Retry, Ignore.
    Par dÃ©faut : Continue.

.PARAMETER Category
    La catÃ©gorie de l'erreur. Permet de regrouper les erreurs par catÃ©gorie.
    Par dÃ©faut : General.

.PARAMETER MaxRetryCount
    Le nombre maximum de tentatives de rÃ©cupÃ©ration. UtilisÃ© uniquement avec ErrorAction = Retry.
    Par dÃ©faut : 3.

.PARAMETER RetryDelaySeconds
    Le dÃ©lai en secondes entre les tentatives de rÃ©cupÃ©ration. UtilisÃ© uniquement avec ErrorAction = Retry.
    Par dÃ©faut : 1.

.PARAMETER LogFilePath
    Le chemin du fichier de journal. Si non spÃ©cifiÃ©, les erreurs seront journalisÃ©es uniquement dans la console.

.PARAMETER NoConsole
    Indique si les erreurs ne doivent pas Ãªtre affichÃ©es dans la console.

.PARAMETER AdditionalInfo
    Informations supplÃ©mentaires Ã  inclure dans le message d'erreur.

.PARAMETER ScriptBlock
    Le bloc de script Ã  exÃ©cuter avec gestion des erreurs. Si spÃ©cifiÃ©, la fonction exÃ©cutera ce bloc
    et gÃ©rera les erreurs qui surviennent.

.PARAMETER ScriptBlockParams
    Les paramÃ¨tres Ã  passer au bloc de script.

.EXAMPLE
    try {
        # Code qui peut gÃ©nÃ©rer une erreur
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorAction Stop -Category "Parsing" -LogFilePath ".\logs\roadmap-parser.log"
    }
    GÃ¨re une erreur en la journalisant et en la relanÃ§ant.

.EXAMPLE
    Invoke-RoadmapErrorHandler -ScriptBlock { Get-Content -Path $filePath } -ErrorAction Retry -MaxRetryCount 5 -Category "IO" -LogFilePath ".\logs\roadmap-parser.log"
    ExÃ©cute un bloc de script avec gestion des erreurs, en rÃ©essayant jusqu'Ã  5 fois en cas d'Ã©chec.

.OUTPUTS
    [PSObject] Le rÃ©sultat du bloc de script si spÃ©cifiÃ© et exÃ©cutÃ© avec succÃ¨s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-15
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

    # VÃ©rifier si les fonctions requises sont dÃ©jÃ  chargÃ©es
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

    # Fonction pour gÃ©rer une erreur
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
                    Write-Error "Erreur lors de l'Ã©criture dans le fichier de journal '$LogFilePath': $_"
                }
            }
        }

        # GÃ©rer l'erreur selon l'action spÃ©cifiÃ©e
        switch ($ErrorHandlingAction) {
            "Continue" {
                # Ne rien faire, l'erreur a Ã©tÃ© journalisÃ©e
            }
            "SilentlyContinue" {
                # Ne rien faire, l'erreur a Ã©tÃ© journalisÃ©e silencieusement
            }
            "Stop" {
                # Relancer l'exception
                throw $exception
            }
            "Ignore" {
                # Ne rien faire, ignorer complÃ¨tement l'erreur
            }
        }
    }

    # ExÃ©cuter le bloc de script avec gestion des erreurs
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
                    # Journaliser la tentative de rÃ©cupÃ©ration
                    $retryLogParams = @{
                        Message   = "Tentative de rÃ©cupÃ©ration $retryCount/$MaxRetryCount aprÃ¨s erreur: $($_.Exception.Message)"
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
                            Write-Warning "[$Category] Tentative de rÃ©cupÃ©ration $retryCount/$MaxRetryCount aprÃ¨s erreur: $($_.Exception.Message)"
                        }
                    }

                    # Attendre avant de rÃ©essayer
                    Start-Sleep -Seconds $RetryDelaySeconds
                } else {
                    # GÃ©rer l'erreur finale
                    Invoke-ErrorHandler -ErrorRecord $_ -ErrorHandlingAction $ErrorHandlingAction -Category $Category -LogFilePath $LogFilePath -NoConsole:$NoConsole -AdditionalInfo $AdditionalInfo

                    if ($ErrorHandlingAction -eq "Stop") {
                        # L'erreur a Ã©tÃ© relancÃ©e, sortir de la fonction
                        return
                    }
                }
            }
        }

        # Journaliser le succÃ¨s aprÃ¨s plusieurs tentatives
        if ($success -and $retryCount -gt 0) {
            $successLogParams = @{
                Message   = "RÃ©cupÃ©ration rÃ©ussie aprÃ¨s $retryCount tentative(s)"
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
                    Write-Host "[$Category] RÃ©cupÃ©ration rÃ©ussie aprÃ¨s $retryCount tentative(s)" -ForegroundColor Green
                }
            }
        }

        return $result
    } else {
        # GÃ©rer l'erreur fournie
        Invoke-ErrorHandler -ErrorRecord $ErrorRecord -ErrorHandlingAction $ErrorHandlingAction -Category $Category -LogFilePath $LogFilePath -NoConsole:$NoConsole -AdditionalInfo $AdditionalInfo
    }
}

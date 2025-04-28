<#
.SYNOPSIS
    Script de calcul des indicateurs clÃ©s de performance (KPIs) applicatifs - Partie 1.
.DESCRIPTION
    Calcule les KPIs applicatifs Ã  partir des donnÃ©es de performance collectÃ©es.
    Cette partie contient les fonctions de base et de journalisation.
#>

# Fonction pour la journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Verbose", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $LogLevels = @{
        "Verbose" = 0; "Info" = 1; "Warning" = 2; "Error" = 3
    }
    
    if ($LogLevels[$Level] -ge $LogLevels[$script:LogLevel]) {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            "Verbose" { Write-Verbose $LogMessage }
            "Info" { Write-Host $LogMessage -ForegroundColor Cyan }
            "Warning" { Write-Host $LogMessage -ForegroundColor Yellow }
            "Error" { Write-Host $LogMessage -ForegroundColor Red }
        }
    }
}

# Fonction pour charger les donnÃ©es
function Import-ApplicationData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    Write-Log -Message "Chargement des donnÃ©es depuis $FilePath" -Level "Info"
    
    try {
        if (Test-Path -Path $FilePath) {
            $Data = Import-Csv -Path $FilePath
            Write-Log -Message "Chargement rÃ©ussi: $($Data.Count) entrÃ©es" -Level "Info"
            return $Data
        } else {
            Write-Log -Message "Fichier non trouvÃ©: $FilePath" -Level "Error"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des donnÃ©es: $_" -Level "Error"
        return $null
    }
}

# Fonction pour charger la configuration des KPIs
function Import-KpiConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )
    
    Write-Log -Message "Chargement de la configuration des KPIs depuis $ConfigPath" -Level "Info"
    
    try {
        if (Test-Path -Path $ConfigPath) {
            $Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            Write-Log -Message "Configuration chargÃ©e avec succÃ¨s: $($Config.kpis.Count) KPIs dÃ©finis" -Level "Info"
            return $Config
        } else {
            Write-Log -Message "Fichier de configuration non trouvÃ©: $ConfigPath" -Level "Warning"
            
            # CrÃ©er une configuration par dÃ©faut simplifiÃ©e
            $DefaultConfig = @{
                kpis = @(
                    @{
                        id = "APP_RESPONSE_TIME"
                        name = "Temps de rÃ©ponse"
                        description = "Temps de rÃ©ponse moyen des requÃªtes applicatives"
                        category = "Performance"
                        unit = "ms"
                        formula = "AVG"
                        source = "ResponseTime"
                        thresholds = @{
                            warning = 500
                            critical = 1000
                        }
                    },
                    @{
                        id = "APP_ERROR_RATE"
                        name = "Taux d'erreur"
                        description = "Pourcentage de requÃªtes ayant gÃ©nÃ©rÃ© une erreur"
                        category = "FiabilitÃ©"
                        unit = "%"
                        formula = "PERCENTAGE"
                        sources = @("ErrorCount", "TotalRequests")
                        thresholds = @{
                            warning = 1
                            critical = 5
                        }
                    }
                )
            }
            
            # CrÃ©er le rÃ©pertoire de configuration s'il n'existe pas
            $ConfigDir = Split-Path -Parent $ConfigPath
            if (-not (Test-Path -Path $ConfigDir)) {
                New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder la configuration par dÃ©faut
            $DefaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
            
            Write-Log -Message "Configuration par dÃ©faut crÃ©Ã©e: $ConfigPath" -Level "Info"
            return $DefaultConfig
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement de la configuration: $_" -Level "Error"
        return $null
    }
}

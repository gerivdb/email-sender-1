<#
.SYNOPSIS
    Script de calcul des indicateurs clés de performance (KPIs) métier - Partie 1.
.DESCRIPTION
    Calcule les KPIs métier à partir des données collectées.
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

# Fonction pour charger les données
function Import-BusinessData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    Write-Log -Message "Chargement des données depuis $FilePath" -Level "Info"
    
    try {
        if (Test-Path -Path $FilePath) {
            $Data = Import-Csv -Path $FilePath
            Write-Log -Message "Chargement réussi: $($Data.Count) entrées" -Level "Info"
            return $Data
        } else {
            Write-Log -Message "Fichier non trouvé: $FilePath" -Level "Error"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des données: $_" -Level "Error"
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
            Write-Log -Message "Configuration chargée avec succès: $($Config.kpis.Count) KPIs définis" -Level "Info"
            return $Config
        } else {
            Write-Log -Message "Fichier de configuration non trouvé: $ConfigPath" -Level "Warning"
            
            # Créer une configuration par défaut simplifiée
            $DefaultConfig = @{
                kpis = @(
                    @{
                        id = "EMAIL_DELIVERY_RATE"
                        name = "Taux de livraison des emails"
                        description = "Pourcentage d'emails correctement livrés"
                        category = "Efficacité"
                        unit = "%"
                        formula = "PERCENTAGE"
                        sources = @("DeliveredEmails", "TotalEmails")
                        thresholds = @{
                            warning = 95
                            critical = 90
                        }
                        inverse = $true
                    },
                    @{
                        id = "EMAIL_OPEN_RATE"
                        name = "Taux d'ouverture des emails"
                        description = "Pourcentage d'emails ouverts par les destinataires"
                        category = "Engagement"
                        unit = "%"
                        formula = "PERCENTAGE"
                        sources = @("OpenedEmails", "DeliveredEmails")
                        thresholds = @{
                            warning = 15
                            critical = 10
                        }
                        inverse = $true
                    }
                )
            }
            
            # Créer le répertoire de configuration s'il n'existe pas
            $ConfigDir = Split-Path -Parent $ConfigPath
            if (-not (Test-Path -Path $ConfigDir)) {
                New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder la configuration par défaut
            $DefaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
            
            Write-Log -Message "Configuration par défaut créée: $ConfigPath" -Level "Info"
            return $DefaultConfig
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement de la configuration: $_" -Level "Error"
        return $null
    }
}

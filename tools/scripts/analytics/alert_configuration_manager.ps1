<#
.SYNOPSIS
    Script de configuration des alertes basÃ©es sur les seuils.
.DESCRIPTION
    Configure les alertes pour les diffÃ©rents KPIs en fonction des seuils dÃ©finis.
.PARAMETER ThresholdsPath
    Chemin vers les fichiers de seuils d'alerte.
.PARAMETER OutputPath
    Chemin oÃ¹ les configurations d'alerte seront sauvegardÃ©es.
.PARAMETER LogLevel
    Niveau de journalisation (Verbose, Info, Warning, Error).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ThresholdsPath = "config/alerts",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "config/alerts",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

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
    
    if ($LogLevels[$Level] -ge $LogLevels[$LogLevel]) {
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

# Fonction pour charger les seuils d'alerte
function Import-AlertThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ThresholdsPath
    )
    
    Write-Log -Message "Chargement des seuils d'alerte depuis $ThresholdsPath" -Level "Info"
    
    try {
        $Thresholds = @{}
        
        # VÃ©rifier si le rÃ©pertoire existe
        if (-not (Test-Path -Path $ThresholdsPath)) {
            Write-Log -Message "RÃ©pertoire des seuils d'alerte non trouvÃ©: $ThresholdsPath" -Level "Error"
            return $null
        }
        
        # Charger tous les fichiers de seuils JSON
        $ThresholdFiles = Get-ChildItem -Path $ThresholdsPath -Filter "*_alert_thresholds.json"
        
        foreach ($File in $ThresholdFiles) {
            $ThresholdType = $File.BaseName -replace "_alert_thresholds$", ""
            $ThresholdContent = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            
            Write-Log -Message "Seuils d'alerte chargÃ©s: $($File.Name) avec $($ThresholdContent.kpis.Count) KPIs" -Level "Info"
            $Thresholds[$ThresholdType] = $ThresholdContent
        }
        
        return $Thresholds
    } catch {
        Write-Log -Message "Erreur lors du chargement des seuils d'alerte: $_" -Level "Error"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer les configurations d'alerte
function Get-AlertConfigurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Thresholds
    )
    
    Write-Log -Message "GÃ©nÃ©ration des configurations d'alerte" -Level "Info"
    
    try {
        $AlertConfigurations = @{
            alerts = @()
            notification_channels = @(
                @{
                    id = "email"
                    name = "Email"
                    type = "email"
                    recipients = @("admin@example.com")
                },
                @{
                    id = "slack"
                    name = "Slack"
                    type = "slack"
                    webhook_url = "https://hooks.slack.com/services/XXXXX/YYYYY/ZZZZZ"
                    channel = "#alerts"
                }
            )
            alert_groups = @()
        }
        
        # CrÃ©er les groupes d'alerte par type de KPI
        foreach ($ThresholdType in $Thresholds.Keys) {
            $AlertGroup = @{
                id = "$($ThresholdType)_alerts"
                name = "Alertes $ThresholdType"
                description = "Groupe d'alertes pour les KPIs $ThresholdType"
                alerts = @()
            }
            
            # Ajouter les alertes pour chaque KPI
            foreach ($Kpi in $Thresholds[$ThresholdType].kpis) {
                $AlertId = "$($Kpi.id)_alert"
                
                # CrÃ©er l'alerte
                $Alert = @{
                    id = $AlertId
                    name = "Alerte $($Kpi.name)"
                    description = "Alerte pour le KPI $($Kpi.name)"
                    kpi_id = $Kpi.id
                    thresholds = $Kpi.thresholds
                    inverse = $Kpi.inverse
                    severity = @{
                        warning = "warning"
                        critical = "critical"
                    }
                    notification_channels = @("email")
                    cooldown_period = 300 # 5 minutes
                    evaluation_period = 60 # 1 minute
                    evaluation_count = 3 # 3 Ã©valuations consÃ©cutives
                    enabled = $true
                }
                
                # Ajouter l'alerte Ã  la liste globale
                $AlertConfigurations.alerts += $Alert
                
                # Ajouter l'ID de l'alerte au groupe
                $AlertGroup.alerts += $AlertId
            }
            
            # Ajouter le groupe Ã  la liste des groupes
            $AlertConfigurations.alert_groups += $AlertGroup
        }
        
        return $AlertConfigurations
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration des configurations d'alerte: $_" -Level "Error"
        return $null
    }
}

# Fonction pour exporter les configurations d'alerte
function Export-AlertConfigurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$AlertConfigurations,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "Exportation des configurations d'alerte vers $OutputPath" -Level "Info"
    
    try {
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Exporter la configuration globale
        $OutputFile = Join-Path -Path $OutputPath -ChildPath "alert_configurations.json"
        $AlertConfigurations | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
        
        Write-Log -Message "Configurations d'alerte exportÃ©es: $OutputFile" -Level "Info"
        
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des configurations d'alerte: $_" -Level "Error"
        return $false
    }
}

# Fonction pour gÃ©nÃ©rer la documentation des configurations d'alerte
function Export-AlertConfigurationsDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$AlertConfigurations,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "GÃ©nÃ©ration de la documentation des configurations d'alerte" -Level "Info"
    
    try {
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er le fichier de documentation
        $DocumentationPath = Join-Path -Path $OutputPath -ChildPath "alert_configurations_documentation.md"
        
        $Documentation = @"
# Documentation des configurations d'alerte

## Introduction

Ce document dÃ©crit les configurations d'alerte dÃ©finies pour les diffÃ©rents indicateurs clÃ©s de performance (KPIs) du systÃ¨me. Ces configurations dÃ©terminent comment et quand les alertes sont dÃ©clenchÃ©es, ainsi que les canaux de notification utilisÃ©s.

## Canaux de notification

Les alertes peuvent Ãªtre envoyÃ©es via les canaux de notification suivants :

"@
        
        # Ajouter les canaux de notification
        foreach ($Channel in $AlertConfigurations.notification_channels) {
            $Documentation += @"

### $($Channel.name)

- **ID** : $($Channel.id)
- **Type** : $($Channel.type)
"@
            
            if ($Channel.type -eq "email") {
                $Documentation += @"
- **Destinataires** : $($Channel.recipients -join ", ")
"@
            } elseif ($Channel.type -eq "slack") {
                $Documentation += @"
- **Canal** : $($Channel.channel)
"@
            }
        }
        
        $Documentation += @"

## Groupes d'alerte

Les alertes sont organisÃ©es en groupes pour faciliter leur gestion :

"@
        
        # Ajouter les groupes d'alerte
        foreach ($Group in $AlertConfigurations.alert_groups) {
            $Documentation += @"

### $($Group.name)

- **ID** : $($Group.id)
- **Description** : $($Group.description)
- **Nombre d'alertes** : $($Group.alerts.Count)
"@
        }
        
        $Documentation += @"

## Configurations d'alerte

Chaque KPI peut avoir une ou plusieurs alertes configurÃ©es :

"@
        
        # Ajouter les alertes
        foreach ($Alert in $AlertConfigurations.alerts) {
            $Documentation += @"

### $($Alert.name)

- **ID** : $($Alert.id)
- **Description** : $($Alert.description)
- **KPI** : $($Alert.kpi_id)
- **Seuils** :
  - Avertissement : $($Alert.thresholds.warning)
  - Critique : $($Alert.thresholds.critical)
- **Inverse** : $($Alert.inverse)
- **PÃ©riode d'Ã©valuation** : $($Alert.evaluation_period) secondes
- **Nombre d'Ã©valuations** : $($Alert.evaluation_count)
- **PÃ©riode de refroidissement** : $($Alert.cooldown_period) secondes
- **Canaux de notification** : $($Alert.notification_channels -join ", ")
- **ActivÃ©** : $($Alert.enabled)
"@
        }
        
        $Documentation += @"

## Logique de dÃ©clenchement

Les alertes sont dÃ©clenchÃ©es selon la logique suivante :

1. La valeur du KPI est Ã©valuÃ©e Ã  intervalles rÃ©guliers (pÃ©riode d'Ã©valuation)
2. Si la valeur dÃ©passe le seuil pendant un nombre consÃ©cutif d'Ã©valuations, l'alerte est dÃ©clenchÃ©e
3. AprÃ¨s le dÃ©clenchement d'une alerte, aucune nouvelle alerte n'est dÃ©clenchÃ©e pendant la pÃ©riode de refroidissement
4. Pour les KPIs inversÃ©s, l'alerte est dÃ©clenchÃ©e lorsque la valeur est infÃ©rieure au seuil

## DerniÃ¨re mise Ã  jour

Date de la derniÃ¨re mise Ã  jour : $(Get-Date -Format "yyyy-MM-dd")
"@
        
        # Sauvegarder la documentation
        $Documentation | Out-File -FilePath $DocumentationPath -Encoding UTF8
        
        Write-Log -Message "Documentation gÃ©nÃ©rÃ©e: $DocumentationPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration de la documentation: $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-AlertConfigurationManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ThresholdsPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "DÃ©but de la configuration des alertes" -Level "Info"
    
    # 1. Charger les seuils d'alerte
    $Thresholds = Import-AlertThresholds -ThresholdsPath $ThresholdsPath
    
    if (-not $Thresholds) {
        Write-Log -Message "Impossible de charger les seuils d'alerte" -Level "Error"
        return $false
    }
    
    # 2. GÃ©nÃ©rer les configurations d'alerte
    $AlertConfigurations = Get-AlertConfigurations -Thresholds $Thresholds
    
    if (-not $AlertConfigurations) {
        Write-Log -Message "Impossible de gÃ©nÃ©rer les configurations d'alerte" -Level "Error"
        return $false
    }
    
    # 3. Exporter les configurations d'alerte
    $ExportResult = Export-AlertConfigurations -AlertConfigurations $AlertConfigurations -OutputPath $OutputPath
    
    if (-not $ExportResult) {
        Write-Log -Message "Impossible d'exporter les configurations d'alerte" -Level "Error"
        return $false
    }
    
    # 4. GÃ©nÃ©rer la documentation
    $DocumentationResult = Export-AlertConfigurationsDocumentation -AlertConfigurations $AlertConfigurations -OutputPath $OutputPath
    
    if (-not $DocumentationResult) {
        Write-Log -Message "Impossible de gÃ©nÃ©rer la documentation des configurations d'alerte" -Level "Warning"
    }
    
    Write-Log -Message "Configuration des alertes terminÃ©e avec succÃ¨s" -Level "Info"
    return $true
}

# ExÃ©cution du script
$Result = Start-AlertConfigurationManager -ThresholdsPath $ThresholdsPath -OutputPath $OutputPath

if ($Result) {
    Write-Log -Message "Configuration des alertes rÃ©ussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Ã‰chec de la configuration des alertes" -Level "Error"
    return 1
}

<#
.SYNOPSIS
    Script de configuration des alertes basées sur les seuils.
.DESCRIPTION
    Configure les alertes pour les différents KPIs en fonction des seuils définis.
.PARAMETER ThresholdsPath
    Chemin vers les fichiers de seuils d'alerte.
.PARAMETER OutputPath
    Chemin où les configurations d'alerte seront sauvegardées.
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
        
        # Vérifier si le répertoire existe
        if (-not (Test-Path -Path $ThresholdsPath)) {
            Write-Log -Message "Répertoire des seuils d'alerte non trouvé: $ThresholdsPath" -Level "Error"
            return $null
        }
        
        # Charger tous les fichiers de seuils JSON
        $ThresholdFiles = Get-ChildItem -Path $ThresholdsPath -Filter "*_alert_thresholds.json"
        
        foreach ($File in $ThresholdFiles) {
            $ThresholdType = $File.BaseName -replace "_alert_thresholds$", ""
            $ThresholdContent = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            
            Write-Log -Message "Seuils d'alerte chargés: $($File.Name) avec $($ThresholdContent.kpis.Count) KPIs" -Level "Info"
            $Thresholds[$ThresholdType] = $ThresholdContent
        }
        
        return $Thresholds
    } catch {
        Write-Log -Message "Erreur lors du chargement des seuils d'alerte: $_" -Level "Error"
        return $null
    }
}

# Fonction pour générer les configurations d'alerte
function Get-AlertConfigurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Thresholds
    )
    
    Write-Log -Message "Génération des configurations d'alerte" -Level "Info"
    
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
        
        # Créer les groupes d'alerte par type de KPI
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
                
                # Créer l'alerte
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
                    evaluation_count = 3 # 3 évaluations consécutives
                    enabled = $true
                }
                
                # Ajouter l'alerte à la liste globale
                $AlertConfigurations.alerts += $Alert
                
                # Ajouter l'ID de l'alerte au groupe
                $AlertGroup.alerts += $AlertId
            }
            
            # Ajouter le groupe à la liste des groupes
            $AlertConfigurations.alert_groups += $AlertGroup
        }
        
        return $AlertConfigurations
    } catch {
        Write-Log -Message "Erreur lors de la génération des configurations d'alerte: $_" -Level "Error"
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
        # Créer le répertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Exporter la configuration globale
        $OutputFile = Join-Path -Path $OutputPath -ChildPath "alert_configurations.json"
        $AlertConfigurations | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
        
        Write-Log -Message "Configurations d'alerte exportées: $OutputFile" -Level "Info"
        
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des configurations d'alerte: $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer la documentation des configurations d'alerte
function Export-AlertConfigurationsDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$AlertConfigurations,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "Génération de la documentation des configurations d'alerte" -Level "Info"
    
    try {
        # Créer le répertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Créer le fichier de documentation
        $DocumentationPath = Join-Path -Path $OutputPath -ChildPath "alert_configurations_documentation.md"
        
        $Documentation = @"
# Documentation des configurations d'alerte

## Introduction

Ce document décrit les configurations d'alerte définies pour les différents indicateurs clés de performance (KPIs) du système. Ces configurations déterminent comment et quand les alertes sont déclenchées, ainsi que les canaux de notification utilisés.

## Canaux de notification

Les alertes peuvent être envoyées via les canaux de notification suivants :

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

Les alertes sont organisées en groupes pour faciliter leur gestion :

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

Chaque KPI peut avoir une ou plusieurs alertes configurées :

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
- **Période d'évaluation** : $($Alert.evaluation_period) secondes
- **Nombre d'évaluations** : $($Alert.evaluation_count)
- **Période de refroidissement** : $($Alert.cooldown_period) secondes
- **Canaux de notification** : $($Alert.notification_channels -join ", ")
- **Activé** : $($Alert.enabled)
"@
        }
        
        $Documentation += @"

## Logique de déclenchement

Les alertes sont déclenchées selon la logique suivante :

1. La valeur du KPI est évaluée à intervalles réguliers (période d'évaluation)
2. Si la valeur dépasse le seuil pendant un nombre consécutif d'évaluations, l'alerte est déclenchée
3. Après le déclenchement d'une alerte, aucune nouvelle alerte n'est déclenchée pendant la période de refroidissement
4. Pour les KPIs inversés, l'alerte est déclenchée lorsque la valeur est inférieure au seuil

## Dernière mise à jour

Date de la dernière mise à jour : $(Get-Date -Format "yyyy-MM-dd")
"@
        
        # Sauvegarder la documentation
        $Documentation | Out-File -FilePath $DocumentationPath -Encoding UTF8
        
        Write-Log -Message "Documentation générée: $DocumentationPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la génération de la documentation: $_" -Level "Error"
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
    
    Write-Log -Message "Début de la configuration des alertes" -Level "Info"
    
    # 1. Charger les seuils d'alerte
    $Thresholds = Import-AlertThresholds -ThresholdsPath $ThresholdsPath
    
    if (-not $Thresholds) {
        Write-Log -Message "Impossible de charger les seuils d'alerte" -Level "Error"
        return $false
    }
    
    # 2. Générer les configurations d'alerte
    $AlertConfigurations = Get-AlertConfigurations -Thresholds $Thresholds
    
    if (-not $AlertConfigurations) {
        Write-Log -Message "Impossible de générer les configurations d'alerte" -Level "Error"
        return $false
    }
    
    # 3. Exporter les configurations d'alerte
    $ExportResult = Export-AlertConfigurations -AlertConfigurations $AlertConfigurations -OutputPath $OutputPath
    
    if (-not $ExportResult) {
        Write-Log -Message "Impossible d'exporter les configurations d'alerte" -Level "Error"
        return $false
    }
    
    # 4. Générer la documentation
    $DocumentationResult = Export-AlertConfigurationsDocumentation -AlertConfigurations $AlertConfigurations -OutputPath $OutputPath
    
    if (-not $DocumentationResult) {
        Write-Log -Message "Impossible de générer la documentation des configurations d'alerte" -Level "Warning"
    }
    
    Write-Log -Message "Configuration des alertes terminée avec succès" -Level "Info"
    return $true
}

# Exécution du script
$Result = Start-AlertConfigurationManager -ThresholdsPath $ThresholdsPath -OutputPath $OutputPath

if ($Result) {
    Write-Log -Message "Configuration des alertes réussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Échec de la configuration des alertes" -Level "Error"
    return 1
}

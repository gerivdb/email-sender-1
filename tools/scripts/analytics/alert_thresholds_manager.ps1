<#
.SYNOPSIS
    Script de gestion des seuils d'alerte pour les KPIs.
.DESCRIPTION
    Permet de dÃ©finir, valider et ajuster les seuils d'alerte pour les diffÃ©rents KPIs.
.PARAMETER ConfigPath
    Chemin vers le rÃ©pertoire de configuration des KPIs.
.PARAMETER OutputPath
    Chemin oÃ¹ les seuils d'alerte seront sauvegardÃ©s.
.PARAMETER HistoricalDataPath
    Chemin vers les donnÃ©es historiques pour l'analyse statistique.
.PARAMETER LogLevel
    Niveau de journalisation (Verbose, Info, Warning, Error).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "config/kpis",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "config/alerts",
    
    [Parameter(Mandatory=$false)]
    [string]$HistoricalDataPath = "data/kpis",
    
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

# Fonction pour charger les configurations des KPIs
function Import-KpiConfigurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )
    
    Write-Log -Message "Chargement des configurations des KPIs depuis $ConfigPath" -Level "Info"
    
    try {
        $Configurations = @{}
        
        # VÃ©rifier si le rÃ©pertoire existe
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Log -Message "RÃ©pertoire de configuration non trouvÃ©: $ConfigPath" -Level "Error"
            return $null
        }
        
        # Charger tous les fichiers de configuration JSON
        $ConfigFiles = Get-ChildItem -Path $ConfigPath -Filter "*.json"
        
        foreach ($File in $ConfigFiles) {
            $ConfigType = $File.BaseName -replace "_kpis$", ""
            $ConfigContent = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            
            Write-Log -Message "Configuration chargÃ©e: $($File.Name) avec $($ConfigContent.kpis.Count) KPIs" -Level "Info"
            $Configurations[$ConfigType] = $ConfigContent
        }
        
        return $Configurations
    } catch {
        Write-Log -Message "Erreur lors du chargement des configurations: $_" -Level "Error"
        return $null
    }
}

# Fonction pour charger les donnÃ©es historiques des KPIs
function Import-HistoricalData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoricalDataPath
    )
    
    Write-Log -Message "Chargement des donnÃ©es historiques depuis $HistoricalDataPath" -Level "Info"
    
    try {
        $HistoricalData = @{}
        
        # VÃ©rifier si le rÃ©pertoire existe
        if (-not (Test-Path -Path $HistoricalDataPath)) {
            Write-Log -Message "RÃ©pertoire de donnÃ©es historiques non trouvÃ©: $HistoricalDataPath" -Level "Error"
            return $null
        }
        
        # Charger tous les fichiers CSV
        $DataFiles = Get-ChildItem -Path $HistoricalDataPath -Filter "*.csv"
        
        foreach ($File in $DataFiles) {
            $DataType = $File.BaseName -replace "_kpis$", ""
            $DataContent = Import-Csv -Path $File.FullName
            
            Write-Log -Message "DonnÃ©es historiques chargÃ©es: $($File.Name) avec $($DataContent.Count) entrÃ©es" -Level "Info"
            $HistoricalData[$DataType] = $DataContent
        }
        
        return $HistoricalData
    } catch {
        Write-Log -Message "Erreur lors du chargement des donnÃ©es historiques: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer les seuils statistiques
function Get-StatisticalThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$KpiId,
        
        [Parameter(Mandatory=$false)]
        [double]$WarningPercentile = 90,
        
        [Parameter(Mandatory=$false)]
        [double]$CriticalPercentile = 95,
        
        [Parameter(Mandatory=$false)]
        [bool]$Inverse = $false
    )
    
    Write-Log -Message "Calcul des seuils statistiques pour $KpiId" -Level "Verbose"
    
    try {
        # Filtrer les donnÃ©es pour le KPI spÃ©cifiÃ©
        $KpiData = $Data | Where-Object { $_.Id -eq $KpiId }
        
        if (-not $KpiData -or $KpiData.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e historique trouvÃ©e pour le KPI: $KpiId" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $KpiData | ForEach-Object { [double]$_.Value }
        
        # Trier les valeurs
        $SortedValues = $Values | Sort-Object
        
        # Calculer les percentiles
        $WarningIndex = [Math]::Ceiling($SortedValues.Count * ($WarningPercentile / 100)) - 1
        $CriticalIndex = [Math]::Ceiling($SortedValues.Count * ($CriticalPercentile / 100)) - 1
        
        # Ajuster les indices pour Ã©viter les dÃ©passements
        $WarningIndex = [Math]::Min($WarningIndex, $SortedValues.Count - 1)
        $CriticalIndex = [Math]::Min($CriticalIndex, $SortedValues.Count - 1)
        
        # Obtenir les valeurs des seuils
        $WarningThreshold = $SortedValues[$WarningIndex]
        $CriticalThreshold = $SortedValues[$CriticalIndex]
        
        # Inverser les seuils si nÃ©cessaire
        if ($Inverse) {
            $TempWarning = $WarningThreshold
            $WarningThreshold = $SortedValues[[Math]::Floor($SortedValues.Count * (1 - $WarningPercentile / 100))]
            $CriticalThreshold = $SortedValues[[Math]::Floor($SortedValues.Count * (1 - $CriticalPercentile / 100))]
        }
        
        return @{
            warning = $WarningThreshold
            critical = $CriticalThreshold
        }
    } catch {
        Write-Log -Message "Erreur lors du calcul des seuils statistiques: $_" -Level "Error"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer les seuils d'alerte
function Get-AlertThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Configurations,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$HistoricalData,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Static", "Statistical", "Hybrid")]
        [string]$Method = "Hybrid",
        
        [Parameter(Mandatory=$false)]
        [double]$StatisticalWeight = 0.5
    )
    
    Write-Log -Message "GÃ©nÃ©ration des seuils d'alerte avec la mÃ©thode: $Method" -Level "Info"
    
    try {
        $AlertThresholds = @{}
        
        foreach ($ConfigType in $Configurations.Keys) {
            $AlertThresholds[$ConfigType] = @{
                kpis = @()
            }
            
            foreach ($Kpi in $Configurations[$ConfigType].kpis) {
                $Thresholds = @{}
                
                # Obtenir les seuils statiques depuis la configuration
                $StaticThresholds = @{
                    warning = $Kpi.thresholds.warning
                    critical = $Kpi.thresholds.critical
                }
                
                # VÃ©rifier si des donnÃ©es historiques sont disponibles
                if ($HistoricalData.ContainsKey($ConfigType)) {
                    # Obtenir les seuils statistiques
                    $Inverse = $Kpi.PSObject.Properties.Name -contains "inverse" -and $Kpi.inverse
                    $StatisticalThresholds = Get-StatisticalThresholds -Data $HistoricalData[$ConfigType] -KpiId $Kpi.id -Inverse $Inverse
                    
                    # Combiner les seuils selon la mÃ©thode spÃ©cifiÃ©e
                    switch ($Method) {
                        "Static" {
                            $Thresholds = $StaticThresholds
                        }
                        "Statistical" {
                            if ($StatisticalThresholds) {
                                $Thresholds = $StatisticalThresholds
                            } else {
                                $Thresholds = $StaticThresholds
                            }
                        }
                        "Hybrid" {
                            if ($StatisticalThresholds) {
                                $Thresholds = @{
                                    warning = $StaticThresholds.warning * (1 - $StatisticalWeight) + $StatisticalThresholds.warning * $StatisticalWeight
                                    critical = $StaticThresholds.critical * (1 - $StatisticalWeight) + $StatisticalThresholds.critical * $StatisticalWeight
                                }
                            } else {
                                $Thresholds = $StaticThresholds
                            }
                        }
                    }
                } else {
                    $Thresholds = $StaticThresholds
                }
                
                # Ajouter les seuils au rÃ©sultat
                $AlertThresholds[$ConfigType].kpis += @{
                    id = $Kpi.id
                    name = $Kpi.name
                    description = $Kpi.description
                    category = $Kpi.category
                    unit = $Kpi.unit
                    thresholds = $Thresholds
                    inverse = $Kpi.PSObject.Properties.Name -contains "inverse" -and $Kpi.inverse
                }
            }
        }
        
        return $AlertThresholds
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration des seuils d'alerte: $_" -Level "Error"
        return $null
    }
}

# Fonction pour exporter les seuils d'alerte
function Export-AlertThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$AlertThresholds,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "Exportation des seuils d'alerte vers $OutputPath" -Level "Info"
    
    try {
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les seuils pour chaque type de KPI
        foreach ($ThresholdType in $AlertThresholds.Keys) {
            $OutputFile = Join-Path -Path $OutputPath -ChildPath "$($ThresholdType)_alert_thresholds.json"
            $AlertThresholds[$ThresholdType] | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
            
            Write-Log -Message "Seuils d'alerte exportÃ©s: $OutputFile" -Level "Info"
        }
        
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des seuils d'alerte: $_" -Level "Error"
        return $false
    }
}

# Fonction pour gÃ©nÃ©rer la documentation des seuils d'alerte
function Export-AlertThresholdsDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$AlertThresholds,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "GÃ©nÃ©ration de la documentation des seuils d'alerte" -Level "Info"
    
    try {
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er le fichier de documentation
        $DocumentationPath = Join-Path -Path $OutputPath -ChildPath "alert_thresholds_documentation.md"
        
        $Documentation = @"
# Documentation des seuils d'alerte

## Introduction

Ce document dÃ©crit les seuils d'alerte dÃ©finis pour les diffÃ©rents indicateurs clÃ©s de performance (KPIs) du systÃ¨me. Ces seuils sont utilisÃ©s pour dÃ©clencher des alertes lorsque les valeurs des KPIs dÃ©passent certains niveaux, permettant ainsi une dÃ©tection prÃ©coce des problÃ¨mes potentiels.

## MÃ©thodologie

Les seuils d'alerte ont Ã©tÃ© dÃ©finis en utilisant une combinaison des approches suivantes :

1. **Seuils statiques** : DÃ©finis manuellement en fonction des bonnes pratiques et des exigences mÃ©tier
2. **Seuils statistiques** : CalculÃ©s Ã  partir des donnÃ©es historiques en utilisant des percentiles
3. **Seuils hybrides** : Combinaison pondÃ©rÃ©e des seuils statiques et statistiques

## Niveaux d'alerte

Deux niveaux d'alerte sont dÃ©finis pour chaque KPI :

- **Avertissement (Warning)** : Indique une situation qui mÃ©rite attention mais n'est pas critique
- **Critique (Critical)** : Indique une situation qui nÃ©cessite une intervention immÃ©diate

## Seuils par catÃ©gorie de KPI

"@
        
        # Ajouter les seuils pour chaque type de KPI
        foreach ($ThresholdType in $AlertThresholds.Keys) {
            $Documentation += @"

### KPIs $ThresholdType

| ID | Nom | CatÃ©gorie | UnitÃ© | Seuil d'avertissement | Seuil critique | Inverse |
|---|---|---|---|---|---|---|
"@
            
            foreach ($Kpi in $AlertThresholds[$ThresholdType].kpis) {
                $InverseText = if ($Kpi.inverse) { "Oui" } else { "Non" }
                $Documentation += @"
| $($Kpi.id) | $($Kpi.name) | $($Kpi.category) | $($Kpi.unit) | $([Math]::Round($Kpi.thresholds.warning, 2)) | $([Math]::Round($Kpi.thresholds.critical, 2)) | $InverseText |
"@
            }
        }
        
        $Documentation += @"

## InterprÃ©tation

- **Seuil normal** : Valeur en dessous du seuil d'avertissement (ou au-dessus pour les KPIs inversÃ©s)
- **Seuil d'avertissement** : Valeur entre le seuil d'avertissement et le seuil critique
- **Seuil critique** : Valeur au-dessus du seuil critique (ou en dessous pour les KPIs inversÃ©s)

## Ajustement des seuils

Les seuils d'alerte sont rÃ©guliÃ¨rement revus et ajustÃ©s en fonction des Ã©lÃ©ments suivants :

1. Analyse des donnÃ©es historiques
2. Retours d'expÃ©rience sur les alertes dÃ©clenchÃ©es
3. Ã‰volution des exigences mÃ©tier
4. Changements dans l'infrastructure ou les applications

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
function Start-AlertThresholdsManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$HistoricalDataPath,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Static", "Statistical", "Hybrid")]
        [string]$Method = "Hybrid",
        
        [Parameter(Mandatory=$false)]
        [double]$StatisticalWeight = 0.5
    )
    
    Write-Log -Message "DÃ©but de la gestion des seuils d'alerte" -Level "Info"
    
    # 1. Charger les configurations des KPIs
    $Configurations = Import-KpiConfigurations -ConfigPath $ConfigPath
    
    if (-not $Configurations) {
        Write-Log -Message "Impossible de charger les configurations des KPIs" -Level "Error"
        return $false
    }
    
    # 2. Charger les donnÃ©es historiques
    $HistoricalData = Import-HistoricalData -HistoricalDataPath $HistoricalDataPath
    
    if (-not $HistoricalData) {
        Write-Log -Message "Impossible de charger les donnÃ©es historiques, utilisation des seuils statiques uniquement" -Level "Warning"
    }
    
    # 3. GÃ©nÃ©rer les seuils d'alerte
    $AlertThresholds = Get-AlertThresholds -Configurations $Configurations -HistoricalData $HistoricalData -Method $Method -StatisticalWeight $StatisticalWeight
    
    if (-not $AlertThresholds) {
        Write-Log -Message "Impossible de gÃ©nÃ©rer les seuils d'alerte" -Level "Error"
        return $false
    }
    
    # 4. Exporter les seuils d'alerte
    $ExportResult = Export-AlertThresholds -AlertThresholds $AlertThresholds -OutputPath $OutputPath
    
    if (-not $ExportResult) {
        Write-Log -Message "Impossible d'exporter les seuils d'alerte" -Level "Error"
        return $false
    }
    
    # 5. GÃ©nÃ©rer la documentation
    $DocumentationResult = Export-AlertThresholdsDocumentation -AlertThresholds $AlertThresholds -OutputPath $OutputPath
    
    if (-not $DocumentationResult) {
        Write-Log -Message "Impossible de gÃ©nÃ©rer la documentation des seuils d'alerte" -Level "Warning"
    }
    
    Write-Log -Message "Gestion des seuils d'alerte terminÃ©e avec succÃ¨s" -Level "Info"
    return $true
}

# ExÃ©cution du script
$Result = Start-AlertThresholdsManager -ConfigPath $ConfigPath -OutputPath $OutputPath -HistoricalDataPath $HistoricalDataPath

if ($Result) {
    Write-Log -Message "Gestion des seuils d'alerte rÃ©ussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Ã‰chec de la gestion des seuils d'alerte" -Level "Error"
    return 1
}

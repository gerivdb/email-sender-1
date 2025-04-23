<#
.SYNOPSIS
    Script de gestion des seuils d'alerte pour les KPIs.
.DESCRIPTION
    Permet de définir, valider et ajuster les seuils d'alerte pour les différents KPIs.
.PARAMETER ConfigPath
    Chemin vers le répertoire de configuration des KPIs.
.PARAMETER OutputPath
    Chemin où les seuils d'alerte seront sauvegardés.
.PARAMETER HistoricalDataPath
    Chemin vers les données historiques pour l'analyse statistique.
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
        
        # Vérifier si le répertoire existe
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Log -Message "Répertoire de configuration non trouvé: $ConfigPath" -Level "Error"
            return $null
        }
        
        # Charger tous les fichiers de configuration JSON
        $ConfigFiles = Get-ChildItem -Path $ConfigPath -Filter "*.json"
        
        foreach ($File in $ConfigFiles) {
            $ConfigType = $File.BaseName -replace "_kpis$", ""
            $ConfigContent = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            
            Write-Log -Message "Configuration chargée: $($File.Name) avec $($ConfigContent.kpis.Count) KPIs" -Level "Info"
            $Configurations[$ConfigType] = $ConfigContent
        }
        
        return $Configurations
    } catch {
        Write-Log -Message "Erreur lors du chargement des configurations: $_" -Level "Error"
        return $null
    }
}

# Fonction pour charger les données historiques des KPIs
function Import-HistoricalData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoricalDataPath
    )
    
    Write-Log -Message "Chargement des données historiques depuis $HistoricalDataPath" -Level "Info"
    
    try {
        $HistoricalData = @{}
        
        # Vérifier si le répertoire existe
        if (-not (Test-Path -Path $HistoricalDataPath)) {
            Write-Log -Message "Répertoire de données historiques non trouvé: $HistoricalDataPath" -Level "Error"
            return $null
        }
        
        # Charger tous les fichiers CSV
        $DataFiles = Get-ChildItem -Path $HistoricalDataPath -Filter "*.csv"
        
        foreach ($File in $DataFiles) {
            $DataType = $File.BaseName -replace "_kpis$", ""
            $DataContent = Import-Csv -Path $File.FullName
            
            Write-Log -Message "Données historiques chargées: $($File.Name) avec $($DataContent.Count) entrées" -Level "Info"
            $HistoricalData[$DataType] = $DataContent
        }
        
        return $HistoricalData
    } catch {
        Write-Log -Message "Erreur lors du chargement des données historiques: $_" -Level "Error"
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
        # Filtrer les données pour le KPI spécifié
        $KpiData = $Data | Where-Object { $_.Id -eq $KpiId }
        
        if (-not $KpiData -or $KpiData.Count -eq 0) {
            Write-Log -Message "Aucune donnée historique trouvée pour le KPI: $KpiId" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $KpiData | ForEach-Object { [double]$_.Value }
        
        # Trier les valeurs
        $SortedValues = $Values | Sort-Object
        
        # Calculer les percentiles
        $WarningIndex = [Math]::Ceiling($SortedValues.Count * ($WarningPercentile / 100)) - 1
        $CriticalIndex = [Math]::Ceiling($SortedValues.Count * ($CriticalPercentile / 100)) - 1
        
        # Ajuster les indices pour éviter les dépassements
        $WarningIndex = [Math]::Min($WarningIndex, $SortedValues.Count - 1)
        $CriticalIndex = [Math]::Min($CriticalIndex, $SortedValues.Count - 1)
        
        # Obtenir les valeurs des seuils
        $WarningThreshold = $SortedValues[$WarningIndex]
        $CriticalThreshold = $SortedValues[$CriticalIndex]
        
        # Inverser les seuils si nécessaire
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

# Fonction pour générer les seuils d'alerte
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
    
    Write-Log -Message "Génération des seuils d'alerte avec la méthode: $Method" -Level "Info"
    
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
                
                # Vérifier si des données historiques sont disponibles
                if ($HistoricalData.ContainsKey($ConfigType)) {
                    # Obtenir les seuils statistiques
                    $Inverse = $Kpi.PSObject.Properties.Name -contains "inverse" -and $Kpi.inverse
                    $StatisticalThresholds = Get-StatisticalThresholds -Data $HistoricalData[$ConfigType] -KpiId $Kpi.id -Inverse $Inverse
                    
                    # Combiner les seuils selon la méthode spécifiée
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
                
                # Ajouter les seuils au résultat
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
        Write-Log -Message "Erreur lors de la génération des seuils d'alerte: $_" -Level "Error"
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
        # Créer le répertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les seuils pour chaque type de KPI
        foreach ($ThresholdType in $AlertThresholds.Keys) {
            $OutputFile = Join-Path -Path $OutputPath -ChildPath "$($ThresholdType)_alert_thresholds.json"
            $AlertThresholds[$ThresholdType] | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
            
            Write-Log -Message "Seuils d'alerte exportés: $OutputFile" -Level "Info"
        }
        
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des seuils d'alerte: $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer la documentation des seuils d'alerte
function Export-AlertThresholdsDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$AlertThresholds,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "Génération de la documentation des seuils d'alerte" -Level "Info"
    
    try {
        # Créer le répertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Créer le fichier de documentation
        $DocumentationPath = Join-Path -Path $OutputPath -ChildPath "alert_thresholds_documentation.md"
        
        $Documentation = @"
# Documentation des seuils d'alerte

## Introduction

Ce document décrit les seuils d'alerte définis pour les différents indicateurs clés de performance (KPIs) du système. Ces seuils sont utilisés pour déclencher des alertes lorsque les valeurs des KPIs dépassent certains niveaux, permettant ainsi une détection précoce des problèmes potentiels.

## Méthodologie

Les seuils d'alerte ont été définis en utilisant une combinaison des approches suivantes :

1. **Seuils statiques** : Définis manuellement en fonction des bonnes pratiques et des exigences métier
2. **Seuils statistiques** : Calculés à partir des données historiques en utilisant des percentiles
3. **Seuils hybrides** : Combinaison pondérée des seuils statiques et statistiques

## Niveaux d'alerte

Deux niveaux d'alerte sont définis pour chaque KPI :

- **Avertissement (Warning)** : Indique une situation qui mérite attention mais n'est pas critique
- **Critique (Critical)** : Indique une situation qui nécessite une intervention immédiate

## Seuils par catégorie de KPI

"@
        
        # Ajouter les seuils pour chaque type de KPI
        foreach ($ThresholdType in $AlertThresholds.Keys) {
            $Documentation += @"

### KPIs $ThresholdType

| ID | Nom | Catégorie | Unité | Seuil d'avertissement | Seuil critique | Inverse |
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

## Interprétation

- **Seuil normal** : Valeur en dessous du seuil d'avertissement (ou au-dessus pour les KPIs inversés)
- **Seuil d'avertissement** : Valeur entre le seuil d'avertissement et le seuil critique
- **Seuil critique** : Valeur au-dessus du seuil critique (ou en dessous pour les KPIs inversés)

## Ajustement des seuils

Les seuils d'alerte sont régulièrement revus et ajustés en fonction des éléments suivants :

1. Analyse des données historiques
2. Retours d'expérience sur les alertes déclenchées
3. Évolution des exigences métier
4. Changements dans l'infrastructure ou les applications

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
    
    Write-Log -Message "Début de la gestion des seuils d'alerte" -Level "Info"
    
    # 1. Charger les configurations des KPIs
    $Configurations = Import-KpiConfigurations -ConfigPath $ConfigPath
    
    if (-not $Configurations) {
        Write-Log -Message "Impossible de charger les configurations des KPIs" -Level "Error"
        return $false
    }
    
    # 2. Charger les données historiques
    $HistoricalData = Import-HistoricalData -HistoricalDataPath $HistoricalDataPath
    
    if (-not $HistoricalData) {
        Write-Log -Message "Impossible de charger les données historiques, utilisation des seuils statiques uniquement" -Level "Warning"
    }
    
    # 3. Générer les seuils d'alerte
    $AlertThresholds = Get-AlertThresholds -Configurations $Configurations -HistoricalData $HistoricalData -Method $Method -StatisticalWeight $StatisticalWeight
    
    if (-not $AlertThresholds) {
        Write-Log -Message "Impossible de générer les seuils d'alerte" -Level "Error"
        return $false
    }
    
    # 4. Exporter les seuils d'alerte
    $ExportResult = Export-AlertThresholds -AlertThresholds $AlertThresholds -OutputPath $OutputPath
    
    if (-not $ExportResult) {
        Write-Log -Message "Impossible d'exporter les seuils d'alerte" -Level "Error"
        return $false
    }
    
    # 5. Générer la documentation
    $DocumentationResult = Export-AlertThresholdsDocumentation -AlertThresholds $AlertThresholds -OutputPath $OutputPath
    
    if (-not $DocumentationResult) {
        Write-Log -Message "Impossible de générer la documentation des seuils d'alerte" -Level "Warning"
    }
    
    Write-Log -Message "Gestion des seuils d'alerte terminée avec succès" -Level "Info"
    return $true
}

# Exécution du script
$Result = Start-AlertThresholdsManager -ConfigPath $ConfigPath -OutputPath $OutputPath -HistoricalDataPath $HistoricalDataPath

if ($Result) {
    Write-Log -Message "Gestion des seuils d'alerte réussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Échec de la gestion des seuils d'alerte" -Level "Error"
    return 1
}

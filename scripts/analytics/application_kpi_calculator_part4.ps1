<#
.SYNOPSIS
    Script de calcul des indicateurs clés de performance (KPIs) applicatifs - Partie 4.
.DESCRIPTION
    Calcule les KPIs applicatifs à partir des données de performance collectées.
    Cette partie contient la fonction principale et l'exécution.
#>

# Fonction pour calculer tous les KPIs applicatifs
function Get-ApplicationKpis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    Write-Log -Message "Calcul des KPIs applicatifs" -Level "Info"
    
    try {
        $Results = @()
        $KpiValues = @{}
        
        foreach ($Kpi in $Config.kpis) {
            Write-Log -Message "Calcul du KPI: $($Kpi.name)" -Level "Verbose"
            
            $KpiValue = $null
            
            # Calculer le KPI selon sa formule
            switch ($Kpi.formula) {
                "COMPOSITE" {
                    $KpiValue = Get-CompositeKpi -Data $Data -Sources $Kpi.sources -Weights $Kpi.weights -KpiValues $KpiValues
                }
                "PERCENTAGE" {
                    $KpiValue = Get-PercentageKpi -Data $Data -Sources $Kpi.sources
                }
                default {
                    $KpiValue = Get-SimpleKpi -Data $Data -Source $Kpi.source -Formula $Kpi.formula
                }
            }
            
            if ($null -ne $KpiValue) {
                # Stocker la valeur pour une utilisation ultérieure dans les KPIs composites
                $KpiValues[$Kpi.id] = $KpiValue
                
                # Inverser la logique des seuils si nécessaire
                $InverseSeuils = $Kpi.PSObject.Properties.Name -contains "inverse" -and $Kpi.inverse
                
                # Déterminer le statut en fonction des seuils
                $Status = "Normal"
                if ($Kpi.thresholds.warning) {
                    if ($InverseSeuils) {
                        if ($KpiValue -le $Kpi.thresholds.warning) {
                            $Status = "Warning"
                        }
                    } else {
                        if ($KpiValue -ge $Kpi.thresholds.warning) {
                            $Status = "Warning"
                        }
                    }
                }
                if ($Kpi.thresholds.critical) {
                    if ($InverseSeuils) {
                        if ($KpiValue -le $Kpi.thresholds.critical) {
                            $Status = "Critical"
                        }
                    } else {
                        if ($KpiValue -ge $Kpi.thresholds.critical) {
                            $Status = "Critical"
                        }
                    }
                }
                
                $Results += [PSCustomObject]@{
                    Id = $Kpi.id
                    Name = $Kpi.name
                    Description = $Kpi.description
                    Category = $Kpi.category
                    Value = $KpiValue
                    Unit = $Kpi.unit
                    Status = $Status
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            }
        }
        
        Write-Log -Message "Calcul terminé: $($Results.Count) KPIs calculés" -Level "Info"
        return $Results
    } catch {
        Write-Log -Message "Erreur lors du calcul des KPIs: $_" -Level "Error"
        return $null
    }
}

# Fonction principale
function Start-ApplicationKpiCalculation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )
    
    Write-Log -Message "Début du calcul des KPIs applicatifs" -Level "Info"
    
    # 1. Charger les données
    $ApplicationDataPath = Join-Path -Path $DataPath -ChildPath "application_metrics.csv"
    $ApplicationData = Import-ApplicationData -FilePath $ApplicationDataPath
    
    # 2. Charger la configuration des KPIs
    $KpiConfig = Import-KpiConfig -ConfigPath $ConfigPath
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 3. Calculer les KPIs
    if ($ApplicationData -and $ApplicationData.Count -gt 0 -and $KpiConfig) {
        $KpiResults = Get-ApplicationKpis -Data $ApplicationData -Config $KpiConfig
        
        if ($KpiResults -and $KpiResults.Count -gt 0) {
            # 4. Exporter les résultats
            $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "application_kpis.csv"
            $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "application_kpis.json"
            $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "application_kpis_dashboard.json"
            
            Export-KpiResults -Results $KpiResults -OutputPath $CsvOutputPath -Format "CSV"
            Export-KpiResults -Results $KpiResults -OutputPath $JsonOutputPath -Format "JSON"
            Export-KpiDashboard -Results $KpiResults -OutputPath $DashboardOutputPath
        } else {
            Write-Log -Message "Aucun KPI calculé" -Level "Warning"
        }
    } else {
        Write-Log -Message "Données ou configuration insuffisantes pour calculer les KPIs" -Level "Warning"
        
        # Créer des fichiers vides avec en-têtes
        $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "application_kpis.csv"
        "Id,Name,Description,Category,Value,Unit,Status,Timestamp" | Out-File -FilePath $CsvOutputPath -Encoding UTF8
        
        $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "application_kpis.json"
        "[]" | Out-File -FilePath $JsonOutputPath -Encoding UTF8
        
        $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "application_kpis_dashboard.json"
        @{
            title = "Tableau de bord des KPIs applicatifs"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            panels = @()
        } | ConvertTo-Json -Depth 10 | Out-File -FilePath $DashboardOutputPath -Encoding UTF8
    }
    
    Write-Log -Message "Calcul des KPIs applicatifs terminé" -Level "Info"
    
    return @{
        Success = $true
        KpiResults = $KpiResults
    }
}

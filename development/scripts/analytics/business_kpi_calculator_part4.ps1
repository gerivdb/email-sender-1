<#
.SYNOPSIS
    Script de calcul des indicateurs clÃ©s de performance (KPIs) mÃ©tier - Partie 4.
.DESCRIPTION
    Calcule les KPIs mÃ©tier Ã  partir des donnÃ©es collectÃ©es.
    Cette partie contient la fonction principale et l'exÃ©cution.
#>

# Fonction pour calculer tous les KPIs mÃ©tier
function Get-BusinessKpis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    Write-Log -Message "Calcul des KPIs mÃ©tier" -Level "Info"
    
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
                "RATIO" {
                    $KpiValue = Get-RatioKpi -Data $Data -Sources $Kpi.sources
                }
                "GROWTH" {
                    $KpiValue = Get-GrowthKpi -Data $Data -Sources $Kpi.sources
                }
                "CUSTOM" {
                    $KpiValue = Get-CustomKpi -Data $Data -Sources $Kpi.sources -CustomFormula $Kpi.customFormula
                }
                default {
                    $KpiValue = Get-SimpleKpi -Data $Data -Source $Kpi.source -Formula $Kpi.formula
                }
            }
            
            if ($null -ne $KpiValue) {
                # Stocker la valeur pour une utilisation ultÃ©rieure dans les KPIs composites
                $KpiValues[$Kpi.id] = $KpiValue
                
                # Inverser la logique des seuils si nÃ©cessaire
                $InverseSeuils = $Kpi.PSObject.Properties.Name -contains "inverse" -and $Kpi.inverse
                
                # DÃ©terminer le statut en fonction des seuils
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
        
        Write-Log -Message "Calcul terminÃ©: $($Results.Count) KPIs calculÃ©s" -Level "Info"
        return $Results
    } catch {
        Write-Log -Message "Erreur lors du calcul des KPIs: $_" -Level "Error"
        return $null
    }
}

# Fonction principale
function Start-BusinessKpiCalculation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )
    
    Write-Log -Message "DÃ©but du calcul des KPIs mÃ©tier" -Level "Info"
    
    # 1. Charger les donnÃ©es
    $BusinessDataPath = Join-Path -Path $DataPath -ChildPath "business_metrics.csv"
    $BusinessData = Import-BusinessData -FilePath $BusinessDataPath
    
    # 2. Charger la configuration des KPIs
    $KpiConfig = Import-KpiConfig -ConfigPath $ConfigPath
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 3. Calculer les KPIs
    if ($BusinessData -and $BusinessData.Count -gt 0 -and $KpiConfig) {
        $KpiResults = Get-BusinessKpis -Data $BusinessData -Config $KpiConfig
        
        if ($KpiResults -and $KpiResults.Count -gt 0) {
            # 4. Exporter les rÃ©sultats
            $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis.csv"
            $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis.json"
            $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis_dashboard.json"
            $ReportOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis_report.html"
            
            Export-KpiResults -Results $KpiResults -OutputPath $CsvOutputPath -Format "CSV"
            Export-KpiResults -Results $KpiResults -OutputPath $JsonOutputPath -Format "JSON"
            Export-KpiDashboard -Results $KpiResults -OutputPath $DashboardOutputPath
            Export-KpiReport -Results $KpiResults -OutputPath $ReportOutputPath -ReportTitle "Rapport des KPIs mÃ©tier" -Period "Dernier mois"
        } else {
            Write-Log -Message "Aucun KPI calculÃ©" -Level "Warning"
        }
    } else {
        Write-Log -Message "DonnÃ©es ou configuration insuffisantes pour calculer les KPIs" -Level "Warning"
        
        # CrÃ©er des fichiers vides avec en-tÃªtes
        $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis.csv"
        "Id,Name,Description,Category,Value,Unit,Status,Timestamp" | Out-File -FilePath $CsvOutputPath -Encoding UTF8
        
        $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis.json"
        "[]" | Out-File -FilePath $JsonOutputPath -Encoding UTF8
        
        $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis_dashboard.json"
        @{
            title = "Tableau de bord des KPIs mÃ©tier"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            panels = @()
        } | ConvertTo-Json -Depth 10 | Out-File -FilePath $DashboardOutputPath -Encoding UTF8
        
        $ReportOutputPath = Join-Path -Path $OutputPath -ChildPath "business_kpis_report.html"
        @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport des KPIs mÃ©tier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
    </style>
</head>
<body>
    <h1>Rapport des KPIs mÃ©tier</h1>
    <p>Aucune donnÃ©e disponible pour la pÃ©riode sÃ©lectionnÃ©e.</p>
</body>
</html>
"@ | Out-File -FilePath $ReportOutputPath -Encoding UTF8
    }
    
    Write-Log -Message "Calcul des KPIs mÃ©tier terminÃ©" -Level "Info"
    
    return @{
        Success = $true
        KpiResults = $KpiResults
    }
}

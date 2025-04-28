<#
.SYNOPSIS
    Script de calcul des indicateurs clÃ©s de performance (KPIs) systÃ¨me.
.DESCRIPTION
    Calcule les KPIs systÃ¨me Ã  partir des donnÃ©es de performance collectÃ©es.
.PARAMETER DataPath
    Chemin vers les donnÃ©es de performance.
.PARAMETER OutputPath
    Chemin oÃ¹ les rÃ©sultats seront sauvegardÃ©s.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration des KPIs.
.PARAMETER LogLevel
    Niveau de journalisation (Verbose, Info, Warning, Error).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath = "data/performance",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "data/kpis",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "projet/config/kpis/system_kpis.json",
    
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

# Fonction pour charger les donnÃ©es
function Import-PerformanceData {
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
            
            # CrÃ©er une configuration par dÃ©faut
            $DefaultConfig = @{
                kpis = @(
                    @{
                        id = "CPU_UTILIZATION"
                        name = "Utilisation CPU"
                        description = "Pourcentage moyen d'utilisation du CPU"
                        category = "SystÃ¨me"
                        unit = "%"
                        formula = "AVG"
                        source = "CPU"
                        thresholds = @{
                            warning = 70
                            critical = 90
                        }
                    },
                    @{
                        id = "MEMORY_UTILIZATION"
                        name = "Utilisation mÃ©moire"
                        description = "Pourcentage d'utilisation de la mÃ©moire physique"
                        category = "SystÃ¨me"
                        unit = "%"
                        formula = "AVG"
                        source = "Memory"
                        thresholds = @{
                            warning = 80
                            critical = 95
                        }
                    },
                    @{
                        id = "DISK_UTILIZATION"
                        name = "Utilisation disque"
                        description = "Pourcentage d'utilisation de l'espace disque"
                        category = "SystÃ¨me"
                        unit = "%"
                        formula = "AVG"
                        source = "Disk"
                        thresholds = @{
                            warning = 85
                            critical = 95
                        }
                    },
                    @{
                        id = "DISK_IO"
                        name = "ActivitÃ© disque"
                        description = "Nombre d'opÃ©rations d'entrÃ©e/sortie par seconde"
                        category = "SystÃ¨me"
                        unit = "IOPS"
                        formula = "AVG"
                        source = "DiskIO"
                        thresholds = @{
                            warning = 5000
                            critical = 10000
                        }
                    },
                    @{
                        id = "NETWORK_THROUGHPUT"
                        name = "DÃ©bit rÃ©seau"
                        description = "DÃ©bit rÃ©seau total (entrÃ©e + sortie)"
                        category = "SystÃ¨me"
                        unit = "MB/s"
                        formula = "AVG"
                        source = "Network"
                        thresholds = @{
                            warning = 50
                            critical = 80
                        }
                    },
                    @{
                        id = "SYSTEM_LOAD"
                        name = "Charge systÃ¨me"
                        description = "Indice de charge systÃ¨me composite (CPU, mÃ©moire, disque)"
                        category = "SystÃ¨me"
                        unit = "Score"
                        formula = "COMPOSITE"
                        sources = @("CPU", "Memory", "Disk")
                        weights = @(0.4, 0.3, 0.3)
                        thresholds = @{
                            warning = 0.7
                            critical = 0.9
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

# Fonction pour calculer un KPI simple
function Get-SimpleKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$Source,
        
        [Parameter(Mandatory=$true)]
        [string]$Formula,
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Path"
    )
    
    try {
        # Filtrer les donnÃ©es pour la source spÃ©cifiÃ©e
        $SourceData = $Data | Where-Object { $_.$SourceColumn -like "*$Source*" }
        
        if (-not $SourceData -or $SourceData.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e trouvÃ©e pour la source: $Source" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $SourceData | ForEach-Object { [double]$_.$ValueColumn }
        
        # Calculer le KPI selon la formule spÃ©cifiÃ©e
        switch ($Formula) {
            "AVG" {
                $Result = ($Values | Measure-Object -Average).Average
            }
            "MAX" {
                $Result = ($Values | Measure-Object -Maximum).Maximum
            }
            "MIN" {
                $Result = ($Values | Measure-Object -Minimum).Minimum
            }
            "SUM" {
                $Result = ($Values | Measure-Object -Sum).Sum
            }
            "MEDIAN" {
                $SortedValues = $Values | Sort-Object
                $Count = $SortedValues.Count
                if ($Count -eq 0) {
                    $Result = $null
                } elseif ($Count % 2 -eq 0) {
                    $Result = ($SortedValues[$Count/2 - 1] + $SortedValues[$Count/2]) / 2
                } else {
                    $Result = $SortedValues[[Math]::Floor($Count/2)]
                }
            }
            "P95" {
                $SortedValues = $Values | Sort-Object
                $Index = [Math]::Ceiling($SortedValues.Count * 0.95) - 1
                $Result = $SortedValues[$Index]
            }
            "P99" {
                $SortedValues = $Values | Sort-Object
                $Index = [Math]::Ceiling($SortedValues.Count * 0.99) - 1
                $Result = $SortedValues[$Index]
            }
            default {
                Write-Log -Message "Formule non prise en charge: $Formula" -Level "Error"
                $Result = $null
            }
        }
        
        return $Result
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI simple: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer un KPI composite
function Get-CompositeKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory=$true)]
        [double[]]$Weights,
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Path"
    )
    
    try {
        if ($Sources.Count -ne $Weights.Count) {
            Write-Log -Message "Le nombre de sources et de poids doit Ãªtre identique" -Level "Error"
            return $null
        }
        
        $WeightSum = ($Weights | Measure-Object -Sum).Sum
        if ([Math]::Abs($WeightSum - 1) -gt 0.001) {
            Write-Log -Message "La somme des poids doit Ãªtre Ã©gale Ã  1" -Level "Warning"
            # Normaliser les poids
            $Weights = $Weights | ForEach-Object { $_ / $WeightSum }
        }
        
        $CompositeValue = 0
        
        for ($i = 0; $i -lt $Sources.Count; $i++) {
            $Source = $Sources[$i]
            $Weight = $Weights[$i]
            
            # Calculer la valeur moyenne pour cette source
            $SourceValue = Get-SimpleKpi -Data $Data -Source $Source -Formula "AVG" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
            
            if ($null -ne $SourceValue) {
                # Normaliser la valeur (supposer que les valeurs sont entre 0 et 100)
                $NormalizedValue = $SourceValue / 100
                $CompositeValue += $NormalizedValue * $Weight
            }
        }
        
        return $CompositeValue
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI composite: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer tous les KPIs
function Get-SystemKpis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    Write-Log -Message "Calcul des KPIs systÃ¨me" -Level "Info"
    
    try {
        $Results = @()
        
        foreach ($Kpi in $Config.kpis) {
            Write-Log -Message "Calcul du KPI: $($Kpi.name)" -Level "Verbose"
            
            $KpiValue = $null
            
            if ($Kpi.formula -eq "COMPOSITE") {
                $KpiValue = Get-CompositeKpi -Data $Data -Sources $Kpi.sources -Weights $Kpi.weights
            } else {
                $KpiValue = Get-SimpleKpi -Data $Data -Source $Kpi.source -Formula $Kpi.formula
            }
            
            if ($null -ne $KpiValue) {
                # DÃ©terminer le statut en fonction des seuils
                $Status = "Normal"
                if ($Kpi.thresholds.warning -and $KpiValue -ge $Kpi.thresholds.warning) {
                    $Status = "Warning"
                }
                if ($Kpi.thresholds.critical -and $KpiValue -ge $Kpi.thresholds.critical) {
                    $Status = "Critical"
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

# Fonction pour exporter les rÃ©sultats
function Export-KpiResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Format = "CSV" # CSV, JSON
    )
    
    Write-Log -Message "Exportation des rÃ©sultats au format $Format vers $OutputPath" -Level "Info"
    
    try {
        # VÃ©rifier si les rÃ©sultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun rÃ©sultat Ã  exporter" -Level "Warning"
            return $false
        }
        
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les rÃ©sultats selon le format spÃ©cifiÃ©
        switch ($Format) {
            "CSV" {
                $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
            "JSON" {
                $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            default {
                Write-Log -Message "Format d'exportation non pris en charge: $Format" -Level "Error"
                return $false
            }
        }
        
        Write-Log -Message "Exportation rÃ©ussie vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des rÃ©sultats: $_" -Level "Error"
        return $false
    }
}

# Fonction pour gÃ©nÃ©rer un tableau de bord JSON
function Export-KpiDashboard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "GÃ©nÃ©ration du tableau de bord vers $OutputPath" -Level "Info"
    
    try {
        # VÃ©rifier si les rÃ©sultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun rÃ©sultat pour gÃ©nÃ©rer le tableau de bord" -Level "Warning"
            return $false
        }
        
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er la structure du tableau de bord
        $Dashboard = @{
            title = "Tableau de bord des KPIs systÃ¨me"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            panels = @()
        }
        
        # Ajouter un panneau pour chaque KPI
        foreach ($Kpi in $Results) {
            $Panel = @{
                id = $Kpi.Id
                title = $Kpi.Name
                description = $Kpi.Description
                type = "gauge"
                value = $Kpi.Value
                unit = $Kpi.Unit
                status = $Kpi.Status
                thresholds = @{
                    warning = 70
                    critical = 90
                }
            }
            
            $Dashboard.panels += $Panel
        }
        
        # Exporter le tableau de bord au format JSON
        $Dashboard | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Tableau de bord gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration du tableau de bord: $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-SystemKpiCalculation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )
    
    Write-Log -Message "DÃ©but du calcul des KPIs systÃ¨me" -Level "Info"
    
    # 1. Charger les donnÃ©es
    $PerformanceDataPath = Join-Path -Path $DataPath -ChildPath "prepared_performance_data.csv"
    $PerformanceData = Import-PerformanceData -FilePath $PerformanceDataPath
    
    # 2. Charger la configuration des KPIs
    $KpiConfig = Import-KpiConfig -ConfigPath $ConfigPath
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 3. Calculer les KPIs
    if ($PerformanceData -and $PerformanceData.Count -gt 0 -and $KpiConfig) {
        $KpiResults = Get-SystemKpis -Data $PerformanceData -Config $KpiConfig
        
        if ($KpiResults -and $KpiResults.Count -gt 0) {
            # 4. Exporter les rÃ©sultats
            $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.csv"
            $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.json"
            $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis_dashboard.json"
            
            Export-KpiResults -Results $KpiResults -OutputPath $CsvOutputPath -Format "CSV"
            Export-KpiResults -Results $KpiResults -OutputPath $JsonOutputPath -Format "JSON"
            Export-KpiDashboard -Results $KpiResults -OutputPath $DashboardOutputPath
        } else {
            Write-Log -Message "Aucun KPI calculÃ©" -Level "Warning"
        }
    } else {
        Write-Log -Message "DonnÃ©es ou configuration insuffisantes pour calculer les KPIs" -Level "Warning"
        
        # CrÃ©er des fichiers vides avec en-tÃªtes
        $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.csv"
        "Id,Name,Description,Category,Value,Unit,Status,Timestamp" | Out-File -FilePath $CsvOutputPath -Encoding UTF8
        
        $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.json"
        "[]" | Out-File -FilePath $JsonOutputPath -Encoding UTF8
        
        $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis_dashboard.json"
        @{
            title = "Tableau de bord des KPIs systÃ¨me"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            panels = @()
        } | ConvertTo-Json -Depth 10 | Out-File -FilePath $DashboardOutputPath -Encoding UTF8
    }
    
    Write-Log -Message "Calcul des KPIs systÃ¨me terminÃ©" -Level "Info"
    
    return @{
        Success = $true
        KpiResults = $KpiResults
    }
}

# ExÃ©cution du script
$Result = Start-SystemKpiCalculation -DataPath $DataPath -OutputPath $OutputPath -ConfigPath $ConfigPath

if ($Result.Success) {
    Write-Log -Message "Calcul des KPIs systÃ¨me rÃ©ussi" -Level "Info"
    return 0
} else {
    Write-Log -Message "Ã‰chec du calcul des KPIs systÃ¨me" -Level "Error"
    return 1
}

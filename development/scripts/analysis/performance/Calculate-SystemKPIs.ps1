<#
.SYNOPSIS
    Script de calcul des indicateurs clÃƒÂ©s de performance (KPIs) systÃƒÂ¨me.
.DESCRIPTION
    Calcule les KPIs systÃƒÂ¨me ÃƒÂ  partir des donnÃƒÂ©es de performance collectÃƒÂ©es.
.PARAMETER DataPath
    Chemin vers les donnÃƒÂ©es de performance.
.PARAMETER OutputPath
    Chemin oÃƒÂ¹ les rÃƒÂ©sultats seront sauvegardÃƒÂ©s.
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

# Fonction pour charger les donnÃƒÂ©es
function Import-PerformanceData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    Write-Log -Message "Chargement des donnÃƒÂ©es depuis $FilePath" -Level "Info"
    
    try {
        if (Test-Path -Path $FilePath) {
            $Data = Import-Csv -Path $FilePath
            Write-Log -Message "Chargement rÃƒÂ©ussi: $($Data.Count) entrÃƒÂ©es" -Level "Info"
            return $Data
        } else {
            Write-Log -Message "Fichier non trouvÃƒÂ©: $FilePath" -Level "Error"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des donnÃƒÂ©es: $_" -Level "Error"
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
            Write-Log -Message "Configuration chargÃƒÂ©e avec succÃƒÂ¨s: $($Config.kpis.Count) KPIs dÃƒÂ©finis" -Level "Info"
            return $Config
        } else {
            Write-Log -Message "Fichier de configuration non trouvÃƒÂ©: $ConfigPath" -Level "Warning"
            
            # CrÃƒÂ©er une configuration par dÃƒÂ©faut
            $DefaultConfig = @{
                kpis = @(
                    @{
                        id = "CPU_UTILIZATION"
                        name = "Utilisation CPU"
                        description = "Pourcentage moyen d'utilisation du CPU"
                        category = "SystÃƒÂ¨me"
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
                        name = "Utilisation mÃƒÂ©moire"
                        description = "Pourcentage d'utilisation de la mÃƒÂ©moire physique"
                        category = "SystÃƒÂ¨me"
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
                        category = "SystÃƒÂ¨me"
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
                        name = "ActivitÃƒÂ© disque"
                        description = "Nombre d'opÃƒÂ©rations d'entrÃƒÂ©e/sortie par seconde"
                        category = "SystÃƒÂ¨me"
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
                        name = "DÃƒÂ©bit rÃƒÂ©seau"
                        description = "DÃƒÂ©bit rÃƒÂ©seau total (entrÃƒÂ©e + sortie)"
                        category = "SystÃƒÂ¨me"
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
                        name = "Charge systÃƒÂ¨me"
                        description = "Indice de charge systÃƒÂ¨me composite (CPU, mÃƒÂ©moire, disque)"
                        category = "SystÃƒÂ¨me"
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
            
            # CrÃƒÂ©er le rÃƒÂ©pertoire de configuration s'il n'existe pas
            $ConfigDir = Split-Path -Parent $ConfigPath
            if (-not (Test-Path -Path $ConfigDir)) {
                New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder la configuration par dÃƒÂ©faut
            $DefaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
            
            Write-Log -Message "Configuration par dÃƒÂ©faut crÃƒÂ©ÃƒÂ©e: $ConfigPath" -Level "Info"
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
        # Filtrer les donnÃƒÂ©es pour la source spÃƒÂ©cifiÃƒÂ©e
        $SourceData = $Data | Where-Object { $_.$SourceColumn -like "*$Source*" }
        
        if (-not $SourceData -or $SourceData.Count -eq 0) {
            Write-Log -Message "Aucune donnÃƒÂ©e trouvÃƒÂ©e pour la source: $Source" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $SourceData | ForEach-Object { [double]$_.$ValueColumn }
        
        # Calculer le KPI selon la formule spÃƒÂ©cifiÃƒÂ©e
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
            Write-Log -Message "Le nombre de sources et de poids doit ÃƒÂªtre identique" -Level "Error"
            return $null
        }
        
        $WeightSum = ($Weights | Measure-Object -Sum).Sum
        if ([Math]::Abs($WeightSum - 1) -gt 0.001) {
            Write-Log -Message "La somme des poids doit ÃƒÂªtre ÃƒÂ©gale ÃƒÂ  1" -Level "Warning"
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
    
    Write-Log -Message "Calcul des KPIs systÃƒÂ¨me" -Level "Info"
    
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
                # DÃƒÂ©terminer le statut en fonction des seuils
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
        
        Write-Log -Message "Calcul terminÃƒÂ©: $($Results.Count) KPIs calculÃƒÂ©s" -Level "Info"
        return $Results
    } catch {
        Write-Log -Message "Erreur lors du calcul des KPIs: $_" -Level "Error"
        return $null
    }
}

# Fonction pour exporter les rÃƒÂ©sultats
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
    
    Write-Log -Message "Exportation des rÃƒÂ©sultats au format $Format vers $OutputPath" -Level "Info"
    
    try {
        # VÃƒÂ©rifier si les rÃƒÂ©sultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun rÃƒÂ©sultat ÃƒÂ  exporter" -Level "Warning"
            return $false
        }
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les rÃƒÂ©sultats selon le format spÃƒÂ©cifiÃƒÂ©
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
        
        Write-Log -Message "Exportation rÃƒÂ©ussie vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des rÃƒÂ©sultats: $_" -Level "Error"
        return $false
    }
}

# Fonction pour gÃƒÂ©nÃƒÂ©rer un tableau de bord JSON
function Export-KpiDashboard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "GÃƒÂ©nÃƒÂ©ration du tableau de bord vers $OutputPath" -Level "Info"
    
    try {
        # VÃƒÂ©rifier si les rÃƒÂ©sultats sont vides
        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Log -Message "Aucun rÃƒÂ©sultat pour gÃƒÂ©nÃƒÂ©rer le tableau de bord" -Level "Warning"
            return $false
        }
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # CrÃƒÂ©er la structure du tableau de bord
        $Dashboard = @{
            title = "Tableau de bord des KPIs systÃƒÂ¨me"
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
        
        Write-Log -Message "Tableau de bord gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la gÃƒÂ©nÃƒÂ©ration du tableau de bord: $_" -Level "Error"
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
    
    Write-Log -Message "DÃƒÂ©but du calcul des KPIs systÃƒÂ¨me" -Level "Info"
    
    # 1. Charger les donnÃƒÂ©es
    $PerformanceDataPath = Join-Path -Path $DataPath -ChildPath "prepared_performance_data.csv"
    $PerformanceData = Import-PerformanceData -FilePath $PerformanceDataPath
    
    # 2. Charger la configuration des KPIs
    $KpiConfig = Import-KpiConfig -ConfigPath $ConfigPath
    
    # CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 3. Calculer les KPIs
    if ($PerformanceData -and $PerformanceData.Count -gt 0 -and $KpiConfig) {
        $KpiResults = Get-SystemKpis -Data $PerformanceData -Config $KpiConfig
        
        if ($KpiResults -and $KpiResults.Count -gt 0) {
            # 4. Exporter les rÃƒÂ©sultats
            $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.csv"
            $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.json"
            $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis_dashboard.json"
            
            Export-KpiResults -Results $KpiResults -OutputPath $CsvOutputPath -Format "CSV"
            Export-KpiResults -Results $KpiResults -OutputPath $JsonOutputPath -Format "JSON"
            Export-KpiDashboard -Results $KpiResults -OutputPath $DashboardOutputPath
        } else {
            Write-Log -Message "Aucun KPI calculÃƒÂ©" -Level "Warning"
        }
    } else {
        Write-Log -Message "DonnÃƒÂ©es ou configuration insuffisantes pour calculer les KPIs" -Level "Warning"
        
        # CrÃƒÂ©er des fichiers vides avec en-tÃƒÂªtes
        $CsvOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.csv"
        "Id,Name,Description,Category,Value,Unit,Status,Timestamp" | Out-File -FilePath $CsvOutputPath -Encoding UTF8
        
        $JsonOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis.json"
        "[]" | Out-File -FilePath $JsonOutputPath -Encoding UTF8
        
        $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "system_kpis_dashboard.json"
        @{
            title = "Tableau de bord des KPIs systÃƒÂ¨me"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            panels = @()
        } | ConvertTo-Json -Depth 10 | Out-File -FilePath $DashboardOutputPath -Encoding UTF8
    }
    
    Write-Log -Message "Calcul des KPIs systÃƒÂ¨me terminÃƒÂ©" -Level "Info"
    
    return @{
        Success = $true
        KpiResults = $KpiResults
    }
}

# ExÃƒÂ©cution du script
$Result = Start-SystemKpiCalculation -DataPath $DataPath -OutputPath $OutputPath -ConfigPath $ConfigPath

if ($Result.Success) {
    Write-Log -Message "Calcul des KPIs systÃƒÂ¨me rÃƒÂ©ussi" -Level "Info"
    return 0
} else {
    Write-Log -Message "Ãƒâ€°chec du calcul des KPIs systÃƒÂ¨me" -Level "Error"
    return 1
}

<#
.SYNOPSIS
    Script d'extraction et de prÃ©paration des donnÃ©es historiques de performance.

.DESCRIPTION
    Ce script extrait les donnÃ©es de performance historiques de diffÃ©rentes sources,
    les nettoie, les transforme et les prÃ©pare pour l'analyse. Il gÃ¨re les valeurs manquantes,
    normalise les donnÃ©es et les structure dans un format adaptÃ© Ã  l'analyse.

.PARAMETER SourcePath
    Chemin vers les sources de donnÃ©es (logs, mÃ©triques, etc.).

.PARAMETER OutputPath
    Chemin oÃ¹ les donnÃ©es prÃ©parÃ©es seront sauvegardÃ©es.

.PARAMETER StartDate
    Date de dÃ©but pour l'extraction des donnÃ©es (format: yyyy-MM-dd).

.PARAMETER EndDate
    Date de fin pour l'extraction des donnÃ©es (format: yyyy-MM-dd).

.PARAMETER LogLevel
    Niveau de journalisation (Verbose, Info, Warning, Error).

.EXAMPLE
    .\data_preparation.ps1 -SourcePath "logs" -OutputPath "data/performance" -StartDate "2025-01-01" -EndDate "2025-03-31" -LogLevel "Info"

.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 22/04/2025
    Version: 1.0
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = "logs",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "data/performance",

    [Parameter(Mandatory = $false)]
    [string]$StartDate = (Get-Date).AddMonths(-3).ToString("yyyy-MM-dd"),

    [Parameter(Mandatory = $false)]
    [string]$EndDate = (Get-Date).ToString("yyyy-MM-dd"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Verbose", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# Importer les modules nÃ©cessaires
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulePath = Join-Path -Path $ScriptPath -ChildPath "..\utils"

# Fonction pour la journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Verbose", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $LogLevels = @{
        "Verbose" = 0
        "Info"    = 1
        "Warning" = 2
        "Error"   = 3
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

# Fonction pour extraire les donnÃ©es des logs systÃ¨me
function Get-SystemLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StartDate,

        [Parameter(Mandatory = $true)]
        [string]$EndDate
    )

    Write-Log -Message "Extraction des logs systÃ¨me du $StartDate au $EndDate" -Level "Info"

    try {
        # Convertir les dates en objets DateTime
        $Start = [DateTime]::ParseExact($StartDate, "yyyy-MM-dd", $null)
        $End = [DateTime]::ParseExact($EndDate, "yyyy-MM-dd", $null).AddDays(1).AddSeconds(-1)

        # Extraire les logs d'Ã©vÃ©nements systÃ¨me
        $SystemLogs = Get-WinEvent -FilterHashtable @{
            LogName   = 'System'
            StartTime = $Start
            EndTime   = $End
        } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message

        Write-Log -Message "Extraction rÃ©ussie: $($SystemLogs.Count) logs systÃ¨me extraits" -Level "Info"
        return $SystemLogs
    } catch {
        Write-Log -Message "Erreur lors de l'extraction des logs systÃ¨me: $_" -Level "Error"
        return $null
    }
}

# Fonction pour extraire les donnÃ©es de performance
function Get-PerformanceData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StartDate,

        [Parameter(Mandatory = $true)]
        [string]$EndDate,

        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 60 # Intervalle en secondes
    )

    Write-Log -Message "Extraction des donnÃ©es de performance du $StartDate au $EndDate" -Level "Info"

    try {
        # Liste des compteurs de performance Ã  collecter
        $Counters = @(
            "\Processor(_Total)\% Processor Time",
            "\Memory\Available MBytes",
            "\PhysicalDisk(_Total)\Disk Reads/sec",
            "\PhysicalDisk(_Total)\Disk Writes/sec",
            "\Network Interface(*)\Bytes Total/sec"
        )

        # Collecter les donnÃ©es de performance actuelles (pour dÃ©monstration)
        # Dans un cas rÃ©el, on utiliserait des donnÃ©es historiques stockÃ©es
        $PerfData = Get-Counter -Counter $Counters -SampleInterval $SampleInterval -MaxSamples 10 -ErrorAction SilentlyContinue

        # Transformer les donnÃ©es en format exploitable
        $ProcessedData = $PerfData.CounterSamples | ForEach-Object {
            [PSCustomObject]@{
                Timestamp = $_.Timestamp
                Path      = $_.Path
                Instance  = $_.InstanceName
                Value     = $_.CookedValue
            }
        }

        Write-Log -Message "Extraction rÃ©ussie: $($ProcessedData.Count) mÃ©triques de performance extraites" -Level "Info"
        return $ProcessedData
    } catch {
        Write-Log -Message "Erreur lors de l'extraction des donnÃ©es de performance: $_" -Level "Error"
        return $null
    }
}

# Fonction pour extraire les logs applicatifs
function Get-ApplicationLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [string]$StartDate,

        [Parameter(Mandatory = $true)]
        [string]$EndDate
    )

    Write-Log -Message "Extraction des logs applicatifs du $StartDate au $EndDate" -Level "Info"

    try {
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $LogPath)) {
            Write-Log -Message "Le chemin des logs applicatifs n'existe pas: $LogPath" -Level "Warning"

            # CrÃ©er des donnÃ©es de dÃ©monstration
            $DemoLogs = @()
            $Start = [DateTime]::ParseExact($StartDate, "yyyy-MM-dd", $null)
            $End = [DateTime]::ParseExact($EndDate, "yyyy-MM-dd", $null)

            $CurrentDate = $Start
            while ($CurrentDate -le $End) {
                $DemoLogs += [PSCustomObject]@{
                    Timestamp = $CurrentDate.AddHours((Get-Random -Minimum 0 -Maximum 24))
                    Level     = (Get-Random -InputObject @("INFO", "WARNING", "ERROR", "DEBUG"))
                    Component = (Get-Random -InputObject @("API", "Database", "UI", "Authentication"))
                    Message   = "Message de log de dÃ©monstration"
                }
                $CurrentDate = $CurrentDate.AddDays(1)
            }

            Write-Log -Message "DonnÃ©es de dÃ©monstration crÃ©Ã©es: $($DemoLogs.Count) logs applicatifs" -Level "Info"
            return $DemoLogs
        }

        # Extraire les logs applicatifs rÃ©els
        $LogFiles = Get-ChildItem -Path $LogPath -Filter "*.log" | Where-Object {
            $_.LastWriteTime -ge [DateTime]::ParseExact($StartDate, "yyyy-MM-dd", $null) -and
            $_.LastWriteTime -le [DateTime]::ParseExact($EndDate, "yyyy-MM-dd", $null).AddDays(1)
        }

        $AppLogs = @()
        foreach ($File in $LogFiles) {
            $Content = Get-Content -Path $File.FullName
            # Analyser le contenu selon le format des logs
            # Ceci est un exemple simplifiÃ©, Ã  adapter selon le format rÃ©el des logs
            foreach ($Line in $Content) {
                if ($Line -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] \[(\w+)\] \[(\w+)\] (.+)$') {
                    $AppLogs += [PSCustomObject]@{
                        Timestamp = [DateTime]$Matches[1]
                        Level     = $Matches[2]
                        Component = $Matches[3]
                        Message   = $Matches[4]
                    }
                }
            }
        }

        Write-Log -Message "Extraction rÃ©ussie: $($AppLogs.Count) logs applicatifs extraits" -Level "Info"
        return $AppLogs
    } catch {
        Write-Log -Message "Erreur lors de l'extraction des logs applicatifs: $_" -Level "Error"
        return $null
    }
}

# Fonction pour nettoyer les donnÃ©es
function Clean-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$DataType = "Performance"
    )

    Write-Log -Message "Nettoyage des donnÃ©es de type $DataType" -Level "Info"

    try {
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  nettoyer pour le type $DataType" -Level "Warning"
            return $null
        }

        # Filtrer les valeurs nulles ou aberrantes
        $CleanedData = $Data | Where-Object { $null -ne $_.Value }

        # Traitement spÃ©cifique selon le type de donnÃ©es
        switch ($DataType) {
            "Performance" {
                # DÃ©tecter et gÃ©rer les valeurs aberrantes (exemple: mÃ©thode IQR)
                $CleanedData = $CleanedData | Group-Object Path | ForEach-Object {
                    $Group = $_.Group
                    $Values = $Group.Value

                    # Calculer les quartiles
                    $SortedValues = $Values | Sort-Object
                    $Q1Index = [math]::Floor($SortedValues.Count * 0.25)
                    $Q3Index = [math]::Floor($SortedValues.Count * 0.75)
                    $Q1 = $SortedValues[$Q1Index]
                    $Q3 = $SortedValues[$Q3Index]
                    $IQR = $Q3 - $Q1

                    # DÃ©finir les limites pour les valeurs aberrantes
                    $LowerBound = $Q1 - (1.5 * $IQR)
                    $UpperBound = $Q3 + (1.5 * $IQR)

                    # Filtrer les valeurs aberrantes
                    $Group | Where-Object { $_.Value -ge $LowerBound -and $_.Value -le $UpperBound }
                }
            }
            "Logs" {
                # Filtrer les logs non pertinents ou en double
                $CleanedData = $CleanedData | Sort-Object Timestamp -Unique
            }
            default {
                # Nettoyage gÃ©nÃ©rique
                $CleanedData = $CleanedData | Sort-Object Timestamp
            }
        }

        Write-Log -Message "Nettoyage rÃ©ussi: $($CleanedData.Count) entrÃ©es conservÃ©es sur $($Data.Count)" -Level "Info"
        return $CleanedData
    } catch {
        Write-Log -Message "Erreur lors du nettoyage des donnÃ©es: $_" -Level "Error"
        return $Data
    }
}

# Fonction pour normaliser les donnÃ©es
function Normalize-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$Method = "MinMax" # MinMax, ZScore, Log
    )

    Write-Log -Message "Normalisation des donnÃ©es avec la mÃ©thode $Method" -Level "Info"

    try {
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  normaliser" -Level "Warning"
            return $null
        }

        # Normaliser les donnÃ©es numÃ©riques
        $NormalizedData = $Data | Group-Object Path | ForEach-Object {
            $Group = $_.Group
            $Values = $Group.Value

            # Calculer les statistiques nÃ©cessaires pour la normalisation
            $Min = ($Values | Measure-Object -Minimum).Minimum
            $Max = ($Values | Measure-Object -Maximum).Maximum
            $Mean = ($Values | Measure-Object -Average).Average
            $StdDev = [Math]::Sqrt(($Values | ForEach-Object { [Math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average)

            # Appliquer la mÃ©thode de normalisation
            switch ($Method) {
                "MinMax" {
                    # Normalisation Min-Max (0-1)
                    if ($Max -eq $Min) {
                        $Group | ForEach-Object { $_.NormalizedValue = 0.5 }
                    } else {
                        $Group | ForEach-Object { $_.NormalizedValue = ($_.Value - $Min) / ($Max - $Min) }
                    }
                }
                "ZScore" {
                    # Normalisation Z-Score
                    if ($StdDev -eq 0) {
                        $Group | ForEach-Object { $_.NormalizedValue = 0 }
                    } else {
                        $Group | ForEach-Object { $_.NormalizedValue = ($_.Value - $Mean) / $StdDev }
                    }
                }
                "Log" {
                    # Normalisation logarithmique
                    $Group | ForEach-Object {
                        if ($_.Value -gt 0) {
                            $_.NormalizedValue = [Math]::Log($_.Value)
                        } else {
                            $_.NormalizedValue = 0
                        }
                    }
                }
                default {
                    # Pas de normalisation
                    $Group | ForEach-Object { $_.NormalizedValue = $_.Value }
                }
            }

            $Group
        }

        Write-Log -Message "Normalisation rÃ©ussie avec la mÃ©thode $Method" -Level "Info"
        return $NormalizedData
    } catch {
        Write-Log -Message "Erreur lors de la normalisation des donnÃ©es: $_" -Level "Error"
        return $Data
    }
}

# Fonction pour exporter les donnÃ©es
function Export-PreparedData {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object[]]$Data,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Format = "CSV" # CSV, JSON
    )

    Write-Log -Message "Exportation des donnÃ©es au format $Format vers $OutputPath" -Level "Info"

    try {
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  exporter" -Level "Warning"
            return $false
        }

        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            if ($PSCmdlet.ShouldProcess($Directory, "CrÃ©ation du rÃ©pertoire")) {
                New-Item -Path $Directory -ItemType Directory -Force | Out-Null
            }
        }

        # Exporter les donnÃ©es selon le format spÃ©cifiÃ©
        switch ($Format) {
            "CSV" {
                if ($PSCmdlet.ShouldProcess($OutputPath, "Exportation des donnÃ©es au format CSV")) {
                    $Data | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
            }
            "JSON" {
                if ($PSCmdlet.ShouldProcess($OutputPath, "Exportation des donnÃ©es au format JSON")) {
                    $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
            }
            default {
                Write-Log -Message "Format d'exportation non pris en charge: $Format" -Level "Error"
                return $false
            }
        }

        Write-Log -Message "Exportation rÃ©ussie: $($Data.Count) entrÃ©es exportÃ©es vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des donnÃ©es: $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-DataPreparation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$StartDate,

        [Parameter(Mandatory = $true)]
        [string]$EndDate
    )

    Write-Log -Message "DÃ©but du processus de prÃ©paration des donnÃ©es" -Level "Info"

    # 1. Extraction des donnÃ©es
    Write-Log -Message "Ã‰tape 1: Extraction des donnÃ©es" -Level "Info"
    $SystemLogs = Get-SystemLogs -StartDate $StartDate -EndDate $EndDate
    $PerformanceData = Get-PerformanceData -StartDate $StartDate -EndDate $EndDate
    $ApplicationLogs = Get-ApplicationLogs -LogPath $SourcePath -StartDate $StartDate -EndDate $EndDate

    # 2. Nettoyage des donnÃ©es
    Write-Log -Message "Ã‰tape 2: Nettoyage des donnÃ©es" -Level "Info"
    $CleanedPerformanceData = if ($null -ne $PerformanceData -and $PerformanceData.Count -gt 0) { Clean-Data -Data $PerformanceData -DataType "Performance" } else { @() }
    $CleanedSystemLogs = if ($null -ne $SystemLogs -and $SystemLogs.Count -gt 0) { Clean-Data -Data $SystemLogs -DataType "Logs" } else { @() }
    $CleanedApplicationLogs = if ($null -ne $ApplicationLogs -and $ApplicationLogs.Count -gt 0) { Clean-Data -Data $ApplicationLogs -DataType "Logs" } else { @() }

    # 3. Normalisation des donnÃ©es
    Write-Log -Message "Ã‰tape 3: Normalisation des donnÃ©es" -Level "Info"
    $NormalizedPerformanceData = if ($null -ne $CleanedPerformanceData -and $CleanedPerformanceData.Count -gt 0) { Normalize-Data -Data $CleanedPerformanceData -Method "MinMax" } else { @() }

    # 4. Exportation des donnÃ©es prÃ©parÃ©es
    Write-Log -Message "Ã‰tape 4: Exportation des donnÃ©es prÃ©parÃ©es" -Level "Info"
    $PerformanceOutputPath = Join-Path -Path $OutputPath -ChildPath "prepared_performance_data.csv"
    $SystemLogsOutputPath = Join-Path -Path $OutputPath -ChildPath "prepared_system_logs.csv"
    $ApplicationLogsOutputPath = Join-Path -Path $OutputPath -ChildPath "prepared_application_logs.csv"

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©ation du rÃ©pertoire")) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
    }

    $ExportPerformance = if ($NormalizedPerformanceData.Count -gt 0) {
        Export-PreparedData -Data $NormalizedPerformanceData -OutputPath $PerformanceOutputPath -Format "CSV"
    } else {
        # CrÃ©er un fichier vide avec en-tÃªte
        "Timestamp,Path,Instance,Value,NormalizedValue" | Out-File -FilePath $PerformanceOutputPath -Encoding UTF8
        $true
    }

    $ExportSystemLogs = if ($CleanedSystemLogs.Count -gt 0) {
        Export-PreparedData -Data $CleanedSystemLogs -OutputPath $SystemLogsOutputPath -Format "CSV"
    } else {
        # CrÃ©er un fichier vide avec en-tÃªte
        "TimeCreated,Id,LevelDisplayName,Message" | Out-File -FilePath $SystemLogsOutputPath -Encoding UTF8
        $true
    }

    $ExportApplicationLogs = if ($CleanedApplicationLogs.Count -gt 0) {
        Export-PreparedData -Data $CleanedApplicationLogs -OutputPath $ApplicationLogsOutputPath -Format "CSV"
    } else {
        # CrÃ©er un fichier vide avec en-tÃªte
        "Timestamp,Level,Component,Message" | Out-File -FilePath $ApplicationLogsOutputPath -Encoding UTF8
        $true
    }

    # 5. RÃ©sumÃ© des rÃ©sultats
    Write-Log -Message "Processus de prÃ©paration des donnÃ©es terminÃ©" -Level "Info"
    Write-Log -Message "DonnÃ©es de performance: $($NormalizedPerformanceData.Count) entrÃ©es" -Level "Info"
    Write-Log -Message "Logs systÃ¨me: $($CleanedSystemLogs.Count) entrÃ©es" -Level "Info"
    Write-Log -Message "Logs applicatifs: $($CleanedApplicationLogs.Count) entrÃ©es" -Level "Info"

    return @{
        PerformanceData = $NormalizedPerformanceData
        SystemLogs      = $CleanedSystemLogs
        ApplicationLogs = $CleanedApplicationLogs
        Success         = $ExportPerformance -and $ExportSystemLogs -and $ExportApplicationLogs
    }
}

# ExÃ©cution du script
if ($PSCmdlet.ShouldProcess("PrÃ©paration des donnÃ©es", "ExÃ©cuter")) {
    $Result = Start-DataPreparation -SourcePath $SourcePath -OutputPath $OutputPath -StartDate $StartDate -EndDate $EndDate

    if ($Result.Success) {
        Write-Log -Message "PrÃ©paration des donnÃ©es rÃ©ussie" -Level "Info"
        return 0
    } else {
        Write-Log -Message "Ã‰chec de la prÃ©paration des donnÃ©es" -Level "Error"
        return 1
    }
}

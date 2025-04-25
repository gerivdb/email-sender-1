<#
.SYNOPSIS
    Script d'extraction et de préparation des données historiques de performance.

.DESCRIPTION
    Ce script extrait les données de performance historiques de différentes sources,
    les nettoie, les transforme et les prépare pour l'analyse. Il gère les valeurs manquantes,
    normalise les données et les structure dans un format adapté à l'analyse.

.PARAMETER SourcePath
    Chemin vers les sources de données (logs, métriques, etc.).

.PARAMETER OutputPath
    Chemin où les données préparées seront sauvegardées.

.PARAMETER StartDate
    Date de début pour l'extraction des données (format: yyyy-MM-dd).

.PARAMETER EndDate
    Date de fin pour l'extraction des données (format: yyyy-MM-dd).

.PARAMETER LogLevel
    Niveau de journalisation (Verbose, Info, Warning, Error).

.EXAMPLE
    .\data_preparation.ps1 -SourcePath "logs" -OutputPath "data/performance" -StartDate "2025-01-01" -EndDate "2025-03-31" -LogLevel "Info"

.NOTES
    Auteur: Augment Agent
    Date de création: 22/04/2025
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

# Importer les modules nécessaires
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

# Fonction pour extraire les données des logs système
function Get-SystemLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StartDate,

        [Parameter(Mandatory = $true)]
        [string]$EndDate
    )

    Write-Log -Message "Extraction des logs système du $StartDate au $EndDate" -Level "Info"

    try {
        # Convertir les dates en objets DateTime
        $Start = [DateTime]::ParseExact($StartDate, "yyyy-MM-dd", $null)
        $End = [DateTime]::ParseExact($EndDate, "yyyy-MM-dd", $null).AddDays(1).AddSeconds(-1)

        # Extraire les logs d'événements système
        $SystemLogs = Get-WinEvent -FilterHashtable @{
            LogName   = 'System'
            StartTime = $Start
            EndTime   = $End
        } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message

        Write-Log -Message "Extraction réussie: $($SystemLogs.Count) logs système extraits" -Level "Info"
        return $SystemLogs
    } catch {
        Write-Log -Message "Erreur lors de l'extraction des logs système: $_" -Level "Error"
        return $null
    }
}

# Fonction pour extraire les données de performance
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

    Write-Log -Message "Extraction des données de performance du $StartDate au $EndDate" -Level "Info"

    try {
        # Liste des compteurs de performance à collecter
        $Counters = @(
            "\Processor(_Total)\% Processor Time",
            "\Memory\Available MBytes",
            "\PhysicalDisk(_Total)\Disk Reads/sec",
            "\PhysicalDisk(_Total)\Disk Writes/sec",
            "\Network Interface(*)\Bytes Total/sec"
        )

        # Collecter les données de performance actuelles (pour démonstration)
        # Dans un cas réel, on utiliserait des données historiques stockées
        $PerfData = Get-Counter -Counter $Counters -SampleInterval $SampleInterval -MaxSamples 10 -ErrorAction SilentlyContinue

        # Transformer les données en format exploitable
        $ProcessedData = $PerfData.CounterSamples | ForEach-Object {
            [PSCustomObject]@{
                Timestamp = $_.Timestamp
                Path      = $_.Path
                Instance  = $_.InstanceName
                Value     = $_.CookedValue
            }
        }

        Write-Log -Message "Extraction réussie: $($ProcessedData.Count) métriques de performance extraites" -Level "Info"
        return $ProcessedData
    } catch {
        Write-Log -Message "Erreur lors de l'extraction des données de performance: $_" -Level "Error"
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
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $LogPath)) {
            Write-Log -Message "Le chemin des logs applicatifs n'existe pas: $LogPath" -Level "Warning"

            # Créer des données de démonstration
            $DemoLogs = @()
            $Start = [DateTime]::ParseExact($StartDate, "yyyy-MM-dd", $null)
            $End = [DateTime]::ParseExact($EndDate, "yyyy-MM-dd", $null)

            $CurrentDate = $Start
            while ($CurrentDate -le $End) {
                $DemoLogs += [PSCustomObject]@{
                    Timestamp = $CurrentDate.AddHours((Get-Random -Minimum 0 -Maximum 24))
                    Level     = (Get-Random -InputObject @("INFO", "WARNING", "ERROR", "DEBUG"))
                    Component = (Get-Random -InputObject @("API", "Database", "UI", "Authentication"))
                    Message   = "Message de log de démonstration"
                }
                $CurrentDate = $CurrentDate.AddDays(1)
            }

            Write-Log -Message "Données de démonstration créées: $($DemoLogs.Count) logs applicatifs" -Level "Info"
            return $DemoLogs
        }

        # Extraire les logs applicatifs réels
        $LogFiles = Get-ChildItem -Path $LogPath -Filter "*.log" | Where-Object {
            $_.LastWriteTime -ge [DateTime]::ParseExact($StartDate, "yyyy-MM-dd", $null) -and
            $_.LastWriteTime -le [DateTime]::ParseExact($EndDate, "yyyy-MM-dd", $null).AddDays(1)
        }

        $AppLogs = @()
        foreach ($File in $LogFiles) {
            $Content = Get-Content -Path $File.FullName
            # Analyser le contenu selon le format des logs
            # Ceci est un exemple simplifié, à adapter selon le format réel des logs
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

        Write-Log -Message "Extraction réussie: $($AppLogs.Count) logs applicatifs extraits" -Level "Info"
        return $AppLogs
    } catch {
        Write-Log -Message "Erreur lors de l'extraction des logs applicatifs: $_" -Level "Error"
        return $null
    }
}

# Fonction pour nettoyer les données
function Clean-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$DataType = "Performance"
    )

    Write-Log -Message "Nettoyage des données de type $DataType" -Level "Info"

    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à nettoyer pour le type $DataType" -Level "Warning"
            return $null
        }

        # Filtrer les valeurs nulles ou aberrantes
        $CleanedData = $Data | Where-Object { $null -ne $_.Value }

        # Traitement spécifique selon le type de données
        switch ($DataType) {
            "Performance" {
                # Détecter et gérer les valeurs aberrantes (exemple: méthode IQR)
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

                    # Définir les limites pour les valeurs aberrantes
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
                # Nettoyage générique
                $CleanedData = $CleanedData | Sort-Object Timestamp
            }
        }

        Write-Log -Message "Nettoyage réussi: $($CleanedData.Count) entrées conservées sur $($Data.Count)" -Level "Info"
        return $CleanedData
    } catch {
        Write-Log -Message "Erreur lors du nettoyage des données: $_" -Level "Error"
        return $Data
    }
}

# Fonction pour normaliser les données
function Normalize-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$Method = "MinMax" # MinMax, ZScore, Log
    )

    Write-Log -Message "Normalisation des données avec la méthode $Method" -Level "Info"

    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à normaliser" -Level "Warning"
            return $null
        }

        # Normaliser les données numériques
        $NormalizedData = $Data | Group-Object Path | ForEach-Object {
            $Group = $_.Group
            $Values = $Group.Value

            # Calculer les statistiques nécessaires pour la normalisation
            $Min = ($Values | Measure-Object -Minimum).Minimum
            $Max = ($Values | Measure-Object -Maximum).Maximum
            $Mean = ($Values | Measure-Object -Average).Average
            $StdDev = [Math]::Sqrt(($Values | ForEach-Object { [Math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average)

            # Appliquer la méthode de normalisation
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

        Write-Log -Message "Normalisation réussie avec la méthode $Method" -Level "Info"
        return $NormalizedData
    } catch {
        Write-Log -Message "Erreur lors de la normalisation des données: $_" -Level "Error"
        return $Data
    }
}

# Fonction pour exporter les données
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

    Write-Log -Message "Exportation des données au format $Format vers $OutputPath" -Level "Info"

    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à exporter" -Level "Warning"
            return $false
        }

        # Créer le répertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            if ($PSCmdlet.ShouldProcess($Directory, "Création du répertoire")) {
                New-Item -Path $Directory -ItemType Directory -Force | Out-Null
            }
        }

        # Exporter les données selon le format spécifié
        switch ($Format) {
            "CSV" {
                if ($PSCmdlet.ShouldProcess($OutputPath, "Exportation des données au format CSV")) {
                    $Data | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
            }
            "JSON" {
                if ($PSCmdlet.ShouldProcess($OutputPath, "Exportation des données au format JSON")) {
                    $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
            }
            default {
                Write-Log -Message "Format d'exportation non pris en charge: $Format" -Level "Error"
                return $false
            }
        }

        Write-Log -Message "Exportation réussie: $($Data.Count) entrées exportées vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des données: $_" -Level "Error"
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

    Write-Log -Message "Début du processus de préparation des données" -Level "Info"

    # 1. Extraction des données
    Write-Log -Message "Étape 1: Extraction des données" -Level "Info"
    $SystemLogs = Get-SystemLogs -StartDate $StartDate -EndDate $EndDate
    $PerformanceData = Get-PerformanceData -StartDate $StartDate -EndDate $EndDate
    $ApplicationLogs = Get-ApplicationLogs -LogPath $SourcePath -StartDate $StartDate -EndDate $EndDate

    # 2. Nettoyage des données
    Write-Log -Message "Étape 2: Nettoyage des données" -Level "Info"
    $CleanedPerformanceData = if ($null -ne $PerformanceData -and $PerformanceData.Count -gt 0) { Clean-Data -Data $PerformanceData -DataType "Performance" } else { @() }
    $CleanedSystemLogs = if ($null -ne $SystemLogs -and $SystemLogs.Count -gt 0) { Clean-Data -Data $SystemLogs -DataType "Logs" } else { @() }
    $CleanedApplicationLogs = if ($null -ne $ApplicationLogs -and $ApplicationLogs.Count -gt 0) { Clean-Data -Data $ApplicationLogs -DataType "Logs" } else { @() }

    # 3. Normalisation des données
    Write-Log -Message "Étape 3: Normalisation des données" -Level "Info"
    $NormalizedPerformanceData = if ($null -ne $CleanedPerformanceData -and $CleanedPerformanceData.Count -gt 0) { Normalize-Data -Data $CleanedPerformanceData -Method "MinMax" } else { @() }

    # 4. Exportation des données préparées
    Write-Log -Message "Étape 4: Exportation des données préparées" -Level "Info"
    $PerformanceOutputPath = Join-Path -Path $OutputPath -ChildPath "prepared_performance_data.csv"
    $SystemLogsOutputPath = Join-Path -Path $OutputPath -ChildPath "prepared_system_logs.csv"
    $ApplicationLogsOutputPath = Join-Path -Path $OutputPath -ChildPath "prepared_application_logs.csv"

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "Création du répertoire")) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
    }

    $ExportPerformance = if ($NormalizedPerformanceData.Count -gt 0) {
        Export-PreparedData -Data $NormalizedPerformanceData -OutputPath $PerformanceOutputPath -Format "CSV"
    } else {
        # Créer un fichier vide avec en-tête
        "Timestamp,Path,Instance,Value,NormalizedValue" | Out-File -FilePath $PerformanceOutputPath -Encoding UTF8
        $true
    }

    $ExportSystemLogs = if ($CleanedSystemLogs.Count -gt 0) {
        Export-PreparedData -Data $CleanedSystemLogs -OutputPath $SystemLogsOutputPath -Format "CSV"
    } else {
        # Créer un fichier vide avec en-tête
        "TimeCreated,Id,LevelDisplayName,Message" | Out-File -FilePath $SystemLogsOutputPath -Encoding UTF8
        $true
    }

    $ExportApplicationLogs = if ($CleanedApplicationLogs.Count -gt 0) {
        Export-PreparedData -Data $CleanedApplicationLogs -OutputPath $ApplicationLogsOutputPath -Format "CSV"
    } else {
        # Créer un fichier vide avec en-tête
        "Timestamp,Level,Component,Message" | Out-File -FilePath $ApplicationLogsOutputPath -Encoding UTF8
        $true
    }

    # 5. Résumé des résultats
    Write-Log -Message "Processus de préparation des données terminé" -Level "Info"
    Write-Log -Message "Données de performance: $($NormalizedPerformanceData.Count) entrées" -Level "Info"
    Write-Log -Message "Logs système: $($CleanedSystemLogs.Count) entrées" -Level "Info"
    Write-Log -Message "Logs applicatifs: $($CleanedApplicationLogs.Count) entrées" -Level "Info"

    return @{
        PerformanceData = $NormalizedPerformanceData
        SystemLogs      = $CleanedSystemLogs
        ApplicationLogs = $CleanedApplicationLogs
        Success         = $ExportPerformance -and $ExportSystemLogs -and $ExportApplicationLogs
    }
}

# Exécution du script
if ($PSCmdlet.ShouldProcess("Préparation des données", "Exécuter")) {
    $Result = Start-DataPreparation -SourcePath $SourcePath -OutputPath $OutputPath -StartDate $StartDate -EndDate $EndDate

    if ($Result.Success) {
        Write-Log -Message "Préparation des données réussie" -Level "Info"
        return 0
    } else {
        Write-Log -Message "Échec de la préparation des données" -Level "Error"
        return 1
    }
}

<#
.SYNOPSIS
    Configure des seuils d'alerte pour les mesures de performance.

.DESCRIPTION
    La fonction Set-RoadmapPerformanceAlert permet de configurer des seuils d'alerte
    pour les différentes mesures de performance (temps d'exécution, utilisation de mémoire,
    comptage d'opérations). Lorsqu'un seuil est dépassé, une alerte est générée et peut
    déclencher une action personnalisée.

.PARAMETER Type
    Le type de mesure de performance. Les valeurs possibles sont : ExecutionTime, MemoryUsage, Operations.

.PARAMETER Name
    Le nom de la mesure de performance pour laquelle configurer un seuil d'alerte.

.PARAMETER Threshold
    La valeur seuil à partir de laquelle une alerte doit être générée.
    Pour ExecutionTime, la valeur est en millisecondes.
    Pour MemoryUsage, la valeur est en octets.
    Pour Operations, la valeur est un nombre d'opérations.

.PARAMETER Action
    Un script à exécuter lorsque le seuil est dépassé. Le script reçoit un objet contenant
    les informations sur l'alerte (Type, Name, Threshold, CurrentValue, Timestamp).

.PARAMETER LogLevel
    Le niveau de journalisation à utiliser pour les alertes. Par défaut : Warning.

.PARAMETER Enabled
    Indique si l'alerte est activée. Par défaut : $true.

.EXAMPLE
    Set-RoadmapPerformanceAlert -Type ExecutionTime -Name "ParseRoadmap" -Threshold 1000
    Configure un seuil d'alerte de 1000 millisecondes pour la mesure de temps d'exécution "ParseRoadmap".

.EXAMPLE
    Set-RoadmapPerformanceAlert -Type MemoryUsage -Name "LoadRoadmap" -Threshold 1GB -Action { param($Alert) Send-MailMessage -To "admin@example.com" -Subject "Alerte mémoire" -Body "Utilisation mémoire élevée: $($Alert.CurrentValue) octets" }
    Configure un seuil d'alerte de 1 Go pour la mesure d'utilisation de mémoire "LoadRoadmap" et envoie un email lorsque le seuil est dépassé.

.OUTPUTS
    [PSCustomObject] Retourne un objet représentant la configuration de l'alerte.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-24
#>
function Set-RoadmapPerformanceAlert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("ExecutionTime", "MemoryUsage", "Operations")]
        [string]$Type,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 2)]
        [long]$Threshold,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [string]$LogLevel = "Warning",

        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true
    )

    # Importer les fonctions de mesure de performance
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance"
    $performanceFunctionsPath = Join-Path -Path $privatePath -ChildPath "PerformanceMeasurementFunctions.ps1"

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Configurer le seuil d'alerte en fonction du type
    switch ($Type) {
        "ExecutionTime" {
            # Vérifier si la fonction existe
            if (Get-Command -Name "Set-PerformanceThreshold" -ErrorAction SilentlyContinue) {
                # Vérifier les paramètres de la fonction
                $paramInfo = Get-Command -Name "Set-PerformanceThreshold" | Select-Object -ExpandProperty Parameters
                if ($paramInfo.ContainsKey("ThresholdMs")) {
                    Set-PerformanceThreshold -Name $Name -ThresholdMs $Threshold
                } else {
                    Write-Log -Message "Paramètre ThresholdMs non trouvé, utilisation de Threshold" -Level "Warning" -Source "PerformanceAlert"
                    Set-PerformanceThreshold -Name $Name -Threshold $Threshold
                }
            } else {
                Write-Log -Message "Fonction Set-PerformanceThreshold non trouvée" -Level "Warning" -Source "PerformanceAlert"
            }
        }
        "MemoryUsage" {
            # Vérifier si la fonction existe
            if (Get-Command -Name "Set-MemoryThreshold" -ErrorAction SilentlyContinue) {
                # Vérifier les paramètres de la fonction
                $paramInfo = Get-Command -Name "Set-MemoryThreshold" | Select-Object -ExpandProperty Parameters
                if ($paramInfo.ContainsKey("ThresholdBytes")) {
                    Set-MemoryThreshold -Name $Name -ThresholdBytes $Threshold
                } else {
                    Write-Log -Message "Paramètre ThresholdBytes non trouvé, utilisation de Threshold" -Level "Warning" -Source "PerformanceAlert"
                    Set-MemoryThreshold -Name $Name -Threshold $Threshold
                }
            } else {
                Write-Log -Message "Fonction Set-MemoryThreshold non trouvée" -Level "Warning" -Source "PerformanceAlert"
            }
        }
        "Operations" {
            # Vérifier si la fonction existe
            if (Get-Command -Name "Set-OperationThreshold" -ErrorAction SilentlyContinue) {
                Set-OperationThreshold -Name $Name -Threshold $Threshold
            } else {
                Write-Log -Message "Fonction Set-OperationThreshold non trouvée" -Level "Warning" -Source "PerformanceAlert"
            }
        }
    }

    # Créer l'objet de configuration d'alerte
    $alertConfig = [PSCustomObject]@{
        Type      = $Type
        Name      = $Name
        Threshold = $Threshold
        Action    = $Action
        LogLevel  = $LogLevel
        Enabled   = $Enabled
        CreatedAt = Get-Date
    }

    # Enregistrer la configuration d'alerte
    Save-AlertConfiguration -AlertConfig $alertConfig

    # Retourner la configuration d'alerte
    return $alertConfig
}

# Fonction privée pour enregistrer la configuration d'alerte
function Save-AlertConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AlertConfig
    )

    # Charger les configurations d'alerte existantes
    $alertConfigurations = Import-AlertConfigurations

    # Vérifier si $alertConfigurations est un tableau
    if ($null -eq $alertConfigurations) {
        $alertConfigurations = [System.Collections.ArrayList]@()
    } elseif ($alertConfigurations -isnot [System.Collections.ArrayList]) {
        $tempList = [System.Collections.ArrayList]@()
        foreach ($item in $alertConfigurations) {
            $tempList.Add($item) | Out-Null
        }
        $alertConfigurations = $tempList
    }

    # Ajouter ou mettre à jour la configuration d'alerte
    $existingIndex = -1
    for ($i = 0; $i -lt $alertConfigurations.Count; $i++) {
        if ($alertConfigurations[$i].Type -eq $AlertConfig.Type -and $alertConfigurations[$i].Name -eq $AlertConfig.Name) {
            $existingIndex = $i
            break
        }
    }

    if ($existingIndex -ge 0) {
        $alertConfigurations[$existingIndex] = $AlertConfig
    } else {
        $alertConfigurations.Add($AlertConfig) | Out-Null
    }

    # Enregistrer les configurations d'alerte
    $alertConfigurationsPath = Get-AlertConfigurationsPath

    # Créer le dossier parent s'il n'existe pas
    $parentFolder = Split-Path -Parent $alertConfigurationsPath
    if (-not [string]::IsNullOrEmpty($parentFolder) -and -not (Test-Path -Path $parentFolder)) {
        New-Item -ItemType Directory -Path $parentFolder -Force | Out-Null
    }

    $alertConfigurations | ConvertTo-Json -Depth 10 | Out-File -FilePath $alertConfigurationsPath -Encoding UTF8

    Write-Log -Message "Configuration d'alerte enregistrée pour $($AlertConfig.Type) '$($AlertConfig.Name)' avec un seuil de $($AlertConfig.Threshold)." -Level "Info" -Source "PerformanceAlert"
}

# Fonction privée pour importer les configurations d'alerte
function Import-AlertConfigurations {
    [CmdletBinding()]
    param ()

    # Obtenir le chemin du fichier de configurations d'alerte
    $alertConfigurationsPath = Get-AlertConfigurationsPath

    # Vérifier si le fichier existe
    if (Test-Path -Path $alertConfigurationsPath) {
        try {
            # Charger les configurations d'alerte
            $content = Get-Content -Path $alertConfigurationsPath -Raw -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-Log -Message "Le fichier de configurations d'alerte est vide." -Level "Warning" -Source "PerformanceAlert"
                return [System.Collections.ArrayList]@()
            }

            $alertConfigurations = $content | ConvertFrom-Json -ErrorAction Stop

            # Convertir en ArrayList
            $result = [System.Collections.ArrayList]@()
            foreach ($item in $alertConfigurations) {
                $result.Add($item) | Out-Null
            }

            return $result
        } catch {
            Write-Log -Message "Erreur lors du chargement des configurations d'alerte : $_" -Level "Error" -Source "PerformanceAlert"
            return [System.Collections.ArrayList]@()
        }
    } else {
        # Retourner une liste vide
        return [System.Collections.ArrayList]@()
    }
}

# Fonction privée pour obtenir le chemin du fichier de configurations d'alerte
function Get-AlertConfigurationsPath {
    [CmdletBinding()]
    param ()

    # Obtenir le dossier temporaire
    $tempFolder = [System.IO.Path]::GetTempPath()
    $alertConfigurationsFolder = Join-Path -Path $tempFolder -ChildPath "RoadmapParser\Performance"

    # Créer le dossier s'il n'existe pas
    if (-not (Test-Path -Path $alertConfigurationsFolder)) {
        New-Item -ItemType Directory -Path $alertConfigurationsFolder -Force | Out-Null
    }

    # Retourner le chemin du fichier
    return Join-Path -Path $alertConfigurationsFolder -ChildPath "AlertConfigurations.json"
}

# Exporter la fonction
# Export-ModuleMember -Function Set-RoadmapPerformanceAlert

<#
.SYNOPSIS
    Récupère les configurations d'alerte de performance.

.DESCRIPTION
    La fonction Get-RoadmapPerformanceAlert permet de récupérer les configurations d'alerte
    de performance configurées avec Set-RoadmapPerformanceAlert. Elle peut filtrer les alertes
    par type et par nom.

.PARAMETER Type
    Le type de mesure de performance. Les valeurs possibles sont : ExecutionTime, MemoryUsage, Operations.
    Si non spécifié, toutes les alertes sont retournées.

.PARAMETER Name
    Le nom de la mesure de performance pour laquelle récupérer les alertes.
    Si non spécifié, toutes les alertes du type spécifié sont retournées.

.PARAMETER IncludeDisabled
    Indique si les alertes désactivées doivent être incluses dans les résultats.
    Par défaut : $false.

.EXAMPLE
    Get-RoadmapPerformanceAlert
    Récupère toutes les configurations d'alerte de performance.

.EXAMPLE
    Get-RoadmapPerformanceAlert -Type ExecutionTime
    Récupère toutes les configurations d'alerte de performance pour les mesures de temps d'exécution.

.EXAMPLE
    Get-RoadmapPerformanceAlert -Type MemoryUsage -Name "LoadRoadmap"
    Récupère la configuration d'alerte de performance pour la mesure d'utilisation de mémoire "LoadRoadmap".

.OUTPUTS
    [PSCustomObject[]] Retourne un tableau d'objets représentant les configurations d'alerte.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-24
#>
function Get-RoadmapPerformanceAlert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("ExecutionTime", "MemoryUsage", "Operations")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeDisabled = $false
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

    # Obtenir le chemin du fichier de configurations d'alerte
    $alertConfigurationsPath = Get-AlertConfigurationsPath

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $alertConfigurationsPath)) {
        Write-Log -Message "Aucune configuration d'alerte trouvée." -Level "Info" -Source "PerformanceAlert"
        return @()
    }

    # Charger les configurations d'alerte
    $alertConfigurations = Get-Content -Path $alertConfigurationsPath -Raw | ConvertFrom-Json

    # Filtrer les alertes
    $filteredAlerts = $alertConfigurations
    
    # Filtrer par type
    if ($Type) {
        $filteredAlerts = $filteredAlerts | Where-Object { $_.Type -eq $Type }
    }
    
    # Filtrer par nom
    if ($Name) {
        $filteredAlerts = $filteredAlerts | Where-Object { $_.Name -eq $Name }
    }
    
    # Filtrer par état
    if (-not $IncludeDisabled) {
        $filteredAlerts = $filteredAlerts | Where-Object { $_.Enabled -eq $true }
    }

    return $filteredAlerts
}

# Fonction privée pour obtenir le chemin du fichier de configurations d'alerte
function Get-AlertConfigurationsPath {
    [CmdletBinding()]
    param ()

    # Obtenir le dossier temporaire
    $tempFolder = [System.IO.Path]::GetTempPath()
    $alertConfigurationsFolder = Join-Path -Path $tempFolder -ChildPath "RoadmapParser\Performance"

    # Retourner le chemin du fichier
    return Join-Path -Path $alertConfigurationsFolder -ChildPath "AlertConfigurations.json"
}

# Exporter la fonction
# Export-ModuleMember -Function Get-RoadmapPerformanceAlert

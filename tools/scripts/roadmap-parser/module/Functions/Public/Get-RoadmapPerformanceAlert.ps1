<#
.SYNOPSIS
    RÃ©cupÃ¨re les configurations d'alerte de performance.

.DESCRIPTION
    La fonction Get-RoadmapPerformanceAlert permet de rÃ©cupÃ©rer les configurations d'alerte
    de performance configurÃ©es avec Set-RoadmapPerformanceAlert. Elle peut filtrer les alertes
    par type et par nom.

.PARAMETER Type
    Le type de mesure de performance. Les valeurs possibles sont : ExecutionTime, MemoryUsage, Operations.
    Si non spÃ©cifiÃ©, toutes les alertes sont retournÃ©es.

.PARAMETER Name
    Le nom de la mesure de performance pour laquelle rÃ©cupÃ©rer les alertes.
    Si non spÃ©cifiÃ©, toutes les alertes du type spÃ©cifiÃ© sont retournÃ©es.

.PARAMETER IncludeDisabled
    Indique si les alertes dÃ©sactivÃ©es doivent Ãªtre incluses dans les rÃ©sultats.
    Par dÃ©faut : $false.

.EXAMPLE
    Get-RoadmapPerformanceAlert
    RÃ©cupÃ¨re toutes les configurations d'alerte de performance.

.EXAMPLE
    Get-RoadmapPerformanceAlert -Type ExecutionTime
    RÃ©cupÃ¨re toutes les configurations d'alerte de performance pour les mesures de temps d'exÃ©cution.

.EXAMPLE
    Get-RoadmapPerformanceAlert -Type MemoryUsage -Name "LoadRoadmap"
    RÃ©cupÃ¨re la configuration d'alerte de performance pour la mesure d'utilisation de mÃ©moire "LoadRoadmap".

.OUTPUTS
    [PSCustomObject[]] Retourne un tableau d'objets reprÃ©sentant les configurations d'alerte.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-24
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Obtenir le chemin du fichier de configurations d'alerte
    $alertConfigurationsPath = Get-AlertConfigurationsPath

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $alertConfigurationsPath)) {
        Write-Log -Message "Aucune configuration d'alerte trouvÃ©e." -Level "Info" -Source "PerformanceAlert"
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
    
    # Filtrer par Ã©tat
    if (-not $IncludeDisabled) {
        $filteredAlerts = $filteredAlerts | Where-Object { $_.Enabled -eq $true }
    }

    return $filteredAlerts
}

# Fonction privÃ©e pour obtenir le chemin du fichier de configurations d'alerte
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

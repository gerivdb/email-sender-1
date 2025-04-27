<#
.SYNOPSIS
    Obtient la configuration de journalisation actuelle du module RoadmapParser.

.DESCRIPTION
    La fonction Get-RoadmapLogConfiguration obtient la configuration de journalisation actuelle du module RoadmapParser.
    Elle retourne un objet contenant les paramÃ¨tres de journalisation actuels.

.EXAMPLE
    Get-RoadmapLogConfiguration
    Obtient la configuration de journalisation actuelle.

.OUTPUTS
    [PSCustomObject] Un objet contenant la configuration de journalisation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Get-RoadmapLogConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    # Importer les fonctions de journalisation
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Logging"
    $loggingFunctionsPath = Join-Path -Path $privatePath -ChildPath "LoggingFunctions.ps1"

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $loggingFunctionsPath)) {
        throw "Le fichier LoggingFunctions.ps1 est introuvable Ã  l'emplacement : $loggingFunctionsPath"
    }

    # Importer les fonctions
    . $loggingFunctionsPath

    # Obtenir la configuration actuelle
    return Get-LoggingConfiguration
}

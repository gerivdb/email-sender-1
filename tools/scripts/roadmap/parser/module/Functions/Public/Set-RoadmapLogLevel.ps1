<#
.SYNOPSIS
    Configure le niveau de journalisation pour le module RoadmapParser.

.DESCRIPTION
    La fonction Set-RoadmapLogLevel configure le niveau de journalisation pour le module RoadmapParser.
    Elle permet de définir le niveau de journalisation utilisé pour filtrer les messages de journal.

.PARAMETER Level
    Le niveau de journalisation à configurer. Valeurs possibles :
    - None : Aucun message de journal
    - Debug : Messages de débogage et supérieurs
    - Verbose : Messages détaillés et supérieurs
    - Information : Messages d'information et supérieurs
    - Warning : Messages d'avertissement et supérieurs
    - Error : Messages d'erreur et supérieurs
    - Critical : Messages critiques uniquement
    - All : Tous les messages de journal

.EXAMPLE
    Set-RoadmapLogLevel -Level Debug
    Configure le niveau de journalisation pour afficher les messages de débogage et supérieurs.

.EXAMPLE
    Set-RoadmapLogLevel -Level Warning
    Configure le niveau de journalisation pour afficher les messages d'avertissement et supérieurs.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Set-RoadmapLogLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("None", "Debug", "Verbose", "Information", "Warning", "Error", "Critical", "All")]
        [string]$Level
    )

    # Importer les fonctions de journalisation
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Logging"
    $loggingFunctionsPath = Join-Path -Path $privatePath -ChildPath "LoggingFunctions.ps1"

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $loggingFunctionsPath)) {
        throw "Le fichier LoggingFunctions.ps1 est introuvable à l'emplacement : $loggingFunctionsPath"
    }

    # Importer les fonctions
    . $loggingFunctionsPath

    # Obtenir la configuration actuelle
    $config = Get-LoggingConfiguration

    # Mettre à jour le niveau de journalisation
    Set-LoggingConfiguration -Level $Level -Enabled $config.Enabled -Destination $config.Destination -FilePath $config.FilePath -FileMaxSize $config.FileMaxSize -FileMaxCount $config.FileMaxCount -Format $config.Format -TimestampFormat $config.TimestampFormat -IncludeTimestamp $config.IncludeTimestamp -IncludeLevel $config.IncludeLevel -IncludeSource $config.IncludeSource -SourceName $config.SourceName
}

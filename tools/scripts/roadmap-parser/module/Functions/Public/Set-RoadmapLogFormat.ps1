<#
.SYNOPSIS
    Configure le format des messages de journalisation pour le module RoadmapParser.

.DESCRIPTION
    La fonction Set-RoadmapLogFormat configure le format des messages de journalisation pour le module RoadmapParser.
    Elle permet de définir comment les messages de journal seront formatés.

.PARAMETER Format
    Le format des messages de journalisation.
    Par défaut, c'est "{0} {1} {2}".

.PARAMETER TimestampFormat
    Le format des horodatages.
    Par défaut, c'est "yyyy-MM-dd HH:mm:ss".

.PARAMETER IncludeTimestamp
    Indique si les horodatages doivent être inclus dans les messages de journalisation.
    Par défaut, c'est $true.

.PARAMETER IncludeLevel
    Indique si les niveaux de journalisation doivent être inclus dans les messages de journalisation.
    Par défaut, c'est $true.

.PARAMETER IncludeSource
    Indique si la source doit être incluse dans les messages de journalisation.
    Par défaut, c'est $true.

.PARAMETER SourceName
    Le nom de la source à inclure dans les messages de journalisation.
    Par défaut, c'est "RoadmapParser".

.EXAMPLE
    Set-RoadmapLogFormat -Format "{0} - {1}{2}" -TimestampFormat "HH:mm:ss"
    Configure le format des messages de journalisation avec un format personnalisé et un format d'horodatage personnalisé.

.EXAMPLE
    Set-RoadmapLogFormat -IncludeTimestamp $false -IncludeLevel $true -IncludeSource $false
    Configure le format des messages de journalisation pour inclure uniquement le niveau de journalisation.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Set-RoadmapLogFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Format = "{0} {1} {2}",

        [Parameter(Mandatory = $false)]
        [string]$TimestampFormat = "yyyy-MM-dd HH:mm:ss",

        [Parameter(Mandatory = $false)]
        [bool]$IncludeTimestamp = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeLevel = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeSource = $true,

        [Parameter(Mandatory = $false)]
        [string]$SourceName = "RoadmapParser"
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

    # Mettre à jour le format des messages de journalisation
    Set-LoggingConfiguration -Format $Format -TimestampFormat $TimestampFormat -IncludeTimestamp $IncludeTimestamp -IncludeLevel $IncludeLevel -IncludeSource $IncludeSource -SourceName $SourceName -Enabled $config.Enabled -Level $config.Level -Destination $config.Destination -FilePath $config.FilePath -FileMaxSize $config.FileMaxSize -FileMaxCount $config.FileMaxCount
}

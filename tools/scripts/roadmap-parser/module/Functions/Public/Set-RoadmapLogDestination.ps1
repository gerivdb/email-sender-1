<#
.SYNOPSIS
    Configure la destination de journalisation pour le module RoadmapParser.

.DESCRIPTION
    La fonction Set-RoadmapLogDestination configure la destination de journalisation pour le module RoadmapParser.
    Elle permet de définir où les messages de journal seront écrits.

.PARAMETER Destination
    La destination de la journalisation. Valeurs possibles :
    - Console : Écrit les messages dans la console
    - File : Écrit les messages dans un fichier
    - Both : Écrit les messages dans la console et dans un fichier

.PARAMETER FilePath
    Le chemin du fichier de journalisation.
    Requis lorsque Destination est "File" ou "Both".

.PARAMETER FileMaxSize
    La taille maximale du fichier de journalisation.
    Par défaut, c'est 10MB.

.PARAMETER FileMaxCount
    Le nombre maximal de fichiers de journalisation à conserver.
    Par défaut, c'est 5.

.EXAMPLE
    Set-RoadmapLogDestination -Destination Console
    Configure la journalisation pour écrire les messages dans la console.

.EXAMPLE
    Set-RoadmapLogDestination -Destination File -FilePath "C:\Logs\RoadmapParser.log"
    Configure la journalisation pour écrire les messages dans un fichier.

.EXAMPLE
    Set-RoadmapLogDestination -Destination Both -FilePath "C:\Logs\RoadmapParser.log" -FileMaxSize 5MB -FileMaxCount 3
    Configure la journalisation pour écrire les messages dans la console et dans un fichier, avec une taille maximale de 5MB et en conservant 3 fichiers.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Set-RoadmapLogDestination {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Console", "File", "Both")]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [long]$FileMaxSize = 10MB,

        [Parameter(Mandatory = $false)]
        [int]$FileMaxCount = 5
    )

    # Valider les paramètres
    if ($Destination -in @("File", "Both") -and [string]::IsNullOrEmpty($FilePath)) {
        throw "Le paramètre FilePath est requis lorsque Destination est 'File' ou 'Both'."
    }

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

    # Mettre à jour la destination de journalisation
    Set-LoggingConfiguration -Destination $Destination -FilePath $FilePath -FileMaxSize $FileMaxSize -FileMaxCount $FileMaxCount -Enabled $config.Enabled -Level $config.Level -Format $config.Format -TimestampFormat $config.TimestampFormat -IncludeTimestamp $config.IncludeTimestamp -IncludeLevel $config.IncludeLevel -IncludeSource $config.IncludeSource -SourceName $config.SourceName
}

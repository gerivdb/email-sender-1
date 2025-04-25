<#
.SYNOPSIS
    Exécute les tests de résolution de chemins avec TestOmnibus.
.DESCRIPTION
    Ce script exécute les tests de résolution de chemins en utilisant
    TestOmnibus et génère un rapport HTML des résultats.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de TestOmnibus.
.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit être généré.
.PARAMETER ShowDetailedResults
    Indique si les résultats détaillés doivent être affichés.
.EXAMPLE
    .\Run-PathResolverTests.ps1 -GenerateHtmlReport
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-15
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath "Config\testomnibus_config.json"),

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlReport,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDetailedResults
)

# Vérifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
    return 1
}

# Chemin vers l'adaptateur
$adapterPath = Join-Path -Path $PSScriptRoot -ChildPath "Adapters\PathResolver-Adapter.ps1"

if (-not (Test-Path -Path $adapterPath)) {
    Write-Error "Adaptateur non trouvé: $adapterPath"
    return 1
}

# Importer l'adaptateur
. $adapterPath

# Exécuter les tests
$results = Invoke-PathResolverTests -GenerateHtmlReport:$GenerateHtmlReport -ShowDetailedResults:$ShowDetailedResults

# Retourner les résultats
return $results

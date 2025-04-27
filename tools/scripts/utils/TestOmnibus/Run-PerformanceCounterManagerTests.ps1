<#
.SYNOPSIS
    ExÃ©cute les tests de gestion des compteurs de performance avec TestOmnibus.
.DESCRIPTION
    Ce script exÃ©cute les tests de gestion des compteurs de performance en utilisant
    TestOmnibus et gÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de TestOmnibus.
.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ©.
.PARAMETER ShowDetailedResults
    Indique si les rÃ©sultats dÃ©taillÃ©s doivent Ãªtre affichÃ©s.
.EXAMPLE
    .\Run-PerformanceCounterManagerTests.ps1 -GenerateHtmlReport
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

# VÃ©rifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
    return 1
}

# Chemin vers l'adaptateur
$adapterPath = Join-Path -Path $PSScriptRoot -ChildPath "Adapters\PerformanceCounterManager-Adapter.ps1"

if (-not (Test-Path -Path $adapterPath)) {
    Write-Error "Adaptateur non trouvÃ©: $adapterPath"
    return 1
}

# Importer l'adaptateur
. $adapterPath

# ExÃ©cuter les tests
$results = Invoke-PerformanceCounterManagerTests -GenerateHtmlReport:$GenerateHtmlReport -ShowDetailedResults:$ShowDetailedResults

# Retourner les rÃ©sultats
return $results

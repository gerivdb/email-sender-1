<#
.SYNOPSIS
    Script d'intÃ©gration pour le mode DEV-R amÃ©liorÃ©.

.DESCRIPTION
    Ce script permet d'invoquer le mode DEV-R amÃ©liorÃ© depuis Augment ou d'autres outils.
    Il prend en charge le traitement de la sÃ©lection actuelle dans le document et
    peut traiter les tÃ¢ches enfants avant les tÃ¢ches parentes.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (optionnel).

.PARAMETER Selection
    La sÃ©lection de texte Ã  traiter. Si spÃ©cifiÃ©e, le mode ProcessSelection est activÃ© automatiquement.

.PARAMETER ChildrenFirst
    Indique si les tÃ¢ches enfants doivent Ãªtre traitÃ©es avant les tÃ¢ches parentes.

.PARAMETER StepByStep
    Indique si les tÃ¢ches doivent Ãªtre traitÃ©es une par une avec une pause entre chaque tÃ¢che.

.PARAMETER ProjectPath
    Chemin vers le rÃ©pertoire du projet.

.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire des tests.

.PARAMETER OutputPath
    Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie.

.PARAMETER AutoCommit
    Indique si les changements doivent Ãªtre automatiquement commitÃ©s.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit Ãªtre mise Ã  jour automatiquement.

.PARAMETER GenerateTests
    Indique si des tests doivent Ãªtre gÃ©nÃ©rÃ©s automatiquement.

.PARAMETER ConfigFile
    Chemin vers un fichier de configuration personnalisÃ©.

.PARAMETER LogLevel
    Niveau de journalisation Ã  utiliser.

.EXAMPLE
    .\Invoke-DevRMode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3"

    Traite la tÃ¢che 1.2.3 du fichier roadmap.md.

.EXAMPLE
    .\Invoke-DevRMode.ps1 -FilePath "roadmap.md" -Selection "- [ ] 1.1 TÃ¢che parent`n  - [ ] 1.1.1 TÃ¢che enfant" -ChildrenFirst -StepByStep

    Traite la sÃ©lection spÃ©cifiÃ©e en commenÃ§ant par les tÃ¢ches enfants, avec une pause entre chaque tÃ¢che.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-16
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Chemin vers le fichier de roadmap Ã  traiter.")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Identifiant de la tÃ¢che Ã  traiter (optionnel).")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, HelpMessage = "La sÃ©lection de texte Ã  traiter.")]
    [string]$Selection,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les tÃ¢ches enfants doivent Ãªtre traitÃ©es avant les tÃ¢ches parentes.")]
    [switch]$ChildrenFirst,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les tÃ¢ches doivent Ãªtre traitÃ©es une par une avec une pause entre chaque tÃ¢che.")]
    [switch]$StepByStep,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le rÃ©pertoire du projet.")]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le rÃ©pertoire des tests.")]
    [string]$TestsPath,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie.")]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les changements doivent Ãªtre automatiquement commitÃ©s.")]
    [switch]$AutoCommit,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si la roadmap doit Ãªtre mise Ã  jour automatiquement.")]
    [switch]$UpdateRoadmap = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si des tests doivent Ãªtre gÃ©nÃ©rÃ©s automatiquement.")]
    [switch]$GenerateTests = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier de configuration personnalisÃ©.")]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de journalisation Ã  utiliser.")]
    [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
    [string]$LogLevel = "INFO"
)

# Chemin vers le script du mode DEV-R amÃ©liorÃ©
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$devRScriptPath = Join-Path -Path $scriptPath -ChildPath "dev-r-mode-enhanced.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $devRScriptPath)) {
    Write-Error "Le script du mode DEV-R amÃ©liorÃ© est introuvable Ã  l'emplacement : $devRScriptPath"
    exit 1
}

# Construire les paramÃ¨tres pour le script du mode DEV-R amÃ©liorÃ©
$params = @{
    FilePath = $FilePath
    LogLevel = $LogLevel
}

if ($TaskIdentifier) {
    $params.TaskIdentifier = $TaskIdentifier
}

if ($Selection) {
    $params.ProcessSelection = $true
    $params.Selection = $Selection
}

if ($ChildrenFirst) {
    $params.ChildrenFirst = $true
}

if ($StepByStep) {
    $params.StepByStep = $true
}

if ($ProjectPath) {
    $params.ProjectPath = $ProjectPath
}

if ($TestsPath) {
    $params.TestsPath = $TestsPath
}

if ($OutputPath) {
    $params.OutputPath = $OutputPath
}

if ($AutoCommit) {
    $params.AutoCommit = $true
}

if ($UpdateRoadmap) {
    $params.UpdateRoadmap = $true
}

if ($GenerateTests) {
    $params.GenerateTests = $true
}

if ($ConfigFile) {
    $params.ConfigFile = $ConfigFile
}

# ExÃ©cuter le script du mode DEV-R amÃ©liorÃ©
& $devRScriptPath @params

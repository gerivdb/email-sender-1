<#
.SYNOPSIS
    Script d'intÃ©gration pour le mode DEV-R amÃ©liorÃ© dans Augment.

.DESCRIPTION
    Ce script permet d'invoquer le mode DEV-R amÃ©liorÃ© directement depuis Augment.
    Il prend en charge le traitement de la sÃ©lection actuelle dans le document et
    peut traiter les tÃ¢ches enfants avant les tÃ¢ches parentes.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (optionnel).

.PARAMETER UseSelection
    Indique si le script doit utiliser la sÃ©lection actuelle dans le document Augment.

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
    .\Invoke-AugmentDevRMode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3"

    Traite la tÃ¢che 1.2.3 du fichier roadmap.md.

.EXAMPLE
    .\Invoke-AugmentDevRMode.ps1 -FilePath "roadmap.md" -UseSelection -ChildrenFirst -StepByStep

    Traite la sÃ©lection actuelle dans le document Augment en commenÃ§ant par les tÃ¢ches enfants, avec une pause entre chaque tÃ¢che.

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

    [Parameter(Mandatory = $false, HelpMessage = "Indique si le script doit utiliser la sÃ©lection actuelle dans le document Augment.")]
    [switch]$UseSelection,

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

# Chemin vers le script d'intÃ©gration du mode DEV-R
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$devRScriptPath = Join-Path -Path $scriptPath -ChildPath "..\..\roadmap\parser\modes\dev-r\Invoke-DevRMode.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $devRScriptPath)) {
    Write-Error "Le script d'intÃ©gration du mode DEV-R est introuvable Ã  l'emplacement : $devRScriptPath"
    exit 1
}

# Construire les paramÃ¨tres pour le script d'intÃ©gration du mode DEV-R
$params = @{
    FilePath = $FilePath
    LogLevel = $LogLevel
}

if ($TaskIdentifier) {
    $params.TaskIdentifier = $TaskIdentifier
}

# Obtenir la sÃ©lection actuelle dans le document Augment si demandÃ©
if ($UseSelection) {
    try {
        # Utiliser la fonction d'Augment pour obtenir la sÃ©lection actuelle
        # Note: Cette fonction doit Ãªtre implÃ©mentÃ©e dans Augment
        $selection = Get-AugmentSelection
        
        if ([string]::IsNullOrEmpty($selection)) {
            Write-Warning "Aucune sÃ©lection trouvÃ©e dans le document Augment."
            exit 0
        }
        
        $params.Selection = $selection
    } catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration de la sÃ©lection dans Augment : $_"
        exit 1
    }
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

# ExÃ©cuter le script d'intÃ©gration du mode DEV-R
& $devRScriptPath @params

# Fonction fictive pour obtenir la sÃ©lection actuelle dans Augment
# Cette fonction doit Ãªtre remplacÃ©e par la vÃ©ritable implÃ©mentation dans Augment
function Get-AugmentSelection {
    # Simuler la rÃ©cupÃ©ration de la sÃ©lection dans Augment
    # Dans une vÃ©ritable implÃ©mentation, cette fonction appellerait l'API d'Augment
    # pour obtenir la sÃ©lection actuelle dans le document
    
    # Pour l'instant, retourner une sÃ©lection fictive
    return "- [ ] 1.1 TÃ¢che parent`n  - [ ] 1.1.1 TÃ¢che enfant"
}

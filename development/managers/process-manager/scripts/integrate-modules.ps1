<#
.SYNOPSIS
    Script d'intÃ©gration des modules amÃ©liorÃ©s pour le Process Manager.

.DESCRIPTION
    Ce script intÃ¨gre les modules amÃ©liorÃ©s (ManagerRegistrationService, ManifestParser,
    ValidationService, DependencyResolver) au Process Manager existant.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER ModulesPath
    Chemin vers le rÃ©pertoire des modules. Par dÃ©faut, utilise le rÃ©pertoire 'modules' dans le rÃ©pertoire du Process Manager.

.PARAMETER Force
    Force l'intÃ©gration mÃªme si les modules sont dÃ©jÃ  intÃ©grÃ©s.

.EXAMPLE
    .\integrate-modules.ps1
    IntÃ¨gre les modules amÃ©liorÃ©s au Process Manager.

.EXAMPLE
    .\integrate-modules.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force
    Force l'intÃ©gration des modules amÃ©liorÃ©s dans le rÃ©pertoire spÃ©cifiÃ©.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [string]$ModulesPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©finir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$defaultModulesPath = Join-Path -Path $processManagerRoot -ChildPath "modules"
$modulesPath = if ($ModulesPath) { $ModulesPath } else { $defaultModulesPath }
$psModulesPath = Join-Path -Path $env:PSModulePath.Split(';')[0] -ChildPath "ProcessManager"

# DÃ©finir les noms des modules
$moduleNames = @(
    "ManagerRegistrationService",
    "ManifestParser",
    "ValidationService",
    "DependencyResolver"
)

# Fonction pour Ã©crire des messages de journal
function Write-IntegrationLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # DÃ©finir la couleur en fonction du niveau
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    Write-Host $logMessage -ForegroundColor $color
}

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-IntegrationLog -Message "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# VÃ©rifier que le rÃ©pertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-IntegrationLog -Message "Le rÃ©pertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# VÃ©rifier que le rÃ©pertoire des modules existe
if (-not (Test-Path -Path $modulesPath -PathType Container)) {
    Write-IntegrationLog -Message "Le rÃ©pertoire des modules n'existe pas : $modulesPath" -Level Error
    exit 1
}

# VÃ©rifier si les modules sont dÃ©jÃ  intÃ©grÃ©s
$modulesIntegrated = $true
foreach ($moduleName in $moduleNames) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $moduleName
    if (-not (Test-Path -Path $modulePath -PathType Container)) {
        $modulesIntegrated = $false
        break
    }
}

if ($modulesIntegrated -and -not $Force) {
    Write-IntegrationLog -Message "Les modules sont dÃ©jÃ  intÃ©grÃ©s. Utilisez -Force pour forcer l'intÃ©gration." -Level Warning
    exit 0
}

# CrÃ©er le rÃ©pertoire des modules PowerShell si nÃ©cessaire
if (-not (Test-Path -Path $psModulesPath -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($psModulesPath, "CrÃ©er le rÃ©pertoire des modules PowerShell")) {
        New-Item -Path $psModulesPath -ItemType Directory -Force | Out-Null
        Write-IntegrationLog -Message "RÃ©pertoire des modules PowerShell crÃ©Ã© : $psModulesPath" -Level Success
    }
}

# IntÃ©grer chaque module
foreach ($moduleName in $moduleNames) {
    $moduleSourcePath = Join-Path -Path $modulesPath -ChildPath $moduleName
    $moduleDestPath = Join-Path -Path $psModulesPath -ChildPath $moduleName
    
    # VÃ©rifier que le module source existe
    if (-not (Test-Path -Path $moduleSourcePath -PathType Container)) {
        Write-IntegrationLog -Message "Le module source n'existe pas : $moduleSourcePath" -Level Error
        continue
    }
    
    # Copier le module vers le rÃ©pertoire des modules PowerShell
    if ($PSCmdlet.ShouldProcess($moduleDestPath, "Copier le module")) {
        # Supprimer le module existant si nÃ©cessaire
        if (Test-Path -Path $moduleDestPath -PathType Container) {
            Remove-Item -Path $moduleDestPath -Recurse -Force
            Write-IntegrationLog -Message "Module existant supprimÃ© : $moduleDestPath" -Level Info
        }
        
        # CrÃ©er le rÃ©pertoire de destination
        New-Item -Path $moduleDestPath -ItemType Directory -Force | Out-Null
        
        # Copier les fichiers du module
        Copy-Item -Path "$moduleSourcePath\*" -Destination $moduleDestPath -Recurse -Force
        Write-IntegrationLog -Message "Module copiÃ© : $moduleName" -Level Success
    }
}

# CrÃ©er un module principal ProcessManager qui importe tous les modules
$processManagerModulePath = Join-Path -Path $psModulesPath -ChildPath "ProcessManager.psm1"
$processManagerManifestPath = Join-Path -Path $psModulesPath -ChildPath "ProcessManager.psd1"

if ($PSCmdlet.ShouldProcess($processManagerModulePath, "CrÃ©er le module principal")) {
    # CrÃ©er le module principal
    $moduleContent = @"
<#
.SYNOPSIS
    Module principal du Process Manager.

.DESCRIPTION
    Ce module importe tous les modules du Process Manager et expose leurs fonctions.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les modules
Import-Module -Name "ManagerRegistrationService" -Force
Import-Module -Name "ManifestParser" -Force
Import-Module -Name "ValidationService" -Force
Import-Module -Name "DependencyResolver" -Force

# Exporter les fonctions des modules importÃ©s
Export-ModuleMember -Function *
"@
    
    Set-Content -Path $processManagerModulePath -Value $moduleContent -Encoding UTF8
    Write-IntegrationLog -Message "Module principal crÃ©Ã© : $processManagerModulePath" -Level Success
    
    # CrÃ©er le manifeste du module principal
    $manifestContent = @"
@{
    # Version du module
    ModuleVersion = '1.0.0'

    # ID utilisÃ© pour identifier de maniÃ¨re unique ce module
    GUID = '56789012-5678-5678-5678-567890123456'

    # Auteur de ce module
    Author = 'EMAIL_SENDER_1'

    # SociÃ©tÃ© ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'

    # DÃ©claration de copyright pour ce module
    Copyright = '(c) 2025 EMAIL_SENDER_1. Tous droits rÃ©servÃ©s.'

    # Description de la fonctionnalitÃ© fournie par ce module
    Description = 'Module principal du Process Manager qui intÃ¨gre tous les modules amÃ©liorÃ©s.'

    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Modules Ã  importer comme modules imbriquÃ©s du module spÃ©cifiÃ© dans RootModule/ModuleToProcess
    NestedModules = @(
        'ManagerRegistrationService',
        'ManifestParser',
        'ValidationService',
        'DependencyResolver'
    )

    # Fonctions Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une table vide si vous n'avez pas de fonctions Ã  exposer
    FunctionsToExport = @(
        'Register-Manager',
        'Unregister-Manager',
        'Update-Manager',
        'Get-RegisteredManager',
        'Find-Manager',
        'Get-ManagerManifest',
        'Test-ManifestValidity',
        'Convert-ToManifest',
        'Test-ManagerValidity',
        'Test-ManagerInterface',
        'Test-ManagerFunctionality',
        'Get-ManagerDependencies',
        'Test-DependenciesAvailability',
        'Resolve-DependencyConflicts',
        'Get-ManagerLoadOrder'
    )

    # Cmdlets Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une table vide si vous n'avez pas de cmdlets Ã  exposer
    CmdletsToExport = @()

    # Variables Ã  exporter Ã  partir de ce module
    VariablesToExport = @()

    # Alias Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une table vide si vous n'avez pas d'alias Ã  exposer
    AliasesToExport = @()

    # Ressources DSC Ã  exporter de ce module
    DscResourcesToExport = @()

    # Liste de tous les modules empaquetÃ©s avec ce module
    ModuleList = @(
        'ManagerRegistrationService',
        'ManifestParser',
        'ValidationService',
        'DependencyResolver'
    )

    # Liste de tous les fichiers empaquetÃ©s avec ce module
    FileList = @(
        'ProcessManager.psm1',
        'ProcessManager.psd1'
    )

    # DonnÃ©es privÃ©es Ã  transmettre au module spÃ©cifiÃ© dans RootModule/ModuleToProcess. Cela peut Ã©galement inclure une table de hachage PSData avec des mÃ©tadonnÃ©es de module supplÃ©mentaires utilisÃ©es par PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags appliquÃ©s Ã  ce module. Ils aident Ã  la dÃ©couverte des modules dans les galeries en ligne.
            Tags = @('ProcessManager', 'Manager', 'Registration', 'Validation', 'Dependency')

            # URL vers la licence de ce module.
            LicenseUri = ''

            # URL vers le site web principal de ce projet.
            ProjectUri = ''

            # URL vers une icÃ´ne reprÃ©sentant ce module.
            IconUri = ''

            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module ProcessManager.'
        }
    }
}
"@
    
    Set-Content -Path $processManagerManifestPath -Value $manifestContent -Encoding UTF8
    Write-IntegrationLog -Message "Manifeste du module principal crÃ©Ã© : $processManagerManifestPath" -Level Success
}

# VÃ©rifier l'intÃ©gration
$modulesVerified = $true
foreach ($moduleName in $moduleNames) {
    $moduleDestPath = Join-Path -Path $psModulesPath -ChildPath $moduleName
    if (-not (Test-Path -Path $moduleDestPath -PathType Container)) {
        Write-IntegrationLog -Message "Le module n'a pas Ã©tÃ© intÃ©grÃ© correctement : $moduleName" -Level Error
        $modulesVerified = $false
    }
}

if (-not (Test-Path -Path $processManagerModulePath -PathType Leaf)) {
    Write-IntegrationLog -Message "Le module principal n'a pas Ã©tÃ© crÃ©Ã© correctement : $processManagerModulePath" -Level Error
    $modulesVerified = $false
}

if (-not (Test-Path -Path $processManagerManifestPath -PathType Leaf)) {
    Write-IntegrationLog -Message "Le manifeste du module principal n'a pas Ã©tÃ© crÃ©Ã© correctement : $processManagerManifestPath" -Level Error
    $modulesVerified = $false
}

# Afficher le rÃ©sultat de l'intÃ©gration
if ($modulesVerified) {
    Write-IntegrationLog -Message "Tous les modules ont Ã©tÃ© intÃ©grÃ©s avec succÃ¨s." -Level Success
    Write-IntegrationLog -Message "Pour utiliser les modules, importez le module principal : Import-Module ProcessManager" -Level Info
} else {
    Write-IntegrationLog -Message "Certains modules n'ont pas Ã©tÃ© intÃ©grÃ©s correctement. VÃ©rifiez les erreurs ci-dessus." -Level Error
}

# Retourner le rÃ©sultat
return $modulesVerified

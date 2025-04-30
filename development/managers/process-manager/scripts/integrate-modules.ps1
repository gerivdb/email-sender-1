<#
.SYNOPSIS
    Script d'intégration des modules améliorés pour le Process Manager.

.DESCRIPTION
    Ce script intègre les modules améliorés (ManagerRegistrationService, ManifestParser,
    ValidationService, DependencyResolver) au Process Manager existant.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER ModulesPath
    Chemin vers le répertoire des modules. Par défaut, utilise le répertoire 'modules' dans le répertoire du Process Manager.

.PARAMETER Force
    Force l'intégration même si les modules sont déjà intégrés.

.EXAMPLE
    .\integrate-modules.ps1
    Intègre les modules améliorés au Process Manager.

.EXAMPLE
    .\integrate-modules.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force
    Force l'intégration des modules améliorés dans le répertoire spécifié.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de création: 2025-05-15
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

# Définir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$defaultModulesPath = Join-Path -Path $processManagerRoot -ChildPath "modules"
$modulesPath = if ($ModulesPath) { $ModulesPath } else { $defaultModulesPath }
$psModulesPath = Join-Path -Path $env:PSModulePath.Split(';')[0] -ChildPath "ProcessManager"

# Définir les noms des modules
$moduleNames = @(
    "ManagerRegistrationService",
    "ManifestParser",
    "ValidationService",
    "DependencyResolver"
)

# Fonction pour écrire des messages de journal
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
    
    # Définir la couleur en fonction du niveau
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

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-IntegrationLog -Message "Le répertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# Vérifier que le répertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-IntegrationLog -Message "Le répertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# Vérifier que le répertoire des modules existe
if (-not (Test-Path -Path $modulesPath -PathType Container)) {
    Write-IntegrationLog -Message "Le répertoire des modules n'existe pas : $modulesPath" -Level Error
    exit 1
}

# Vérifier si les modules sont déjà intégrés
$modulesIntegrated = $true
foreach ($moduleName in $moduleNames) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $moduleName
    if (-not (Test-Path -Path $modulePath -PathType Container)) {
        $modulesIntegrated = $false
        break
    }
}

if ($modulesIntegrated -and -not $Force) {
    Write-IntegrationLog -Message "Les modules sont déjà intégrés. Utilisez -Force pour forcer l'intégration." -Level Warning
    exit 0
}

# Créer le répertoire des modules PowerShell si nécessaire
if (-not (Test-Path -Path $psModulesPath -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($psModulesPath, "Créer le répertoire des modules PowerShell")) {
        New-Item -Path $psModulesPath -ItemType Directory -Force | Out-Null
        Write-IntegrationLog -Message "Répertoire des modules PowerShell créé : $psModulesPath" -Level Success
    }
}

# Intégrer chaque module
foreach ($moduleName in $moduleNames) {
    $moduleSourcePath = Join-Path -Path $modulesPath -ChildPath $moduleName
    $moduleDestPath = Join-Path -Path $psModulesPath -ChildPath $moduleName
    
    # Vérifier que le module source existe
    if (-not (Test-Path -Path $moduleSourcePath -PathType Container)) {
        Write-IntegrationLog -Message "Le module source n'existe pas : $moduleSourcePath" -Level Error
        continue
    }
    
    # Copier le module vers le répertoire des modules PowerShell
    if ($PSCmdlet.ShouldProcess($moduleDestPath, "Copier le module")) {
        # Supprimer le module existant si nécessaire
        if (Test-Path -Path $moduleDestPath -PathType Container) {
            Remove-Item -Path $moduleDestPath -Recurse -Force
            Write-IntegrationLog -Message "Module existant supprimé : $moduleDestPath" -Level Info
        }
        
        # Créer le répertoire de destination
        New-Item -Path $moduleDestPath -ItemType Directory -Force | Out-Null
        
        # Copier les fichiers du module
        Copy-Item -Path "$moduleSourcePath\*" -Destination $moduleDestPath -Recurse -Force
        Write-IntegrationLog -Message "Module copié : $moduleName" -Level Success
    }
}

# Créer un module principal ProcessManager qui importe tous les modules
$processManagerModulePath = Join-Path -Path $psModulesPath -ChildPath "ProcessManager.psm1"
$processManagerManifestPath = Join-Path -Path $psModulesPath -ChildPath "ProcessManager.psd1"

if ($PSCmdlet.ShouldProcess($processManagerModulePath, "Créer le module principal")) {
    # Créer le module principal
    $moduleContent = @"
<#
.SYNOPSIS
    Module principal du Process Manager.

.DESCRIPTION
    Ce module importe tous les modules du Process Manager et expose leurs fonctions.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de création: 2025-05-15
#>

# Importer les modules
Import-Module -Name "ManagerRegistrationService" -Force
Import-Module -Name "ManifestParser" -Force
Import-Module -Name "ValidationService" -Force
Import-Module -Name "DependencyResolver" -Force

# Exporter les fonctions des modules importés
Export-ModuleMember -Function *
"@
    
    Set-Content -Path $processManagerModulePath -Value $moduleContent -Encoding UTF8
    Write-IntegrationLog -Message "Module principal créé : $processManagerModulePath" -Level Success
    
    # Créer le manifeste du module principal
    $manifestContent = @"
@{
    # Version du module
    ModuleVersion = '1.0.0'

    # ID utilisé pour identifier de manière unique ce module
    GUID = '56789012-5678-5678-5678-567890123456'

    # Auteur de ce module
    Author = 'EMAIL_SENDER_1'

    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'

    # Déclaration de copyright pour ce module
    Copyright = '(c) 2025 EMAIL_SENDER_1. Tous droits réservés.'

    # Description de la fonctionnalité fournie par ce module
    Description = 'Module principal du Process Manager qui intègre tous les modules améliorés.'

    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Modules à importer comme modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    NestedModules = @(
        'ManagerRegistrationService',
        'ManifestParser',
        'ValidationService',
        'DependencyResolver'
    )

    # Fonctions à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une table vide si vous n'avez pas de fonctions à exposer
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

    # Cmdlets à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une table vide si vous n'avez pas de cmdlets à exposer
    CmdletsToExport = @()

    # Variables à exporter à partir de ce module
    VariablesToExport = @()

    # Alias à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une table vide si vous n'avez pas d'alias à exposer
    AliasesToExport = @()

    # Ressources DSC à exporter de ce module
    DscResourcesToExport = @()

    # Liste de tous les modules empaquetés avec ce module
    ModuleList = @(
        'ManagerRegistrationService',
        'ManifestParser',
        'ValidationService',
        'DependencyResolver'
    )

    # Liste de tous les fichiers empaquetés avec ce module
    FileList = @(
        'ProcessManager.psm1',
        'ProcessManager.psd1'
    )

    # Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess. Cela peut également inclure une table de hachage PSData avec des métadonnées de module supplémentaires utilisées par PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module. Ils aident à la découverte des modules dans les galeries en ligne.
            Tags = @('ProcessManager', 'Manager', 'Registration', 'Validation', 'Dependency')

            # URL vers la licence de ce module.
            LicenseUri = ''

            # URL vers le site web principal de ce projet.
            ProjectUri = ''

            # URL vers une icône représentant ce module.
            IconUri = ''

            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module ProcessManager.'
        }
    }
}
"@
    
    Set-Content -Path $processManagerManifestPath -Value $manifestContent -Encoding UTF8
    Write-IntegrationLog -Message "Manifeste du module principal créé : $processManagerManifestPath" -Level Success
}

# Vérifier l'intégration
$modulesVerified = $true
foreach ($moduleName in $moduleNames) {
    $moduleDestPath = Join-Path -Path $psModulesPath -ChildPath $moduleName
    if (-not (Test-Path -Path $moduleDestPath -PathType Container)) {
        Write-IntegrationLog -Message "Le module n'a pas été intégré correctement : $moduleName" -Level Error
        $modulesVerified = $false
    }
}

if (-not (Test-Path -Path $processManagerModulePath -PathType Leaf)) {
    Write-IntegrationLog -Message "Le module principal n'a pas été créé correctement : $processManagerModulePath" -Level Error
    $modulesVerified = $false
}

if (-not (Test-Path -Path $processManagerManifestPath -PathType Leaf)) {
    Write-IntegrationLog -Message "Le manifeste du module principal n'a pas été créé correctement : $processManagerManifestPath" -Level Error
    $modulesVerified = $false
}

# Afficher le résultat de l'intégration
if ($modulesVerified) {
    Write-IntegrationLog -Message "Tous les modules ont été intégrés avec succès." -Level Success
    Write-IntegrationLog -Message "Pour utiliser les modules, importez le module principal : Import-Module ProcessManager" -Level Info
} else {
    Write-IntegrationLog -Message "Certains modules n'ont pas été intégrés correctement. Vérifiez les erreurs ci-dessus." -Level Error
}

# Retourner le résultat
return $modulesVerified

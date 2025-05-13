#Requires -Version 5.1
<#
.SYNOPSIS
    Framework de test minimal pour les tests unitaires PowerShell.
.DESCRIPTION
    Ce module fournit un framework minimal pour standardiser les tests unitaires
    PowerShell dans le projet EMAIL_SENDER_1. Il s'intègre avec Pester et fournit
    des fonctionnalités supplémentaires pour faciliter l'écriture de tests.
.EXAMPLE
    Import-Module TestFramework
    Invoke-TestSetup -ModuleName "MonModule"
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

#region Variables globales
$script:ModuleName = 'TestFramework'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '1.0.0'
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config\$script:ModuleName.config.json"
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs\$script:ModuleName.log"
$script:TestDataPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
$script:TestResultsPath = Join-Path -Path $PSScriptRoot -ChildPath "results"
#endregion

#region Fonctions privées
# Importer toutes les fonctions privées
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction privée importée : $($Function.BaseName)"
    }
    catch {
        Write-Error "Échec de l'importation de la fonction privée $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions publiques
# Importer toutes les fonctions publiques
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction publique importée : $($Function.BaseName)"
    }
    catch {
        Write-Error "Échec de l'importation de la fonction publique $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions principales du framework

function Invoke-TestSetup {
    <#
    .SYNOPSIS
        Configure l'environnement de test pour un module.
    .DESCRIPTION
        Configure l'environnement de test pour un module spécifié, en important le module
        et en configurant les mocks de base.
    .PARAMETER ModuleName
        Nom du module à tester.
    .PARAMETER ModulePath
        Chemin du module à tester. Si non spécifié, le module sera recherché dans les chemins standards.
    .PARAMETER ImportModule
        Indique si le module doit être importé. Par défaut, le module est importé.
    .PARAMETER Force
        Force l'importation du module même s'il est déjà importé.
    .EXAMPLE
        Invoke-TestSetup -ModuleName "MonModule"
    .EXAMPLE
        Invoke-TestSetup -ModuleName "MonModule" -ModulePath "C:\Modules\MonModule\MonModule.psm1" -Force
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$ImportModule = $true,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si Pester est installé
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
    }

    # Déterminer le chemin du module
    if (-not $ModulePath) {
        # Rechercher le module dans les chemins standards
        $moduleInfo = Get-Module -Name $ModuleName -ListAvailable
        if ($moduleInfo) {
            $ModulePath = $moduleInfo[0].Path
        }
        else {
            # Rechercher dans le répertoire courant et ses sous-répertoires
            $moduleFiles = Get-ChildItem -Path (Get-Location) -Recurse -Filter "$ModuleName.psm1" -ErrorAction SilentlyContinue
            if ($moduleFiles) {
                $ModulePath = $moduleFiles[0].FullName
            }
            else {
                Write-Error "Module '$ModuleName' non trouvé. Spécifiez le chemin avec -ModulePath."
                return $false
            }
        }
    }

    # Vérifier que le module existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-Error "Le chemin du module '$ModulePath' n'existe pas."
        return $false
    }

    # Importer le module si demandé
    if ($ImportModule) {
        try {
            if ($Force) {
                Import-Module -Name $ModulePath -Force -ErrorAction Stop
            }
            else {
                Import-Module -Name $ModulePath -ErrorAction Stop
            }
            Write-Verbose "Module '$ModuleName' importé avec succès depuis '$ModulePath'."
        }
        catch {
            Write-Error "Erreur lors de l'importation du module '$ModuleName' : $_"
            return $false
        }
    }

    # Retourner les informations sur le module
    return @{
        ModuleName = $ModuleName
        ModulePath = $ModulePath
        Imported = $ImportModule
        Functions = Get-Command -Module $ModuleName -CommandType Function
    }
}

function New-TestEnvironment {
    <#
    .SYNOPSIS
        Crée un environnement de test temporaire.
    .DESCRIPTION
        Crée un environnement de test temporaire avec des fichiers et des dossiers pour les tests.
    .PARAMETER TestName
        Nom du test pour lequel créer l'environnement.
    .PARAMETER Files
        Hashtable des fichiers à créer dans l'environnement de test. Les clés sont les noms des fichiers
        et les valeurs sont le contenu des fichiers.
    .PARAMETER Folders
        Tableau des dossiers à créer dans l'environnement de test.
    .EXAMPLE
        $env = New-TestEnvironment -TestName "MonTest" -Files @{ "test.txt" = "Contenu du fichier" } -Folders @("dossier1", "dossier2")
        # Utiliser l'environnement
        $env.Cleanup()
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Files = @{},

        [Parameter(Mandatory = $false)]
        [string[]]$Folders = @()
    )

    # Créer un dossier temporaire pour le test
    $tempPath = Join-Path -Path $env:TEMP -ChildPath "TestEnv_$TestName`_$(Get-Random)"
    New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
    Write-Verbose "Environnement de test créé : $tempPath"

    # Créer les dossiers demandés
    foreach ($folder in $Folders) {
        $folderPath = Join-Path -Path $tempPath -ChildPath $folder
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Verbose "Dossier créé : $folderPath"
    }

    # Créer les fichiers demandés
    foreach ($file in $Files.Keys) {
        $filePath = Join-Path -Path $tempPath -ChildPath $file
        $fileContent = $Files[$file]
        
        # Créer le dossier parent si nécessaire
        $parentFolder = Split-Path -Path $filePath -Parent
        if (-not (Test-Path -Path $parentFolder)) {
            New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
        }
        
        # Créer le fichier
        $fileContent | Out-File -FilePath $filePath -Encoding utf8 -Force
        Write-Verbose "Fichier créé : $filePath"
    }

    # Fonction de nettoyage
    $cleanup = {
        param($path)
        if (Test-Path -Path $path) {
            Remove-Item -Path $path -Recurse -Force
            Write-Verbose "Environnement de test nettoyé : $path"
        }
    }

    # Retourner les informations sur l'environnement
    return @{
        Path = $tempPath
        Files = $Files.Keys | ForEach-Object { Join-Path -Path $tempPath -ChildPath $_ }
        Folders = $Folders | ForEach-Object { Join-Path -Path $tempPath -ChildPath $_ }
        Cleanup = { & $cleanup $tempPath }
    }
}

function Invoke-TestCleanup {
    <#
    .SYNOPSIS
        Nettoie l'environnement après les tests.
    .DESCRIPTION
        Nettoie l'environnement après les tests en supprimant les modules importés
        et en nettoyant les ressources temporaires.
    .PARAMETER ModuleName
        Nom du module à nettoyer.
    .PARAMETER RemoveModule
        Indique si le module doit être supprimé de la session. Par défaut, le module est supprimé.
    .EXAMPLE
        Invoke-TestCleanup -ModuleName "MonModule"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveModule = $true
    )

    # Supprimer le module si demandé
    if ($RemoveModule) {
        try {
            Remove-Module -Name $ModuleName -ErrorAction SilentlyContinue
            Write-Verbose "Module '$ModuleName' supprimé de la session."
        }
        catch {
            Write-Warning "Erreur lors de la suppression du module '$ModuleName' : $_"
        }
    }

    # Nettoyer les mocks
    try {
        # Cette fonction est spécifique à Pester
        if (Get-Command -Name 'Remove-MockAll' -ErrorAction SilentlyContinue) {
            Remove-MockAll
            Write-Verbose "Tous les mocks ont été supprimés."
        }
    }
    catch {
        Write-Warning "Erreur lors du nettoyage des mocks : $_"
    }
}

#endregion

#region Initialisation du module
function Initialize-TestFrameworkModule {
    <#
    .SYNOPSIS
        Initialise le module TestFramework.
    .DESCRIPTION
        Crée les dossiers nécessaires et initialise les configurations du module.
    .EXAMPLE
        Initialize-TestFrameworkModule
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Créer les dossiers nécessaires s'ils n'existent pas
    $Folders = @(
        (Join-Path -Path $script:ModuleRoot -ChildPath "config"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "logs"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "data"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "results")
    )

    foreach ($Folder in $Folders) {
        if (-not (Test-Path -Path $Folder)) {
            if ($PSCmdlet.ShouldProcess($Folder, "Créer le dossier")) {
                New-Item -Path $Folder -ItemType Directory -Force | Out-Null
                Write-Verbose "Dossier créé : $Folder"
            }
        }
    }

    # Initialiser le fichier de configuration s'il n'existe pas
    if (-not (Test-Path -Path $script:ConfigPath)) {
        if ($PSCmdlet.ShouldProcess($script:ConfigPath, "Créer le fichier de configuration")) {
            $DefaultConfig = @{
                ModuleName = $script:ModuleName
                Version = $script:ModuleVersion
                LogLevel = "Info"
                LogPath = $script:LogPath
                Enabled = $true
                Settings = @{
                    TestDataPath = $script:TestDataPath
                    TestResultsPath = $script:TestResultsPath
                    DefaultTimeout = 30
                    PesterVersion = "5.0.0"
                }
            }

            $DefaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $script:ConfigPath -Encoding utf8
            Write-Verbose "Fichier de configuration créé : $script:ConfigPath"
        }
    }
}
#endregion

#region Exportation des fonctions
# Exporter uniquement les fonctions publiques
$FunctionsToExport = @(
    'Invoke-TestSetup'
    'New-TestEnvironment'
    'Invoke-TestCleanup'
) + $PublicFunctions.BaseName

Export-ModuleMember -Function $FunctionsToExport -Variable @()
#endregion

# Initialiser le module lors du chargement
Initialize-TestFrameworkModule

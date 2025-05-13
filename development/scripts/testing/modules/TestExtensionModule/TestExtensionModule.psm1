#Requires -Version 5.1
<#
.SYNOPSIS
    Test Extension Module (Extension).
.DESCRIPTION
    Module PowerShell d'extension pour les tests.
    Ce module d'extension est conçu pour étendre les fonctionnalités d'autres modules.
.EXAMPLE
    Import-Module TestExtensionModule
    Get-Command -Module TestExtensionModule
.NOTES
    Version: 1.0.0
    Auteur: Test User
    Date de création: 2025-05-15
#>

#region Variables globales
$script:ModuleName = 'TestExtensionModule'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '1.0.0'
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config\$script:ModuleName.config.json"
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs\$script:ModuleName.log"
$script:ExtendedModules = @()
$script:ExtensionPoints = @{}
#endregion

#region Fonctions d'extension
function Register-ExtensionPoint {
    <#
    .SYNOPSIS
        Enregistre un point d'extension dans le module.
    .DESCRIPTION
        Enregistre un point d'extension qui peut être utilisé par d'autres modules pour étendre les fonctionnalités.
    .PARAMETER Name
        Nom du point d'extension.
    .PARAMETER Description
        Description du point d'extension.
    .PARAMETER ScriptBlock
        Script à exécuter lorsque le point d'extension est appelé.
    .EXAMPLE
        Register-ExtensionPoint -Name "OnDataProcessed" -Description "Exécuté après le traitement des données" -ScriptBlock { param($data) Write-Verbose "Données traitées: $data" }
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [scriptblock]$ScriptBlock = {}
    )

    if ($PSCmdlet.ShouldProcess("Module $script:ModuleName", "Enregistrer le point d'extension '$Name'")) {
        $script:ExtensionPoints[$Name] = @{
            Name = $Name
            Description = $Description
            ScriptBlock = $ScriptBlock
            Handlers = @()
            Enabled = $true
            CreatedAt = [DateTime]::Now
        }
        Write-Verbose "Point d'extension '$Name' enregistré dans le module $script:ModuleName"
    }
}

function Register-ExtensionHandler {
    <#
    .SYNOPSIS
        Enregistre un gestionnaire pour un point d'extension.
    .DESCRIPTION
        Enregistre un gestionnaire qui sera exécuté lorsqu'un point d'extension spécifique est appelé.
    .PARAMETER ExtensionPoint
        Nom du point d'extension.
    .PARAMETER Name
        Nom du gestionnaire.
    .PARAMETER ScriptBlock
        Script à exécuter lorsque le point d'extension est appelé.
    .PARAMETER Priority
        Priorité du gestionnaire (les valeurs plus basses sont exécutées en premier).
    .EXAMPLE
        Register-ExtensionHandler -ExtensionPoint "OnDataProcessed" -Name "LogData" -ScriptBlock { param($data) Write-Log "Données: $data" } -Priority 10
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExtensionPoint,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$Priority = 100
    )

    if (-not $script:ExtensionPoints.ContainsKey($ExtensionPoint)) {
        Write-Error "Le point d'extension '$ExtensionPoint' n'existe pas"
        return
    }

    if ($PSCmdlet.ShouldProcess("Point d'extension '$ExtensionPoint'", "Enregistrer le gestionnaire '$Name'")) {
        $handler = @{
            Name = $Name
            ScriptBlock = $ScriptBlock
            Priority = $Priority
            Enabled = $true
            RegisteredAt = [DateTime]::Now
        }

        $script:ExtensionPoints[$ExtensionPoint].Handlers += $handler
        # Trier les gestionnaires par priorité
        $script:ExtensionPoints[$ExtensionPoint].Handlers = $script:ExtensionPoints[$ExtensionPoint].Handlers | Sort-Object -Property Priority
        Write-Verbose "Gestionnaire '$Name' enregistré pour le point d'extension '$ExtensionPoint' avec priorité $Priority"
    }
}

function Invoke-ExtensionPoint {
    <#
    .SYNOPSIS
        Invoque un point d'extension.
    .DESCRIPTION
        Exécute tous les gestionnaires enregistrés pour un point d'extension spécifique.
    .PARAMETER Name
        Nom du point d'extension à invoquer.
    .PARAMETER Arguments
        Arguments à passer aux gestionnaires.
    .EXAMPLE
        Invoke-ExtensionPoint -Name "OnDataProcessed" -Arguments @{ Data = $processedData }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [hashtable]$Arguments = @{}
    )

    if (-not $script:ExtensionPoints.ContainsKey($Name)) {
        Write-Error "Le point d'extension '$Name' n'existe pas"
        return
    }

    if (-not $script:ExtensionPoints[$Name].Enabled) {
        Write-Verbose "Le point d'extension '$Name' est désactivé"
        return
    }

    Write-Verbose "Invocation du point d'extension '$Name' avec $(($script:ExtensionPoints[$Name].Handlers | Where-Object { $_.Enabled }).Count) gestionnaires actifs"

    # Exécuter le script du point d'extension
    try {
        & $script:ExtensionPoints[$Name].ScriptBlock @Arguments
    }
    catch {
        Write-Error "Erreur lors de l'exécution du script du point d'extension '$Name': $_"
    }

    # Exécuter tous les gestionnaires actifs
    foreach ($handler in ($script:ExtensionPoints[$Name].Handlers | Where-Object { $_.Enabled })) {
        try {
            Write-Verbose "Exécution du gestionnaire '$($handler.Name)' pour le point d'extension '$Name'"
            & $handler.ScriptBlock @Arguments
        }
        catch {
            Write-Error "Erreur lors de l'exécution du gestionnaire '$($handler.Name)' pour le point d'extension '$Name': $_"
        }
    }
}

function Get-ExtensionPoint {
    <#
    .SYNOPSIS
        Récupère les informations sur les points d'extension.
    .DESCRIPTION
        Récupère les informations sur tous les points d'extension ou sur un point d'extension spécifique.
    .PARAMETER Name
        Nom du point d'extension à récupérer. Si non spécifié, tous les points d'extension sont retournés.
    .EXAMPLE
        Get-ExtensionPoint
        Get-ExtensionPoint -Name "OnDataProcessed"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    if ($Name) {
        if ($script:ExtensionPoints.ContainsKey($Name)) {
            return $script:ExtensionPoints[$Name]
        }
        else {
            Write-Error "Le point d'extension '$Name' n'existe pas"
            return $null
        }
    }
    else {
        return $script:ExtensionPoints
    }
}

function Enable-ExtensionPoint {
    <#
    .SYNOPSIS
        Active un point d'extension.
    .DESCRIPTION
        Active un point d'extension qui a été désactivé.
    .PARAMETER Name
        Nom du point d'extension à activer.
    .EXAMPLE
        Enable-ExtensionPoint -Name "OnDataProcessed"
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $script:ExtensionPoints.ContainsKey($Name)) {
        Write-Error "Le point d'extension '$Name' n'existe pas"
        return
    }

    if ($PSCmdlet.ShouldProcess("Point d'extension '$Name'", "Activer")) {
        $script:ExtensionPoints[$Name].Enabled = $true
        Write-Verbose "Point d'extension '$Name' activé"
    }
}

function Disable-ExtensionPoint {
    <#
    .SYNOPSIS
        Désactive un point d'extension.
    .DESCRIPTION
        Désactive un point d'extension pour empêcher son exécution.
    .PARAMETER Name
        Nom du point d'extension à désactiver.
    .EXAMPLE
        Disable-ExtensionPoint -Name "OnDataProcessed"
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $script:ExtensionPoints.ContainsKey($Name)) {
        Write-Error "Le point d'extension '$Name' n'existe pas"
        return
    }

    if ($PSCmdlet.ShouldProcess("Point d'extension '$Name'", "Désactiver")) {
        $script:ExtensionPoints[$Name].Enabled = $false
        Write-Verbose "Point d'extension '$Name' désactivé"
    }
}

function Register-ExtendedModule {
    <#
    .SYNOPSIS
        Enregistre un module étendu.
    .DESCRIPTION
        Enregistre un module que ce module d'extension étend.
    .PARAMETER Name
        Nom du module étendu.
    .PARAMETER Version
        Version du module étendu.
    .PARAMETER ExtensionPoints
        Points d'extension fournis par le module étendu.
    .EXAMPLE
        Register-ExtendedModule -Name "CoreModule" -Version "1.0.0" -ExtensionPoints @("OnDataProcessed", "OnConfigLoaded")
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Version = "1.0.0",

        [Parameter(Mandatory = $false)]
        [string[]]$ExtensionPoints = @()
    )

    if ($PSCmdlet.ShouldProcess("Module $Name", "Enregistrer comme module étendu")) {
        $extendedModule = @{
            Name = $Name
            Version = $Version
            ExtensionPoints = $ExtensionPoints
            RegisteredAt = [DateTime]::Now
        }

        $script:ExtendedModules += $extendedModule
        Write-Verbose "Module '$Name' v$Version enregistré comme module étendu"
    }
}

function Get-ExtendedModule {
    <#
    .SYNOPSIS
        Récupère les informations sur les modules étendus.
    .DESCRIPTION
        Récupère les informations sur tous les modules étendus ou sur un module étendu spécifique.
    .PARAMETER Name
        Nom du module étendu à récupérer. Si non spécifié, tous les modules étendus sont retournés.
    .EXAMPLE
        Get-ExtendedModule
        Get-ExtendedModule -Name "CoreModule"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    if ($Name) {
        return $script:ExtendedModules | Where-Object { $_.Name -eq $Name }
    }
    else {
        return $script:ExtendedModules
    }
}
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

#region Initialisation du module
function Initialize-TestExtensionModule {
    <#
    .SYNOPSIS
        Initialise le module Test Extension Module.
    .DESCRIPTION
        Crée les dossiers nécessaires et initialise les configurations du module.
    .EXAMPLE
        Initialize-TestExtensionModule
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Créer les dossiers nécessaires s'ils n'existent pas
    $Folders = @(
        (Join-Path -Path $script:ModuleRoot -ChildPath "config"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "logs"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "data"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "extensions")
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
                Extensions = @{
                    AutoLoadExtensions = $true
                    ExtensionsPath = (Join-Path -Path $script:ModuleRoot -ChildPath "extensions")
                }
                Settings = @{
                    MaxLogSize = 10MB
                    MaxLogAge = 30
                    DefaultTimeout = 30
                }
            }

            $DefaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $script:ConfigPath -Encoding utf8
            Write-Verbose "Fichier de configuration créé : $script:ConfigPath"
        }
    }

    # Enregistrer les points d'extension par défaut
    Register-ExtensionPoint -Name "OnModuleLoad" -Description "Exécuté lors du chargement du module"
    Register-ExtensionPoint -Name "OnModuleUnload" -Description "Exécuté lors du déchargement du module"
    Register-ExtensionPoint -Name "OnConfigLoaded" -Description "Exécuté après le chargement de la configuration"

    # Charger les extensions si configuré
    try {
        $config = Get-Content -Path $script:ConfigPath -Raw | ConvertFrom-Json
        if ($config.Extensions.AutoLoadExtensions) {
            $extensionsPath = $config.Extensions.ExtensionsPath
            if (Test-Path -Path $extensionsPath) {
                $extensions = Get-ChildItem -Path $extensionsPath -Filter "*.ps1" -File
                foreach ($extension in $extensions) {
                    try {
                        Write-Verbose "Chargement de l'extension : $($extension.Name)"
                        . $extension.FullName
                    }
                    catch {
                        Write-Error "Échec du chargement de l'extension $($extension.FullName): $_"
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Erreur lors du chargement des extensions : $_"
    }

    # Invoquer le point d'extension OnModuleLoad
    Invoke-ExtensionPoint -Name "OnModuleLoad" -Arguments @{ ModuleName = $script:ModuleName; Version = $script:ModuleVersion }
}
#endregion

#region Exportation des fonctions
# Exporter les fonctions publiques et les fonctions d'extension
$FunctionsToExport = @(
    $PublicFunctions.BaseName
    'Register-ExtensionPoint'
    'Register-ExtensionHandler'
    'Invoke-ExtensionPoint'
    'Get-ExtensionPoint'
    'Enable-ExtensionPoint'
    'Disable-ExtensionPoint'
    'Register-ExtendedModule'
    'Get-ExtendedModule'
)
Export-ModuleMember -Function $FunctionsToExport -Variable @()
#endregion

#region Nettoyage à la décharge du module
# Enregistrer un script de nettoyage à exécuter lorsque le module est déchargé
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Invoquer le point d'extension OnModuleUnload
    Invoke-ExtensionPoint -Name "OnModuleUnload" -Arguments @{ ModuleName = $script:ModuleName; Version = $script:ModuleVersion }
}
#endregion

# Initialiser le module lors du chargement
Initialize-TestExtensionModule

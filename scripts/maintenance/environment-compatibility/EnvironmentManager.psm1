<#
.SYNOPSIS
    Module pour la gestion de la compatibilité entre environnements.

.DESCRIPTION
    Ce module fournit des fonctions pour détecter l'environnement d'exécution,
    standardiser la gestion des chemins et fournir des wrappers pour les commandes
    spécifiques à l'OS.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

#region Variables globales

# Variables pour stocker les informations sur l'environnement
$script:EnvironmentInfo = $null
$script:IsInitialized = $false

#endregion

#region Fonctions d'initialisation

<#
.SYNOPSIS
    Initialise le module EnvironmentManager.

.DESCRIPTION
    Cette fonction initialise le module EnvironmentManager en détectant
    l'environnement d'exécution et en configurant les paramètres nécessaires.

.PARAMETER Force
    Force la réinitialisation du module même s'il a déjà été initialisé.

.EXAMPLE
    Initialize-EnvironmentManager

.EXAMPLE
    Initialize-EnvironmentManager -Force
#>
function Initialize-EnvironmentManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($script:IsInitialized -and -not $Force) {
        Write-Verbose "Le module EnvironmentManager est déjà initialisé."
        return
    }

    # Détecter l'environnement d'exécution
    $script:EnvironmentInfo = Get-EnvironmentInfo
    $script:IsInitialized = $true

    Write-Verbose "Module EnvironmentManager initialisé avec succès."
    Write-Verbose "Système d'exploitation: $($script:EnvironmentInfo.OSName)"
    Write-Verbose "Version PowerShell: $($script:EnvironmentInfo.PSVersion)"
}

#endregion

#region Fonctions de détection d'environnement

<#
.SYNOPSIS
    Obtient des informations détaillées sur l'environnement d'exécution.

.DESCRIPTION
    Cette fonction détecte l'environnement d'exécution (système d'exploitation,
    version de PowerShell, etc.) et retourne un objet contenant ces informations.

.EXAMPLE
    $env = Get-EnvironmentInfo
    if ($env.IsWindows) {
        # Code spécifique à Windows
    }

.OUTPUTS
    System.Management.Automation.PSObject
#>
function Get-EnvironmentInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    # Créer l'objet d'informations sur l'environnement
    $envInfo = [PSCustomObject]@{
        # Informations sur le système d'exploitation
        OSVersion = [System.Environment]::OSVersion
        OSPlatform = [System.Environment]::OSVersion.Platform
        OSDescription = if ($PSVersionTable.PSVersion.Major -ge 6) {
            [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        } else {
            ""
        }
        OSName = ""
        IsWindows = $false
        IsLinux = $false
        IsMacOS = $false
        IsUnix = $false
        Is64Bit = [System.Environment]::Is64BitOperatingSystem
        Is64BitProcess = [System.Environment]::Is64BitProcess

        # Informations sur PowerShell
        PSVersion = $PSVersionTable.PSVersion
        PSEdition = $PSVersionTable.PSEdition
        IsCoreCLR = $false
        IsDesktopCLR = $false
        IsWindowsPowerShell = $false
        IsPowerShellCore = $false

        # Informations sur le chemin
        PathSeparator = [System.IO.Path]::DirectorySeparatorChar
        AltPathSeparator = [System.IO.Path]::AltDirectorySeparatorChar
        NewLine = [System.Environment]::NewLine
    }

    # Déterminer le type de système d'exploitation
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core a des variables intégrées pour le système d'exploitation
        $envInfo.IsWindows = $IsWindows
        $envInfo.IsLinux = $IsLinux
        $envInfo.IsMacOS = $IsMacOS
        $envInfo.IsUnix = $IsLinux -or $IsMacOS
    }
    else {
        # Windows PowerShell s'exécute uniquement sur Windows
        $envInfo.IsWindows = $true
        $envInfo.IsLinux = $false
        $envInfo.IsMacOS = $false
        $envInfo.IsUnix = $false
    }

    # Déterminer le type de runtime PowerShell
    $envInfo.IsCoreCLR = $PSVersionTable.PSVersion.Major -ge 6
    $envInfo.IsDesktopCLR = -not $envInfo.IsCoreCLR
    $envInfo.IsWindowsPowerShell = $PSVersionTable.PSVersion.Major -le 5
    $envInfo.IsPowerShellCore = $PSVersionTable.PSVersion.Major -ge 6

    # Déterminer le nom du système d'exploitation
    if ($envInfo.IsWindows) {
        $envInfo.OSName = "Windows"
    }
    elseif ($envInfo.IsLinux) {
        $envInfo.OSName = "Linux"
    }
    elseif ($envInfo.IsMacOS) {
        $envInfo.OSName = "macOS"
    }
    else {
        $envInfo.OSName = "Unknown"
    }

    return $envInfo
}

<#
.SYNOPSIS
    Vérifie la compatibilité avec un environnement cible.

.DESCRIPTION
    Cette fonction vérifie si l'environnement d'exécution actuel est compatible
    avec les exigences spécifiées.

.PARAMETER TargetOS
    Le système d'exploitation cible. Valeurs possibles : "Windows", "Linux", "MacOS", "Any".

.PARAMETER MinimumPSVersion
    La version minimale de PowerShell requise.

.PARAMETER PSEdition
    L'édition de PowerShell requise. Valeurs possibles : "Desktop", "Core", "Any".

.PARAMETER ThrowOnIncompatible
    Si spécifié, lance une exception si l'environnement n'est pas compatible.

.EXAMPLE
    $result = Test-EnvironmentCompatibility -TargetOS "Windows" -MinimumPSVersion "5.1"
    if ($result.IsCompatible) {
        # Code compatible
    }

.OUTPUTS
    System.Management.Automation.PSObject
#>
function Test-EnvironmentCompatibility {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Windows", "Linux", "MacOS", "Any")]
        [string]$TargetOS = "Any",

        [Parameter(Mandatory = $false)]
        [version]$MinimumPSVersion = "3.0",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Desktop", "Core", "Any")]
        [string]$PSEdition = "Any",

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnIncompatible
    )

    # Vérifier si le module est initialisé
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Obtenir les informations sur l'environnement actuel
    $envInfo = $script:EnvironmentInfo

    # Vérifier la compatibilité du système d'exploitation
    $osCompatible = switch ($TargetOS) {
        "Windows" { $envInfo.IsWindows }
        "Linux" { $envInfo.IsLinux }
        "MacOS" { $envInfo.IsMacOS }
        "Any" { $true }
        default { $true }
    }

    # Vérifier la compatibilité de la version PowerShell
    $psVersionCompatible = $envInfo.PSVersion -ge $MinimumPSVersion

    # Vérifier la compatibilité de l'édition PowerShell
    $psEditionCompatible = switch ($PSEdition) {
        "Desktop" { $envInfo.IsDesktopCLR }
        "Core" { $envInfo.IsCoreCLR }
        "Any" { $true }
        default { $true }
    }

    # Déterminer la compatibilité globale
    $isCompatible = $osCompatible -and $psVersionCompatible -and $psEditionCompatible

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        IsCompatible = $isCompatible
        OSCompatible = $osCompatible
        PSVersionCompatible = $psVersionCompatible
        PSEditionCompatible = $psEditionCompatible
        Environment = $envInfo
        IncompatibilityReasons = @()
    }

    # Ajouter les raisons d'incompatibilité
    if (-not $osCompatible) {
        $result.IncompatibilityReasons += "Le système d'exploitation actuel ($($envInfo.OSName)) n'est pas compatible avec la cible ($TargetOS)."
    }

    if (-not $psVersionCompatible) {
        $result.IncompatibilityReasons += "La version PowerShell actuelle ($($envInfo.PSVersion)) est inférieure à la version minimale requise ($MinimumPSVersion)."
    }

    if (-not $psEditionCompatible) {
        $result.IncompatibilityReasons += "L'édition PowerShell actuelle ($($envInfo.PSEdition)) n'est pas compatible avec l'édition requise ($PSEdition)."
    }

    # Lancer une exception si demandé
    if ($ThrowOnIncompatible -and -not $isCompatible) {
        $message = "L'environnement n'est pas compatible : $($result.IncompatibilityReasons -join ' ')"
        throw $message
    }

    return $result
}

#endregion

#region Fonctions de gestion des chemins

<#
.SYNOPSIS
    Normalise un chemin pour la compatibilité entre environnements.

.DESCRIPTION
    Cette fonction normalise un chemin en utilisant le séparateur de chemin
    approprié pour l'environnement cible.

.PARAMETER Path
    Le chemin à normaliser.

.PARAMETER TargetOS
    Le système d'exploitation cible. Valeurs possibles : "Windows", "Linux", "MacOS", "Auto".

.EXAMPLE
    $normalizedPath = ConvertTo-CrossPlatformPath -Path "C:\Users\user\Documents"
    # Retourne "C:/Users/user/Documents" sur Linux/macOS

.EXAMPLE
    $normalizedPath = ConvertTo-CrossPlatformPath -Path "/home/user/documents" -TargetOS "Windows"
    # Retourne "\home\user\documents"

.OUTPUTS
    System.String
#>
function ConvertTo-CrossPlatformPath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Windows", "Linux", "MacOS", "Auto")]
        [string]$TargetOS = "Auto"
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return ""
    }

    # Vérifier si le module est initialisé
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Déterminer le séparateur de chemin cible
    $targetSeparator = switch ($TargetOS) {
        "Windows" { "\" }
        "Linux" { "/" }
        "MacOS" { "/" }
        default {
            if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
        }
    }

    # Normaliser les séparateurs de chemin
    $normalizedPath = $Path.Replace("\", $targetSeparator).Replace("/", $targetSeparator)

    return $normalizedPath
}

<#
.SYNOPSIS
    Vérifie si un chemin existe de manière compatible entre environnements.

.DESCRIPTION
    Cette fonction vérifie si un chemin existe en utilisant les méthodes
    appropriées pour l'environnement d'exécution.

.PARAMETER Path
    Le chemin à vérifier.

.PARAMETER PathType
    Le type de chemin à vérifier. Valeurs possibles : "Any", "Leaf", "Container".

.EXAMPLE
    $exists = Test-CrossPlatformPath -Path "C:\Users\user\Documents"
    if ($exists) {
        # Le chemin existe
    }

.EXAMPLE
    $isFile = Test-CrossPlatformPath -Path "/home/user/document.txt" -PathType "Leaf"
    if ($isFile) {
        # Le chemin est un fichier
    }

.OUTPUTS
    System.Boolean
#>
function Test-CrossPlatformPath {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Any", "Leaf", "Container")]
        [string]$PathType = "Any"
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return $false
    }

    # Vérifier si le module est initialisé
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Normaliser le chemin pour l'environnement actuel
    $normalizedPath = ConvertTo-CrossPlatformPath -Path $Path

    # Vérifier si le chemin existe
    $exists = switch ($PathType) {
        "Leaf" { Test-Path -Path $normalizedPath -PathType Leaf }
        "Container" { Test-Path -Path $normalizedPath -PathType Container }
        default { Test-Path -Path $normalizedPath }
    }

    return $exists
}

<#
.SYNOPSIS
    Joint des chemins de manière compatible entre environnements.

.DESCRIPTION
    Cette fonction joint des chemins en utilisant le séparateur de chemin
    approprié pour l'environnement cible.

.PARAMETER Path
    Le chemin de base.

.PARAMETER ChildPath
    Les chemins enfants à joindre au chemin de base.

.PARAMETER TargetOS
    Le système d'exploitation cible. Valeurs possibles : "Windows", "Linux", "MacOS", "Auto".

.EXAMPLE
    $path = Join-CrossPlatformPath -Path "C:\Users" -ChildPath "user", "Documents"
    # Retourne "C:\Users\user\Documents" sur Windows

.EXAMPLE
    $path = Join-CrossPlatformPath -Path "/home" -ChildPath "user", "documents" -TargetOS "Linux"
    # Retourne "/home/user/documents"

.OUTPUTS
    System.String
#>
function Join-CrossPlatformPath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string[]]$ChildPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Windows", "Linux", "MacOS", "Auto")]
        [string]$TargetOS = "Auto"
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return ""
    }

    # Vérifier si le module est initialisé
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Déterminer le séparateur de chemin cible
    $targetSeparator = switch ($TargetOS) {
        "Windows" { "\" }
        "Linux" { "/" }
        "MacOS" { "/" }
        default {
            if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
        }
    }

    # Normaliser le chemin de base
    $normalizedPath = ConvertTo-CrossPlatformPath -Path $Path -TargetOS $TargetOS

    # Joindre les chemins enfants
    foreach ($child in $ChildPath) {
        $normalizedChild = ConvertTo-CrossPlatformPath -Path $child -TargetOS $TargetOS

        # S'assurer que le chemin de base se termine par un séparateur
        if (-not $normalizedPath.EndsWith($targetSeparator)) {
            $normalizedPath += $targetSeparator
        }

        # S'assurer que le chemin enfant ne commence pas par un séparateur
        if ($normalizedChild.StartsWith($targetSeparator)) {
            $normalizedChild = $normalizedChild.Substring(1)
        }

        $normalizedPath += $normalizedChild
    }

    return $normalizedPath
}

#endregion

#region Fonctions de wrappers de commandes

<#
.SYNOPSIS
    Exécute une commande avec les adaptations nécessaires selon l'OS.

.DESCRIPTION
    Cette fonction exécute une commande en utilisant la version appropriée
    pour l'environnement d'exécution.

.PARAMETER WindowsCommand
    La commande à exécuter sur Windows.

.PARAMETER UnixCommand
    La commande à exécuter sur Linux/Unix.

.PARAMETER MacOSCommand
    La commande à exécuter sur macOS. Si non spécifiée, utilise UnixCommand.

.PARAMETER PassThru
    Si spécifié, retourne la commande à exécuter sans l'exécuter.

.EXAMPLE
    Invoke-CrossPlatformCommand -WindowsCommand "dir" -UnixCommand "ls -la"
    # Exécute "dir" sur Windows et "ls -la" sur Linux/macOS

.EXAMPLE
    $command = Invoke-CrossPlatformCommand -WindowsCommand "ipconfig" -UnixCommand "ifconfig" -PassThru
    # Retourne "ipconfig" sur Windows et "ifconfig" sur Linux/macOS sans l'exécuter

.OUTPUTS
    System.Object
#>
function Invoke-CrossPlatformCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$WindowsCommand,

        [Parameter(Mandatory = $true)]
        [string]$UnixCommand,

        [Parameter(Mandatory = $false)]
        [string]$MacOSCommand = "",

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Vérifier si le module est initialisé
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Déterminer la commande à exécuter
    $command = if ($script:EnvironmentInfo.IsWindows) {
        $WindowsCommand
    }
    elseif ($script:EnvironmentInfo.IsMacOS -and -not [string]::IsNullOrEmpty($MacOSCommand)) {
        $MacOSCommand
    }
    else {
        $UnixCommand
    }

    # Retourner la commande ou l'exécuter
    if ($PassThru) {
        return $command
    }
    else {
        return Invoke-Expression -Command $command
    }
}

<#
.SYNOPSIS
    Obtient le contenu d'un fichier de manière compatible entre environnements.

.DESCRIPTION
    Cette fonction lit le contenu d'un fichier en utilisant l'encodage approprié
    pour l'environnement d'exécution.

.PARAMETER Path
    Le chemin du fichier à lire.

.PARAMETER Encoding
    L'encodage à utiliser. Par défaut, utilise UTF8.

.EXAMPLE
    $content = Get-CrossPlatformContent -Path "C:\Users\user\Documents\file.txt"
    # Lit le contenu du fichier avec l'encodage UTF8

.EXAMPLE
    $content = Get-CrossPlatformContent -Path "/home/user/documents/file.txt" -Encoding "ASCII"
    # Lit le contenu du fichier avec l'encodage ASCII

.OUTPUTS
    System.String
#>
function Get-CrossPlatformContent {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "ASCII", "Unicode", "UTF7", "UTF32", "BigEndianUnicode", "Default", "OEM")]
        [string]$Encoding = "UTF8"
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return ""
    }

    # Vérifier si le module est initialisé
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Normaliser le chemin pour l'environnement actuel
    $normalizedPath = ConvertTo-CrossPlatformPath -Path $Path

    # Vérifier si le fichier existe
    if (-not (Test-CrossPlatformPath -Path $normalizedPath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas: $normalizedPath"
        return ""
    }

    # Lire le contenu du fichier
    try {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $content = Get-Content -Path $normalizedPath -Raw -Encoding $Encoding
        } else {
            # PowerShell 5.1 et antérieur ne supporte pas tous les encodages de la même manière
            $content = Get-Content -Path $normalizedPath -Raw
        }
        return $content
    }
    catch {
        Write-Error "Erreur lors de la lecture du fichier: $_"
        return ""
    }
}

<#
.SYNOPSIS
    Définit le contenu d'un fichier de manière compatible entre environnements.

.DESCRIPTION
    Cette fonction écrit le contenu dans un fichier en utilisant l'encodage approprié
    pour l'environnement d'exécution.

.PARAMETER Path
    Le chemin du fichier à écrire.

.PARAMETER Content
    Le contenu à écrire dans le fichier.

.PARAMETER Encoding
    L'encodage à utiliser. Par défaut, utilise UTF8.

.PARAMETER Force
    Si spécifié, crée le fichier s'il n'existe pas.

.EXAMPLE
    Set-CrossPlatformContent -Path "C:\Users\user\Documents\file.txt" -Content "Hello, World!"
    # Écrit "Hello, World!" dans le fichier avec l'encodage UTF8

.EXAMPLE
    Set-CrossPlatformContent -Path "/home/user/documents/file.txt" -Content "Hello, World!" -Encoding "ASCII" -Force
    # Écrit "Hello, World!" dans le fichier avec l'encodage ASCII, crée le fichier s'il n'existe pas

.OUTPUTS
    System.Boolean
#>
function Set-CrossPlatformContent {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "ASCII", "Unicode", "UTF7", "UTF32", "BigEndianUnicode", "Default", "OEM")]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return $false
    }

    # Vérifier si le module est initialisé
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Normaliser le chemin pour l'environnement actuel
    $normalizedPath = ConvertTo-CrossPlatformPath -Path $Path

    # Vérifier si le fichier existe ou si Force est spécifié
    if (-not (Test-CrossPlatformPath -Path $normalizedPath -PathType Leaf) -and -not $Force) {
        Write-Error "Le fichier n'existe pas: $normalizedPath. Utilisez -Force pour créer le fichier."
        return $false
    }

    # Écrire le contenu dans le fichier
    try {
        Set-Content -Path $normalizedPath -Value $Content -Encoding $Encoding -Force:$Force
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'écriture dans le fichier: $_"
        return $false
    }
}

#endregion

# Exporter les fonctions publiques du module
Export-ModuleMember -Function Initialize-EnvironmentManager, Get-EnvironmentInfo, Test-EnvironmentCompatibility, ConvertTo-CrossPlatformPath, Test-CrossPlatformPath, Join-CrossPlatformPath, Invoke-CrossPlatformCommand, Get-CrossPlatformContent, Set-CrossPlatformContent

<#
.SYNOPSIS
    Module pour la gestion de la compatibilitÃ© entre environnements.

.DESCRIPTION
    Ce module fournit des fonctions pour dÃ©tecter l'environnement d'exÃ©cution,
    standardiser la gestion des chemins et fournir des wrappers pour les commandes
    spÃ©cifiques Ã  l'OS.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
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
    Cette fonction initialise le module EnvironmentManager en dÃ©tectant
    l'environnement d'exÃ©cution et en configurant les paramÃ¨tres nÃ©cessaires.

.PARAMETER Force
    Force la rÃ©initialisation du module mÃªme s'il a dÃ©jÃ  Ã©tÃ© initialisÃ©.

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
        Write-Verbose "Le module EnvironmentManager est dÃ©jÃ  initialisÃ©."
        return
    }

    # DÃ©tecter l'environnement d'exÃ©cution
    $script:EnvironmentInfo = Get-EnvironmentInfo
    $script:IsInitialized = $true

    Write-Verbose "Module EnvironmentManager initialisÃ© avec succÃ¨s."
    Write-Verbose "SystÃ¨me d'exploitation: $($script:EnvironmentInfo.OSName)"
    Write-Verbose "Version PowerShell: $($script:EnvironmentInfo.PSVersion)"
}

#endregion

#region Fonctions de dÃ©tection d'environnement

<#
.SYNOPSIS
    Obtient des informations dÃ©taillÃ©es sur l'environnement d'exÃ©cution.

.DESCRIPTION
    Cette fonction dÃ©tecte l'environnement d'exÃ©cution (systÃ¨me d'exploitation,
    version de PowerShell, etc.) et retourne un objet contenant ces informations.

.EXAMPLE
    $env = Get-EnvironmentInfo
    if ($env.IsWindows) {
        # Code spÃ©cifique Ã  Windows
    }

.OUTPUTS
    System.Management.Automation.PSObject
#>
function Get-EnvironmentInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    # CrÃ©er l'objet d'informations sur l'environnement
    $envInfo = [PSCustomObject]@{
        # Informations sur le systÃ¨me d'exploitation
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

    # DÃ©terminer le type de systÃ¨me d'exploitation
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core a des variables intÃ©grÃ©es pour le systÃ¨me d'exploitation
        $envInfo.IsWindows = $IsWindows
        $envInfo.IsLinux = $IsLinux
        $envInfo.IsMacOS = $IsMacOS
        $envInfo.IsUnix = $IsLinux -or $IsMacOS
    }
    else {
        # Windows PowerShell s'exÃ©cute uniquement sur Windows
        $envInfo.IsWindows = $true
        $envInfo.IsLinux = $false
        $envInfo.IsMacOS = $false
        $envInfo.IsUnix = $false
    }

    # DÃ©terminer le type de runtime PowerShell
    $envInfo.IsCoreCLR = $PSVersionTable.PSVersion.Major -ge 6
    $envInfo.IsDesktopCLR = -not $envInfo.IsCoreCLR
    $envInfo.IsWindowsPowerShell = $PSVersionTable.PSVersion.Major -le 5
    $envInfo.IsPowerShellCore = $PSVersionTable.PSVersion.Major -ge 6

    # DÃ©terminer le nom du systÃ¨me d'exploitation
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
    VÃ©rifie la compatibilitÃ© avec un environnement cible.

.DESCRIPTION
    Cette fonction vÃ©rifie si l'environnement d'exÃ©cution actuel est compatible
    avec les exigences spÃ©cifiÃ©es.

.PARAMETER TargetOS
    Le systÃ¨me d'exploitation cible. Valeurs possibles : "Windows", "Linux", "MacOS", "Any".

.PARAMETER MinimumPSVersion
    La version minimale de PowerShell requise.

.PARAMETER PSEdition
    L'Ã©dition de PowerShell requise. Valeurs possibles : "Desktop", "Core", "Any".

.PARAMETER ThrowOnIncompatible
    Si spÃ©cifiÃ©, lance une exception si l'environnement n'est pas compatible.

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

    # VÃ©rifier si le module est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Obtenir les informations sur l'environnement actuel
    $envInfo = $script:EnvironmentInfo

    # VÃ©rifier la compatibilitÃ© du systÃ¨me d'exploitation
    $osCompatible = switch ($TargetOS) {
        "Windows" { $envInfo.IsWindows }
        "Linux" { $envInfo.IsLinux }
        "MacOS" { $envInfo.IsMacOS }
        "Any" { $true }
        default { $true }
    }

    # VÃ©rifier la compatibilitÃ© de la version PowerShell
    $psVersionCompatible = $envInfo.PSVersion -ge $MinimumPSVersion

    # VÃ©rifier la compatibilitÃ© de l'Ã©dition PowerShell
    $psEditionCompatible = switch ($PSEdition) {
        "Desktop" { $envInfo.IsDesktopCLR }
        "Core" { $envInfo.IsCoreCLR }
        "Any" { $true }
        default { $true }
    }

    # DÃ©terminer la compatibilitÃ© globale
    $isCompatible = $osCompatible -and $psVersionCompatible -and $psEditionCompatible

    # CrÃ©er l'objet de rÃ©sultat
    $result = [PSCustomObject]@{
        IsCompatible = $isCompatible
        OSCompatible = $osCompatible
        PSVersionCompatible = $psVersionCompatible
        PSEditionCompatible = $psEditionCompatible
        Environment = $envInfo
        IncompatibilityReasons = @()
    }

    # Ajouter les raisons d'incompatibilitÃ©
    if (-not $osCompatible) {
        $result.IncompatibilityReasons += "Le systÃ¨me d'exploitation actuel ($($envInfo.OSName)) n'est pas compatible avec la cible ($TargetOS)."
    }

    if (-not $psVersionCompatible) {
        $result.IncompatibilityReasons += "La version PowerShell actuelle ($($envInfo.PSVersion)) est infÃ©rieure Ã  la version minimale requise ($MinimumPSVersion)."
    }

    if (-not $psEditionCompatible) {
        $result.IncompatibilityReasons += "L'Ã©dition PowerShell actuelle ($($envInfo.PSEdition)) n'est pas compatible avec l'Ã©dition requise ($PSEdition)."
    }

    # Lancer une exception si demandÃ©
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
    Normalise un chemin pour la compatibilitÃ© entre environnements.

.DESCRIPTION
    Cette fonction normalise un chemin en utilisant le sÃ©parateur de chemin
    appropriÃ© pour l'environnement cible.

.PARAMETER Path
    Le chemin Ã  normaliser.

.PARAMETER TargetOS
    Le systÃ¨me d'exploitation cible. Valeurs possibles : "Windows", "Linux", "MacOS", "Auto".

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
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Windows", "Linux", "MacOS", "Auto")]
        [string]$TargetOS = "Auto"
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return ""
    }

    # VÃ©rifier si le module est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # DÃ©terminer le sÃ©parateur de chemin cible
    $targetSeparator = switch ($TargetOS) {
        "Windows" { "\" }
        "Linux" { "/" }
        "MacOS" { "/" }
        default {
            if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
        }
    }

    # Normaliser les sÃ©parateurs de chemin
    $normalizedPath = $Path.Replace("\", $targetSeparator).Replace("/", $targetSeparator)

    return $normalizedPath
}

<#
.SYNOPSIS
    VÃ©rifie si un chemin existe de maniÃ¨re compatible entre environnements.

.DESCRIPTION
    Cette fonction vÃ©rifie si un chemin existe en utilisant les mÃ©thodes
    appropriÃ©es pour l'environnement d'exÃ©cution.

.PARAMETER Path
    Le chemin Ã  vÃ©rifier.

.PARAMETER PathType
    Le type de chemin Ã  vÃ©rifier. Valeurs possibles : "Any", "Leaf", "Container".

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
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Any", "Leaf", "Container")]
        [string]$PathType = "Any"
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return $false
    }

    # VÃ©rifier si le module est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Normaliser le chemin pour l'environnement actuel
    $normalizedPath = ConvertTo-CrossPlatformPath -Path $Path

    # VÃ©rifier si le chemin existe
    $exists = switch ($PathType) {
        "Leaf" { Test-Path -Path $normalizedPath -PathType Leaf }
        "Container" { Test-Path -Path $normalizedPath -PathType Container }
        default { Test-Path -Path $normalizedPath }
    }

    return $exists
}

<#
.SYNOPSIS
    Joint des chemins de maniÃ¨re compatible entre environnements.

.DESCRIPTION
    Cette fonction joint des chemins en utilisant le sÃ©parateur de chemin
    appropriÃ© pour l'environnement cible.

.PARAMETER Path
    Le chemin de base.

.PARAMETER ChildPath
    Les chemins enfants Ã  joindre au chemin de base.

.PARAMETER TargetOS
    Le systÃ¨me d'exploitation cible. Valeurs possibles : "Windows", "Linux", "MacOS", "Auto".

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
        [AllowEmptyString()]
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

    # VÃ©rifier si le module est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # DÃ©terminer le sÃ©parateur de chemin cible
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

        # S'assurer que le chemin de base se termine par un sÃ©parateur
        if (-not $normalizedPath.EndsWith($targetSeparator)) {
            $normalizedPath += $targetSeparator
        }

        # S'assurer que le chemin enfant ne commence pas par un sÃ©parateur
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
    ExÃ©cute une commande avec les adaptations nÃ©cessaires selon l'OS.

.DESCRIPTION
    Cette fonction exÃ©cute une commande en utilisant la version appropriÃ©e
    pour l'environnement d'exÃ©cution.

.PARAMETER WindowsCommand
    La commande Ã  exÃ©cuter sur Windows.

.PARAMETER UnixCommand
    La commande Ã  exÃ©cuter sur Linux/Unix.

.PARAMETER MacOSCommand
    La commande Ã  exÃ©cuter sur macOS. Si non spÃ©cifiÃ©e, utilise UnixCommand.

.PARAMETER PassThru
    Si spÃ©cifiÃ©, retourne la commande Ã  exÃ©cuter sans l'exÃ©cuter.

.EXAMPLE
    Invoke-CrossPlatformCommand -WindowsCommand "dir" -UnixCommand "ls -la"
    # ExÃ©cute "dir" sur Windows et "ls -la" sur Linux/macOS

.EXAMPLE
    $command = Invoke-CrossPlatformCommand -WindowsCommand "ipconfig" -UnixCommand "ifconfig" -PassThru
    # Retourne "ipconfig" sur Windows et "ifconfig" sur Linux/macOS sans l'exÃ©cuter

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

    # VÃ©rifier si le module est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # DÃ©terminer la commande Ã  exÃ©cuter
    $command = if ($script:EnvironmentInfo.IsWindows) {
        $WindowsCommand
    }
    elseif ($script:EnvironmentInfo.IsMacOS -and -not [string]::IsNullOrEmpty($MacOSCommand)) {
        $MacOSCommand
    }
    else {
        $UnixCommand
    }

    # Retourner la commande ou l'exÃ©cuter
    if ($PassThru) {
        return $command
    }
    else {
        return Invoke-Expression -Command $command
    }
}

<#
.SYNOPSIS
    Obtient le contenu d'un fichier de maniÃ¨re compatible entre environnements.

.DESCRIPTION
    Cette fonction lit le contenu d'un fichier en utilisant l'encodage appropriÃ©
    pour l'environnement d'exÃ©cution.

.PARAMETER Path
    Le chemin du fichier Ã  lire.

.PARAMETER Encoding
    L'encodage Ã  utiliser. Par dÃ©faut, utilise UTF8.

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
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "ASCII", "Unicode", "UTF7", "UTF32", "BigEndianUnicode", "Default", "OEM")]
        [string]$Encoding = "UTF8"
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return ""
    }

    # VÃ©rifier si le module est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Normaliser le chemin pour l'environnement actuel
    $normalizedPath = ConvertTo-CrossPlatformPath -Path $Path

    # VÃ©rifier si le fichier existe
    if (-not (Test-CrossPlatformPath -Path $normalizedPath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas: $normalizedPath"
        return ""
    }

    # Lire le contenu du fichier
    try {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $content = Get-Content -Path $normalizedPath -Raw -Encoding $Encoding
        } else {
            # PowerShell 5.1 et antÃ©rieur ne supporte pas tous les encodages de la mÃªme maniÃ¨re
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
    DÃ©finit le contenu d'un fichier de maniÃ¨re compatible entre environnements.

.DESCRIPTION
    Cette fonction Ã©crit le contenu dans un fichier en utilisant l'encodage appropriÃ©
    pour l'environnement d'exÃ©cution.

.PARAMETER Path
    Le chemin du fichier Ã  Ã©crire.

.PARAMETER Content
    Le contenu Ã  Ã©crire dans le fichier.

.PARAMETER Encoding
    L'encodage Ã  utiliser. Par dÃ©faut, utilise UTF8.

.PARAMETER Force
    Si spÃ©cifiÃ©, crÃ©e le fichier s'il n'existe pas.

.EXAMPLE
    Set-CrossPlatformContent -Path "C:\Users\user\Documents\file.txt" -Content "Hello, World!"
    # Ã‰crit "Hello, World!" dans le fichier avec l'encodage UTF8

.EXAMPLE
    Set-CrossPlatformContent -Path "/home/user/documents/file.txt" -Content "Hello, World!" -Encoding "ASCII" -Force
    # Ã‰crit "Hello, World!" dans le fichier avec l'encodage ASCII, crÃ©e le fichier s'il n'existe pas

.OUTPUTS
    System.Boolean
#>
function Set-CrossPlatformContent {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
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

    # VÃ©rifier si le module est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-EnvironmentManager
    }

    # Normaliser le chemin pour l'environnement actuel
    $normalizedPath = ConvertTo-CrossPlatformPath -Path $Path

    # VÃ©rifier si le fichier existe ou si Force est spÃ©cifiÃ©
    if (-not (Test-CrossPlatformPath -Path $normalizedPath -PathType Leaf) -and -not $Force) {
        Write-Error "Le fichier n'existe pas: $normalizedPath. Utilisez -Force pour crÃ©er le fichier."
        return $false
    }

    # Ã‰crire le contenu dans le fichier
    try {
        Set-Content -Path $normalizedPath -Value $Content -Encoding $Encoding -Force:$Force
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'Ã©criture dans le fichier: $_"
        return $false
    }
}

#endregion

# Exporter les fonctions publiques du module
Export-ModuleMember -Function Initialize-EnvironmentManager, Get-EnvironmentInfo, Test-EnvironmentCompatibility, ConvertTo-CrossPlatformPath, Test-CrossPlatformPath, Join-CrossPlatformPath, Invoke-CrossPlatformCommand, Get-CrossPlatformContent, Set-CrossPlatformContent

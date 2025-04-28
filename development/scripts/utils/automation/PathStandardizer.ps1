<#
.SYNOPSIS
    Standardise les chemins pour une meilleure compatibilitÃ© entre les environnements.

.DESCRIPTION
    Ce script fournit des fonctions pour standardiser les chemins de fichiers et de dossiers
    afin d'assurer une meilleure compatibilitÃ© entre diffÃ©rents systÃ¨mes d'exploitation et
    environnements. Il gÃ¨re les chemins relatifs, absolus, UNC, et les URL de fichiers.

.EXAMPLE
    . .\PathStandardizer.ps1
    $standardPath = ConvertTo-StandardPath -Path "C:\Users\user\Documents\file.txt"
    $relativePath = ConvertTo-RelativePath -Path $standardPath -BasePath "C:\Users\user"

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Charger le module de dÃ©tection d'environnement
$environmentDetectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EnvironmentDetector.ps1"
if (Test-Path -Path $environmentDetectorPath -PathType Leaf) {
    . $environmentDetectorPath
}
else {
    Write-Warning "Le module de dÃ©tection d'environnement n'a pas Ã©tÃ© trouvÃ©. Certaines fonctionnalitÃ©s peuvent ne pas fonctionner correctement."
}

# Obtenir les informations sur l'environnement
$script:EnvironmentInfo = if (Get-Command -Name Get-EnvironmentInfo -ErrorAction SilentlyContinue) {
    Get-EnvironmentInfo
}
else {
    # CrÃ©er un objet d'informations sur l'environnement minimal
    [PSCustomObject]@{
        IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
        IsLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
        IsMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
        PathSeparator = [System.IO.Path]::DirectorySeparatorChar
        AltPathSeparator = [System.IO.Path]::AltDirectorySeparatorChar
    }
}

# Fonction pour convertir un chemin en chemin standard
function ConvertTo-StandardPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Windows", "Unix")]
        [string]$TargetOS = "Auto",
        
        [Parameter(Mandatory = $false)]
        [switch]$NormalizeCase,
        
        [Parameter(Mandatory = $false)]
        [switch]$ResolveRelativePath
    )
    
    process {
        if ([string]::IsNullOrEmpty($Path)) {
            return ""
        }
        
        # DÃ©terminer le sÃ©parateur de chemin cible
        $targetSeparator = switch ($TargetOS) {
            "Windows" { "\" }
            "Unix" { "/" }
            default {
                if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
            }
        }
        
        # Normaliser les sÃ©parateurs de chemin
        $normalizedPath = $Path.Replace("\", $targetSeparator).Replace("/", $targetSeparator)
        
        # RÃ©soudre le chemin relatif si demandÃ©
        if ($ResolveRelativePath) {
            try {
                $normalizedPath = Resolve-Path -Path $normalizedPath -ErrorAction Stop | Select-Object -ExpandProperty Path
            }
            catch {
                Write-Warning "Impossible de rÃ©soudre le chemin relatif '$Path': $_"
            }
        }
        
        # Normaliser la casse si demandÃ©
        if ($NormalizeCase) {
            if ($TargetOS -eq "Windows" -or ($TargetOS -eq "Auto" -and $script:EnvironmentInfo.IsWindows)) {
                # Windows est insensible Ã  la casse, convertir en minuscules
                $normalizedPath = $normalizedPath.ToLower()
            }
        }
        
        # GÃ©rer les chemins UNC
        if ($normalizedPath -match "^\\\\") {
            # C'est un chemin UNC, s'assurer qu'il a le bon format
            $normalizedPath = $normalizedPath -replace "^\\\\", "\\"
        }
        
        # GÃ©rer les URL de fichiers
        if ($normalizedPath -match "^file://") {
            # C'est une URL de fichier, la convertir en chemin standard
            $normalizedPath = $normalizedPath -replace "^file://", ""
            
            # GÃ©rer les URL de fichiers Windows (file:///C:/...)
            if ($normalizedPath -match "^/[A-Za-z]:") {
                $normalizedPath = $normalizedPath.Substring(1)
            }
            
            # Normaliser les sÃ©parateurs de chemin Ã  nouveau
            $normalizedPath = $normalizedPath.Replace("\", $targetSeparator).Replace("/", $targetSeparator)
        }
        
        return $normalizedPath
    }
}

# Fonction pour convertir un chemin absolu en chemin relatif
function ConvertTo-RelativePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$BasePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Windows", "Unix")]
        [string]$TargetOS = "Auto"
    )
    
    process {
        if ([string]::IsNullOrEmpty($Path) -or [string]::IsNullOrEmpty($BasePath)) {
            return ""
        }
        
        # DÃ©terminer le sÃ©parateur de chemin cible
        $targetSeparator = switch ($TargetOS) {
            "Windows" { "\" }
            "Unix" { "/" }
            default {
                if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
            }
        }
        
        # Normaliser les chemins
        $normalizedPath = ConvertTo-StandardPath -Path $Path -TargetOS $TargetOS
        $normalizedBasePath = ConvertTo-StandardPath -Path $BasePath -TargetOS $TargetOS
        
        # S'assurer que le chemin de base se termine par un sÃ©parateur
        if (-not $normalizedBasePath.EndsWith($targetSeparator)) {
            $normalizedBasePath += $targetSeparator
        }
        
        # VÃ©rifier si le chemin est dÃ©jÃ  relatif
        if (-not [System.IO.Path]::IsPathRooted($normalizedPath)) {
            return $normalizedPath
        }
        
        # VÃ©rifier si le chemin est sous le chemin de base
        if (-not $normalizedPath.StartsWith($normalizedBasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            # Le chemin n'est pas sous le chemin de base, impossible de crÃ©er un chemin relatif
            return $normalizedPath
        }
        
        # Extraire la partie relative du chemin
        $relativePath = $normalizedPath.Substring($normalizedBasePath.Length)
        
        # Supprimer le sÃ©parateur de chemin initial si prÃ©sent
        if ($relativePath.StartsWith($targetSeparator)) {
            $relativePath = $relativePath.Substring(1)
        }
        
        return $relativePath
    }
}

# Fonction pour convertir un chemin relatif en chemin absolu
function ConvertTo-AbsolutePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$BasePath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Windows", "Unix")]
        [string]$TargetOS = "Auto"
    )
    
    process {
        if ([string]::IsNullOrEmpty($Path)) {
            return ""
        }
        
        # DÃ©terminer le sÃ©parateur de chemin cible
        $targetSeparator = switch ($TargetOS) {
            "Windows" { "\" }
            "Unix" { "/" }
            default {
                if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
            }
        }
        
        # Normaliser le chemin
        $normalizedPath = ConvertTo-StandardPath -Path $Path -TargetOS $TargetOS
        
        # VÃ©rifier si le chemin est dÃ©jÃ  absolu
        if ([System.IO.Path]::IsPathRooted($normalizedPath)) {
            return $normalizedPath
        }
        
        # DÃ©terminer le chemin de base
        $normalizedBasePath = if ([string]::IsNullOrEmpty($BasePath)) {
            ConvertTo-StandardPath -Path (Get-Location).Path -TargetOS $TargetOS
        }
        else {
            ConvertTo-StandardPath -Path $BasePath -TargetOS $TargetOS
        }
        
        # S'assurer que le chemin de base se termine par un sÃ©parateur
        if (-not $normalizedBasePath.EndsWith($targetSeparator)) {
            $normalizedBasePath += $targetSeparator
        }
        
        # Combiner les chemins
        $absolutePath = $normalizedBasePath + $normalizedPath
        
        # Normaliser le chemin (rÃ©soudre les .. et .)
        $absolutePath = [System.IO.Path]::GetFullPath($absolutePath)
        
        # Normaliser les sÃ©parateurs de chemin
        $absolutePath = $absolutePath.Replace("\", $targetSeparator).Replace("/", $targetSeparator)
        
        return $absolutePath
    }
}

# Fonction pour normaliser un chemin en fonction de l'OS cible
function Get-NormalizedPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Windows", "Unix")]
        [string]$TargetOS = "Auto",
        
        [Parameter(Mandatory = $false)]
        [switch]$MakeAbsolute,
        
        [Parameter(Mandatory = $false)]
        [switch]$MakeRelative,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$NormalizeCase,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnsureExists
    )
    
    process {
        if ([string]::IsNullOrEmpty($Path)) {
            return ""
        }
        
        # Normaliser le chemin
        $normalizedPath = ConvertTo-StandardPath -Path $Path -TargetOS $TargetOS -NormalizeCase:$NormalizeCase
        
        # Convertir en chemin absolu si demandÃ©
        if ($MakeAbsolute) {
            $normalizedPath = ConvertTo-AbsolutePath -Path $normalizedPath -BasePath $BasePath -TargetOS $TargetOS
        }
        
        # Convertir en chemin relatif si demandÃ©
        if ($MakeRelative) {
            $basePathToUse = if ([string]::IsNullOrEmpty($BasePath)) {
                (Get-Location).Path
            }
            else {
                $BasePath
            }
            
            $normalizedPath = ConvertTo-RelativePath -Path $normalizedPath -BasePath $basePathToUse -TargetOS $TargetOS
        }
        
        # VÃ©rifier si le chemin existe si demandÃ©
        if ($EnsureExists) {
            if (-not (Test-Path -Path $normalizedPath)) {
                Write-Warning "Le chemin '$normalizedPath' n'existe pas."
            }
        }
        
        return $normalizedPath
    }
}

# Fonction pour obtenir un chemin temporaire compatible avec l'OS
function Get-TempPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FileName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Extension = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Windows", "Unix")]
        [string]$TargetOS = "Auto",
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateDirectory
    )
    
    # DÃ©terminer le sÃ©parateur de chemin cible
    $targetSeparator = switch ($TargetOS) {
        "Windows" { "\" }
        "Unix" { "/" }
        default {
            if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
        }
    }
    
    # Obtenir le rÃ©pertoire temporaire
    $tempDir = [System.IO.Path]::GetTempPath()
    
    # Normaliser le chemin du rÃ©pertoire temporaire
    $tempDir = ConvertTo-StandardPath -Path $tempDir -TargetOS $TargetOS
    
    # S'assurer que le chemin se termine par un sÃ©parateur
    if (-not $tempDir.EndsWith($targetSeparator)) {
        $tempDir += $targetSeparator
    }
    
    # GÃ©nÃ©rer un nom de fichier alÃ©atoire si non spÃ©cifiÃ©
    $fileNameToUse = if ([string]::IsNullOrEmpty($FileName)) {
        [System.IO.Path]::GetRandomFileName()
    }
    else {
        $FileName
    }
    
    # Ajouter l'extension si spÃ©cifiÃ©e
    if (-not [string]::IsNullOrEmpty($Extension)) {
        if (-not $Extension.StartsWith(".")) {
            $Extension = ".$Extension"
        }
        
        if (-not $fileNameToUse.EndsWith($Extension, [System.StringComparison]::OrdinalIgnoreCase)) {
            $fileNameToUse += $Extension
        }
    }
    
    # Construire le chemin complet
    $tempPath = $tempDir + $fileNameToUse
    
    # CrÃ©er le rÃ©pertoire si demandÃ©
    if ($CreateDirectory) {
        $directory = if ([string]::IsNullOrEmpty($Extension)) {
            # Si pas d'extension, considÃ©rer que c'est un rÃ©pertoire
            $tempPath
        }
        else {
            # Sinon, obtenir le rÃ©pertoire parent
            [System.IO.Path]::GetDirectoryName($tempPath)
        }
        
        if (-not (Test-Path -Path $directory -PathType Container)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }
    }
    
    return $tempPath
}

# Fonction pour rÃ©soudre les chemins avec des variables d'environnement
function Resolve-EnvironmentPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Windows", "Unix")]
        [string]$TargetOS = "Auto",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalVariables = @{}
    )
    
    process {
        if ([string]::IsNullOrEmpty($Path)) {
            return ""
        }
        
        # DÃ©terminer le sÃ©parateur de chemin cible
        $targetSeparator = switch ($TargetOS) {
            "Windows" { "\" }
            "Unix" { "/" }
            default {
                if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
            }
        }
        
        # Remplacer les variables d'environnement Windows (%VAR%)
        $resolvedPath = [regex]::Replace($Path, '%([^%]+)%', {
            param($match)
            $varName = $match.Groups[1].Value
            
            if ($AdditionalVariables.ContainsKey($varName)) {
                return $AdditionalVariables[$varName]
            }
            else {
                $envValue = [System.Environment]::GetEnvironmentVariable($varName)
                return if ($null -ne $envValue) { $envValue } else { $match.Value }
            }
        })
        
        # Remplacer les variables d'environnement Unix ($VAR ou ${VAR})
        $resolvedPath = [regex]::Replace($resolvedPath, '\$\{([^}]+)\}|\$([a-zA-Z0-9_]+)', {
            param($match)
            $varName = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
            
            if ($AdditionalVariables.ContainsKey($varName)) {
                return $AdditionalVariables[$varName]
            }
            else {
                $envValue = [System.Environment]::GetEnvironmentVariable($varName)
                return if ($null -ne $envValue) { $envValue } else { $match.Value }
            }
        })
        
        # Remplacer le tilde (~) par le rÃ©pertoire utilisateur
        if ($resolvedPath.StartsWith("~")) {
            $homeDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
            $resolvedPath = $homeDir + $resolvedPath.Substring(1)
        }
        
        # Normaliser le chemin
        $resolvedPath = ConvertTo-StandardPath -Path $resolvedPath -TargetOS $TargetOS
        
        return $resolvedPath
    }
}

# Fonction pour obtenir un chemin relatif entre deux chemins
function Get-RelativePathBetween {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$RelativeTo,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Windows", "Unix")]
        [string]$TargetOS = "Auto"
    )
    
    if ([string]::IsNullOrEmpty($Path) -or [string]::IsNullOrEmpty($RelativeTo)) {
        return ""
    }
    
    # DÃ©terminer le sÃ©parateur de chemin cible
    $targetSeparator = switch ($TargetOS) {
        "Windows" { "\" }
        "Unix" { "/" }
        default {
            if ($script:EnvironmentInfo.IsWindows) { "\" } else { "/" }
        }
    }
    
    # Normaliser les chemins
    $normalizedPath = ConvertTo-StandardPath -Path $Path -TargetOS $TargetOS
    $normalizedRelativeTo = ConvertTo-StandardPath -Path $RelativeTo -TargetOS $TargetOS
    
    # S'assurer que les chemins sont absolus
    if (-not [System.IO.Path]::IsPathRooted($normalizedPath)) {
        $normalizedPath = ConvertTo-AbsolutePath -Path $normalizedPath -TargetOS $TargetOS
    }
    
    if (-not [System.IO.Path]::IsPathRooted($normalizedRelativeTo)) {
        $normalizedRelativeTo = ConvertTo-AbsolutePath -Path $normalizedRelativeTo -TargetOS $TargetOS
    }
    
    # VÃ©rifier si les chemins sont sur le mÃªme lecteur (Windows)
    if ($TargetOS -eq "Windows" -or ($TargetOS -eq "Auto" -and $script:EnvironmentInfo.IsWindows)) {
        $pathDrive = if ($normalizedPath -match "^([A-Za-z]:)") { $matches[1].ToUpper() } else { "" }
        $relativeToPathDrive = if ($normalizedRelativeTo -match "^([A-Za-z]:)") { $matches[1].ToUpper() } else { "" }
        
        if ($pathDrive -ne $relativeToPathDrive) {
            # Les chemins sont sur des lecteurs diffÃ©rents, impossible de crÃ©er un chemin relatif
            return $normalizedPath
        }
    }
    
    # Diviser les chemins en segments
    $pathSegments = $normalizedPath.Split($targetSeparator, [System.StringSplitOptions]::RemoveEmptyEntries)
    $relativeToSegments = $normalizedRelativeTo.Split($targetSeparator, [System.StringSplitOptions]::RemoveEmptyEntries)
    
    # Trouver le prÃ©fixe commun
    $commonPrefixLength = 0
    $minLength = [Math]::Min($pathSegments.Length, $relativeToSegments.Length)
    
    for ($i = 0; $i -lt $minLength; $i++) {
        if ($pathSegments[$i] -eq $relativeToSegments[$i]) {
            $commonPrefixLength++
        }
        else {
            break
        }
    }
    
    # Construire le chemin relatif
    $relativePath = ""
    
    # Ajouter les ".." pour remonter au prÃ©fixe commun
    for ($i = 0; $i -lt ($relativeToSegments.Length - $commonPrefixLength); $i++) {
        $relativePath += "..$targetSeparator"
    }
    
    # Ajouter les segments restants du chemin cible
    for ($i = $commonPrefixLength; $i -lt $pathSegments.Length; $i++) {
        $relativePath += $pathSegments[$i]
        
        if ($i -lt $pathSegments.Length - 1) {
            $relativePath += $targetSeparator
        }
    }
    
    # Si le chemin relatif est vide, retourner "."
    if ([string]::IsNullOrEmpty($relativePath)) {
        return "."
    }
    
    return $relativePath
}

# Exporter les fonctions
Export-ModuleMember -Function ConvertTo-StandardPath, ConvertTo-RelativePath, ConvertTo-AbsolutePath, Get-NormalizedPath, Get-TempPath, Resolve-EnvironmentPath, Get-RelativePathBetween

# PathResolver.ps1
# Module de resolution des chemins d'archives
# Version: 1.0
# Date: 2025-05-15

# Fonction pour resoudre un chemin d'archive
function Resolve-ArchivePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [string]$IndexPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateExists,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateIfNotExists,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("File", "Directory", "Any")]
        [string]$PathType = "Any"
    )
    
    process {
        # Verifier si le chemin est vide ou null
        if ([string]::IsNullOrWhiteSpace($Path)) {
            Write-Error "Le chemin ne peut pas etre vide ou null."
            return $null
        }
        
        # Determiner si le chemin est absolu ou relatif
        $isAbsolutePath = [System.IO.Path]::IsPathRooted($Path)
        
        # Resoudre le chemin
        $resolvedPath = $Path
        
        if (-not $isAbsolutePath) {
            # Si un chemin d'index est specifie, l'utiliser comme base pour les chemins relatifs
            if (-not [string]::IsNullOrWhiteSpace($IndexPath)) {
                $indexDirectory = [System.IO.Path]::GetDirectoryName($IndexPath)
                $resolvedPath = [System.IO.Path]::Combine($indexDirectory, $Path)
            }
            # Sinon, utiliser le chemin de base
            else {
                $resolvedPath = [System.IO.Path]::Combine($BasePath, $Path)
            }
        }
        
        # Normaliser le chemin
        try {
            $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)
        }
        catch {
            Write-Error "Erreur lors de la normalisation du chemin: $($_.Exception.Message)"
            return $null
        }
        
        # Verifier si le chemin existe
        $pathExists = Test-Path -Path $resolvedPath
        
        # Verifier le type de chemin
        $isCorrectType = $true
        if ($pathExists -and $PathType -ne "Any") {
            $isFile = Test-Path -Path $resolvedPath -PathType Leaf
            $isDirectory = Test-Path -Path $resolvedPath -PathType Container
            
            if ($PathType -eq "File" -and -not $isFile) {
                $isCorrectType = $false
            }
            elseif ($PathType -eq "Directory" -and -not $isDirectory) {
                $isCorrectType = $false
            }
        }
        
        # Creer le chemin s'il n'existe pas et que CreateIfNotExists est specifie
        if (-not $pathExists -and $CreateIfNotExists) {
            try {
                if ($PathType -eq "Directory" -or ($PathType -eq "Any" -and $Path.EndsWith("\"))) {
                    New-Item -Path $resolvedPath -ItemType Directory -Force | Out-Null
                    $pathExists = $true
                    $isCorrectType = $true
                }
                elseif ($PathType -eq "File" -or $PathType -eq "Any") {
                    # Creer le repertoire parent s'il n'existe pas
                    $parentDirectory = [System.IO.Path]::GetDirectoryName($resolvedPath)
                    if (-not (Test-Path -Path $parentDirectory -PathType Container)) {
                        New-Item -Path $parentDirectory -ItemType Directory -Force | Out-Null
                    }
                    
                    # Creer un fichier vide
                    New-Item -Path $resolvedPath -ItemType File -Force | Out-Null
                    $pathExists = $true
                    $isCorrectType = $true
                }
            }
            catch {
                Write-Error "Erreur lors de la creation du chemin: $($_.Exception.Message)"
                return $null
            }
        }
        
        # Verifier si le chemin existe et est du bon type
        if ($ValidateExists -and (-not $pathExists -or -not $isCorrectType)) {
            if (-not $pathExists) {
                Write-Error "Le chemin n'existe pas: $resolvedPath"
            }
            elseif (-not $isCorrectType) {
                Write-Error "Le chemin n'est pas du type attendu ($PathType): $resolvedPath"
            }
            return $null
        }
        
        # Creer un objet avec les informations sur le chemin
        $result = [PSCustomObject]@{
            OriginalPath = $Path
            ResolvedPath = $resolvedPath
            IsAbsolute = $isAbsolutePath
            Exists = $pathExists
            Type = if ($pathExists) {
                if (Test-Path -Path $resolvedPath -PathType Leaf) { "File" } else { "Directory" }
            } else {
                "Unknown"
            }
            BasePath = if ($isAbsolutePath) { $null } else { if (-not [string]::IsNullOrWhiteSpace($IndexPath)) { $indexDirectory } else { $BasePath } }
            IndexPath = $IndexPath
        }
        
        return $result
    }
}

# Fonction pour valider un chemin d'archive
function Test-ArchivePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [string]$IndexPath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("File", "Directory", "Any")]
        [string]$PathType = "Any",
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckPermissions,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckIntegrity
    )
    
    process {
        # Resoudre le chemin
        $resolvedPath = Resolve-ArchivePath -Path $Path -BasePath $BasePath -IndexPath $IndexPath -ValidateExists -PathType $PathType
        
        if ($null -eq $resolvedPath) {
            return $false
        }
        
        # Verifier les permissions
        if ($CheckPermissions) {
            try {
                $acl = Get-Acl -Path $resolvedPath.ResolvedPath
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                
                # Verifier si l'utilisateur a les permissions de lecture
                $hasReadPermission = $false
                foreach ($accessRule in $acl.Access) {
                    if ($accessRule.IdentityReference.Value -eq $currentUser -or $accessRule.IdentityReference.Value -eq "Everyone" -or $accessRule.IdentityReference.Value -eq "BUILTIN\Users") {
                        if ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Read) {
                            $hasReadPermission = $true
                            break
                        }
                    }
                }
                
                if (-not $hasReadPermission) {
                    Write-Error "L'utilisateur n'a pas les permissions de lecture sur: $($resolvedPath.ResolvedPath)"
                    return $false
                }
            }
            catch {
                Write-Error "Erreur lors de la verification des permissions: $($_.Exception.Message)"
                return $false
            }
        }
        
        # Verifier l'integrite du fichier
        if ($CheckIntegrity -and $resolvedPath.Type -eq "File") {
            try {
                # Verifier si le fichier peut etre ouvert en lecture
                $fileStream = [System.IO.File]::OpenRead($resolvedPath.ResolvedPath)
                $fileStream.Close()
                $fileStream.Dispose()
                
                # Verifier la taille du fichier
                $fileInfo = Get-Item -Path $resolvedPath.ResolvedPath
                if ($fileInfo.Length -eq 0) {
                    Write-Warning "Le fichier est vide: $($resolvedPath.ResolvedPath)"
                    # Ne pas echouer pour un fichier vide, juste avertir
                }
            }
            catch {
                Write-Error "Erreur lors de la verification de l'integrite du fichier: $($_.Exception.Message)"
                return $false
            }
        }
        
        return $true
    }
}

# Fonction pour gerer les erreurs de resolution de chemin
function Get-ArchivePathError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [string]$IndexPath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("File", "Directory", "Any")]
        [string]$PathType = "Any"
    )
    
    # Resoudre le chemin sans validation
    $resolvedPath = Resolve-ArchivePath -Path $Path -BasePath $BasePath -IndexPath $IndexPath
    
    if ($null -eq $resolvedPath) {
        return [PSCustomObject]@{
            Path = $Path
            Error = "Erreur lors de la resolution du chemin"
            ErrorType = "ResolutionError"
            Details = "Impossible de resoudre le chemin"
        }
    }
    
    # Verifier si le chemin existe
    if (-not $resolvedPath.Exists) {
        return [PSCustomObject]@{
            Path = $Path
            ResolvedPath = $resolvedPath.ResolvedPath
            Error = "Le chemin n'existe pas"
            ErrorType = "NotFound"
            Details = "Le chemin resolu n'existe pas sur le systeme de fichiers"
        }
    }
    
    # Verifier le type de chemin
    if ($PathType -ne "Any" -and $resolvedPath.Type -ne $PathType) {
        return [PSCustomObject]@{
            Path = $Path
            ResolvedPath = $resolvedPath.ResolvedPath
            Error = "Type de chemin incorrect"
            ErrorType = "WrongType"
            Details = "Le chemin est de type $($resolvedPath.Type) mais devrait etre de type $PathType"
        }
    }
    
    # Verifier les permissions
    try {
        $acl = Get-Acl -Path $resolvedPath.ResolvedPath
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        
        # Verifier si l'utilisateur a les permissions de lecture
        $hasReadPermission = $false
        foreach ($accessRule in $acl.Access) {
            if ($accessRule.IdentityReference.Value -eq $currentUser -or $accessRule.IdentityReference.Value -eq "Everyone" -or $accessRule.IdentityReference.Value -eq "BUILTIN\Users") {
                if ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Read) {
                    $hasReadPermission = $true
                    break
                }
            }
        }
        
        if (-not $hasReadPermission) {
            return [PSCustomObject]@{
                Path = $Path
                ResolvedPath = $resolvedPath.ResolvedPath
                Error = "Permissions insuffisantes"
                ErrorType = "PermissionDenied"
                Details = "L'utilisateur n'a pas les permissions de lecture sur le chemin"
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            Path = $Path
            ResolvedPath = $resolvedPath.ResolvedPath
            Error = "Erreur lors de la verification des permissions"
            ErrorType = "PermissionError"
            Details = $_.Exception.Message
        }
    }
    
    # Aucune erreur
    return $null
}

# Fonction pour convertir entre chemins relatifs et absolus
function Convert-ArchivePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("ToAbsolute", "ToRelative")]
        [string]$ConversionType,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [string]$IndexPath = ""
    )
    
    process {
        # Verifier si le chemin est vide ou null
        if ([string]::IsNullOrWhiteSpace($Path)) {
            Write-Error "Le chemin ne peut pas etre vide ou null."
            return $null
        }
        
        # Determiner si le chemin est absolu ou relatif
        $isAbsolutePath = [System.IO.Path]::IsPathRooted($Path)
        
        # Conversion de relatif a absolu
        if ($ConversionType -eq "ToAbsolute" -and -not $isAbsolutePath) {
            # Si un chemin d'index est specifie, l'utiliser comme base pour les chemins relatifs
            if (-not [string]::IsNullOrWhiteSpace($IndexPath)) {
                $indexDirectory = [System.IO.Path]::GetDirectoryName($IndexPath)
                $absolutePath = [System.IO.Path]::Combine($indexDirectory, $Path)
            }
            # Sinon, utiliser le chemin de base
            else {
                $absolutePath = [System.IO.Path]::Combine($BasePath, $Path)
            }
            
            # Normaliser le chemin
            try {
                $absolutePath = [System.IO.Path]::GetFullPath($absolutePath)
                return $absolutePath
            }
            catch {
                Write-Error "Erreur lors de la normalisation du chemin: $($_.Exception.Message)"
                return $null
            }
        }
        # Conversion d'absolu a relatif
        elseif ($ConversionType -eq "ToRelative" -and $isAbsolutePath) {
            # Determiner le chemin de base
            $baseDir = if (-not [string]::IsNullOrWhiteSpace($IndexPath)) {
                [System.IO.Path]::GetDirectoryName($IndexPath)
            } else {
                $BasePath
            }
            
            # Normaliser les chemins
            try {
                $absolutePath = [System.IO.Path]::GetFullPath($Path)
                $baseDir = [System.IO.Path]::GetFullPath($baseDir)
                
                # Verifier si le chemin absolu est sous le repertoire de base
                if (-not $absolutePath.StartsWith($baseDir, [StringComparison]::OrdinalIgnoreCase)) {
                    Write-Error "Le chemin absolu n'est pas sous le repertoire de base."
                    return $null
                }
                
                # Calculer le chemin relatif
                $relativePath = $absolutePath.Substring($baseDir.Length)
                
                # Supprimer le separateur de chemin initial si present
                if ($relativePath.StartsWith([System.IO.Path]::DirectorySeparatorChar) -or $relativePath.StartsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
                    $relativePath = $relativePath.Substring(1)
                }
                
                return $relativePath
            }
            catch {
                Write-Error "Erreur lors de la conversion du chemin: $($_.Exception.Message)"
                return $null
            }
        }
        # Aucune conversion necessaire
        else {
            return $Path
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Resolve-ArchivePath, Test-ArchivePath, Get-ArchivePathError, Convert-ArchivePath

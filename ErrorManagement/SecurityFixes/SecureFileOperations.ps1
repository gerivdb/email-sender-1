# Script pour sécuriser les opérations de fichiers

# Importer le module de sécurisation des entrées
$inputSanitizerPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "InputSanitizer.ps1"
if (Test-Path -Path $inputSanitizerPath) {
    . $inputSanitizerPath
}
else {
    Write-Error "Le module de sécurisation des entrées est introuvable: $inputSanitizerPath"
    return
}

# Fonction pour lire un fichier de manière sécurisée
function Get-SecureFileContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Raw,
        
        [Parameter(Mandatory = $false)]
        [switch]$SanitizeContent
    )
    
    # Vérifier si le chemin est sécurisé
    if (-not (Test-SafePath -Path $Path -AllowedPaths $AllowedPaths -PreventPathTraversal)) {
        throw "Chemin non sécurisé: $Path"
    }
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Le fichier n'existe pas: $Path"
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw:$Raw
    
    # Nettoyer le contenu si demandé
    if ($SanitizeContent) {
        if ($Raw) {
            $content = Get-SanitizedString -Input $content
        }
        else {
            $content = $content | ForEach-Object { Get-SanitizedString -Input $_ }
        }
    }
    
    return $content
}

# Fonction pour écrire dans un fichier de manière sécurisée
function Set-SecureFileContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [object]$Content,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8"
    )
    
    # Vérifier si le chemin est sécurisé
    if (-not (Test-SafePath -Path $Path -AllowedPaths $AllowedPaths -PreventPathTraversal)) {
        throw "Chemin non sécurisé: $Path"
    }
    
    # Vérifier si le répertoire parent existe
    $parentDir = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path -Path $parentDir -PathType Container)) {
        if ($Force) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }
        else {
            throw "Le répertoire parent n'existe pas: $parentDir"
        }
    }
    
    # Écrire le contenu dans le fichier
    Set-Content -Path $Path -Value $Content -Encoding $Encoding -Force:$Force
}

# Fonction pour copier un fichier de manière sécurisée
function Copy-SecureFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedSourcePaths = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedDestinationPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le chemin source est sécurisé
    if (-not (Test-SafePath -Path $Path -AllowedPaths $AllowedSourcePaths -PreventPathTraversal)) {
        throw "Chemin source non sécurisé: $Path"
    }
    
    # Vérifier si le chemin de destination est sécurisé
    if (-not (Test-SafePath -Path $Destination -AllowedPaths $AllowedDestinationPaths -PreventPathTraversal)) {
        throw "Chemin de destination non sécurisé: $Destination"
    }
    
    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Le fichier source n'existe pas: $Path"
    }
    
    # Vérifier si le répertoire de destination existe
    $destDir = Split-Path -Path $Destination -Parent
    if (-not [string]::IsNullOrEmpty($destDir) -and -not (Test-Path -Path $destDir -PathType Container)) {
        if ($Force) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        else {
            throw "Le répertoire de destination n'existe pas: $destDir"
        }
    }
    
    # Copier le fichier
    Copy-Item -Path $Path -Destination $Destination -Force:$Force
}

# Fonction pour supprimer un fichier de manière sécurisée
function Remove-SecureFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$Secure
    )
    
    # Vérifier si le chemin est sécurisé
    if (-not (Test-SafePath -Path $Path -AllowedPaths $AllowedPaths -PreventPathTraversal)) {
        throw "Chemin non sécurisé: $Path"
    }
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        if ($Force) {
            return
        }
        else {
            throw "Le fichier n'existe pas: $Path"
        }
    }
    
    # Supprimer le fichier de manière sécurisée si demandé
    if ($Secure) {
        # Obtenir la taille du fichier
        $fileInfo = Get-Item -Path $Path
        $fileSize = $fileInfo.Length
        
        # Écraser le fichier avec des zéros
        $buffer = New-Object byte[] 4096
        $stream = [System.IO.File]::OpenWrite($Path)
        
        try {
            for ($i = 0; $i -lt $fileSize; $i += $buffer.Length) {
                $bytesToWrite = [Math]::Min($buffer.Length, $fileSize - $i)
                $stream.Write($buffer, 0, $bytesToWrite)
            }
        }
        finally {
            $stream.Close()
        }
    }
    
    # Supprimer le fichier
    Remove-Item -Path $Path -Force
}

# Fonction pour vérifier les permissions d'un fichier
function Test-FilePermissions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireReadAccess,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireWriteAccess,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireExecuteAccess
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        return $false
    }
    
    try {
        $item = Get-Item -Path $Path
        
        # Vérifier les permissions de lecture
        if ($RequireReadAccess) {
            try {
                if ($item.PSIsContainer) {
                    $null = Get-ChildItem -Path $Path -ErrorAction Stop
                }
                else {
                    $null = Get-Content -Path $Path -TotalCount 1 -ErrorAction Stop
                }
            }
            catch {
                return $false
            }
        }
        
        # Vérifier les permissions d'écriture
        if ($RequireWriteAccess) {
            try {
                if ($item.PSIsContainer) {
                    $testFile = Join-Path -Path $Path -ChildPath ([System.IO.Path]::GetRandomFileName())
                    $null = New-Item -Path $testFile -ItemType File -ErrorAction Stop
                    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
                }
                else {
                    if ($item.IsReadOnly) {
                        return $false
                    }
                }
            }
            catch {
                return $false
            }
        }
        
        # Vérifier les permissions d'exécution (Windows uniquement)
        if ($RequireExecuteAccess -and $script:IsWindows) {
            if (-not $item.PSIsContainer -and $item.Extension -in @(".exe", ".bat", ".cmd", ".ps1")) {
                try {
                    $acl = Get-Acl -Path $Path
                    $hasExecutePermission = $acl.Access | Where-Object { $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::ExecuteFile }
                    
                    if (-not $hasExecutePermission) {
                        return $false
                    }
                }
                catch {
                    return $false
                }
            }
        }
        
        return $true
    }
    catch {
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-SecureFileContent, Set-SecureFileContent, Copy-SecureFile, Remove-SecureFile, Test-FilePermissions

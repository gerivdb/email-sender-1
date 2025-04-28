<#
.SYNOPSIS
    Fonctions publiques pour la gestion des chemins d'accès.

.DESCRIPTION
    Ce script contient des fonctions publiques pour initialiser, tester et réparer
    les chemins d'accès dans le système de fichiers.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Fonction pour initialiser les chemins d'accès
function Initialize-Paths {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Paths,

        [Parameter(Mandatory = $false)]
        [switch]$CreateIfMissing,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        $results = @{}

        foreach ($key in $Paths.Keys) {
            $path = $Paths[$key]
            
            # Vérifier si le chemin existe
            $exists = Test-Path -Path $path -ErrorAction SilentlyContinue
            
            if (-not $exists -and $CreateIfMissing) {
                # Déterminer si c'est un fichier ou un répertoire
                $isFile = [System.IO.Path]::HasExtension($path)
                
                if ($isFile) {
                    # Créer le répertoire parent
                    $parentPath = [System.IO.Path]::GetDirectoryName($path)
                    
                    if (-not (Test-Path -Path $parentPath -PathType Container)) {
                        if ($PSCmdlet.ShouldProcess($parentPath, "Créer le répertoire parent")) {
                            $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
                        }
                    }
                    
                    # Créer le fichier
                    if ($PSCmdlet.ShouldProcess($path, "Créer le fichier")) {
                        $null = New-Item -Path $path -ItemType File -Force -ErrorAction Stop
                    }
                } else {
                    # Créer le répertoire
                    if ($PSCmdlet.ShouldProcess($path, "Créer le répertoire")) {
                        $null = New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop
                    }
                }
                
                $exists = $true
            }
            
            $results[$key] = @{
                Path = $path
                Exists = $exists
                IsFile = $isFile
            }
        }
        
        return $results
    } catch {
        Write-Error "Erreur lors de l'initialisation des chemins: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour tester les chemins d'accès
function Test-Paths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Paths,

        [Parameter(Mandatory = $false)]
        [switch]$TestRead,

        [Parameter(Mandatory = $false)]
        [switch]$TestWrite,

        [Parameter(Mandatory = $false)]
        [switch]$TestExecute,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    try {
        $results = @{}

        foreach ($key in $Paths.Keys) {
            $path = $Paths[$key]
            
            # Tester le chemin
            $result = Test-PathPermissions -Path $path -TestRead:$TestRead -TestWrite:$TestWrite -TestExecute:$TestExecute -Detailed:$Detailed
            
            $results[$key] = $result
        }
        
        return $results
    } catch {
        Write-Error "Erreur lors du test des chemins: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour réparer les chemins d'accès
function Repair-Paths {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Paths,

        [Parameter(Mandatory = $false)]
        [switch]$GrantRead,

        [Parameter(Mandatory = $false)]
        [switch]$GrantWrite,

        [Parameter(Mandatory = $false)]
        [switch]$GrantExecute,

        [Parameter(Mandatory = $false)]
        [switch]$GrantFullControl,

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [string]$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,

        [Parameter(Mandatory = $false)]
        [switch]$CreateIfMissing
    )

    try {
        $results = @{}

        foreach ($key in $Paths.Keys) {
            $path = $Paths[$key]
            
            # Vérifier si le chemin existe
            $exists = Test-Path -Path $path -ErrorAction SilentlyContinue
            
            if (-not $exists) {
                if ($CreateIfMissing) {
                    # Déterminer si c'est un fichier ou un répertoire
                    $isFile = [System.IO.Path]::HasExtension($path)
                    
                    if ($isFile) {
                        # Créer le répertoire parent
                        $parentPath = [System.IO.Path]::GetDirectoryName($path)
                        
                        if (-not (Test-Path -Path $parentPath -PathType Container)) {
                            if ($PSCmdlet.ShouldProcess($parentPath, "Créer le répertoire parent")) {
                                $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
                            }
                        }
                        
                        # Créer le fichier
                        if ($PSCmdlet.ShouldProcess($path, "Créer le fichier")) {
                            $null = New-Item -Path $path -ItemType File -Force -ErrorAction Stop
                        }
                    } else {
                        # Créer le répertoire
                        if ($PSCmdlet.ShouldProcess($path, "Créer le répertoire")) {
                            $null = New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop
                        }
                    }
                    
                    $exists = $true
                } else {
                    $results[$key] = @{
                        Path = $path
                        Success = $false
                        Error = "Le chemin n'existe pas"
                    }
                    
                    continue
                }
            }
            
            # Réparer les permissions
            $result = Repair-PathPermissions -Path $path -GrantRead:$GrantRead -GrantWrite:$GrantWrite -GrantExecute:$GrantExecute -GrantFullControl:$GrantFullControl -Recursive:$Recursive -User $User -WhatIf:$WhatIfPreference
            
            $results[$key] = @{
                Path = $path
                Success = $result
                Error = if (-not $result) { "Échec de la réparation des permissions" } else { $null }
            }
        }
        
        return $results
    } catch {
        Write-Error "Erreur lors de la réparation des chemins: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour obtenir le chemin absolu
function Get-AbsolutePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyExists
    )

    try {
        $result = Resolve-RelativePath -Path $Path -BasePath $BasePath -VerifyExists:$VerifyExists
        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention du chemin absolu: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour obtenir le chemin relatif
function Get-RelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyExists
    )

    try {
        $result = Resolve-AbsolutePath -Path $Path -BasePath $BasePath -VerifyExists:$VerifyExists
        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention du chemin relatif: $($_.Exception.Message)"
        return $null
    }
}

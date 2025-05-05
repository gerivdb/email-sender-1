<#
.SYNOPSIS
    Fonctions publiques pour la gestion des chemins d'accÃ¨s.

.DESCRIPTION
    Ce script contient des fonctions publiques pour initialiser, tester et rÃ©parer
    les chemins d'accÃ¨s dans le systÃ¨me de fichiers.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Fonction pour initialiser les chemins d'accÃ¨s
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
            
            # VÃ©rifier si le chemin existe
            $exists = Test-Path -Path $path -ErrorAction SilentlyContinue
            
            if (-not $exists -and $CreateIfMissing) {
                # DÃ©terminer si c'est un fichier ou un rÃ©pertoire
                $isFile = [System.IO.Path]::HasExtension($path)
                
                if ($isFile) {
                    # CrÃ©er le rÃ©pertoire parent
                    $parentPath = [System.IO.Path]::GetDirectoryName($path)
                    
                    if (-not (Test-Path -Path $parentPath -PathType Container)) {
                        if ($PSCmdlet.ShouldProcess($parentPath, "CrÃ©er le rÃ©pertoire parent")) {
                            $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
                        }
                    }
                    
                    # CrÃ©er le fichier
                    if ($PSCmdlet.ShouldProcess($path, "CrÃ©er le fichier")) {
                        $null = New-Item -Path $path -ItemType File -Force -ErrorAction Stop
                    }
                } else {
                    # CrÃ©er le rÃ©pertoire
                    if ($PSCmdlet.ShouldProcess($path, "CrÃ©er le rÃ©pertoire")) {
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

# Fonction pour tester les chemins d'accÃ¨s
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

# Fonction pour rÃ©parer les chemins d'accÃ¨s
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
            
            # VÃ©rifier si le chemin existe
            $exists = Test-Path -Path $path -ErrorAction SilentlyContinue
            
            if (-not $exists) {
                if ($CreateIfMissing) {
                    # DÃ©terminer si c'est un fichier ou un rÃ©pertoire
                    $isFile = [System.IO.Path]::HasExtension($path)
                    
                    if ($isFile) {
                        # CrÃ©er le rÃ©pertoire parent
                        $parentPath = [System.IO.Path]::GetDirectoryName($path)
                        
                        if (-not (Test-Path -Path $parentPath -PathType Container)) {
                            if ($PSCmdlet.ShouldProcess($parentPath, "CrÃ©er le rÃ©pertoire parent")) {
                                $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
                            }
                        }
                        
                        # CrÃ©er le fichier
                        if ($PSCmdlet.ShouldProcess($path, "CrÃ©er le fichier")) {
                            $null = New-Item -Path $path -ItemType File -Force -ErrorAction Stop
                        }
                    } else {
                        # CrÃ©er le rÃ©pertoire
                        if ($PSCmdlet.ShouldProcess($path, "CrÃ©er le rÃ©pertoire")) {
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
            
            # RÃ©parer les permissions
            $result = Repair-PathPermissions -Path $path -GrantRead:$GrantRead -GrantWrite:$GrantWrite -GrantExecute:$GrantExecute -GrantFullControl:$GrantFullControl -Recursive:$Recursive -User $User -WhatIf:$WhatIfPreference
            
            $results[$key] = @{
                Path = $path
                Success = $result
                Error = if (-not $result) { "Ã‰chec de la rÃ©paration des permissions" } else { $null }
            }
        }
        
        return $results
    } catch {
        Write-Error "Erreur lors de la rÃ©paration des chemins: $($_.Exception.Message)"
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

<#
.SYNOPSIS
    Fonctions utilitaires pour gÃ©rer les permissions des chemins d'accÃ¨s.

.DESCRIPTION
    Ce script contient des fonctions pour vÃ©rifier et corriger les permissions
    des chemins d'accÃ¨s dans le systÃ¨me de fichiers.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Fonction pour vÃ©rifier les permissions d'un chemin
function Test-PathPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            if ($Detailed) {
                return [PSCustomObject]@{
                    Path                 = $Path
                    Exists               = $false
                    IsContainer          = $false
                    IsReadOnly           = $false
                    IsHidden             = $false
                    IsSystem             = $false
                    Owner                = $null
                    CurrentUserAccess    = $null
                    ReadAccess           = $false
                    WriteAccess          = $false
                    ExecuteAccess        = $false
                    AllAccess            = $false
                    AccessControlEntries = @()
                    Error                = "Le chemin n'existe pas"
                    TestResults          = $null
                }
            }
            return $false
        }

        # Obtenir les informations sur le fichier/dossier
        $item = Get-Item -Path $Path -Force
        $isContainer = $item -is [System.IO.DirectoryInfo]

        # VÃ©rifier les attributs
        $isReadOnly = $false
        $isHidden = $false
        $isSystem = $false

        if (-not $isContainer) {
            $isReadOnly = $item.IsReadOnly
            $isHidden = ($item.Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden
            $isSystem = ($item.Attributes -band [System.IO.FileAttributes]::System) -eq [System.IO.FileAttributes]::System
        }

        # Obtenir les ACL
        $acl = Get-Acl -Path $Path -ErrorAction Stop
        $owner = $acl.Owner

        # Obtenir l'utilisateur actuel
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        # VÃ©rifier les permissions
        $readAccess = $false
        $writeAccess = $false
        $executeAccess = $false
        $allAccess = $false

        # VÃ©rifier les permissions pour l'utilisateur actuel
        $userAccessRules = $acl.Access | Where-Object { $_.IdentityReference.Value -eq $currentUser -or $_.IdentityReference.Value -eq "BUILTIN\Administrators" -or $_.IdentityReference.Value -eq "NT AUTHORITY\SYSTEM" }

        foreach ($rule in $userAccessRules) {
            if ($rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Read) {
                $readAccess = $true
            }
            if ($rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write) {
                $writeAccess = $true
            }
            if ($rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::ExecuteFile) {
                $executeAccess = $true
            }
            if ($rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl) {
                $allAccess = $true
                $readAccess = $true
                $writeAccess = $true
                $executeAccess = $true
            }
        }

        # Effectuer les tests demandÃ©s
        $testResults = @{}

        if ($TestRead) {
            $testResults["Read"] = Test-ReadAccess -Path $Path
        }

        if ($TestWrite) {
            $testResults["Write"] = Test-WriteAccess -Path $Path
        }

        if ($TestExecute) {
            $testResults["Execute"] = Test-ExecuteAccess -Path $Path
        }

        # Retourner les rÃ©sultats dÃ©taillÃ©s si demandÃ©
        if ($Detailed) {
            return [PSCustomObject]@{
                Path                 = $Path
                Exists               = $true
                IsContainer          = $isContainer
                IsReadOnly           = $isReadOnly
                IsHidden             = $isHidden
                IsSystem             = $isSystem
                Owner                = $owner
                CurrentUserAccess    = $userAccessRules
                ReadAccess           = $readAccess
                WriteAccess          = $writeAccess
                ExecuteAccess        = $executeAccess
                AllAccess            = $allAccess
                AccessControlEntries = $acl.Access
                Error                = $null
                TestResults          = $testResults
            }
        }

        # Retourner un rÃ©sultat simple
        return $readAccess -and $writeAccess -and $executeAccess
    } catch {
        if ($Detailed) {
            return [PSCustomObject]@{
                Path                 = $Path
                Exists               = $true
                IsContainer          = $null
                IsReadOnly           = $null
                IsHidden             = $null
                IsSystem             = $null
                Owner                = $null
                CurrentUserAccess    = $null
                ReadAccess           = $false
                WriteAccess          = $false
                ExecuteAccess        = $false
                AllAccess            = $false
                AccessControlEntries = @()
                Error                = $_.Exception.Message
                TestResults          = $null
            }
        }
        return $false
    }
}

# Fonction pour tester l'accÃ¨s en lecture
function Test-ReadAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            return $false
        }

        # VÃ©rifier si c'est un dossier ou un fichier
        $item = Get-Item -Path $Path -Force

        if ($item -is [System.IO.DirectoryInfo]) {
            # Pour un dossier, essayer de lister les fichiers
            $null = Get-ChildItem -Path $Path -Force -ErrorAction Stop
        } else {
            # Pour un fichier, essayer de lire le contenu
            $null = Get-Content -Path $Path -TotalCount 1 -ErrorAction Stop
        }

        return $true
    } catch {
        return $false
    }
}

# Fonction pour tester l'accÃ¨s en Ã©criture
function Test-WriteAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            return $false
        }

        # VÃ©rifier si c'est un dossier ou un fichier
        $item = Get-Item -Path $Path -Force

        if ($item -is [System.IO.DirectoryInfo]) {
            # Pour un dossier, essayer de crÃ©er un fichier temporaire
            $tempFile = Join-Path -Path $Path -ChildPath "temp_$([Guid]::NewGuid().ToString()).tmp"
            $null = New-Item -Path $tempFile -ItemType File -ErrorAction Stop
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        } else {
            # Pour un fichier, essayer d'ajouter du contenu
            $originalContent = Get-Content -Path $Path -Raw -ErrorAction Stop
            Add-Content -Path $Path -Value "" -ErrorAction Stop
            Set-Content -Path $Path -Value $originalContent -ErrorAction Stop
        }

        return $true
    } catch {
        return $false
    }
}

# Fonction pour tester l'accÃ¨s en exÃ©cution
function Test-ExecuteAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            return $false
        }

        # VÃ©rifier si c'est un dossier ou un fichier
        $item = Get-Item -Path $Path -Force

        if ($item -is [System.IO.DirectoryInfo]) {
            # Pour un dossier, vÃ©rifier si on peut y accÃ©der
            $null = Get-ChildItem -Path $Path -Force -ErrorAction Stop
            return $true
        } else {
            # Pour un fichier, vÃ©rifier l'extension
            $extension = [System.IO.Path]::GetExtension($Path).ToLower()

            if ($extension -in @(".exe", ".bat", ".cmd", ".ps1", ".psm1", ".psd1")) {
                # VÃ©rifier les permissions d'exÃ©cution via ACL
                $acl = Get-Acl -Path $Path -ErrorAction Stop
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

                $userAccessRules = $acl.Access | Where-Object { $_.IdentityReference.Value -eq $currentUser -or $_.IdentityReference.Value -eq "BUILTIN\Administrators" -or $_.IdentityReference.Value -eq "NT AUTHORITY\SYSTEM" }

                foreach ($rule in $userAccessRules) {
                    if ($rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::ExecuteFile -or $rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl) {
                        return $true
                    }
                }

                return $false
            } else {
                # Pour les fichiers non exÃ©cutables, l'accÃ¨s en exÃ©cution n'est pas applicable
                return $true
            }
        }
    } catch {
        return $false
    }
}

# Fonction pour corriger les permissions d'un chemin
function Repair-PathPermissions {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

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
        [string]$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    )

    try {
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            Write-Warning "Le chemin '$Path' n'existe pas."
            return $false
        }

        # Obtenir les ACL actuelles
        $acl = Get-Acl -Path $Path -ErrorAction Stop

        # DÃ©terminer les permissions Ã  accorder
        $fileSystemRights = [System.Security.AccessControl.FileSystemRights]::None

        if ($GrantRead) {
            $fileSystemRights = $fileSystemRights -bor [System.Security.AccessControl.FileSystemRights]::Read
        }

        if ($GrantWrite) {
            $fileSystemRights = $fileSystemRights -bor [System.Security.AccessControl.FileSystemRights]::Write
        }

        if ($GrantExecute) {
            $fileSystemRights = $fileSystemRights -bor [System.Security.AccessControl.FileSystemRights]::ExecuteFile
        }

        if ($GrantFullControl) {
            $fileSystemRights = [System.Security.AccessControl.FileSystemRights]::FullControl
        }

        # Si aucune permission n'est spÃ©cifiÃ©e, accorder toutes les permissions
        if ($fileSystemRights -eq [System.Security.AccessControl.FileSystemRights]::None) {
            $fileSystemRights = [System.Security.AccessControl.FileSystemRights]::FullControl
        }

        # CrÃ©er une rÃ¨gle d'accÃ¨s
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $User,
            $fileSystemRights,
            [System.Security.AccessControl.InheritanceFlags]::None,
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )

        # Ajouter la rÃ¨gle d'accÃ¨s aux ACL
        $acl.AddAccessRule($accessRule)

        # Appliquer les nouvelles ACL
        if ($PSCmdlet.ShouldProcess($Path, "Modifier les permissions")) {
            Set-Acl -Path $Path -AclObject $acl -ErrorAction Stop
        }

        # Si rÃ©cursif, appliquer aux sous-dossiers et fichiers
        if ($Recursive -and (Test-Path -Path $Path -PathType Container)) {
            $items = Get-ChildItem -Path $Path -Recurse -Force

            foreach ($item in $items) {
                $itemAcl = Get-Acl -Path $item.FullName -ErrorAction Continue

                if ($itemAcl) {
                    $itemAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                        $User,
                        $fileSystemRights,
                        [System.Security.AccessControl.InheritanceFlags]::None,
                        [System.Security.AccessControl.PropagationFlags]::None,
                        [System.Security.AccessControl.AccessControlType]::Allow
                    )

                    $itemAcl.AddAccessRule($itemAccessRule)

                    if ($PSCmdlet.ShouldProcess($item.FullName, "Modifier les permissions")) {
                        Set-Acl -Path $item.FullName -AclObject $itemAcl -ErrorAction Continue
                    }
                }
            }
        }

        return $true
    } catch {
        Write-Warning "Erreur lors de la modification des permissions pour '$Path': $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour crÃ©er un rÃ©pertoire avec les permissions appropriÃ©es
function New-DirectoryWithPermissions {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$GrantRead,

        [Parameter(Mandatory = $false)]
        [switch]$GrantWrite,

        [Parameter(Mandatory = $false)]
        [switch]$GrantExecute,

        [Parameter(Mandatory = $false)]
        [switch]$GrantFullControl,

        [Parameter(Mandatory = $false)]
        [string]$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        # VÃ©rifier si le chemin existe dÃ©jÃ 
        if (Test-Path -Path $Path -PathType Container) {
            if ($Force) {
                # Si Force est spÃ©cifiÃ©, modifier les permissions du rÃ©pertoire existant
                $result = Repair-PathPermissions -Path $Path -GrantRead:$GrantRead -GrantWrite:$GrantWrite -GrantExecute:$GrantExecute -GrantFullControl:$GrantFullControl -User $User -WhatIf:$WhatIfPreference
                return $result
            } else {
                Write-Warning "Le rÃ©pertoire '$Path' existe dÃ©jÃ . Utilisez -Force pour modifier ses permissions."
                return $false
            }
        }

        # CrÃ©er le rÃ©pertoire
        if ($PSCmdlet.ShouldProcess($Path, "CrÃ©er le rÃ©pertoire")) {
            $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
        }

        # Modifier les permissions
        $result = Repair-PathPermissions -Path $Path -GrantRead:$GrantRead -GrantWrite:$GrantWrite -GrantExecute:$GrantExecute -GrantFullControl:$GrantFullControl -User $User -WhatIf:$WhatIfPreference

        return $result
    } catch {
        Write-Warning "Erreur lors de la crÃ©ation du rÃ©pertoire '$Path': $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour vÃ©rifier et corriger les permissions d'un chemin
function Ensure-PathPermissions {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

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
        [switch]$CreateIfMissing,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        # VÃ©rifier si le chemin existe
        $pathExists = Test-Path -Path $Path -ErrorAction SilentlyContinue

        if (-not $pathExists) {
            if ($CreateIfMissing) {
                # DÃ©terminer si c'est un fichier ou un rÃ©pertoire
                $isFile = [System.IO.Path]::HasExtension($Path)

                if ($isFile) {
                    # CrÃ©er le rÃ©pertoire parent
                    $parentPath = [System.IO.Path]::GetDirectoryName($Path)

                    if (-not (Test-Path -Path $parentPath -PathType Container)) {
                        $result = New-DirectoryWithPermissions -Path $parentPath -GrantFullControl -User $User -Force:$Force -WhatIf:$WhatIfPreference

                        if (-not $result) {
                            Write-Warning "Impossible de crÃ©er le rÃ©pertoire parent '$parentPath'."
                            return $false
                        }
                    }

                    # CrÃ©er le fichier
                    if ($PSCmdlet.ShouldProcess($Path, "CrÃ©er le fichier")) {
                        $null = New-Item -Path $Path -ItemType File -Force -ErrorAction Stop
                    }
                } else {
                    # CrÃ©er le rÃ©pertoire
                    $result = New-DirectoryWithPermissions -Path $Path -GrantFullControl -User $User -Force:$Force -WhatIf:$WhatIfPreference

                    if (-not $result) {
                        Write-Warning "Impossible de crÃ©er le rÃ©pertoire '$Path'."
                        return $false
                    }
                }
            } else {
                Write-Warning "Le chemin '$Path' n'existe pas. Utilisez -CreateIfMissing pour le crÃ©er."
                return $false
            }
        }

        # VÃ©rifier les permissions actuelles
        $permissions = Test-PathPermissions -Path $Path -TestRead:$GrantRead -TestWrite:$GrantWrite -TestExecute:$GrantExecute -Detailed

        # DÃ©terminer si des corrections sont nÃ©cessaires
        $needsCorrection = $false

        if ($GrantRead -and -not $permissions.ReadAccess) {
            $needsCorrection = $true
        }

        if ($GrantWrite -and -not $permissions.WriteAccess) {
            $needsCorrection = $true
        }

        if ($GrantExecute -and -not $permissions.ExecuteAccess) {
            $needsCorrection = $true
        }

        if ($GrantFullControl -and -not $permissions.AllAccess) {
            $needsCorrection = $true
        }

        # Corriger les permissions si nÃ©cessaire
        if ($needsCorrection -or $Force) {
            $result = Repair-PathPermissions -Path $Path -GrantRead:$GrantRead -GrantWrite:$GrantWrite -GrantExecute:$GrantExecute -GrantFullControl:$GrantFullControl -Recursive:$Recursive -User $User -WhatIf:$WhatIfPreference

            if (-not $result) {
                Write-Warning "Impossible de corriger les permissions pour '$Path'."
                return $false
            }
        }

        return $true
    } catch {
        Write-Warning "Erreur lors de la vÃ©rification et correction des permissions pour '$Path': $($_.Exception.Message)"
        return $false
    }
}

# Les fonctions seront exportÃ©es par le module principal

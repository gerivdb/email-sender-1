<#
.SYNOPSIS
    Exemples de dÃ©bogage pour les scÃ©narios courants d'accÃ¨s refusÃ©.
.DESCRIPTION
    Ce script fournit des exemples concrets pour dÃ©boguer diffÃ©rents scÃ©narios
    d'accÃ¨s refusÃ©, notamment pour les fichiers systÃ¨me protÃ©gÃ©s, les clÃ©s de registre,
    les problÃ¨mes d'accÃ¨s rÃ©seau et les bases de donnÃ©es.
.NOTES
    Auteur: Augment Code
    Date de crÃ©ation: 2023-11-15
#>

# Importer les fonctions de diagnostic des permissions
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "FilePermissionDiagnostic.ps1"
. $scriptPath

# Importer les fonctions d'Ã©lÃ©vation de privilÃ¨ges
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PrivilegeElevationTools.ps1"
. $scriptPath

function Debug-SystemFileAccess {
    <#
    .SYNOPSIS
        DÃ©montre et dÃ©bogue l'accÃ¨s Ã  un fichier systÃ¨me protÃ©gÃ©.

    .DESCRIPTION
        Cette fonction tente d'accÃ©der Ã  un fichier systÃ¨me protÃ©gÃ© de diffÃ©rentes maniÃ¨res
        et montre comment dÃ©boguer et rÃ©soudre les problÃ¨mes d'accÃ¨s.

    .PARAMETER FilePath
        Le chemin du fichier systÃ¨me protÃ©gÃ© Ã  dÃ©boguer.

    .EXAMPLE
        Debug-SystemFileAccess -FilePath "C:\Windows\System32\config\SAM"

    .OUTPUTS
        [PSCustomObject] avec des informations sur les diffÃ©rentes tentatives d'accÃ¨s
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $results = [PSCustomObject]@{
        FilePath = $FilePath
        FileExists = $false
        DirectAccessResult = $null
        BackupPrivilegeResult = $null
        TakeOwnershipResult = $null
        CopyWithElevationResult = $null
        ShadowCopyResult = $null
        Recommendations = @()
    }

    # 1. VÃ©rifier si le fichier existe
    $results.FileExists = Test-Path -Path $FilePath -ErrorAction SilentlyContinue

    if (-not $results.FileExists) {
        Write-Warning "Le fichier '$FilePath' n'existe pas."
        $results.Recommendations += "VÃ©rifiez que le chemin du fichier est correct."
        return $results
    }

    # 2. Analyser les permissions actuelles
    Write-Host "`n=== Analyse des permissions actuelles ===" -ForegroundColor Cyan
    $permissionsResult = Test-PathPermissions -Path $FilePath -TestRead -TestWrite -Detailed
    Format-PathPermissionsReport -PermissionsResult $permissionsResult

    # 3. Tenter un accÃ¨s direct
    Write-Host "`n=== Tentative d'accÃ¨s direct ===" -ForegroundColor Cyan
    $directAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
        Get-Content -Path $FilePath -TotalCount 1
    } -Path $FilePath -AnalyzePermissions

    $results.DirectAccessResult = if ($directAccessResult.Success) { "SuccÃ¨s" } else { "Ã‰chec" }

    if (-not $directAccessResult.Success) {
        Write-Host "L'accÃ¨s direct a Ã©chouÃ© comme prÃ©vu pour un fichier systÃ¨me protÃ©gÃ©." -ForegroundColor Yellow
        Format-UnauthorizedAccessReport -DebugResult $directAccessResult
    } else {
        Write-Host "L'accÃ¨s direct a rÃ©ussi, ce qui est inhabituel pour un fichier systÃ¨me protÃ©gÃ©." -ForegroundColor Green
    }

    # 4. Tenter d'utiliser le privilÃ¨ge SeBackupPrivilege
    Write-Host "`n=== Tentative avec le privilÃ¨ge SeBackupPrivilege ===" -ForegroundColor Cyan
    $backupPrivilegeSuccess = $false

    try {
        $backupPrivilegeEnabled = Enable-Privilege -Privilege "SeBackupPrivilege"

        if ($backupPrivilegeEnabled) {
            Write-Host "PrivilÃ¨ge SeBackupPrivilege activÃ© avec succÃ¨s." -ForegroundColor Green

            # CrÃ©er un rÃ©pertoire temporaire pour la sauvegarde
            $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            $backupPath = Join-Path -Path $tempDir -ChildPath ([System.IO.Path]::GetFileName($FilePath))

            try {
                # Tenter de copier le fichier avec le privilÃ¨ge de sauvegarde
                Copy-Item -Path $FilePath -Destination $backupPath -ErrorAction Stop
                $backupPrivilegeSuccess = $true
                Write-Host "Fichier copiÃ© avec succÃ¨s en utilisant le privilÃ¨ge SeBackupPrivilege." -ForegroundColor Green
                Write-Host "Chemin de la copie: $backupPath"
            } catch {
                Write-Host "Ã‰chec de la copie malgrÃ© l'activation du privilÃ¨ge SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
            } finally {
                # Nettoyer
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "Impossible d'activer le privilÃ¨ge SeBackupPrivilege. Vous devez Ãªtre administrateur." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'utilisation du privilÃ¨ge SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.BackupPrivilegeResult = if ($backupPrivilegeSuccess) { "SuccÃ¨s" } else { "Ã‰chec" }

    # 5. Tenter de prendre possession du fichier
    Write-Host "`n=== Tentative de prise de possession du fichier ===" -ForegroundColor Cyan
    $takeOwnershipSuccess = $false

    try {
        # Activer le privilÃ¨ge SeTakeOwnershipPrivilege
        $takeOwnershipEnabled = Enable-Privilege -Privilege "SeTakeOwnershipPrivilege"

        if ($takeOwnershipEnabled) {
            Write-Host "PrivilÃ¨ge SeTakeOwnershipPrivilege activÃ© avec succÃ¨s." -ForegroundColor Green

            # Tenter de prendre possession du fichier
            $acl = Get-Acl -Path $FilePath
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $acl.SetOwner([System.Security.Principal.NTAccount]$currentUser)

            try {
                Set-Acl -Path $FilePath -AclObject $acl -ErrorAction Stop
                $takeOwnershipSuccess = $true
                Write-Host "Prise de possession du fichier rÃ©ussie." -ForegroundColor Green

                # Ajouter des droits de lecture
                $acl = Get-Acl -Path $FilePath
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $currentUser,
                    [System.Security.AccessControl.FileSystemRights]::Read,
                    [System.Security.AccessControl.AccessControlType]::Allow
                )
                $acl.AddAccessRule($accessRule)
                Set-Acl -Path $FilePath -AclObject $acl

                Write-Host "Droits de lecture ajoutÃ©s avec succÃ¨s." -ForegroundColor Green
            } catch {
                Write-Host "Ã‰chec de la prise de possession: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Impossible d'activer le privilÃ¨ge SeTakeOwnershipPrivilege." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la prise de possession: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.TakeOwnershipResult = if ($takeOwnershipSuccess) { "SuccÃ¨s" } else { "Ã‰chec" }

    # 6. Tenter d'utiliser un processus Ã©levÃ©
    Write-Host "`n=== Tentative avec un processus Ã©levÃ© ===" -ForegroundColor Cyan
    $elevatedCopySuccess = $false

    try {
        # CrÃ©er un rÃ©pertoire temporaire pour la copie
        $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        $copyPath = Join-Path -Path $tempDir -ChildPath ([System.IO.Path]::GetFileName($FilePath))

        # Tenter de copier le fichier avec un processus Ã©levÃ©
        $result = Edit-ProtectedFile -Path $FilePath -EditScriptBlock {
            param($TempFile)
            # Ne pas modifier le fichier, juste le copier
            return $true
        }

        if ($result.Success) {
            $elevatedCopySuccess = $true
            Write-Host "Copie avec processus Ã©levÃ© rÃ©ussie." -ForegroundColor Green
        } else {
            Write-Host "Ã‰chec de la copie avec processus Ã©levÃ©: $($result.Message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la copie avec processus Ã©levÃ©: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Nettoyer
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    $results.CopyWithElevationResult = if ($elevatedCopySuccess) { "SuccÃ¨s" } else { "Ã‰chec" }

    # 7. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    if ($backupPrivilegeSuccess) {
        $results.Recommendations += "Utilisez le privilÃ¨ge SeBackupPrivilege pour accÃ©der au fichier en lecture seule."
        Write-Host "- Utilisez le privilÃ¨ge SeBackupPrivilege pour accÃ©der au fichier en lecture seule." -ForegroundColor Green
    }

    if ($takeOwnershipSuccess) {
        $results.Recommendations += "Prenez possession du fichier pour modifier ses permissions."
        Write-Host "- Prenez possession du fichier pour modifier ses permissions." -ForegroundColor Green
    }

    if ($elevatedCopySuccess) {
        $results.Recommendations += "Utilisez un processus Ã©levÃ© pour copier le fichier."
        Write-Host "- Utilisez un processus Ã©levÃ© pour copier le fichier." -ForegroundColor Green
    }

    if (-not ($backupPrivilegeSuccess -or $takeOwnershipSuccess -or $elevatedCopySuccess)) {
        $results.Recommendations += "Utilisez des outils systÃ¨me spÃ©cialisÃ©s comme 'ntdsutil' pour les fichiers de base de donnÃ©es Active Directory."
        $results.Recommendations += "CrÃ©ez une copie de volume shadow (VSS) pour accÃ©der aux fichiers verrouillÃ©s par le systÃ¨me."
        $results.Recommendations += "DÃ©marrez en mode sans Ã©chec ou utilisez un environnement de rÃ©cupÃ©ration Windows pour accÃ©der aux fichiers systÃ¨me."

        Write-Host "- Utilisez des outils systÃ¨me spÃ©cialisÃ©s comme 'ntdsutil' pour les fichiers de base de donnÃ©es Active Directory." -ForegroundColor Yellow
        Write-Host "- CrÃ©ez une copie de volume shadow (VSS) pour accÃ©der aux fichiers verrouillÃ©s par le systÃ¨me." -ForegroundColor Yellow
        Write-Host "- DÃ©marrez en mode sans Ã©chec ou utilisez un environnement de rÃ©cupÃ©ration Windows pour accÃ©der aux fichiers systÃ¨me." -ForegroundColor Yellow
    }

    return $results
}

function Debug-RegistryKeyAccess {
    <#
    .SYNOPSIS
        DÃ©montre et dÃ©bogue l'accÃ¨s Ã  une clÃ© de registre protÃ©gÃ©e.

    .DESCRIPTION
        Cette fonction tente d'accÃ©der Ã  une clÃ© de registre protÃ©gÃ©e de diffÃ©rentes maniÃ¨res
        et montre comment dÃ©boguer et rÃ©soudre les problÃ¨mes d'accÃ¨s.

    .PARAMETER RegistryPath
        Le chemin de la clÃ© de registre protÃ©gÃ©e Ã  dÃ©boguer.

    .EXAMPLE
        Debug-RegistryKeyAccess -RegistryPath "HKLM:\SECURITY\Policy"

    .OUTPUTS
        [PSCustomObject] avec des informations sur les diffÃ©rentes tentatives d'accÃ¨s
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RegistryPath
    )

    $results = [PSCustomObject]@{
        RegistryPath = $RegistryPath
        KeyExists = $false
        DirectAccessResult = $null
        BackupPrivilegeResult = $null
        TakeOwnershipResult = $null
        ElevatedAccessResult = $null
        Recommendations = @()
    }

    # 1. VÃ©rifier si la clÃ© de registre existe
    $results.KeyExists = Test-Path -Path $RegistryPath -ErrorAction SilentlyContinue

    if (-not $results.KeyExists) {
        Write-Warning "La clÃ© de registre '$RegistryPath' n'existe pas."
        $results.Recommendations += "VÃ©rifiez que le chemin de la clÃ© de registre est correct."
        return $results
    }

    # 2. Tenter un accÃ¨s direct
    Write-Host "`n=== Tentative d'accÃ¨s direct ===" -ForegroundColor Cyan
    $directAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
        Get-ItemProperty -Path $RegistryPath -ErrorAction Stop
    } -Path $RegistryPath

    $results.DirectAccessResult = if ($directAccessResult.Success) { "SuccÃ¨s" } else { "Ã‰chec" }

    if (-not $directAccessResult.Success) {
        Write-Host "L'accÃ¨s direct a Ã©chouÃ© comme prÃ©vu pour une clÃ© de registre protÃ©gÃ©e." -ForegroundColor Yellow
        Format-UnauthorizedAccessReport -DebugResult $directAccessResult
    } else {
        Write-Host "L'accÃ¨s direct a rÃ©ussi, ce qui est inhabituel pour une clÃ© de registre protÃ©gÃ©e." -ForegroundColor Green
    }

    # 3. Tenter d'utiliser le privilÃ¨ge SeBackupPrivilege
    Write-Host "`n=== Tentative avec le privilÃ¨ge SeBackupPrivilege ===" -ForegroundColor Cyan
    $backupPrivilegeSuccess = $false

    try {
        $backupPrivilegeEnabled = Enable-Privilege -Privilege "SeBackupPrivilege"

        if ($backupPrivilegeEnabled) {
            Write-Host "PrivilÃ¨ge SeBackupPrivilege activÃ© avec succÃ¨s." -ForegroundColor Green

            try {
                # Tenter d'accÃ©der Ã  la clÃ© de registre avec le privilÃ¨ge de sauvegarde
                $regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
                    [Microsoft.Win32.RegistryHive]::LocalMachine,
                    [Environment]::MachineName
                )

                # Extraire le chemin relatif (sans HKLM:\)
                $relativePath = $RegistryPath -replace "^HKLM:\\", ""

                # Ouvrir la clÃ© avec des droits de lecture
                $key = $regKey.OpenSubKey($relativePath, $false)

                if ($key -ne $null) {
                    $backupPrivilegeSuccess = $true
                    Write-Host "AccÃ¨s Ã  la clÃ© de registre rÃ©ussi en utilisant le privilÃ¨ge SeBackupPrivilege." -ForegroundColor Green

                    # Afficher les valeurs de la clÃ©
                    Write-Host "Valeurs de la clÃ©:"
                    foreach ($valueName in $key.GetValueNames()) {
                        $value = $key.GetValue($valueName)
                        $valueType = $key.GetValueKind($valueName)
                        Write-Host "  $valueName = $value ($valueType)"
                    }

                    # Fermer la clÃ©
                    $key.Close()
                } else {
                    Write-Host "Impossible d'ouvrir la clÃ© de registre malgrÃ© l'activation du privilÃ¨ge SeBackupPrivilege." -ForegroundColor Red
                }
            } catch {
                Write-Host "Ã‰chec de l'accÃ¨s malgrÃ© l'activation du privilÃ¨ge SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Impossible d'activer le privilÃ¨ge SeBackupPrivilege. Vous devez Ãªtre administrateur." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'utilisation du privilÃ¨ge SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.BackupPrivilegeResult = if ($backupPrivilegeSuccess) { "SuccÃ¨s" } else { "Ã‰chec" }

    # 4. Tenter de prendre possession de la clÃ© de registre
    Write-Host "`n=== Tentative de prise de possession de la clÃ© de registre ===" -ForegroundColor Cyan
    $takeOwnershipSuccess = $false

    try {
        # Activer le privilÃ¨ge SeTakeOwnershipPrivilege
        $takeOwnershipEnabled = Enable-Privilege -Privilege "SeTakeOwnershipPrivilege"

        if ($takeOwnershipEnabled) {
            Write-Host "PrivilÃ¨ge SeTakeOwnershipPrivilege activÃ© avec succÃ¨s." -ForegroundColor Green

            # Tenter de prendre possession de la clÃ© de registre
            $script = {
                param($Path)

                try {
                    # Charger l'assembly pour les ACL de registre
                    Add-Type -AssemblyName System.Security

                    # Obtenir la clÃ© de registre
                    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
                        $Path.Replace("HKLM:\", ""),
                        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
                        [System.Security.AccessControl.RegistryRights]::TakeOwnership
                    )

                    if ($key -ne $null) {
                        # Obtenir les ACL actuelles
                        $acl = $key.GetAccessControl()

                        # DÃ©finir le propriÃ©taire
                        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
                        $acl.SetOwner($currentUser)

                        # Appliquer les nouvelles ACL
                        $key.SetAccessControl($acl)

                        # Fermer la clÃ©
                        $key.Close()

                        # Rouvrir la clÃ© avec des droits complets
                        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
                            $Path.Replace("HKLM:\", ""),
                            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
                            [System.Security.AccessControl.RegistryRights]::FullControl
                        )

                        # Obtenir les ACL actuelles
                        $acl = $key.GetAccessControl()

                        # Ajouter une rÃ¨gle d'accÃ¨s pour l'utilisateur actuel
                        $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
                            $currentUser,
                            [System.Security.AccessControl.RegistryRights]::FullControl,
                            [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                            [System.Security.AccessControl.PropagationFlags]::None,
                            [System.Security.AccessControl.AccessControlType]::Allow
                        )

                        $acl.AddAccessRule($rule)

                        # Appliquer les nouvelles ACL
                        $key.SetAccessControl($acl)

                        # Fermer la clÃ©
                        $key.Close()

                        return $true
                    } else {
                        return $false
                    }
                } catch {
                    Write-Error $_.Exception.Message
                    return $false
                }
            }

            # ExÃ©cuter le script avec des privilÃ¨ges Ã©levÃ©s
            $result = Start-ElevatedProcess -ScriptBlock $script -ArgumentList $RegistryPath -Wait

            if ($result -eq 0) {
                $takeOwnershipSuccess = $true
                Write-Host "Prise de possession de la clÃ© de registre rÃ©ussie." -ForegroundColor Green
            } else {
                Write-Host "Ã‰chec de la prise de possession de la clÃ© de registre." -ForegroundColor Red
            }
        } else {
            Write-Host "Impossible d'activer le privilÃ¨ge SeTakeOwnershipPrivilege." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la prise de possession: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.TakeOwnershipResult = if ($takeOwnershipSuccess) { "SuccÃ¨s" } else { "Ã‰chec" }

    # 5. Tenter d'utiliser un processus Ã©levÃ©
    Write-Host "`n=== Tentative avec un processus Ã©levÃ© ===" -ForegroundColor Cyan
    $elevatedAccessSuccess = $false

    try {
        $script = {
            param($Path)

            try {
                $key = Get-ItemProperty -Path $Path -ErrorAction Stop
                $properties = $key | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

                $result = [PSCustomObject]@{
                    Success = $true
                    Properties = $properties
                    Values = @{}
                }

                foreach ($prop in $properties) {
                    if ($prop -ne "PSPath" -and $prop -ne "PSParentPath" -and $prop -ne "PSChildName" -and $prop -ne "PSProvider") {
                        $result.Values[$prop] = $key.$prop
                    }
                }

                return $result | ConvertTo-Json -Compress
            } catch {
                return [PSCustomObject]@{
                    Success = $false
                    Error = $_.Exception.Message
                } | ConvertTo-Json -Compress
            }
        }

        $jsonResult = Start-ElevatedProcess -ScriptBlock $script -ArgumentList $RegistryPath -Wait

        if ($jsonResult -eq 0) {
            $elevatedAccessSuccess = $true
            Write-Host "AccÃ¨s avec processus Ã©levÃ© rÃ©ussi." -ForegroundColor Green
        } else {
            Write-Host "Ã‰chec de l'accÃ¨s avec processus Ã©levÃ©." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'accÃ¨s avec processus Ã©levÃ©: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.ElevatedAccessResult = if ($elevatedAccessSuccess) { "SuccÃ¨s" } else { "Ã‰chec" }

    # 6. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    if ($backupPrivilegeSuccess) {
        $results.Recommendations += "Utilisez le privilÃ¨ge SeBackupPrivilege pour accÃ©der Ã  la clÃ© de registre en lecture seule."
        Write-Host "- Utilisez le privilÃ¨ge SeBackupPrivilege pour accÃ©der Ã  la clÃ© de registre en lecture seule." -ForegroundColor Green
    }

    if ($takeOwnershipSuccess) {
        $results.Recommendations += "Prenez possession de la clÃ© de registre pour modifier ses permissions."
        Write-Host "- Prenez possession de la clÃ© de registre pour modifier ses permissions." -ForegroundColor Green
    }

    if ($elevatedAccessSuccess) {
        $results.Recommendations += "Utilisez un processus Ã©levÃ© pour accÃ©der Ã  la clÃ© de registre."
        Write-Host "- Utilisez un processus Ã©levÃ© pour accÃ©der Ã  la clÃ© de registre." -ForegroundColor Green
    }

    if (-not ($backupPrivilegeSuccess -or $takeOwnershipSuccess -or $elevatedAccessSuccess)) {
        $results.Recommendations += "Utilisez l'Ã©diteur de registre (regedit.exe) en mode administrateur."
        $results.Recommendations += "Utilisez l'outil de ligne de commande reg.exe avec des privilÃ¨ges Ã©levÃ©s."
        $results.Recommendations += "Utilisez PowerShell avec le module PSRemoting pour accÃ©der au registre Ã  distance."

        Write-Host "- Utilisez l'Ã©diteur de registre (regedit.exe) en mode administrateur." -ForegroundColor Yellow
        Write-Host "- Utilisez l'outil de ligne de commande reg.exe avec des privilÃ¨ges Ã©levÃ©s." -ForegroundColor Yellow
        Write-Host "- Utilisez PowerShell avec le module PSRemoting pour accÃ©der au registre Ã  distance." -ForegroundColor Yellow
    }

    return $results
}

function Debug-NetworkAccess {
    <#
    .SYNOPSIS
        DÃ©montre et dÃ©bogue l'accÃ¨s Ã  une ressource rÃ©seau.

    .DESCRIPTION
        Cette fonction tente d'accÃ©der Ã  une ressource rÃ©seau de diffÃ©rentes maniÃ¨res
        et montre comment dÃ©boguer et rÃ©soudre les problÃ¨mes d'accÃ¨s.

    .PARAMETER NetworkPath
        Le chemin de la ressource rÃ©seau Ã  dÃ©boguer (UNC).

    .PARAMETER Credential
        Les informations d'identification Ã  utiliser pour l'accÃ¨s rÃ©seau.

    .EXAMPLE
        Debug-NetworkAccess -NetworkPath "\\server\share\file.txt"

    .EXAMPLE
        $cred = Get-Credential
        Debug-NetworkAccess -NetworkPath "\\server\share\file.txt" -Credential $cred

    .OUTPUTS
        [PSCustomObject] avec des informations sur les diffÃ©rentes tentatives d'accÃ¨s
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NetworkPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $results = [PSCustomObject]@{
        NetworkPath = $NetworkPath
        Server = $null
        Share = $null
        PathExists = $false
        DirectAccessResult = $null
        CredentialAccessResult = $null
        ImpersonationResult = $null
        PingResult = $null
        PortScanResult = $null
        NetworkDiagnostics = @{}
        Recommendations = @()
    }

    # Extraire le serveur et le partage du chemin rÃ©seau
    if ($NetworkPath -match "\\\\([^\\]+)\\([^\\]+)") {
        $results.Server = $matches[1]
        $results.Share = $matches[2]
    } else {
        Write-Warning "Le chemin rÃ©seau '$NetworkPath' n'est pas un chemin UNC valide (format attendu: \\server\share\...)."
        $results.Recommendations += "Utilisez un chemin UNC valide au format \\server\share\..."
        return $results
    }

    # 1. VÃ©rifier si le serveur rÃ©pond au ping
    Write-Host "`n=== Test de connectivitÃ© rÃ©seau (Ping) ===" -ForegroundColor Cyan
    try {
        $pingResult = Test-Connection -ComputerName $results.Server -Count 2 -Quiet
        $results.PingResult = $pingResult

        if ($pingResult) {
            Write-Host "Le serveur '$($results.Server)' rÃ©pond au ping." -ForegroundColor Green
        } else {
            Write-Host "Le serveur '$($results.Server)' ne rÃ©pond pas au ping." -ForegroundColor Red
            Write-Host "Cela peut Ãªtre dÃ» Ã  un pare-feu ou Ã  un serveur hors ligne." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Erreur lors du ping du serveur: $($_.Exception.Message)" -ForegroundColor Red
        $results.PingResult = $false
    }

    # 2. Scanner les ports courants pour les partages rÃ©seau
    Write-Host "`n=== Test des ports rÃ©seau ===" -ForegroundColor Cyan
    $ports = @(139, 445)  # Ports SMB/CIFS
    $portsOpen = @()

    foreach ($port in $ports) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connectionResult = $tcpClient.BeginConnect($results.Server, $port, $null, $null)
            $wait = $connectionResult.AsyncWaitHandle.WaitOne(1000, $false)

            if ($wait) {
                try {
                    $tcpClient.EndConnect($connectionResult)
                    $portsOpen += $port
                    Write-Host "Port $port: Ouvert" -ForegroundColor Green
                } catch {
                    Write-Host "Port $port: FermÃ©" -ForegroundColor Red
                }
            } else {
                Write-Host "Port $port: Timeout" -ForegroundColor Red
            }

            $tcpClient.Close()
        } catch {
            Write-Host "Erreur lors du test du port $port: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    $results.PortScanResult = $portsOpen

    if ($portsOpen.Count -eq 0) {
        Write-Host "Aucun port SMB/CIFS n'est ouvert sur le serveur. Les partages rÃ©seau ne sont pas accessibles." -ForegroundColor Red
        $results.Recommendations += "VÃ©rifiez que le service de partage de fichiers est activÃ© sur le serveur."
        $results.Recommendations += "VÃ©rifiez que les ports 139 et 445 ne sont pas bloquÃ©s par un pare-feu."
    }

    # 3. VÃ©rifier si le chemin rÃ©seau existe
    Write-Host "`n=== VÃ©rification de l'existence du chemin rÃ©seau ===" -ForegroundColor Cyan
    $results.PathExists = Test-Path -Path $NetworkPath -ErrorAction SilentlyContinue

    if ($results.PathExists) {
        Write-Host "Le chemin rÃ©seau '$NetworkPath' existe." -ForegroundColor Green
    } else {
        Write-Host "Le chemin rÃ©seau '$NetworkPath' n'existe pas ou n'est pas accessible." -ForegroundColor Red
    }

    # 4. Tenter un accÃ¨s direct
    Write-Host "`n=== Tentative d'accÃ¨s direct ===" -ForegroundColor Cyan
    $directAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
        if ((Get-Item -Path $NetworkPath -ErrorAction Stop).PSIsContainer) {
            Get-ChildItem -Path $NetworkPath -ErrorAction Stop
        } else {
            Get-Content -Path $NetworkPath -TotalCount 1 -ErrorAction Stop
        }
    } -Path $NetworkPath

    $results.DirectAccessResult = if ($directAccessResult.Success) { "SuccÃ¨s" } else { "Ã‰chec" }

    if ($directAccessResult.Success) {
        Write-Host "L'accÃ¨s direct a rÃ©ussi." -ForegroundColor Green
    } else {
        Write-Host "L'accÃ¨s direct a Ã©chouÃ©." -ForegroundColor Yellow
        Format-UnauthorizedAccessReport -DebugResult $directAccessResult
    }

    # 5. Tenter un accÃ¨s avec les informations d'identification fournies
    if ($Credential) {
        Write-Host "`n=== Tentative d'accÃ¨s avec informations d'identification ===" -ForegroundColor Cyan

        try {
            # CrÃ©er un objet NetworkCredential
            $netCred = $Credential.GetNetworkCredential()

            # Construire la commande net use
            $username = $netCred.Domain + "\" + $netCred.UserName
            $password = $netCred.Password
            $server = "\\" + $results.Server

            # Utiliser la commande net use pour Ã©tablir une connexion
            $output = net use $server /user:$username $password 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Connexion Ã©tablie avec le serveur en utilisant les informations d'identification fournies." -ForegroundColor Green

                # Tester l'accÃ¨s au chemin
                $credAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
                    if ((Get-Item -Path $NetworkPath -ErrorAction Stop).PSIsContainer) {
                        Get-ChildItem -Path $NetworkPath -ErrorAction Stop
                    } else {
                        Get-Content -Path $NetworkPath -TotalCount 1 -ErrorAction Stop
                    }
                } -Path $NetworkPath

                $results.CredentialAccessResult = if ($credAccessResult.Success) { "SuccÃ¨s" } else { "Ã‰chec" }

                if ($credAccessResult.Success) {
                    Write-Host "L'accÃ¨s avec informations d'identification a rÃ©ussi." -ForegroundColor Green
                } else {
                    Write-Host "L'accÃ¨s avec informations d'identification a Ã©chouÃ© malgrÃ© une connexion rÃ©ussie au serveur." -ForegroundColor Yellow
                    Format-UnauthorizedAccessReport -DebugResult $credAccessResult
                }

                # DÃ©connecter la session
                net use $server /delete | Out-Null
            } else {
                Write-Host "Ã‰chec de la connexion au serveur avec les informations d'identification fournies: $output" -ForegroundColor Red
                $results.CredentialAccessResult = "Ã‰chec"
            }
        } catch {
            Write-Host "Erreur lors de l'accÃ¨s avec informations d'identification: $($_.Exception.Message)" -ForegroundColor Red
            $results.CredentialAccessResult = "Ã‰chec"
        }
    }

    # 6. Tenter un accÃ¨s avec impersonation
    if ($Credential) {
        Write-Host "`n=== Tentative d'accÃ¨s avec impersonation ===" -ForegroundColor Cyan

        try {
            $impersonationResult = Invoke-WithImpersonation -Credential $Credential -ScriptBlock {
                try {
                    if ((Get-Item -Path $NetworkPath -ErrorAction Stop).PSIsContainer) {
                        $files = Get-ChildItem -Path $NetworkPath -ErrorAction Stop
                        return [PSCustomObject]@{
                            Success = $true
                            IsContainer = $true
                            ItemCount = $files.Count
                        }
                    } else {
                        $content = Get-Content -Path $NetworkPath -TotalCount 1 -ErrorAction Stop
                        return [PSCustomObject]@{
                            Success = $true
                            IsContainer = $false
                            Content = $content
                        }
                    }
                } catch {
                    return [PSCustomObject]@{
                        Success = $false
                        Error = $_.Exception.Message
                    }
                }
            }

            $results.ImpersonationResult = if ($impersonationResult.Success) { "SuccÃ¨s" } else { "Ã‰chec" }

            if ($impersonationResult.Success) {
                Write-Host "L'accÃ¨s avec impersonation a rÃ©ussi." -ForegroundColor Green

                if ($impersonationResult.IsContainer) {
                    Write-Host "Le chemin est un dossier contenant $($impersonationResult.ItemCount) Ã©lÃ©ments." -ForegroundColor Green
                } else {
                    Write-Host "Le chemin est un fichier. PremiÃ¨re ligne: $($impersonationResult.Content)" -ForegroundColor Green
                }
            } else {
                Write-Host "L'accÃ¨s avec impersonation a Ã©chouÃ©: $($impersonationResult.Error)" -ForegroundColor Red
            }
        } catch {
            Write-Host "Erreur lors de l'impersonation: $($_.Exception.Message)" -ForegroundColor Red
            $results.ImpersonationResult = "Ã‰chec"
        }
    }

    # 7. Diagnostics rÃ©seau supplÃ©mentaires
    Write-Host "`n=== Diagnostics rÃ©seau supplÃ©mentaires ===" -ForegroundColor Cyan

    # VÃ©rifier les partages disponibles sur le serveur
    Write-Host "Partages disponibles sur le serveur '$($results.Server)':" -ForegroundColor Yellow
    try {
        $shares = net view $results.Server /all 2>&1

        if ($LASTEXITCODE -eq 0) {
            $results.NetworkDiagnostics["SharesAvailable"] = $true
            Write-Host $shares -ForegroundColor Gray
        } else {
            $results.NetworkDiagnostics["SharesAvailable"] = $false
            Write-Host "Impossible de lister les partages: $shares" -ForegroundColor Red
        }
    } catch {
        $results.NetworkDiagnostics["SharesAvailable"] = $false
        Write-Host "Erreur lors de la rÃ©cupÃ©ration des partages: $($_.Exception.Message)" -ForegroundColor Red
    }

    # VÃ©rifier les sessions actives
    Write-Host "`nSessions actives:" -ForegroundColor Yellow
    try {
        $sessions = net session 2>&1

        if ($LASTEXITCODE -eq 0) {
            $results.NetworkDiagnostics["SessionsAvailable"] = $true
            Write-Host $sessions -ForegroundColor Gray
        } else {
            $results.NetworkDiagnostics["SessionsAvailable"] = $false
            Write-Host "Impossible de lister les sessions: $sessions" -ForegroundColor Red
        }
    } catch {
        $results.NetworkDiagnostics["SessionsAvailable"] = $false
        Write-Host "Erreur lors de la rÃ©cupÃ©ration des sessions: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 8. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    # Recommandations basÃ©es sur les rÃ©sultats des tests
    if (-not $results.PingResult) {
        $results.Recommendations += "VÃ©rifiez que le serveur est en ligne et accessible sur le rÃ©seau."
        $results.Recommendations += "VÃ©rifiez que le ping n'est pas bloquÃ© par un pare-feu."
        Write-Host "- VÃ©rifiez que le serveur est en ligne et accessible sur le rÃ©seau." -ForegroundColor Yellow
        Write-Host "- VÃ©rifiez que le ping n'est pas bloquÃ© par un pare-feu." -ForegroundColor Yellow
    }

    if ($results.PortScanResult.Count -eq 0) {
        $results.Recommendations += "VÃ©rifiez que les ports SMB (139, 445) sont ouverts sur le serveur."
        Write-Host "- VÃ©rifiez que les ports SMB (139, 445) sont ouverts sur le serveur." -ForegroundColor Yellow
    }

    if (-not $results.PathExists) {
        $results.Recommendations += "VÃ©rifiez que le chemin rÃ©seau existe et que vous avez les permissions nÃ©cessaires."
        Write-Host "- VÃ©rifiez que le chemin rÃ©seau existe et que vous avez les permissions nÃ©cessaires." -ForegroundColor Yellow
    }

    if ($results.DirectAccessResult -eq "Ã‰chec" -and $results.CredentialAccessResult -eq "SuccÃ¨s") {
        $results.Recommendations += "Utilisez des informations d'identification explicites pour accÃ©der Ã  cette ressource."
        Write-Host "- Utilisez des informations d'identification explicites pour accÃ©der Ã  cette ressource." -ForegroundColor Green
    }

    if ($results.ImpersonationResult -eq "SuccÃ¨s") {
        $results.Recommendations += "Utilisez l'impersonation pour accÃ©der Ã  cette ressource."
        Write-Host "- Utilisez l'impersonation pour accÃ©der Ã  cette ressource." -ForegroundColor Green
    }

    if ($results.NetworkDiagnostics["SharesAvailable"] -eq $false) {
        $results.Recommendations += "VÃ©rifiez que le service de partage de fichiers est activÃ© sur le serveur."
        Write-Host "- VÃ©rifiez que le service de partage de fichiers est activÃ© sur le serveur." -ForegroundColor Yellow
    }

    # Recommandations gÃ©nÃ©rales
    if ($results.DirectAccessResult -eq "Ã‰chec" -and $results.CredentialAccessResult -eq "Ã‰chec" -and $results.ImpersonationResult -eq "Ã‰chec") {
        $results.Recommendations += "VÃ©rifiez les permissions sur le partage rÃ©seau."
        $results.Recommendations += "VÃ©rifiez que le compte utilisÃ© a accÃ¨s au partage."
        $results.Recommendations += "Essayez d'accÃ©der au partage avec un compte administrateur."
        $results.Recommendations += "VÃ©rifiez les paramÃ¨tres de sÃ©curitÃ© du partage sur le serveur."

        Write-Host "- VÃ©rifiez les permissions sur le partage rÃ©seau." -ForegroundColor Yellow
        Write-Host "- VÃ©rifiez que le compte utilisÃ© a accÃ¨s au partage." -ForegroundColor Yellow
        Write-Host "- Essayez d'accÃ©der au partage avec un compte administrateur." -ForegroundColor Yellow
        Write-Host "- VÃ©rifiez les paramÃ¨tres de sÃ©curitÃ© du partage sur le serveur." -ForegroundColor Yellow
    }

    return $results
}

function Debug-DatabaseAccess {
    <#
    .SYNOPSIS
        DÃ©montre et dÃ©bogue l'accÃ¨s Ã  une base de donnÃ©es SQL Server.

    .DESCRIPTION
        Cette fonction tente d'accÃ©der Ã  une base de donnÃ©es SQL Server de diffÃ©rentes maniÃ¨res
        et montre comment dÃ©boguer et rÃ©soudre les problÃ¨mes d'accÃ¨s.

    .PARAMETER ServerInstance
        Le nom de l'instance SQL Server (serveur\instance ou serveur).

    .PARAMETER Database
        Le nom de la base de donnÃ©es Ã  dÃ©boguer.

    .PARAMETER Credential
        Les informations d'identification Ã  utiliser pour l'accÃ¨s Ã  la base de donnÃ©es.

    .PARAMETER IntegratedSecurity
        Indique si l'authentification Windows doit Ãªtre utilisÃ©e.

    .EXAMPLE
        Debug-DatabaseAccess -ServerInstance "localhost\SQLEXPRESS" -Database "AdventureWorks" -IntegratedSecurity

    .EXAMPLE
        $cred = Get-Credential
        Debug-DatabaseAccess -ServerInstance "localhost\SQLEXPRESS" -Database "AdventureWorks" -Credential $cred

    .OUTPUTS
        [PSCustomObject] avec des informations sur les diffÃ©rentes tentatives d'accÃ¨s
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $true)]
        [string]$Database,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [switch]$IntegratedSecurity
    )

    # VÃ©rifier si le module SqlServer est installÃ©
    if (-not (Get-Module -Name SqlServer -ListAvailable)) {
        Write-Warning "Le module SqlServer n'est pas installÃ©. Installation en cours..."
        try {
            Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
        } catch {
            Write-Error "Impossible d'installer le module SqlServer: $($_.Exception.Message)"
            return
        }
    }

    $results = [PSCustomObject]@{
        ServerInstance = $ServerInstance
        Database = $Database
        ServerExists = $false
        DatabaseExists = $false
        DirectAccessResult = $null
        CredentialAccessResult = $null
        ElevatedAccessResult = $null
        ConnectionDiagnostics = @{}
        PermissionDiagnostics = @{}
        Recommendations = @()
    }

    # 1. VÃ©rifier si le serveur rÃ©pond
    Write-Host "`n=== Test de connectivitÃ© au serveur SQL ===" -ForegroundColor Cyan
    try {
        $serverName = $ServerInstance.Split('\')[0]
        $pingResult = Test-Connection -ComputerName $serverName -Count 2 -Quiet
        $results.ConnectionDiagnostics["PingResult"] = $pingResult

        if ($pingResult) {
            Write-Host "Le serveur '$serverName' rÃ©pond au ping." -ForegroundColor Green
        } else {
            Write-Host "Le serveur '$serverName' ne rÃ©pond pas au ping." -ForegroundColor Red
            Write-Host "Cela peut Ãªtre dÃ» Ã  un pare-feu ou Ã  un serveur hors ligne." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Erreur lors du ping du serveur: $($_.Exception.Message)" -ForegroundColor Red
        $results.ConnectionDiagnostics["PingResult"] = $false
    }

    # 2. Scanner le port SQL Server
    Write-Host "`n=== Test du port SQL Server ===" -ForegroundColor Cyan
    try {
        $port = 1433  # Port SQL Server par dÃ©faut
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectionResult = $tcpClient.BeginConnect($serverName, $port, $null, $null)
        $wait = $connectionResult.AsyncWaitHandle.WaitOne(1000, $false)

        if ($wait) {
            try {
                $tcpClient.EndConnect($connectionResult)
                $results.ConnectionDiagnostics["PortOpen"] = $true
                Write-Host "Port $port: Ouvert" -ForegroundColor Green
            } catch {
                $results.ConnectionDiagnostics["PortOpen"] = $false
                Write-Host "Port $port: FermÃ©" -ForegroundColor Red
            }
        } else {
            $results.ConnectionDiagnostics["PortOpen"] = $false
            Write-Host "Port $port: Timeout" -ForegroundColor Red
        }

        $tcpClient.Close()
    } catch {
        Write-Host "Erreur lors du test du port: $($_.Exception.Message)" -ForegroundColor Red
        $results.ConnectionDiagnostics["PortOpen"] = $false
    }

    # 3. Tenter une connexion directe avec l'authentification Windows
    if ($IntegratedSecurity) {
        Write-Host "`n=== Tentative de connexion avec l'authentification Windows ===" -ForegroundColor Cyan

        try {
            $connectionString = "Server=$ServerInstance;Database=master;Integrated Security=True;"
            $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
            $connection.Open()

            $results.ServerExists = $true
            $results.ConnectionDiagnostics["WindowsAuthConnection"] = $true
            Write-Host "Connexion au serveur rÃ©ussie avec l'authentification Windows." -ForegroundColor Green

            # VÃ©rifier si la base de donnÃ©es existe
            $query = "SELECT name FROM sys.databases WHERE name = '$Database'"
            $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
            $reader = $command.ExecuteReader()

            if ($reader.Read()) {
                $results.DatabaseExists = $true
                Write-Host "La base de donnÃ©es '$Database' existe." -ForegroundColor Green
            } else {
                Write-Host "La base de donnÃ©es '$Database' n'existe pas." -ForegroundColor Red
                $results.Recommendations += "VÃ©rifiez que la base de donnÃ©es existe sur le serveur."
            }

            $reader.Close()

            # Si la base de donnÃ©es existe, tenter de s'y connecter
            if ($results.DatabaseExists) {
                $connection.Close()
                $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
                $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
                $connection.Open()

                $results.DirectAccessResult = "SuccÃ¨s"
                Write-Host "Connexion Ã  la base de donnÃ©es '$Database' rÃ©ussie avec l'authentification Windows." -ForegroundColor Green

                # VÃ©rifier les permissions de l'utilisateur
                $query = @"
SELECT
    dp.name AS principal_name,
    dp.type_desc AS principal_type,
    o.name AS object_name,
    o.type_desc AS object_type,
    p.permission_name,
    p.state_desc AS permission_state
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.name = SYSTEM_USER
ORDER BY o.name, p.permission_name
"@
                $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
                $reader = $command.ExecuteReader()

                $permissions = @()
                while ($reader.Read()) {
                    $permissions += [PSCustomObject]@{
                        PrincipalName = $reader["principal_name"]
                        PrincipalType = $reader["principal_type"]
                        ObjectName = if ($reader["object_name"] -is [DBNull]) { "NULL" } else { $reader["object_name"] }
                        ObjectType = if ($reader["object_type"] -is [DBNull]) { "NULL" } else { $reader["object_type"] }
                        PermissionName = $reader["permission_name"]
                        PermissionState = $reader["permission_state"]
                    }
                }

                $reader.Close()

                $results.PermissionDiagnostics["UserPermissions"] = $permissions

                if ($permissions.Count -gt 0) {
                    Write-Host "`nPermissions de l'utilisateur actuel:" -ForegroundColor Yellow
                    foreach ($perm in $permissions) {
                        Write-Host "  $($perm.PermissionState) $($perm.PermissionName) sur $($perm.ObjectName) ($($perm.ObjectType))" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "`nL'utilisateur actuel n'a aucune permission explicite dans la base de donnÃ©es." -ForegroundColor Yellow
                    $results.Recommendations += "VÃ©rifiez que l'utilisateur a les permissions nÃ©cessaires dans la base de donnÃ©es."
                }
            }

            $connection.Close()
        } catch {
            Write-Host "Erreur lors de la connexion avec l'authentification Windows: $($_.Exception.Message)" -ForegroundColor Red
            $results.DirectAccessResult = "Ã‰chec"

            # Analyser l'erreur
            $errorMessage = $_.Exception.Message

            if ($errorMessage -match "Login failed for user") {
                $results.Recommendations += "VÃ©rifiez que l'utilisateur Windows actuel a accÃ¨s au serveur SQL."
                Write-Host "- VÃ©rifiez que l'utilisateur Windows actuel a accÃ¨s au serveur SQL." -ForegroundColor Yellow
            } elseif ($errorMessage -match "Cannot open database") {
                $results.Recommendations += "VÃ©rifiez que l'utilisateur a accÃ¨s Ã  la base de donnÃ©es spÃ©cifiÃ©e."
                Write-Host "- VÃ©rifiez que l'utilisateur a accÃ¨s Ã  la base de donnÃ©es spÃ©cifiÃ©e." -ForegroundColor Yellow
            } elseif ($errorMessage -match "network-related or instance-specific") {
                $results.Recommendations += "VÃ©rifiez que le serveur SQL est en cours d'exÃ©cution et accessible sur le rÃ©seau."
                $results.Recommendations += "VÃ©rifiez que le nom de l'instance est correct."
                Write-Host "- VÃ©rifiez que le serveur SQL est en cours d'exÃ©cution et accessible sur le rÃ©seau." -ForegroundColor Yellow
                Write-Host "- VÃ©rifiez que le nom de l'instance est correct." -ForegroundColor Yellow
            }
        }
    }

    # 4. Tenter une connexion avec les informations d'identification fournies
    if ($Credential) {
        Write-Host "`n=== Tentative de connexion avec les informations d'identification fournies ===" -ForegroundColor Cyan

        try {
            $username = $Credential.UserName
            $password = $Credential.GetNetworkCredential().Password

            $connectionString = "Server=$ServerInstance;Database=master;User Id=$username;Password=$password;"
            $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
            $connection.Open()

            $results.ServerExists = $true
            $results.ConnectionDiagnostics["SqlAuthConnection"] = $true
            Write-Host "Connexion au serveur rÃ©ussie avec l'authentification SQL." -ForegroundColor Green

            # VÃ©rifier si la base de donnÃ©es existe
            $query = "SELECT name FROM sys.databases WHERE name = '$Database'"
            $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
            $reader = $command.ExecuteReader()

            if ($reader.Read()) {
                $results.DatabaseExists = $true
                Write-Host "La base de donnÃ©es '$Database' existe." -ForegroundColor Green
            } else {
                Write-Host "La base de donnÃ©es '$Database' n'existe pas." -ForegroundColor Red
                $results.Recommendations += "VÃ©rifiez que la base de donnÃ©es existe sur le serveur."
            }

            $reader.Close()

            # Si la base de donnÃ©es existe, tenter de s'y connecter
            if ($results.DatabaseExists) {
                $connection.Close()
                $connectionString = "Server=$ServerInstance;Database=$Database;User Id=$username;Password=$password;"
                $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
                $connection.Open()

                $results.CredentialAccessResult = "SuccÃ¨s"
                Write-Host "Connexion Ã  la base de donnÃ©es '$Database' rÃ©ussie avec l'authentification SQL." -ForegroundColor Green

                # VÃ©rifier les permissions de l'utilisateur
                $query = @"
SELECT
    dp.name AS principal_name,
    dp.type_desc AS principal_type,
    o.name AS object_name,
    o.type_desc AS object_type,
    p.permission_name,
    p.state_desc AS permission_state
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.name = CURRENT_USER
ORDER BY o.name, p.permission_name
"@
                $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
                $reader = $command.ExecuteReader()

                $permissions = @()
                while ($reader.Read()) {
                    $permissions += [PSCustomObject]@{
                        PrincipalName = $reader["principal_name"]
                        PrincipalType = $reader["principal_type"]
                        ObjectName = if ($reader["object_name"] -is [DBNull]) { "NULL" } else { $reader["object_name"] }
                        ObjectType = if ($reader["object_type"] -is [DBNull]) { "NULL" } else { $reader["object_type"] }
                        PermissionName = $reader["permission_name"]
                        PermissionState = $reader["permission_state"]
                    }
                }

                $reader.Close()

                $results.PermissionDiagnostics["SqlUserPermissions"] = $permissions

                if ($permissions.Count -gt 0) {
                    Write-Host "`nPermissions de l'utilisateur SQL:" -ForegroundColor Yellow
                    foreach ($perm in $permissions) {
                        Write-Host "  $($perm.PermissionState) $($perm.PermissionName) sur $($perm.ObjectName) ($($perm.ObjectType))" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "`nL'utilisateur SQL n'a aucune permission explicite dans la base de donnÃ©es." -ForegroundColor Yellow
                    $results.Recommendations += "VÃ©rifiez que l'utilisateur SQL a les permissions nÃ©cessaires dans la base de donnÃ©es."
                }
            }

            $connection.Close()
        } catch {
            Write-Host "Erreur lors de la connexion avec l'authentification SQL: $($_.Exception.Message)" -ForegroundColor Red
            $results.CredentialAccessResult = "Ã‰chec"

            # Analyser l'erreur
            $errorMessage = $_.Exception.Message

            if ($errorMessage -match "Login failed for user") {
                $results.Recommendations += "VÃ©rifiez que le nom d'utilisateur et le mot de passe SQL sont corrects."
                $results.Recommendations += "VÃ©rifiez que l'authentification SQL est activÃ©e sur le serveur."
                Write-Host "- VÃ©rifiez que le nom d'utilisateur et le mot de passe SQL sont corrects." -ForegroundColor Yellow
                Write-Host "- VÃ©rifiez que l'authentification SQL est activÃ©e sur le serveur." -ForegroundColor Yellow
            } elseif ($errorMessage -match "Cannot open database") {
                $results.Recommendations += "VÃ©rifiez que l'utilisateur SQL a accÃ¨s Ã  la base de donnÃ©es spÃ©cifiÃ©e."
                Write-Host "- VÃ©rifiez que l'utilisateur SQL a accÃ¨s Ã  la base de donnÃ©es spÃ©cifiÃ©e." -ForegroundColor Yellow
            } elseif ($errorMessage -match "network-related or instance-specific") {
                $results.Recommendations += "VÃ©rifiez que le serveur SQL est en cours d'exÃ©cution et accessible sur le rÃ©seau."
                $results.Recommendations += "VÃ©rifiez que le nom de l'instance est correct."
                Write-Host "- VÃ©rifiez que le serveur SQL est en cours d'exÃ©cution et accessible sur le rÃ©seau." -ForegroundColor Yellow
                Write-Host "- VÃ©rifiez que le nom de l'instance est correct." -ForegroundColor Yellow
            }
        }
    }

    # 5. Tenter une connexion avec un processus Ã©levÃ©
    Write-Host "`n=== Tentative de connexion avec un processus Ã©levÃ© ===" -ForegroundColor Cyan

    $script = {
        param($ServerInstance, $Database, $IntegratedSecurity, $Username, $Password)

        try {
            # Construire la chaÃ®ne de connexion
            if ($IntegratedSecurity) {
                $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
            } else {
                $connectionString = "Server=$ServerInstance;Database=$Database;User Id=$Username;Password=$Password;"
            }

            # Tenter de se connecter
            $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
            $connection.Open()

            # ExÃ©cuter une requÃªte simple
            $query = "SELECT DB_NAME() AS DatabaseName, CURRENT_USER AS CurrentUser"
            $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
            $reader = $command.ExecuteReader()

            $result = [PSCustomObject]@{
                Success = $true
                DatabaseName = $null
                CurrentUser = $null
                Error = $null
            }

            if ($reader.Read()) {
                $result.DatabaseName = $reader["DatabaseName"]
                $result.CurrentUser = $reader["CurrentUser"]
            }

            $reader.Close()
            $connection.Close()

            return $result | ConvertTo-Json -Compress
        } catch {
            return [PSCustomObject]@{
                Success = $false
                DatabaseName = $null
                CurrentUser = $null
                Error = $_.Exception.Message
            } | ConvertTo-Json -Compress
        }
    }

    try {
        if ($IntegratedSecurity) {
            $scriptResult = Start-ElevatedProcess -ScriptBlock $script -ArgumentList $ServerInstance, $Database, $true, $null, $null -Wait
        } else {
            $username = $Credential.UserName
            $password = $Credential.GetNetworkCredential().Password
            $scriptResult = Start-ElevatedProcess -ScriptBlock $script -ArgumentList $ServerInstance, $Database, $false, $username, $password -Wait
        }

        if ($scriptResult -eq 0) {
            $results.ElevatedAccessResult = "SuccÃ¨s"
            Write-Host "Connexion avec processus Ã©levÃ© rÃ©ussie." -ForegroundColor Green
        } else {
            $results.ElevatedAccessResult = "Ã‰chec"
            Write-Host "Ã‰chec de la connexion avec processus Ã©levÃ©." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la connexion avec processus Ã©levÃ©: $($_.Exception.Message)" -ForegroundColor Red
        $results.ElevatedAccessResult = "Ã‰chec"
    }

    # 6. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    # Recommandations basÃ©es sur les rÃ©sultats des tests
    if (-not $results.ConnectionDiagnostics["PingResult"]) {
        $results.Recommendations += "VÃ©rifiez que le serveur est en ligne et accessible sur le rÃ©seau."
        Write-Host "- VÃ©rifiez que le serveur est en ligne et accessible sur le rÃ©seau." -ForegroundColor Yellow
    }

    if (-not $results.ConnectionDiagnostics["PortOpen"]) {
        $results.Recommendations += "VÃ©rifiez que le port SQL Server (1433 par dÃ©faut) est ouvert sur le serveur."
        $results.Recommendations += "VÃ©rifiez que le service SQL Server est en cours d'exÃ©cution."
        Write-Host "- VÃ©rifiez que le port SQL Server (1433 par dÃ©faut) est ouvert sur le serveur." -ForegroundColor Yellow
        Write-Host "- VÃ©rifiez que le service SQL Server est en cours d'exÃ©cution." -ForegroundColor Yellow
    }

    if (-not $results.DatabaseExists) {
        $results.Recommendations += "VÃ©rifiez que la base de donnÃ©es existe sur le serveur."
        Write-Host "- VÃ©rifiez que la base de donnÃ©es existe sur le serveur." -ForegroundColor Yellow
    }

    if ($results.DirectAccessResult -eq "Ã‰chec" -and $results.CredentialAccessResult -eq "SuccÃ¨s") {
        $results.Recommendations += "Utilisez l'authentification SQL pour accÃ©der Ã  cette base de donnÃ©es."
        Write-Host "- Utilisez l'authentification SQL pour accÃ©der Ã  cette base de donnÃ©es." -ForegroundColor Green
    }

    if ($results.DirectAccessResult -eq "Ã‰chec" -and $results.CredentialAccessResult -eq "Ã‰chec" -and $results.ElevatedAccessResult -eq "SuccÃ¨s") {
        $results.Recommendations += "Utilisez un processus Ã©levÃ© pour accÃ©der Ã  cette base de donnÃ©es."
        Write-Host "- Utilisez un processus Ã©levÃ© pour accÃ©der Ã  cette base de donnÃ©es." -ForegroundColor Green
    }

    # Recommandations gÃ©nÃ©rales
    if ($results.DirectAccessResult -eq "Ã‰chec" -and $results.CredentialAccessResult -eq "Ã‰chec" -and $results.ElevatedAccessResult -eq "Ã‰chec") {
        $results.Recommendations += "VÃ©rifiez les permissions de l'utilisateur dans SQL Server."
        $results.Recommendations += "VÃ©rifiez que l'authentification appropriÃ©e est activÃ©e sur le serveur."
        $results.Recommendations += "VÃ©rifiez les paramÃ¨tres de sÃ©curitÃ© de SQL Server."
        $results.Recommendations += "Consultez les journaux d'erreurs SQL Server pour plus d'informations."

        Write-Host "- VÃ©rifiez les permissions de l'utilisateur dans SQL Server." -ForegroundColor Yellow
        Write-Host "- VÃ©rifiez que l'authentification appropriÃ©e est activÃ©e sur le serveur." -ForegroundColor Yellow
        Write-Host "- VÃ©rifiez les paramÃ¨tres de sÃ©curitÃ© de SQL Server." -ForegroundColor Yellow
        Write-Host "- Consultez les journaux d'erreurs SQL Server pour plus d'informations." -ForegroundColor Yellow
    }

    return $results
}

# Exporter les fonctions
Export-ModuleMember -Function Debug-SystemFileAccess, Debug-RegistryKeyAccess, Debug-NetworkAccess, Debug-DatabaseAccess

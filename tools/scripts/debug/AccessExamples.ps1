<#
.SYNOPSIS
    Exemples de débogage pour les scénarios courants d'accès refusé.
.DESCRIPTION
    Ce script fournit des exemples concrets pour déboguer différents scénarios
    d'accès refusé, notamment pour les fichiers système protégés, les clés de registre,
    les problèmes d'accès réseau et les bases de données.
.NOTES
    Auteur: Augment Code
    Date de création: 2023-11-15
#>

# Importer les fonctions de diagnostic des permissions
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "FilePermissionDiagnostic.ps1"
. $scriptPath

# Importer les fonctions d'élévation de privilèges
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PrivilegeElevationTools.ps1"
. $scriptPath

function Debug-SystemFileAccess {
    <#
    .SYNOPSIS
        Démontre et débogue l'accès à un fichier système protégé.

    .DESCRIPTION
        Cette fonction tente d'accéder à un fichier système protégé de différentes manières
        et montre comment déboguer et résoudre les problèmes d'accès.

    .PARAMETER FilePath
        Le chemin du fichier système protégé à déboguer.

    .EXAMPLE
        Debug-SystemFileAccess -FilePath "C:\Windows\System32\config\SAM"

    .OUTPUTS
        [PSCustomObject] avec des informations sur les différentes tentatives d'accès
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

    # 1. Vérifier si le fichier existe
    $results.FileExists = Test-Path -Path $FilePath -ErrorAction SilentlyContinue

    if (-not $results.FileExists) {
        Write-Warning "Le fichier '$FilePath' n'existe pas."
        $results.Recommendations += "Vérifiez que le chemin du fichier est correct."
        return $results
    }

    # 2. Analyser les permissions actuelles
    Write-Host "`n=== Analyse des permissions actuelles ===" -ForegroundColor Cyan
    $permissionsResult = Test-PathPermissions -Path $FilePath -TestRead -TestWrite -Detailed
    Format-PathPermissionsReport -PermissionsResult $permissionsResult

    # 3. Tenter un accès direct
    Write-Host "`n=== Tentative d'accès direct ===" -ForegroundColor Cyan
    $directAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
        Get-Content -Path $FilePath -TotalCount 1
    } -Path $FilePath -AnalyzePermissions

    $results.DirectAccessResult = if ($directAccessResult.Success) { "Succès" } else { "Échec" }

    if (-not $directAccessResult.Success) {
        Write-Host "L'accès direct a échoué comme prévu pour un fichier système protégé." -ForegroundColor Yellow
        Format-UnauthorizedAccessReport -DebugResult $directAccessResult
    } else {
        Write-Host "L'accès direct a réussi, ce qui est inhabituel pour un fichier système protégé." -ForegroundColor Green
    }

    # 4. Tenter d'utiliser le privilège SeBackupPrivilege
    Write-Host "`n=== Tentative avec le privilège SeBackupPrivilege ===" -ForegroundColor Cyan
    $backupPrivilegeSuccess = $false

    try {
        $backupPrivilegeEnabled = Enable-Privilege -Privilege "SeBackupPrivilege"

        if ($backupPrivilegeEnabled) {
            Write-Host "Privilège SeBackupPrivilege activé avec succès." -ForegroundColor Green

            # Créer un répertoire temporaire pour la sauvegarde
            $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            $backupPath = Join-Path -Path $tempDir -ChildPath ([System.IO.Path]::GetFileName($FilePath))

            try {
                # Tenter de copier le fichier avec le privilège de sauvegarde
                Copy-Item -Path $FilePath -Destination $backupPath -ErrorAction Stop
                $backupPrivilegeSuccess = $true
                Write-Host "Fichier copié avec succès en utilisant le privilège SeBackupPrivilege." -ForegroundColor Green
                Write-Host "Chemin de la copie: $backupPath"
            } catch {
                Write-Host "Échec de la copie malgré l'activation du privilège SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
            } finally {
                # Nettoyer
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "Impossible d'activer le privilège SeBackupPrivilege. Vous devez être administrateur." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'utilisation du privilège SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.BackupPrivilegeResult = if ($backupPrivilegeSuccess) { "Succès" } else { "Échec" }

    # 5. Tenter de prendre possession du fichier
    Write-Host "`n=== Tentative de prise de possession du fichier ===" -ForegroundColor Cyan
    $takeOwnershipSuccess = $false

    try {
        # Activer le privilège SeTakeOwnershipPrivilege
        $takeOwnershipEnabled = Enable-Privilege -Privilege "SeTakeOwnershipPrivilege"

        if ($takeOwnershipEnabled) {
            Write-Host "Privilège SeTakeOwnershipPrivilege activé avec succès." -ForegroundColor Green

            # Tenter de prendre possession du fichier
            $acl = Get-Acl -Path $FilePath
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $acl.SetOwner([System.Security.Principal.NTAccount]$currentUser)

            try {
                Set-Acl -Path $FilePath -AclObject $acl -ErrorAction Stop
                $takeOwnershipSuccess = $true
                Write-Host "Prise de possession du fichier réussie." -ForegroundColor Green

                # Ajouter des droits de lecture
                $acl = Get-Acl -Path $FilePath
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $currentUser,
                    [System.Security.AccessControl.FileSystemRights]::Read,
                    [System.Security.AccessControl.AccessControlType]::Allow
                )
                $acl.AddAccessRule($accessRule)
                Set-Acl -Path $FilePath -AclObject $acl

                Write-Host "Droits de lecture ajoutés avec succès." -ForegroundColor Green
            } catch {
                Write-Host "Échec de la prise de possession: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Impossible d'activer le privilège SeTakeOwnershipPrivilege." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la prise de possession: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.TakeOwnershipResult = if ($takeOwnershipSuccess) { "Succès" } else { "Échec" }

    # 6. Tenter d'utiliser un processus élevé
    Write-Host "`n=== Tentative avec un processus élevé ===" -ForegroundColor Cyan
    $elevatedCopySuccess = $false

    try {
        # Créer un répertoire temporaire pour la copie
        $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        $copyPath = Join-Path -Path $tempDir -ChildPath ([System.IO.Path]::GetFileName($FilePath))

        # Tenter de copier le fichier avec un processus élevé
        $result = Edit-ProtectedFile -Path $FilePath -EditScriptBlock {
            param($TempFile)
            # Ne pas modifier le fichier, juste le copier
            return $true
        }

        if ($result.Success) {
            $elevatedCopySuccess = $true
            Write-Host "Copie avec processus élevé réussie." -ForegroundColor Green
        } else {
            Write-Host "Échec de la copie avec processus élevé: $($result.Message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la copie avec processus élevé: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Nettoyer
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    $results.CopyWithElevationResult = if ($elevatedCopySuccess) { "Succès" } else { "Échec" }

    # 7. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    if ($backupPrivilegeSuccess) {
        $results.Recommendations += "Utilisez le privilège SeBackupPrivilege pour accéder au fichier en lecture seule."
        Write-Host "- Utilisez le privilège SeBackupPrivilege pour accéder au fichier en lecture seule." -ForegroundColor Green
    }

    if ($takeOwnershipSuccess) {
        $results.Recommendations += "Prenez possession du fichier pour modifier ses permissions."
        Write-Host "- Prenez possession du fichier pour modifier ses permissions." -ForegroundColor Green
    }

    if ($elevatedCopySuccess) {
        $results.Recommendations += "Utilisez un processus élevé pour copier le fichier."
        Write-Host "- Utilisez un processus élevé pour copier le fichier." -ForegroundColor Green
    }

    if (-not ($backupPrivilegeSuccess -or $takeOwnershipSuccess -or $elevatedCopySuccess)) {
        $results.Recommendations += "Utilisez des outils système spécialisés comme 'ntdsutil' pour les fichiers de base de données Active Directory."
        $results.Recommendations += "Créez une copie de volume shadow (VSS) pour accéder aux fichiers verrouillés par le système."
        $results.Recommendations += "Démarrez en mode sans échec ou utilisez un environnement de récupération Windows pour accéder aux fichiers système."

        Write-Host "- Utilisez des outils système spécialisés comme 'ntdsutil' pour les fichiers de base de données Active Directory." -ForegroundColor Yellow
        Write-Host "- Créez une copie de volume shadow (VSS) pour accéder aux fichiers verrouillés par le système." -ForegroundColor Yellow
        Write-Host "- Démarrez en mode sans échec ou utilisez un environnement de récupération Windows pour accéder aux fichiers système." -ForegroundColor Yellow
    }

    return $results
}

function Debug-RegistryKeyAccess {
    <#
    .SYNOPSIS
        Démontre et débogue l'accès à une clé de registre protégée.

    .DESCRIPTION
        Cette fonction tente d'accéder à une clé de registre protégée de différentes manières
        et montre comment déboguer et résoudre les problèmes d'accès.

    .PARAMETER RegistryPath
        Le chemin de la clé de registre protégée à déboguer.

    .EXAMPLE
        Debug-RegistryKeyAccess -RegistryPath "HKLM:\SECURITY\Policy"

    .OUTPUTS
        [PSCustomObject] avec des informations sur les différentes tentatives d'accès
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

    # 1. Vérifier si la clé de registre existe
    $results.KeyExists = Test-Path -Path $RegistryPath -ErrorAction SilentlyContinue

    if (-not $results.KeyExists) {
        Write-Warning "La clé de registre '$RegistryPath' n'existe pas."
        $results.Recommendations += "Vérifiez que le chemin de la clé de registre est correct."
        return $results
    }

    # 2. Tenter un accès direct
    Write-Host "`n=== Tentative d'accès direct ===" -ForegroundColor Cyan
    $directAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
        Get-ItemProperty -Path $RegistryPath -ErrorAction Stop
    } -Path $RegistryPath

    $results.DirectAccessResult = if ($directAccessResult.Success) { "Succès" } else { "Échec" }

    if (-not $directAccessResult.Success) {
        Write-Host "L'accès direct a échoué comme prévu pour une clé de registre protégée." -ForegroundColor Yellow
        Format-UnauthorizedAccessReport -DebugResult $directAccessResult
    } else {
        Write-Host "L'accès direct a réussi, ce qui est inhabituel pour une clé de registre protégée." -ForegroundColor Green
    }

    # 3. Tenter d'utiliser le privilège SeBackupPrivilege
    Write-Host "`n=== Tentative avec le privilège SeBackupPrivilege ===" -ForegroundColor Cyan
    $backupPrivilegeSuccess = $false

    try {
        $backupPrivilegeEnabled = Enable-Privilege -Privilege "SeBackupPrivilege"

        if ($backupPrivilegeEnabled) {
            Write-Host "Privilège SeBackupPrivilege activé avec succès." -ForegroundColor Green

            try {
                # Tenter d'accéder à la clé de registre avec le privilège de sauvegarde
                $regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
                    [Microsoft.Win32.RegistryHive]::LocalMachine,
                    [Environment]::MachineName
                )

                # Extraire le chemin relatif (sans HKLM:\)
                $relativePath = $RegistryPath -replace "^HKLM:\\", ""

                # Ouvrir la clé avec des droits de lecture
                $key = $regKey.OpenSubKey($relativePath, $false)

                if ($key -ne $null) {
                    $backupPrivilegeSuccess = $true
                    Write-Host "Accès à la clé de registre réussi en utilisant le privilège SeBackupPrivilege." -ForegroundColor Green

                    # Afficher les valeurs de la clé
                    Write-Host "Valeurs de la clé:"
                    foreach ($valueName in $key.GetValueNames()) {
                        $value = $key.GetValue($valueName)
                        $valueType = $key.GetValueKind($valueName)
                        Write-Host "  $valueName = $value ($valueType)"
                    }

                    # Fermer la clé
                    $key.Close()
                } else {
                    Write-Host "Impossible d'ouvrir la clé de registre malgré l'activation du privilège SeBackupPrivilege." -ForegroundColor Red
                }
            } catch {
                Write-Host "Échec de l'accès malgré l'activation du privilège SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Impossible d'activer le privilège SeBackupPrivilege. Vous devez être administrateur." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'utilisation du privilège SeBackupPrivilege: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.BackupPrivilegeResult = if ($backupPrivilegeSuccess) { "Succès" } else { "Échec" }

    # 4. Tenter de prendre possession de la clé de registre
    Write-Host "`n=== Tentative de prise de possession de la clé de registre ===" -ForegroundColor Cyan
    $takeOwnershipSuccess = $false

    try {
        # Activer le privilège SeTakeOwnershipPrivilege
        $takeOwnershipEnabled = Enable-Privilege -Privilege "SeTakeOwnershipPrivilege"

        if ($takeOwnershipEnabled) {
            Write-Host "Privilège SeTakeOwnershipPrivilege activé avec succès." -ForegroundColor Green

            # Tenter de prendre possession de la clé de registre
            $script = {
                param($Path)

                try {
                    # Charger l'assembly pour les ACL de registre
                    Add-Type -AssemblyName System.Security

                    # Obtenir la clé de registre
                    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
                        $Path.Replace("HKLM:\", ""),
                        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
                        [System.Security.AccessControl.RegistryRights]::TakeOwnership
                    )

                    if ($key -ne $null) {
                        # Obtenir les ACL actuelles
                        $acl = $key.GetAccessControl()

                        # Définir le propriétaire
                        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
                        $acl.SetOwner($currentUser)

                        # Appliquer les nouvelles ACL
                        $key.SetAccessControl($acl)

                        # Fermer la clé
                        $key.Close()

                        # Rouvrir la clé avec des droits complets
                        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
                            $Path.Replace("HKLM:\", ""),
                            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
                            [System.Security.AccessControl.RegistryRights]::FullControl
                        )

                        # Obtenir les ACL actuelles
                        $acl = $key.GetAccessControl()

                        # Ajouter une règle d'accès pour l'utilisateur actuel
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

                        # Fermer la clé
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

            # Exécuter le script avec des privilèges élevés
            $result = Start-ElevatedProcess -ScriptBlock $script -ArgumentList $RegistryPath -Wait

            if ($result -eq 0) {
                $takeOwnershipSuccess = $true
                Write-Host "Prise de possession de la clé de registre réussie." -ForegroundColor Green
            } else {
                Write-Host "Échec de la prise de possession de la clé de registre." -ForegroundColor Red
            }
        } else {
            Write-Host "Impossible d'activer le privilège SeTakeOwnershipPrivilege." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la prise de possession: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.TakeOwnershipResult = if ($takeOwnershipSuccess) { "Succès" } else { "Échec" }

    # 5. Tenter d'utiliser un processus élevé
    Write-Host "`n=== Tentative avec un processus élevé ===" -ForegroundColor Cyan
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
            Write-Host "Accès avec processus élevé réussi." -ForegroundColor Green
        } else {
            Write-Host "Échec de l'accès avec processus élevé." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'accès avec processus élevé: $($_.Exception.Message)" -ForegroundColor Red
    }

    $results.ElevatedAccessResult = if ($elevatedAccessSuccess) { "Succès" } else { "Échec" }

    # 6. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    if ($backupPrivilegeSuccess) {
        $results.Recommendations += "Utilisez le privilège SeBackupPrivilege pour accéder à la clé de registre en lecture seule."
        Write-Host "- Utilisez le privilège SeBackupPrivilege pour accéder à la clé de registre en lecture seule." -ForegroundColor Green
    }

    if ($takeOwnershipSuccess) {
        $results.Recommendations += "Prenez possession de la clé de registre pour modifier ses permissions."
        Write-Host "- Prenez possession de la clé de registre pour modifier ses permissions." -ForegroundColor Green
    }

    if ($elevatedAccessSuccess) {
        $results.Recommendations += "Utilisez un processus élevé pour accéder à la clé de registre."
        Write-Host "- Utilisez un processus élevé pour accéder à la clé de registre." -ForegroundColor Green
    }

    if (-not ($backupPrivilegeSuccess -or $takeOwnershipSuccess -or $elevatedAccessSuccess)) {
        $results.Recommendations += "Utilisez l'éditeur de registre (regedit.exe) en mode administrateur."
        $results.Recommendations += "Utilisez l'outil de ligne de commande reg.exe avec des privilèges élevés."
        $results.Recommendations += "Utilisez PowerShell avec le module PSRemoting pour accéder au registre à distance."

        Write-Host "- Utilisez l'éditeur de registre (regedit.exe) en mode administrateur." -ForegroundColor Yellow
        Write-Host "- Utilisez l'outil de ligne de commande reg.exe avec des privilèges élevés." -ForegroundColor Yellow
        Write-Host "- Utilisez PowerShell avec le module PSRemoting pour accéder au registre à distance." -ForegroundColor Yellow
    }

    return $results
}

function Debug-NetworkAccess {
    <#
    .SYNOPSIS
        Démontre et débogue l'accès à une ressource réseau.

    .DESCRIPTION
        Cette fonction tente d'accéder à une ressource réseau de différentes manières
        et montre comment déboguer et résoudre les problèmes d'accès.

    .PARAMETER NetworkPath
        Le chemin de la ressource réseau à déboguer (UNC).

    .PARAMETER Credential
        Les informations d'identification à utiliser pour l'accès réseau.

    .EXAMPLE
        Debug-NetworkAccess -NetworkPath "\\server\share\file.txt"

    .EXAMPLE
        $cred = Get-Credential
        Debug-NetworkAccess -NetworkPath "\\server\share\file.txt" -Credential $cred

    .OUTPUTS
        [PSCustomObject] avec des informations sur les différentes tentatives d'accès
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

    # Extraire le serveur et le partage du chemin réseau
    if ($NetworkPath -match "\\\\([^\\]+)\\([^\\]+)") {
        $results.Server = $matches[1]
        $results.Share = $matches[2]
    } else {
        Write-Warning "Le chemin réseau '$NetworkPath' n'est pas un chemin UNC valide (format attendu: \\server\share\...)."
        $results.Recommendations += "Utilisez un chemin UNC valide au format \\server\share\..."
        return $results
    }

    # 1. Vérifier si le serveur répond au ping
    Write-Host "`n=== Test de connectivité réseau (Ping) ===" -ForegroundColor Cyan
    try {
        $pingResult = Test-Connection -ComputerName $results.Server -Count 2 -Quiet
        $results.PingResult = $pingResult

        if ($pingResult) {
            Write-Host "Le serveur '$($results.Server)' répond au ping." -ForegroundColor Green
        } else {
            Write-Host "Le serveur '$($results.Server)' ne répond pas au ping." -ForegroundColor Red
            Write-Host "Cela peut être dû à un pare-feu ou à un serveur hors ligne." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Erreur lors du ping du serveur: $($_.Exception.Message)" -ForegroundColor Red
        $results.PingResult = $false
    }

    # 2. Scanner les ports courants pour les partages réseau
    Write-Host "`n=== Test des ports réseau ===" -ForegroundColor Cyan
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
                    Write-Host "Port $port: Fermé" -ForegroundColor Red
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
        Write-Host "Aucun port SMB/CIFS n'est ouvert sur le serveur. Les partages réseau ne sont pas accessibles." -ForegroundColor Red
        $results.Recommendations += "Vérifiez que le service de partage de fichiers est activé sur le serveur."
        $results.Recommendations += "Vérifiez que les ports 139 et 445 ne sont pas bloqués par un pare-feu."
    }

    # 3. Vérifier si le chemin réseau existe
    Write-Host "`n=== Vérification de l'existence du chemin réseau ===" -ForegroundColor Cyan
    $results.PathExists = Test-Path -Path $NetworkPath -ErrorAction SilentlyContinue

    if ($results.PathExists) {
        Write-Host "Le chemin réseau '$NetworkPath' existe." -ForegroundColor Green
    } else {
        Write-Host "Le chemin réseau '$NetworkPath' n'existe pas ou n'est pas accessible." -ForegroundColor Red
    }

    # 4. Tenter un accès direct
    Write-Host "`n=== Tentative d'accès direct ===" -ForegroundColor Cyan
    $directAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
        if ((Get-Item -Path $NetworkPath -ErrorAction Stop).PSIsContainer) {
            Get-ChildItem -Path $NetworkPath -ErrorAction Stop
        } else {
            Get-Content -Path $NetworkPath -TotalCount 1 -ErrorAction Stop
        }
    } -Path $NetworkPath

    $results.DirectAccessResult = if ($directAccessResult.Success) { "Succès" } else { "Échec" }

    if ($directAccessResult.Success) {
        Write-Host "L'accès direct a réussi." -ForegroundColor Green
    } else {
        Write-Host "L'accès direct a échoué." -ForegroundColor Yellow
        Format-UnauthorizedAccessReport -DebugResult $directAccessResult
    }

    # 5. Tenter un accès avec les informations d'identification fournies
    if ($Credential) {
        Write-Host "`n=== Tentative d'accès avec informations d'identification ===" -ForegroundColor Cyan

        try {
            # Créer un objet NetworkCredential
            $netCred = $Credential.GetNetworkCredential()

            # Construire la commande net use
            $username = $netCred.Domain + "\" + $netCred.UserName
            $password = $netCred.Password
            $server = "\\" + $results.Server

            # Utiliser la commande net use pour établir une connexion
            $output = net use $server /user:$username $password 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Connexion établie avec le serveur en utilisant les informations d'identification fournies." -ForegroundColor Green

                # Tester l'accès au chemin
                $credAccessResult = Debug-UnauthorizedAccessException -ScriptBlock {
                    if ((Get-Item -Path $NetworkPath -ErrorAction Stop).PSIsContainer) {
                        Get-ChildItem -Path $NetworkPath -ErrorAction Stop
                    } else {
                        Get-Content -Path $NetworkPath -TotalCount 1 -ErrorAction Stop
                    }
                } -Path $NetworkPath

                $results.CredentialAccessResult = if ($credAccessResult.Success) { "Succès" } else { "Échec" }

                if ($credAccessResult.Success) {
                    Write-Host "L'accès avec informations d'identification a réussi." -ForegroundColor Green
                } else {
                    Write-Host "L'accès avec informations d'identification a échoué malgré une connexion réussie au serveur." -ForegroundColor Yellow
                    Format-UnauthorizedAccessReport -DebugResult $credAccessResult
                }

                # Déconnecter la session
                net use $server /delete | Out-Null
            } else {
                Write-Host "Échec de la connexion au serveur avec les informations d'identification fournies: $output" -ForegroundColor Red
                $results.CredentialAccessResult = "Échec"
            }
        } catch {
            Write-Host "Erreur lors de l'accès avec informations d'identification: $($_.Exception.Message)" -ForegroundColor Red
            $results.CredentialAccessResult = "Échec"
        }
    }

    # 6. Tenter un accès avec impersonation
    if ($Credential) {
        Write-Host "`n=== Tentative d'accès avec impersonation ===" -ForegroundColor Cyan

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

            $results.ImpersonationResult = if ($impersonationResult.Success) { "Succès" } else { "Échec" }

            if ($impersonationResult.Success) {
                Write-Host "L'accès avec impersonation a réussi." -ForegroundColor Green

                if ($impersonationResult.IsContainer) {
                    Write-Host "Le chemin est un dossier contenant $($impersonationResult.ItemCount) éléments." -ForegroundColor Green
                } else {
                    Write-Host "Le chemin est un fichier. Première ligne: $($impersonationResult.Content)" -ForegroundColor Green
                }
            } else {
                Write-Host "L'accès avec impersonation a échoué: $($impersonationResult.Error)" -ForegroundColor Red
            }
        } catch {
            Write-Host "Erreur lors de l'impersonation: $($_.Exception.Message)" -ForegroundColor Red
            $results.ImpersonationResult = "Échec"
        }
    }

    # 7. Diagnostics réseau supplémentaires
    Write-Host "`n=== Diagnostics réseau supplémentaires ===" -ForegroundColor Cyan

    # Vérifier les partages disponibles sur le serveur
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
        Write-Host "Erreur lors de la récupération des partages: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Vérifier les sessions actives
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
        Write-Host "Erreur lors de la récupération des sessions: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 8. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    # Recommandations basées sur les résultats des tests
    if (-not $results.PingResult) {
        $results.Recommendations += "Vérifiez que le serveur est en ligne et accessible sur le réseau."
        $results.Recommendations += "Vérifiez que le ping n'est pas bloqué par un pare-feu."
        Write-Host "- Vérifiez que le serveur est en ligne et accessible sur le réseau." -ForegroundColor Yellow
        Write-Host "- Vérifiez que le ping n'est pas bloqué par un pare-feu." -ForegroundColor Yellow
    }

    if ($results.PortScanResult.Count -eq 0) {
        $results.Recommendations += "Vérifiez que les ports SMB (139, 445) sont ouverts sur le serveur."
        Write-Host "- Vérifiez que les ports SMB (139, 445) sont ouverts sur le serveur." -ForegroundColor Yellow
    }

    if (-not $results.PathExists) {
        $results.Recommendations += "Vérifiez que le chemin réseau existe et que vous avez les permissions nécessaires."
        Write-Host "- Vérifiez que le chemin réseau existe et que vous avez les permissions nécessaires." -ForegroundColor Yellow
    }

    if ($results.DirectAccessResult -eq "Échec" -and $results.CredentialAccessResult -eq "Succès") {
        $results.Recommendations += "Utilisez des informations d'identification explicites pour accéder à cette ressource."
        Write-Host "- Utilisez des informations d'identification explicites pour accéder à cette ressource." -ForegroundColor Green
    }

    if ($results.ImpersonationResult -eq "Succès") {
        $results.Recommendations += "Utilisez l'impersonation pour accéder à cette ressource."
        Write-Host "- Utilisez l'impersonation pour accéder à cette ressource." -ForegroundColor Green
    }

    if ($results.NetworkDiagnostics["SharesAvailable"] -eq $false) {
        $results.Recommendations += "Vérifiez que le service de partage de fichiers est activé sur le serveur."
        Write-Host "- Vérifiez que le service de partage de fichiers est activé sur le serveur." -ForegroundColor Yellow
    }

    # Recommandations générales
    if ($results.DirectAccessResult -eq "Échec" -and $results.CredentialAccessResult -eq "Échec" -and $results.ImpersonationResult -eq "Échec") {
        $results.Recommendations += "Vérifiez les permissions sur le partage réseau."
        $results.Recommendations += "Vérifiez que le compte utilisé a accès au partage."
        $results.Recommendations += "Essayez d'accéder au partage avec un compte administrateur."
        $results.Recommendations += "Vérifiez les paramètres de sécurité du partage sur le serveur."

        Write-Host "- Vérifiez les permissions sur le partage réseau." -ForegroundColor Yellow
        Write-Host "- Vérifiez que le compte utilisé a accès au partage." -ForegroundColor Yellow
        Write-Host "- Essayez d'accéder au partage avec un compte administrateur." -ForegroundColor Yellow
        Write-Host "- Vérifiez les paramètres de sécurité du partage sur le serveur." -ForegroundColor Yellow
    }

    return $results
}

function Debug-DatabaseAccess {
    <#
    .SYNOPSIS
        Démontre et débogue l'accès à une base de données SQL Server.

    .DESCRIPTION
        Cette fonction tente d'accéder à une base de données SQL Server de différentes manières
        et montre comment déboguer et résoudre les problèmes d'accès.

    .PARAMETER ServerInstance
        Le nom de l'instance SQL Server (serveur\instance ou serveur).

    .PARAMETER Database
        Le nom de la base de données à déboguer.

    .PARAMETER Credential
        Les informations d'identification à utiliser pour l'accès à la base de données.

    .PARAMETER IntegratedSecurity
        Indique si l'authentification Windows doit être utilisée.

    .EXAMPLE
        Debug-DatabaseAccess -ServerInstance "localhost\SQLEXPRESS" -Database "AdventureWorks" -IntegratedSecurity

    .EXAMPLE
        $cred = Get-Credential
        Debug-DatabaseAccess -ServerInstance "localhost\SQLEXPRESS" -Database "AdventureWorks" -Credential $cred

    .OUTPUTS
        [PSCustomObject] avec des informations sur les différentes tentatives d'accès
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

    # Vérifier si le module SqlServer est installé
    if (-not (Get-Module -Name SqlServer -ListAvailable)) {
        Write-Warning "Le module SqlServer n'est pas installé. Installation en cours..."
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

    # 1. Vérifier si le serveur répond
    Write-Host "`n=== Test de connectivité au serveur SQL ===" -ForegroundColor Cyan
    try {
        $serverName = $ServerInstance.Split('\')[0]
        $pingResult = Test-Connection -ComputerName $serverName -Count 2 -Quiet
        $results.ConnectionDiagnostics["PingResult"] = $pingResult

        if ($pingResult) {
            Write-Host "Le serveur '$serverName' répond au ping." -ForegroundColor Green
        } else {
            Write-Host "Le serveur '$serverName' ne répond pas au ping." -ForegroundColor Red
            Write-Host "Cela peut être dû à un pare-feu ou à un serveur hors ligne." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Erreur lors du ping du serveur: $($_.Exception.Message)" -ForegroundColor Red
        $results.ConnectionDiagnostics["PingResult"] = $false
    }

    # 2. Scanner le port SQL Server
    Write-Host "`n=== Test du port SQL Server ===" -ForegroundColor Cyan
    try {
        $port = 1433  # Port SQL Server par défaut
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
                Write-Host "Port $port: Fermé" -ForegroundColor Red
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
            Write-Host "Connexion au serveur réussie avec l'authentification Windows." -ForegroundColor Green

            # Vérifier si la base de données existe
            $query = "SELECT name FROM sys.databases WHERE name = '$Database'"
            $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
            $reader = $command.ExecuteReader()

            if ($reader.Read()) {
                $results.DatabaseExists = $true
                Write-Host "La base de données '$Database' existe." -ForegroundColor Green
            } else {
                Write-Host "La base de données '$Database' n'existe pas." -ForegroundColor Red
                $results.Recommendations += "Vérifiez que la base de données existe sur le serveur."
            }

            $reader.Close()

            # Si la base de données existe, tenter de s'y connecter
            if ($results.DatabaseExists) {
                $connection.Close()
                $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
                $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
                $connection.Open()

                $results.DirectAccessResult = "Succès"
                Write-Host "Connexion à la base de données '$Database' réussie avec l'authentification Windows." -ForegroundColor Green

                # Vérifier les permissions de l'utilisateur
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
                    Write-Host "`nL'utilisateur actuel n'a aucune permission explicite dans la base de données." -ForegroundColor Yellow
                    $results.Recommendations += "Vérifiez que l'utilisateur a les permissions nécessaires dans la base de données."
                }
            }

            $connection.Close()
        } catch {
            Write-Host "Erreur lors de la connexion avec l'authentification Windows: $($_.Exception.Message)" -ForegroundColor Red
            $results.DirectAccessResult = "Échec"

            # Analyser l'erreur
            $errorMessage = $_.Exception.Message

            if ($errorMessage -match "Login failed for user") {
                $results.Recommendations += "Vérifiez que l'utilisateur Windows actuel a accès au serveur SQL."
                Write-Host "- Vérifiez que l'utilisateur Windows actuel a accès au serveur SQL." -ForegroundColor Yellow
            } elseif ($errorMessage -match "Cannot open database") {
                $results.Recommendations += "Vérifiez que l'utilisateur a accès à la base de données spécifiée."
                Write-Host "- Vérifiez que l'utilisateur a accès à la base de données spécifiée." -ForegroundColor Yellow
            } elseif ($errorMessage -match "network-related or instance-specific") {
                $results.Recommendations += "Vérifiez que le serveur SQL est en cours d'exécution et accessible sur le réseau."
                $results.Recommendations += "Vérifiez que le nom de l'instance est correct."
                Write-Host "- Vérifiez que le serveur SQL est en cours d'exécution et accessible sur le réseau." -ForegroundColor Yellow
                Write-Host "- Vérifiez que le nom de l'instance est correct." -ForegroundColor Yellow
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
            Write-Host "Connexion au serveur réussie avec l'authentification SQL." -ForegroundColor Green

            # Vérifier si la base de données existe
            $query = "SELECT name FROM sys.databases WHERE name = '$Database'"
            $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
            $reader = $command.ExecuteReader()

            if ($reader.Read()) {
                $results.DatabaseExists = $true
                Write-Host "La base de données '$Database' existe." -ForegroundColor Green
            } else {
                Write-Host "La base de données '$Database' n'existe pas." -ForegroundColor Red
                $results.Recommendations += "Vérifiez que la base de données existe sur le serveur."
            }

            $reader.Close()

            # Si la base de données existe, tenter de s'y connecter
            if ($results.DatabaseExists) {
                $connection.Close()
                $connectionString = "Server=$ServerInstance;Database=$Database;User Id=$username;Password=$password;"
                $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
                $connection.Open()

                $results.CredentialAccessResult = "Succès"
                Write-Host "Connexion à la base de données '$Database' réussie avec l'authentification SQL." -ForegroundColor Green

                # Vérifier les permissions de l'utilisateur
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
                    Write-Host "`nL'utilisateur SQL n'a aucune permission explicite dans la base de données." -ForegroundColor Yellow
                    $results.Recommendations += "Vérifiez que l'utilisateur SQL a les permissions nécessaires dans la base de données."
                }
            }

            $connection.Close()
        } catch {
            Write-Host "Erreur lors de la connexion avec l'authentification SQL: $($_.Exception.Message)" -ForegroundColor Red
            $results.CredentialAccessResult = "Échec"

            # Analyser l'erreur
            $errorMessage = $_.Exception.Message

            if ($errorMessage -match "Login failed for user") {
                $results.Recommendations += "Vérifiez que le nom d'utilisateur et le mot de passe SQL sont corrects."
                $results.Recommendations += "Vérifiez que l'authentification SQL est activée sur le serveur."
                Write-Host "- Vérifiez que le nom d'utilisateur et le mot de passe SQL sont corrects." -ForegroundColor Yellow
                Write-Host "- Vérifiez que l'authentification SQL est activée sur le serveur." -ForegroundColor Yellow
            } elseif ($errorMessage -match "Cannot open database") {
                $results.Recommendations += "Vérifiez que l'utilisateur SQL a accès à la base de données spécifiée."
                Write-Host "- Vérifiez que l'utilisateur SQL a accès à la base de données spécifiée." -ForegroundColor Yellow
            } elseif ($errorMessage -match "network-related or instance-specific") {
                $results.Recommendations += "Vérifiez que le serveur SQL est en cours d'exécution et accessible sur le réseau."
                $results.Recommendations += "Vérifiez que le nom de l'instance est correct."
                Write-Host "- Vérifiez que le serveur SQL est en cours d'exécution et accessible sur le réseau." -ForegroundColor Yellow
                Write-Host "- Vérifiez que le nom de l'instance est correct." -ForegroundColor Yellow
            }
        }
    }

    # 5. Tenter une connexion avec un processus élevé
    Write-Host "`n=== Tentative de connexion avec un processus élevé ===" -ForegroundColor Cyan

    $script = {
        param($ServerInstance, $Database, $IntegratedSecurity, $Username, $Password)

        try {
            # Construire la chaîne de connexion
            if ($IntegratedSecurity) {
                $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
            } else {
                $connectionString = "Server=$ServerInstance;Database=$Database;User Id=$Username;Password=$Password;"
            }

            # Tenter de se connecter
            $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
            $connection.Open()

            # Exécuter une requête simple
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
            $results.ElevatedAccessResult = "Succès"
            Write-Host "Connexion avec processus élevé réussie." -ForegroundColor Green
        } else {
            $results.ElevatedAccessResult = "Échec"
            Write-Host "Échec de la connexion avec processus élevé." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la connexion avec processus élevé: $($_.Exception.Message)" -ForegroundColor Red
        $results.ElevatedAccessResult = "Échec"
    }

    # 6. Recommandations
    Write-Host "`n=== Recommandations ===" -ForegroundColor Cyan

    # Recommandations basées sur les résultats des tests
    if (-not $results.ConnectionDiagnostics["PingResult"]) {
        $results.Recommendations += "Vérifiez que le serveur est en ligne et accessible sur le réseau."
        Write-Host "- Vérifiez que le serveur est en ligne et accessible sur le réseau." -ForegroundColor Yellow
    }

    if (-not $results.ConnectionDiagnostics["PortOpen"]) {
        $results.Recommendations += "Vérifiez que le port SQL Server (1433 par défaut) est ouvert sur le serveur."
        $results.Recommendations += "Vérifiez que le service SQL Server est en cours d'exécution."
        Write-Host "- Vérifiez que le port SQL Server (1433 par défaut) est ouvert sur le serveur." -ForegroundColor Yellow
        Write-Host "- Vérifiez que le service SQL Server est en cours d'exécution." -ForegroundColor Yellow
    }

    if (-not $results.DatabaseExists) {
        $results.Recommendations += "Vérifiez que la base de données existe sur le serveur."
        Write-Host "- Vérifiez que la base de données existe sur le serveur." -ForegroundColor Yellow
    }

    if ($results.DirectAccessResult -eq "Échec" -and $results.CredentialAccessResult -eq "Succès") {
        $results.Recommendations += "Utilisez l'authentification SQL pour accéder à cette base de données."
        Write-Host "- Utilisez l'authentification SQL pour accéder à cette base de données." -ForegroundColor Green
    }

    if ($results.DirectAccessResult -eq "Échec" -and $results.CredentialAccessResult -eq "Échec" -and $results.ElevatedAccessResult -eq "Succès") {
        $results.Recommendations += "Utilisez un processus élevé pour accéder à cette base de données."
        Write-Host "- Utilisez un processus élevé pour accéder à cette base de données." -ForegroundColor Green
    }

    # Recommandations générales
    if ($results.DirectAccessResult -eq "Échec" -and $results.CredentialAccessResult -eq "Échec" -and $results.ElevatedAccessResult -eq "Échec") {
        $results.Recommendations += "Vérifiez les permissions de l'utilisateur dans SQL Server."
        $results.Recommendations += "Vérifiez que l'authentification appropriée est activée sur le serveur."
        $results.Recommendations += "Vérifiez les paramètres de sécurité de SQL Server."
        $results.Recommendations += "Consultez les journaux d'erreurs SQL Server pour plus d'informations."

        Write-Host "- Vérifiez les permissions de l'utilisateur dans SQL Server." -ForegroundColor Yellow
        Write-Host "- Vérifiez que l'authentification appropriée est activée sur le serveur." -ForegroundColor Yellow
        Write-Host "- Vérifiez les paramètres de sécurité de SQL Server." -ForegroundColor Yellow
        Write-Host "- Consultez les journaux d'erreurs SQL Server pour plus d'informations." -ForegroundColor Yellow
    }

    return $results
}

# Exporter les fonctions
Export-ModuleMember -Function Debug-SystemFileAccess, Debug-RegistryKeyAccess, Debug-NetworkAccess, Debug-DatabaseAccess

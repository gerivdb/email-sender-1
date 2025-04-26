<#
.SYNOPSIS
    Outils d'élévation de privilèges temporaires pour résoudre les problèmes d'accès.
.DESCRIPTION
    Ce script fournit des fonctions pour élever temporairement les privilèges afin de résoudre
    les problèmes d'accès, en particulier pour les erreurs UnauthorizedAccessException.
.NOTES
    Auteur: Augment Code
    Date de création: 2023-11-15
#>

function Start-ElevatedProcess {
    <#
    .SYNOPSIS
        Lance un nouveau processus PowerShell avec des privilèges administratifs.
    
    .DESCRIPTION
        Cette fonction lance un nouveau processus PowerShell avec des privilèges administratifs
        et exécute le script ou la commande spécifiée.
    
    .PARAMETER ScriptBlock
        Le bloc de script à exécuter avec des privilèges élevés.
    
    .PARAMETER ScriptPath
        Le chemin d'un script PowerShell à exécuter avec des privilèges élevés.
    
    .PARAMETER ArgumentList
        Les arguments à passer au script ou à la commande.
    
    .PARAMETER NoExit
        Indique si la fenêtre PowerShell doit rester ouverte après l'exécution.
    
    .PARAMETER Wait
        Indique si la fonction doit attendre la fin de l'exécution du processus.
    
    .EXAMPLE
        Start-ElevatedProcess -ScriptBlock { Set-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "# Nouvelle entrée" }
    
    .EXAMPLE
        Start-ElevatedProcess -ScriptPath "C:\Scripts\ModifyHosts.ps1" -ArgumentList "param1", "param2"
    
    .OUTPUTS
        [System.Diagnostics.Process] si Wait est $false, [int] (code de sortie) si Wait est $true
    #>
    [CmdletBinding(DefaultParameterSetName = "ScriptBlock")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ScriptBlock")]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ScriptPath")]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ArgumentList,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoExit,
        
        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )
    
    # Vérifier si nous sommes déjà en mode administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Warning "Le processus actuel est déjà en mode administrateur."
        
        # Exécuter directement le code si nous sommes déjà en mode administrateur
        if ($PSCmdlet.ParameterSetName -eq "ScriptBlock") {
            return & $ScriptBlock
        } else {
            $scriptArgs = if ($ArgumentList) { $ArgumentList } else { @() }
            return & $ScriptPath @scriptArgs
        }
    }
    
    # Préparer la commande PowerShell
    $arguments = @()
    
    if ($NoExit) {
        $arguments += "-NoExit"
    }
    
    if ($PSCmdlet.ParameterSetName -eq "ScriptBlock") {
        # Convertir le ScriptBlock en commande
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptBlock.ToString()))
        $arguments += "-EncodedCommand", $encodedCommand
    } else {
        # Utiliser le chemin du script
        $arguments += "-File", "`"$ScriptPath`""
        
        # Ajouter les arguments du script
        if ($ArgumentList) {
            $arguments += $ArgumentList
        }
    }
    
    # Lancer PowerShell en tant qu'administrateur
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "powershell.exe"
    $startInfo.Arguments = $arguments -join " "
    $startInfo.Verb = "runas"  # Demande d'élévation de privilèges
    $startInfo.UseShellExecute = $true
    
    try {
        $process = [System.Diagnostics.Process]::Start($startInfo)
        
        if ($Wait -and $process -ne $null) {
            $process.WaitForExit()
            return $process.ExitCode
        }
        
        return $process
    } catch {
        Write-Error "Impossible de lancer le processus avec des privilèges élevés : $($_.Exception.Message)"
        return $null
    }
}

function Invoke-WithImpersonation {
    <#
    .SYNOPSIS
        Exécute une opération en utilisant les informations d'identification d'un autre utilisateur.
    
    .DESCRIPTION
        Cette fonction utilise l'impersonation pour exécuter un bloc de code avec les informations
        d'identification d'un autre utilisateur, ce qui peut être utile pour accéder à des ressources
        auxquelles l'utilisateur actuel n'a pas accès.
    
    .PARAMETER Credential
        Les informations d'identification à utiliser pour l'impersonation.
    
    .PARAMETER ScriptBlock
        Le bloc de code à exécuter avec les informations d'identification spécifiées.
    
    .EXAMPLE
        $cred = Get-Credential
        Invoke-WithImpersonation -Credential $cred -ScriptBlock {
            Get-Content -Path "\\server\share\file.txt"
        }
    
    .OUTPUTS
        Le résultat du bloc de code exécuté avec les informations d'identification spécifiées.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    # Ajouter les types nécessaires
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Security.Principal;

public class ImpersonationHelper
{
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LogonUser(
        string lpszUsername,
        string lpszDomain,
        IntPtr lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        ref IntPtr phToken);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool ImpersonateLoggedOnUser(IntPtr hToken);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool RevertToSelf();
}
"@
    
    # Constantes pour LogonUser
    $LOGON32_LOGON_INTERACTIVE = 2
    $LOGON32_PROVIDER_DEFAULT = 0
    
    # Extraire le nom d'utilisateur et le domaine
    $username = $Credential.UserName
    $domain = "."
    
    if ($username.Contains("\")) {
        $parts = $username.Split("\")
        $domain = $parts[0]
        $username = $parts[1]
    } elseif ($username.Contains("@")) {
        $parts = $username.Split("@")
        $username = $parts[0]
        $domain = $parts[1]
    }
    
    # Obtenir le mot de passe en texte clair
    $password = $Credential.GetNetworkCredential().Password
    $passwordPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($Credential.Password)
    
    # Initialiser le handle du token
    $tokenHandle = [IntPtr]::Zero
    
    try {
        # Tenter de se connecter avec les informations d'identification
        $result = [ImpersonationHelper]::LogonUser(
            $username,
            $domain,
            $passwordPtr,
            $LOGON32_LOGON_INTERACTIVE,
            $LOGON32_PROVIDER_DEFAULT,
            [ref]$tokenHandle)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            throw "Échec de LogonUser. Code d'erreur : $errorCode"
        }
        
        # Impersonate l'utilisateur
        $result = [ImpersonationHelper]::ImpersonateLoggedOnUser($tokenHandle)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            throw "Échec de ImpersonateLoggedOnUser. Code d'erreur : $errorCode"
        }
        
        # Exécuter le bloc de code
        return & $ScriptBlock
    } finally {
        # Revenir à l'identité originale
        [void][ImpersonationHelper]::RevertToSelf()
        
        # Fermer le handle du token
        if ($tokenHandle -ne [IntPtr]::Zero) {
            [void][ImpersonationHelper]::CloseHandle($tokenHandle)
        }
        
        # Libérer la mémoire allouée pour le mot de passe
        if ($passwordPtr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($passwordPtr)
        }
    }
}

function Edit-ProtectedFile {
    <#
    .SYNOPSIS
        Modifie un fichier protégé en utilisant une copie temporaire.
    
    .DESCRIPTION
        Cette fonction permet de modifier un fichier protégé en le copiant dans un emplacement
        temporaire, en le modifiant, puis en le recopiant à son emplacement d'origine avec
        des privilèges élevés.
    
    .PARAMETER Path
        Le chemin du fichier protégé à modifier.
    
    .PARAMETER EditScriptBlock
        Le bloc de code qui effectue les modifications sur la copie temporaire.
    
    .PARAMETER ElevationMethod
        La méthode d'élévation de privilèges à utiliser (NewProcess ou Impersonation).
    
    .PARAMETER Credential
        Les informations d'identification à utiliser pour l'impersonation (si ElevationMethod est Impersonation).
    
    .EXAMPLE
        Edit-ProtectedFile -Path "C:\Windows\System32\drivers\etc\hosts" -EditScriptBlock {
            param($TempFile)
            Add-Content -Path $TempFile -Value "127.0.0.1 example.com"
        }
    
    .OUTPUTS
        [PSCustomObject] avec des informations sur le résultat de l'opération
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$EditScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("NewProcess", "Impersonation")]
        [string]$ElevationMethod = "NewProcess",
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
        return [PSCustomObject]@{
            Success = $false
            Message = "Le fichier '$Path' n'existe pas."
            OriginalPath = $Path
            TempPath = $null
        }
    }
    
    # Créer un répertoire temporaire
    $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # Créer le chemin du fichier temporaire
    $tempFile = Join-Path -Path $tempDir -ChildPath ([System.IO.Path]::GetFileName($Path))
    
    try {
        # Copier le fichier original vers le fichier temporaire
        Copy-Item -Path $Path -Destination $tempFile -Force -ErrorAction Stop
        
        # Appliquer les modifications au fichier temporaire
        & $EditScriptBlock $tempFile
        
        # Vérifier si le fichier temporaire existe toujours
        if (-not (Test-Path -Path $tempFile -ErrorAction SilentlyContinue)) {
            return [PSCustomObject]@{
                Success = $false
                Message = "Le fichier temporaire a été supprimé pendant l'édition."
                OriginalPath = $Path
                TempPath = $tempFile
            }
        }
        
        # Copier le fichier temporaire vers le fichier original avec élévation de privilèges
        switch ($ElevationMethod) {
            "NewProcess" {
                # Utiliser un nouveau processus avec privilèges élevés
                $copyScript = {
                    param($Source, $Destination)
                    Copy-Item -Path $Source -Destination $Destination -Force
                    if ($?) {
                        return "Succès"
                    } else {
                        return "Échec"
                    }
                }
                
                $result = Start-ElevatedProcess -ScriptBlock $copyScript -ArgumentList $tempFile, $Path -Wait
                
                if ($result -eq 0) {
                    return [PSCustomObject]@{
                        Success = $true
                        Message = "Le fichier a été modifié avec succès."
                        OriginalPath = $Path
                        TempPath = $tempFile
                    }
                } else {
                    return [PSCustomObject]@{
                        Success = $false
                        Message = "Impossible de copier le fichier temporaire vers le fichier original."
                        OriginalPath = $Path
                        TempPath = $tempFile
                    }
                }
            }
            "Impersonation" {
                # Vérifier si les informations d'identification sont fournies
                if (-not $Credential) {
                    return [PSCustomObject]@{
                        Success = $false
                        Message = "Les informations d'identification sont requises pour l'impersonation."
                        OriginalPath = $Path
                        TempPath = $tempFile
                    }
                }
                
                # Utiliser l'impersonation
                $result = Invoke-WithImpersonation -Credential $Credential -ScriptBlock {
                    param($Source, $Destination)
                    try {
                        Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction Stop
                        return $true
                    } catch {
                        return $false
                    }
                }.GetNewClosure()
                
                if ($result) {
                    return [PSCustomObject]@{
                        Success = $true
                        Message = "Le fichier a été modifié avec succès."
                        OriginalPath = $Path
                        TempPath = $tempFile
                    }
                } else {
                    return [PSCustomObject]@{
                        Success = $false
                        Message = "Impossible de copier le fichier temporaire vers le fichier original."
                        OriginalPath = $Path
                        TempPath = $tempFile
                    }
                }
            }
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "Erreur lors de la modification du fichier : $($_.Exception.Message)"
            OriginalPath = $Path
            TempPath = $tempFile
        }
    } finally {
        # Nettoyer le répertoire temporaire
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Set-TemporaryPermission {
    <#
    .SYNOPSIS
        Modifie temporairement les permissions d'un fichier ou d'un dossier.
    
    .DESCRIPTION
        Cette fonction modifie temporairement les permissions d'un fichier ou d'un dossier
        pour effectuer une opération, puis restaure les permissions d'origine.
    
    .PARAMETER Path
        Le chemin du fichier ou du dossier à modifier.
    
    .PARAMETER Identity
        L'identité à laquelle accorder les permissions temporaires.
    
    .PARAMETER Permission
        Les permissions à accorder temporairement.
    
    .PARAMETER ScriptBlock
        Le bloc de code à exécuter avec les permissions temporaires.
    
    .EXAMPLE
        Set-TemporaryPermission -Path "C:\Data\Confidential" -Identity "DOMAIN\User" -Permission "Read" -ScriptBlock {
            Get-Content -Path "C:\Data\Confidential\secret.txt"
        }
    
    .OUTPUTS
        Le résultat du bloc de code exécuté avec les permissions temporaires.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Identity,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Read", "Write", "ReadAndExecute", "Modify", "FullControl")]
        [string]$Permission,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return
    }
    
    # Convertir la permission en droit du système de fichiers
    $fileSystemRight = switch ($Permission) {
        "Read" { [System.Security.AccessControl.FileSystemRights]::Read }
        "Write" { [System.Security.AccessControl.FileSystemRights]::Write }
        "ReadAndExecute" { [System.Security.AccessControl.FileSystemRights]::ReadAndExecute }
        "Modify" { [System.Security.AccessControl.FileSystemRights]::Modify }
        "FullControl" { [System.Security.AccessControl.FileSystemRights]::FullControl }
    }
    
    # Obtenir les ACL actuelles
    $acl = Get-Acl -Path $Path
    $originalAcl = $acl.Clone()
    
    # Créer une nouvelle règle d'accès
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Identity,
        $fileSystemRight,
        [System.Security.AccessControl.InheritanceFlags]::None,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    
    try {
        # Ajouter la nouvelle règle d'accès
        $acl.AddAccessRule($accessRule)
        
        # Appliquer les nouvelles ACL
        if ($PSCmdlet.ShouldProcess($Path, "Modifier temporairement les permissions")) {
            Set-Acl -Path $Path -AclObject $acl
        }
        
        # Exécuter le bloc de code
        return & $ScriptBlock
    } finally {
        # Restaurer les ACL d'origine
        if ($PSCmdlet.ShouldProcess($Path, "Restaurer les permissions d'origine")) {
            Set-Acl -Path $Path -AclObject $originalAcl
        }
    }
}

function Enable-Privilege {
    <#
    .SYNOPSIS
        Active un privilège spécifique pour le processus actuel.
    
    .DESCRIPTION
        Cette fonction utilise l'API Windows pour activer un privilège spécifique pour le processus
        actuel, ce qui peut être utile pour effectuer certaines opérations système.
    
    .PARAMETER Privilege
        Le privilège à activer.
    
    .EXAMPLE
        Enable-Privilege -Privilege "SeBackupPrivilege"
    
    .OUTPUTS
        [bool] Indique si le privilège a été activé avec succès.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
            "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
            "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
            "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege",
            "SeIncreaseBasePriorityPrivilege", "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege",
            "SeLoadDriverPrivilege", "SeLockMemoryPrivilege", "SeMachineAccountPrivilege",
            "SeManageVolumePrivilege", "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege",
            "SeRemoteShutdownPrivilege", "SeRestorePrivilege", "SeSecurityPrivilege",
            "SeShutdownPrivilege", "SeSyncAgentPrivilege", "SeSystemEnvironmentPrivilege",
            "SeSystemProfilePrivilege", "SeSystemtimePrivilege", "SeTakeOwnershipPrivilege",
            "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
            "SeUndockPrivilege", "SeUnsolicitedInputPrivilege"
        )]
        [string]$Privilege
    )
    
    # Ajouter les types nécessaires
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class PrivilegeHelper
{
    [DllImport("advapi32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool AdjustTokenPrivileges(
        IntPtr TokenHandle,
        [MarshalAs(UnmanagedType.Bool)] bool DisableAllPrivileges,
        ref TOKEN_PRIVILEGES NewState,
        UInt32 BufferLength,
        IntPtr PreviousState,
        IntPtr ReturnLength);

    [DllImport("advapi32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool OpenProcessToken(
        IntPtr ProcessHandle,
        UInt32 DesiredAccess,
        ref IntPtr TokenHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetCurrentProcess();

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LookupPrivilegeValue(
        string lpSystemName,
        string lpName,
        ref LUID lpLuid);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID
    {
        public UInt32 LowPart;
        public Int32 HighPart;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct TOKEN_PRIVILEGES
    {
        public UInt32 PrivilegeCount;
        public LUID_AND_ATTRIBUTES Privileges;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID_AND_ATTRIBUTES
    {
        public LUID Luid;
        public UInt32 Attributes;
    }
}
"@
    
    # Constantes
    $TOKEN_ADJUST_PRIVILEGES = 0x0020
    $TOKEN_QUERY = 0x0008
    $SE_PRIVILEGE_ENABLED = 0x00000002
    
    # Initialiser les variables
    $tokenHandle = [IntPtr]::Zero
    $luid = New-Object PrivilegeHelper+LUID
    
    try {
        # Ouvrir le token du processus actuel
        $result = [PrivilegeHelper]::OpenProcessToken(
            [PrivilegeHelper]::GetCurrentProcess(),
            $TOKEN_ADJUST_PRIVILEGES -bor $TOKEN_QUERY,
            [ref]$tokenHandle)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Error "Échec de OpenProcessToken. Code d'erreur : $errorCode"
            return $false
        }
        
        # Rechercher la valeur du privilège
        $result = [PrivilegeHelper]::LookupPrivilegeValue($null, $Privilege, [ref]$luid)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Error "Échec de LookupPrivilegeValue. Code d'erreur : $errorCode"
            return $false
        }
        
        # Préparer la structure TOKEN_PRIVILEGES
        $tokenPrivileges = New-Object PrivilegeHelper+TOKEN_PRIVILEGES
        $tokenPrivileges.PrivilegeCount = 1
        $tokenPrivileges.Privileges.Luid = $luid
        $tokenPrivileges.Privileges.Attributes = $SE_PRIVILEGE_ENABLED
        
        # Ajuster les privilèges du token
        $result = [PrivilegeHelper]::AdjustTokenPrivileges(
            $tokenHandle,
            $false,
            [ref]$tokenPrivileges,
            0,
            [IntPtr]::Zero,
            [IntPtr]::Zero)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Error "Échec de AdjustTokenPrivileges. Code d'erreur : $errorCode"
            return $false
        }
        
        return $true
    } finally {
        # Fermer le handle du token
        if ($tokenHandle -ne [IntPtr]::Zero) {
            [void][PrivilegeHelper]::CloseHandle($tokenHandle)
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Start-ElevatedProcess, Invoke-WithImpersonation, Edit-ProtectedFile, Set-TemporaryPermission, Enable-Privilege

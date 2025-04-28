<#
.SYNOPSIS
    Outils d'Ã©lÃ©vation de privilÃ¨ges temporaires pour rÃ©soudre les problÃ¨mes d'accÃ¨s.
.DESCRIPTION
    Ce script fournit des fonctions pour Ã©lever temporairement les privilÃ¨ges afin de rÃ©soudre
    les problÃ¨mes d'accÃ¨s, en particulier pour les erreurs UnauthorizedAccessException.
.NOTES
    Auteur: Augment Code
    Date de crÃ©ation: 2023-11-15
#>

function Start-ElevatedProcess {
    <#
    .SYNOPSIS
        Lance un nouveau processus PowerShell avec des privilÃ¨ges administratifs.
    
    .DESCRIPTION
        Cette fonction lance un nouveau processus PowerShell avec des privilÃ¨ges administratifs
        et exÃ©cute le script ou la commande spÃ©cifiÃ©e.
    
    .PARAMETER ScriptBlock
        Le bloc de script Ã  exÃ©cuter avec des privilÃ¨ges Ã©levÃ©s.
    
    .PARAMETER ScriptPath
        Le chemin d'un script PowerShell Ã  exÃ©cuter avec des privilÃ¨ges Ã©levÃ©s.
    
    .PARAMETER ArgumentList
        Les arguments Ã  passer au script ou Ã  la commande.
    
    .PARAMETER NoExit
        Indique si la fenÃªtre PowerShell doit rester ouverte aprÃ¨s l'exÃ©cution.
    
    .PARAMETER Wait
        Indique si la fonction doit attendre la fin de l'exÃ©cution du processus.
    
    .EXAMPLE
        Start-ElevatedProcess -ScriptBlock { Set-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "# Nouvelle entrÃ©e" }
    
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
    
    # VÃ©rifier si nous sommes dÃ©jÃ  en mode administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Warning "Le processus actuel est dÃ©jÃ  en mode administrateur."
        
        # ExÃ©cuter directement le code si nous sommes dÃ©jÃ  en mode administrateur
        if ($PSCmdlet.ParameterSetName -eq "ScriptBlock") {
            return & $ScriptBlock
        } else {
            $scriptArgs = if ($ArgumentList) { $ArgumentList } else { @() }
            return & $ScriptPath @scriptArgs
        }
    }
    
    # PrÃ©parer la commande PowerShell
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
    $startInfo.Verb = "runas"  # Demande d'Ã©lÃ©vation de privilÃ¨ges
    $startInfo.UseShellExecute = $true
    
    try {
        $process = [System.Diagnostics.Process]::Start($startInfo)
        
        if ($Wait -and $process -ne $null) {
            $process.WaitForExit()
            return $process.ExitCode
        }
        
        return $process
    } catch {
        Write-Error "Impossible de lancer le processus avec des privilÃ¨ges Ã©levÃ©s : $($_.Exception.Message)"
        return $null
    }
}

function Invoke-WithImpersonation {
    <#
    .SYNOPSIS
        ExÃ©cute une opÃ©ration en utilisant les informations d'identification d'un autre utilisateur.
    
    .DESCRIPTION
        Cette fonction utilise l'impersonation pour exÃ©cuter un bloc de code avec les informations
        d'identification d'un autre utilisateur, ce qui peut Ãªtre utile pour accÃ©der Ã  des ressources
        auxquelles l'utilisateur actuel n'a pas accÃ¨s.
    
    .PARAMETER Credential
        Les informations d'identification Ã  utiliser pour l'impersonation.
    
    .PARAMETER ScriptBlock
        Le bloc de code Ã  exÃ©cuter avec les informations d'identification spÃ©cifiÃ©es.
    
    .EXAMPLE
        $cred = Get-Credential
        Invoke-WithImpersonation -Credential $cred -ScriptBlock {
            Get-Content -Path "\\server\share\file.txt"
        }
    
    .OUTPUTS
        Le rÃ©sultat du bloc de code exÃ©cutÃ© avec les informations d'identification spÃ©cifiÃ©es.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    # Ajouter les types nÃ©cessaires
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
            throw "Ã‰chec de LogonUser. Code d'erreur : $errorCode"
        }
        
        # Impersonate l'utilisateur
        $result = [ImpersonationHelper]::ImpersonateLoggedOnUser($tokenHandle)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            throw "Ã‰chec de ImpersonateLoggedOnUser. Code d'erreur : $errorCode"
        }
        
        # ExÃ©cuter le bloc de code
        return & $ScriptBlock
    } finally {
        # Revenir Ã  l'identitÃ© originale
        [void][ImpersonationHelper]::RevertToSelf()
        
        # Fermer le handle du token
        if ($tokenHandle -ne [IntPtr]::Zero) {
            [void][ImpersonationHelper]::CloseHandle($tokenHandle)
        }
        
        # LibÃ©rer la mÃ©moire allouÃ©e pour le mot de passe
        if ($passwordPtr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($passwordPtr)
        }
    }
}

function Edit-ProtectedFile {
    <#
    .SYNOPSIS
        Modifie un fichier protÃ©gÃ© en utilisant une copie temporaire.
    
    .DESCRIPTION
        Cette fonction permet de modifier un fichier protÃ©gÃ© en le copiant dans un emplacement
        temporaire, en le modifiant, puis en le recopiant Ã  son emplacement d'origine avec
        des privilÃ¨ges Ã©levÃ©s.
    
    .PARAMETER Path
        Le chemin du fichier protÃ©gÃ© Ã  modifier.
    
    .PARAMETER EditScriptBlock
        Le bloc de code qui effectue les modifications sur la copie temporaire.
    
    .PARAMETER ElevationMethod
        La mÃ©thode d'Ã©lÃ©vation de privilÃ¨ges Ã  utiliser (NewProcess ou Impersonation).
    
    .PARAMETER Credential
        Les informations d'identification Ã  utiliser pour l'impersonation (si ElevationMethod est Impersonation).
    
    .EXAMPLE
        Edit-ProtectedFile -Path "C:\Windows\System32\drivers\etc\hosts" -EditScriptBlock {
            param($TempFile)
            Add-Content -Path $TempFile -Value "127.0.0.1 example.com"
        }
    
    .OUTPUTS
        [PSCustomObject] avec des informations sur le rÃ©sultat de l'opÃ©ration
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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
        return [PSCustomObject]@{
            Success = $false
            Message = "Le fichier '$Path' n'existe pas."
            OriginalPath = $Path
            TempPath = $null
        }
    }
    
    # CrÃ©er un rÃ©pertoire temporaire
    $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # CrÃ©er le chemin du fichier temporaire
    $tempFile = Join-Path -Path $tempDir -ChildPath ([System.IO.Path]::GetFileName($Path))
    
    try {
        # Copier le fichier original vers le fichier temporaire
        Copy-Item -Path $Path -Destination $tempFile -Force -ErrorAction Stop
        
        # Appliquer les modifications au fichier temporaire
        & $EditScriptBlock $tempFile
        
        # VÃ©rifier si le fichier temporaire existe toujours
        if (-not (Test-Path -Path $tempFile -ErrorAction SilentlyContinue)) {
            return [PSCustomObject]@{
                Success = $false
                Message = "Le fichier temporaire a Ã©tÃ© supprimÃ© pendant l'Ã©dition."
                OriginalPath = $Path
                TempPath = $tempFile
            }
        }
        
        # Copier le fichier temporaire vers le fichier original avec Ã©lÃ©vation de privilÃ¨ges
        switch ($ElevationMethod) {
            "NewProcess" {
                # Utiliser un nouveau processus avec privilÃ¨ges Ã©levÃ©s
                $copyScript = {
                    param($Source, $Destination)
                    Copy-Item -Path $Source -Destination $Destination -Force
                    if ($?) {
                        return "SuccÃ¨s"
                    } else {
                        return "Ã‰chec"
                    }
                }
                
                $result = Start-ElevatedProcess -ScriptBlock $copyScript -ArgumentList $tempFile, $Path -Wait
                
                if ($result -eq 0) {
                    return [PSCustomObject]@{
                        Success = $true
                        Message = "Le fichier a Ã©tÃ© modifiÃ© avec succÃ¨s."
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
                # VÃ©rifier si les informations d'identification sont fournies
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
                        Message = "Le fichier a Ã©tÃ© modifiÃ© avec succÃ¨s."
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
        # Nettoyer le rÃ©pertoire temporaire
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Set-TemporaryPermission {
    <#
    .SYNOPSIS
        Modifie temporairement les permissions d'un fichier ou d'un dossier.
    
    .DESCRIPTION
        Cette fonction modifie temporairement les permissions d'un fichier ou d'un dossier
        pour effectuer une opÃ©ration, puis restaure les permissions d'origine.
    
    .PARAMETER Path
        Le chemin du fichier ou du dossier Ã  modifier.
    
    .PARAMETER Identity
        L'identitÃ© Ã  laquelle accorder les permissions temporaires.
    
    .PARAMETER Permission
        Les permissions Ã  accorder temporairement.
    
    .PARAMETER ScriptBlock
        Le bloc de code Ã  exÃ©cuter avec les permissions temporaires.
    
    .EXAMPLE
        Set-TemporaryPermission -Path "C:\Data\Confidential" -Identity "DOMAIN\User" -Permission "Read" -ScriptBlock {
            Get-Content -Path "C:\Data\Confidential\secret.txt"
        }
    
    .OUTPUTS
        Le rÃ©sultat du bloc de code exÃ©cutÃ© avec les permissions temporaires.
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
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return
    }
    
    # Convertir la permission en droit du systÃ¨me de fichiers
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
    
    # CrÃ©er une nouvelle rÃ¨gle d'accÃ¨s
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Identity,
        $fileSystemRight,
        [System.Security.AccessControl.InheritanceFlags]::None,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    
    try {
        # Ajouter la nouvelle rÃ¨gle d'accÃ¨s
        $acl.AddAccessRule($accessRule)
        
        # Appliquer les nouvelles ACL
        if ($PSCmdlet.ShouldProcess($Path, "Modifier temporairement les permissions")) {
            Set-Acl -Path $Path -AclObject $acl
        }
        
        # ExÃ©cuter le bloc de code
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
        Active un privilÃ¨ge spÃ©cifique pour le processus actuel.
    
    .DESCRIPTION
        Cette fonction utilise l'API Windows pour activer un privilÃ¨ge spÃ©cifique pour le processus
        actuel, ce qui peut Ãªtre utile pour effectuer certaines opÃ©rations systÃ¨me.
    
    .PARAMETER Privilege
        Le privilÃ¨ge Ã  activer.
    
    .EXAMPLE
        Enable-Privilege -Privilege "SeBackupPrivilege"
    
    .OUTPUTS
        [bool] Indique si le privilÃ¨ge a Ã©tÃ© activÃ© avec succÃ¨s.
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
    
    # Ajouter les types nÃ©cessaires
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
            Write-Error "Ã‰chec de OpenProcessToken. Code d'erreur : $errorCode"
            return $false
        }
        
        # Rechercher la valeur du privilÃ¨ge
        $result = [PrivilegeHelper]::LookupPrivilegeValue($null, $Privilege, [ref]$luid)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Error "Ã‰chec de LookupPrivilegeValue. Code d'erreur : $errorCode"
            return $false
        }
        
        # PrÃ©parer la structure TOKEN_PRIVILEGES
        $tokenPrivileges = New-Object PrivilegeHelper+TOKEN_PRIVILEGES
        $tokenPrivileges.PrivilegeCount = 1
        $tokenPrivileges.Privileges.Luid = $luid
        $tokenPrivileges.Privileges.Attributes = $SE_PRIVILEGE_ENABLED
        
        # Ajuster les privilÃ¨ges du token
        $result = [PrivilegeHelper]::AdjustTokenPrivileges(
            $tokenHandle,
            $false,
            [ref]$tokenPrivileges,
            0,
            [IntPtr]::Zero,
            [IntPtr]::Zero)
        
        if (-not $result) {
            $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Error "Ã‰chec de AdjustTokenPrivileges. Code d'erreur : $errorCode"
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

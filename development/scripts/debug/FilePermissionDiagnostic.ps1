<#
.SYNOPSIS
    Outils de diagnostic des permissions de fichiers et dossiers.
.DESCRIPTION
    Ce script fournit des fonctions pour diagnostiquer les problÃ¨mes de permissions
    sur les fichiers et dossiers, en particulier pour les erreurs UnauthorizedAccessException.
.NOTES
    Auteur: Augment Code
    Date de crÃ©ation: 2023-11-15
#>

function Test-PathPermissions {
    <#
    .SYNOPSIS
        Analyse en dÃ©tail les permissions d'un fichier ou d'un dossier.

    .DESCRIPTION
        Cette fonction effectue une analyse complÃ¨te des permissions d'un fichier ou d'un dossier
        et fournit un rapport dÃ©taillÃ© sur les problÃ¨mes d'accÃ¨s potentiels. Elle vÃ©rifie les
        permissions de l'utilisateur actuel, les attributs du fichier, les ACL, et effectue des
        tests d'accÃ¨s rÃ©els.

    .PARAMETER Path
        Le chemin du fichier ou du dossier Ã  analyser.

    .PARAMETER TestWrite
        Indique si un test d'Ã©criture doit Ãªtre effectuÃ©.

    .PARAMETER TestRead
        Indique si un test de lecture doit Ãªtre effectuÃ©.

    .PARAMETER TestExecute
        Indique si un test d'exÃ©cution doit Ãªtre effectuÃ© (pour les fichiers exÃ©cutables).

    .PARAMETER Detailed
        Retourne un rapport dÃ©taillÃ© au lieu d'un simple rÃ©sultat boolÃ©en.

    .EXAMPLE
        Test-PathPermissions -Path "C:\Windows\System32\drivers\etc\hosts" -TestRead -TestWrite -Detailed

    .EXAMPLE
        Test-PathPermissions -Path "C:\Program Files" -TestRead -TestWrite -TestExecute -Detailed

    .OUTPUTS
        [PSCustomObject] ou [bool] selon le paramÃ¨tre Detailed
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter()]
        [switch]$TestWrite,

        [Parameter()]
        [switch]$TestRead,

        [Parameter()]
        [switch]$TestExecute,

        [Parameter()]
        [switch]$Detailed
    )

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        if ($Detailed) {
            return [PSCustomObject]@{
                Path = $Path
                Exists = $false
                IsContainer = $false
                IsReadOnly = $false
                IsHidden = $false
                IsSystem = $false
                Owner = $null
                CurrentUserAccess = $null
                ReadAccess = $false
                WriteAccess = $false
                ExecuteAccess = $false
                AllAccess = $false
                AccessControlEntries = @()
                Error = "Le chemin n'existe pas"
                TestResults = $null
            }
        }
        return $false
    }

    try {
        # RÃ©soudre le chemin complet
        $resolvedPath = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path

        # Obtenir les informations sur le fichier/dossier
        $item = Get-Item -Path $resolvedPath -Force
        $isContainer = $item -is [System.IO.DirectoryInfo]

        # Obtenir les attributs
        $isReadOnly = $false
        $isHidden = $false
        $isSystem = $false

        if (-not $isContainer) {
            $isReadOnly = $item.IsReadOnly
            $isHidden = ($item.Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden
            $isSystem = ($item.Attributes -band [System.IO.FileAttributes]::System) -eq [System.IO.FileAttributes]::System
        }

        # Obtenir les ACL
        $acl = Get-Acl -Path $resolvedPath
        $owner = $acl.Owner

        # Obtenir l'utilisateur actuel
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

        # VÃ©rifier si l'utilisateur est administrateur
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        # Analyser les ACE pour l'utilisateur actuel
        $currentUserAccess = @()
        $accessControlEntries = @()

        foreach ($ace in $acl.Access) {
            $aceInfo = [PSCustomObject]@{
                IdentityReference = $ace.IdentityReference.Value
                AccessControlType = $ace.AccessControlType.ToString()
                FileSystemRights = $ace.FileSystemRights.ToString()
                IsInherited = $ace.IsInherited
                InheritanceFlags = $ace.InheritanceFlags.ToString()
                PropagationFlags = $ace.PropagationFlags.ToString()
            }

            $accessControlEntries += $aceInfo

            # VÃ©rifier si cette ACE s'applique Ã  l'utilisateur actuel
            if ($ace.IdentityReference.Value -eq $currentUser -or
                $ace.IdentityReference.Value -eq "Everyone" -or
                $ace.IdentityReference.Value -eq "BUILTIN\Users" -or
                ($isAdmin -and $ace.IdentityReference.Value -eq "BUILTIN\Administrators")) {

                $currentUserAccess += $aceInfo
            }
        }

        # Effectuer des tests d'accÃ¨s rÃ©els
        $readAccess = $false
        $writeAccess = $false
        $executeAccess = $false
        $testResults = @{}

        if ($TestRead) {
            try {
                if ($isContainer) {
                    $null = Get-ChildItem -Path $resolvedPath -Force -ErrorAction Stop
                    $readAccess = $true
                    $testResults["ReadTest"] = "SuccÃ¨s: Lecture du contenu du dossier rÃ©ussie"
                } else {
                    $null = Get-Content -Path $resolvedPath -TotalCount 1 -ErrorAction Stop
                    $readAccess = $true
                    $testResults["ReadTest"] = "SuccÃ¨s: Lecture du contenu du fichier rÃ©ussie"
                }
            } catch {
                $readAccess = $false
                $testResults["ReadTest"] = "Ã‰chec: $($_.Exception.Message)"
            }
        }

        if ($TestWrite) {
            try {
                if ($isContainer) {
                    $testFile = Join-Path -Path $resolvedPath -ChildPath ([System.IO.Path]::GetRandomFileName())
                    $null = New-Item -Path $testFile -ItemType File -ErrorAction Stop
                    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
                    $writeAccess = $true
                    $testResults["WriteTest"] = "SuccÃ¨s: CrÃ©ation d'un fichier temporaire rÃ©ussie"
                } else {
                    # Sauvegarde du contenu original
                    $originalContent = Get-Content -Path $resolvedPath -Raw -ErrorAction Stop

                    # Test d'Ã©criture (ajout d'une ligne vide Ã  la fin)
                    Add-Content -Path $resolvedPath -Value "" -ErrorAction Stop

                    # Restauration du contenu original
                    Set-Content -Path $resolvedPath -Value $originalContent -ErrorAction Stop

                    $writeAccess = $true
                    $testResults["WriteTest"] = "SuccÃ¨s: Modification du fichier rÃ©ussie"
                }
            } catch {
                $writeAccess = $false
                $testResults["WriteTest"] = "Ã‰chec: $($_.Exception.Message)"
            }
        }

        if ($TestExecute -and -not $isContainer) {
            $executeAccess = $false
            $execExtensions = @(".exe", ".bat", ".cmd", ".ps1", ".vbs", ".js")

            if ($execExtensions -contains $item.Extension.ToLower()) {
                try {
                    # Pour les scripts PowerShell
                    if ($item.Extension.ToLower() -eq ".ps1") {
                        $scriptBlock = [ScriptBlock]::Create("& '$resolvedPath' -WhatIf")
                        $null = Invoke-Command -ScriptBlock $scriptBlock -ErrorAction Stop
                        $executeAccess = $true
                        $testResults["ExecuteTest"] = "SuccÃ¨s: ExÃ©cution du script PowerShell rÃ©ussie (mode WhatIf)"
                    }
                    # Pour les exÃ©cutables
                    elseif ($item.Extension.ToLower() -eq ".exe") {
                        $process = Start-Process -FilePath $resolvedPath -ArgumentList "/?" -WindowStyle Hidden -PassThru -ErrorAction Stop
                        $process.WaitForExit(1000) # Attendre 1 seconde
                        if (-not $process.HasExited) {
                            $process.Kill()
                        }
                        $executeAccess = $true
                        $testResults["ExecuteTest"] = "SuccÃ¨s: Lancement de l'exÃ©cutable rÃ©ussi"
                    }
                    # Pour les autres scripts
                    else {
                        $executeAccess = $true
                        $testResults["ExecuteTest"] = "SuccÃ¨s: Le fichier semble Ãªtre exÃ©cutable (non testÃ©)"
                    }
                } catch {
                    $executeAccess = $false
                    $testResults["ExecuteTest"] = "Ã‰chec: $($_.Exception.Message)"
                }
            } else {
                $testResults["ExecuteTest"] = "Non applicable: Le fichier n'est pas un type exÃ©cutable"
            }
        }

        # DÃ©terminer le rÃ©sultat global
        $allAccess = $true
        if ($TestRead -and -not $readAccess) { $allAccess = $false }
        if ($TestWrite -and -not $writeAccess) { $allAccess = $false }
        if ($TestExecute -and -not $executeAccess) { $allAccess = $false }

        # Retourner le rÃ©sultat
        if ($Detailed) {
            return [PSCustomObject]@{
                Path = $resolvedPath
                Exists = $true
                IsContainer = $isContainer
                IsReadOnly = $isReadOnly
                IsHidden = $isHidden
                IsSystem = $isSystem
                Owner = $owner
                CurrentUserAccess = $currentUserAccess
                ReadAccess = $readAccess
                WriteAccess = $writeAccess
                ExecuteAccess = $executeAccess
                AllAccess = $allAccess
                AccessControlEntries = $accessControlEntries
                Error = $null
                TestResults = $testResults
            }
        } else {
            return $allAccess
        }
    } catch {
        if ($Detailed) {
            return [PSCustomObject]@{
                Path = $Path
                Exists = $true
                IsContainer = $false
                IsReadOnly = $false
                IsHidden = $false
                IsSystem = $false
                Owner = $null
                CurrentUserAccess = $null
                ReadAccess = $false
                WriteAccess = $false
                ExecuteAccess = $false
                AllAccess = $false
                AccessControlEntries = @()
                Error = "Erreur lors de l'analyse des permissions: $($_.Exception.Message)"
                TestResults = $null
            }
        }
        return $false
    }
}

function Format-PathPermissionsReport {
    <#
    .SYNOPSIS
        Formate le rapport de permissions en un format lisible.

    .DESCRIPTION
        Cette fonction prend le rÃ©sultat de Test-PathPermissions et le formate
        en un rapport lisible avec des couleurs pour une meilleure lisibilitÃ©.

    .PARAMETER PermissionsResult
        Le rÃ©sultat de la fonction Test-PathPermissions.

    .EXAMPLE
        $result = Test-PathPermissions -Path "C:\Windows\System32\drivers\etc\hosts" -TestRead -TestWrite -Detailed
        Format-PathPermissionsReport -PermissionsResult $result

    .OUTPUTS
        Aucun. Affiche le rapport formatÃ© dans la console.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSCustomObject]$PermissionsResult
    )

    process {
        Write-Host "=== Rapport de permissions pour: $($PermissionsResult.Path) ===" -ForegroundColor Cyan

        if (-not $PermissionsResult.Exists) {
            Write-Host "ERREUR: Le chemin n'existe pas" -ForegroundColor Red
            return
        }

        if ($PermissionsResult.Error) {
            Write-Host "ERREUR: $($PermissionsResult.Error)" -ForegroundColor Red
            return
        }

        # Informations de base
        Write-Host "`nInformations de base:" -ForegroundColor Yellow
        Write-Host "  Type: $($PermissionsResult.IsContainer ? 'Dossier' : 'Fichier')"

        if (-not $PermissionsResult.IsContainer) {
            Write-Host "  Lecture seule: $($PermissionsResult.IsReadOnly ? 'Oui' : 'Non')"
            Write-Host "  CachÃ©: $($PermissionsResult.IsHidden ? 'Oui' : 'Non')"
            Write-Host "  SystÃ¨me: $($PermissionsResult.IsSystem ? 'Oui' : 'Non')"
        }

        Write-Host "  PropriÃ©taire: $($PermissionsResult.Owner)"

        # RÃ©sultats des tests
        Write-Host "`nRÃ©sultats des tests:" -ForegroundColor Yellow

        if ($PermissionsResult.TestResults.ContainsKey("ReadTest")) {
            $readColor = $PermissionsResult.ReadAccess ? 'Green' : 'Red'
            Write-Host "  Lecture: " -NoNewline
            Write-Host "$($PermissionsResult.TestResults.ReadTest)" -ForegroundColor $readColor
        }

        if ($PermissionsResult.TestResults.ContainsKey("WriteTest")) {
            $writeColor = $PermissionsResult.WriteAccess ? 'Green' : 'Red'
            Write-Host "  Ã‰criture: " -NoNewline
            Write-Host "$($PermissionsResult.TestResults.WriteTest)" -ForegroundColor $writeColor
        }

        if ($PermissionsResult.TestResults.ContainsKey("ExecuteTest")) {
            if ($PermissionsResult.TestResults.ExecuteTest -like "Non applicable*") {
                Write-Host "  ExÃ©cution: $($PermissionsResult.TestResults.ExecuteTest)" -ForegroundColor Gray
            } else {
                $execColor = $PermissionsResult.ExecuteAccess ? 'Green' : 'Red'
                Write-Host "  ExÃ©cution: " -NoNewline
                Write-Host "$($PermissionsResult.TestResults.ExecuteTest)" -ForegroundColor $execColor
            }
        }

        # AccÃ¨s de l'utilisateur actuel
        Write-Host "`nAccÃ¨s de l'utilisateur actuel:" -ForegroundColor Yellow

        if ($PermissionsResult.CurrentUserAccess.Count -eq 0) {
            Write-Host "  Aucun accÃ¨s explicite trouvÃ© pour l'utilisateur actuel" -ForegroundColor Red
        } else {
            foreach ($ace in $PermissionsResult.CurrentUserAccess) {
                $aceColor = $ace.AccessControlType -eq "Allow" ? 'Green' : 'Red'
                Write-Host "  $($ace.IdentityReference) ($($ace.AccessControlType)):" -ForegroundColor $aceColor
                Write-Host "    Droits: $($ace.FileSystemRights)"
                Write-Host "    HÃ©ritÃ©: $($ace.IsInherited ? 'Oui' : 'Non')"
                if (-not [string]::IsNullOrEmpty($ace.InheritanceFlags) -and $ace.InheritanceFlags -ne "None") {
                    Write-Host "    Flags d'hÃ©ritage: $($ace.InheritanceFlags)"
                }
                if (-not [string]::IsNullOrEmpty($ace.PropagationFlags) -and $ace.PropagationFlags -ne "None") {
                    Write-Host "    Flags de propagation: $($ace.PropagationFlags)"
                }
            }
        }

        # Toutes les entrÃ©es de contrÃ´le d'accÃ¨s
        Write-Host "`nToutes les entrÃ©es de contrÃ´le d'accÃ¨s:" -ForegroundColor Yellow

        foreach ($ace in $PermissionsResult.AccessControlEntries) {
            $aceColor = $ace.AccessControlType -eq "Allow" ? 'DarkGreen' : 'DarkRed'
            Write-Host "  $($ace.IdentityReference) ($($ace.AccessControlType)):" -ForegroundColor $aceColor
            Write-Host "    Droits: $($ace.FileSystemRights)"
            Write-Host "    HÃ©ritÃ©: $($ace.IsInherited ? 'Oui' : 'Non')"
        }

        # RÃ©sumÃ©
        Write-Host "`nRÃ©sumÃ©:" -ForegroundColor Yellow
        $allAccessColor = $PermissionsResult.AllAccess ? 'Green' : 'Red'
        Write-Host "  Tous les accÃ¨s demandÃ©s: " -NoNewline
        Write-Host "$($PermissionsResult.AllAccess ? 'Oui' : 'Non')" -ForegroundColor $allAccessColor

        # Recommandations
        Write-Host "`nRecommandations:" -ForegroundColor Yellow

        if (-not $PermissionsResult.AllAccess) {
            if (-not $PermissionsResult.ReadAccess -and $PermissionsResult.TestResults.ContainsKey("ReadTest")) {
                Write-Host "  - Pour obtenir l'accÃ¨s en lecture:" -ForegroundColor Cyan
                Write-Host "    * VÃ©rifiez que votre compte a les permissions de lecture sur ce chemin"
                Write-Host "    * Si nÃ©cessaire, exÃ©cutez PowerShell en tant qu'administrateur"
            }

            if (-not $PermissionsResult.WriteAccess -and $PermissionsResult.TestResults.ContainsKey("WriteTest")) {
                Write-Host "  - Pour obtenir l'accÃ¨s en Ã©criture:" -ForegroundColor Cyan

                if ($PermissionsResult.IsReadOnly) {
                    Write-Host "    * Le fichier est en lecture seule. Utilisez 'Set-ItemProperty -Path '$($PermissionsResult.Path)' -Name IsReadOnly -Value `$false'"
                }

                Write-Host "    * VÃ©rifiez que votre compte a les permissions d'Ã©criture sur ce chemin"
                Write-Host "    * Si nÃ©cessaire, exÃ©cutez PowerShell en tant qu'administrateur"
            }

            if (-not $PermissionsResult.ExecuteAccess -and $PermissionsResult.TestResults.ContainsKey("ExecuteTest") -and
                -not $PermissionsResult.TestResults.ExecuteTest.StartsWith("Non applicable")) {
                Write-Host "  - Pour obtenir l'accÃ¨s en exÃ©cution:" -ForegroundColor Cyan
                Write-Host "    * VÃ©rifiez que votre compte a les permissions d'exÃ©cution sur ce fichier"
                Write-Host "    * Si nÃ©cessaire, exÃ©cutez PowerShell en tant qu'administrateur"
                Write-Host "    * VÃ©rifiez les restrictions de la politique d'exÃ©cution PowerShell avec 'Get-ExecutionPolicy'"
            }
        } else {
            Write-Host "  Aucune recommandation nÃ©cessaire. Vous avez tous les accÃ¨s demandÃ©s." -ForegroundColor Green
        }
    }
}

function Get-UnauthorizedAccessDetails {
    <#
    .SYNOPSIS
        Analyse une exception UnauthorizedAccessException et fournit des dÃ©tails.

    .DESCRIPTION
        Cette fonction analyse une exception UnauthorizedAccessException et fournit
        des dÃ©tails sur la cause probable et les solutions possibles.

    .PARAMETER Exception
        L'exception UnauthorizedAccessException Ã  analyser.

    .PARAMETER Path
        Le chemin du fichier ou du dossier concernÃ© par l'exception.

    .EXAMPLE
        try {
            Get-Content -Path "C:\Windows\System32\config\SAM"
        } catch {
            Get-UnauthorizedAccessDetails -Exception $_.Exception -Path "C:\Windows\System32\config\SAM"
        }

    .OUTPUTS
        [PSCustomObject] avec des dÃ©tails sur l'exception
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Path = $null
    )

    # VÃ©rifier si c'est bien une UnauthorizedAccessException
    if (-not ($Exception -is [System.UnauthorizedAccessException])) {
        return [PSCustomObject]@{
            IsUnauthorizedAccess = $false
            Message = "L'exception n'est pas une UnauthorizedAccessException"
            HResult = $Exception.HResult
            ExceptionType = $Exception.GetType().FullName
            Path = $Path
            ProbableCause = "Exception de type incorrect"
            PossibleSolutions = @("VÃ©rifiez le type d'exception avant d'utiliser cette fonction")
        }
    }

    # Si le chemin n'est pas fourni, essayer de l'extraire du message d'erreur
    if (-not $Path) {
        if ($Exception.Message -match "'([^']+)'") {
            $Path = $matches[1]
        } elseif ($Exception.Message -match '"([^"]+)"') {
            $Path = $matches[1]
        }
    }

    # Analyser le code HResult
    $hResult = $Exception.HResult
    $hResultHex = "0x{0:X8}" -f $hResult

    # DÃ©terminer la cause probable
    $probableCause = "AccÃ¨s non autorisÃ©"
    $possibleSolutions = @()

    # Analyser le message d'erreur pour des indices supplÃ©mentaires
    if ($Exception.Message -match "denied|refusÃ©|accÃ¨s refusÃ©|access is denied" -or $hResult -eq -2147024891) { # 0x80070005
        $probableCause = "Permissions insuffisantes"
        $possibleSolutions = @(
            "VÃ©rifiez les permissions du fichier/dossier avec Test-PathPermissions",
            "ExÃ©cutez l'application avec des privilÃ¨ges Ã©levÃ©s",
            "Modifiez les permissions du fichier/dossier avec Set-Acl"
        )
    } elseif ($Exception.Message -match "read-only|lecture seule") {
        $probableCause = "Fichier en lecture seule"
        $possibleSolutions = @(
            "Retirez l'attribut de lecture seule avec Set-ItemProperty -Path '$Path' -Name IsReadOnly -Value `$false",
            "Copiez le fichier dans un emplacement oÃ¹ vous avez des droits d'Ã©criture"
        )
    } elseif ($Exception.Message -match "being used by another process|utilisÃ© par un autre processus") {
        $probableCause = "Fichier verrouillÃ© par un autre processus"
        $possibleSolutions = @(
            "Identifiez et fermez le processus qui utilise le fichier",
            "Utilisez la commande 'handle.exe' de Sysinternals pour identifier le processus",
            "Attendez que le fichier soit libÃ©rÃ© avant d'y accÃ©der"
        )
    } elseif ($Path -and $Path.StartsWith("HKEY_LOCAL_MACHINE") -or $Path.StartsWith("HKLM:")) {
        $probableCause = "AccÃ¨s non autorisÃ© au registre"
        $possibleSolutions = @(
            "ExÃ©cutez PowerShell en tant qu'administrateur",
            "VÃ©rifiez les permissions de la clÃ© de registre"
        )
    } elseif ($Path -and $Path.StartsWith("\\")) {
        $probableCause = "AccÃ¨s rÃ©seau non autorisÃ©"
        $possibleSolutions = @(
            "VÃ©rifiez les permissions rÃ©seau et les partages",
            "VÃ©rifiez les informations d'identification rÃ©seau",
            "Assurez-vous que le serveur distant est accessible"
        )
    }

    # CrÃ©er et retourner l'objet rÃ©sultat
    return [PSCustomObject]@{
        IsUnauthorizedAccess = $true
        Message = $Exception.Message
        HResult = $hResult
        HResultHex = $hResultHex
        ExceptionType = $Exception.GetType().FullName
        Path = $Path
        ProbableCause = $probableCause
        PossibleSolutions = $possibleSolutions
    }
}

function Debug-UnauthorizedAccessException {
    <#
    .SYNOPSIS
        Capture et analyse les erreurs d'accÃ¨s non autorisÃ©.

    .DESCRIPTION
        Cette fonction exÃ©cute un bloc de code et capture les erreurs UnauthorizedAccessException
        qui peuvent se produire. Elle analyse ensuite ces erreurs et fournit des informations
        dÃ©taillÃ©es sur la cause et les solutions possibles.

    .PARAMETER ScriptBlock
        Le bloc de code Ã  exÃ©cuter.

    .PARAMETER Path
        Le chemin du fichier ou du dossier concernÃ© (facultatif).

    .PARAMETER AnalyzePermissions
        Indique si les permissions du chemin doivent Ãªtre analysÃ©es en cas d'erreur.

    .EXAMPLE
        Debug-UnauthorizedAccessException -ScriptBlock { Get-Content -Path "C:\Windows\System32\config\SAM" }

    .EXAMPLE
        Debug-UnauthorizedAccessException -ScriptBlock { Set-Content -Path "C:\Windows\test.txt" -Value "Test" } -AnalyzePermissions

    .OUTPUTS
        [PSCustomObject] avec des dÃ©tails sur l'erreur et les solutions possibles
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Path = $null,

        [Parameter(Mandatory = $false)]
        [switch]$AnalyzePermissions
    )

    try {
        # ExÃ©cuter le bloc de code
        $result = & $ScriptBlock

        # Si aucune erreur ne s'est produite, retourner le rÃ©sultat
        return [PSCustomObject]@{
            Success = $true
            Result = $result
            Error = $null
            AccessDetails = $null
            PermissionsAnalysis = $null
        }
    } catch {
        $exception = $_.Exception

        # Si le chemin n'est pas spÃ©cifiÃ©, essayer de l'extraire du message d'erreur
        if (-not $Path) {
            if ($exception.Message -match "'([^']+)'") {
                $Path = $matches[1]
            } elseif ($exception.Message -match '"([^"]+)"') {
                $Path = $matches[1]
            }
        }

        # Analyser l'exception
        $accessDetails = $null
        if ($exception -is [System.UnauthorizedAccessException]) {
            $accessDetails = Get-UnauthorizedAccessDetails -Exception $exception -Path $Path
        } elseif ($exception.InnerException -is [System.UnauthorizedAccessException]) {
            $accessDetails = Get-UnauthorizedAccessDetails -Exception $exception.InnerException -Path $Path
        }

        # Analyser les permissions si demandÃ© et si un chemin est disponible
        $permissionsAnalysis = $null
        if ($AnalyzePermissions -and $Path -and (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            $permissionsAnalysis = Test-PathPermissions -Path $Path -TestRead -TestWrite -TestExecute -Detailed
        }

        # Retourner les dÃ©tails de l'erreur
        return [PSCustomObject]@{
            Success = $false
            Result = $null
            Error = $_
            AccessDetails = $accessDetails
            PermissionsAnalysis = $permissionsAnalysis
        }
    }
}

function Format-UnauthorizedAccessReport {
    <#
    .SYNOPSIS
        Formate le rapport d'une erreur d'accÃ¨s non autorisÃ©.

    .DESCRIPTION
        Cette fonction prend le rÃ©sultat de Debug-UnauthorizedAccessException et le formate
        en un rapport lisible avec des couleurs pour une meilleure lisibilitÃ©.

    .PARAMETER DebugResult
        Le rÃ©sultat de la fonction Debug-UnauthorizedAccessException.

    .EXAMPLE
        $result = Debug-UnauthorizedAccessException -ScriptBlock { Get-Content -Path "C:\Windows\System32\config\SAM" } -AnalyzePermissions
        Format-UnauthorizedAccessReport -DebugResult $result

    .OUTPUTS
        Aucun. Affiche le rapport formatÃ© dans la console.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSCustomObject]$DebugResult
    )

    process {
        if ($DebugResult.Success) {
            Write-Host "OpÃ©ration rÃ©ussie. Aucune erreur d'accÃ¨s dÃ©tectÃ©e." -ForegroundColor Green
            return
        }

        Write-Host "=== Rapport d'erreur d'accÃ¨s ===" -ForegroundColor Cyan

        # Afficher l'erreur
        Write-Host "`nErreur:" -ForegroundColor Red
        Write-Host "  $($DebugResult.Error.Exception.Message)"

        # Afficher le type d'exception
        Write-Host "`nType d'exception:" -ForegroundColor Yellow
        Write-Host "  $($DebugResult.Error.Exception.GetType().FullName)"

        # Afficher les dÃ©tails de l'accÃ¨s non autorisÃ©
        if ($DebugResult.AccessDetails) {
            Write-Host "`nDÃ©tails de l'accÃ¨s non autorisÃ©:" -ForegroundColor Yellow
            Write-Host "  Chemin: $($DebugResult.AccessDetails.Path)"
            Write-Host "  Code HResult: $($DebugResult.AccessDetails.HResultHex) ($($DebugResult.AccessDetails.HResult))"
            Write-Host "  Cause probable: $($DebugResult.AccessDetails.ProbableCause)"

            Write-Host "`nSolutions possibles:" -ForegroundColor Green
            foreach ($solution in $DebugResult.AccessDetails.PossibleSolutions) {
                Write-Host "  - $solution"
            }
        }

        # Afficher l'analyse des permissions
        if ($DebugResult.PermissionsAnalysis) {
            Write-Host "`nAnalyse des permissions:" -ForegroundColor Yellow
            Format-PathPermissionsReport -PermissionsResult $DebugResult.PermissionsAnalysis
        }

        # Afficher la stack trace
        if ($DebugResult.Error.ScriptStackTrace) {
            Write-Host "`nStack trace:" -ForegroundColor Gray
            $stackLines = $DebugResult.Error.ScriptStackTrace -split "`n"
            foreach ($line in $stackLines) {
                Write-Host "  $line" -ForegroundColor Gray
            }
        }
    }
}

function Test-AccessRequirements {
    <#
    .SYNOPSIS
        VÃ©rifie si les permissions nÃ©cessaires sont disponibles avant d'effectuer une opÃ©ration.

    .DESCRIPTION
        Cette fonction vÃ©rifie si les permissions nÃ©cessaires sont disponibles pour un chemin donnÃ©
        avant d'effectuer une opÃ©ration, Ã©vitant ainsi les erreurs UnauthorizedAccessException.
        Si les permissions ne sont pas disponibles, la fonction peut suggÃ©rer des solutions.

    .PARAMETER Path
        Le chemin du fichier ou du dossier Ã  vÃ©rifier.

    .PARAMETER RequiredAccess
        Les types d'accÃ¨s requis (Read, Write, Execute, Delete, FullControl).

    .PARAMETER SuggestSolutions
        Indique si des solutions doivent Ãªtre suggÃ©rÃ©es en cas de permissions insuffisantes.

    .PARAMETER Quiet
        Indique si les messages d'erreur doivent Ãªtre supprimÃ©s.

    .EXAMPLE
        Test-AccessRequirements -Path "C:\Windows\System32\drivers\etc\hosts" -RequiredAccess "Read", "Write"

    .EXAMPLE
        Test-AccessRequirements -Path "C:\Program Files" -RequiredAccess "Write" -SuggestSolutions

    .OUTPUTS
        [PSCustomObject] avec des dÃ©tails sur les permissions disponibles
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Read", "Write", "Execute", "Delete", "FullControl")]
        [string[]]$RequiredAccess,

        [Parameter(Mandatory = $false)]
        [switch]$SuggestSolutions,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
        if (-not $Quiet) {
            Write-Warning "Le chemin '$Path' n'existe pas."
        }

        return [PSCustomObject]@{
            Path = $Path
            Exists = $false
            AccessGranted = $false
            MissingAccess = $RequiredAccess
            AvailableAccess = @()
            Suggestions = @(
                "VÃ©rifiez que le chemin existe",
                "VÃ©rifiez l'orthographe du chemin",
                "VÃ©rifiez que vous avez accÃ¨s au rÃ©pertoire parent"
            )
        }
    }

    # Convertir les types d'accÃ¨s requis en droits du systÃ¨me de fichiers
    $requiredRights = @()
    foreach ($access in $RequiredAccess) {
        switch ($access) {
            "Read" { $requiredRights += [System.Security.AccessControl.FileSystemRights]::Read }
            "Write" { $requiredRights += [System.Security.AccessControl.FileSystemRights]::Write }
            "Execute" { $requiredRights += [System.Security.AccessControl.FileSystemRights]::ExecuteFile }
            "Delete" { $requiredRights += [System.Security.AccessControl.FileSystemRights]::Delete }
            "FullControl" { $requiredRights += [System.Security.AccessControl.FileSystemRights]::FullControl }
        }
    }

    # Obtenir les informations sur le fichier/dossier
    $item = Get-Item -Path $Path -Force
    $isContainer = $item -is [System.IO.DirectoryInfo]

    # VÃ©rifier les attributs
    $isReadOnly = $false
    if (-not $isContainer) {
        $isReadOnly = $item.IsReadOnly
    }

    # Obtenir les ACL
    try {
        $acl = Get-Acl -Path $Path -ErrorAction Stop
    } catch {
        if (-not $Quiet) {
            Write-Warning "Impossible d'obtenir les ACL pour le chemin '$Path': $($_.Exception.Message)"
        }

        return [PSCustomObject]@{
            Path = $Path
            Exists = $true
            AccessGranted = $false
            MissingAccess = $RequiredAccess
            AvailableAccess = @()
            Suggestions = @(
                "ExÃ©cutez le script avec des privilÃ¨ges Ã©levÃ©s",
                "VÃ©rifiez que vous avez accÃ¨s au chemin"
            )
        }
    }

    # Obtenir l'utilisateur actuel
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # VÃ©rifier les permissions
    $accessGranted = $true
    $missingAccess = @()
    $availableAccess = @()

    foreach ($right in $requiredRights) {
        $hasAccess = $false

        # VÃ©rifier si l'utilisateur a les droits requis
        foreach ($ace in $acl.Access) {
            if (($ace.IdentityReference.Value -eq $currentUser -or
                 $ace.IdentityReference.Value -eq "Everyone" -or
                 $ace.IdentityReference.Value -eq "BUILTIN\Users" -or
                 ($isAdmin -and $ace.IdentityReference.Value -eq "BUILTIN\Administrators")) -and
                $ace.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow) {

                if (($ace.FileSystemRights -band $right) -eq $right) {
                    $hasAccess = $true
                    break
                }
            }
        }

        # Cas spÃ©cial pour les fichiers en lecture seule
        if ($right -eq [System.Security.AccessControl.FileSystemRights]::Write -and $isReadOnly) {
            $hasAccess = $false
        }

        if ($hasAccess) {
            $accessType = switch ($right) {
                ([System.Security.AccessControl.FileSystemRights]::Read) { "Read" }
                ([System.Security.AccessControl.FileSystemRights]::Write) { "Write" }
                ([System.Security.AccessControl.FileSystemRights]::ExecuteFile) { "Execute" }
                ([System.Security.AccessControl.FileSystemRights]::Delete) { "Delete" }
                ([System.Security.AccessControl.FileSystemRights]::FullControl) { "FullControl" }
                default { $right.ToString() }
            }
            $availableAccess += $accessType
        } else {
            $accessType = switch ($right) {
                ([System.Security.AccessControl.FileSystemRights]::Read) { "Read" }
                ([System.Security.AccessControl.FileSystemRights]::Write) { "Write" }
                ([System.Security.AccessControl.FileSystemRights]::ExecuteFile) { "Execute" }
                ([System.Security.AccessControl.FileSystemRights]::Delete) { "Delete" }
                ([System.Security.AccessControl.FileSystemRights]::FullControl) { "FullControl" }
                default { $right.ToString() }
            }
            $missingAccess += $accessType
            $accessGranted = $false
        }
    }

    # GÃ©nÃ©rer des suggestions si demandÃ©
    $suggestions = @()
    if (-not $accessGranted -and $SuggestSolutions) {
        if ($missingAccess -contains "Write" -and $isReadOnly) {
            $suggestions += "Le fichier est en lecture seule. Utilisez 'Set-ItemProperty -Path '$Path' -Name IsReadOnly -Value `$false'"
        }

        if (-not $isAdmin) {
            $suggestions += "ExÃ©cutez le script avec des privilÃ¨ges administratifs"
        }

        $suggestions += "Modifiez les permissions du fichier/dossier avec Set-Acl"
        $suggestions += "Utilisez une copie du fichier dans un emplacement oÃ¹ vous avez les permissions nÃ©cessaires"

        if ($isContainer) {
            $suggestions += "CrÃ©ez un nouveau dossier avec les permissions appropriÃ©es et copiez-y les fichiers"
        }
    }

    # Afficher un avertissement si les permissions sont insuffisantes
    if (-not $accessGranted -and -not $Quiet) {
        Write-Warning "Permissions insuffisantes pour le chemin '$Path'. AccÃ¨s manquants: $($missingAccess -join ', ')"

        if ($SuggestSolutions -and $suggestions.Count -gt 0) {
            Write-Host "Suggestions:" -ForegroundColor Yellow
            foreach ($suggestion in $suggestions) {
                Write-Host "  - $suggestion" -ForegroundColor Cyan
            }
        }
    }

    # Retourner le rÃ©sultat
    return [PSCustomObject]@{
        Path = $Path
        Exists = $true
        AccessGranted = $accessGranted
        MissingAccess = $missingAccess
        AvailableAccess = $availableAccess
        Suggestions = $suggestions
    }
}

function Invoke-WithAccessCheck {
    <#
    .SYNOPSIS
        ExÃ©cute un bloc de code uniquement si les permissions nÃ©cessaires sont disponibles.

    .DESCRIPTION
        Cette fonction vÃ©rifie si les permissions nÃ©cessaires sont disponibles pour un chemin donnÃ©
        avant d'exÃ©cuter un bloc de code, Ã©vitant ainsi les erreurs UnauthorizedAccessException.

    .PARAMETER Path
        Le chemin du fichier ou du dossier Ã  vÃ©rifier.

    .PARAMETER RequiredAccess
        Les types d'accÃ¨s requis (Read, Write, Execute, Delete, FullControl).

    .PARAMETER ScriptBlock
        Le bloc de code Ã  exÃ©cuter si les permissions sont disponibles.

    .PARAMETER OnFailure
        Le bloc de code Ã  exÃ©cuter si les permissions ne sont pas disponibles.

    .PARAMETER SuggestSolutions
        Indique si des solutions doivent Ãªtre suggÃ©rÃ©es en cas de permissions insuffisantes.

    .EXAMPLE
        Invoke-WithAccessCheck -Path "C:\Windows\System32\drivers\etc\hosts" -RequiredAccess "Read", "Write" -ScriptBlock {
            Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "# Nouvelle entrÃ©e"
        } -OnFailure {
            Write-Host "Impossible de modifier le fichier hosts" -ForegroundColor Red
        }

    .OUTPUTS
        Le rÃ©sultat du bloc de code si les permissions sont disponibles, sinon le rÃ©sultat du bloc OnFailure.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Read", "Write", "Execute", "Delete", "FullControl")]
        [string[]]$RequiredAccess,

        [Parameter(Mandatory = $true, Position = 2)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [scriptblock]$OnFailure = {
            Write-Warning "Permissions insuffisantes pour le chemin '$Path'. OpÃ©ration annulÃ©e."
        },

        [Parameter(Mandatory = $false)]
        [switch]$SuggestSolutions
    )

    # VÃ©rifier les permissions
    $accessCheck = Test-AccessRequirements -Path $Path -RequiredAccess $RequiredAccess -SuggestSolutions:$SuggestSolutions -Quiet

    if ($accessCheck.AccessGranted) {
        # ExÃ©cuter le bloc de code
        return & $ScriptBlock
    } else {
        # ExÃ©cuter le bloc OnFailure
        return & $OnFailure
    }
}

function Format-AccessRequirementsReport {
    <#
    .SYNOPSIS
        Formate le rapport de vÃ©rification des permissions en un format lisible.

    .DESCRIPTION
        Cette fonction prend le rÃ©sultat de Test-AccessRequirements et le formate
        en un rapport lisible avec des couleurs pour une meilleure lisibilitÃ©.

    .PARAMETER AccessCheck
        Le rÃ©sultat de la fonction Test-AccessRequirements.

    .EXAMPLE
        $result = Test-AccessRequirements -Path "C:\Windows\System32\drivers\etc\hosts" -RequiredAccess "Read", "Write" -SuggestSolutions
        Format-AccessRequirementsReport -AccessCheck $result

    .OUTPUTS
        Aucun. Affiche le rapport formatÃ© dans la console.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSCustomObject]$AccessCheck
    )

    process {
        Write-Host "=== Rapport de vÃ©rification des permissions ===" -ForegroundColor Cyan
        Write-Host "Chemin: $($AccessCheck.Path)" -ForegroundColor White

        if (-not $AccessCheck.Exists) {
            Write-Host "Le chemin n'existe pas" -ForegroundColor Red

            if ($AccessCheck.Suggestions.Count -gt 0) {
                Write-Host "`nSuggestions:" -ForegroundColor Yellow
                foreach ($suggestion in $AccessCheck.Suggestions) {
                    Write-Host "  - $suggestion" -ForegroundColor Cyan
                }
            }

            return
        }

        # Afficher le statut global
        $statusColor = $AccessCheck.AccessGranted ? 'Green' : 'Red'
        Write-Host "Statut: " -NoNewline
        Write-Host "$($AccessCheck.AccessGranted ? 'AccÃ¨s autorisÃ©' : 'AccÃ¨s refusÃ©')" -ForegroundColor $statusColor

        # Afficher les accÃ¨s disponibles
        if ($AccessCheck.AvailableAccess.Count -gt 0) {
            Write-Host "`nAccÃ¨s disponibles:" -ForegroundColor Green
            foreach ($access in $AccessCheck.AvailableAccess) {
                Write-Host "  - $access" -ForegroundColor Green
            }
        }

        # Afficher les accÃ¨s manquants
        if ($AccessCheck.MissingAccess.Count -gt 0) {
            Write-Host "`nAccÃ¨s manquants:" -ForegroundColor Red
            foreach ($access in $AccessCheck.MissingAccess) {
                Write-Host "  - $access" -ForegroundColor Red
            }
        }

        # Afficher les suggestions
        if ($AccessCheck.Suggestions.Count -gt 0) {
            Write-Host "`nSuggestions:" -ForegroundColor Yellow
            foreach ($suggestion in $AccessCheck.Suggestions) {
                Write-Host "  - $suggestion" -ForegroundColor Cyan
            }
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Test-PathPermissions, Format-PathPermissionsReport, Get-UnauthorizedAccessDetails, Debug-UnauthorizedAccessException, Format-UnauthorizedAccessReport, Test-AccessRequirements, Invoke-WithAccessCheck, Format-AccessRequirementsReport

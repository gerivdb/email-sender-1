<#
.SYNOPSIS
    DÃ©tecte automatiquement l'environnement d'exÃ©cution et ses caractÃ©ristiques.

.DESCRIPTION
    Ce script dÃ©tecte l'environnement d'exÃ©cution (systÃ¨me d'exploitation, version de PowerShell,
    architecture, etc.) et fournit des informations sur les capacitÃ©s et limitations de l'environnement.
    Il peut Ãªtre utilisÃ© pour adapter le comportement des scripts en fonction de l'environnement.

.EXAMPLE
    . .\EnvironmentDetector.ps1
    $env = Get-EnvironmentInfo
    if ($env.IsWindows) {
        # Code spÃ©cifique Ã  Windows
    }
    else {
        # Code pour d'autres systÃ¨mes
    }

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0

<#
.SYNOPSIS
    DÃ©tecte automatiquement l'environnement d'exÃ©cution et ses caractÃ©ristiques.

.DESCRIPTION
    Ce script dÃ©tecte l'environnement d'exÃ©cution (systÃ¨me d'exploitation, version de PowerShell,
    architecture, etc.) et fournit des informations sur les capacitÃ©s et limitations de l'environnement.
    Il peut Ãªtre utilisÃ© pour adapter le comportement des scripts en fonction de l'environnement.

.EXAMPLE
    . .\EnvironmentDetector.ps1
    $env = Get-EnvironmentInfo
    if ($env.IsWindows) {
        # Code spÃ©cifique Ã  Windows
    }
    else {
        # Code pour d'autres systÃ¨mes
    }

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Fonction pour obtenir des informations dÃ©taillÃ©es sur l'environnement
function Get-EnvironmentInfo {
    [CmdletBinding()]
    param ()

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
    # CrÃ©er l'objet d'informations sur l'environnement
    $envInfo = [PSCustomObject]@{
        # Informations sur le systÃ¨me d'exploitation
        OSVersion = [System.Environment]::OSVersion
        OSPlatform = [System.Environment]::OSVersion.Platform
        OSDescription = if ($PSVersionTable.PSVersion.Major -ge 6) { [System.Runtime.InteropServices.RuntimeInformation]::OSDescription } else { "" }
        IsWindows = $false
        IsLinux = $false
        IsMacOS = $false
        IsUnix = $false
        Is64Bit = [System.Environment]::Is64BitOperatingSystem
        Is64BitProcess = [System.Environment]::Is64BitProcess
        
        # Informations sur PowerShell
        PSVersion = $PSVersionTable.PSVersion
        PSEdition = $PSVersionTable.PSEdition
        PSCompatibleVersions = $PSVersionTable.PSCompatibleVersions
        PSRemotingProtocolVersion = $PSVersionTable.PSRemotingProtocolVersion
        IsCoreCLR = $false
        IsDesktopCLR = $false
        IsWindowsPowerShell = $false
        IsPowerShellCore = $false
        
        # Informations sur l'hÃ´te
        PSHost = $Host.Name
        PSHostVersion = $Host.Version
        PSHostUI = $Host.UI.GetType().Name
        IsConsoleHost = $Host.Name -eq "ConsoleHost"
        IsISE = $Host.Name -eq "Windows PowerShell ISE Host"
        IsVSCode = $Host.Name -match "Visual Studio Code"
        
        # Informations sur l'environnement d'exÃ©cution
        CurrentDirectory = (Get-Location).Path
        TempDirectory = [System.IO.Path]::GetTempPath()
        UserName = [System.Environment]::UserName
        MachineName = [System.Environment]::MachineName
        UserDomainName = [System.Environment]::UserDomainName
        ProcessId = [System.Diagnostics.Process]::GetCurrentProcess().Id
        ProcessName = [System.Diagnostics.Process]::GetCurrentProcess().ProcessName
        CurrentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture.Name
        CurrentUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture.Name
        
        # CapacitÃ©s et limitations
        SupportsUnicode = $true
        SupportsANSI = $false
        SupportsVT100 = $false
        MaxPathLength = 260
        PathSeparator = [System.IO.Path]::DirectorySeparatorChar
        AltPathSeparator = [System.IO.Path]::AltDirectorySeparatorChar
        NewLine = [System.Environment]::NewLine
        
        # Informations sur les modules et cmdlets disponibles
        AvailableModules = @()
        CoreCmdletsAvailable = $false
        LegacyCmdletsAvailable = $false
    }
    
    # DÃ©terminer le type de systÃ¨me d'exploitation
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core a des variables intÃ©grÃ©es pour le systÃ¨me d'exploitation
        $envInfo.IsWindows = $IsWindows
        $envInfo.IsLinux = $IsLinux
        $envInfo.IsMacOS = $IsMacOS
        $envInfo.IsUnix = $IsLinux -or $IsMacOS
    }
    else {
        # Windows PowerShell s'exÃ©cute uniquement sur Windows
        $envInfo.IsWindows = $true
        $envInfo.IsLinux = $false
        $envInfo.IsMacOS = $false
        $envInfo.IsUnix = $false
    }
    
    # DÃ©terminer le type de runtime PowerShell
    $envInfo.IsCoreCLR = $PSVersionTable.PSVersion.Major -ge 6
    $envInfo.IsDesktopCLR = -not $envInfo.IsCoreCLR
    $envInfo.IsWindowsPowerShell = $PSVersionTable.PSVersion.Major -le 5
    $envInfo.IsPowerShellCore = $PSVersionTable.PSVersion.Major -ge 6
    
    # DÃ©terminer les capacitÃ©s du terminal
    if ($envInfo.IsWindows) {
        # VÃ©rifier si le terminal Windows prend en charge ANSI/VT100
        $envInfo.SupportsANSI = $Host.UI.SupportsVirtualTerminal -or 
                               ($env:TERM -ne $null) -or 
                               ($env:ConEmuANSI -eq "ON") -or 
                               ($env:ANSICON -ne $null)
        
        $envInfo.SupportsVT100 = $envInfo.SupportsANSI
        
        # DÃ©finir la longueur maximale du chemin
        if ($PSVersionTable.PSVersion.Major -ge 5 -and $PSVersionTable.PSVersion.Minor -ge 1) {
            # PowerShell 5.1+ peut gÃ©rer des chemins plus longs si la fonctionnalitÃ© est activÃ©e
            $envInfo.MaxPathLength = 32767
        }
        else {
            $envInfo.MaxPathLength = 260
        }
    }
    else {
        # Les systÃ¨mes Unix prennent gÃ©nÃ©ralement en charge ANSI/VT100
        $envInfo.SupportsANSI = $true
        $envInfo.SupportsVT100 = $true
        
        # Les systÃ¨mes Unix ont gÃ©nÃ©ralement une limite de chemin beaucoup plus Ã©levÃ©e
        $envInfo.MaxPathLength = 4096
    }
    
    # Obtenir la liste des modules disponibles
    $envInfo.AvailableModules = Get-Module -ListAvailable | Select-Object -ExpandProperty Name
    
    # VÃ©rifier la disponibilitÃ© des cmdlets de base
    $envInfo.CoreCmdletsAvailable = (Get-Command -Name "Get-ChildItem" -ErrorAction SilentlyContinue) -ne $null
    $envInfo.LegacyCmdletsAvailable = (Get-Command -Name "Get-WmiObject" -ErrorAction SilentlyContinue) -ne $null
    
    return $envInfo
}

# Fonction pour vÃ©rifier la compatibilitÃ© avec un environnement cible
function Test-EnvironmentCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Windows", "Linux", "MacOS", "Any")]
        [string]$TargetOS = "Any",
        
        [Parameter(Mandatory = $false)]
        [version]$MinimumPSVersion = "3.0",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Desktop", "Core", "Any")]
        [string]$PSEdition = "Any",
        
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredModules = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredCommands = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Require64Bit,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireElevatedPrivileges,
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnIncompatible
    )
    
    # Obtenir les informations sur l'environnement actuel
    $envInfo = Get-EnvironmentInfo
    
    # VÃ©rifier la compatibilitÃ© du systÃ¨me d'exploitation
    $osCompatible = switch ($TargetOS) {
        "Windows" { $envInfo.IsWindows }
        "Linux" { $envInfo.IsLinux }
        "MacOS" { $envInfo.IsMacOS }
        "Any" { $true }
        default { $true }
    }
    
    # VÃ©rifier la compatibilitÃ© de la version PowerShell
    $psVersionCompatible = $envInfo.PSVersion -ge $MinimumPSVersion
    
    # VÃ©rifier la compatibilitÃ© de l'Ã©dition PowerShell
    $psEditionCompatible = switch ($PSEdition) {
        "Desktop" { $envInfo.IsDesktopCLR }
        "Core" { $envInfo.IsCoreCLR }
        "Any" { $true }
        default { $true }
    }
    
    # VÃ©rifier la disponibilitÃ© des modules requis
    $modulesCompatible = $true
    foreach ($module in $RequiredModules) {
        if ($envInfo.AvailableModules -notcontains $module) {
            $modulesCompatible = $false
            break
        }
    }
    
    # VÃ©rifier la disponibilitÃ© des commandes requises
    $commandsCompatible = $true
    foreach ($command in $RequiredCommands) {
        if ((Get-Command -Name $command -ErrorAction SilentlyContinue) -eq $null) {
            $commandsCompatible = $false
            break
        }
    }
    
    # VÃ©rifier la compatibilitÃ© de l'architecture
    $architectureCompatible = -not $Require64Bit -or $envInfo.Is64BitProcess
    
    # VÃ©rifier les privilÃ¨ges Ã©levÃ©s
    $privilegesCompatible = -not $RequireElevatedPrivileges -or (
        # VÃ©rifier les privilÃ¨ges Ã©levÃ©s en fonction du systÃ¨me d'exploitation
        if ($envInfo.IsWindows) {
            # VÃ©rifier si l'utilisateur est administrateur sous Windows
            $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
            $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        else {
            # VÃ©rifier si l'utilisateur est root sous Unix
            $envInfo.UserName -eq "root" -or (id -u) -eq 0
        }
    )
    
    # DÃ©terminer la compatibilitÃ© globale
    $isCompatible = $osCompatible -and $psVersionCompatible -and $psEditionCompatible -and $modulesCompatible -and $commandsCompatible -and $architectureCompatible -and $privilegesCompatible
    
    # CrÃ©er l'objet de rÃ©sultat
    $result = [PSCustomObject]@{
        IsCompatible = $isCompatible
        OSCompatible = $osCompatible
        PSVersionCompatible = $psVersionCompatible
        PSEditionCompatible = $psEditionCompatible
        ModulesCompatible = $modulesCompatible
        CommandsCompatible = $commandsCompatible
        ArchitectureCompatible = $architectureCompatible
        PrivilegesCompatible = $privilegesCompatible
        Environment = $envInfo
        IncompatibilityReasons = @()
    }
    
    # Ajouter les raisons d'incompatibilitÃ©
    if (-not $osCompatible) {
        $result.IncompatibilityReasons += "Le systÃ¨me d'exploitation actuel ($($envInfo.OSDescription)) n'est pas compatible avec la cible ($TargetOS)."
    }
    
    if (-not $psVersionCompatible) {
        $result.IncompatibilityReasons += "La version PowerShell actuelle ($($envInfo.PSVersion)) est infÃ©rieure Ã  la version minimale requise ($MinimumPSVersion)."
    }
    
    if (-not $psEditionCompatible) {
        $result.IncompatibilityReasons += "L'Ã©dition PowerShell actuelle ($($envInfo.PSEdition)) n'est pas compatible avec l'Ã©dition requise ($PSEdition)."
    }
    
    if (-not $modulesCompatible) {
        $missingModules = $RequiredModules | Where-Object { $envInfo.AvailableModules -notcontains $_ }
        $result.IncompatibilityReasons += "Modules manquants: $($missingModules -join ", ")."
    }
    
    if (-not $commandsCompatible) {
        $missingCommands = $RequiredCommands | Where-Object { (Get-Command -Name $_ -ErrorAction SilentlyContinue) -eq $null }
        $result.IncompatibilityReasons += "Commandes manquantes: $($missingCommands -join ", ")."
    }
    
    if (-not $architectureCompatible) {
        $result.IncompatibilityReasons += "L'architecture actuelle ($(if ($envInfo.Is64BitProcess) { "64-bit" } else { "32-bit" })) n'est pas compatible avec l'architecture requise (64-bit)."
    }
    
    if (-not $privilegesCompatible) {
        $result.IncompatibilityReasons += "Les privilÃ¨ges actuels ne sont pas suffisants. Des privilÃ¨ges Ã©levÃ©s sont requis."
    }
    
    # Lever une exception si demandÃ© et incompatible
    if (-not $isCompatible -and $ThrowOnIncompatible) {
        throw "Environnement incompatible: $($result.IncompatibilityReasons -join " ")"
    }
    
    return $result
}

# Fonction pour obtenir des recommandations d'adaptation Ã  l'environnement
function Get-EnvironmentAdaptationRecommendations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$EnvironmentInfo = $null,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Windows", "Linux", "MacOS", "Any")]
        [string]$TargetOS = "Any",
        
        [Parameter(Mandatory = $false)]
        [version]$MinimumPSVersion = "3.0",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Desktop", "Core", "Any")]
        [string]$PSEdition = "Any"
    )
    
    # Obtenir les informations sur l'environnement si non fournies
    if ($null -eq $EnvironmentInfo) {
        $EnvironmentInfo = Get-EnvironmentInfo
    }
    
    # CrÃ©er l'objet de recommandations
    $recommendations = [PSCustomObject]@{
        PathHandling = @()
        CommandSubstitutions = @()
        EncodingRecommendations = @()
        FeatureAdaptations = @()
        GeneralRecommendations = @()
    }
    
    # Recommandations pour la gestion des chemins
    if ($EnvironmentInfo.IsWindows) {
        $recommendations.PathHandling += "Utiliser [System.IO.Path]::Combine() pour construire des chemins compatibles."
        $recommendations.PathHandling += "Ã‰viter les chemins codÃ©s en dur avec des barres obliques inversÃ©es (\)."
        $recommendations.PathHandling += "Utiliser Join-Path pour construire des chemins de maniÃ¨re compatible."
        
        if ($EnvironmentInfo.MaxPathLength -le 260) {
            $recommendations.PathHandling += "Attention aux limitations de longueur de chemin (MAX_PATH = 260). Envisager d'activer le support des chemins longs."
        }
    }
    else {
        $recommendations.PathHandling += "Utiliser des barres obliques (/) pour les chemins sur les systÃ¨mes Unix."
        $recommendations.PathHandling += "Les chemins sont sensibles Ã  la casse sur les systÃ¨mes Unix."
        $recommendations.PathHandling += "Utiliser [System.IO.Path]::Combine() ou Join-Path pour construire des chemins compatibles."
    }
    
    # Recommandations pour les substitutions de commandes
    if ($EnvironmentInfo.IsWindowsPowerShell) {
        $recommendations.CommandSubstitutions += "Utiliser Get-WmiObject pour les requÃªtes WMI."
        $recommendations.CommandSubstitutions += "Utiliser les applets de commande *-Computer* pour la gestion du systÃ¨me."
    }
    elseif ($EnvironmentInfo.IsPowerShellCore) {
        $recommendations.CommandSubstitutions += "Utiliser Get-CimInstance au lieu de Get-WmiObject."
        
        if ($EnvironmentInfo.IsWindows) {
            $recommendations.CommandSubstitutions += "Certaines applets de commande Windows peuvent ne pas Ãªtre disponibles. VÃ©rifier la disponibilitÃ©."
        }
        else {
            $recommendations.CommandSubstitutions += "Les applets de commande spÃ©cifiques Ã  Windows ne sont pas disponibles. Utiliser des alternatives natives."
        }
    }
    
    # Recommandations pour l'encodage
    if ($EnvironmentInfo.IsWindows) {
        $recommendations.EncodingRecommendations += "Utiliser UTF-8 avec BOM pour les scripts PowerShell."
        $recommendations.EncodingRecommendations += "SpÃ©cifier explicitement l'encodage dans les applets de commande de fichier (Get-Content, Set-Content, etc.)."
    }
    else {
        $recommendations.EncodingRecommendations += "Utiliser UTF-8 sans BOM pour une meilleure compatibilitÃ© avec les outils Unix."
        $recommendations.EncodingRecommendations += "Ã‰viter les caractÃ¨res spÃ©cifiques Ã  Windows (CRLF, etc.)."
    }
    
    # Recommandations pour l'adaptation des fonctionnalitÃ©s
    if ($EnvironmentInfo.PSVersion -lt [version]"5.1") {
        $recommendations.FeatureAdaptations += "Ã‰viter les fonctionnalitÃ©s PowerShell 5.1+ comme les classes, les Ã©numÃ©rations, etc."
    }
    
    if ($EnvironmentInfo.PSVersion -lt [version]"6.0") {
        $recommendations.FeatureAdaptations += "Ã‰viter les fonctionnalitÃ©s PowerShell 6.0+ comme les opÃ©rateurs ternaires, etc."
    }
    
    if (-not $EnvironmentInfo.SupportsANSI) {
        $recommendations.FeatureAdaptations += "Ã‰viter les sÃ©quences d'Ã©chappement ANSI pour la coloration du texte."
    }
    
    # Recommandations gÃ©nÃ©rales
    $recommendations.GeneralRecommendations += "Utiliser Test-Path avant d'accÃ©der aux fichiers et rÃ©pertoires."
    $recommendations.GeneralRecommendations += "GÃ©rer les exceptions de maniÃ¨re appropriÃ©e avec try/catch."
    $recommendations.GeneralRecommendations += "Utiliser des chemins relatifs plutÃ´t que des chemins absolus lorsque c'est possible."
    
    if ($EnvironmentInfo.IsWindows -and $TargetOS -ne "Windows") {
        $recommendations.GeneralRecommendations += "Ã‰viter les appels Ã  des exÃ©cutables Windows spÃ©cifiques (.exe, .bat, etc.)."
    }
    
    if ($EnvironmentInfo.IsUnix -and $TargetOS -ne "Any" -and $TargetOS -ne "Linux" -and $TargetOS -ne "MacOS") {
        $recommendations.GeneralRecommendations += "Ã‰viter les appels Ã  des commandes Unix spÃ©cifiques qui ne sont pas disponibles sur Windows."
    }
    
    return $recommendations
}

# Exporter les fonctions
Export-ModuleMember -Function Get-EnvironmentInfo, Test-EnvironmentCompatibility, Get-EnvironmentAdaptationRecommendations

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}

<#
.SYNOPSIS
    Détecte automatiquement l'environnement d'exécution et ses caractéristiques.

.DESCRIPTION
    Ce script détecte l'environnement d'exécution (système d'exploitation, version de PowerShell,
    architecture, etc.) et fournit des informations sur les capacités et limitations de l'environnement.
    Il peut être utilisé pour adapter le comportement des scripts en fonction de l'environnement.

.EXAMPLE
    . .\EnvironmentDetector.ps1
    $env = Get-EnvironmentInfo
    if ($env.IsWindows) {
        # Code spécifique à Windows
    }
    else {
        # Code pour d'autres systèmes
    }

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
    Version: 1.0
#>

# Fonction pour obtenir des informations détaillées sur l'environnement
function Get-EnvironmentInfo {
    [CmdletBinding()]
    param ()
    
    # Créer l'objet d'informations sur l'environnement
    $envInfo = [PSCustomObject]@{
        # Informations sur le système d'exploitation
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
        
        # Informations sur l'hôte
        PSHost = $Host.Name
        PSHostVersion = $Host.Version
        PSHostUI = $Host.UI.GetType().Name
        IsConsoleHost = $Host.Name -eq "ConsoleHost"
        IsISE = $Host.Name -eq "Windows PowerShell ISE Host"
        IsVSCode = $Host.Name -match "Visual Studio Code"
        
        # Informations sur l'environnement d'exécution
        CurrentDirectory = (Get-Location).Path
        TempDirectory = [System.IO.Path]::GetTempPath()
        UserName = [System.Environment]::UserName
        MachineName = [System.Environment]::MachineName
        UserDomainName = [System.Environment]::UserDomainName
        ProcessId = [System.Diagnostics.Process]::GetCurrentProcess().Id
        ProcessName = [System.Diagnostics.Process]::GetCurrentProcess().ProcessName
        CurrentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture.Name
        CurrentUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture.Name
        
        # Capacités et limitations
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
    
    # Déterminer le type de système d'exploitation
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core a des variables intégrées pour le système d'exploitation
        $envInfo.IsWindows = $IsWindows
        $envInfo.IsLinux = $IsLinux
        $envInfo.IsMacOS = $IsMacOS
        $envInfo.IsUnix = $IsLinux -or $IsMacOS
    }
    else {
        # Windows PowerShell s'exécute uniquement sur Windows
        $envInfo.IsWindows = $true
        $envInfo.IsLinux = $false
        $envInfo.IsMacOS = $false
        $envInfo.IsUnix = $false
    }
    
    # Déterminer le type de runtime PowerShell
    $envInfo.IsCoreCLR = $PSVersionTable.PSVersion.Major -ge 6
    $envInfo.IsDesktopCLR = -not $envInfo.IsCoreCLR
    $envInfo.IsWindowsPowerShell = $PSVersionTable.PSVersion.Major -le 5
    $envInfo.IsPowerShellCore = $PSVersionTable.PSVersion.Major -ge 6
    
    # Déterminer les capacités du terminal
    if ($envInfo.IsWindows) {
        # Vérifier si le terminal Windows prend en charge ANSI/VT100
        $envInfo.SupportsANSI = $Host.UI.SupportsVirtualTerminal -or 
                               ($env:TERM -ne $null) -or 
                               ($env:ConEmuANSI -eq "ON") -or 
                               ($env:ANSICON -ne $null)
        
        $envInfo.SupportsVT100 = $envInfo.SupportsANSI
        
        # Définir la longueur maximale du chemin
        if ($PSVersionTable.PSVersion.Major -ge 5 -and $PSVersionTable.PSVersion.Minor -ge 1) {
            # PowerShell 5.1+ peut gérer des chemins plus longs si la fonctionnalité est activée
            $envInfo.MaxPathLength = 32767
        }
        else {
            $envInfo.MaxPathLength = 260
        }
    }
    else {
        # Les systèmes Unix prennent généralement en charge ANSI/VT100
        $envInfo.SupportsANSI = $true
        $envInfo.SupportsVT100 = $true
        
        # Les systèmes Unix ont généralement une limite de chemin beaucoup plus élevée
        $envInfo.MaxPathLength = 4096
    }
    
    # Obtenir la liste des modules disponibles
    $envInfo.AvailableModules = Get-Module -ListAvailable | Select-Object -ExpandProperty Name
    
    # Vérifier la disponibilité des cmdlets de base
    $envInfo.CoreCmdletsAvailable = (Get-Command -Name "Get-ChildItem" -ErrorAction SilentlyContinue) -ne $null
    $envInfo.LegacyCmdletsAvailable = (Get-Command -Name "Get-WmiObject" -ErrorAction SilentlyContinue) -ne $null
    
    return $envInfo
}

# Fonction pour vérifier la compatibilité avec un environnement cible
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
    
    # Vérifier la compatibilité du système d'exploitation
    $osCompatible = switch ($TargetOS) {
        "Windows" { $envInfo.IsWindows }
        "Linux" { $envInfo.IsLinux }
        "MacOS" { $envInfo.IsMacOS }
        "Any" { $true }
        default { $true }
    }
    
    # Vérifier la compatibilité de la version PowerShell
    $psVersionCompatible = $envInfo.PSVersion -ge $MinimumPSVersion
    
    # Vérifier la compatibilité de l'édition PowerShell
    $psEditionCompatible = switch ($PSEdition) {
        "Desktop" { $envInfo.IsDesktopCLR }
        "Core" { $envInfo.IsCoreCLR }
        "Any" { $true }
        default { $true }
    }
    
    # Vérifier la disponibilité des modules requis
    $modulesCompatible = $true
    foreach ($module in $RequiredModules) {
        if ($envInfo.AvailableModules -notcontains $module) {
            $modulesCompatible = $false
            break
        }
    }
    
    # Vérifier la disponibilité des commandes requises
    $commandsCompatible = $true
    foreach ($command in $RequiredCommands) {
        if ((Get-Command -Name $command -ErrorAction SilentlyContinue) -eq $null) {
            $commandsCompatible = $false
            break
        }
    }
    
    # Vérifier la compatibilité de l'architecture
    $architectureCompatible = -not $Require64Bit -or $envInfo.Is64BitProcess
    
    # Vérifier les privilèges élevés
    $privilegesCompatible = -not $RequireElevatedPrivileges -or (
        # Vérifier les privilèges élevés en fonction du système d'exploitation
        if ($envInfo.IsWindows) {
            # Vérifier si l'utilisateur est administrateur sous Windows
            $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
            $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        else {
            # Vérifier si l'utilisateur est root sous Unix
            $envInfo.UserName -eq "root" -or (id -u) -eq 0
        }
    )
    
    # Déterminer la compatibilité globale
    $isCompatible = $osCompatible -and $psVersionCompatible -and $psEditionCompatible -and $modulesCompatible -and $commandsCompatible -and $architectureCompatible -and $privilegesCompatible
    
    # Créer l'objet de résultat
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
    
    # Ajouter les raisons d'incompatibilité
    if (-not $osCompatible) {
        $result.IncompatibilityReasons += "Le système d'exploitation actuel ($($envInfo.OSDescription)) n'est pas compatible avec la cible ($TargetOS)."
    }
    
    if (-not $psVersionCompatible) {
        $result.IncompatibilityReasons += "La version PowerShell actuelle ($($envInfo.PSVersion)) est inférieure à la version minimale requise ($MinimumPSVersion)."
    }
    
    if (-not $psEditionCompatible) {
        $result.IncompatibilityReasons += "L'édition PowerShell actuelle ($($envInfo.PSEdition)) n'est pas compatible avec l'édition requise ($PSEdition)."
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
        $result.IncompatibilityReasons += "Les privilèges actuels ne sont pas suffisants. Des privilèges élevés sont requis."
    }
    
    # Lever une exception si demandé et incompatible
    if (-not $isCompatible -and $ThrowOnIncompatible) {
        throw "Environnement incompatible: $($result.IncompatibilityReasons -join " ")"
    }
    
    return $result
}

# Fonction pour obtenir des recommandations d'adaptation à l'environnement
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
    
    # Créer l'objet de recommandations
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
        $recommendations.PathHandling += "Éviter les chemins codés en dur avec des barres obliques inversées (\)."
        $recommendations.PathHandling += "Utiliser Join-Path pour construire des chemins de manière compatible."
        
        if ($EnvironmentInfo.MaxPathLength -le 260) {
            $recommendations.PathHandling += "Attention aux limitations de longueur de chemin (MAX_PATH = 260). Envisager d'activer le support des chemins longs."
        }
    }
    else {
        $recommendations.PathHandling += "Utiliser des barres obliques (/) pour les chemins sur les systèmes Unix."
        $recommendations.PathHandling += "Les chemins sont sensibles à la casse sur les systèmes Unix."
        $recommendations.PathHandling += "Utiliser [System.IO.Path]::Combine() ou Join-Path pour construire des chemins compatibles."
    }
    
    # Recommandations pour les substitutions de commandes
    if ($EnvironmentInfo.IsWindowsPowerShell) {
        $recommendations.CommandSubstitutions += "Utiliser Get-WmiObject pour les requêtes WMI."
        $recommendations.CommandSubstitutions += "Utiliser les applets de commande *-Computer* pour la gestion du système."
    }
    elseif ($EnvironmentInfo.IsPowerShellCore) {
        $recommendations.CommandSubstitutions += "Utiliser Get-CimInstance au lieu de Get-WmiObject."
        
        if ($EnvironmentInfo.IsWindows) {
            $recommendations.CommandSubstitutions += "Certaines applets de commande Windows peuvent ne pas être disponibles. Vérifier la disponibilité."
        }
        else {
            $recommendations.CommandSubstitutions += "Les applets de commande spécifiques à Windows ne sont pas disponibles. Utiliser des alternatives natives."
        }
    }
    
    # Recommandations pour l'encodage
    if ($EnvironmentInfo.IsWindows) {
        $recommendations.EncodingRecommendations += "Utiliser UTF-8 avec BOM pour les scripts PowerShell."
        $recommendations.EncodingRecommendations += "Spécifier explicitement l'encodage dans les applets de commande de fichier (Get-Content, Set-Content, etc.)."
    }
    else {
        $recommendations.EncodingRecommendations += "Utiliser UTF-8 sans BOM pour une meilleure compatibilité avec les outils Unix."
        $recommendations.EncodingRecommendations += "Éviter les caractères spécifiques à Windows (CRLF, etc.)."
    }
    
    # Recommandations pour l'adaptation des fonctionnalités
    if ($EnvironmentInfo.PSVersion -lt [version]"5.1") {
        $recommendations.FeatureAdaptations += "Éviter les fonctionnalités PowerShell 5.1+ comme les classes, les énumérations, etc."
    }
    
    if ($EnvironmentInfo.PSVersion -lt [version]"6.0") {
        $recommendations.FeatureAdaptations += "Éviter les fonctionnalités PowerShell 6.0+ comme les opérateurs ternaires, etc."
    }
    
    if (-not $EnvironmentInfo.SupportsANSI) {
        $recommendations.FeatureAdaptations += "Éviter les séquences d'échappement ANSI pour la coloration du texte."
    }
    
    # Recommandations générales
    $recommendations.GeneralRecommendations += "Utiliser Test-Path avant d'accéder aux fichiers et répertoires."
    $recommendations.GeneralRecommendations += "Gérer les exceptions de manière appropriée avec try/catch."
    $recommendations.GeneralRecommendations += "Utiliser des chemins relatifs plutôt que des chemins absolus lorsque c'est possible."
    
    if ($EnvironmentInfo.IsWindows -and $TargetOS -ne "Windows") {
        $recommendations.GeneralRecommendations += "Éviter les appels à des exécutables Windows spécifiques (.exe, .bat, etc.)."
    }
    
    if ($EnvironmentInfo.IsUnix -and $TargetOS -ne "Any" -and $TargetOS -ne "Linux" -and $TargetOS -ne "MacOS") {
        $recommendations.GeneralRecommendations += "Éviter les appels à des commandes Unix spécifiques qui ne sont pas disponibles sur Windows."
    }
    
    return $recommendations
}

# Exporter les fonctions
Export-ModuleMember -Function Get-EnvironmentInfo, Test-EnvironmentCompatibility, Get-EnvironmentAdaptationRecommendations

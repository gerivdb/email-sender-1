<#
.SYNOPSIS
    Vérifie les prérequis avant l'exécution des scripts.

.DESCRIPTION
    Ce script vérifie que tous les prérequis nécessaires à l'exécution d'un script
    sont présents (modules, commandes, versions, privilèges, etc.) et fournit des
    recommandations pour résoudre les problèmes détectés.

.EXAMPLE
    . .\PrerequisiteChecker.ps1
    $prerequisites = @{
        Modules = @("PSReadLine", "Az")
        Commands = @("git", "npm")
        MinimumPSVersion = "5.1"
        RequireAdmin = $true
    }
    $result = Test-Prerequisites -Prerequisites $prerequisites
    if (-not $result.AllPrerequisitesMet) {
        Show-PrerequisiteReport -Report $result
        exit
    }

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
    Version: 1.0
#>

# Charger le module de détection d'environnement
$environmentDetectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EnvironmentDetector.ps1"
if (Test-Path -Path $environmentDetectorPath -PathType Leaf) {
    . $environmentDetectorPath
}
else {
    Write-Warning "Le module de détection d'environnement n'a pas été trouvé. Certaines fonctionnalités peuvent ne pas fonctionner correctement."
}

# Fonction pour vérifier si un module est disponible
function Test-ModuleAvailable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $false)]
        [version]$MinimumVersion = $null
    )
    
    $module = Get-Module -Name $ModuleName -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
    
    if ($null -eq $module) {
        return [PSCustomObject]@{
            Name = $ModuleName
            Available = $false
            Installed = $false
            Version = $null
            MinimumVersionMet = $false
            InstallCommand = "Install-Module -Name $ModuleName -Scope CurrentUser -Force"
        }
    }
    
    $minimumVersionMet = $null -eq $MinimumVersion -or $module.Version -ge $MinimumVersion
    
    return [PSCustomObject]@{
        Name = $ModuleName
        Available = $true
        Installed = $true
        Version = $module.Version
        MinimumVersionMet = $minimumVersionMet
        InstallCommand = if ($minimumVersionMet) { "" } else { "Install-Module -Name $ModuleName -MinimumVersion $MinimumVersion -Scope CurrentUser -Force" }
    }
}

# Fonction pour vérifier si une commande est disponible
function Test-CommandAvailable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )
    
    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    
    if ($null -eq $command) {
        return [PSCustomObject]@{
            Name = $CommandName
            Available = $false
            Type = "Unknown"
            Source = "Unknown"
            InstallationHint = "La commande '$CommandName' n'est pas disponible. Veuillez l'installer selon les instructions du fournisseur."
        }
    }
    
    return [PSCustomObject]@{
        Name = $CommandName
        Available = $true
        Type = $command.CommandType
        Source = if ($command.Source) { $command.Source } else { "Unknown" }
        InstallationHint = ""
    }
}

# Fonction pour vérifier si l'utilisateur a des privilèges administratifs
function Test-AdminPrivileges {
    [CmdletBinding()]
    param ()
    
    # Obtenir les informations sur l'environnement
    $envInfo = if (Get-Command -Name Get-EnvironmentInfo -ErrorAction SilentlyContinue) {
        Get-EnvironmentInfo
    }
    else {
        # Créer un objet d'informations sur l'environnement minimal
        [PSCustomObject]@{
            IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
            IsLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
            IsMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
        }
    }
    
    if ($envInfo.IsWindows) {
        # Vérifier les privilèges administratifs sous Windows
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        
        return [PSCustomObject]@{
            IsAdmin = $isAdmin
            ElevationHint = if (-not $isAdmin) {
                "Exécutez PowerShell en tant qu'administrateur pour obtenir les privilèges nécessaires."
            }
            else {
                ""
            }
        }
    }
    else {
        # Vérifier les privilèges root sous Unix
        $isRoot = $env:USER -eq "root" -or (& id -u) -eq "0"
        
        return [PSCustomObject]@{
            IsAdmin = $isRoot
            ElevationHint = if (-not $isRoot) {
                "Exécutez le script avec sudo pour obtenir les privilèges nécessaires."
            }
            else {
                ""
            }
        }
    }
}

# Fonction pour vérifier la version de PowerShell
function Test-PowerShellVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [version]$MinimumVersion
    )
    
    $currentVersion = $PSVersionTable.PSVersion
    $versionMet = $currentVersion -ge $MinimumVersion
    
    return [PSCustomObject]@{
        CurrentVersion = $currentVersion
        MinimumVersion = $MinimumVersion
        VersionMet = $versionMet
        UpgradeHint = if (-not $versionMet) {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                "Installez PowerShell Core depuis https://github.com/PowerShell/PowerShell/releases"
            }
            else {
                "Mettez à jour PowerShell Core vers la version $MinimumVersion ou supérieure depuis https://github.com/PowerShell/PowerShell/releases"
            }
        }
        else {
            ""
        }
    }
}

# Fonction pour vérifier l'accès à un chemin
function Test-PathAccess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Read", "Write", "ReadWrite")]
        [string]$AccessType = "Read"
    )
    
    # Vérifier si le chemin existe
    $exists = Test-Path -Path $Path -ErrorAction SilentlyContinue
    
    if (-not $exists) {
        return [PSCustomObject]@{
            Path = $Path
            Exists = $false
            CanRead = $false
            CanWrite = $false
            AccessMet = $false
            AccessHint = "Le chemin '$Path' n'existe pas."
        }
    }
    
    # Vérifier les permissions de lecture
    $canRead = $false
    try {
        if (Test-Path -Path $Path -PathType Container) {
            # C'est un dossier, essayer de lister son contenu
            $null = Get-ChildItem -Path $Path -ErrorAction Stop -Force
        }
        else {
            # C'est un fichier, essayer de le lire
            $null = Get-Content -Path $Path -TotalCount 1 -ErrorAction Stop
        }
        $canRead = $true
    }
    catch {
        $canRead = $false
    }
    
    # Vérifier les permissions d'écriture
    $canWrite = $false
    try {
        if (Test-Path -Path $Path -PathType Container) {
            # C'est un dossier, essayer de créer un fichier temporaire
            $tempFile = Join-Path -Path $Path -ChildPath ([System.IO.Path]::GetRandomFileName())
            $null = New-Item -Path $tempFile -ItemType File -ErrorAction Stop
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        else {
            # C'est un fichier, vérifier s'il est en lecture seule
            $item = Get-Item -Path $Path
            $canWrite = -not $item.IsReadOnly
        }
    }
    catch {
        $canWrite = $false
    }
    
    # Déterminer si les conditions d'accès sont remplies
    $accessMet = switch ($AccessType) {
        "Read" { $canRead }
        "Write" { $canWrite }
        "ReadWrite" { $canRead -and $canWrite }
        default { $false }
    }
    
    # Générer un indice pour résoudre les problèmes d'accès
    $accessHint = if (-not $accessMet) {
        if (-not $canRead -and ($AccessType -eq "Read" -or $AccessType -eq "ReadWrite")) {
            "Vous n'avez pas les permissions de lecture pour '$Path'."
        }
        elseif (-not $canWrite -and ($AccessType -eq "Write" -or $AccessType -eq "ReadWrite")) {
            "Vous n'avez pas les permissions d'écriture pour '$Path'."
        }
        else {
            "Vous n'avez pas les permissions nécessaires pour '$Path'."
        }
    }
    else {
        ""
    }
    
    return [PSCustomObject]@{
        Path = $Path
        Exists = $exists
        CanRead = $canRead
        CanWrite = $canWrite
        AccessMet = $accessMet
        AccessHint = $accessHint
    }
}

# Fonction pour vérifier la connectivité réseau
function Test-NetworkConnectivity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Endpoints = @("8.8.8.8", "1.1.1.1"),
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 1000
    )
    
    $results = @()
    $allEndpointsReachable = $true
    
    foreach ($endpoint in $Endpoints) {
        $isReachable = $false
        $responseTime = 0
        
        try {
            # Déterminer si l'endpoint est une URL ou une adresse IP
            if ($endpoint -match '^(http|https)://') {
                # C'est une URL, utiliser Invoke-WebRequest
                $startTime = [System.Diagnostics.Stopwatch]::StartNew()
                $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec ($TimeoutMilliseconds / 1000) -ErrorAction Stop -UseBasicParsing
                $responseTime = $startTime.ElapsedMilliseconds
                $isReachable = $response.StatusCode -eq 200
            }
            else {
                # C'est une adresse IP ou un nom d'hôte, utiliser Test-Connection
                if (Get-Command -Name Test-Connection -ErrorAction SilentlyContinue) {
                    $pingResult = Test-Connection -ComputerName $endpoint -Count 1 -Quiet -TimeoutSeconds ($TimeoutMilliseconds / 1000)
                    $isReachable = $pingResult
                }
                else {
                    # Fallback pour les anciennes versions de PowerShell
                    $ping = New-Object System.Net.NetworkInformation.Ping
                    $pingResult = $ping.Send($endpoint, $TimeoutMilliseconds)
                    $isReachable = $pingResult.Status -eq [System.Net.NetworkInformation.IPStatus]::Success
                    $responseTime = $pingResult.RoundtripTime
                }
            }
        }
        catch {
            $isReachable = $false
        }
        
        $results += [PSCustomObject]@{
            Endpoint = $endpoint
            IsReachable = $isReachable
            ResponseTime = $responseTime
        }
        
        if (-not $isReachable) {
            $allEndpointsReachable = $false
        }
    }
    
    return [PSCustomObject]@{
        AllEndpointsReachable = $allEndpointsReachable
        Results = $results
        ConnectivityHint = if (-not $allEndpointsReachable) {
            "Certains points de terminaison ne sont pas accessibles. Vérifiez votre connexion réseau ou les paramètres de proxy."
        }
        else {
            ""
        }
    }
}

# Fonction principale pour vérifier tous les prérequis
function Test-Prerequisites {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Prerequisites
    )
    
    $report = [PSCustomObject]@{
        AllPrerequisitesMet = $true
        ModuleResults = @()
        CommandResults = @()
        PowerShellVersionResult = $null
        AdminPrivilegesResult = $null
        PathAccessResults = @()
        NetworkConnectivityResult = $null
        MissingPrerequisites = @()
    }
    
    # Vérifier les modules
    if ($Prerequisites.ContainsKey("Modules")) {
        foreach ($module in $Prerequisites.Modules) {
            $moduleName = $module
            $minimumVersion = $null
            
            if ($module -is [hashtable] -or $module -is [PSCustomObject]) {
                $moduleName = $module.Name
                $minimumVersion = if ($module.MinimumVersion) { [version]$module.MinimumVersion } else { $null }
            }
            
            $moduleResult = Test-ModuleAvailable -ModuleName $moduleName -MinimumVersion $minimumVersion
            $report.ModuleResults += $moduleResult
            
            if (-not $moduleResult.Available -or -not $moduleResult.MinimumVersionMet) {
                $report.AllPrerequisitesMet = $false
                $report.MissingPrerequisites += "Module: $moduleName $(if ($minimumVersion) { "(version $minimumVersion minimum)" } else { "" })"
            }
        }
    }
    
    # Vérifier les commandes
    if ($Prerequisites.ContainsKey("Commands")) {
        foreach ($command in $Prerequisites.Commands) {
            $commandResult = Test-CommandAvailable -CommandName $command
            $report.CommandResults += $commandResult
            
            if (-not $commandResult.Available) {
                $report.AllPrerequisitesMet = $false
                $report.MissingPrerequisites += "Commande: $command"
            }
        }
    }
    
    # Vérifier la version de PowerShell
    if ($Prerequisites.ContainsKey("MinimumPSVersion")) {
        $psVersionResult = Test-PowerShellVersion -MinimumVersion ([version]$Prerequisites.MinimumPSVersion)
        $report.PowerShellVersionResult = $psVersionResult
        
        if (-not $psVersionResult.VersionMet) {
            $report.AllPrerequisitesMet = $false
            $report.MissingPrerequisites += "Version PowerShell: $($Prerequisites.MinimumPSVersion) minimum (actuelle: $($psVersionResult.CurrentVersion))"
        }
    }
    
    # Vérifier les privilèges administratifs
    if ($Prerequisites.ContainsKey("RequireAdmin") -and $Prerequisites.RequireAdmin) {
        $adminResult = Test-AdminPrivileges
        $report.AdminPrivilegesResult = $adminResult
        
        if (-not $adminResult.IsAdmin) {
            $report.AllPrerequisitesMet = $false
            $report.MissingPrerequisites += "Privilèges administratifs requis"
        }
    }
    
    # Vérifier l'accès aux chemins
    if ($Prerequisites.ContainsKey("Paths")) {
        foreach ($pathInfo in $Prerequisites.Paths) {
            $path = $pathInfo
            $accessType = "Read"
            
            if ($pathInfo -is [hashtable] -or $pathInfo -is [PSCustomObject]) {
                $path = $pathInfo.Path
                $accessType = if ($pathInfo.AccessType) { $pathInfo.AccessType } else { "Read" }
            }
            
            $pathResult = Test-PathAccess -Path $path -AccessType $accessType
            $report.PathAccessResults += $pathResult
            
            if (-not $pathResult.AccessMet) {
                $report.AllPrerequisitesMet = $false
                $report.MissingPrerequisites += "Accès au chemin: $path ($accessType)"
            }
        }
    }
    
    # Vérifier la connectivité réseau
    if ($Prerequisites.ContainsKey("NetworkEndpoints")) {
        $connectivityResult = Test-NetworkConnectivity -Endpoints $Prerequisites.NetworkEndpoints
        $report.NetworkConnectivityResult = $connectivityResult
        
        if (-not $connectivityResult.AllEndpointsReachable) {
            $report.AllPrerequisitesMet = $false
            $unreachableEndpoints = $connectivityResult.Results | Where-Object { -not $_.IsReachable } | ForEach-Object { $_.Endpoint }
            $report.MissingPrerequisites += "Connectivité réseau: $($unreachableEndpoints -join ", ")"
        }
    }
    
    return $report
}

# Fonction pour afficher un rapport de prérequis
function Show-PrerequisiteReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSuccessful
    )
    
    Write-Host "=== Rapport de vérification des prérequis ===" -ForegroundColor Cyan
    
    if ($Report.AllPrerequisitesMet) {
        Write-Host "Tous les prérequis sont satisfaits." -ForegroundColor Green
        return
    }
    
    Write-Host "Certains prérequis ne sont pas satisfaits:" -ForegroundColor Yellow
    
    # Afficher les modules manquants
    if ($Report.ModuleResults.Count -gt 0) {
        Write-Host "`nModules:" -ForegroundColor Cyan
        foreach ($module in $Report.ModuleResults) {
            if (-not $module.Available -or -not $module.MinimumVersionMet) {
                Write-Host "  [X] $($module.Name)" -ForegroundColor Red -NoNewline
                if ($module.Version) {
                    Write-Host " (version $($module.Version) installée)" -ForegroundColor Red
                }
                else {
                    Write-Host " (non installé)" -ForegroundColor Red
                }
                Write-Host "      Installation: $($module.InstallCommand)" -ForegroundColor Yellow
            }
            elseif ($IncludeSuccessful) {
                Write-Host "  [V] $($module.Name) (version $($module.Version))" -ForegroundColor Green
            }
        }
    }
    
    # Afficher les commandes manquantes
    if ($Report.CommandResults.Count -gt 0) {
        Write-Host "`nCommandes:" -ForegroundColor Cyan
        foreach ($command in $Report.CommandResults) {
            if (-not $command.Available) {
                Write-Host "  [X] $($command.Name) (non disponible)" -ForegroundColor Red
                Write-Host "      $($command.InstallationHint)" -ForegroundColor Yellow
            }
            elseif ($IncludeSuccessful) {
                Write-Host "  [V] $($command.Name) ($($command.Type) de $($command.Source))" -ForegroundColor Green
            }
        }
    }
    
    # Afficher le résultat de la version PowerShell
    if ($null -ne $Report.PowerShellVersionResult) {
        Write-Host "`nVersion PowerShell:" -ForegroundColor Cyan
        if (-not $Report.PowerShellVersionResult.VersionMet) {
            Write-Host "  [X] Version actuelle: $($Report.PowerShellVersionResult.CurrentVersion) (minimum requis: $($Report.PowerShellVersionResult.MinimumVersion))" -ForegroundColor Red
            Write-Host "      $($Report.PowerShellVersionResult.UpgradeHint)" -ForegroundColor Yellow
        }
        elseif ($IncludeSuccessful) {
            Write-Host "  [V] Version actuelle: $($Report.PowerShellVersionResult.CurrentVersion)" -ForegroundColor Green
        }
    }
    
    # Afficher le résultat des privilèges administratifs
    if ($null -ne $Report.AdminPrivilegesResult) {
        Write-Host "`nPrivilèges administratifs:" -ForegroundColor Cyan
        if (-not $Report.AdminPrivilegesResult.IsAdmin) {
            Write-Host "  [X] Privilèges administratifs requis mais non disponibles" -ForegroundColor Red
            Write-Host "      $($Report.AdminPrivilegesResult.ElevationHint)" -ForegroundColor Yellow
        }
        elseif ($IncludeSuccessful) {
            Write-Host "  [V] Privilèges administratifs disponibles" -ForegroundColor Green
        }
    }
    
    # Afficher les résultats d'accès aux chemins
    if ($Report.PathAccessResults.Count -gt 0) {
        Write-Host "`nAccès aux chemins:" -ForegroundColor Cyan
        foreach ($path in $Report.PathAccessResults) {
            if (-not $path.AccessMet) {
                Write-Host "  [X] $($path.Path)" -ForegroundColor Red
                Write-Host "      $($path.AccessHint)" -ForegroundColor Yellow
            }
            elseif ($IncludeSuccessful) {
                Write-Host "  [V] $($path.Path) (Lecture: $($path.CanRead), Écriture: $($path.CanWrite))" -ForegroundColor Green
            }
        }
    }
    
    # Afficher le résultat de la connectivité réseau
    if ($null -ne $Report.NetworkConnectivityResult) {
        Write-Host "`nConnectivité réseau:" -ForegroundColor Cyan
        if (-not $Report.NetworkConnectivityResult.AllEndpointsReachable) {
            Write-Host "  [X] Certains points de terminaison ne sont pas accessibles:" -ForegroundColor Red
            foreach ($endpoint in $Report.NetworkConnectivityResult.Results) {
                if (-not $endpoint.IsReachable) {
                    Write-Host "      - $($endpoint.Endpoint)" -ForegroundColor Red
                }
            }
            Write-Host "      $($Report.NetworkConnectivityResult.ConnectivityHint)" -ForegroundColor Yellow
        }
        elseif ($IncludeSuccessful) {
            Write-Host "  [V] Tous les points de terminaison sont accessibles:" -ForegroundColor Green
            foreach ($endpoint in $Report.NetworkConnectivityResult.Results) {
                Write-Host "      - $($endpoint.Endpoint) (Temps de réponse: $($endpoint.ResponseTime) ms)" -ForegroundColor Green
            }
        }
    }
    
    Write-Host "`nRésumé des prérequis manquants:" -ForegroundColor Cyan
    foreach ($missing in $Report.MissingPrerequisites) {
        Write-Host "  - $missing" -ForegroundColor Red
    }
}

# Fonction pour installer automatiquement les prérequis manquants
function Install-Prerequisites {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if ($Report.AllPrerequisitesMet) {
        Write-Host "Tous les prérequis sont déjà satisfaits." -ForegroundColor Green
        return $true
    }
    
    $installationSuccessful = $true
    
    # Installer les modules manquants
    foreach ($module in $Report.ModuleResults) {
        if ((-not $module.Available -or -not $module.MinimumVersionMet) -and -not [string]::IsNullOrEmpty($module.InstallCommand)) {
            if ($Force -or $PSCmdlet.ShouldProcess($module.Name, "Installer le module")) {
                try {
                    Write-Host "Installation du module $($module.Name)..." -ForegroundColor Yellow
                    Invoke-Expression -Command $module.InstallCommand -ErrorAction Stop
                    Write-Host "Module $($module.Name) installé avec succès." -ForegroundColor Green
                }
                catch {
                    Write-Host "Échec de l'installation du module $($module.Name): $_" -ForegroundColor Red
                    $installationSuccessful = $false
                }
            }
        }
    }
    
    # Afficher des instructions pour les autres prérequis qui ne peuvent pas être installés automatiquement
    if ($null -ne $Report.PowerShellVersionResult -and -not $Report.PowerShellVersionResult.VersionMet) {
        Write-Host "`nPour mettre à jour PowerShell:" -ForegroundColor Yellow
        Write-Host $Report.PowerShellVersionResult.UpgradeHint -ForegroundColor Cyan
    }
    
    if ($null -ne $Report.AdminPrivilegesResult -and -not $Report.AdminPrivilegesResult.IsAdmin) {
        Write-Host "`nPour obtenir des privilèges administratifs:" -ForegroundColor Yellow
        Write-Host $Report.AdminPrivilegesResult.ElevationHint -ForegroundColor Cyan
    }
    
    foreach ($command in $Report.CommandResults) {
        if (-not $command.Available) {
            Write-Host "`nPour installer la commande $($command.Name):" -ForegroundColor Yellow
            Write-Host $command.InstallationHint -ForegroundColor Cyan
        }
    }
    
    foreach ($path in $Report.PathAccessResults) {
        if (-not $path.AccessMet) {
            Write-Host "`nPour résoudre les problèmes d'accès au chemin $($path.Path):" -ForegroundColor Yellow
            Write-Host $path.AccessHint -ForegroundColor Cyan
        }
    }
    
    if ($null -ne $Report.NetworkConnectivityResult -and -not $Report.NetworkConnectivityResult.AllEndpointsReachable) {
        Write-Host "`nPour résoudre les problèmes de connectivité réseau:" -ForegroundColor Yellow
        Write-Host $Report.NetworkConnectivityResult.ConnectivityHint -ForegroundColor Cyan
    }
    
    return $installationSuccessful
}

# Exporter les fonctions
Export-ModuleMember -Function Test-ModuleAvailable, Test-CommandAvailable, Test-AdminPrivileges, Test-PowerShellVersion, Test-PathAccess, Test-NetworkConnectivity, Test-Prerequisites, Show-PrerequisiteReport, Install-Prerequisites

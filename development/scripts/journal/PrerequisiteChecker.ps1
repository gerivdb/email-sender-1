<#
.SYNOPSIS
    VÃ©rifie les prÃ©requis avant l'exÃ©cution des scripts.

.DESCRIPTION
    Ce script vÃ©rifie que tous les prÃ©requis nÃ©cessaires Ã  l'exÃ©cution d'un script
    sont prÃ©sents (modules, commandes, versions, privilÃ¨ges, etc.) et fournit des
    recommandations pour rÃ©soudre les problÃ¨mes dÃ©tectÃ©s.

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
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Charger le module de dÃ©tection d'environnement
$environmentDetectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EnvironmentDetector.ps1"
if (Test-Path -Path $environmentDetectorPath -PathType Leaf) {
    . $environmentDetectorPath
}
else {
    Write-Warning "Le module de dÃ©tection d'environnement n'a pas Ã©tÃ© trouvÃ©. Certaines fonctionnalitÃ©s peuvent ne pas fonctionner correctement."
}

# Fonction pour vÃ©rifier si un module est disponible
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

# Fonction pour vÃ©rifier si une commande est disponible
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

# Fonction pour vÃ©rifier si l'utilisateur a des privilÃ¨ges administratifs
function Test-AdminPrivileges {
    [CmdletBinding()]
    param ()
    
    # Obtenir les informations sur l'environnement
    $envInfo = if (Get-Command -Name Get-EnvironmentInfo -ErrorAction SilentlyContinue) {
        Get-EnvironmentInfo
    }
    else {
        # CrÃ©er un objet d'informations sur l'environnement minimal
        [PSCustomObject]@{
            IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
            IsLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
            IsMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
        }
    }
    
    if ($envInfo.IsWindows) {
        # VÃ©rifier les privilÃ¨ges administratifs sous Windows
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        
        return [PSCustomObject]@{
            IsAdmin = $isAdmin
            ElevationHint = if (-not $isAdmin) {
                "ExÃ©cutez PowerShell en tant qu'administrateur pour obtenir les privilÃ¨ges nÃ©cessaires."
            }
            else {
                ""
            }
        }
    }
    else {
        # VÃ©rifier les privilÃ¨ges root sous Unix
        $isRoot = $env:USER -eq "root" -or (& id -u) -eq "0"
        
        return [PSCustomObject]@{
            IsAdmin = $isRoot
            ElevationHint = if (-not $isRoot) {
                "ExÃ©cutez le script avec sudo pour obtenir les privilÃ¨ges nÃ©cessaires."
            }
            else {
                ""
            }
        }
    }
}

# Fonction pour vÃ©rifier la version de PowerShell
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
                "Mettez Ã  jour PowerShell Core vers la version $MinimumVersion ou supÃ©rieure depuis https://github.com/PowerShell/PowerShell/releases"
            }
        }
        else {
            ""
        }
    }
}

# Fonction pour vÃ©rifier l'accÃ¨s Ã  un chemin
function Test-PathAccess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Read", "Write", "ReadWrite")]
        [string]$AccessType = "Read"
    )
    
    # VÃ©rifier si le chemin existe
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
    
    # VÃ©rifier les permissions de lecture
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
    
    # VÃ©rifier les permissions d'Ã©criture
    $canWrite = $false
    try {
        if (Test-Path -Path $Path -PathType Container) {
            # C'est un dossier, essayer de crÃ©er un fichier temporaire
            $tempFile = Join-Path -Path $Path -ChildPath ([System.IO.Path]::GetRandomFileName())
            $null = New-Item -Path $tempFile -ItemType File -ErrorAction Stop
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        else {
            # C'est un fichier, vÃ©rifier s'il est en lecture seule
            $item = Get-Item -Path $Path
            $canWrite = -not $item.IsReadOnly
        }
    }
    catch {
        $canWrite = $false
    }
    
    # DÃ©terminer si les conditions d'accÃ¨s sont remplies
    $accessMet = switch ($AccessType) {
        "Read" { $canRead }
        "Write" { $canWrite }
        "ReadWrite" { $canRead -and $canWrite }
        default { $false }
    }
    
    # GÃ©nÃ©rer un indice pour rÃ©soudre les problÃ¨mes d'accÃ¨s
    $accessHint = if (-not $accessMet) {
        if (-not $canRead -and ($AccessType -eq "Read" -or $AccessType -eq "ReadWrite")) {
            "Vous n'avez pas les permissions de lecture pour '$Path'."
        }
        elseif (-not $canWrite -and ($AccessType -eq "Write" -or $AccessType -eq "ReadWrite")) {
            "Vous n'avez pas les permissions d'Ã©criture pour '$Path'."
        }
        else {
            "Vous n'avez pas les permissions nÃ©cessaires pour '$Path'."
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

# Fonction pour vÃ©rifier la connectivitÃ© rÃ©seau
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
            # DÃ©terminer si l'endpoint est une URL ou une adresse IP
            if ($endpoint -match '^(http|https)://') {
                # C'est une URL, utiliser Invoke-WebRequest
                $startTime = [System.Diagnostics.Stopwatch]::StartNew()
                $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec ($TimeoutMilliseconds / 1000) -ErrorAction Stop -UseBasicParsing
                $responseTime = $startTime.ElapsedMilliseconds
                $isReachable = $response.StatusCode -eq 200
            }
            else {
                # C'est une adresse IP ou un nom d'hÃ´te, utiliser Test-Connection
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
            "Certains points de terminaison ne sont pas accessibles. VÃ©rifiez votre connexion rÃ©seau ou les paramÃ¨tres de proxy."
        }
        else {
            ""
        }
    }
}

# Fonction principale pour vÃ©rifier tous les prÃ©requis
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
    
    # VÃ©rifier les modules
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
    
    # VÃ©rifier les commandes
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
    
    # VÃ©rifier la version de PowerShell
    if ($Prerequisites.ContainsKey("MinimumPSVersion")) {
        $psVersionResult = Test-PowerShellVersion -MinimumVersion ([version]$Prerequisites.MinimumPSVersion)
        $report.PowerShellVersionResult = $psVersionResult
        
        if (-not $psVersionResult.VersionMet) {
            $report.AllPrerequisitesMet = $false
            $report.MissingPrerequisites += "Version PowerShell: $($Prerequisites.MinimumPSVersion) minimum (actuelle: $($psVersionResult.CurrentVersion))"
        }
    }
    
    # VÃ©rifier les privilÃ¨ges administratifs
    if ($Prerequisites.ContainsKey("RequireAdmin") -and $Prerequisites.RequireAdmin) {
        $adminResult = Test-AdminPrivileges
        $report.AdminPrivilegesResult = $adminResult
        
        if (-not $adminResult.IsAdmin) {
            $report.AllPrerequisitesMet = $false
            $report.MissingPrerequisites += "PrivilÃ¨ges administratifs requis"
        }
    }
    
    # VÃ©rifier l'accÃ¨s aux chemins
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
                $report.MissingPrerequisites += "AccÃ¨s au chemin: $path ($accessType)"
            }
        }
    }
    
    # VÃ©rifier la connectivitÃ© rÃ©seau
    if ($Prerequisites.ContainsKey("NetworkEndpoints")) {
        $connectivityResult = Test-NetworkConnectivity -Endpoints $Prerequisites.NetworkEndpoints
        $report.NetworkConnectivityResult = $connectivityResult
        
        if (-not $connectivityResult.AllEndpointsReachable) {
            $report.AllPrerequisitesMet = $false
            $unreachableEndpoints = $connectivityResult.Results | Where-Object { -not $_.IsReachable } | ForEach-Object { $_.Endpoint }
            $report.MissingPrerequisites += "ConnectivitÃ© rÃ©seau: $($unreachableEndpoints -join ", ")"
        }
    }
    
    return $report
}

# Fonction pour afficher un rapport de prÃ©requis
function Show-PrerequisiteReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSuccessful
    )
    
    Write-Host "=== Rapport de vÃ©rification des prÃ©requis ===" -ForegroundColor Cyan
    
    if ($Report.AllPrerequisitesMet) {
        Write-Host "Tous les prÃ©requis sont satisfaits." -ForegroundColor Green
        return
    }
    
    Write-Host "Certains prÃ©requis ne sont pas satisfaits:" -ForegroundColor Yellow
    
    # Afficher les modules manquants
    if ($Report.ModuleResults.Count -gt 0) {
        Write-Host "`nModules:" -ForegroundColor Cyan
        foreach ($module in $Report.ModuleResults) {
            if (-not $module.Available -or -not $module.MinimumVersionMet) {
                Write-Host "  [X] $($module.Name)" -ForegroundColor Red -NoNewline
                if ($module.Version) {
                    Write-Host " (version $($module.Version) installÃ©e)" -ForegroundColor Red
                }
                else {
                    Write-Host " (non installÃ©)" -ForegroundColor Red
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
    
    # Afficher le rÃ©sultat de la version PowerShell
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
    
    # Afficher le rÃ©sultat des privilÃ¨ges administratifs
    if ($null -ne $Report.AdminPrivilegesResult) {
        Write-Host "`nPrivilÃ¨ges administratifs:" -ForegroundColor Cyan
        if (-not $Report.AdminPrivilegesResult.IsAdmin) {
            Write-Host "  [X] PrivilÃ¨ges administratifs requis mais non disponibles" -ForegroundColor Red
            Write-Host "      $($Report.AdminPrivilegesResult.ElevationHint)" -ForegroundColor Yellow
        }
        elseif ($IncludeSuccessful) {
            Write-Host "  [V] PrivilÃ¨ges administratifs disponibles" -ForegroundColor Green
        }
    }
    
    # Afficher les rÃ©sultats d'accÃ¨s aux chemins
    if ($Report.PathAccessResults.Count -gt 0) {
        Write-Host "`nAccÃ¨s aux chemins:" -ForegroundColor Cyan
        foreach ($path in $Report.PathAccessResults) {
            if (-not $path.AccessMet) {
                Write-Host "  [X] $($path.Path)" -ForegroundColor Red
                Write-Host "      $($path.AccessHint)" -ForegroundColor Yellow
            }
            elseif ($IncludeSuccessful) {
                Write-Host "  [V] $($path.Path) (Lecture: $($path.CanRead), Ã‰criture: $($path.CanWrite))" -ForegroundColor Green
            }
        }
    }
    
    # Afficher le rÃ©sultat de la connectivitÃ© rÃ©seau
    if ($null -ne $Report.NetworkConnectivityResult) {
        Write-Host "`nConnectivitÃ© rÃ©seau:" -ForegroundColor Cyan
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
                Write-Host "      - $($endpoint.Endpoint) (Temps de rÃ©ponse: $($endpoint.ResponseTime) ms)" -ForegroundColor Green
            }
        }
    }
    
    Write-Host "`nRÃ©sumÃ© des prÃ©requis manquants:" -ForegroundColor Cyan
    foreach ($missing in $Report.MissingPrerequisites) {
        Write-Host "  - $missing" -ForegroundColor Red
    }
}

# Fonction pour installer automatiquement les prÃ©requis manquants
function Install-Prerequisites {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if ($Report.AllPrerequisitesMet) {
        Write-Host "Tous les prÃ©requis sont dÃ©jÃ  satisfaits." -ForegroundColor Green
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
                    Write-Host "Module $($module.Name) installÃ© avec succÃ¨s." -ForegroundColor Green
                }
                catch {
                    Write-Host "Ã‰chec de l'installation du module $($module.Name): $_" -ForegroundColor Red
                    $installationSuccessful = $false
                }
            }
        }
    }
    
    # Afficher des instructions pour les autres prÃ©requis qui ne peuvent pas Ãªtre installÃ©s automatiquement
    if ($null -ne $Report.PowerShellVersionResult -and -not $Report.PowerShellVersionResult.VersionMet) {
        Write-Host "`nPour mettre Ã  jour PowerShell:" -ForegroundColor Yellow
        Write-Host $Report.PowerShellVersionResult.UpgradeHint -ForegroundColor Cyan
    }
    
    if ($null -ne $Report.AdminPrivilegesResult -and -not $Report.AdminPrivilegesResult.IsAdmin) {
        Write-Host "`nPour obtenir des privilÃ¨ges administratifs:" -ForegroundColor Yellow
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
            Write-Host "`nPour rÃ©soudre les problÃ¨mes d'accÃ¨s au chemin $($path.Path):" -ForegroundColor Yellow
            Write-Host $path.AccessHint -ForegroundColor Cyan
        }
    }
    
    if ($null -ne $Report.NetworkConnectivityResult -and -not $Report.NetworkConnectivityResult.AllEndpointsReachable) {
        Write-Host "`nPour rÃ©soudre les problÃ¨mes de connectivitÃ© rÃ©seau:" -ForegroundColor Yellow
        Write-Host $Report.NetworkConnectivityResult.ConnectivityHint -ForegroundColor Cyan
    }
    
    return $installationSuccessful
}

# Exporter les fonctions
Export-ModuleMember -Function Test-ModuleAvailable, Test-CommandAvailable, Test-AdminPrivileges, Test-PowerShellVersion, Test-PathAccess, Test-NetworkConnectivity, Test-Prerequisites, Show-PrerequisiteReport, Install-Prerequisites

<#
.SYNOPSIS
    Teste la compatibilitÃ© des scripts entre diffÃ©rents environnements.
.DESCRIPTION
    Ce script teste la compatibilitÃ© des scripts PowerShell entre diffÃ©rents environnements (Windows, Linux, macOS).
#>

[CmdletBinding()]
param (
    [string]$ScriptsDirectory = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "scripts"),
    [string]$LogFilePath = (Join-Path -Path $PSScriptRoot -ChildPath "environment_compatibility_tests.log")
)

# Fonction de journalisation simple
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    } catch { Write-Warning "Impossible d'Ã©crire dans le journal: $_" }
}

# Fonction pour dÃ©tecter l'environnement d'exÃ©cution
function Get-ScriptEnvironment {
    $environment = [PSCustomObject]@{
        IsWindows = $false
        IsLinux = $false
        IsMacOS = $false
        PSVersion = $PSVersionTable.PSVersion
        PathSeparator = [System.IO.Path]::DirectorySeparatorChar
    }
    
    # DÃ©tecter le systÃ¨me d'exploitation
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core (6+)
        $environment.IsWindows = $IsWindows
        $environment.IsLinux = $IsLinux
        $environment.IsMacOS = $IsMacOS
    } else {
        # Windows PowerShell
        $environment.IsWindows = $true
    }
    
    return $environment
}

# Fonction pour vÃ©rifier la compatibilitÃ© d'un script
function Test-ScriptCompatibility {
    param ([string]$ScriptPath)
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Script non trouvÃ©: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    $content = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        Write-Log "Impossible de lire le script: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    $issues = @()
    
    # VÃ©rifier les chemins absolus Windows
    if ($content -match "[A-Za-z]:\\") {
        $issues += "Chemins absolus Windows dÃ©tectÃ©s"
    }
    
    # VÃ©rifier les chemins UNC
    if ($content -match "\\\\") {
        $issues += "Chemins UNC dÃ©tectÃ©s"
    }
    
    # VÃ©rifier les commandes spÃ©cifiques Ã  Windows
    $windowsCommands = @("cmd.exe", "powershell.exe", "explorer.exe", "regedit", "reg.exe", "net.exe", "netsh.exe")
    foreach ($command in $windowsCommands) {
        if ($content -match $command) {
            $issues += "Commande spÃ©cifique Ã  Windows dÃ©tectÃ©e: $command"
        }
    }
    
    # VÃ©rifier l'utilisation de fonctions de gestion de chemins
    $hasPathFunctions = $content -match "Join-Path|Split-Path|Test-Path.*-PathType|System\.IO\.Path|Get-NormalizedPath"
    
    # VÃ©rifier la prÃ©sence de dÃ©tection d'environnement
    $hasEnvironmentDetection = $content -match "Get-ScriptEnvironment|Test-Environment|\$IsWindows|\$IsLinux|\$IsMacOS"
    
    # DÃ©terminer si le script est compatible
    $isCompatible = ($issues.Count -eq 0) -or $hasPathFunctions -or $hasEnvironmentDetection
    
    return [PSCustomObject]@{
        Path = $ScriptPath
        IsCompatible = $isCompatible
        Issues = $issues
        HasPathFunctions = $hasPathFunctions
        HasEnvironmentDetection = $hasEnvironmentDetection
    }
}

# Fonction principale
function Test-EnvironmentCompatibility {
    param ([string]$ScriptsDirectory)
    
    Write-Log "DÃ©marrage des tests de compatibilitÃ© entre environnements"
    
    # VÃ©rifier si le rÃ©pertoire des scripts existe
    if (-not (Test-Path -Path $ScriptsDirectory)) {
        Write-Log "RÃ©pertoire des scripts non trouvÃ©: $ScriptsDirectory" -Level "ERROR"
        return $false
    }
    
    # RÃ©cupÃ©rer l'environnement actuel
    $environment = Get-ScriptEnvironment
    Write-Log "Environnement dÃ©tectÃ©: $(if ($environment.IsWindows) { 'Windows' } elseif ($environment.IsLinux) { 'Linux' } elseif ($environment.IsMacOS) { 'macOS' } else { 'Inconnu' })"
    Write-Log "Version PowerShell: $($environment.PSVersion)"
    Write-Log "SÃ©parateur de chemin: '$($environment.PathSeparator)'"
    
    # RÃ©cupÃ©rer les scripts PowerShell
    $scripts = Get-ChildItem -Path $ScriptsDirectory -Recurse -File -Filter "*.ps1" | 
               Where-Object { -not $_.FullName.Contains(".bak") }
    
    Write-Log "Scripts trouvÃ©s: $($scripts.Count)"
    
    $results = @{
        Total = $scripts.Count
        Compatible = 0
        Incompatible = 0
        Details = @()
    }
    
    foreach ($script in $scripts) {
        Write-Log "Test de compatibilitÃ© pour: $($script.FullName)" -Level "INFO"
        $compatibility = Test-ScriptCompatibility -ScriptPath $script.FullName
        
        if ($compatibility.IsCompatible) {
            Write-Log "Script compatible: $($script.FullName)" -Level "SUCCESS"
            $results.Compatible++
        } else {
            Write-Log "Script incompatible: $($script.FullName)" -Level "WARNING"
            foreach ($issue in $compatibility.Issues) {
                Write-Log "  - $issue" -Level "WARNING"
            }
            $results.Incompatible++
        }
        
        $results.Details += $compatibility
    }
    
    Write-Log "Tests de compatibilitÃ© terminÃ©s: $($results.Compatible)/$($results.Total) compatibles"
    
    # GÃ©nÃ©rer un rapport
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "environment_compatibility_report.json"
    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath
    Write-Log "Rapport enregistrÃ©: $reportPath"
    
    return $results
}

# ExÃ©cuter la fonction principale
$result = Test-EnvironmentCompatibility -ScriptsDirectory $ScriptsDirectory

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests de compatibilitÃ©:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Scripts testÃ©s: $($result.Total)" -ForegroundColor White
Write-Host "Compatibles: $($result.Compatible)" -ForegroundColor Green
Write-Host "Incompatibles: $($result.Incompatible)" -ForegroundColor Red
Write-Host "Taux de compatibilitÃ©: $(if ($result.Total -gt 0) { [math]::Round(($result.Compatible / $result.Total) * 100, 2) } else { 0 })%" -ForegroundColor $(if ($result.Total -gt 0 -and ($result.Compatible / $result.Total) -ge 0.8) { "Green" } else { "Yellow" })
Write-Host "Journal: $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

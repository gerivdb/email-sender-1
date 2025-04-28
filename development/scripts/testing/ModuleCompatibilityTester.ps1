<#
.SYNOPSIS
    Testeur de compatibilitÃ© pour les modules PowerShell.
.DESCRIPTION
    VÃ©rifie la compatibilitÃ© des modules avec diffÃ©rentes versions de PowerShell.
#>

# Configuration du testeur de compatibilitÃ©
$script:CompatibilityTesterConfig = @{
    TestResultsPath = Join-Path -Path $env:TEMP -ChildPath "module-compatibility-tests"
    PowerShellVersions = @{
        "5.1" = "powershell.exe"
        "7.0" = "pwsh.exe"
    }
}

# Initialiser le testeur de compatibilitÃ©
function Initialize-CompatibilityTester {
    [CmdletBinding()]
    param (
        [string]$TestResultsPath,
        [hashtable]$PowerShellVersions
    )
    
    if ($TestResultsPath) { $script:CompatibilityTesterConfig.TestResultsPath = $TestResultsPath }
    if ($PowerShellVersions) { $script:CompatibilityTesterConfig.PowerShellVersions = $PowerShellVersions }
    
    # CrÃ©er le dossier de rÃ©sultats
    if (-not (Test-Path -Path $script:CompatibilityTesterConfig.TestResultsPath)) {
        New-Item -Path $script:CompatibilityTesterConfig.TestResultsPath -ItemType Directory -Force | Out-Null
    }
    
    return $true
}

# Tester la compatibilitÃ© d'un module
function Test-ModuleCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $false)]
        [string[]]$PowerShellVersions = @()
    )
    
    # Utiliser toutes les versions disponibles si non spÃ©cifiÃ©es
    if ($PowerShellVersions.Count -eq 0) {
        $PowerShellVersions = $script:CompatibilityTesterConfig.PowerShellVersions.Keys
    }
    
    $results = @{}
    
    foreach ($psVersion in $PowerShellVersions) {
        if (-not $script:CompatibilityTesterConfig.PowerShellVersions.ContainsKey($psVersion)) {
            Write-Warning "Version PowerShell '$psVersion' non configurÃ©e. IgnorÃ©e."
            continue
        }
        
        $psExecutable = $script:CompatibilityTesterConfig.PowerShellVersions[$psVersion]
        
        # CrÃ©er un script de test
        $testScript = @"
try {
    `$ErrorActionPreference = 'Stop'
    Import-Module -Name '$ModuleName' $(if ($Version) { "-RequiredVersion '$Version'" } else { "" })
    [PSCustomObject]@{
        Success = `$true
        ModuleName = '$ModuleName'
        Version = (Get-Module -Name '$ModuleName').Version
        PowerShellVersion = `$PSVersionTable.PSVersion.ToString()
        Error = `$null
    } | ConvertTo-Json
}
catch {
    [PSCustomObject]@{
        Success = `$false
        ModuleName = '$ModuleName'
        Version = '$Version'
        PowerShellVersion = `$PSVersionTable.PSVersion.ToString()
        Error = `$_.Exception.Message
    } | ConvertTo-Json
}
"@
        
        $testScriptPath = Join-Path -Path $script:CompatibilityTesterConfig.TestResultsPath -ChildPath "test-$ModuleName-$psVersion.ps1"
        Set-Content -Path $testScriptPath -Value $testScript
        
        # ExÃ©cuter le test
        try {
            $output = & $psExecutable -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $testScriptPath
            $result = $output | ConvertFrom-Json
            $results[$psVersion] = $result
        }
        catch {
            $results[$psVersion] = [PSCustomObject]@{
                Success = $false
                ModuleName = $ModuleName
                Version = $Version
                PowerShellVersion = $psVersion
                Error = "Erreur lors de l'exÃ©cution du test: $_"
            }
        }
    }
    
    return $results
}

# GÃ©nÃ©rer un rapport de compatibilitÃ©
function Get-CompatibilityReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestResults
    )
    
    $report = [PSCustomObject]@{
        ModuleName = $null
        Version = $null
        CompatibleVersions = @()
        IncompatibleVersions = @()
        CompatibilityScore = 0
        Details = @{}
    }
    
    # Extraire les informations du module
    foreach ($psVersion in $TestResults.Keys) {
        $result = $TestResults[$psVersion]
        
        if ($null -eq $report.ModuleName) {
            $report.ModuleName = $result.ModuleName
            $report.Version = $result.Version
        }
        
        if ($result.Success) {
            $report.CompatibleVersions += $psVersion
        }
        else {
            $report.IncompatibleVersions += $psVersion
        }
        
        $report.Details[$psVersion] = $result
    }
    
    # Calculer le score de compatibilitÃ©
    if ($TestResults.Count -gt 0) {
        $report.CompatibilityScore = ($report.CompatibleVersions.Count / $TestResults.Count) * 100
    }
    
    return $report
}

# Tester la compatibilitÃ© entre modules
function Test-ModulesInteroperability {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleNames,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Versions = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    )
    
    # VÃ©rifier si la version PowerShell est configurÃ©e
    if (-not $script:CompatibilityTesterConfig.PowerShellVersions.ContainsKey($PowerShellVersion)) {
        Write-Warning "Version PowerShell '$PowerShellVersion' non configurÃ©e. Utilisation de la version actuelle."
        $psExecutable = "powershell.exe"
    }
    else {
        $psExecutable = $script:CompatibilityTesterConfig.PowerShellVersions[$PowerShellVersion]
    }
    
    # CrÃ©er un script de test
    $moduleImports = foreach ($module in $ModuleNames) {
        $versionParam = if ($Versions.ContainsKey($module)) { "-RequiredVersion '$($Versions[$module])'" } else { "" }
        "Import-Module -Name '$module' $versionParam -ErrorAction Stop"
    }
    
    $testScript = @"
try {
    `$ErrorActionPreference = 'Stop'
    $($moduleImports -join "`n    ")
    
    [PSCustomObject]@{
        Success = `$true
        Modules = @(
$($ModuleNames | ForEach-Object { "            '$_'" } -join ",`n")
        )
        Versions = @{
$($ModuleNames | ForEach-Object { "            '$_' = (Get-Module -Name '$_').Version.ToString()" } -join "`n")
        }
        PowerShellVersion = `$PSVersionTable.PSVersion.ToString()
        Error = `$null
    } | ConvertTo-Json -Depth 5
}
catch {
    [PSCustomObject]@{
        Success = `$false
        Modules = @(
$($ModuleNames | ForEach-Object { "            '$_'" } -join ",`n")
        )
        Versions = `$Versions
        PowerShellVersion = `$PSVersionTable.PSVersion.ToString()
        Error = `$_.Exception.Message
    } | ConvertTo-Json -Depth 5
}
"@
    
    $testScriptPath = Join-Path -Path $script:CompatibilityTesterConfig.TestResultsPath -ChildPath "interop-test-$([Guid]::NewGuid().ToString()).ps1"
    Set-Content -Path $testScriptPath -Value $testScript
    
    # ExÃ©cuter le test
    try {
        $output = & $psExecutable -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $testScriptPath
        $result = $output | ConvertFrom-Json
        return $result
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Modules = $ModuleNames
            Versions = $Versions
            PowerShellVersion = $PowerShellVersion
            Error = "Erreur lors de l'exÃ©cution du test: $_"
        }
    }
    finally {
        # Nettoyer
        Remove-Item -Path $testScriptPath -Force -ErrorAction SilentlyContinue
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-CompatibilityTester, Test-ModuleCompatibility, Get-CompatibilityReport, Test-ModulesInteroperability

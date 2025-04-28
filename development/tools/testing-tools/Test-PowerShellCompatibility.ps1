﻿#Requires -Version 5.1
<#
.SYNOPSIS
    Teste la compatibilitÃ© PowerShell et gÃ©nÃ¨re un rapport.
.DESCRIPTION
    Ce script dÃ©tecte la version de PowerShell, vÃ©rifie la disponibilitÃ© de PowerShell 7,
    teste la compatibilitÃ© des modules requis et gÃ©nÃ¨re un rapport dÃ©taillÃ©.
.PARAMETER ModulesToTest
    Liste des modules Ã  tester pour la compatibilitÃ©.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport de compatibilitÃ©.
.PARAMETER CheckPowerShell7
    Indique s'il faut vÃ©rifier la disponibilitÃ© de PowerShell 7.
.EXAMPLE
    .\Test-PowerShellCompatibility.ps1 -ModulesToTest @('PSScriptAnalyzer', 'Pester')
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$ModulesToTest = @('PSScriptAnalyzer', 'Pester', 'Microsoft.PowerShell.Management'),
    
    [Parameter()]
    [string]$OutputPath = "$env:TEMP\PowerShellCompatibilityReport.html",
    
    [Parameter()]
    [switch]$CheckPowerShell7 = $true
)

# Fonction pour vÃ©rifier si PowerShell 7 est installÃ©
function Test-PowerShell7Installed {
    $ps7Paths = @(
        "${env:ProgramFiles}\PowerShell\7\pwsh.exe",
        "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
        "$env:LocalAppData\Microsoft\PowerShell\7\pwsh.exe"
    )
    
    foreach ($path in $ps7Paths) {
        if (Test-Path -Path $path) {
            return @{
                Installed = $true
                Path = $path
                Version = (Get-Item $path).VersionInfo.ProductVersion
            }
        }
    }
    
    # VÃ©rifier si pwsh est dans le PATH
    try {
        $pwshInPath = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($pwshInPath) {
            return @{
                Installed = $true
                Path = $pwshInPath.Source
                Version = (Get-Item $pwshInPath.Source).VersionInfo.ProductVersion
            }
        }
    }
    catch {
        # Ignorer les erreurs
    }
    
    return @{
        Installed = $false
        Path = $null
        Version = $null
    }
}

# Fonction pour tester la compatibilitÃ© d'un module
function Test-ModuleCompatibility {
    param(
        [string]$ModuleName,
        [string]$PowerShellPath
    )
    
    $result = @{
        ModuleName = $ModuleName
        PS5Compatible = $false
        PS7Compatible = $false
        PS5Version = $null
        PS7Version = $null
        Issues = @()
    }
    
    # VÃ©rifier la compatibilitÃ© avec PowerShell 5
    try {
        $modulePS5 = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue
        if ($modulePS5) {
            $result.PS5Compatible = $true
            $result.PS5Version = $modulePS5[0].Version.ToString()
        }
        else {
            $result.Issues += "Module non trouvÃ© pour PowerShell 5"
        }
    }
    catch {
        $result.Issues += "Erreur lors de la vÃ©rification pour PowerShell 5: $_"
    }
    
    # VÃ©rifier la compatibilitÃ© avec PowerShell 7 si disponible
    if ($PowerShellPath) {
        try {
            $modulePS7 = & $PowerShellPath -Command "Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { `$_.Version.ToString() }"
            if ($modulePS7) {
                $result.PS7Compatible = $true
                $result.PS7Version = $modulePS7
            }
            else {
                $result.Issues += "Module non trouvÃ© pour PowerShell 7"
            }
        }
        catch {
            $result.Issues += "Erreur lors de la vÃ©rification pour PowerShell 7: $_"
        }
    }
    
    return $result
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-CompatibilityReport {
    param(
        [hashtable]$CurrentPSInfo,
        [hashtable]$PS7Info,
        [array]$ModuleResults,
        [string]$OutputPath
    )
    
    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME
    $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de compatibilitÃ© PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        .info-box { background-color: #f0f0f0; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport de compatibilitÃ© PowerShell</h1>
    <div class="info-box">
        <p><strong>Date du rapport:</strong> $reportDate</p>
        <p><strong>Ordinateur:</strong> $computerName</p>
        <p><strong>SystÃ¨me d'exploitation:</strong> $($osInfo.Caption) $($osInfo.Version) $($osInfo.OSArchitecture)</p>
    </div>
    
    <h2>Informations PowerShell</h2>
    <table>
        <tr>
            <th>Version</th>
            <th>Edition</th>
            <th>Chemin</th>
        </tr>
        <tr>
            <td>$($CurrentPSInfo.Version)</td>
            <td>$($CurrentPSInfo.Edition)</td>
            <td>$($CurrentPSInfo.Path)</td>
        </tr>
    </table>
    
    <h2>PowerShell 7</h2>
    <table>
        <tr>
            <th>InstallÃ©</th>
            <th>Version</th>
            <th>Chemin</th>
        </tr>
        <tr>
            <td>$($PS7Info.Installed)</td>
            <td>$($PS7Info.Version)</td>
            <td>$($PS7Info.Path)</td>
        </tr>
    </table>
    
    <h2>CompatibilitÃ© des modules</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>PS 5 Compatible</th>
            <th>PS 5 Version</th>
            <th>PS 7 Compatible</th>
            <th>PS 7 Version</th>
            <th>ProblÃ¨mes</th>
        </tr>
"@

    foreach ($result in $ModuleResults) {
        $ps5Class = if ($result.PS5Compatible) { "success" } else { "error" }
        $ps7Class = if ($result.PS7Compatible) { "success" } else { "error" }
        
        $html += @"
        <tr>
            <td>$($result.ModuleName)</td>
            <td class="$ps5Class">$($result.PS5Compatible)</td>
            <td>$($result.PS5Version)</td>
            <td class="$ps7Class">$($result.PS7Compatible)</td>
            <td>$($result.PS7Version)</td>
            <td>$($result.Issues -join "<br>")</td>
        </tr>
"@
    }

    $html += @"
    </table>
    
    <h2>Recommandations</h2>
    <ul>
"@

    if (-not $PS7Info.Installed) {
        $html += @"
        <li class="warning">PowerShell 7 n'est pas installÃ©. Envisagez d'installer PowerShell 7 pour une meilleure compatibilitÃ© et des performances amÃ©liorÃ©es.</li>
"@
    }

    $incompatibleModules = $ModuleResults | Where-Object { -not $_.PS7Compatible }
    if ($incompatibleModules) {
        $html += @"
        <li class="warning">Certains modules ne sont pas compatibles avec PowerShell 7. Envisagez de mettre Ã  jour ces modules ou de trouver des alternatives compatibles.</li>
"@
    }

    $html += @"
    </ul>
    
    <h2>Ã‰tapes suivantes</h2>
    <ol>
"@

    if (-not $PS7Info.Installed) {
        $html += @"
        <li>Installer PowerShell 7 depuis <a href="https://github.com/PowerShell/PowerShell/releases" target="_blank">GitHub</a>.</li>
"@
    }

    $html += @"
        <li>Mettre Ã  jour les modules incompatibles vers des versions compatibles avec PowerShell 7.</li>
        <li>Tester vos scripts avec PowerShell 7 pour identifier les problÃ¨mes de compatibilitÃ©.</li>
        <li>Refactoriser le code pour utiliser des fonctionnalitÃ©s compatibles avec les deux versions si nÃ©cessaire.</li>
    </ol>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

# Obtenir les informations sur PowerShell actuel
$currentPSInfo = @{
    Version = $PSVersionTable.PSVersion.ToString()
    Edition = $PSVersionTable.PSEdition
    Path = $PSHOME
}

# VÃ©rifier si PowerShell 7 est installÃ©
$ps7Info = @{ Installed = $false; Path = $null; Version = $null }
if ($CheckPowerShell7) {
    $ps7Info = Test-PowerShell7Installed
}

# Tester la compatibilitÃ© des modules
$moduleResults = @()
foreach ($module in $ModulesToTest) {
    $moduleResults += Test-ModuleCompatibility -ModuleName $module -PowerShellPath $ps7Info.Path
}

# GÃ©nÃ©rer le rapport
$reportPath = New-CompatibilityReport -CurrentPSInfo $currentPSInfo -PS7Info $ps7Info -ModuleResults $moduleResults -OutputPath $OutputPath

# Afficher un rÃ©sumÃ©
Write-Host "Informations PowerShell actuel:" -ForegroundColor Cyan
Write-Host "  Version: $($currentPSInfo.Version)"
Write-Host "  Edition: $($currentPSInfo.Edition)"
Write-Host "  Chemin: $($currentPSInfo.Path)"
Write-Host ""

Write-Host "PowerShell 7:" -ForegroundColor Cyan
if ($ps7Info.Installed) {
    Write-Host "  InstallÃ©: Oui"
    Write-Host "  Version: $($ps7Info.Version)"
    Write-Host "  Chemin: $($ps7Info.Path)"
} else {
    Write-Host "  InstallÃ©: Non"
}
Write-Host ""

Write-Host "CompatibilitÃ© des modules:" -ForegroundColor Cyan
foreach ($result in $moduleResults) {
    Write-Host "  $($result.ModuleName):"
    Write-Host "    PS5 Compatible: $($result.PS5Compatible)"
    if ($result.PS5Compatible) {
        Write-Host "    PS5 Version: $($result.PS5Version)"
    }
    Write-Host "    PS7 Compatible: $($result.PS7Compatible)"
    if ($result.PS7Compatible) {
        Write-Host "    PS7 Version: $($result.PS7Version)"
    }
    if ($result.Issues.Count -gt 0) {
        Write-Host "    ProblÃ¨mes: $($result.Issues -join ", ")" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "Rapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
Write-Host "Ouvrez ce fichier dans un navigateur pour voir le rapport complet."

# Retourner un objet avec les rÃ©sultats
return @{
    CurrentPSInfo = $currentPSInfo
    PS7Info = $ps7Info
    ModuleResults = $moduleResults
    ReportPath = $reportPath
}

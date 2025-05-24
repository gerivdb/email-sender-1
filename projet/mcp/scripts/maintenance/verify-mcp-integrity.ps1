#Requires -Version 5.1
<#
.SYNOPSIS
    Vérifie l'intégrité de l'installation MCP.
.DESCRIPTION
    Ce script vérifie l'intégrité de l'installation MCP en contrôlant la présence
    de tous les fichiers nécessaires, la validité des configurations et l'état des serveurs.
.PARAMETER Fix
    Tente de corriger automatiquement les problèmes détectés.
.PARAMETER OutputFormat
    Format de sortie du rapport (Text, JSON, HTML). Par défaut: Text.
.PARAMETER Force
    Force la vérification sans demander de confirmation.
.EXAMPLE
    .\verify-mcp-integrity.ps1 -Fix -OutputFormat HTML
    Vérifie l'intégrité de l'installation MCP, tente de corriger les problèmes et génère un rapport HTML.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Fix,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "HTML")]
    [string]$OutputFormat = "Text",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $scriptsRoot).Parent.FullName
$projectRoot = (Get-Item $mcpRoot).Parent.FullName
$modulePath = Join-Path -Path $mcpRoot -ChildPath "modules\MCPManager"
$reportPath = Join-Path -Path $mcpRoot -ChildPath "monitoring\reports\mcp-integrity-$(Get-Date -Format 'yyyyMMdd-HHmmss').$($OutputFormat.ToLower())"

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-FileExists {
    param (
        [string]$Path,
        [string]$Description,
        [bool]$Critical = $false
    )
    
    $result = @{
        Path = $Path
        Description = $Description
        Status = if (Test-Path $Path) { "OK" } else { "Missing" }
        Critical = $Critical
    }
    
    return $result
}

function Test-ConfigValid {
    param (
        [string]$Path,
        [string]$Description,
        [bool]$Critical = $false
    )
    
    $result = @{
        Path = $Path
        Description = $Description
        Status = "Unknown"
        Critical = $Critical
    }
    
    if (-not (Test-Path $Path)) {
        $result.Status = "Missing"
        return $result
    }
    
    try {
        $content = Get-Content -Path $Path -Raw
        $null = $content | ConvertFrom-Json
        $result.Status = "OK"
    }
    catch {
        $result.Status = "Invalid"
        $result.Error = $_.Exception.Message
    }
    
    return $result
}

function Test-ModuleValid {
    param (
        [string]$Path,
        [string]$Description,
        [bool]$Critical = $false
    )
    
    $result = @{
        Path = $Path
        Description = $Description
        Status = "Unknown"
        Critical = $Critical
    }
    
    if (-not (Test-Path $Path)) {
        $result.Status = "Missing"
        return $result
    }
    
    try {
        $manifestPath = Join-Path -Path $Path -ChildPath "MCPManager.psd1"
        $moduleValid = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        $result.Status = "OK"
    }
    catch {
        $result.Status = "Invalid"
        $result.Error = $_.Exception.Message
    }
    
    return $result
}

function Repair-MissingFile {
    param (
        [string]$Path,
        [string]$Description
    )
    
    $result = @{
        Path = $Path
        Description = $Description
        Status = "Unknown"
        Action = "None"
    }
    
    if (Test-Path $Path) {
        $result.Status = "OK"
        $result.Action = "None"
        return $result
    }
    
    # Déterminer le type de fichier
    $extension = [System.IO.Path]::GetExtension($Path)
    $fileName = [System.IO.Path]::GetFileName($Path)
    $dirPath = [System.IO.Path]::GetDirectoryName($Path)
    
    # Créer le répertoire parent si nécessaire
    if (-not (Test-Path $dirPath)) {
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
        $result.Action = "Created directory"
    }
    
    # Tenter de restaurer le fichier
    try {
        if ($fileName -eq "mcp-config.json") {
            # Restaurer la configuration principale
            $templatePath = Join-Path -Path $mcpRoot -ChildPath "config\templates\mcp-config-template.json"
            
            if (Test-Path $templatePath) {
                Copy-Item -Path $templatePath -Destination $Path
                $result.Status = "Fixed"
                $result.Action = "Restored from template"
            }
            else {
                $result.Status = "Failed"
                $result.Action = "Template not found"
            }
        }
        elseif ($extension -eq ".json" -and $Path -like "*\config\servers\*") {
            # Restaurer la configuration d'un serveur
            $templatePath = Join-Path -Path $mcpRoot -ChildPath "config\templates\servers\$fileName"
            
            if (Test-Path $templatePath) {
                Copy-Item -Path $templatePath -Destination $Path
                $result.Status = "Fixed"
                $result.Action = "Restored from template"
            }
            else {
                $result.Status = "Failed"
                $result.Action = "Template not found"
            }
        }
        elseif ($Path -like "*\modules\MCPManager*") {
            # Réinstaller le module
            $setupScript = Join-Path -Path $mcpRoot -ChildPath "scripts\setup\setup-mcp.ps1"
            
            if (Test-Path $setupScript) {
                & $setupScript -Force
                $result.Status = "Fixed"
                $result.Action = "Reinstalled module"
            }
            else {
                $result.Status = "Failed"
                $result.Action = "Setup script not found"
            }
        }
        else {
            $result.Status = "Failed"
            $result.Action = "No fix available"
        }
    }
    catch {
        $result.Status = "Failed"
        $result.Action = "Error: $($_.Exception.Message)"
    }
    
    return $result
}

function Repair-InvalidConfig {
    param (
        [string]$Path,
        [string]$Description
    )
    
    $result = @{
        Path = $Path
        Description = $Description
        Status = "Unknown"
        Action = "None"
    }
    
    if (-not (Test-Path $Path)) {
        $result.Status = "Missing"
        $result.Action = "None"
        return $result
    }
    
    try {
        $content = Get-Content -Path $Path -Raw
        $null = $content | ConvertFrom-Json
        $result.Status = "OK"
        $result.Action = "None"
        return $result
    }
    catch {
        # La configuration est invalide, tenter de la restaurer
        $fileName = [System.IO.Path]::GetFileName($Path)
        
        if ($fileName -eq "mcp-config.json") {
            # Restaurer la configuration principale
            $templatePath = Join-Path -Path $mcpRoot -ChildPath "config\templates\mcp-config-template.json"
            
            if (Test-Path $templatePath) {
                # Sauvegarder la configuration invalide
                $backupPath = "$Path.bak"
                Copy-Item -Path $Path -Destination $backupPath -Force
                
                # Copier le modèle
                Copy-Item -Path $templatePath -Destination $Path -Force
                
                $result.Status = "Fixed"
                $result.Action = "Restored from template (backup at $backupPath)"
            }
            else {
                $result.Status = "Failed"
                $result.Action = "Template not found"
            }
        }
        elseif ($Path -like "*\config\servers\*") {
            # Restaurer la configuration d'un serveur
            $templatePath = Join-Path -Path $mcpRoot -ChildPath "config\templates\servers\$fileName"
            
            if (Test-Path $templatePath) {
                # Sauvegarder la configuration invalide
                $backupPath = "$Path.bak"
                Copy-Item -Path $Path -Destination $backupPath -Force
                
                # Copier le modèle
                Copy-Item -Path $templatePath -Destination $Path -Force
                
                $result.Status = "Fixed"
                $result.Action = "Restored from template (backup at $backupPath)"
            }
            else {
                $result.Status = "Failed"
                $result.Action = "Template not found"
            }
        }
        else {
            $result.Status = "Failed"
            $result.Action = "No fix available"
        }
    }
    
    return $result
}

function Format-TextReport {
    param (
        [array]$Results
    )
    
    $text = @"
MCP Integrity Report
====================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Summary
-------
Total checks: $($Results.Count)
Passed: $($Results | Where-Object { $_.Status -eq "OK" } | Measure-Object | Select-Object -ExpandProperty Count)
Failed: $($Results | Where-Object { $_.Status -ne "OK" } | Measure-Object | Select-Object -ExpandProperty Count)
Critical issues: $($Results | Where-Object { $_.Status -ne "OK" -and $_.Critical -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)

Details
-------

"@
    
    foreach ($result in $Results) {
        $status = switch ($result.Status) {
            "OK" { "OK" }
            "Missing" { "MISSING" }
            "Invalid" { "INVALID" }
            default { $result.Status }
        }
        
        $critical = if ($result.Critical) { " (CRITICAL)" } else { "" }
        
        $text += "[$status]$critical $($result.Description)`n"
        $text += "  Path: $($result.Path)`n"
        
        if ($result.Error) {
            $text += "  Error: $($result.Error)`n"
        }
        
        if ($result.Action) {
            $text += "  Action: $($result.Action)`n"
        }
        
        $text += "`n"
    }
    
    return $text
}

function Format-JSONReport {
    param (
        [array]$Results
    )
    
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Summary = @{
            TotalChecks = $Results.Count
            Passed = ($Results | Where-Object { $_.Status -eq "OK" } | Measure-Object).Count
            Failed = ($Results | Where-Object { $_.Status -ne "OK" } | Measure-Object).Count
            CriticalIssues = ($Results | Where-Object { $_.Status -ne "OK" -and $_.Critical -eq $true } | Measure-Object).Count
        }
        Details = $Results
    }
    
    return $report | ConvertTo-Json -Depth 5
}

function Format-HTMLReport {
    param (
        [array]$Results
    )
    
    $passedCount = ($Results | Where-Object { $_.Status -eq "OK" } | Measure-Object).Count
    $failedCount = ($Results | Where-Object { $_.Status -ne "OK" } | Measure-Object).Count
    $criticalCount = ($Results | Where-Object { $_.Status -ne "OK" -and $_.Critical -eq $true } | Measure-Object).Count
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>MCP Integrity Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .ok { background-color: #dff0d8; }
        .missing, .invalid, .failed { background-color: #f2dede; }
        .critical { font-weight: bold; color: #a94442; }
        .summary { display: flex; justify-content: space-between; margin-bottom: 20px; }
        .summary-box { border: 1px solid #ddd; padding: 15px; border-radius: 5px; width: 30%; text-align: center; }
        .summary-box h3 { margin-top: 0; }
        .success { color: green; }
        .danger { color: red; }
    </style>
</head>
<body>
    <h1>MCP Integrity Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    
    <div class="summary">
        <div class="summary-box">
            <h3>Total Checks</h3>
            <p>$($Results.Count)</p>
        </div>
        <div class="summary-box">
            <h3>Passed</h3>
            <p class="success">$passedCount</p>
        </div>
        <div class="summary-box">
            <h3>Failed</h3>
            <p class="danger">$failedCount ($criticalCount critical)</p>
        </div>
    </div>
    
    <h2>Details</h2>
    <table>
        <tr>
            <th>Status</th>
            <th>Description</th>
            <th>Path</th>
            <th>Details</th>
            <th>Action</th>
        </tr>
"@
    
    foreach ($result in $Results) {
        $statusClass = $result.Status.ToLower()
        $criticalClass = if ($result.Critical) { "critical" } else { "" }
        $details = if ($result.Error) { $result.Error } else { "" }
        $action = if ($result.Action) { $result.Action } else { "" }
        
        $html += @"
        <tr class="$statusClass">
            <td class="$criticalClass">$($result.Status)</td>
            <td>$($result.Description)</td>
            <td>$($result.Path)</td>
            <td>$details</td>
            <td>$action</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    return $html
}

# Corps principal du script
try {
    Write-Log "Vérification de l'intégrité de l'installation MCP..." -Level "TITLE"
    
    # Demander confirmation
    if (-not $Force) {
        $message = "Voulez-vous vérifier l'intégrité de l'installation MCP"
        
        if ($Fix) {
            $message += " et tenter de corriger les problèmes"
        }
        
        $message += " ? (O/N)"
        
        $confirmation = Read-Host $message
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Vérification annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Liste des fichiers et répertoires à vérifier
    $checksToPerform = @(
        @{ Path = "$mcpRoot\config\mcp-config.json"; Description = "Configuration principale"; Critical = $true },
        @{ Path = "$mcpRoot\config\servers"; Description = "Répertoire des configurations des serveurs"; Critical = $true },
        @{ Path = "$mcpRoot\modules\MCPManager"; Description = "Module MCPManager"; Critical = $true },
        @{ Path = "$mcpRoot\scripts\setup\setup-mcp.ps1"; Description = "Script d'installation"; Critical = $true },
        @{ Path = "$mcpRoot\scripts\utils\start-mcp-server.ps1"; Description = "Script de démarrage des serveurs"; Critical = $true },
        @{ Path = "$mcpRoot\scripts\utils\stop-mcp-server.ps1"; Description = "Script d'arrêt des serveurs"; Critical = $true },
        @{ Path = "$mcpRoot\monitoring\logs"; Description = "Répertoire des journaux"; Critical = $false },
        @{ Path = "$mcpRoot\monitoring\reports"; Description = "Répertoire des rapports"; Critical = $false },
        @{ Path = "$mcpRoot\versioning\backups"; Description = "Répertoire des sauvegardes"; Critical = $false },
        @{ Path = "$mcpRoot\dependencies\scripts\install-dependencies.ps1"; Description = "Script d'installation des dépendances"; Critical = $true },
        @{ Path = "$mcpRoot\config\servers\filesystem.json"; Description = "Configuration du serveur Filesystem"; Critical = $false },
        @{ Path = "$mcpRoot\config\servers\github.json"; Description = "Configuration du serveur GitHub"; Critical = $false },
        @{ Path = "$mcpRoot\config\servers\gateway.yaml"; Description = "Configuration du serveur Gateway"; Critical = $false },
        @{ Path = "$mcpRoot\config\templates\mcp-config-template.json"; Description = "Modèle de configuration principale"; Critical = $true },
        @{ Path = "$mcpRoot\docs\guides\quick-start.md"; Description = "Guide de démarrage rapide"; Critical = $false },
        @{ Path = "$mcpRoot\docs\guides\maintenance.md"; Description = "Guide de maintenance"; Critical = $false },
        @{ Path = "$mcpRoot\docs\guides\troubleshooting.md"; Description = "Guide de dépannage"; Critical = $false }
    )
    
    # Résultats des vérifications
    $results = @()
    
    # Vérifier l'existence des fichiers et répertoires
    Write-Log "Vérification de l'existence des fichiers et répertoires..." -Level "INFO"
    
    foreach ($check in $checksToPerform) {
        $result = Test-FileExists -Path $check.Path -Description $check.Description -Critical $check.Critical
        $results += $result
        
        $statusColor = switch ($result.Status) {
            "OK" { "SUCCESS" }
            "Missing" { if ($result.Critical) { "ERROR" } else { "WARNING" } }
            default { "INFO" }
        }
        
        Write-Log "$($result.Description): $($result.Status)" -Level $statusColor
        
        # Tenter de corriger les problèmes si demandé
        if ($Fix -and $result.Status -eq "Missing") {
            Write-Log "Tentative de correction..." -Level "INFO"
            $fixResult = Repair-MissingFile -Path $result.Path -Description $result.Description
            
            $fixStatusColor = switch ($fixResult.Status) {
                "Fixed" { "SUCCESS" }
                "Failed" { "ERROR" }
                default { "INFO" }
            }
            
            Write-Log "Résultat: $($fixResult.Status) - $($fixResult.Action)" -Level $fixStatusColor
            
            # Mettre à jour le résultat
            if ($fixResult.Status -eq "Fixed") {
                $result.Status = "Fixed"
                $result.Action = $fixResult.Action
            }
            else {
                $result.Action = $fixResult.Action
            }
        }
    }
    
    # Vérifier la validité des configurations JSON
    Write-Log "Vérification de la validité des configurations..." -Level "INFO"
    
    $configsToCheck = @(
        @{ Path = "$mcpRoot\config\mcp-config.json"; Description = "Configuration principale"; Critical = $true },
        @{ Path = "$mcpRoot\config\servers\filesystem.json"; Description = "Configuration du serveur Filesystem"; Critical = $false },
        @{ Path = "$mcpRoot\config\servers\github.json"; Description = "Configuration du serveur GitHub"; Critical = $false }
    )
    
    foreach ($config in $configsToCheck) {
        if (Test-Path $config.Path) {
            $result = Test-ConfigValid -Path $config.Path -Description $config.Description -Critical $config.Critical
            $results += $result
            
            $statusColor = switch ($result.Status) {
                "OK" { "SUCCESS" }
                "Invalid" { if ($result.Critical) { "ERROR" } else { "WARNING" } }
                default { "INFO" }
            }
            
            Write-Log "$($result.Description): $($result.Status)" -Level $statusColor
            
            # Tenter de corriger les problèmes si demandé
            if ($Fix -and $result.Status -eq "Invalid") {
                Write-Log "Tentative de correction..." -Level "INFO"
                $fixResult = Repair-InvalidConfig -Path $result.Path -Description $result.Description
                
                $fixStatusColor = switch ($fixResult.Status) {
                    "Fixed" { "SUCCESS" }
                    "Failed" { "ERROR" }
                    default { "INFO" }
                }
                
                Write-Log "Résultat: $($fixResult.Status) - $($fixResult.Action)" -Level $fixStatusColor
                
                # Mettre à jour le résultat
                if ($fixResult.Status -eq "Fixed") {
                    $result.Status = "Fixed"
                    $result.Action = $fixResult.Action
                }
                else {
                    $result.Action = $fixResult.Action
                }
            }
        }
    }
    
    # Vérifier la validité du module MCPManager
    Write-Log "Vérification du module MCPManager..." -Level "INFO"
    
    $result = Test-ModuleValid -Path "$mcpRoot\modules\MCPManager" -Description "Module MCPManager" -Critical $true
    $results += $result
    
    $statusColor = switch ($result.Status) {
        "OK" { "SUCCESS" }
        "Invalid" { "ERROR" }
        "Missing" { "ERROR" }
        default { "INFO" }
    }
    
    Write-Log "Module MCPManager: $($result.Status)" -Level $statusColor
    
    # Tenter de corriger les problèmes si demandé
    if ($Fix -and ($result.Status -eq "Invalid" -or $result.Status -eq "Missing")) {
        Write-Log "Tentative de correction..." -Level "INFO"
        
        # Réinstaller le module
        $setupScript = Join-Path -Path $mcpRoot -ChildPath "scripts\setup\setup-mcp.ps1"
        
        if (Test-Path $setupScript) {
            Write-Log "Réinstallation du module MCPManager..." -Level "INFO"
            
            try {
                & $setupScript -Force
                $result.Status = "Fixed"
                $result.Action = "Reinstalled module"
                Write-Log "Module MCPManager réinstallé avec succès." -Level "SUCCESS"
            }
            catch {
                $result.Action = "Failed to reinstall: $($_.Exception.Message)"
                Write-Log "Échec de la réinstallation du module: $_" -Level "ERROR"
            }
        }
        else {
            $result.Action = "Setup script not found"
            Write-Log "Script d'installation non trouvé: $setupScript" -Level "ERROR"
        }
    }
    
    # Générer le rapport
    Write-Log "Génération du rapport..." -Level "INFO"
    
    $reportContent = switch ($OutputFormat) {
        "JSON" { Format-JSONReport -Results $results }
        "HTML" { Format-HTMLReport -Results $results }
        default { Format-TextReport -Results $results }
    }
    
    # Créer le répertoire de sortie si nécessaire
    $reportDir = Split-Path -Parent $reportPath
    if (-not (Test-Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    Set-Content -Path $reportPath -Value $reportContent
    Write-Log "Rapport enregistré: $reportPath" -Level "SUCCESS"
    
    # Afficher le résumé
    $passedCount = ($results | Where-Object { $_.Status -eq "OK" -or $_.Status -eq "Fixed" } | Measure-Object).Count
    $failedCount = ($results | Where-Object { $_.Status -ne "OK" -and $_.Status -ne "Fixed" } | Measure-Object).Count
    $criticalCount = ($results | Where-Object { $_.Status -ne "OK" -and $_.Status -ne "Fixed" -and $_.Critical -eq $true } | Measure-Object).Count
    $fixedCount = ($results | Where-Object { $_.Status -eq "Fixed" } | Measure-Object).Count
    
    Write-Log "`nRésumé de la vérification:" -Level "TITLE"
    Write-Log "Total des vérifications: $($results.Count)" -Level "INFO"
    Write-Log "Réussies: $passedCount" -Level "SUCCESS"
    Write-Log "Échouées: $failedCount" -Level "ERROR"
    Write-Log "Problèmes critiques: $criticalCount" -Level "ERROR"
    Write-Log "Problèmes corrigés: $fixedCount" -Level "SUCCESS"
    
    # Afficher le rapport en mode texte
    if ($OutputFormat -eq "Text") {
        Write-Host "`n$reportContent" -ForegroundColor White
    }
    
    # Retourner un code de sortie
    if ($criticalCount -gt 0) {
        Write-Log "Des problèmes critiques ont été détectés. Veuillez les corriger avant d'utiliser MCP." -Level "ERROR"
        exit 1
    }
    elseif ($failedCount -gt 0) {
        Write-Log "Des problèmes non critiques ont été détectés. MCP peut fonctionner, mais certaines fonctionnalités peuvent être limitées." -Level "WARNING"
        exit 0
    }
    else {
        Write-Log "L'installation MCP est intègre." -Level "SUCCESS"
        exit 0
    }
} catch {
    Write-Log "Erreur lors de la vérification de l'intégrité de l'installation MCP: $_" -Level "ERROR"
    exit 1
}


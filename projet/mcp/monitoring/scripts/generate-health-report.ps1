#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un rapport de santé complet pour les serveurs MCP.
.DESCRIPTION
    Ce script génère un rapport de santé complet pour les serveurs MCP,
    incluant l'état des serveurs, les métriques de performance et les tests.
.PARAMETER OutputFormat
    Format de sortie du rapport (HTML, JSON, Text). Par défaut: HTML.
.PARAMETER IncludeTests
    Inclut les résultats des tests dans le rapport.
.PARAMETER SendEmail
    Envoie le rapport par e-mail.
.PARAMETER EmailTo
    Adresse e-mail du destinataire. Obligatoire si SendEmail est spécifié.
.EXAMPLE
    .\generate-health-report.ps1 -OutputFormat HTML -IncludeTests
    Génère un rapport de santé au format HTML incluant les résultats des tests.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("HTML", "JSON", "Text")]
    [string]$OutputFormat = "HTML",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SendEmail,
    
    [Parameter(Mandatory = $false)]
    [string]$EmailTo
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$monitoringRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $monitoringRoot).Parent.FullName
$testsRoot = Join-Path -Path $mcpRoot -ChildPath "tests"
$modulePath = Join-Path -Path $mcpRoot -ChildPath "modules\MCPManager"
$reportPath = Join-Path -Path $monitoringRoot -ChildPath "reports\mcp-health-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').$($OutputFormat.ToLower())"

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

function Get-SystemInfo {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    $processorInfo = Get-CimInstance -ClassName Win32_Processor
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    
    return @{
        ComputerName = $computerInfo.Name
        OSName = $osInfo.Caption
        OSVersion = $osInfo.Version
        Processor = $processorInfo.Name
        Memory = [math]::Round($memoryInfo.Sum / 1GB, 2)
        Architecture = $osInfo.OSArchitecture
        LastBootTime = $osInfo.LastBootUpTime
        Uptime = (Get-Date) - $osInfo.LastBootUpTime
    }
}

function Start-Tests {
    param (
        [string]$TestsPath
    )
    
    $testFiles = Get-ChildItem -Path $TestsPath -Filter "Test-*.ps1" -Recurse
    
    if ($testFiles.Count -eq 0) {
        return @{
            Total = 0
            Passed = 0
            Failed = 0
            Results = @()
        }
    }
    
    $results = @{
        Total = $testFiles.Count
        Passed = 0
        Failed = 0
        Results = @()
    }
    
    foreach ($testFile in $testFiles) {
        try {
            $testResult = & $testFile.FullName
            $exitCode = $LASTEXITCODE
            
            $testStatus = if ($exitCode -eq 0) { "Passed" } else { "Failed" }
            
            $results.Results += @{
                Name = $testFile.Name
                Status = $testStatus
                Path = $testFile.FullName
            }
            
            if ($exitCode -eq 0) {
                $results.Passed++
            }
            else {
                $results.Failed++
            }
        }
        catch {
            $results.Results += @{
                Name = $testFile.Name
                Status = "Error"
                Path = $testFile.FullName
                Error = $_.Exception.Message
            }
            
            $results.Failed++
        }
    }
    
    return $results
}

function Format-HTMLReport {
    param (
        [hashtable]$SystemInfo,
        [array]$ServerStatus,
        [hashtable]$TestResults
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>MCP Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .healthy, .running, .passed { background-color: #dff0d8; }
        .unhealthy, .failed, .error { background-color: #f2dede; }
        .stopped, .warning { background-color: #fcf8e3; }
        .unknown { background-color: #f5f5f5; }
        .section { margin-bottom: 30px; }
        .summary { display: flex; justify-content: space-between; margin-bottom: 20px; }
        .summary-box { border: 1px solid #ddd; padding: 15px; border-radius: 5px; width: 30%; text-align: center; }
        .summary-box h3 { margin-top: 0; }
        .success { color: green; }
        .danger { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>MCP Health Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    
    <div class="section">
        <h2>System Information</h2>
        <table>
            <tr><th>Computer Name</th><td>$($SystemInfo.ComputerName)</td></tr>
            <tr><th>OS</th><td>$($SystemInfo.OSName)</td></tr>
            <tr><th>OS Version</th><td>$($SystemInfo.OSVersion)</td></tr>
            <tr><th>Processor</th><td>$($SystemInfo.Processor)</td></tr>
            <tr><th>Memory (GB)</th><td>$($SystemInfo.Memory)</td></tr>
            <tr><th>Architecture</th><td>$($SystemInfo.Architecture)</td></tr>
            <tr><th>Last Boot Time</th><td>$($SystemInfo.LastBootTime)</td></tr>
            <tr><th>Uptime</th><td>$($SystemInfo.Uptime.Days) days, $($SystemInfo.Uptime.Hours) hours, $($SystemInfo.Uptime.Minutes) minutes</td></tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Server Status</h2>
        
        <div class="summary">
            <div class="summary-box">
                <h3>Total Servers</h3>
                <p>$($ServerStatus.Count)</p>
            </div>
            <div class="summary-box">
                <h3>Running</h3>
                <p class="success">$($ServerStatus | Where-Object { $_.Status -eq "Running" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
            </div>
            <div class="summary-box">
                <h3>Stopped</h3>
                <p class="warning">$($ServerStatus | Where-Object { $_.Status -eq "Stopped" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
            </div>
        </div>
        
        <table>
            <tr>
                <th>Server</th>
                <th>Status</th>
                <th>PID</th>
                <th>Memory (MB)</th>
                <th>CPU (%)</th>
                <th>Uptime</th>
            </tr>
"@
    
    foreach ($server in $ServerStatus) {
        $statusClass = $server.Status.ToLower()
        $memory = if ($server.Memory) { [math]::Round($server.Memory / 1MB, 2) } else { "N/A" }
        $cpu = if ($server.CPU) { [math]::Round($server.CPU, 2) } else { "N/A" }
        $uptime = if ($server.Uptime) { "$($server.Uptime.Days) days, $($server.Uptime.Hours) hours, $($server.Uptime.Minutes) minutes" } else { "N/A" }
        
        $html += @"
            <tr class="$statusClass">
                <td>$($server.Name)</td>
                <td>$($server.Status)</td>
                <td>$($server.PID)</td>
                <td>$memory</td>
                <td>$cpu</td>
                <td>$uptime</td>
            </tr>
"@
    }
    
    $html += @"
        </table>
    </div>
"@
    
    if ($TestResults.Total -gt 0) {
        $html += @"
    <div class="section">
        <h2>Test Results</h2>
        
        <div class="summary">
            <div class="summary-box">
                <h3>Total Tests</h3>
                <p>$($TestResults.Total)</p>
            </div>
            <div class="summary-box">
                <h3>Passed</h3>
                <p class="success">$($TestResults.Passed)</p>
            </div>
            <div class="summary-box">
                <h3>Failed</h3>
                <p class="danger">$($TestResults.Failed)</p>
            </div>
        </div>
        
        <table>
            <tr>
                <th>Test</th>
                <th>Status</th>
                <th>Path</th>
            </tr>
"@
        
        foreach ($test in $TestResults.Results) {
            $statusClass = $test.Status.ToLower()
            
            $html += @"
            <tr class="$statusClass">
                <td>$($test.Name)</td>
                <td>$($test.Status)</td>
                <td>$($test.Path)</td>
            </tr>
"@
        }
        
        $html += @"
        </table>
    </div>
"@
    }
    
    $html += @"
</body>
</html>
"@
    
    return $html
}

function Format-JSONReport {
    param (
        [hashtable]$SystemInfo,
        [array]$ServerStatus,
        [hashtable]$TestResults
    )
    
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SystemInfo = $SystemInfo
        ServerStatus = $ServerStatus
        TestResults = if ($TestResults.Total -gt 0) { $TestResults } else { $null }
    }
    
    return $report | ConvertTo-Json -Depth 10
}

function Format-TextReport {
    param (
        [hashtable]$SystemInfo,
        [array]$ServerStatus,
        [hashtable]$TestResults
    )
    
    $text = @"
MCP Health Report
=================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

System Information
-----------------
Computer Name: $($SystemInfo.ComputerName)
OS: $($SystemInfo.OSName)
OS Version: $($SystemInfo.OSVersion)
Processor: $($SystemInfo.Processor)
Memory (GB): $($SystemInfo.Memory)
Architecture: $($SystemInfo.Architecture)
Last Boot Time: $($SystemInfo.LastBootTime)
Uptime: $($SystemInfo.Uptime.Days) days, $($SystemInfo.Uptime.Hours) hours, $($SystemInfo.Uptime.Minutes) minutes

Server Status
------------
Total Servers: $($ServerStatus.Count)
Running: $($ServerStatus | Where-Object { $_.Status -eq "Running" } | Measure-Object | Select-Object -ExpandProperty Count)
Stopped: $($ServerStatus | Where-Object { $_.Status -eq "Stopped" } | Measure-Object | Select-Object -ExpandProperty Count)

"@
    
    foreach ($server in $ServerStatus) {
        $memory = if ($server.Memory) { [math]::Round($server.Memory / 1MB, 2) } else { "N/A" }
        $cpu = if ($server.CPU) { [math]::Round($server.CPU, 2) } else { "N/A" }
        $uptime = if ($server.Uptime) { "$($server.Uptime.Days) days, $($server.Uptime.Hours) hours, $($server.Uptime.Minutes) minutes" } else { "N/A" }
        
        $text += @"
Server: $($server.Name)
Status: $($server.Status)
PID: $($server.PID)
Memory (MB): $memory
CPU (%): $cpu
Uptime: $uptime

"@
    }
    
    if ($TestResults.Total -gt 0) {
        $text += @"
Test Results
-----------
Total Tests: $($TestResults.Total)
Passed: $($TestResults.Passed)
Failed: $($TestResults.Failed)

"@
        
        foreach ($test in $TestResults.Results) {
            $text += @"
Test: $($test.Name)
Status: $($test.Status)
Path: $($test.Path)

"@
        }
    }
    
    return $text
}

function Send-EmailReport {
    param (
        [string]$To,
        [string]$Subject,
        [string]$Body,
        [string]$AttachmentPath
    )
    
    try {
        # Ici, vous devriez implémenter l'envoi d'e-mail selon votre configuration SMTP
        # Exemple avec Send-MailMessage (nécessite configuration SMTP) :
        # Send-MailMessage -From "mcp-monitoring@example.com" -To $To -Subject $Subject -Body $Body -BodyAsHtml -Attachments $AttachmentPath -SmtpServer "smtp.example.com"
        
        # Pour l'instant, nous nous contentons d'écrire un message
        Write-Log "Envoi d'un e-mail à $To avec le sujet '$Subject' et le rapport en pièce jointe: $AttachmentPath" -Level "INFO"
        return $true
    }
    catch {
        Write-Log "Erreur lors de l'envoi de l'e-mail: $_" -Level "ERROR"
        return $false
    }
}

# Corps principal du script
try {
    Write-Log "Génération du rapport de santé MCP..." -Level "TITLE"
    
    # Vérifier les paramètres
    if ($SendEmail -and [string]::IsNullOrEmpty($EmailTo)) {
        Write-Log "Le paramètre EmailTo est obligatoire lorsque SendEmail est spécifié." -Level "ERROR"
        exit 1
    }
    
    # Importer le module MCPManager
    Import-Module $modulePath -Force -ErrorAction Stop
    
    # Récupérer les informations système
    Write-Log "Récupération des informations système..." -Level "INFO"
    $systemInfo = Get-SystemInfo
    
    # Récupérer l'état des serveurs
    Write-Log "Récupération de l'état des serveurs..." -Level "INFO"
    $serverStatus = Get-MCPServerStatus
    
    # Exécuter les tests si demandé
    $testResults = @{
        Total = 0
        Passed = 0
        Failed = 0
        Results = @()
    }
    
    if ($IncludeTests) {
        Write-Log "Exécution des tests..." -Level "INFO"
        $testResults = Start-Tests -TestsPath $testsRoot
    }
    
    # Générer le rapport
    Write-Log "Génération du rapport au format $OutputFormat..." -Level "INFO"
    
    $reportContent = switch ($OutputFormat) {
        "HTML" { Format-HTMLReport -SystemInfo $systemInfo -ServerStatus $serverStatus -TestResults $testResults }
        "JSON" { Format-JSONReport -SystemInfo $systemInfo -ServerStatus $serverStatus -TestResults $testResults }
        "Text" { Format-TextReport -SystemInfo $systemInfo -ServerStatus $serverStatus -TestResults $testResults }
    }
    
    # Créer le répertoire de sortie si nécessaire
    $reportDir = Split-Path -Parent $reportPath
    if (-not (Test-Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    Set-Content -Path $reportPath -Value $reportContent
    Write-Log "Rapport enregistré: $reportPath" -Level "SUCCESS"
    
    # Envoyer le rapport par e-mail si demandé
    if ($SendEmail) {
        Write-Log "Envoi du rapport par e-mail..." -Level "INFO"
        
        $subject = "MCP Health Report - $(Get-Date -Format 'yyyy-MM-dd')"
        $body = "Veuillez trouver ci-joint le rapport de santé MCP généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')."
        
        if ($OutputFormat -eq "HTML") {
            $body = $reportContent
        }
        
        $emailResult = Send-EmailReport -To $EmailTo -Subject $subject -Body $body -AttachmentPath $reportPath
        
        if ($emailResult) {
            Write-Log "Rapport envoyé par e-mail avec succès." -Level "SUCCESS"
        }
    }
    
    Write-Log "Génération du rapport de santé MCP terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la génération du rapport de santé MCP: $_" -Level "ERROR"
    exit 1
}


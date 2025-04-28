function Test-ProcessRunning {
    param (
        [string]$processName
    )
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    return $null -ne $process
}

function Test-Port {
    param (
        [string]$serviceName,
        [int]$port
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $result = $tcpClient.ConnectAsync("127.0.0.1", $port).Wait(1000)
        $tcpClient.Close()
        return $result
    } catch {
        return $false
    }
}

function Write-ServiceStatus {
    param (
        [string]$serviceName,
        [string]$processName,
        [int]$port,
        [string]$configPath
    )
    
    Write-Host "`nDiagnostic pour $serviceName :" -ForegroundColor Cyan
    
    # Vérifier le processus
    $processRunning = Test-ProcessRunning -processName $processName
    Write-Host "- Processus ($processName): " -NoNewline
    if ($processRunning) {
        Write-Host "EN COURS" -ForegroundColor Green
    } else {
        Write-Host "ARRÊTÉ" -ForegroundColor Red
    }
    
    # Vérifier le port
    Write-Host "- Port ($port): " -NoNewline
    if (Test-Port -serviceName $serviceName -port $port) {
        Write-Host "ACCESSIBLE" -ForegroundColor Green
    } else {
        Write-Host "INACCESSIBLE" -ForegroundColor Red
    }
    
    # Vérifier la configuration
    Write-Host "- Fichier de configuration: " -NoNewline
    if (Test-Path $configPath) {
        Write-Host "PRÉSENT" -ForegroundColor Green
    } else {
        Write-Host "MANQUANT" -ForegroundColor Red
    }
}

# Diagnostic pour chaque service
Write-ServiceStatus -serviceName "N8N" -processName "n8n" -port 5678 -configPath "src\n8n\config\n8n-local.json"
Write-ServiceStatus -serviceName "MCP Proxy" -processName "mcp" -port 4000 -configPath "src\mcp\config\default.json"
Write-ServiceStatus -serviceName "Augment Service" -processName "augment" -port 3000 -configPath "src\augment\config\local.json"

# Afficher les processus en cours sur les ports
Write-Host "`nProcessus écoutant sur les ports :" -ForegroundColor Cyan
netstat -ano | findstr "LISTENING" | findstr ":5678 :4000 :3000"
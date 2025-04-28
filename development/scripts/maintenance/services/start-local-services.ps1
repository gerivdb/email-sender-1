function Start-ServiceWithRetry {
    param (
        [string]$serviceName,
        [string]$scriptPath,
        [int]$port,
        [int]$maxRetries = 3
    )

    Write-Host "Démarrage de $serviceName..." -ForegroundColor Cyan

    for ($i = 1; $i -le $maxRetries; $i++) {
        # Arrêter tout processus existant sur le port
        $existingProcess = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($existingProcess) {
            $processId = $existingProcess.OwningProcess
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }

        # Démarrer le service
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $scriptPath -NoNewWindow

        # Attendre que le service soit prêt
        $ready = $false
        $attempts = 0
        while (-not $ready -and $attempts -lt 10) {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $ready = $tcpClient.ConnectAsync("127.0.0.1", $port).Wait(1000)
                $tcpClient.Close()
            } catch {
                Start-Sleep -Seconds 1
                $attempts++
            }
        }

        if ($ready) {
            Write-Host "✓ $serviceName démarré avec succès (port $port)" -ForegroundColor Green
            return $true
        }

        Write-Host "Tentative $i/$maxRetries échouée pour $serviceName" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }

    Write-Host "✗ Échec du démarrage de $serviceName après $maxRetries tentatives" -ForegroundColor Red
    return $false
}

# Démarrer les services
$n8nSuccess = Start-ServiceWithRetry -serviceName "N8N" -scriptPath "src\n8n\scripts\deployment\start-n8n-local.cmd" -port 5678
$mcpSuccess = Start-ServiceWithRetry -serviceName "MCP Proxy" -scriptPath "src\mcp\scripts\start-mcp-local.cmd" -port 4000
$augmentSuccess = Start-ServiceWithRetry -serviceName "Augment Service" -scriptPath "src\augment\scripts\start-augment-local.cmd" -port 3000

# Vérifier l'état final
Write-Host "`nÉtat final des services :" -ForegroundColor Cyan
. '.\development\tools\scripts\check-services.ps1'

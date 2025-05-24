function Test-ServiceStatus {
    param (
        [string]$serviceName,
        [int]$port
    )
    
    Write-Host "`nVÃ©rification de $serviceName sur le port $port..." -ForegroundColor Cyan
    
    # VÃ©rifier si le port est en Ã©coute
    $listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    
    if ($listening) {
        Write-Host "âœ“ $serviceName est en cours d'exÃ©cution sur le port $port" -ForegroundColor Green
        
        # VÃ©rifier l'adresse d'Ã©coute
        $address = $listening.LocalAddress
        if ($address -eq "127.0.0.1") {
            Write-Host "âœ“ Ã‰coute correctement sur l'adresse locale" -ForegroundColor Green
        } else {
            Write-Host "âš  ATTENTION: Ã‰coute sur $address au lieu de 127.0.0.1" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âœ— $serviceName n'est pas en cours d'exÃ©cution sur le port $port" -ForegroundColor Red
    }
}

# VÃ©rifier chaque service
Test-ServiceStatus -serviceName "N8N" -port 5678
Test-ServiceStatus -serviceName "MCP Proxy" -port 4000
Test-ServiceStatus -serviceName "Augment Service" -port 3000


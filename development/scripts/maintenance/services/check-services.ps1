function Check-ServiceStatus {
    param (
        [string]$serviceName,
        [int]$port
    )
    
    Write-Host "`nVérification de $serviceName sur le port $port..." -ForegroundColor Cyan
    
    # Vérifier si le port est en écoute
    $listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    
    if ($listening) {
        Write-Host "✓ $serviceName est en cours d'exécution sur le port $port" -ForegroundColor Green
        
        # Vérifier l'adresse d'écoute
        $address = $listening.LocalAddress
        if ($address -eq "127.0.0.1") {
            Write-Host "✓ Écoute correctement sur l'adresse locale" -ForegroundColor Green
        } else {
            Write-Host "⚠ ATTENTION: Écoute sur $address au lieu de 127.0.0.1" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ $serviceName n'est pas en cours d'exécution sur le port $port" -ForegroundColor Red
    }
}

# Vérifier chaque service
Check-ServiceStatus -serviceName "N8N" -port 5678
Check-ServiceStatus -serviceName "MCP Proxy" -port 4000
Check-ServiceStatus -serviceName "Augment Service" -port 3000

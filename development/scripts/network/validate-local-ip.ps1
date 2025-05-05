function Test-LocalConnection {
    # VÃ©rifier que les services utilisent bien l'adresse locale
    $services = @(
        @{Name="N8N"; Port=5678},
        @{Name="MCP Proxy"; Port=4000},
        @{Name="Augment Service"; Port=3000}
    )

    foreach ($service in $services) {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        try {
            # Tester uniquement sur 127.0.0.1
            $result = $tcpClient.ConnectAsync("127.0.0.1", $service.Port).Wait(1000)
            if ($result) {
                Write-Host "$($service.Name) est bien configurÃ© sur l'adresse locale (Port: $($service.Port))" -ForegroundColor Green
            } else {
                Write-Host "$($service.Name) n'est pas accessible sur l'adresse locale (Port: $($service.Port))" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "$($service.Name) n'est pas accessible sur l'adresse locale (Port: $($service.Port))" -ForegroundColor Red
        }
        finally {
            $tcpClient.Dispose()
        }
    }

    # VÃ©rifier qu'aucun service n'Ã©coute sur 0.0.0.0
    $netstat = netstat -an | Select-String "LISTENING"
    foreach ($service in $services) {
        if ($netstat | Select-String ":$($service.Port).*0.0.0.0") {
            Write-Host "ATTENTION: $($service.Name) Ã©coute toujours sur toutes les interfaces (0.0.0.0)" -ForegroundColor Yellow
        }
    }
}

Test-LocalConnection
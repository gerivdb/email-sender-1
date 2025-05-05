function Get-LocalIP {
    # Obtenir l'adresse IP locale (IPv4 uniquement, en excluant les adresses spÃ©ciales)
    $localIP = (Get-NetIPAddress | Where-Object { 
        $_.AddressFamily -eq "IPv4" -and 
        $_.PrefixOrigin -ne "WellKnown" 
    } | Select-Object -First 1).IPAddress

    if ($localIP) {
        Write-Host "Adresse IP locale : $localIP"
        return $localIP
    } else {
        Write-Error "Impossible de dÃ©terminer l'adresse IP locale"
        return $null
    }
}

# Appeler la fonction
Get-LocalIP
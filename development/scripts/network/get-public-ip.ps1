function Get-PublicIP {
    [CmdletBinding()]
    param(
        [switch]$IncludeVPNCheck,
        [switch]$ShowDetails
    )

    # Liste des services avec prioritÃ© sur ceux supportant IPv6
    $ipServices = @(
        @{
            Uri = "https://api64.ipify.org?format=json"
            Pattern = "ip"
            IPv6 = $true
            JsonResponse = $true
        },
        @{
            Uri = "https://api.ipify.org?format=text"
            Pattern = $null
            IPv6 = $false
            JsonResponse = $false
        },
        @{
            Uri = "https://ipinfo.io/ip"
            Pattern = $null
            IPv6 = $true
            JsonResponse = $false
        }
    )

    $results = @()

    foreach ($service in $ipServices) {
        try {
            if ($service.JsonResponse) {
                $response = Invoke-RestMethod -Uri $service.Uri -Method Get -TimeoutSec 10
                $ip = $response.$($service.Pattern)
            } else {
                $ip = Invoke-RestMethod -Uri $service.Uri -Method Get -TimeoutSec 10
            }

            if ($ip -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$|^(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}$") {
                $results += $ip
                if ($ShowDetails) {
                    Write-Verbose "Service $($service.Uri) : $ip"
                }
            }
        }
        catch {
            if ($ShowDetails) {
                Write-Warning "Ã‰chec du service $($service.Uri) : $_"
            }
            continue
        }
    }

    # VÃ©rifier si une IP apparaÃ®t le plus souvent (consensus)
    if ($results.Count -gt 0) {
        $consensusIP = $results | Group-Object | Sort-Object Count -Descending | Select-Object -First 1 | Select-Object -ExpandProperty Name
    }
    else {
        Write-Warning "Aucune IP n'a pu Ãªtre rÃ©cupÃ©rÃ©e"
        return
    }

    $vpnDetected = $false
    $vpnScore = 0
    $location = "Non disponible"
    $isp = "Non disponible"
    $vpnIndicators = @()

    if ($IncludeVPNCheck) {
        try {
            # Check avec ip-api.com (service gratuit supportant IPv6)
            $ipApiResponse = Invoke-RestMethod -Uri "http://ip-api.com/json/$consensusIP" -TimeoutSec 10
            if ($ipApiResponse.status -eq "success") {
                $location = "$($ipApiResponse.city), $($ipApiResponse.regionName), $($ipApiResponse.countryCode)"
                $isp = $ipApiResponse.isp

                $vpnIndicators += @{
                    Source = "ip-api.com"
                    Checks = @(
                        @{Name = "Proxy"; Value = $ipApiResponse.proxy},
                        @{Name = "Hosting"; Value = $ipApiResponse.hosting},
                        @{Name = "ISP Pattern"; Value = $ipApiResponse.isp -match "VPN|OpenVPN|hosting|cloud|proxy|tunnel|vpn|private|anonymous"}
                    )
                }
            }
        }
        catch {
            if ($ShowDetails) {
                Write-Warning "Erreur lors de la vÃ©rification VPN avec ip-api.com : $_"
            }
        }

        # Calculer le score VPN
        $totalChecks = 0
        $positiveChecks = 0
        foreach ($indicator in $vpnIndicators) {
            foreach ($check in $indicator.Checks) {
                $totalChecks++
                if ($check.Value -eq $true) {
                    $positiveChecks++
                }
            }
        }

        if ($totalChecks -gt 0) {
            $vpnScore = [math]::Round(($positiveChecks / $totalChecks) * 100)
            $vpnDetected = $vpnScore -gt 30
        }
    }

    # Retourner les rÃ©sultats
    return [PSCustomObject]@{
        IP = $consensusIP
        VPNDetected = $vpnDetected
        VPNScore = $vpnScore
        Location = $location
        ISP = $isp
        Details = if ($ShowDetails) {
            $vpnIndicators | ForEach-Object {
                [PSCustomObject]@{
                    Source = $_.Source
                    Checks = $_.Checks
                }
            }
        } else { $null }
    }
}

# Exemple d'utilisation
$ipInfo = Get-PublicIP -IncludeVPNCheck -ShowDetails
Write-Host "`nRÃ©sultats:" -ForegroundColor Cyan
Write-Host "IP Publique     : $($ipInfo.IP)"
Write-Host "VPN DÃ©tectÃ©     : $($ipInfo.VPNDetected) (Score: $($ipInfo.VPNScore)%)"
Write-Host "Localisation    : $($ipInfo.Location)"
Write-Host "Fournisseur     : $($ipInfo.ISP)"

if ($ipInfo.Details) {
    Write-Host "`nDÃ©tails des vÃ©rifications:" -ForegroundColor Yellow
    foreach ($detail in $ipInfo.Details) {
        Write-Host "$($detail.Source):"
        foreach ($check in $detail.Checks) {
            Write-Host "  - $($check.Name): $($check.Value)"
        }
    }
}



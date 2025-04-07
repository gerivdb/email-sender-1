# Script pour sécuriser les communications réseau

# Importer le module de sécurisation des entrées
$inputSanitizerPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "InputSanitizer.ps1"
if (Test-Path -Path $inputSanitizerPath) {
    . $inputSanitizerPath
}
else {
    Write-Error "Le module de sécurisation des entrées est introuvable: $inputSanitizerPath"
    return
}

# Fonction pour effectuer une requête web sécurisée
function Invoke-SecureWebRequest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS")]
        [string]$Method = "GET",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory = $false)]
        [object]$Body,
        
        [Parameter(Mandatory = $false)]
        [string]$OutFile,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedDomains = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowInsecure,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30
    )
    
    # Vérifier si l'URL est sécurisée
    if (-not (Test-SafeUrl -Url $Uri -AllowedDomains $AllowedDomains)) {
        throw "URL non sécurisée: $Uri"
    }
    
    # Vérifier si le protocole est sécurisé
    $uriObj = [System.Uri]$Uri
    if ($uriObj.Scheme -ne "https" -and -not $AllowInsecure) {
        throw "Protocole non sécurisé: $($uriObj.Scheme). Utilisez HTTPS ou spécifiez -AllowInsecure."
    }
    
    # Vérifier le fichier de sortie si spécifié
    if (-not [string]::IsNullOrEmpty($OutFile)) {
        $outFileDir = Split-Path -Path $OutFile -Parent
        if (-not [string]::IsNullOrEmpty($outFileDir) -and -not (Test-Path -Path $outFileDir -PathType Container)) {
            New-Item -Path $outFileDir -ItemType Directory -Force | Out-Null
        }
    }
    
    # Configurer les paramètres de la requête
    $params = @{
        Uri = $Uri
        Method = $Method
        Headers = $Headers
        TimeoutSec = $TimeoutSeconds
    }
    
    # Ajouter le corps si spécifié
    if ($null -ne $Body) {
        $params.Body = $Body
    }
    
    # Ajouter le fichier de sortie si spécifié
    if (-not [string]::IsNullOrEmpty($OutFile)) {
        $params.OutFile = $OutFile
    }
    
    # Ajouter UseBasicParsing pour les anciennes versions de PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $params.UseBasicParsing = $true
    }
    
    # Effectuer la requête
    try {
        $response = Invoke-WebRequest @params
        return $response
    }
    catch {
        throw "Erreur lors de la requête web: $_"
    }
}

# Fonction pour valider un certificat SSL
function Test-SSLCertificate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Hostname,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 443,
        
        [Parameter(Mandatory = $false)]
        [int]$MinimumDaysValid = 30
    )
    
    try {
        # Créer une connexion TCP
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($Hostname, $Port)
        
        # Créer un flux SSL
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, {
            param($sender, $certificate, $chain, $sslPolicyErrors)
            return $true
        })
        
        # Authentifier en tant que client
        $sslStream.AuthenticateAsClient($Hostname)
        
        # Obtenir le certificat
        $certificate = $sslStream.RemoteCertificate
        
        # Fermer les connexions
        $sslStream.Close()
        $tcpClient.Close()
        
        # Convertir en certificat X509
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$certificate
        
        # Vérifier la validité du certificat
        $now = [System.DateTime]::Now
        $expirationDate = $cert.NotAfter
        $daysUntilExpiration = ($expirationDate - $now).Days
        
        # Créer l'objet résultat
        $result = [PSCustomObject]@{
            Hostname = $Hostname
            Port = $Port
            Subject = $cert.Subject
            Issuer = $cert.Issuer
            ValidFrom = $cert.NotBefore
            ValidTo = $cert.NotAfter
            DaysUntilExpiration = $daysUntilExpiration
            IsValid = $now -ge $cert.NotBefore -and $now -le $cert.NotAfter
            HasSufficientValidity = $daysUntilExpiration -ge $MinimumDaysValid
            Thumbprint = $cert.Thumbprint
        }
        
        return $result
    }
    catch {
        throw "Erreur lors de la vérification du certificat SSL: $_"
    }
}

# Fonction pour tester la connectivité réseau de manière sécurisée
function Test-SecureNetworkConnectivity {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Target,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 1000,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedTargets = @()
    )
    
    # Vérifier si la cible est autorisée
    if ($AllowedTargets.Count -gt 0) {
        $isAllowed = $false
        foreach ($allowedTarget in $AllowedTargets) {
            if ($Target -eq $allowedTarget -or $Target.EndsWith(".$allowedTarget")) {
                $isAllowed = $true
                break
            }
        }
        
        if (-not $isAllowed) {
            throw "Cible non autorisée: $Target"
        }
    }
    
    # Déterminer si la cible est une URL ou une adresse IP/nom d'hôte
    $isUrl = $Target -match '^(http|https)://'
    
    if ($isUrl) {
        # C'est une URL, utiliser Invoke-WebRequest
        try {
            $params = @{
                Uri = $Target
                Method = "HEAD"
                TimeoutSec = $TimeoutMilliseconds / 1000
            }
            
            # Ajouter UseBasicParsing pour les anciennes versions de PowerShell
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $params.UseBasicParsing = $true
            }
            
            $response = Invoke-WebRequest @params
            
            return [PSCustomObject]@{
                Target = $Target
                IsReachable = $true
                ResponseTime = $response.BaseResponse.ResponseTime
                StatusCode = $response.StatusCode
                StatusDescription = $response.StatusDescription
            }
        }
        catch {
            return [PSCustomObject]@{
                Target = $Target
                IsReachable = $false
                ResponseTime = 0
                StatusCode = 0
                StatusDescription = $_.Exception.Message
            }
        }
    }
    else {
        # C'est une adresse IP ou un nom d'hôte
        if ($Port -eq 0) {
            # Utiliser Test-Connection (ping)
            try {
                $result = Test-Connection -ComputerName $Target -Count 1 -Quiet -TimeoutSeconds ($TimeoutMilliseconds / 1000)
                
                return [PSCustomObject]@{
                    Target = $Target
                    IsReachable = $result
                    ResponseTime = if ($result) { (Test-Connection -ComputerName $Target -Count 1).ResponseTime } else { 0 }
                    StatusCode = $null
                    StatusDescription = if ($result) { "Ping successful" } else { "Ping failed" }
                }
            }
            catch {
                return [PSCustomObject]@{
                    Target = $Target
                    IsReachable = $false
                    ResponseTime = 0
                    StatusCode = $null
                    StatusDescription = $_.Exception.Message
                }
            }
        }
        else {
            # Tester la connectivité TCP
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $connectionTask = $tcpClient.ConnectAsync($Target, $Port)
                
                # Attendre la connexion avec timeout
                $connectionTask.Wait($TimeoutMilliseconds)
                
                $isConnected = $tcpClient.Connected
                $tcpClient.Close()
                
                return [PSCustomObject]@{
                    Target = $Target
                    Port = $Port
                    IsReachable = $isConnected
                    ResponseTime = 0
                    StatusCode = $null
                    StatusDescription = if ($isConnected) { "TCP connection successful" } else { "TCP connection failed" }
                }
            }
            catch {
                return [PSCustomObject]@{
                    Target = $Target
                    Port = $Port
                    IsReachable = $false
                    ResponseTime = 0
                    StatusCode = $null
                    StatusDescription = $_.Exception.Message
                }
            }
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-SecureWebRequest, Test-SSLCertificate, Test-SecureNetworkConnectivity

<#
.SYNOPSIS
    Gestionnaire d'authentification pour le partage des vues.

.DESCRIPTION
    Ce module implémente le gestionnaire d'authentification qui permet de sécuriser
    l'accès aux vues partagées à l'aide de différentes méthodes d'authentification.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module de chiffrement
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$encryptionManagerPath = Join-Path -Path $scriptDir -ChildPath "EncryptionManager.ps1"

if (Test-Path -Path $encryptionManagerPath) {
    . $encryptionManagerPath
}
else {
    throw "Le module EncryptionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $encryptionManagerPath"
}

# Classe pour représenter le gestionnaire d'authentification
class AuthenticationManager {
    # Propriétés
    [hashtable]$AuthMethods
    [string]$UserStorePath
    [bool]$EnableDebug

    # Constructeur par défaut
    AuthenticationManager() {
        $this.AuthMethods = @{
            "PASSWORD" = @{
                AuthFunction = { param($credentials, $storedCredentials) return $this.AuthenticatePassword($credentials, $storedCredentials) }
                Description = "Authentification par mot de passe"
            }
            "TOKEN" = @{
                AuthFunction = { param($token, $storedTokens) return $this.AuthenticateToken($token, $storedTokens) }
                Description = "Authentification par token"
            }
            "CERTIFICATE" = @{
                AuthFunction = { param($certificate, $storedCertificates) return $this.AuthenticateCertificate($certificate, $storedCertificates) }
                Description = "Authentification par certificat"
            }
        }
        $this.UserStorePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing\UserStore"
        $this.EnableDebug = $false
    }

    # Constructeur avec paramètres
    AuthenticationManager([string]$userStorePath, [bool]$enableDebug) {
        $this.AuthMethods = @{
            "PASSWORD" = @{
                AuthFunction = { param($credentials, $storedCredentials) return $this.AuthenticatePassword($credentials, $storedCredentials) }
                Description = "Authentification par mot de passe"
            }
            "TOKEN" = @{
                AuthFunction = { param($token, $storedTokens) return $this.AuthenticateToken($token, $storedTokens) }
                Description = "Authentification par token"
            }
            "CERTIFICATE" = @{
                AuthFunction = { param($certificate, $storedCertificates) return $this.AuthenticateCertificate($certificate, $storedCertificates) }
                Description = "Authentification par certificat"
            }
        }
        $this.UserStorePath = $userStorePath
        $this.EnableDebug = $enableDebug
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [AuthenticationManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour initialiser le stockage des utilisateurs
    [void] InitializeUserStore() {
        $this.WriteDebug("Initialisation du stockage des utilisateurs")
        
        try {
            # Créer le répertoire de stockage s'il n'existe pas
            if (-not (Test-Path -Path $this.UserStorePath)) {
                New-Item -Path $this.UserStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage créé: $($this.UserStorePath)")
            }
            
            # Créer les sous-répertoires pour chaque méthode d'authentification
            $passwordStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Passwords"
            $tokenStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Tokens"
            $certificateStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Certificates"
            
            if (-not (Test-Path -Path $passwordStorePath)) {
                New-Item -Path $passwordStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage des mots de passe créé: $passwordStorePath")
            }
            
            if (-not (Test-Path -Path $tokenStorePath)) {
                New-Item -Path $tokenStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage des tokens créé: $tokenStorePath")
            }
            
            if (-not (Test-Path -Path $certificateStorePath)) {
                New-Item -Path $certificateStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage des certificats créé: $certificateStorePath")
            }
            
            $this.WriteDebug("Initialisation du stockage des utilisateurs terminée")
        }
        catch {
            $this.WriteDebug("Erreur lors de l'initialisation du stockage des utilisateurs - $($_.Exception.Message)")
            throw "Erreur lors de l'initialisation du stockage des utilisateurs - $($_.Exception.Message)"
        }
    }

    # Méthode pour créer un utilisateur avec authentification par mot de passe
    [bool] CreatePasswordUser([string]$username, [string]$password) {
        $this.WriteDebug("Création d'un utilisateur avec authentification par mot de passe: $username")
        
        try {
            # Initialiser le stockage des utilisateurs si nécessaire
            $this.InitializeUserStore()
            
            # Vérifier si l'utilisateur existe déjà
            $passwordStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Passwords"
            $userFilePath = Join-Path -Path $passwordStorePath -ChildPath "$username.json"
            
            if (Test-Path -Path $userFilePath) {
                $this.WriteDebug("L'utilisateur $username existe déjà")
                return $false
            }
            
            # Générer un sel aléatoire
            $salt = New-Object byte[] 16
            $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
            $rng.GetBytes($salt)
            $saltBase64 = [Convert]::ToBase64String($salt)
            
            # Hacher le mot de passe avec le sel
            $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
            $combinedBytes = $passwordBytes + $salt
            
            $sha256 = [System.Security.Cryptography.SHA256]::Create()
            $hashBytes = $sha256.ComputeHash($combinedBytes)
            $hashBase64 = [Convert]::ToBase64String($hashBytes)
            
            # Créer l'objet utilisateur
            $user = @{
                Username = $username
                PasswordHash = $hashBase64
                Salt = $saltBase64
                CreatedAt = (Get-Date).ToString('o')
                LastModified = (Get-Date).ToString('o')
            }
            
            # Enregistrer l'utilisateur
            $userJson = $user | ConvertTo-Json
            $userJson | Out-File -FilePath $userFilePath -Encoding utf8
            
            $this.WriteDebug("Utilisateur $username créé avec succès")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de la création de l'utilisateur - $($_.Exception.Message)")
            throw "Erreur lors de la création de l'utilisateur $username - $($_.Exception.Message)"
        }
    }

    # Méthode pour authentifier un utilisateur avec mot de passe
    [bool] AuthenticatePassword([PSObject]$credentials, [PSObject]$storedCredentials) {
        $this.WriteDebug("Authentification par mot de passe pour l'utilisateur: $($credentials.Username)")
        
        try {
            # Extraire les informations d'authentification
            $username = $credentials.Username
            $password = $credentials.Password
            
            # Si les informations stockées ne sont pas fournies, les charger depuis le stockage
            if ($null -eq $storedCredentials) {
                $passwordStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Passwords"
                $userFilePath = Join-Path -Path $passwordStorePath -ChildPath "$username.json"
                
                if (-not (Test-Path -Path $userFilePath)) {
                    $this.WriteDebug("L'utilisateur $username n'existe pas")
                    return $false
                }
                
                $userJson = Get-Content -Path $userFilePath -Raw
                $storedCredentials = $userJson | ConvertFrom-Json
            }
            
            # Extraire le sel et le hachage stockés
            $salt = [Convert]::FromBase64String($storedCredentials.Salt)
            $storedHash = [Convert]::FromBase64String($storedCredentials.PasswordHash)
            
            # Hacher le mot de passe fourni avec le même sel
            $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
            $combinedBytes = $passwordBytes + $salt
            
            $sha256 = [System.Security.Cryptography.SHA256]::Create()
            $hashBytes = $sha256.ComputeHash($combinedBytes)
            
            # Comparer les hachages
            if ($hashBytes.Length -ne $storedHash.Length) {
                $this.WriteDebug("Échec de l'authentification: longueur de hachage différente")
                return $false
            }
            
            for ($i = 0; $i -lt $hashBytes.Length; $i++) {
                if ($hashBytes[$i] -ne $storedHash[$i]) {
                    $this.WriteDebug("Échec de l'authentification: hachage différent")
                    return $false
                }
            }
            
            $this.WriteDebug("Authentification réussie pour l'utilisateur $username")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de l'authentification - $($_.Exception.Message)")
            throw "Erreur lors de l'authentification de l'utilisateur $($credentials.Username) - $($_.Exception.Message)"
        }
    }

    # Méthode pour générer un token d'authentification
    [PSObject] GenerateToken([string]$username, [int]$expirationMinutes = 60) {
        $this.WriteDebug("Génération d'un token pour l'utilisateur: $username")
        
        try {
            # Générer un token aléatoire
            $tokenBytes = New-Object byte[] 32
            $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
            $rng.GetBytes($tokenBytes)
            $tokenBase64 = [Convert]::ToBase64String($tokenBytes)
            
            # Calculer la date d'expiration
            $createdAt = Get-Date
            $expiresAt = $createdAt.AddMinutes($expirationMinutes)
            
            # Créer l'objet token
            $token = [PSCustomObject]@{
                Username = $username
                Token = $tokenBase64
                CreatedAt = $createdAt.ToString('o')
                ExpiresAt = $expiresAt.ToString('o')
            }
            
            # Enregistrer le token
            $this.SaveToken($token)
            
            $this.WriteDebug("Token généré avec succès pour l'utilisateur $username")
            return $token
        }
        catch {
            $this.WriteDebug("Erreur lors de la génération du token - $($_.Exception.Message)")
            throw "Erreur lors de la génération du token pour l'utilisateur $username - $($_.Exception.Message)"
        }
    }

    # Méthode pour enregistrer un token
    [void] SaveToken([PSObject]$token) {
        $this.WriteDebug("Enregistrement du token pour l'utilisateur: $($token.Username)")
        
        try {
            # Initialiser le stockage des utilisateurs si nécessaire
            $this.InitializeUserStore()
            
            # Préparer le chemin de stockage
            $tokenStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Tokens"
            $userTokensPath = Join-Path -Path $tokenStorePath -ChildPath "$($token.Username).json"
            
            # Charger les tokens existants ou créer une nouvelle liste
            $tokens = @()
            
            if (Test-Path -Path $userTokensPath) {
                $tokensJson = Get-Content -Path $userTokensPath -Raw
                $tokens = $tokensJson | ConvertFrom-Json
                
                # Convertir en tableau si ce n'est pas déjà le cas
                if ($tokens -isnot [array]) {
                    $tokens = @($tokens)
                }
            }
            
            # Ajouter le nouveau token
            $tokens += $token
            
            # Enregistrer la liste mise à jour
            $tokensJson = $tokens | ConvertTo-Json
            $tokensJson | Out-File -FilePath $userTokensPath -Encoding utf8
            
            $this.WriteDebug("Token enregistré avec succès pour l'utilisateur $($token.Username)")
        }
        catch {
            $this.WriteDebug("Erreur lors de l'enregistrement du token - $($_.Exception.Message)")
            throw "Erreur lors de l'enregistrement du token pour l'utilisateur $($token.Username) - $($_.Exception.Message)"
        }
    }

    # Méthode pour authentifier un token
    [bool] AuthenticateToken([string]$token, [array]$storedTokens) {
        $this.WriteDebug("Authentification par token")
        
        try {
            # Si les tokens stockés ne sont pas fournis, les charger depuis le stockage
            if ($null -eq $storedTokens -or $storedTokens.Count -eq 0) {
                $tokenStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Tokens"
                
                # Parcourir tous les fichiers de tokens
                $tokenFiles = Get-ChildItem -Path $tokenStorePath -Filter "*.json" -ErrorAction SilentlyContinue
                
                foreach ($file in $tokenFiles) {
                    $tokensJson = Get-Content -Path $file.FullName -Raw
                    $userTokens = $tokensJson | ConvertFrom-Json
                    
                    # Convertir en tableau si ce n'est pas déjà le cas
                    if ($userTokens -isnot [array]) {
                        $userTokens = @($userTokens)
                    }
                    
                    # Vérifier chaque token
                    foreach ($storedToken in $userTokens) {
                        if ($storedToken.Token -eq $token) {
                            # Vérifier si le token n'est pas expiré
                            $expiresAt = [datetime]::Parse($storedToken.ExpiresAt)
                            
                            if ($expiresAt -gt (Get-Date)) {
                                $this.WriteDebug("Token valide trouvé pour l'utilisateur $($storedToken.Username)")
                                return $true
                            }
                            else {
                                $this.WriteDebug("Token expiré trouvé pour l'utilisateur $($storedToken.Username)")
                                return $false
                            }
                        }
                    }
                }
                
                $this.WriteDebug("Aucun token correspondant trouvé")
                return $false
            }
            else {
                # Vérifier dans les tokens fournis
                foreach ($storedToken in $storedTokens) {
                    if ($storedToken.Token -eq $token) {
                        # Vérifier si le token n'est pas expiré
                        $expiresAt = [datetime]::Parse($storedToken.ExpiresAt)
                        
                        if ($expiresAt -gt (Get-Date)) {
                            $this.WriteDebug("Token valide trouvé pour l'utilisateur $($storedToken.Username)")
                            return $true
                        }
                        else {
                            $this.WriteDebug("Token expiré trouvé pour l'utilisateur $($storedToken.Username)")
                            return $false
                        }
                    }
                }
                
                $this.WriteDebug("Aucun token correspondant trouvé dans les tokens fournis")
                return $false
            }
        }
        catch {
            $this.WriteDebug("Erreur lors de l'authentification par token - $($_.Exception.Message)")
            throw "Erreur lors de l'authentification par token - $($_.Exception.Message)"
        }
    }

    # Méthode pour révoquer un token
    [bool] RevokeToken([string]$token, [string]$username) {
        $this.WriteDebug("Révocation du token pour l'utilisateur: $username")
        
        try {
            # Préparer le chemin de stockage
            $tokenStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Tokens"
            $userTokensPath = Join-Path -Path $tokenStorePath -ChildPath "$username.json"
            
            # Vérifier si le fichier de tokens existe
            if (-not (Test-Path -Path $userTokensPath)) {
                $this.WriteDebug("Aucun token trouvé pour l'utilisateur $username")
                return $false
            }
            
            # Charger les tokens existants
            $tokensJson = Get-Content -Path $userTokensPath -Raw
            $tokens = $tokensJson | ConvertFrom-Json
            
            # Convertir en tableau si ce n'est pas déjà le cas
            if ($tokens -isnot [array]) {
                $tokens = @($tokens)
            }
            
            # Rechercher et supprimer le token
            $newTokens = @()
            $tokenFound = $false
            
            foreach ($storedToken in $tokens) {
                if ($storedToken.Token -ne $token) {
                    $newTokens += $storedToken
                }
                else {
                    $tokenFound = $true
                }
            }
            
            # Si le token a été trouvé, enregistrer la liste mise à jour
            if ($tokenFound) {
                if ($newTokens.Count -gt 0) {
                    $newTokensJson = $newTokens | ConvertTo-Json
                    $newTokensJson | Out-File -FilePath $userTokensPath -Encoding utf8
                }
                else {
                    # Si plus aucun token, supprimer le fichier
                    Remove-Item -Path $userTokensPath -Force
                }
                
                $this.WriteDebug("Token révoqué avec succès pour l'utilisateur $username")
                return $true
            }
            else {
                $this.WriteDebug("Token non trouvé pour l'utilisateur $username")
                return $false
            }
        }
        catch {
            $this.WriteDebug("Erreur lors de la révocation du token - $($_.Exception.Message)")
            throw "Erreur lors de la révocation du token pour l'utilisateur $username - $($_.Exception.Message)"
        }
    }

    # Méthode pour importer un certificat
    [bool] ImportCertificate([string]$username, [string]$certificatePath, [string]$password = $null) {
        $this.WriteDebug("Importation du certificat pour l'utilisateur: $username")
        
        try {
            # Initialiser le stockage des utilisateurs si nécessaire
            $this.InitializeUserStore()
            
            # Vérifier si le certificat existe
            if (-not (Test-Path -Path $certificatePath)) {
                $this.WriteDebug("Le certificat spécifié n'existe pas: $certificatePath")
                return $false
            }
            
            # Charger le certificat
            $cert = $null
            
            if ([string]::IsNullOrEmpty($password)) {
                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificatePath)
            }
            else {
                $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificatePath, $securePassword)
            }
            
            # Extraire les informations du certificat
            $thumbprint = $cert.Thumbprint
            $subject = $cert.Subject
            $issuer = $cert.Issuer
            $notBefore = $cert.NotBefore.ToString('o')
            $notAfter = $cert.NotAfter.ToString('o')
            $publicKey = [Convert]::ToBase64String($cert.GetPublicKey())
            
            # Créer l'objet certificat
            $certificate = @{
                Username = $username
                Thumbprint = $thumbprint
                Subject = $subject
                Issuer = $issuer
                NotBefore = $notBefore
                NotAfter = $notAfter
                PublicKey = $publicKey
                ImportedAt = (Get-Date).ToString('o')
            }
            
            # Enregistrer le certificat
            $certificateStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Certificates"
            $userCertificatePath = Join-Path -Path $certificateStorePath -ChildPath "$username.json"
            
            $certificateJson = $certificate | ConvertTo-Json
            $certificateJson | Out-File -FilePath $userCertificatePath -Encoding utf8
            
            $this.WriteDebug("Certificat importé avec succès pour l'utilisateur $username")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de l'importation du certificat - $($_.Exception.Message)")
            throw "Erreur lors de l'importation du certificat pour l'utilisateur $username - $($_.Exception.Message)"
        }
    }

    # Méthode pour authentifier un certificat
    [bool] AuthenticateCertificate([PSObject]$certificate, [PSObject]$storedCertificate) {
        $this.WriteDebug("Authentification par certificat pour l'utilisateur: $($certificate.Username)")
        
        try {
            # Extraire les informations d'authentification
            $username = $certificate.Username
            $thumbprint = $certificate.Thumbprint
            
            # Si le certificat stocké n'est pas fourni, le charger depuis le stockage
            if ($null -eq $storedCertificate) {
                $certificateStorePath = Join-Path -Path $this.UserStorePath -ChildPath "Certificates"
                $userCertificatePath = Join-Path -Path $certificateStorePath -ChildPath "$username.json"
                
                if (-not (Test-Path -Path $userCertificatePath)) {
                    $this.WriteDebug("Aucun certificat trouvé pour l'utilisateur $username")
                    return $false
                }
                
                $certificateJson = Get-Content -Path $userCertificatePath -Raw
                $storedCertificate = $certificateJson | ConvertFrom-Json
            }
            
            # Vérifier si le certificat correspond
            if ($storedCertificate.Thumbprint -ne $thumbprint) {
                $this.WriteDebug("Le certificat ne correspond pas pour l'utilisateur $username")
                return $false
            }
            
            # Vérifier si le certificat n'est pas expiré
            $notAfter = [datetime]::Parse($storedCertificate.NotAfter)
            $notBefore = [datetime]::Parse($storedCertificate.NotBefore)
            $now = Get-Date
            
            if ($now -lt $notBefore -or $now -gt $notAfter) {
                $this.WriteDebug("Le certificat est expiré ou pas encore valide pour l'utilisateur $username")
                return $false
            }
            
            $this.WriteDebug("Authentification par certificat réussie pour l'utilisateur $username")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de l'authentification par certificat - $($_.Exception.Message)")
            throw "Erreur lors de l'authentification par certificat pour l'utilisateur $($certificate.Username) - $($_.Exception.Message)"
        }
    }

    # Méthode pour authentifier un utilisateur
    [bool] Authenticate([string]$method, [PSObject]$credentials, [PSObject]$storedCredentials = $null) {
        $this.WriteDebug("Authentification avec la méthode $method")
        
        # Vérifier si la méthode est supportée
        if (-not $this.AuthMethods.ContainsKey($method)) {
            throw "Méthode d'authentification non supportée: $method"
        }
        
        # Appliquer la méthode d'authentification
        $authFunction = $this.AuthMethods[$method].AuthFunction
        return & $authFunction $credentials $storedCredentials
    }
}

# Fonction pour créer un nouveau gestionnaire d'authentification
function New-AuthenticationManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$UserStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\UserStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    return [AuthenticationManager]::new($UserStorePath, $EnableDebug)
}

# Fonction pour créer un utilisateur avec authentification par mot de passe
function New-PasswordUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $true)]
        [string]$Password,
        
        [Parameter(Mandatory = $false)]
        [string]$UserStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\UserStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-AuthenticationManager -UserStorePath $UserStorePath -EnableDebug:$EnableDebug
    return $manager.CreatePasswordUser($Username, $Password)
}

# Fonction pour authentifier un utilisateur
function Test-UserAuthentication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("PASSWORD", "TOKEN", "CERTIFICATE")]
        [string]$Method,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Credentials,
        
        [Parameter(Mandatory = $false)]
        [PSObject]$StoredCredentials = $null,
        
        [Parameter(Mandatory = $false)]
        [string]$UserStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\UserStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-AuthenticationManager -UserStorePath $UserStorePath -EnableDebug:$EnableDebug
    return $manager.Authenticate($Method, $Credentials, $StoredCredentials)
}

# Fonction pour générer un token d'authentification
function New-AuthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [int]$ExpirationMinutes = 60,
        
        [Parameter(Mandatory = $false)]
        [string]$UserStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\UserStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-AuthenticationManager -UserStorePath $UserStorePath -EnableDebug:$EnableDebug
    return $manager.GenerateToken($Username, $ExpirationMinutes)
}

# Fonction pour révoquer un token d'authentification
function Revoke-AuthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [string]$UserStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\UserStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-AuthenticationManager -UserStorePath $UserStorePath -EnableDebug:$EnableDebug
    return $manager.RevokeToken($Token, $Username)
}

# Fonction pour importer un certificat
function Import-AuthCertificate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificatePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Password,
        
        [Parameter(Mandatory = $false)]
        [string]$UserStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\UserStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-AuthenticationManager -UserStorePath $UserStorePath -EnableDebug:$EnableDebug
    return $manager.ImportCertificate($Username, $CertificatePath, $Password)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-AuthenticationManager, New-PasswordUser, Test-UserAuthentication, New-AuthToken, Revoke-AuthToken, Import-AuthCertificate

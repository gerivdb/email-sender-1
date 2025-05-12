# Enable-MultiFactorAuth.ps1
# Module pour l'authentification multi-facteurs
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour l'authentification multi-facteurs.

.DESCRIPTION
    Ce module fournit des fonctions pour l'authentification multi-facteurs,
    notamment la génération de codes TOTP, la vérification des codes et la gestion des appareils.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.Web

# Fonction pour générer une clé secrète TOTP
function New-TOTPSecret {
    <#
    .SYNOPSIS
        Génère une nouvelle clé secrète pour TOTP (Time-based One-Time Password).

    .DESCRIPTION
        Cette fonction génère une nouvelle clé secrète aléatoire pour TOTP
        qui peut être utilisée pour configurer l'authentification à deux facteurs.

    .PARAMETER SecretLength
        La longueur de la clé secrète en octets.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la clé secrète.
        Si non spécifié, la clé est retournée mais non sauvegardée.

    .PARAMETER UserId
        L'identifiant de l'utilisateur associé à cette clé.

    .PARAMETER AppName
        Le nom de l'application à afficher dans l'application d'authentification.

    .EXAMPLE
        New-TOTPSecret -SecretLength 20 -OutputPath "C:\Keys\totp-secret.json" -UserId "john.doe" -AppName "Roadmap Manager"
        Génère une clé secrète TOTP et la sauvegarde dans un fichier.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SecretLength = 20,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$UserId = "",

        [Parameter(Mandatory = $false)]
        [string]$AppName = "Roadmap Manager"
    )

    try {
        # Générer une clé secrète aléatoire
        $SecureRandom = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $SecretBytes = New-Object byte[] $SecretLength
        $SecureRandom.GetBytes($SecretBytes)
        
        # Convertir la clé en Base32
        $Base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        $Base32Secret = ""
        $Bits = 0
        $BitsCount = 0
        
        foreach ($Byte in $SecretBytes) {
            $Bits = ($Bits -shl 8) -bor $Byte
            $BitsCount += 8
            
            while ($BitsCount -ge 5) {
                $BitsCount -= 5
                $Base32Secret += $Base32Chars[($Bits -shr $BitsCount) -band 0x1F]
            }
        }
        
        if ($BitsCount -gt 0) {
            $Base32Secret += $Base32Chars[($Bits -shl (5 - $BitsCount)) -band 0x1F]
        }
        
        # Créer l'objet de clé secrète
        $Secret = [PSCustomObject]@{
            Secret = $Base32Secret
            SecretBytes = $SecretBytes
            UserId = $UserId
            AppName = $AppName
            CreationDate = Get-Date
            Algorithm = "SHA1"
            Digits = 6
            Period = 30
        }
        
        # Générer l'URL pour le QR code
        $Label = if ([string]::IsNullOrEmpty($UserId)) { $AppName } else { "$AppName`:$UserId" }
        $Parameters = "secret=$Base32Secret&issuer=$([System.Web.HttpUtility]::UrlEncode($AppName))&algorithm=$($Secret.Algorithm)&digits=$($Secret.Digits)&period=$($Secret.Period)"
        $Secret | Add-Member -MemberType NoteProperty -Name "OtpAuthUrl" -Value "otpauth://totp/$([System.Web.HttpUtility]::UrlEncode($Label))?$Parameters"
        
        # Sauvegarder la clé secrète si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $OutputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $OutputDir)) {
                New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
            }
            
            # Convertir la clé secrète en JSON
            $SecretJson = [PSCustomObject]@{
                Secret = $Base32Secret
                UserId = $UserId
                AppName = $AppName
                CreationDate = $Secret.CreationDate.ToString("o")
                Algorithm = $Secret.Algorithm
                Digits = $Secret.Digits
                Period = $Secret.Period
                OtpAuthUrl = $Secret.OtpAuthUrl
            } | ConvertTo-Json
            
            # Sauvegarder la clé secrète
            $SecretJson | Out-File -FilePath $OutputPath -Encoding UTF8
            
            Write-Host "Clé secrète TOTP sauvegardée dans: $OutputPath" -ForegroundColor Green
        }
        
        return $Secret
    } catch {
        Write-Error "Échec de la génération de la clé secrète TOTP: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour charger une clé secrète TOTP
function Get-TOTPSecret {
    <#
    .SYNOPSIS
        Charge une clé secrète TOTP à partir d'un fichier.

    .DESCRIPTION
        Cette fonction charge une clé secrète TOTP à partir d'un fichier JSON.

    .PARAMETER SecretPath
        Le chemin vers le fichier de clé secrète.

    .EXAMPLE
        Get-TOTPSecret -SecretPath "C:\Keys\totp-secret.json"
        Charge une clé secrète TOTP à partir d'un fichier.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SecretPath
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path $SecretPath)) {
            Write-Error "Le fichier de clé secrète n'existe pas: $SecretPath"
            return $null
        }
        
        # Charger la clé secrète
        $SecretJson = Get-Content -Path $SecretPath -Raw | ConvertFrom-Json
        
        # Convertir la clé Base32 en octets
        $Base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        $Base32Secret = $SecretJson.Secret
        $SecretBytes = New-Object System.Collections.ArrayList
        
        $Bits = 0
        $BitsCount = 0
        
        foreach ($Char in $Base32Secret.ToUpper().ToCharArray()) {
            $Value = $Base32Chars.IndexOf($Char)
            if ($Value -eq -1) {
                continue
            }
            
            $Bits = ($Bits -shl 5) -bor $Value
            $BitsCount += 5
            
            if ($BitsCount -ge 8) {
                $BitsCount -= 8
                $SecretBytes.Add([byte](($Bits -shr $BitsCount) -band 0xFF)) | Out-Null
            }
        }
        
        # Créer l'objet de clé secrète
        $Secret = [PSCustomObject]@{
            Secret = $SecretJson.Secret
            SecretBytes = $SecretBytes.ToArray()
            UserId = $SecretJson.UserId
            AppName = $SecretJson.AppName
            CreationDate = [DateTime]::Parse($SecretJson.CreationDate)
            Algorithm = $SecretJson.Algorithm
            Digits = $SecretJson.Digits
            Period = $SecretJson.Period
            OtpAuthUrl = $SecretJson.OtpAuthUrl
        }
        
        return $Secret
    } catch {
        Write-Error "Échec du chargement de la clé secrète TOTP: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour générer un code TOTP
function Get-TOTPCode {
    <#
    .SYNOPSIS
        Génère un code TOTP (Time-based One-Time Password).

    .DESCRIPTION
        Cette fonction génère un code TOTP à partir d'une clé secrète.

    .PARAMETER Secret
        La clé secrète TOTP.
        Peut être générée avec New-TOTPSecret ou chargée avec Get-TOTPSecret.

    .PARAMETER Time
        L'horodatage à utiliser pour générer le code.
        Si non spécifié, l'heure actuelle est utilisée.

    .EXAMPLE
        Get-TOTPCode -Secret $secret
        Génère un code TOTP à partir d'une clé secrète.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Secret,

        [Parameter(Mandatory = $false)]
        [DateTime]$Time = (Get-Date)
    )

    try {
        # Calculer le compteur basé sur le temps
        $Epoch = New-Object DateTime(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
        $TimeCounter = [Math]::Floor(($Time.ToUniversalTime() - $Epoch).TotalSeconds / $Secret.Period)
        
        # Convertir le compteur en octets (big-endian)
        $TimeBytes = New-Object byte[] 8
        for ($i = 7; $i -ge 0; $i--) {
            $TimeBytes[$i] = $TimeCounter -band 0xFF
            $TimeCounter = $TimeCounter -shr 8
        }
        
        # Créer l'objet HMAC
        $HMAC = $null
        switch ($Secret.Algorithm) {
            "SHA1" { $HMAC = New-Object System.Security.Cryptography.HMACSHA1 }
            "SHA256" { $HMAC = New-Object System.Security.Cryptography.HMACSHA256 }
            "SHA512" { $HMAC = New-Object System.Security.Cryptography.HMACSHA512 }
            default { $HMAC = New-Object System.Security.Cryptography.HMACSHA1 }
        }
        
        $HMAC.Key = $Secret.SecretBytes
        
        # Calculer le hachage
        $Hash = $HMAC.ComputeHash($TimeBytes)
        
        # Extraire le code
        $Offset = $Hash[$Hash.Length - 1] -band 0x0F
        $Code = (($Hash[$Offset] -band 0x7F) -shl 24) -bor
                (($Hash[$Offset + 1] -band 0xFF) -shl 16) -bor
                (($Hash[$Offset + 2] -band 0xFF) -shl 8) -bor
                ($Hash[$Offset + 3] -band 0xFF)
        
        # Tronquer le code au nombre de chiffres spécifié
        $Code = $Code % [Math]::Pow(10, $Secret.Digits)
        
        # Formater le code avec des zéros en tête si nécessaire
        return $Code.ToString("D$($Secret.Digits)")
    } catch {
        Write-Error "Échec de la génération du code TOTP: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour vérifier un code TOTP
function Test-TOTPCode {
    <#
    .SYNOPSIS
        Vérifie un code TOTP (Time-based One-Time Password).

    .DESCRIPTION
        Cette fonction vérifie si un code TOTP est valide pour une clé secrète donnée.

    .PARAMETER Secret
        La clé secrète TOTP.
        Peut être générée avec New-TOTPSecret ou chargée avec Get-TOTPSecret.

    .PARAMETER Code
        Le code TOTP à vérifier.

    .PARAMETER WindowSize
        Le nombre de périodes avant et après la période actuelle à vérifier.
        Par défaut, une période avant et après est vérifiée.

    .EXAMPLE
        Test-TOTPCode -Secret $secret -Code "123456" -WindowSize 1
        Vérifie si le code TOTP est valide.

    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Secret,

        [Parameter(Mandatory = $true)]
        [string]$Code,

        [Parameter(Mandatory = $false)]
        [int]$WindowSize = 1
    )

    try {
        # Vérifier que le code a le bon format
        if ($Code.Length -ne $Secret.Digits -or -not ($Code -match "^\d+$")) {
            return $false
        }
        
        # Obtenir l'heure actuelle
        $Now = Get-Date
        
        # Vérifier le code pour chaque période dans la fenêtre
        for ($i = -$WindowSize; $i -le $WindowSize; $i++) {
            $Time = $Now.AddSeconds($i * $Secret.Period)
            $ExpectedCode = Get-TOTPCode -Secret $Secret -Time $Time
            
            if ($ExpectedCode -eq $Code) {
                return $true
            }
        }
        
        return $false
    } catch {
        Write-Error "Échec de la vérification du code TOTP: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour générer un QR code pour TOTP
function New-TOTPQRCode {
    <#
    .SYNOPSIS
        Génère un QR code pour configurer TOTP dans une application d'authentification.

    .DESCRIPTION
        Cette fonction génère un QR code pour configurer TOTP dans une application d'authentification
        comme Google Authenticator, Microsoft Authenticator, Authy, etc.

    .PARAMETER Secret
        La clé secrète TOTP.
        Peut être générée avec New-TOTPSecret ou chargée avec Get-TOTPSecret.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le QR code.
        Si non spécifié, le QR code est affiché dans le navigateur.

    .PARAMETER Size
        La taille du QR code en pixels.

    .EXAMPLE
        New-TOTPQRCode -Secret $secret -OutputPath "C:\QRCodes\totp-qrcode.png" -Size 300
        Génère un QR code pour configurer TOTP et le sauvegarde dans un fichier.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Secret,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [int]$Size = 300
    )

    try {
        # Encoder l'URL pour le QR code
        $EncodedUrl = [System.Web.HttpUtility]::UrlEncode($Secret.OtpAuthUrl)
        
        # Construire l'URL du service de génération de QR code
        $QRCodeUrl = "https://chart.googleapis.com/chart?cht=qr&chs=${Size}x${Size}&chl=$EncodedUrl"
        
        # Sauvegarder le QR code si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $OutputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $OutputDir)) {
                New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
            }
            
            # Télécharger le QR code
            Invoke-WebRequest -Uri $QRCodeUrl -OutFile $OutputPath
            
            Write-Host "QR code sauvegardé dans: $OutputPath" -ForegroundColor Green
        } else {
            # Afficher le QR code dans le navigateur
            Start-Process $QRCodeUrl
        }
        
        # Créer l'objet de résultat
        $Result = [PSCustomObject]@{
            Secret = $Secret.Secret
            UserId = $Secret.UserId
            AppName = $Secret.AppName
            QRCodeUrl = $QRCodeUrl
            OutputPath = $OutputPath
        }
        
        return $Result
    } catch {
        Write-Error "Échec de la génération du QR code: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour enregistrer un appareil pour l'authentification multi-facteurs
function Register-MFADevice {
    <#
    .SYNOPSIS
        Enregistre un appareil pour l'authentification multi-facteurs.

    .DESCRIPTION
        Cette fonction enregistre un appareil pour l'authentification multi-facteurs
        en générant une clé secrète TOTP et en l'associant à un utilisateur et un appareil.

    .PARAMETER UserId
        L'identifiant de l'utilisateur.

    .PARAMETER DeviceName
        Le nom de l'appareil.

    .PARAMETER AppName
        Le nom de l'application à afficher dans l'application d'authentification.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les informations d'enregistrement.

    .PARAMETER GenerateQRCode
        Indique si un QR code doit être généré pour configurer l'application d'authentification.

    .PARAMETER QRCodePath
        Le chemin où sauvegarder le QR code.
        Si non spécifié, le QR code est affiché dans le navigateur.

    .EXAMPLE
        Register-MFADevice -UserId "john.doe" -DeviceName "Smartphone" -AppName "Roadmap Manager" -OutputPath "C:\MFA\john.doe.json" -GenerateQRCode -QRCodePath "C:\MFA\john.doe.png"
        Enregistre un appareil pour l'authentification multi-facteurs et génère un QR code.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [string]$DeviceName,

        [Parameter(Mandatory = $false)]
        [string]$AppName = "Roadmap Manager",

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateQRCode,

        [Parameter(Mandatory = $false)]
        [string]$QRCodePath = ""
    )

    try {
        # Générer une clé secrète TOTP
        $Secret = New-TOTPSecret -UserId $UserId -AppName $AppName
        
        if ($null -eq $Secret) {
            Write-Error "Échec de la génération de la clé secrète TOTP."
            return $null
        }
        
        # Créer l'objet d'enregistrement
        $Registration = [PSCustomObject]@{
            UserId = $UserId
            DeviceName = $DeviceName
            AppName = $AppName
            Secret = $Secret.Secret
            Algorithm = $Secret.Algorithm
            Digits = $Secret.Digits
            Period = $Secret.Period
            OtpAuthUrl = $Secret.OtpAuthUrl
            RegistrationDate = Get-Date
            LastUsed = $null
            Enabled = $true
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder l'enregistrement
        $RegistrationJson = $Registration | ConvertTo-Json
        $RegistrationJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "Appareil enregistré pour l'authentification multi-facteurs: $OutputPath" -ForegroundColor Green
        
        # Générer un QR code si demandé
        if ($GenerateQRCode) {
            $QRCode = New-TOTPQRCode -Secret $Secret -OutputPath $QRCodePath
            
            if ($null -ne $QRCode) {
                $Registration | Add-Member -MemberType NoteProperty -Name "QRCodeUrl" -Value $QRCode.QRCodeUrl
                $Registration | Add-Member -MemberType NoteProperty -Name "QRCodePath" -Value $QRCode.OutputPath
            }
        }
        
        return $Registration
    } catch {
        Write-Error "Échec de l'enregistrement de l'appareil: $($_.Exception.Message)"
        return $null
    }
}

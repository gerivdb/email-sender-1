#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'utilitaires de chiffrement pour sÃ©curiser les donnÃ©es.
.DESCRIPTION
    Ce module fournit des fonctions pour chiffrer et dÃ©chiffrer des donnÃ©es,
    ainsi que pour sÃ©curiser les fichiers contenant des informations sensibles.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Initialiser les paramÃ¨tres de chiffrement
$script:EncryptionConfig = @{
    KeySize       = 256
    BlockSize     = 128
    Iterations    = 10000
    HashAlgorithm = "SHA256"
}

# Fonction pour gÃ©nÃ©rer une clÃ© de chiffrement
function New-EncryptionKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [string]$Salt = "EMAIL_SENDER_1_Salt",

        [Parameter(Mandatory = $false)]
        [int]$KeySize = $script:EncryptionConfig.KeySize,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = $script:EncryptionConfig.Iterations,

        [Parameter(Mandatory = $false)]
        [string]$HashAlgorithm = $script:EncryptionConfig.HashAlgorithm,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile
    )

    # Si aucun mot de passe n'est fourni, en gÃ©nÃ©rer un alÃ©atoire
    if ($null -eq $Password) {
        $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $bytes = New-Object byte[] 32
        $rng.GetBytes($bytes)
        $passwordString = [Convert]::ToBase64String($bytes)
    } else {
        # Convertir SecureString en String
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        $passwordString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }

    # Convertir le sel en tableau d'octets
    $saltBytes = [System.Text.Encoding]::UTF8.GetBytes($Salt)

    # DÃ©river une clÃ© Ã  partir du mot de passe
    $deriveBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($passwordString, $saltBytes, $Iterations)

    # SÃ©curiser la mÃ©moire en effaÃ§ant le mot de passe en clair
    if ($passwordString) {
        $passwordString = $null
        [System.GC]::Collect()
    }
    $key = $deriveBytes.GetBytes($KeySize / 8)

    # CrÃ©er l'objet de clÃ©
    $encryptionKey = [PSCustomObject]@{
        Key           = $key
        KeyBase64     = [Convert]::ToBase64String($key)
        Salt          = $Salt
        SaltBase64    = [Convert]::ToBase64String($saltBytes)
        KeySize       = $KeySize
        Iterations    = $Iterations
        HashAlgorithm = $HashAlgorithm
    }

    # Enregistrer la clÃ© dans un fichier si demandÃ©
    if (-not [string]::IsNullOrEmpty($OutputFile)) {
        $keyJson = $encryptionKey | ConvertTo-Json
        $keyJson | Set-Content -Path $OutputFile -Encoding UTF8
    }

    return $encryptionKey
}

# Fonction pour chiffrer une chaÃ®ne de caractÃ¨res
function Protect-String {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputString,

        [Parameter(Mandatory = $true)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = $script:EncryptionConfig.BlockSize
    )

    try {
        # Convertir la chaÃ®ne en tableau d'octets
        $inputBytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)

        # CrÃ©er un vecteur d'initialisation alÃ©atoire
        $aes = New-Object System.Security.Cryptography.AesManaged
        $aes.KeySize = $EncryptionKey.KeySize
        $aes.BlockSize = $BlockSize
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $EncryptionKey.Key
        $aes.GenerateIV()
        $iv = $aes.IV

        # Chiffrer les donnÃ©es
        $encryptor = $aes.CreateEncryptor($aes.Key, $aes.IV)
        $memoryStream = New-Object System.IO.MemoryStream
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
        $cryptoStream.Write($inputBytes, 0, $inputBytes.Length)
        $cryptoStream.FlushFinalBlock()

        # Combiner le vecteur d'initialisation et les donnÃ©es chiffrÃ©es
        $encryptedBytes = $memoryStream.ToArray()
        $result = New-Object byte[] ($iv.Length + $encryptedBytes.Length)
        [System.Buffer]::BlockCopy($iv, 0, $result, 0, $iv.Length)
        [System.Buffer]::BlockCopy($encryptedBytes, 0, $result, $iv.Length, $encryptedBytes.Length)

        # Nettoyer les ressources
        $cryptoStream.Close()
        $memoryStream.Close()
        $aes.Clear()

        # Retourner le rÃ©sultat en Base64
        return [Convert]::ToBase64String($result)
    } catch {
        Write-Error "Erreur lors du chiffrement de la chaÃ®ne : $_"
        return $null
    }
}

# Fonction pour dÃ©chiffrer une chaÃ®ne de caractÃ¨res
function Unprotect-String {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$EncryptedString,

        [Parameter(Mandatory = $true)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = $script:EncryptionConfig.BlockSize
    )

    try {
        # Convertir la chaÃ®ne Base64 en tableau d'octets
        $encryptedBytes = [Convert]::FromBase64String($EncryptedString)

        # Extraire le vecteur d'initialisation
        $aes = New-Object System.Security.Cryptography.AesManaged
        $aes.KeySize = $EncryptionKey.KeySize
        $aes.BlockSize = $BlockSize
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $EncryptionKey.Key

        $ivLength = $aes.BlockSize / 8
        $iv = New-Object byte[] $ivLength
        [System.Buffer]::BlockCopy($encryptedBytes, 0, $iv, 0, $ivLength)
        $aes.IV = $iv

        # DÃ©chiffrer les donnÃ©es
        $encryptedData = New-Object byte[] ($encryptedBytes.Length - $ivLength)
        [System.Buffer]::BlockCopy($encryptedBytes, $ivLength, $encryptedData, 0, $encryptedData.Length)

        $decryptor = $aes.CreateDecryptor($aes.Key, $aes.IV)
        $memoryStream = New-Object System.IO.MemoryStream
        $memoryStream.Write($encryptedData, 0, $encryptedData.Length)
        $memoryStream.Position = 0

        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
        $decryptedStream = New-Object System.IO.MemoryStream

        $buffer = New-Object byte[] 4096
        $bytesRead = 0

        while (($bytesRead = $cryptoStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $decryptedStream.Write($buffer, 0, $bytesRead)
        }

        $decryptedBytes = $decryptedStream.ToArray()

        # Nettoyer les ressources
        $cryptoStream.Close()
        $memoryStream.Close()
        $decryptedStream.Close()
        $aes.Clear()

        # Retourner la chaÃ®ne dÃ©chiffrÃ©e
        return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
    } catch {
        Write-Error "Erreur lors du dÃ©chiffrement de la chaÃ®ne : $_"
        return $null
    }
}

# Fonction pour chiffrer un fichier
function Protect-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = $script:EncryptionConfig.BlockSize,

        [Parameter(Mandatory = $false)]
        [int]$BufferSize = 4096
    )

    try {
        # VÃ©rifier que le fichier d'entrÃ©e existe
        if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
            Write-Error "Le fichier d'entrÃ©e n'existe pas : $InputFile"
            return $false
        }

        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputFile
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # CrÃ©er un vecteur d'initialisation alÃ©atoire
        $aes = New-Object System.Security.Cryptography.AesManaged
        $aes.KeySize = $EncryptionKey.KeySize
        $aes.BlockSize = $BlockSize
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $EncryptionKey.Key
        $aes.GenerateIV()
        $iv = $aes.IV

        # Ouvrir les flux de fichiers
        $inputStream = [System.IO.File]::OpenRead($InputFile)
        $outputStream = [System.IO.File]::Create($OutputFile)

        # Ã‰crire le vecteur d'initialisation au dÃ©but du fichier
        $outputStream.Write($iv, 0, $iv.Length)

        # Chiffrer le fichier
        $encryptor = $aes.CreateEncryptor($aes.Key, $aes.IV)
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outputStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)

        $buffer = New-Object byte[] $BufferSize
        $bytesRead = 0

        while (($bytesRead = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $cryptoStream.Write($buffer, 0, $bytesRead)
        }

        # Nettoyer les ressources
        $cryptoStream.FlushFinalBlock()
        $cryptoStream.Close()
        $inputStream.Close()
        $outputStream.Close()
        $aes.Clear()

        return $true
    } catch {
        Write-Error "Erreur lors du chiffrement du fichier : $_"
        return $false
    }
}

# Fonction pour dÃ©chiffrer un fichier
function Unprotect-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = $script:EncryptionConfig.BlockSize,

        [Parameter(Mandatory = $false)]
        [int]$BufferSize = 4096
    )

    try {
        # VÃ©rifier que le fichier d'entrÃ©e existe
        if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
            Write-Error "Le fichier d'entrÃ©e n'existe pas : $InputFile"
            return $false
        }

        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputFile
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Ouvrir les flux de fichiers
        $inputStream = [System.IO.File]::OpenRead($InputFile)
        $outputStream = [System.IO.File]::Create($OutputFile)

        # Lire le vecteur d'initialisation au dÃ©but du fichier
        $aes = New-Object System.Security.Cryptography.AesManaged
        $aes.KeySize = $EncryptionKey.KeySize
        $aes.BlockSize = $BlockSize
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $EncryptionKey.Key

        $ivLength = $aes.BlockSize / 8
        $iv = New-Object byte[] $ivLength
        $inputStream.Read($iv, 0, $ivLength)
        $aes.IV = $iv

        # DÃ©chiffrer le fichier
        $decryptor = $aes.CreateDecryptor($aes.Key, $aes.IV)
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($inputStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)

        $buffer = New-Object byte[] $BufferSize
        $bytesRead = 0

        while (($bytesRead = $cryptoStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $outputStream.Write($buffer, 0, $bytesRead)
        }

        # Nettoyer les ressources
        $cryptoStream.Close()
        $inputStream.Close()
        $outputStream.Close()
        $aes.Clear()

        return $true
    } catch {
        Write-Error "Erreur lors du dÃ©chiffrement du fichier : $_"
        return $false
    }
}

# Fonction pour calculer le hachage d'un fichier
function Get-FileHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
        [string]$Algorithm = "SHA256",

        [Parameter(Mandatory = $false)]
        [int]$BufferSize = 4096
    )

    try {
        # VÃ©rifier que le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier n'existe pas : $FilePath"
            return $null
        }

        # CrÃ©er l'algorithme de hachage
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)

        # Ouvrir le fichier
        $stream = [System.IO.File]::OpenRead($FilePath)

        # Calculer le hachage
        $hashBytes = $hashAlgorithm.ComputeHash($stream)

        # Nettoyer les ressources
        $stream.Close()
        $hashAlgorithm.Clear()

        # Convertir le hachage en chaÃ®ne hexadÃ©cimale
        $hashString = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()

        return [PSCustomObject]@{
            FilePath  = $FilePath
            Algorithm = $Algorithm
            Hash      = $hashString
        }
    } catch {
        Write-Error "Erreur lors du calcul du hachage du fichier : $_"
        return $null
    }
}

# Fonction pour signer un fichier
function New-FileSignature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [string]$SignatureFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
        [string]$Algorithm = "SHA256"
    )

    try {
        # VÃ©rifier que le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier n'existe pas : $FilePath"
            return $null
        }

        # Calculer le hachage du fichier
        $fileHash = Get-FileHash -FilePath $FilePath -Algorithm $Algorithm

        # CrÃ©er la signature
        $signature = [PSCustomObject]@{
            FilePath  = $FilePath
            Algorithm = $Algorithm
            Hash      = $fileHash.Hash
            Timestamp = Get-Date -Format "o"
        }

        # Convertir la signature en JSON
        $signatureJson = $signature | ConvertTo-Json

        # Chiffrer la signature
        $encryptedSignature = Protect-String -InputString $signatureJson -EncryptionKey $EncryptionKey

        # Enregistrer la signature dans un fichier si demandÃ©
        if (-not [string]::IsNullOrEmpty($SignatureFile)) {
            $encryptedSignature | Set-Content -Path $SignatureFile -Encoding UTF8
        }

        return $encryptedSignature
    } catch {
        Write-Error "Erreur lors de la signature du fichier : $_"
        return $null
    }
}

# Fonction pour vÃ©rifier la signature d'un fichier
function Test-FileSignature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [object]$EncryptionKey,

        [Parameter(Mandatory = $true, ParameterSetName = "SignatureString")]
        [string]$Signature,

        [Parameter(Mandatory = $true, ParameterSetName = "SignatureFile")]
        [string]$SignatureFile
    )

    try {
        # VÃ©rifier que le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier n'existe pas : $FilePath"
            return $false
        }

        # Lire la signature
        if ($PSCmdlet.ParameterSetName -eq "SignatureFile") {
            if (-not (Test-Path -Path $SignatureFile -PathType Leaf)) {
                Write-Error "Le fichier de signature n'existe pas : $SignatureFile"
                return $false
            }

            $Signature = Get-Content -Path $SignatureFile -Raw
        }

        # DÃ©chiffrer la signature
        $signatureJson = Unprotect-String -EncryptedString $Signature -EncryptionKey $EncryptionKey

        if ([string]::IsNullOrEmpty($signatureJson)) {
            Write-Error "Impossible de dÃ©chiffrer la signature"
            return $false
        }

        # Convertir la signature JSON en objet
        $signatureObj = $signatureJson | ConvertFrom-Json

        # VÃ©rifier que la signature correspond au fichier
        if ($signatureObj.FilePath -ne $FilePath) {
            Write-Warning "Le chemin du fichier dans la signature ne correspond pas au fichier spÃ©cifiÃ©"
        }

        # Calculer le hachage actuel du fichier
        $currentHash = Get-FileHash -FilePath $FilePath -Algorithm $signatureObj.Algorithm

        # Comparer les hachages
        $isValid = $currentHash.Hash -eq $signatureObj.Hash

        return [PSCustomObject]@{
            IsValid            = $isValid
            FilePath           = $FilePath
            SignatureTimestamp = $signatureObj.Timestamp
            ExpectedHash       = $signatureObj.Hash
            CurrentHash        = $currentHash.Hash
            Algorithm          = $signatureObj.Algorithm
        }
    } catch {
        Write-Error "Erreur lors de la vÃ©rification de la signature du fichier : $_"
        return $false
    }
}

# Exporter les fonctions
# Export-ModuleMember est commentÃ© pour permettre le chargement direct du script


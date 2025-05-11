<#
.SYNOPSIS
    Gestionnaire de chiffrement pour le partage des vues.

.DESCRIPTION
    Ce module implémente le gestionnaire de chiffrement qui permet de sécuriser
    les données partagées à l'aide de différentes méthodes de chiffrement.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Classe pour représenter le gestionnaire de chiffrement
class EncryptionManager {
    # Propriétés
    [hashtable]$EncryptionMethods
    [bool]$EnableDebug

    # Constructeur par défaut
    EncryptionManager() {
        $this.EncryptionMethods = @{
            "AES" = @{
                EncryptFunction = { param($data, $key, $iv) return $this.EncryptAES($data, $key, $iv) }
                DecryptFunction = { param($encryptedData, $key, $iv) return $this.DecryptAES($encryptedData, $key, $iv) }
                Description     = "Chiffrement AES-256 (symétrique)"
                KeySize         = 256
                BlockSize       = 128
            }
            "RSA" = @{
                EncryptFunction = { param($data, $publicKey) return $this.EncryptRSA($data, $publicKey) }
                DecryptFunction = { param($encryptedData, $privateKey) return $this.DecryptRSA($encryptedData, $privateKey) }
                Description     = "Chiffrement RSA (asymétrique)"
                KeySize         = 2048
            }
        }
        $this.EnableDebug = $false
    }

    # Constructeur avec paramètres
    EncryptionManager([bool]$enableDebug) {
        $this.EncryptionMethods = @{
            "AES" = @{
                EncryptFunction = { param($data, $key, $iv) return $this.EncryptAES($data, $key, $iv) }
                DecryptFunction = { param($encryptedData, $key, $iv) return $this.DecryptAES($encryptedData, $key, $iv) }
                Description     = "Chiffrement AES-256 (symétrique)"
                KeySize         = 256
                BlockSize       = 128
            }
            "RSA" = @{
                EncryptFunction = { param($data, $publicKey) return $this.EncryptRSA($data, $publicKey) }
                DecryptFunction = { param($encryptedData, $privateKey) return $this.DecryptRSA($encryptedData, $privateKey) }
                Description     = "Chiffrement RSA (asymétrique)"
                KeySize         = 2048
            }
        }
        $this.EnableDebug = $enableDebug
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [EncryptionManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour générer une clé AES
    [PSObject] GenerateAESKey() {
        $this.WriteDebug("Génération d'une clé AES")

        try {
            $aes = [System.Security.Cryptography.Aes]::Create()
            $aes.KeySize = $this.EncryptionMethods["AES"].KeySize
            $aes.BlockSize = $this.EncryptionMethods["AES"].BlockSize
            $aes.GenerateKey()
            $aes.GenerateIV()

            $result = [PSCustomObject]@{
                Key       = $aes.Key
                IV        = $aes.IV
                KeyBase64 = [Convert]::ToBase64String($aes.Key)
                IVBase64  = [Convert]::ToBase64String($aes.IV)
            }

            $aes.Dispose()

            $this.WriteDebug("Clé AES générée avec succès")
            return $result
        } catch {
            $this.WriteDebug("Erreur lors de la génération de la clé AES - $($_.Exception.Message)")
            throw "Erreur lors de la génération de la clé AES - $($_.Exception.Message)"
        }
    }

    # Méthode pour chiffrer des données avec AES
    [byte[]] EncryptAES([byte[]]$data, [byte[]]$key, [byte[]]$iv) {
        $this.WriteDebug("Chiffrement AES de $($data.Length) octets")

        try {
            $aes = [System.Security.Cryptography.Aes]::Create()
            $aes.Key = $key
            $aes.IV = $iv
            $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
            $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

            $encryptor = $aes.CreateEncryptor()
            $outputStream = New-Object System.IO.MemoryStream
            $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outputStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)

            $cryptoStream.Write($data, 0, $data.Length)
            $cryptoStream.FlushFinalBlock()

            $encryptedData = $outputStream.ToArray()

            $cryptoStream.Close()
            $outputStream.Close()
            $aes.Dispose()

            $this.WriteDebug("Chiffrement AES terminé. Taille chiffrée: $($encryptedData.Length) octets")
            return $encryptedData
        } catch {
            $this.WriteDebug("Erreur lors du chiffrement AES - $($_.Exception.Message)")
            throw "Erreur lors du chiffrement AES - $($_.Exception.Message)"
        }
    }

    # Méthode pour déchiffrer des données avec AES
    [byte[]] DecryptAES([byte[]]$encryptedData, [byte[]]$key, [byte[]]$iv) {
        $this.WriteDebug("Déchiffrement AES de $($encryptedData.Length) octets")

        try {
            $aes = [System.Security.Cryptography.Aes]::Create()
            $aes.Key = $key
            $aes.IV = $iv
            $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
            $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

            $decryptor = $aes.CreateDecryptor()
            $inputStream = New-Object System.IO.MemoryStream
            $inputStream.Write($encryptedData, 0, $encryptedData.Length)
            $inputStream.Position = 0
            $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($inputStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
            $outputStream = New-Object System.IO.MemoryStream

            $buffer = New-Object byte[] 4096
            $bytesRead = 0

            while (($bytesRead = $cryptoStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $outputStream.Write($buffer, 0, $bytesRead)
            }

            $decryptedData = $outputStream.ToArray()

            $cryptoStream.Close()
            $inputStream.Close()
            $outputStream.Close()
            $aes.Dispose()

            $this.WriteDebug("Déchiffrement AES terminé. Taille déchiffrée: $($decryptedData.Length) octets")
            return $decryptedData
        } catch {
            $this.WriteDebug("Erreur lors du déchiffrement AES - $($_.Exception.Message)")
            throw "Erreur lors du déchiffrement AES - $($_.Exception.Message)"
        }
    }

    # Méthode pour générer une paire de clés RSA
    [PSObject] GenerateRSAKeyPair() {
        $this.WriteDebug("Génération d'une paire de clés RSA")

        try {
            # Utiliser une approche compatible avec PowerShell 5.1
            $cspParams = New-Object System.Security.Cryptography.CspParameters
            $cspParams.ProviderType = 1 # PROV_RSA_FULL
            $cspParams.KeyContainerName = "TempRSAKeyContainer_" + [Guid]::NewGuid().ToString()
            $cspParams.Flags = 1 # CspProviderFlags.UseMachineKeyStore

            $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider($this.EncryptionMethods["RSA"].KeySize, $cspParams)

            # Exporter les clés au format XML
            $privateKeyXml = $rsa.ToXmlString($true)  # Inclut la clé privée
            $publicKeyXml = $rsa.ToXmlString($false)  # Clé publique uniquement

            # Convertir en bytes pour la cohérence avec le reste du code
            $privateKeyBytes = [System.Text.Encoding]::UTF8.GetBytes($privateKeyXml)
            $publicKeyBytes = [System.Text.Encoding]::UTF8.GetBytes($publicKeyXml)

            $result = [PSCustomObject]@{
                PrivateKey       = $privateKeyBytes
                PublicKey        = $publicKeyBytes
                PrivateKeyBase64 = [Convert]::ToBase64String($privateKeyBytes)
                PublicKeyBase64  = [Convert]::ToBase64String($publicKeyBytes)
                PrivateKeyXml    = $privateKeyXml
                PublicKeyXml     = $publicKeyXml
            }

            # Nettoyer les ressources
            $rsa.Clear()

            $this.WriteDebug("Paire de clés RSA générée avec succès")
            return $result
        } catch {
            $this.WriteDebug("Erreur lors de la génération de la paire de clés RSA - $($_.Exception.Message)")
            throw "Erreur lors de la génération de la paire de clés RSA - $($_.Exception.Message)"
        }
    }

    # Méthode pour chiffrer des données avec RSA
    [byte[]] EncryptRSA([byte[]]$data, [byte[]]$publicKey) {
        $this.WriteDebug("Chiffrement RSA de $($data.Length) octets")

        try {
            $rsa = [System.Security.Cryptography.RSA]::Create()
            $rsa.ImportRSAPublicKey($publicKey, [ref]0)

            # RSA ne peut chiffrer que de petites quantités de données
            # Pour les données plus volumineuses, on utilise généralement un chiffrement hybride
            if ($data.Length -gt 190) {
                $this.WriteDebug("Les données sont trop volumineuses pour un chiffrement RSA direct. Utilisation d'un chiffrement hybride.")

                # Générer une clé AES aléatoire
                $aesKey = $this.GenerateAESKey()

                # Chiffrer les données avec AES
                $encryptedData = $this.EncryptAES($data, $aesKey.Key, $aesKey.IV)

                # Chiffrer la clé AES avec RSA
                $encryptedKey = $rsa.Encrypt($aesKey.Key, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)
                $encryptedIV = $rsa.Encrypt($aesKey.IV, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

                # Combiner les données chiffrées et les clés chiffrées
                $outputStream = New-Object System.IO.MemoryStream
                $writer = New-Object System.IO.BinaryWriter($outputStream)

                $writer.Write([byte]1) # Indicateur de chiffrement hybride
                $writer.Write([int]$encryptedKey.Length)
                $writer.Write($encryptedKey)
                $writer.Write([int]$encryptedIV.Length)
                $writer.Write($encryptedIV)
                $writer.Write([int]$encryptedData.Length)
                $writer.Write($encryptedData)

                $result = $outputStream.ToArray()

                $writer.Close()
                $outputStream.Close()

                $rsa.Dispose()

                $this.WriteDebug("Chiffrement RSA hybride terminé. Taille chiffrée: $($result.Length) octets")
                return $result
            } else {
                # Chiffrement RSA direct pour les petites données
                $encryptedData = $rsa.Encrypt($data, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

                $outputStream = New-Object System.IO.MemoryStream
                $writer = New-Object System.IO.BinaryWriter($outputStream)

                $writer.Write([byte]0) # Indicateur de chiffrement RSA direct
                $writer.Write([int]$encryptedData.Length)
                $writer.Write($encryptedData)

                $result = $outputStream.ToArray()

                $writer.Close()
                $outputStream.Close()

                $rsa.Dispose()

                $this.WriteDebug("Chiffrement RSA direct terminé. Taille chiffrée: $($result.Length) octets")
                return $result
            }
        } catch {
            $this.WriteDebug("Erreur lors du chiffrement RSA - $($_.Exception.Message)")
            throw "Erreur lors du chiffrement RSA - $($_.Exception.Message)"
        }
    }

    # Méthode pour déchiffrer des données avec RSA
    [byte[]] DecryptRSA([byte[]]$encryptedData, [byte[]]$privateKey) {
        $this.WriteDebug("Déchiffrement RSA de $($encryptedData.Length) octets")

        try {
            $rsa = [System.Security.Cryptography.RSA]::Create()
            $rsa.ImportRSAPrivateKey($privateKey, [ref]0)

            $inputStream = New-Object System.IO.MemoryStream
            $inputStream.Write($encryptedData, 0, $encryptedData.Length)
            $inputStream.Position = 0
            $reader = New-Object System.IO.BinaryReader($inputStream)

            $encryptionType = $reader.ReadByte()

            if ($encryptionType -eq 0) {
                # Déchiffrement RSA direct
                $dataLength = $reader.ReadInt32()
                $data = $reader.ReadBytes($dataLength)

                $decryptedData = $rsa.Decrypt($data, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

                $reader.Close()
                $inputStream.Close()

                $rsa.Dispose()

                $this.WriteDebug("Déchiffrement RSA direct terminé. Taille déchiffrée: $($decryptedData.Length) octets")
                return $decryptedData
            } else {
                # Déchiffrement hybride
                $keyLength = $reader.ReadInt32()
                $encryptedKey = $reader.ReadBytes($keyLength)
                $ivLength = $reader.ReadInt32()
                $encryptedIV = $reader.ReadBytes($ivLength)
                $dataLength = $reader.ReadInt32()
                $data = $reader.ReadBytes($dataLength)

                # Déchiffrer la clé AES avec RSA
                $key = $rsa.Decrypt($encryptedKey, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)
                $iv = $rsa.Decrypt($encryptedIV, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

                # Déchiffrer les données avec AES
                $decryptedData = $this.DecryptAES($data, $key, $iv)

                $reader.Close()
                $inputStream.Close()

                $rsa.Dispose()

                $this.WriteDebug("Déchiffrement RSA hybride terminé. Taille déchiffrée: $($decryptedData.Length) octets")
                return $decryptedData
            }
        } catch {
            $this.WriteDebug("Erreur lors du déchiffrement RSA - $($_.Exception.Message)")
            throw "Erreur lors du déchiffrement RSA - $($_.Exception.Message)"
        }
    }

    # Méthode pour chiffrer des données
    [byte[]] EncryptData([byte[]]$data, [string]$method, [PSObject]$keyData) {
        $this.WriteDebug("Chiffrement des données avec la méthode $method")

        # Vérifier si la méthode est supportée
        if (-not $this.EncryptionMethods.ContainsKey($method)) {
            throw "Méthode de chiffrement non supportée: $method"
        }

        # Appliquer la méthode de chiffrement
        if ($method -eq "AES") {
            if ($null -eq $keyData -or $null -eq $keyData.Key -or $null -eq $keyData.IV) {
                throw "Les clés AES (Key et IV) sont requises pour le chiffrement"
            }

            $encryptFunction = $this.EncryptionMethods[$method].EncryptFunction
            return & $encryptFunction $data $keyData.Key $keyData.IV
        } elseif ($method -eq "RSA") {
            if ($null -eq $keyData -or $null -eq $keyData.PublicKey) {
                throw "La clé publique RSA est requise pour le chiffrement"
            }

            $encryptFunction = $this.EncryptionMethods[$method].EncryptFunction
            return & $encryptFunction $data $keyData.PublicKey
        } else {
            throw "Méthode de chiffrement non implémentée: $method"
        }
    }

    # Méthode pour déchiffrer des données
    [byte[]] DecryptData([byte[]]$encryptedData, [string]$method, [PSObject]$keyData) {
        $this.WriteDebug("Déchiffrement des données avec la méthode $method")

        # Vérifier si la méthode est supportée
        if (-not $this.EncryptionMethods.ContainsKey($method)) {
            throw "Méthode de chiffrement non supportée: $method"
        }

        # Appliquer la méthode de déchiffrement
        if ($method -eq "AES") {
            if ($null -eq $keyData -or $null -eq $keyData.Key -or $null -eq $keyData.IV) {
                throw "Les clés AES (Key et IV) sont requises pour le déchiffrement"
            }

            $decryptFunction = $this.EncryptionMethods[$method].DecryptFunction
            return & $decryptFunction $encryptedData $keyData.Key $keyData.IV
        } elseif ($method -eq "RSA") {
            if ($null -eq $keyData -or $null -eq $keyData.PrivateKey) {
                throw "La clé privée RSA est requise pour le déchiffrement"
            }

            $decryptFunction = $this.EncryptionMethods[$method].DecryptFunction
            return & $decryptFunction $encryptedData $keyData.PrivateKey
        } else {
            throw "Méthode de déchiffrement non implémentée: $method"
        }
    }

    # Méthode pour chiffrer un fichier
    [string] EncryptFile([string]$inputPath, [string]$outputPath, [string]$method, [PSObject]$keyData) {
        $this.WriteDebug("Chiffrement du fichier $inputPath avec la méthode $method")

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $inputPath)) {
            throw "Le fichier spécifié n'existe pas: $inputPath"
        }

        # Vérifier si la méthode est supportée
        if (-not $this.EncryptionMethods.ContainsKey($method)) {
            throw "Méthode de chiffrement non supportée: $method"
        }

        try {
            # Lire le contenu du fichier
            $data = [System.IO.File]::ReadAllBytes($inputPath)

            # Chiffrer les données
            $encryptedData = $this.EncryptData($data, $method, $keyData)

            # Si le chemin de sortie n'est pas spécifié, générer un nom de fichier
            if ([string]::IsNullOrEmpty($outputPath)) {
                $outputPath = "$inputPath.encrypted"
            }

            # Écrire les données chiffrées dans le fichier de sortie
            [System.IO.File]::WriteAllBytes($outputPath, $encryptedData)

            return $outputPath
        } catch {
            $this.WriteDebug("Erreur lors du chiffrement du fichier - $($_.Exception.Message)")
            throw "Erreur lors du chiffrement du fichier $inputPath - $($_.Exception.Message)"
        }
    }

    # Méthode pour déchiffrer un fichier
    [string] DecryptFile([string]$inputPath, [string]$outputPath, [string]$method, [PSObject]$keyData) {
        $this.WriteDebug("Déchiffrement du fichier $inputPath avec la méthode $method")

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $inputPath)) {
            throw "Le fichier spécifié n'existe pas: $inputPath"
        }

        # Vérifier si la méthode est supportée
        if (-not $this.EncryptionMethods.ContainsKey($method)) {
            throw "Méthode de chiffrement non supportée: $method"
        }

        try {
            # Lire le contenu du fichier
            $encryptedData = [System.IO.File]::ReadAllBytes($inputPath)

            # Déchiffrer les données
            $decryptedData = $this.DecryptData($encryptedData, $method, $keyData)

            # Si le chemin de sortie n'est pas spécifié, générer un nom de fichier
            if ([string]::IsNullOrEmpty($outputPath)) {
                $outputPath = $inputPath -replace "\.encrypted$", ".decrypted"
                if ($outputPath -eq $inputPath) {
                    $outputPath = "$inputPath.decrypted"
                }
            }

            # Écrire les données déchiffrées dans le fichier de sortie
            [System.IO.File]::WriteAllBytes($outputPath, $decryptedData)

            return $outputPath
        } catch {
            $this.WriteDebug("Erreur lors du déchiffrement du fichier - $($_.Exception.Message)")
            throw "Erreur lors du déchiffrement du fichier $inputPath - $($_.Exception.Message)"
        }
    }
}

# Fonction pour créer un nouveau gestionnaire de chiffrement
function New-EncryptionManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    return [EncryptionManager]::new($EnableDebug)
}

# Fonction pour générer une clé AES
function New-AESKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-EncryptionManager -EnableDebug:$EnableDebug
    return $manager.GenerateAESKey()
}

# Fonction pour générer une paire de clés RSA
function New-RSAKeyPair {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-EncryptionManager -EnableDebug:$EnableDebug
    return $manager.GenerateRSAKeyPair()
}

# Fonction pour chiffrer des données
function Protect-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$Data,

        [Parameter(Mandatory = $true)]
        [ValidateSet("AES", "RSA")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [PSObject]$KeyData,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-EncryptionManager -EnableDebug:$EnableDebug
    return $manager.EncryptData($Data, $Method, $KeyData)
}

# Fonction pour déchiffrer des données
function Unprotect-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$EncryptedData,

        [Parameter(Mandatory = $true)]
        [ValidateSet("AES", "RSA")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [PSObject]$KeyData,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-EncryptionManager -EnableDebug:$EnableDebug
    return $manager.DecryptData($EncryptedData, $Method, $KeyData)
}

# Fonction pour chiffrer un fichier
function Protect-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("AES", "RSA")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [PSObject]$KeyData,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-EncryptionManager -EnableDebug:$EnableDebug
    return $manager.EncryptFile($InputPath, $OutputPath, $Method, $KeyData)
}

# Fonction pour déchiffrer un fichier
function Unprotect-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("AES", "RSA")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [PSObject]$KeyData,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-EncryptionManager -EnableDebug:$EnableDebug
    return $manager.DecryptFile($InputPath, $OutputPath, $Method, $KeyData)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-EncryptionManager, New-AESKey, New-RSAKeyPair, Protect-Data, Unprotect-Data, Protect-File, Unprotect-File

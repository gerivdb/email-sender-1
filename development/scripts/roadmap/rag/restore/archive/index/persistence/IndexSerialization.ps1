# IndexSerialization.ps1
# Script implémentant le système de sérialisation/désérialisation pour les index
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$structuresPath = Join-Path -Path $parentPath -ChildPath "structures"
$indexStructuresPath = Join-Path -Path $structuresPath -ChildPath "IndexStructures.ps1"

if (Test-Path -Path $indexStructuresPath) {
    . $indexStructuresPath
} else {
    Write-Error "Le fichier IndexStructures.ps1 est introuvable."
    exit 1
}

# Classe pour gérer la sérialisation et désérialisation des index
class IndexSerializer {
    # Format de sérialisation (JSON, Binary, BSON)
    [string]$Format
    
    # Compression (None, GZip, Deflate)
    [string]$Compression
    
    # Chiffrement (None, AES)
    [string]$Encryption
    
    # Clé de chiffrement (si applicable)
    [securestring]$EncryptionKey
    
    # Constructeur par défaut
    IndexSerializer() {
        $this.Format = "JSON"
        $this.Compression = "None"
        $this.Encryption = "None"
        $this.EncryptionKey = $null
    }
    
    # Constructeur avec format
    IndexSerializer([string]$format) {
        $this.Format = $format
        $this.Compression = "None"
        $this.Encryption = "None"
        $this.EncryptionKey = $null
    }
    
    # Constructeur complet
    IndexSerializer([string]$format, [string]$compression, [string]$encryption, [securestring]$encryptionKey) {
        $this.Format = $format
        $this.Compression = $compression
        $this.Encryption = $encryption
        $this.EncryptionKey = $encryptionKey
    }
    
    # Méthode pour sérialiser un document
    [byte[]] SerializeDocument([IndexDocument]$document) {
        # Convertir le document en JSON
        $json = $document.ToJson()
        
        # Convertir en bytes
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        
        # Appliquer la compression
        $bytes = $this.CompressData($bytes)
        
        # Appliquer le chiffrement
        $bytes = $this.EncryptData($bytes)
        
        return $bytes
    }
    
    # Méthode pour désérialiser un document
    [IndexDocument] DeserializeDocument([byte[]]$bytes) {
        # Déchiffrer les données
        $bytes = $this.DecryptData($bytes)
        
        # Décompresser les données
        $bytes = $this.DecompressData($bytes)
        
        # Convertir en JSON
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        
        # Créer le document
        return [IndexDocument]::FromJson($json)
    }
    
    # Méthode pour sérialiser un segment
    [byte[]] SerializeSegment([IndexSegment]$segment) {
        # Convertir le segment en JSON
        $json = $segment.ToJson()
        
        # Convertir en bytes
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        
        # Appliquer la compression
        $bytes = $this.CompressData($bytes)
        
        # Appliquer le chiffrement
        $bytes = $this.EncryptData($bytes)
        
        return $bytes
    }
    
    # Méthode pour désérialiser un segment
    [IndexSegment] DeserializeSegment([byte[]]$bytes) {
        # Déchiffrer les données
        $bytes = $this.DecryptData($bytes)
        
        # Décompresser les données
        $bytes = $this.DecompressData($bytes)
        
        # Convertir en JSON
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        
        # Créer le segment
        return [IndexSegment]::FromJson($json)
    }
    
    # Méthode pour compresser des données
    [byte[]] CompressData([byte[]]$data) {
        switch ($this.Compression) {
            "None" {
                return $data
            }
            "GZip" {
                $outputStream = New-Object System.IO.MemoryStream
                $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
                $gzipStream.Write($data, 0, $data.Length)
                $gzipStream.Close()
                return $outputStream.ToArray()
            }
            "Deflate" {
                $outputStream = New-Object System.IO.MemoryStream
                $deflateStream = New-Object System.IO.Compression.DeflateStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
                $deflateStream.Write($data, 0, $data.Length)
                $deflateStream.Close()
                return $outputStream.ToArray()
            }
            default {
                return $data
            }
        }
    }
    
    # Méthode pour décompresser des données
    [byte[]] DecompressData([byte[]]$data) {
        switch ($this.Compression) {
            "None" {
                return $data
            }
            "GZip" {
                $inputStream = New-Object System.IO.MemoryStream($data)
                $outputStream = New-Object System.IO.MemoryStream
                $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
                $buffer = New-Object byte[] 4096
                $count = 0
                
                do {
                    $count = $gzipStream.Read($buffer, 0, $buffer.Length)
                    if ($count -gt 0) {
                        $outputStream.Write($buffer, 0, $count)
                    }
                } while ($count -gt 0)
                
                $gzipStream.Close()
                $inputStream.Close()
                return $outputStream.ToArray()
            }
            "Deflate" {
                $inputStream = New-Object System.IO.MemoryStream($data)
                $outputStream = New-Object System.IO.MemoryStream
                $deflateStream = New-Object System.IO.Compression.DeflateStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
                $buffer = New-Object byte[] 4096
                $count = 0
                
                do {
                    $count = $deflateStream.Read($buffer, 0, $buffer.Length)
                    if ($count -gt 0) {
                        $outputStream.Write($buffer, 0, $count)
                    }
                } while ($count -gt 0)
                
                $deflateStream.Close()
                $inputStream.Close()
                return $outputStream.ToArray()
            }
            default {
                return $data
            }
        }
    }
    
    # Méthode pour chiffrer des données
    [byte[]] EncryptData([byte[]]$data) {
        switch ($this.Encryption) {
            "None" {
                return $data
            }
            "AES" {
                if ($null -eq $this.EncryptionKey) {
                    Write-Error "Clé de chiffrement non définie"
                    return $data
                }
                
                # Convertir la clé sécurisée en tableau de bytes
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.EncryptionKey)
                $keyString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                
                # Dériver une clé AES à partir de la chaîne
                $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($keyString)
                $sha = New-Object System.Security.Cryptography.SHA256Managed
                $keyBytes = $sha.ComputeHash($keyBytes)
                
                # Créer un vecteur d'initialisation aléatoire
                $aes = New-Object System.Security.Cryptography.AesManaged
                $aes.Key = $keyBytes
                $aes.GenerateIV()
                $iv = $aes.IV
                
                # Chiffrer les données
                $encryptor = $aes.CreateEncryptor()
                $encryptedData = $encryptor.TransformFinalBlock($data, 0, $data.Length)
                
                # Combiner le vecteur d'initialisation et les données chiffrées
                $result = New-Object byte[] ($iv.Length + $encryptedData.Length)
                [System.Buffer]::BlockCopy($iv, 0, $result, 0, $iv.Length)
                [System.Buffer]::BlockCopy($encryptedData, 0, $result, $iv.Length, $encryptedData.Length)
                
                return $result
            }
            default {
                return $data
            }
        }
    }
    
    # Méthode pour déchiffrer des données
    [byte[]] DecryptData([byte[]]$data) {
        switch ($this.Encryption) {
            "None" {
                return $data
            }
            "AES" {
                if ($null -eq $this.EncryptionKey) {
                    Write-Error "Clé de chiffrement non définie"
                    return $data
                }
                
                # Convertir la clé sécurisée en tableau de bytes
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.EncryptionKey)
                $keyString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                
                # Dériver une clé AES à partir de la chaîne
                $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($keyString)
                $sha = New-Object System.Security.Cryptography.SHA256Managed
                $keyBytes = $sha.ComputeHash($keyBytes)
                
                # Extraire le vecteur d'initialisation
                $aes = New-Object System.Security.Cryptography.AesManaged
                $ivLength = 16  # Taille du vecteur d'initialisation AES
                $iv = New-Object byte[] $ivLength
                [System.Buffer]::BlockCopy($data, 0, $iv, 0, $ivLength)
                
                # Extraire les données chiffrées
                $encryptedData = New-Object byte[] ($data.Length - $ivLength)
                [System.Buffer]::BlockCopy($data, $ivLength, $encryptedData, 0, $encryptedData.Length)
                
                # Déchiffrer les données
                $aes.Key = $keyBytes
                $aes.IV = $iv
                $decryptor = $aes.CreateDecryptor()
                $decryptedData = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)
                
                return $decryptedData
            }
            default {
                return $data
            }
        }
    }
}

# Fonction pour créer un sérialiseur d'index
function New-IndexSerializer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Binary", "BSON")]
        [string]$Format = "JSON",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "GZip", "Deflate")]
        [string]$Compression = "None",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "AES")]
        [string]$Encryption = "None",
        
        [Parameter(Mandatory = $false)]
        [securestring]$EncryptionKey = $null
    )
    
    return [IndexSerializer]::new($Format, $Compression, $Encryption, $EncryptionKey)
}

# Fonction pour sérialiser un document
function ConvertTo-SerializedDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexDocument]$Document,
        
        [Parameter(Mandatory = $false)]
        [IndexSerializer]$Serializer = [IndexSerializer]::new()
    )
    
    return $Serializer.SerializeDocument($Document)
}

# Fonction pour désérialiser un document
function ConvertFrom-SerializedDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [IndexSerializer]$Serializer = [IndexSerializer]::new()
    )
    
    return $Serializer.DeserializeDocument($Data)
}

# Fonction pour sérialiser un segment
function ConvertTo-SerializedSegment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegment]$Segment,
        
        [Parameter(Mandatory = $false)]
        [IndexSerializer]$Serializer = [IndexSerializer]::new()
    )
    
    return $Serializer.SerializeSegment($Segment)
}

# Fonction pour désérialiser un segment
function ConvertFrom-SerializedSegment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [IndexSerializer]$Serializer = [IndexSerializer]::new()
    )
    
    return $Serializer.DeserializeSegment($Data)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexSerializer, ConvertTo-SerializedDocument, ConvertFrom-SerializedDocument, ConvertTo-SerializedSegment, ConvertFrom-SerializedSegment

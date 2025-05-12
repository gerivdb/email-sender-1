# Protect-RoadmapData.ps1
# Module pour le chiffrement et la protection des données des roadmaps
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour le chiffrement et la protection des données des roadmaps.

.DESCRIPTION
    Ce module fournit des fonctions pour le chiffrement et la protection des données des roadmaps,
    notamment le chiffrement de bout en bout, la gestion des clés et la vérification d'intégrité.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
Add-Type -AssemblyName System.Security

# Fonction pour générer une clé de chiffrement
function New-EncryptionKey {
    <#
    .SYNOPSIS
        Génère une nouvelle clé de chiffrement.

    .DESCRIPTION
        Cette fonction génère une nouvelle clé de chiffrement aléatoire
        qui peut être utilisée pour chiffrer et déchiffrer des données.

    .PARAMETER KeySize
        La taille de la clé en bits (128, 192 ou 256).

    .PARAMETER KeyPath
        Le chemin où sauvegarder la clé.
        Si non spécifié, la clé est retournée mais non sauvegardée.

    .PARAMETER Password
        Le mot de passe pour protéger la clé.
        Si non spécifié, un mot de passe est généré automatiquement.

    .EXAMPLE
        New-EncryptionKey -KeySize 256 -KeyPath "C:\Keys\roadmap-key.xml" -Password "MySecurePassword"
        Génère une clé de chiffrement de 256 bits et la sauvegarde dans un fichier protégé par mot de passe.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet(128, 192, 256)]
        [int]$KeySize = 256,

        [Parameter(Mandatory = $false)]
        [string]$KeyPath = "",

        [Parameter(Mandatory = $false)]
        [string]$Password = ""
    )

    try {
        # Générer un mot de passe aléatoire si non spécifié
        if ([string]::IsNullOrEmpty($Password)) {
            $PasswordLength = 32
            $CharSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?/"
            $SecureRandom = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            $Bytes = New-Object byte[] $PasswordLength
            $SecureRandom.GetBytes($Bytes)
            
            $Password = ""
            for ($i = 0; $i -lt $PasswordLength; $i++) {
                $Password += $CharSet[$Bytes[$i] % $CharSet.Length]
            }
        }
        
        # Créer un objet AES
        $Aes = New-Object System.Security.Cryptography.AesManaged
        $Aes.KeySize = $KeySize
        $Aes.GenerateKey()
        $Aes.GenerateIV()
        
        # Créer l'objet de clé
        $Key = [PSCustomObject]@{
            Algorithm = "AES"
            KeySize = $KeySize
            Key = $Aes.Key
            IV = $Aes.IV
            Password = $Password
            CreationDate = Get-Date
        }
        
        # Sauvegarder la clé si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($KeyPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $KeyDir = Split-Path -Parent $KeyPath
            if (-not (Test-Path $KeyDir)) {
                New-Item -Path $KeyDir -ItemType Directory -Force | Out-Null
            }
            
            # Convertir la clé en XML
            $KeyXml = @"
<EncryptionKey>
    <Algorithm>$($Key.Algorithm)</Algorithm>
    <KeySize>$($Key.KeySize)</KeySize>
    <Key>$([Convert]::ToBase64String($Key.Key))</Key>
    <IV>$([Convert]::ToBase64String($Key.IV))</IV>
    <CreationDate>$($Key.CreationDate.ToString("o"))</CreationDate>
</EncryptionKey>
"@
            
            # Chiffrer le XML avec le mot de passe
            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $EncryptedXml = Protect-CmsMessage -Content $KeyXml -To "cn=RoadmapEncryption" -OutFile $KeyPath
            
            Write-Host "Clé de chiffrement sauvegardée dans: $KeyPath" -ForegroundColor Green
            Write-Host "Mot de passe: $Password" -ForegroundColor Yellow
            Write-Host "IMPORTANT: Conservez ce mot de passe en lieu sûr!" -ForegroundColor Red
        }
        
        return $Key
    } catch {
        Write-Error "Échec de la génération de la clé de chiffrement: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour charger une clé de chiffrement
function Get-EncryptionKey {
    <#
    .SYNOPSIS
        Charge une clé de chiffrement à partir d'un fichier.

    .DESCRIPTION
        Cette fonction charge une clé de chiffrement à partir d'un fichier
        protégé par mot de passe.

    .PARAMETER KeyPath
        Le chemin vers le fichier de clé.

    .PARAMETER Password
        Le mot de passe pour déprotéger la clé.

    .EXAMPLE
        Get-EncryptionKey -KeyPath "C:\Keys\roadmap-key.xml" -Password "MySecurePassword"
        Charge une clé de chiffrement à partir d'un fichier protégé par mot de passe.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    try {
        # Vérifier que le fichier de clé existe
        if (-not (Test-Path $KeyPath)) {
            Write-Error "Le fichier de clé n'existe pas: $KeyPath"
            return $null
        }
        
        # Déchiffrer le XML avec le mot de passe
        $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $KeyXml = Unprotect-CmsMessage -Path $KeyPath
        
        # Parser le XML
        $XmlDoc = New-Object System.Xml.XmlDocument
        $XmlDoc.LoadXml($KeyXml)
        
        # Créer l'objet de clé
        $Key = [PSCustomObject]@{
            Algorithm = $XmlDoc.SelectSingleNode("/EncryptionKey/Algorithm").InnerText
            KeySize = [int]$XmlDoc.SelectSingleNode("/EncryptionKey/KeySize").InnerText
            Key = [Convert]::FromBase64String($XmlDoc.SelectSingleNode("/EncryptionKey/Key").InnerText)
            IV = [Convert]::FromBase64String($XmlDoc.SelectSingleNode("/EncryptionKey/IV").InnerText)
            Password = $Password
            CreationDate = [DateTime]::Parse($XmlDoc.SelectSingleNode("/EncryptionKey/CreationDate").InnerText)
        }
        
        return $Key
    } catch {
        Write-Error "Échec du chargement de la clé de chiffrement: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour chiffrer un fichier
function Protect-RoadmapFile {
    <#
    .SYNOPSIS
        Chiffre un fichier de roadmap.

    .DESCRIPTION
        Cette fonction chiffre un fichier de roadmap à l'aide d'une clé de chiffrement.

    .PARAMETER FilePath
        Le chemin vers le fichier à chiffrer.

    .PARAMETER Key
        La clé de chiffrement à utiliser.
        Peut être générée avec New-EncryptionKey ou chargée avec Get-EncryptionKey.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier chiffré.
        Si non spécifié, le fichier d'entrée est remplacé.

    .PARAMETER AddChecksum
        Indique si une somme de contrôle doit être ajoutée pour vérifier l'intégrité.

    .EXAMPLE
        Protect-RoadmapFile -FilePath "C:\Roadmaps\roadmap.md" -Key $key -OutputPath "C:\Roadmaps\roadmap.enc" -AddChecksum
        Chiffre un fichier de roadmap et ajoute une somme de contrôle.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [PSObject]$Key,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [switch]$AddChecksum
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path $FilePath)) {
            Write-Error "Le fichier n'existe pas: $FilePath"
            return $null
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $FilePath + ".enc"
        }
        
        # Lire le contenu du fichier
        $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        # Calculer la somme de contrôle si demandé
        $Checksum = $null
        if ($AddChecksum) {
            $SHA256 = New-Object System.Security.Cryptography.SHA256Managed
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
            $Checksum = [Convert]::ToBase64String($SHA256.ComputeHash($Bytes))
        }
        
        # Créer un objet AES
        $Aes = New-Object System.Security.Cryptography.AesManaged
        $Aes.KeySize = $Key.KeySize
        $Aes.Key = $Key.Key
        $Aes.IV = $Key.IV
        
        # Créer un flux de mémoire pour le contenu chiffré
        $MemoryStream = New-Object System.IO.MemoryStream
        $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($MemoryStream, $Aes.CreateEncryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write)
        $StreamWriter = New-Object System.IO.StreamWriter($CryptoStream)
        
        # Écrire le contenu dans le flux
        $StreamWriter.Write($Content)
        $StreamWriter.Flush()
        $CryptoStream.FlushFinalBlock()
        
        # Obtenir le contenu chiffré
        $EncryptedBytes = $MemoryStream.ToArray()
        
        # Fermer les flux
        $StreamWriter.Close()
        $CryptoStream.Close()
        $MemoryStream.Close()
        
        # Créer l'en-tête du fichier chiffré
        $Header = @{
            Algorithm = $Key.Algorithm
            KeySize = $Key.KeySize
            IV = [Convert]::ToBase64String($Key.IV)
            Checksum = $Checksum
            EncryptionDate = Get-Date -Format "o"
            OriginalFileName = (Get-Item $FilePath).Name
        }
        
        # Convertir l'en-tête en JSON
        $HeaderJson = $Header | ConvertTo-Json -Compress
        
        # Écrire l'en-tête et le contenu chiffré dans le fichier de sortie
        $HeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($HeaderJson)
        $HeaderLength = $HeaderBytes.Length
        
        $FileStream = [System.IO.File]::Create($OutputPath)
        $BinaryWriter = New-Object System.IO.BinaryWriter($FileStream)
        
        # Écrire la longueur de l'en-tête (4 octets)
        $BinaryWriter.Write([int]$HeaderLength)
        
        # Écrire l'en-tête
        $BinaryWriter.Write($HeaderBytes)
        
        # Écrire le contenu chiffré
        $BinaryWriter.Write($EncryptedBytes)
        
        # Fermer le flux
        $BinaryWriter.Close()
        $FileStream.Close()
        
        # Créer l'objet de résultat
        $Result = [PSCustomObject]@{
            OriginalFile = $FilePath
            EncryptedFile = $OutputPath
            Algorithm = $Key.Algorithm
            KeySize = $Key.KeySize
            HasChecksum = $AddChecksum
            EncryptionDate = $Header.EncryptionDate
        }
        
        return $Result
    } catch {
        Write-Error "Échec du chiffrement du fichier: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour déchiffrer un fichier
function Unprotect-RoadmapFile {
    <#
    .SYNOPSIS
        Déchiffre un fichier de roadmap.

    .DESCRIPTION
        Cette fonction déchiffre un fichier de roadmap à l'aide d'une clé de chiffrement.

    .PARAMETER FilePath
        Le chemin vers le fichier à déchiffrer.

    .PARAMETER Key
        La clé de chiffrement à utiliser.
        Peut être chargée avec Get-EncryptionKey.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier déchiffré.
        Si non spécifié, un nom de fichier est généré automatiquement.

    .PARAMETER VerifyChecksum
        Indique si la somme de contrôle doit être vérifiée pour confirmer l'intégrité.

    .EXAMPLE
        Unprotect-RoadmapFile -FilePath "C:\Roadmaps\roadmap.enc" -Key $key -OutputPath "C:\Roadmaps\roadmap.md" -VerifyChecksum
        Déchiffre un fichier de roadmap et vérifie la somme de contrôle.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [PSObject]$Key,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [switch]$VerifyChecksum
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path $FilePath)) {
            Write-Error "Le fichier n'existe pas: $FilePath"
            return $null
        }
        
        # Lire le fichier chiffré
        $FileStream = [System.IO.File]::OpenRead($FilePath)
        $BinaryReader = New-Object System.IO.BinaryReader($FileStream)
        
        # Lire la longueur de l'en-tête
        $HeaderLength = $BinaryReader.ReadInt32()
        
        # Lire l'en-tête
        $HeaderBytes = $BinaryReader.ReadBytes($HeaderLength)
        $HeaderJson = [System.Text.Encoding]::UTF8.GetString($HeaderBytes)
        $Header = $HeaderJson | ConvertFrom-Json
        
        # Lire le contenu chiffré
        $EncryptedBytes = New-Object byte[] ($FileStream.Length - $HeaderLength - 4)
        $BinaryReader.Read($EncryptedBytes, 0, $EncryptedBytes.Length) | Out-Null
        
        # Fermer le flux
        $BinaryReader.Close()
        $FileStream.Close()
        
        # Créer un objet AES
        $Aes = New-Object System.Security.Cryptography.AesManaged
        $Aes.KeySize = $Key.KeySize
        $Aes.Key = $Key.Key
        $Aes.IV = [Convert]::FromBase64String($Header.IV)
        
        # Créer un flux de mémoire pour le contenu déchiffré
        $MemoryStream = New-Object System.IO.MemoryStream($EncryptedBytes)
        $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($MemoryStream, $Aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read)
        $StreamReader = New-Object System.IO.StreamReader($CryptoStream)
        
        # Lire le contenu déchiffré
        $Content = $StreamReader.ReadToEnd()
        
        # Fermer les flux
        $StreamReader.Close()
        $CryptoStream.Close()
        $MemoryStream.Close()
        
        # Vérifier la somme de contrôle si demandé
        if ($VerifyChecksum -and $null -ne $Header.Checksum) {
            $SHA256 = New-Object System.Security.Cryptography.SHA256Managed
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
            $ComputedChecksum = [Convert]::ToBase64String($SHA256.ComputeHash($Bytes))
            
            if ($ComputedChecksum -ne $Header.Checksum) {
                Write-Error "La somme de contrôle ne correspond pas. Le fichier a peut-être été modifié."
                return $null
            }
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputDir = Split-Path -Parent $FilePath
            $OutputPath = Join-Path -Path $OutputDir -ChildPath $Header.OriginalFileName
        }
        
        # Écrire le contenu déchiffré dans le fichier de sortie
        $Content | Out-File -FilePath $OutputPath -Encoding UTF8
        
        # Créer l'objet de résultat
        $Result = [PSCustomObject]@{
            EncryptedFile = $FilePath
            DecryptedFile = $OutputPath
            Algorithm = $Header.Algorithm
            KeySize = $Header.KeySize
            ChecksumVerified = ($VerifyChecksum -and $null -ne $Header.Checksum)
            EncryptionDate = $Header.EncryptionDate
        }
        
        return $Result
    } catch {
        Write-Error "Échec du déchiffrement du fichier: $($_.Exception.Message)"
        return $null
    }
}

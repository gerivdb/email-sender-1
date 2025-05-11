<#
.SYNOPSIS
    Gestionnaire de compression pour le partage des vues.

.DESCRIPTION
    Ce module implémente le gestionnaire de compression qui permet de compresser
    et décompresser les données pour optimiser le partage des vues.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Classe pour représenter le gestionnaire de compression
class CompressionManager {
    # Propriétés
    [hashtable]$CompressionMethods
    [int]$DefaultCompressionLevel
    [bool]$Debug

    # Constructeur par défaut
    CompressionManager() {
        $this.CompressionMethods = @{
            "GZIP"    = @{
                CompressFunction   = { param($data) return $this.CompressGZip($data) }
                DecompressFunction = { param($data) return $this.DecompressGZip($data) }
                Description        = "Compression GZip standard"
            }
            "DEFLATE" = @{
                CompressFunction   = { param($data) return $this.CompressDeflate($data) }
                DecompressFunction = { param($data) return $this.DecompressDeflate($data) }
                Description        = "Compression Deflate (Zlib)"
            }
            "BROTLI"  = @{
                CompressFunction   = { param($data) return $this.CompressBrotli($data) }
                DecompressFunction = { param($data) return $this.DecompressBrotli($data) }
                Description        = "Compression Brotli (haute performance)"
            }
        }
        $this.DefaultCompressionLevel = 5
        $this.Debug = $false
    }

    # Constructeur avec paramètres
    CompressionManager([int]$compressionLevel, [bool]$debug) {
        $this.CompressionMethods = @{
            "GZIP"    = @{
                CompressFunction   = { param($data) return $this.CompressGZip($data) }
                DecompressFunction = { param($data) return $this.DecompressGZip($data) }
                Description        = "Compression GZip standard"
            }
            "DEFLATE" = @{
                CompressFunction   = { param($data) return $this.CompressDeflate($data) }
                DecompressFunction = { param($data) return $this.DecompressDeflate($data) }
                Description        = "Compression Deflate (Zlib)"
            }
            "BROTLI"  = @{
                CompressFunction   = { param($data) return $this.CompressBrotli($data) }
                DecompressFunction = { param($data) return $this.DecompressBrotli($data) }
                Description        = "Compression Brotli (haute performance)"
            }
        }
        $this.DefaultCompressionLevel = $compressionLevel
        $this.Debug = $debug
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[DEBUG] [CompressionManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour compresser des données avec GZip
    [byte[]] CompressGZip([byte[]]$data) {
        $this.WriteDebug("Compression GZip de $($data.Length) octets")

        try {
            $outputStream = New-Object System.IO.MemoryStream
            $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
            if ($this.DefaultCompressionLevel -le 3) {
                $compressionLevel = [System.IO.Compression.CompressionLevel]::Fastest
            } elseif ($this.DefaultCompressionLevel -ge 7) {
                $compressionLevel = [System.IO.Compression.CompressionLevel]::NoCompression
            }
            $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, $compressionLevel)
            $gzipStream.Write($data, 0, $data.Length)
            $gzipStream.Close()

            $compressedData = $outputStream.ToArray()
            $outputStream.Close()

            $this.WriteDebug("Compression terminée. Taille compressée: $($compressedData.Length) octets")
            return $compressedData
        } catch {
            $this.WriteDebug("Erreur lors de la compression GZip: $_")
            throw "Erreur lors de la compression GZip: $_"
        }
    }

    # Méthode pour décompresser des données avec GZip
    [byte[]] DecompressGZip([byte[]]$compressedData) {
        $this.WriteDebug("Décompression GZip de $($compressedData.Length) octets")

        try {
            $inputStream = New-Object System.IO.MemoryStream
            $inputStream.Write($compressedData, 0, $compressedData.Length)
            $inputStream.Position = 0
            $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
            $outputStream = New-Object System.IO.MemoryStream

            $buffer = New-Object byte[] 4096
            $bytesRead = 0

            while (($bytesRead = $gzipStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $outputStream.Write($buffer, 0, $bytesRead)
            }

            $gzipStream.Close()
            $inputStream.Close()

            $decompressedData = $outputStream.ToArray()
            $outputStream.Close()

            $this.WriteDebug("Décompression terminée. Taille décompressée: $($decompressedData.Length) octets")
            return $decompressedData
        } catch {
            $this.WriteDebug("Erreur lors de la décompression GZip: $_")
            throw "Erreur lors de la décompression GZip: $_"
        }
    }

    # Méthode pour compresser des données avec Deflate
    [byte[]] CompressDeflate([byte[]]$data) {
        $this.WriteDebug("Compression Deflate de $($data.Length) octets")

        try {
            $outputStream = New-Object System.IO.MemoryStream
            $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
            if ($this.DefaultCompressionLevel -le 3) {
                $compressionLevel = [System.IO.Compression.CompressionLevel]::Fastest
            } elseif ($this.DefaultCompressionLevel -ge 7) {
                $compressionLevel = [System.IO.Compression.CompressionLevel]::NoCompression
            }
            $deflateStream = New-Object System.IO.Compression.DeflateStream($outputStream, $compressionLevel)
            $deflateStream.Write($data, 0, $data.Length)
            $deflateStream.Close()

            $compressedData = $outputStream.ToArray()
            $outputStream.Close()

            $this.WriteDebug("Compression terminée. Taille compressée: $($compressedData.Length) octets")
            return $compressedData
        } catch {
            $this.WriteDebug("Erreur lors de la compression Deflate: $_")
            throw "Erreur lors de la compression Deflate: $_"
        }
    }

    # Méthode pour décompresser des données avec Deflate
    [byte[]] DecompressDeflate([byte[]]$compressedData) {
        $this.WriteDebug("Décompression Deflate de $($compressedData.Length) octets")

        try {
            $inputStream = New-Object System.IO.MemoryStream
            $inputStream.Write($compressedData, 0, $compressedData.Length)
            $inputStream.Position = 0
            $deflateStream = New-Object System.IO.Compression.DeflateStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
            $outputStream = New-Object System.IO.MemoryStream

            $buffer = New-Object byte[] 4096
            $bytesRead = 0

            while (($bytesRead = $deflateStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $outputStream.Write($buffer, 0, $bytesRead)
            }

            $deflateStream.Close()
            $inputStream.Close()

            $decompressedData = $outputStream.ToArray()
            $outputStream.Close()

            $this.WriteDebug("Décompression terminée. Taille décompressée: $($decompressedData.Length) octets")
            return $decompressedData
        } catch {
            $this.WriteDebug("Erreur lors de la décompression Deflate: $_")
            throw "Erreur lors de la décompression Deflate: $_"
        }
    }

    # Méthode pour compresser des données avec Brotli (simulation)
    [byte[]] CompressBrotli([byte[]]$data) {
        $this.WriteDebug("Compression Brotli de $($data.Length) octets (simulation)")

        # Note: Brotli n'est pas nativement supporté dans .NET Framework
        # Cette méthode est une simulation qui utilise GZip à la place
        return $this.CompressGZip($data)
    }

    # Méthode pour décompresser des données avec Brotli (simulation)
    [byte[]] DecompressBrotli([byte[]]$compressedData) {
        $this.WriteDebug("Décompression Brotli de $($compressedData.Length) octets (simulation)")

        # Note: Brotli n'est pas nativement supporté dans .NET Framework
        # Cette méthode est une simulation qui utilise GZip à la place
        return $this.DecompressGZip($compressedData)
    }

    # Méthode pour compresser des données
    [byte[]] CompressData([byte[]]$data, [string]$method) {
        $this.WriteDebug("Compression des données avec la méthode $method")

        # Vérifier si la méthode est supportée
        if (-not $this.CompressionMethods.ContainsKey($method)) {
            throw "Méthode de compression non supportée: $method"
        }

        # Appliquer la méthode de compression
        $compressFunction = $this.CompressionMethods[$method].CompressFunction
        return & $compressFunction $data
    }

    # Méthode pour décompresser des données
    [byte[]] DecompressData([byte[]]$compressedData, [string]$method) {
        $this.WriteDebug("Décompression des données avec la méthode $method")

        # Vérifier si la méthode est supportée
        if (-not $this.CompressionMethods.ContainsKey($method)) {
            throw "Méthode de compression non supportée: $method"
        }

        # Appliquer la méthode de décompression
        $decompressFunction = $this.CompressionMethods[$method].DecompressFunction
        return & $decompressFunction $compressedData
    }

    # Méthode pour compresser un fichier
    [string] CompressFile([string]$inputPath, [string]$outputPath, [string]$method) {
        $this.WriteDebug("Compression du fichier $inputPath avec la méthode $method")

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $inputPath)) {
            throw "Le fichier spécifié n'existe pas: $inputPath"
        }

        # Vérifier si la méthode est supportée
        if (-not $this.CompressionMethods.ContainsKey($method)) {
            throw "Méthode de compression non supportée: $method"
        }

        try {
            # Lire le contenu du fichier
            $data = [System.IO.File]::ReadAllBytes($inputPath)

            # Compresser les données
            $compressedData = $this.CompressData($data, $method)

            # Si le chemin de sortie n'est pas spécifié, générer un nom de fichier
            if ([string]::IsNullOrEmpty($outputPath)) {
                $outputPath = "$inputPath.$method"
            }

            # Écrire les données compressées dans le fichier de sortie
            [System.IO.File]::WriteAllBytes($outputPath, $compressedData)

            return $outputPath
        } catch {
            $this.WriteDebug("Erreur lors de la compression du fichier: $_")
            throw "Erreur lors de la compression du fichier $inputPath : $($_.Exception.Message)"
        }
    }

    # Méthode pour décompresser un fichier
    [string] DecompressFile([string]$inputPath, [string]$outputPath, [string]$method) {
        $this.WriteDebug("Décompression du fichier $inputPath avec la méthode $method")

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $inputPath)) {
            throw "Le fichier spécifié n'existe pas: $inputPath"
        }

        # Vérifier si la méthode est supportée
        if (-not $this.CompressionMethods.ContainsKey($method)) {
            throw "Méthode de compression non supportée: $method"
        }

        try {
            # Lire le contenu du fichier
            $compressedData = [System.IO.File]::ReadAllBytes($inputPath)

            # Décompresser les données
            $decompressedData = $this.DecompressData($compressedData, $method)

            # Si le chemin de sortie n'est pas spécifié, générer un nom de fichier
            if ([string]::IsNullOrEmpty($outputPath)) {
                $outputPath = $inputPath -replace "\.$method$", ""
                if ($outputPath -eq $inputPath) {
                    $outputPath = "$inputPath.decompressed"
                }
            }

            # Écrire les données décompressées dans le fichier de sortie
            [System.IO.File]::WriteAllBytes($outputPath, $decompressedData)

            return $outputPath
        } catch {
            $this.WriteDebug("Erreur lors de la décompression du fichier: $_")
            throw "Erreur lors de la décompression du fichier $inputPath : $($_.Exception.Message)"
        }
    }
}

# Fonction pour créer un nouveau gestionnaire de compression
function New-CompressionManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 9)]
        [int]$CompressionLevel = 5,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    return [CompressionManager]::new($CompressionLevel, $EnableDebug)
}

# Fonction pour compresser des données
function Compress-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GZIP", "DEFLATE", "BROTLI")]
        [string]$Method = "GZIP",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 9)]
        [int]$CompressionLevel = 5,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-CompressionManager -CompressionLevel $CompressionLevel -EnableDebug:$EnableDebug
    return $manager.CompressData($Data, $Method)
}

# Fonction pour décompresser des données
function Expand-CompressedData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$CompressedData,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GZIP", "DEFLATE", "BROTLI")]
        [string]$Method = "GZIP",

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-CompressionManager -EnableDebug:$EnableDebug
    return $manager.DecompressData($CompressedData, $Method)
}

# Fonction pour compresser un fichier
function Compress-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GZIP", "DEFLATE", "BROTLI")]
        [string]$Method = "GZIP",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 9)]
        [int]$CompressionLevel = 5,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-CompressionManager -CompressionLevel $CompressionLevel -EnableDebug:$EnableDebug
    return $manager.CompressFile($InputPath, $OutputPath, $Method)
}

# Fonction pour décompresser un fichier
function Expand-CompressedFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GZIP", "DEFLATE", "BROTLI")]
        [string]$Method = "GZIP",

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-CompressionManager -EnableDebug:$EnableDebug
    return $manager.DecompressFile($InputPath, $OutputPath, $Method)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-CompressionManager, Compress-Data, Decompress-Data, Compress-File, Decompress-File

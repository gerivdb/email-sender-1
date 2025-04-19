#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'optimisation pour les segmenteurs de formats.
.DESCRIPTION
    Ce script fournit des fonctionnalités d'optimisation pour améliorer les performances
    des segmenteurs de formats lors du traitement de fichiers volumineux.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer les modules nécessaires
. "$PSScriptRoot\UnifiedSegmenter.ps1" -ErrorAction Stop

# Fonction pour traiter un fichier volumineux en mode streaming
function Split-StreamingFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDir = ".\output",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT")]
        [string]$Format = "AUTO",
        
        [Parameter(Mandatory = $false)]
        [int]$BufferSizeKB = 1024,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 10,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Détecter le format si nécessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format détecté: $Format"
    }
    
    # Traiter selon le format
    switch ($Format) {
        "JSON" {
            return Split-StreamingJsonFile -FilePath $FilePath -OutputDir $OutputDir -BufferSizeKB $BufferSizeKB -ChunkSizeKB $ChunkSizeKB -PreserveStructure:$PreserveStructure
        }
        "XML" {
            return Split-StreamingXmlFile -FilePath $FilePath -OutputDir $OutputDir -BufferSizeKB $BufferSizeKB -ChunkSizeKB $ChunkSizeKB -PreserveStructure:$PreserveStructure
        }
        "TEXT" {
            return Split-StreamingTextFile -FilePath $FilePath -OutputDir $OutputDir -BufferSizeKB $BufferSizeKB -ChunkSizeKB $ChunkSizeKB
        }
        default {
            Write-Error "Format non pris en charge: $Format"
            return @()
        }
    }
}

# Fonction pour traiter un fichier JSON volumineux en mode streaming
function Split-StreamingJsonFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDir = ".\output",
        
        [Parameter(Mandatory = $false)]
        [int]$BufferSizeKB = 1024,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 10,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Utiliser le segmenteur JSON en mode streaming
    $arguments = @(
        "$PSScriptRoot\JsonSegmenter.py",
        "segment",
        $FilePath,
        "--output-dir", $OutputDir,
        "--max-chunk-size", $ChunkSizeKB,
        "--buffer-size", $BufferSizeKB
    )
    
    if (-not $PreserveStructure) {
        $arguments += "--no-preserve-structure"
    }
    
    # Exécuter la commande Python
    $result = & python $arguments
    
    # Extraire les chemins des fichiers créés
    $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
    return $filePaths
}

# Fonction pour traiter un fichier XML volumineux en mode streaming
function Split-StreamingXmlFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDir = ".\output",
        
        [Parameter(Mandatory = $false)]
        [int]$BufferSizeKB = 1024,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 10,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Utiliser le segmenteur XML en mode streaming
    $arguments = @(
        "$PSScriptRoot\XmlSegmenter.py",
        "segment",
        $FilePath,
        "--output-dir", $OutputDir,
        "--max-chunk-size", $ChunkSizeKB,
        "--buffer-size", $BufferSizeKB,
        "--streaming"
    )
    
    if (-not $PreserveStructure) {
        $arguments += "--no-preserve-structure"
    }
    
    # Exécuter la commande Python
    $result = & python $arguments
    
    # Extraire les chemins des fichiers créés
    $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
    return $filePaths
}

# Fonction pour traiter un fichier texte volumineux en mode streaming
function Split-StreamingTextFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDir = ".\output",
        
        [Parameter(Mandatory = $false)]
        [int]$BufferSizeKB = 1024,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 10
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Utiliser le segmenteur de texte en mode streaming
    $arguments = @(
        "$PSScriptRoot\TextSegmenter.py",
        "segment",
        $FilePath,
        "--output-dir", $OutputDir,
        "--max-chunk-size", $ChunkSizeKB,
        "--buffer-size", $BufferSizeKB,
        "--streaming"
    )
    
    # Exécuter la commande Python
    $result = & python $arguments
    
    # Extraire les chemins des fichiers créés
    $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
    return $filePaths
}

# Fonction pour traiter un fichier en parallèle
function Split-ParallelFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDir = ".\output",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT")]
        [string]$Format = "AUTO",
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 4,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Détecter le format si nécessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format détecté: $Format"
    }
    
    # Diviser le fichier en segments temporaires
    $tempDir = Join-Path -Path $env:TEMP -ChildPath "ParallelSegmentation_$(Get-Random)"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # Utiliser Split-StreamingFile pour diviser le fichier en segments temporaires
    $tempSegments = Split-StreamingFile -FilePath $FilePath -OutputDir $tempDir -Format $Format -BufferSizeKB 1024 -ChunkSizeKB 1024 -PreserveStructure:$PreserveStructure
    
    # Traiter chaque segment temporaire en parallèle
    $segments = @()
    
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # PowerShell 7+ : Utiliser ForEach-Object -Parallel
        $segments = $tempSegments | ForEach-Object -Parallel {
            $segment = $_
            $segmentOutputDir = Join-Path -Path $using:OutputDir -ChildPath "segment_$(Get-Random)"
            New-Item -Path $segmentOutputDir -ItemType Directory -Force | Out-Null
            
            # Traiter le segment
            $result = & python "$using:PSScriptRoot\UnifiedSegmenter.ps1" Split-File -FilePath $segment -OutputDir $segmentOutputDir -Format $using:Format -ChunkSizeKB $using:ChunkSizeKB -PreserveStructure:$using:PreserveStructure
            
            # Retourner les segments créés
            return $result
        } -ThrottleLimit $MaxThreads
    } else {
        # PowerShell 5.1 : Utiliser des jobs
        $jobs = @()
        
        foreach ($segment in $tempSegments) {
            $job = Start-Job -ScriptBlock {
                param($segment, $outputDir, $scriptRoot, $format, $chunkSizeKB, $preserveStructure)
                
                $segmentOutputDir = Join-Path -Path $outputDir -ChildPath "segment_$(Get-Random)"
                New-Item -Path $segmentOutputDir -ItemType Directory -Force | Out-Null
                
                # Traiter le segment
                $result = & python "$scriptRoot\UnifiedSegmenter.ps1" Split-File -FilePath $segment -OutputDir $segmentOutputDir -Format $format -ChunkSizeKB $chunkSizeKB -PreserveStructure:$preserveStructure
                
                # Retourner les segments créés
                return $result
            } -ArgumentList $segment, $OutputDir, $PSScriptRoot, $Format, $ChunkSizeKB, $PreserveStructure
            
            $jobs += $job
            
            # Limiter le nombre de jobs en cours
            while ((Get-Job -State Running).Count -ge $MaxThreads) {
                Start-Sleep -Milliseconds 100
            }
        }
        
        # Attendre que tous les jobs soient terminés
        $jobs | Wait-Job | Out-Null
        
        # Récupérer les résultats
        $segments = $jobs | Receive-Job
        
        # Nettoyer les jobs
        $jobs | Remove-Job
    }
    
    # Nettoyer les segments temporaires
    Remove-Item -Path $tempDir -Recurse -Force
    
    return $segments
}

# Fonction pour compresser les segments
function Compress-Segments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFile,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Zip", "GZip", "Deflate")]
        [string]$CompressionMethod = "Zip"
    )
    
    # Vérifier que les fichiers existent
    $missingFiles = $FilePaths | Where-Object { -not (Test-Path -Path $_) }
    if ($missingFiles.Count -gt 0) {
        Write-Error "Fichiers manquants: $($missingFiles -join ', ')"
        return $null
    }
    
    # Si aucun fichier de sortie n'est spécifié, en créer un
    if (-not $OutputFile) {
        $OutputFile = Join-Path -Path $env:TEMP -ChildPath "segments_$(Get-Date -Format 'yyyyMMddHHmmss').zip"
    }
    
    # Compresser les fichiers selon la méthode spécifiée
    switch ($CompressionMethod) {
        "Zip" {
            # Utiliser Compress-Archive
            Compress-Archive -Path $FilePaths -DestinationPath $OutputFile -Force
        }
        "GZip" {
            # Utiliser System.IO.Compression.GZipStream
            $outputStream = [System.IO.File]::Create($OutputFile)
            $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
            
            try {
                foreach ($filePath in $FilePaths) {
                    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                    $gzipStream.Write($fileBytes, 0, $fileBytes.Length)
                }
            }
            finally {
                $gzipStream.Close()
                $outputStream.Close()
            }
        }
        "Deflate" {
            # Utiliser System.IO.Compression.DeflateStream
            $outputStream = [System.IO.File]::Create($OutputFile)
            $deflateStream = New-Object System.IO.Compression.DeflateStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
            
            try {
                foreach ($filePath in $FilePaths) {
                    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                    $deflateStream.Write($fileBytes, 0, $fileBytes.Length)
                }
            }
            finally {
                $deflateStream.Close()
                $outputStream.Close()
            }
        }
    }
    
    return $OutputFile
}

# Fonction pour décompresser les segments
function Expand-Segments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDir,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Zip", "GZip", "Deflate")]
        [string]$CompressionMethod = "Zip"
    )
    
    # Vérifier que l'archive existe
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Error "L'archive n'existe pas: $ArchivePath"
        return @()
    }
    
    # Si aucun répertoire de sortie n'est spécifié, en créer un
    if (-not $OutputDir) {
        $OutputDir = Join-Path -Path $env:TEMP -ChildPath "segments_$(Get-Date -Format 'yyyyMMddHHmmss')"
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Décompresser l'archive selon la méthode spécifiée
    switch ($CompressionMethod) {
        "Zip" {
            # Utiliser Expand-Archive
            Expand-Archive -Path $ArchivePath -DestinationPath $OutputDir -Force
        }
        "GZip" {
            # Utiliser System.IO.Compression.GZipStream
            $inputStream = [System.IO.File]::OpenRead($ArchivePath)
            $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
            
            try {
                $outputFile = Join-Path -Path $OutputDir -ChildPath "decompressed.bin"
                $outputStream = [System.IO.File]::Create($outputFile)
                
                $buffer = New-Object byte[] 4096
                $count = 0
                
                do {
                    $count = $gzipStream.Read($buffer, 0, $buffer.Length)
                    if ($count -gt 0) {
                        $outputStream.Write($buffer, 0, $count)
                    }
                } while ($count -gt 0)
                
                $outputStream.Close()
            }
            finally {
                $gzipStream.Close()
                $inputStream.Close()
            }
        }
        "Deflate" {
            # Utiliser System.IO.Compression.DeflateStream
            $inputStream = [System.IO.File]::OpenRead($ArchivePath)
            $deflateStream = New-Object System.IO.Compression.DeflateStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
            
            try {
                $outputFile = Join-Path -Path $OutputDir -ChildPath "decompressed.bin"
                $outputStream = [System.IO.File]::Create($outputFile)
                
                $buffer = New-Object byte[] 4096
                $count = 0
                
                do {
                    $count = $deflateStream.Read($buffer, 0, $buffer.Length)
                    if ($count -gt 0) {
                        $outputStream.Write($buffer, 0, $count)
                    }
                } while ($count -gt 0)
                
                $outputStream.Close()
            }
            finally {
                $deflateStream.Close()
                $inputStream.Close()
            }
        }
    }
    
    # Retourner les fichiers décompressés
    return Get-ChildItem -Path $OutputDir -Recurse -File | Select-Object -ExpandProperty FullName
}

# Exporter les fonctions
Export-ModuleMember -Function Split-StreamingFile, Split-ParallelFile, Compress-Segments, Expand-Segments

#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte l'encodage des fichiers texte.

.DESCRIPTION
    Ce script détecte l'encodage des fichiers texte en analysant les premiers octets
    du fichier (BOM) et en effectuant une analyse heuristique du contenu.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER SampleSize
    La taille de l'échantillon à analyser (en octets). Par défaut, 4096 octets.

.EXAMPLE
    .\Detect-FileEncoding.ps1 -FilePath "C:\Temp\document.txt"

.EXAMPLE
    Get-ChildItem -Path "C:\Temp" -Filter "*.txt" | .\Detect-FileEncoding.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias("FullName")]
    [string]$FilePath,
    
    [Parameter()]
    [int]$SampleSize = 4096
)

begin {
    # Fonction pour détecter l'encodage d'un fichier
    function Get-FileEncoding {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter()]
            [int]$SampleSize = 4096
        )
        
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                Write-Error "Le fichier $FilePath n'existe pas."
                return "FILE_NOT_FOUND"
            }
            
            # Lire les premiers octets du fichier pour détecter les BOM
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)
            
            # Vérifier les BOM (Byte Order Mark)
            if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "UTF-32BE"
                    BOM = $true
                    Confidence = 100
                    Description = "UTF-32 Big Endian avec BOM"
                }
            }
            if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "UTF-32LE"
                    BOM = $true
                    Confidence = 100
                    Description = "UTF-32 Little Endian avec BOM"
                }
            }
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "UTF-8-BOM"
                    BOM = $true
                    Confidence = 100
                    Description = "UTF-8 avec BOM"
                }
            }
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "UTF-16BE"
                    BOM = $true
                    Confidence = 100
                    Description = "UTF-16 Big Endian avec BOM"
                }
            }
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "UTF-16LE"
                    BOM = $true
                    Confidence = 100
                    Description = "UTF-16 Little Endian avec BOM"
                }
            }
            
            # Si aucun BOM n'est détecté, essayer de déterminer l'encodage par analyse du contenu
            # Limiter la taille de l'échantillon
            $sampleSize = [Math]::Min($SampleSize, $bytes.Length)
            $sample = $bytes[0..($sampleSize - 1)]
            
            # Vérifier si le fichier est binaire
            $binaryCount = 0
            $controlCharsAllowed = @(9, 10, 13)  # TAB, LF, CR
            
            foreach ($byte in $sample) {
                if (($byte -lt 32 -and $controlCharsAllowed -notcontains $byte) -or $byte -eq 0) {
                    $binaryCount++
                }
            }
            
            $binaryRatio = $binaryCount / $sampleSize
            
            if ($binaryRatio -gt 0.1) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "BINARY"
                    BOM = $false
                    Confidence = [Math]::Round($binaryRatio * 100)
                    Description = "Fichier binaire (ratio de caractères binaires: $([Math]::Round($binaryRatio * 100))%)"
                }
            }
            
            # Vérifier si le fichier contient des octets nuls (caractéristique de UTF-16/UTF-32)
            $containsNulls = $false
            for ($i = 0; $i -lt $sample.Length; $i++) {
                if ($sample[$i] -eq 0) {
                    $containsNulls = $true
                    break
                }
            }
            
            if ($containsNulls) {
                # Vérifier les motifs de nulls pour UTF-16/UTF-32
                $utf16LEPattern = $true
                $utf16BEPattern = $true
                $nullCount = 0
                
                for ($i = 0; $i -lt $sample.Length - 1; $i += 2) {
                    if ($i + 1 -lt $sample.Length) {
                        if ($sample[$i] -eq 0 -and $sample[$i + 1] -ne 0) {
                            $utf16BEPattern = $false
                            $nullCount++
                        }
                        if ($sample[$i] -ne 0 -and $sample[$i + 1] -eq 0) {
                            $utf16LEPattern = $false
                            $nullCount++
                        }
                    }
                }
                
                $nullRatio = $nullCount / ($sample.Length / 2)
                
                if ($utf16LEPattern) {
                    return [PSCustomObject]@{
                        FilePath = $FilePath
                        Encoding = "UTF-16LE"
                        BOM = $false
                        Confidence = 80
                        Description = "UTF-16 Little Endian sans BOM (détecté par motif d'octets nuls)"
                    }
                }
                if ($utf16BEPattern) {
                    return [PSCustomObject]@{
                        FilePath = $FilePath
                        Encoding = "UTF-16BE"
                        BOM = $false
                        Confidence = 80
                        Description = "UTF-16 Big Endian sans BOM (détecté par motif d'octets nuls)"
                    }
                }
                
                # Si les motifs ne correspondent pas clairement, considérer comme binaire
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "BINARY"
                    BOM = $false
                    Confidence = 60
                    Description = "Probablement binaire (contient des octets nuls sans motif clair)"
                }
            }
            
            # Vérifier si le fichier est probablement UTF-8
            $isUtf8 = $true
            $utf8Sequences = 0
            $i = 0
            
            while ($i -lt $sample.Length) {
                # Vérifier les séquences UTF-8 valides
                if ($sample[$i] -lt 0x80) {
                    # ASCII (0xxxxxxx)
                    $i++
                } elseif ($sample[$i] -ge 0xC0 -and $sample[$i] -le 0xDF -and $i + 1 -lt $sample.Length) {
                    # 2-byte sequence (110xxxxx 10xxxxxx)
                    if ($sample[$i + 1] -lt 0x80 -or $sample[$i + 1] -gt 0xBF) {
                        $isUtf8 = $false
                        break
                    }
                    $utf8Sequences++
                    $i += 2
                } elseif ($sample[$i] -ge 0xE0 -and $sample[$i] -le 0xEF -and $i + 2 -lt $sample.Length) {
                    # 3-byte sequence (1110xxxx 10xxxxxx 10xxxxxx)
                    if ($sample[$i + 1] -lt 0x80 -or $sample[$i + 1] -gt 0xBF -or
                        $sample[$i + 2] -lt 0x80 -or $sample[$i + 2] -gt 0xBF) {
                        $isUtf8 = $false
                        break
                    }
                    $utf8Sequences++
                    $i += 3
                } elseif ($sample[$i] -ge 0xF0 -and $sample[$i] -le 0xF7 -and $i + 3 -lt $sample.Length) {
                    # 4-byte sequence (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
                    if ($sample[$i + 1] -lt 0x80 -or $sample[$i + 1] -gt 0xBF -or
                        $sample[$i + 2] -lt 0x80 -or $sample[$i + 2] -gt 0xBF -or
                        $sample[$i + 3] -lt 0x80 -or $sample[$i + 3] -gt 0xBF) {
                        $isUtf8 = $false
                        break
                    }
                    $utf8Sequences++
                    $i += 4
                } else {
                    # Séquence invalide
                    $isUtf8 = $false
                    break
                }
            }
            
            if ($isUtf8 -and $utf8Sequences -gt 0) {
                # Si des séquences UTF-8 multi-octets sont détectées, c'est probablement de l'UTF-8
                $confidence = [Math]::Min(90, 50 + ($utf8Sequences * 5))
                
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "UTF-8"
                    BOM = $false
                    Confidence = $confidence
                    Description = "UTF-8 sans BOM (détecté $utf8Sequences séquences multi-octets)"
                }
            }
            
            # Vérifier si le fichier est probablement ASCII
            $isAscii = $true
            foreach ($byte in $sample) {
                if ($byte -gt 0x7F) {
                    $isAscii = $false
                    break
                }
            }
            
            if ($isAscii) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "ASCII"
                    BOM = $false
                    Confidence = 90
                    Description = "ASCII (tous les caractères < 128)"
                }
            }
            
            # Vérifier les encodages Windows-1252 et ISO-8859-1
            $windows1252Count = 0
            $iso88591Count = 0
            
            foreach ($byte in $sample) {
                if ($byte -gt 0x7F -and $byte -lt 0xA0) {
                    $windows1252Count++
                } elseif ($byte -ge 0xA0 -and $byte -le 0xFF) {
                    $iso88591Count++
                }
            }
            
            if ($windows1252Count -gt 0) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "Windows-1252"
                    BOM = $false
                    Confidence = 70
                    Description = "Windows-1252 (détecté $windows1252Count caractères spécifiques)"
                }
            }
            
            if ($iso88591Count -gt 0) {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Encoding = "ISO-8859-1"
                    BOM = $false
                    Confidence = 60
                    Description = "ISO-8859-1 (Latin-1)"
                }
            }
            
            # Si aucun encodage spécifique n'est détecté, supposer UTF-8 par défaut
            return [PSCustomObject]@{
                FilePath = $FilePath
                Encoding = "UTF-8"
                BOM = $false
                Confidence = 50
                Description = "UTF-8 sans BOM (par défaut)"
            }
        } catch {
            Write-Error "Erreur lors de la détection de l'encodage du fichier $FilePath : $_"
            return [PSCustomObject]@{
                FilePath = $FilePath
                Encoding = "ERROR"
                BOM = $false
                Confidence = 0
                Description = "Erreur: $($_.Exception.Message)"
            }
        }
    }
}

process {
    # Détecter l'encodage du fichier
    $result = Get-FileEncoding -FilePath $FilePath -SampleSize $SampleSize
    
    # Retourner le résultat
    return $result
}

end {
    # Rien à faire ici
}

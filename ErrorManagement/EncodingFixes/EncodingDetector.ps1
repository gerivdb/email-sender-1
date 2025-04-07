<#
.SYNOPSIS
    Détecte automatiquement l'encodage d'un fichier.
.DESCRIPTION
    Ce script analyse un fichier pour déterminer son encodage (UTF-8, UTF-16, ASCII, etc.)
    et indique si le fichier contient un BOM (Byte Order Mark).
.EXAMPLE
    . .\EncodingDetector.ps1
    $encoding = Get-FileEncoding -FilePath "C:\path\to\file.txt"
    Write-Host "Le fichier est encodé en $($encoding.EncodingName)"
#>

function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$FilePath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }
    
    try {
        # Lire les premiers octets du fichier pour détecter le BOM
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Créer l'objet résultat
        $result = [PSCustomObject]@{
            FilePath = $FilePath
            Encoding = $null
            EncodingName = "Unknown"
            HasBOM = $false
            Confidence = 0
            ByteOrderMark = $null
        }
        
        # Détecter le BOM
        if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            $result.Encoding = [System.Text.Encoding]::GetEncoding("utf-32BE")
            $result.EncodingName = "UTF-32 BE"
            $result.HasBOM = $true
            $result.Confidence = 100
            $result.ByteOrderMark = $bytes[0..3]
            return $result
        }
        elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
            $result.Encoding = [System.Text.Encoding]::UTF32
            $result.EncodingName = "UTF-32 LE"
            $result.HasBOM = $true
            $result.Confidence = 100
            $result.ByteOrderMark = $bytes[0..3]
            return $result
        }
        elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $result.Encoding = [System.Text.Encoding]::UTF8
            $result.EncodingName = "UTF-8 with BOM"
            $result.HasBOM = $true
            $result.Confidence = 100
            $result.ByteOrderMark = $bytes[0..2]
            return $result
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            $result.Encoding = [System.Text.Encoding]::BigEndianUnicode
            $result.EncodingName = "UTF-16 BE"
            $result.HasBOM = $true
            $result.Confidence = 100
            $result.ByteOrderMark = $bytes[0..1]
            return $result
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            $result.Encoding = [System.Text.Encoding]::Unicode
            $result.EncodingName = "UTF-16 LE"
            $result.HasBOM = $true
            $result.Confidence = 100
            $result.ByteOrderMark = $bytes[0..1]
            return $result
        }
        
        # Si aucun BOM n'est détecté, essayer de deviner l'encodage
        
        # Vérifier si c'est de l'UTF-8 sans BOM
        $isUtf8 = $true
        $utf8Confidence = 0
        $nonAsciiCount = 0
        
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            # Si c'est un caractère ASCII, continuer
            if ($bytes[$i] -lt 128) {
                continue
            }
            
            $nonAsciiCount++
            
            # Vérifier les séquences UTF-8 valides
            if ($bytes[$i] -ge 0xC2 -and $bytes[$i] -le 0xDF) {
                # Séquence à 2 octets
                if ($i + 1 -ge $bytes.Length -or $bytes[$i + 1] -lt 0x80 -or $bytes[$i + 1] -gt 0xBF) {
                    $isUtf8 = $false
                    break
                }
                $i++
            }
            elseif ($bytes[$i] -ge 0xE0 -and $bytes[$i] -le 0xEF) {
                # Séquence à 3 octets
                if ($i + 2 -ge $bytes.Length -or 
                    $bytes[$i + 1] -lt 0x80 -or $bytes[$i + 1] -gt 0xBF -or
                    $bytes[$i + 2] -lt 0x80 -or $bytes[$i + 2] -gt 0xBF) {
                    $isUtf8 = $false
                    break
                }
                $i += 2
            }
            elseif ($bytes[$i] -ge 0xF0 -and $bytes[$i] -le 0xF7) {
                # Séquence à 4 octets
                if ($i + 3 -ge $bytes.Length -or 
                    $bytes[$i + 1] -lt 0x80 -or $bytes[$i + 1] -gt 0xBF -or
                    $bytes[$i + 2] -lt 0x80 -or $bytes[$i + 2] -gt 0xBF -or
                    $bytes[$i + 3] -lt 0x80 -or $bytes[$i + 3] -gt 0xBF) {
                    $isUtf8 = $false
                    break
                }
                $i += 3
            }
            else {
                $isUtf8 = $false
                break
            }
        }
        
        # Calculer la confiance pour UTF-8
        if ($isUtf8) {
            if ($nonAsciiCount > 0) {
                $utf8Confidence = 90
            }
            else {
                # Si tous les caractères sont ASCII, c'est aussi de l'UTF-8, mais avec une confiance moindre
                $utf8Confidence = 60
            }
        }
        
        # Vérifier si c'est de l'UTF-16 sans BOM
        $isUtf16LE = $true
        $isUtf16BE = $true
        $utf16Confidence = 0
        
        # Vérifier les modèles typiques de l'UTF-16
        if ($bytes.Length % 2 -eq 0 -and $bytes.Length -ge 4) {
            $zeroCount = 0
            
            for ($i = 0; $i -lt [Math]::Min($bytes.Length, 100); $i += 2) {
                # UTF-16 LE: un octet sur deux est souvent 0 pour le texte latin
                if ($bytes[$i + 1] -eq 0) {
                    $zeroCount++
                }
                else {
                    $isUtf16LE = $false
                }
                
                # UTF-16 BE: un octet sur deux est souvent 0 pour le texte latin
                if ($bytes[$i] -eq 0) {
                    $zeroCount++
                }
                else {
                    $isUtf16BE = $false
                }
            }
            
            if ($isUtf16LE -and $zeroCount > 10) {
                $utf16Confidence = 80
            }
            elseif ($isUtf16BE -and $zeroCount > 10) {
                $utf16Confidence = 80
            }
        }
        
        # Déterminer l'encodage le plus probable
        if ($utf8Confidence -ge $utf16Confidence -and $utf8Confidence -gt 0) {
            $result.Encoding = New-Object System.Text.UTF8Encoding $false
            $result.EncodingName = "UTF-8"
            $result.Confidence = $utf8Confidence
        }
        elseif ($isUtf16LE -and $utf16Confidence -gt 0) {
            $result.Encoding = [System.Text.Encoding]::Unicode
            $result.EncodingName = "UTF-16 LE (no BOM)"
            $result.Confidence = $utf16Confidence
        }
        elseif ($isUtf16BE -and $utf16Confidence -gt 0) {
            $result.Encoding = [System.Text.Encoding]::BigEndianUnicode
            $result.EncodingName = "UTF-16 BE (no BOM)"
            $result.Confidence = $utf16Confidence
        }
        else {
            # Par défaut, supposer ASCII ou ANSI (Windows-1252)
            $result.Encoding = [System.Text.Encoding]::GetEncoding(1252)
            $result.EncodingName = "ANSI (Windows-1252)"
            $result.Confidence = 50
        }
        
        return $result
    }
    catch {
        Write-Error "Erreur lors de la détection de l'encodage: $_"
        return $null
    }
}

function Test-FileHasBOM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$FilePath
    )
    
    $encoding = Get-FileEncoding -FilePath $FilePath
    
    if ($null -eq $encoding) {
        return $false
    }
    
    return $encoding.HasBOM
}

function Get-EncodingName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Text.Encoding]$Encoding
    )
    
    $encodingName = switch ($Encoding.GetType().FullName) {
        "System.Text.UTF8Encoding" {
            $utf8 = [System.Text.UTF8Encoding]$Encoding
            if ($utf8.GetPreamble().Length -gt 0) {
                "UTF-8 with BOM"
            }
            else {
                "UTF-8"
            }
        }
        "System.Text.UnicodeEncoding" {
            if ($Encoding.GetPreamble()[0] -eq 0xFF) {
                "UTF-16 LE"
            }
            else {
                "UTF-16 BE"
            }
        }
        "System.Text.UTF32Encoding" {
            if ($Encoding.GetPreamble()[0] -eq 0xFF) {
                "UTF-32 LE"
            }
            else {
                "UTF-32 BE"
            }
        }
        "System.Text.ASCIIEncoding" { "ASCII" }
        default {
            try {
                $Encoding.WebName
            }
            catch {
                "Unknown"
            }
        }
    }
    
    return $encodingName
}

# Exporter les fonctions
Export-ModuleMember -Function Get-FileEncoding, Test-FileHasBOM, Get-EncodingName

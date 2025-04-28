<#
.SYNOPSIS
    DÃ©tecte automatiquement l'encodage d'un fichier.

.DESCRIPTION
    Ce script analyse un fichier pour dÃ©terminer son encodage (UTF-8, UTF-8 avec BOM, ASCII, etc.).
    Il utilise plusieurs mÃ©thodes pour dÃ©tecter l'encodage avec prÃ©cision.

.PARAMETER FilePath
    Chemin du fichier Ã  analyser.

.EXAMPLE
    .\EncodingDetector.ps1 -FilePath "C:\path\to\file.ps1"

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

function Test-FileExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "Le fichier '$Path' n'existe pas ou n'est pas un fichier."
        return $false
    }
    
    return $true
}

function Get-FileEncoding {
    param (
        [string]$Path
    )
    
    try {
        # Lire les premiers octets du fichier pour dÃ©tecter les BOM (Byte Order Mark)
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        
        # VÃ©rifier les diffÃ©rents BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return @{
                Encoding = "UTF-8 with BOM"
                EncodingObj = [System.Text.Encoding]::UTF8
                HasBOM = $true
            }
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            return @{
                Encoding = "UTF-16 BE"
                EncodingObj = [System.Text.Encoding]::BigEndianUnicode
                HasBOM = $true
            }
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            if ($bytes.Length -ge 4 -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                return @{
                    Encoding = "UTF-32 LE"
                    EncodingObj = [System.Text.Encoding]::UTF32
                    HasBOM = $true
                }
            }
            else {
                return @{
                    Encoding = "UTF-16 LE"
                    EncodingObj = [System.Text.Encoding]::Unicode
                    HasBOM = $true
                }
            }
        }
        elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            return @{
                Encoding = "UTF-32 BE"
                EncodingObj = [System.Text.Encoding]::GetEncoding("utf-32BE")
                HasBOM = $true
            }
        }
        
        # Si aucun BOM n'est dÃ©tectÃ©, essayer de dÃ©terminer l'encodage par analyse du contenu
        # VÃ©rifier si le fichier contient des caractÃ¨res nuls (indicateur de UTF-16/UTF-32)
        $containsNulls = $false
        for ($i = 0; $i -lt [Math]::Min($bytes.Length, 1000); $i++) {
            if ($bytes[$i] -eq 0) {
                $containsNulls = $true
                break
            }
        }
        
        if ($containsNulls) {
            # VÃ©rifier le modÃ¨le des octets nuls pour distinguer UTF-16 et UTF-32
            $pattern = 0
            for ($i = 0; $i -lt [Math]::Min($bytes.Length, 100); $i += 2) {
                if ($i + 1 -lt $bytes.Length -and $bytes[$i] -eq 0 -and $bytes[$i + 1] -ne 0) {
                    $pattern += 1
                }
                elseif ($i + 1 -lt $bytes.Length -and $bytes[$i] -ne 0 -and $bytes[$i + 1] -eq 0) {
                    $pattern += 2
                }
            }
            
            if ($pattern -gt 10) {
                if ($pattern % 2 -eq 0) {
                    return @{
                        Encoding = "UTF-16 BE (no BOM)"
                        EncodingObj = [System.Text.Encoding]::BigEndianUnicode
                        HasBOM = $false
                    }
                }
                else {
                    return @{
                        Encoding = "UTF-16 LE (no BOM)"
                        EncodingObj = [System.Text.Encoding]::Unicode
                        HasBOM = $false
                    }
                }
            }
        }
        
        # VÃ©rifier si le fichier est valide en UTF-8
        $isValidUtf8 = $true
        $i = 0
        while ($i -lt $bytes.Length) {
            # VÃ©rifier les sÃ©quences UTF-8 valides
            if ($bytes[$i] -lt 0x80) {
                # CaractÃ¨re ASCII (0xxxxxxx)
                $i++
            }
            elseif ($bytes[$i] -ge 0xC0 -and $bytes[$i] -le 0xDF) {
                # SÃ©quence de 2 octets (110xxxxx 10xxxxxx)
                if ($i + 1 -ge $bytes.Length -or ($bytes[$i + 1] -lt 0x80 -or $bytes[$i + 1] -gt 0xBF)) {
                    $isValidUtf8 = $false
                    break
                }
                $i += 2
            }
            elseif ($bytes[$i] -ge 0xE0 -and $bytes[$i] -le 0xEF) {
                # SÃ©quence de 3 octets (1110xxxx 10xxxxxx 10xxxxxx)
                if ($i + 2 -ge $bytes.Length -or 
                    ($bytes[$i + 1] -lt 0x80 -or $bytes[$i + 1] -gt 0xBF) -or 
                    ($bytes[$i + 2] -lt 0x80 -or $bytes[$i + 2] -gt 0xBF)) {
                    $isValidUtf8 = $false
                    break
                }
                $i += 3
            }
            elseif ($bytes[$i] -ge 0xF0 -and $bytes[$i] -le 0xF7) {
                # SÃ©quence de 4 octets (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
                if ($i + 3 -ge $bytes.Length -or 
                    ($bytes[$i + 1] -lt 0x80 -or $bytes[$i + 1] -gt 0xBF) -or 
                    ($bytes[$i + 2] -lt 0x80 -or $bytes[$i + 2] -gt 0xBF) -or 
                    ($bytes[$i + 3] -lt 0x80 -or $bytes[$i + 3] -gt 0xBF)) {
                    $isValidUtf8 = $false
                    break
                }
                $i += 4
            }
            else {
                # SÃ©quence invalide
                $isValidUtf8 = $false
                break
            }
        }
        
        if ($isValidUtf8) {
            return @{
                Encoding = "UTF-8 (no BOM)"
                EncodingObj = New-Object System.Text.UTF8Encoding $false
                HasBOM = $false
            }
        }
        
        # Si ce n'est pas UTF-8 valide, supposer que c'est ASCII ou une autre encodage 8 bits
        # VÃ©rifier si tous les octets sont dans la plage ASCII
        $isAscii = $true
        foreach ($byte in $bytes) {
            if ($byte -gt 127) {
                $isAscii = $false
                break
            }
        }
        
        if ($isAscii) {
            return @{
                Encoding = "ASCII"
                EncodingObj = [System.Text.Encoding]::ASCII
                HasBOM = $false
            }
        }
        
        # Si ce n'est pas ASCII, c'est probablement un encodage 8 bits comme Windows-1252
        return @{
            Encoding = "Windows-1252 (or other 8-bit encoding)"
            EncodingObj = [System.Text.Encoding]::GetEncoding(1252)
            HasBOM = $false
        }
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection de l'encodage: $_"
        return $null
    }
}

function Test-EncodingForSpecialCharacters {
    param (
        [string]$Path,
        [System.Text.Encoding]$Encoding
    )
    
    try {
        $content = [System.IO.File]::ReadAllText($Path, $Encoding)
        $specialChars = [regex]::Matches($content, '[Ã Ã¡Ã¢Ã¤Ã¦Ã£Ã¥ÄÃ¨Ã©ÃªÃ«Ä“Ä—Ä™Ã®Ã¯Ã­Ä«Ä¯Ã¬Ã´Ã¶Ã²Ã³Å“Ã¸ÅÃµÃ»Ã¼Ã¹ÃºÅ«]')
        
        return @{
            SpecialCharCount = $specialChars.Count
            HasSpecialChars = $specialChars.Count -gt 0
            Examples = if ($specialChars.Count -gt 0) { $specialChars[0..([Math]::Min(4, $specialChars.Count - 1))] | ForEach-Object { $_.Value } } else { @() }
        }
    }
    catch {
        Write-Warning "Erreur lors de la vÃ©rification des caractÃ¨res spÃ©ciaux avec l'encodage $($Encoding.WebName): $_"
        return @{
            SpecialCharCount = 0
            HasSpecialChars = $false
            Examples = @()
        }
    }
}

# Fonction principale
function Get-FileEncodingInfo {
    param (
        [string]$Path
    )
    
    if (-not (Test-FileExists -Path $Path)) {
        return
    }
    
    $encodingInfo = Get-FileEncoding -Path $Path
    
    if ($null -eq $encodingInfo) {
        return
    }
    
    $specialCharsInfo = Test-EncodingForSpecialCharacters -Path $Path -Encoding $encodingInfo.EncodingObj
    
    $result = [PSCustomObject]@{
        FilePath = $Path
        Encoding = $encodingInfo.Encoding
        HasBOM = $encodingInfo.HasBOM
        HasSpecialChars = $specialCharsInfo.HasSpecialChars
        SpecialCharCount = $specialCharsInfo.SpecialCharCount
        SpecialCharExamples = $specialCharsInfo.Examples -join ", "
        RecommendedEncoding = if ($Path -match '\.ps1$' -or $specialCharsInfo.HasSpecialChars) { "UTF-8 with BOM" } else { "UTF-8" }
        NeedsConversion = ($encodingInfo.Encoding -ne "UTF-8 with BOM" -and $Path -match '\.ps1$') -or 
                          ($encodingInfo.Encoding -ne "UTF-8 with BOM" -and $specialCharsInfo.HasSpecialChars) -or
                          ($encodingInfo.Encoding -ne "UTF-8 (no BOM)" -and -not $specialCharsInfo.HasSpecialChars -and $Path -notmatch '\.ps1$')
    }
    
    return $result
}

# ExÃ©cution principale
$result = Get-FileEncodingInfo -Path $FilePath

# Afficher les rÃ©sultats
$result | Format-List

# Retourner l'objet pour une utilisation dans d'autres scripts
return $result

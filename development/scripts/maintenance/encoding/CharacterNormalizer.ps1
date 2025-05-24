<#
.SYNOPSIS
    Normalise les caractÃ¨res spÃ©ciaux dans un fichier texte.

.DESCRIPTION
    Ce script normalise les caractÃ¨res spÃ©ciaux (accents, caractÃ¨res non-ASCII) dans un fichier texte
    pour Ã©viter les problÃ¨mes d'encodage et de compatibilitÃ© entre diffÃ©rents systÃ¨mes.

.PARAMETER FilePath
    Chemin du fichier Ã  normaliser.

.PARAMETER OutputPath
    Chemin du fichier de sortie. Si non spÃ©cifiÃ©, le fichier original sera remplacÃ©.

.PARAMETER NormalizationForm
    Forme de normalisation Unicode Ã  utiliser. Les valeurs possibles sont:
    - FormD: DÃ©composition canonique
    - FormC: DÃ©composition suivie d'une recomposition canonique (par dÃ©faut)
    - FormKD: DÃ©composition de compatibilitÃ©
    - FormKC: DÃ©composition de compatibilitÃ© suivie d'une recomposition canonique

.PARAMETER RemoveAccents
    Si spÃ©cifiÃ©, les accents seront supprimÃ©s des caractÃ¨res (ex: Ã© -> e).

.PARAMETER ReplaceNonAscii
    Si spÃ©cifiÃ©, les caractÃ¨res non-ASCII seront remplacÃ©s par leurs Ã©quivalents ASCII ou par des caractÃ¨res de substitution.

.EXAMPLE
    .\CharacterNormalizer.ps1 -FilePath "C:\path\to\file.txt" -RemoveAccents

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("FormD", "FormC", "FormKD", "FormKC")]
    [string]$NormalizationForm = "FormC",
    
    [Parameter(Mandatory = $false)]
    [switch]$RemoveAccents,
    
    [Parameter(Mandatory = $false)]
    [switch]$ReplaceNonAscii
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
    
    # Utiliser le script EncodingDetector.ps1 s'il est disponible
    $encodingDetectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingDetector.ps1"
    
    if (Test-Path -Path $encodingDetectorPath -PathType Leaf) {
        $encodingInfo = & $encodingDetectorPath -FilePath $Path
        return $encodingInfo.Encoding, $encodingInfo.HasBOM
    }
    
    # MÃ©thode de secours si EncodingDetector.ps1 n'est pas disponible
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        
        # VÃ©rifier les diffÃ©rents BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return "UTF-8 with BOM", $true
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            return "UTF-16 BE", $true
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            if ($bytes.Length -ge 4 -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                return "UTF-32 LE", $true
            }
            else {
                return "UTF-16 LE", $true
            }
        }
        elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            return "UTF-32 BE", $true
        }
        
        # Si aucun BOM n'est dÃ©tectÃ©, supposer UTF-8 sans BOM
        return "UTF-8 (no BOM)", $false
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection de l'encodage: $_"
        return "UTF-8 (no BOM)", $false
    }
}

function Get-EncodingObject {
    param (
        [string]$EncodingName,
        [bool]$HasBOM
    )
    
    switch -Regex ($EncodingName) {
        "UTF-8.*BOM" {
            return [System.Text.Encoding]::UTF8
        }
        "UTF-8" {
            return New-Object System.Text.UTF8Encoding $false
        }
        "UTF-16 LE" {
            return [System.Text.Encoding]::Unicode
        }
        "UTF-16 BE" {
            return [System.Text.Encoding]::BigEndianUnicode
        }
        "UTF-32 LE" {
            return [System.Text.Encoding]::UTF32
        }
        "UTF-32 BE" {
            return [System.Text.Encoding]::GetEncoding("utf-32BE")
        }
        "ASCII" {
            return [System.Text.Encoding]::ASCII
        }
        default {
            # Par dÃ©faut, utiliser Windows-1252
            return [System.Text.Encoding]::GetEncoding(1252)
        }
    }
}

function Remove-Diacritics {
    param (
        [string]$Text
    )
    
    $normalizedText = $Text.Normalize([Text.NormalizationForm]::FormD)
    $stringBuilder = New-Object Text.StringBuilder
    
    foreach ($c in $normalizedText.ToCharArray()) {
        $unicodeCategory = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($c)
        if ($unicodeCategory -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$stringBuilder.Append($c)
        }
    }
    
    return $stringBuilder.ToString()
}

function Set-NonAsciiChars {
    param (
        [string]$Text
    )
    
    # Table de correspondance pour les caractÃ¨res non-ASCII courants
    $replacements = @{
        'Ã ' = 'a'; 'Ã¡' = 'a'; 'Ã¢' = 'a'; 'Ã£' = 'a'; 'Ã¤' = 'a'; 'Ã¥' = 'a'; 'Ã¦' = 'ae'
        'Ã§' = 'c'; 'Ä' = 'c'
        'Ã¨' = 'e'; 'Ã©' = 'e'; 'Ãª' = 'e'; 'Ã«' = 'e'; 'Ä“' = 'e'; 'Ä—' = 'e'; 'Ä™' = 'e'
        'Ã¬' = 'i'; 'Ã­' = 'i'; 'Ã®' = 'i'; 'Ã¯' = 'i'; 'Ä«' = 'i'; 'Ä¯' = 'i'
        'Ã±' = 'n'; 'Å„' = 'n'
        'Ã²' = 'o'; 'Ã³' = 'o'; 'Ã´' = 'o'; 'Ãµ' = 'o'; 'Ã¶' = 'o'; 'Ã¸' = 'o'; 'Å' = 'o'; 'Å“' = 'oe'
        'Ã¹' = 'u'; 'Ãº' = 'u'; 'Ã»' = 'u'; 'Ã¼' = 'u'; 'Å«' = 'u'
        'Ã½' = 'y'; 'Ã¿' = 'y'
        'ÃŸ' = 'ss'
        'Ãž' = 'th'
        'Ã€' = 'A'; 'Ã' = 'A'; 'Ã‚' = 'A'; 'Ãƒ' = 'A'; 'Ã„' = 'A'; 'Ã…' = 'A'; 'Ã†' = 'AE'
        'Ã‡' = 'C'; 'ÄŒ' = 'C'
        'Ãˆ' = 'E'; 'Ã‰' = 'E'; 'ÃŠ' = 'E'; 'Ã‹' = 'E'; 'Ä’' = 'E'; 'Ä–' = 'E'; 'Ä˜' = 'E'
        'ÃŒ' = 'I'; 'Ã' = 'I'; 'ÃŽ' = 'I'; 'Ã' = 'I'; 'Äª' = 'I'; 'Ä®' = 'I'
        'Ã‘' = 'N'; 'Åƒ' = 'N'
        'Ã’' = 'O'; 'Ã“' = 'O'; 'Ã”' = 'O'; 'Ã•' = 'O'; 'Ã–' = 'O'; 'Ã˜' = 'O'; 'ÅŒ' = 'O'; 'Å’' = 'OE'
        'Ã™' = 'U'; 'Ãš' = 'U'; 'Ã›' = 'U'; 'Ãœ' = 'U'; 'Åª' = 'U'
        'Ã' = 'Y'; 'Å¸' = 'Y'
        'Â«' = '"'; 'Â»' = '"'; 'â€ž' = '"'; '"' = '"'; '"' = '"'
        ''' = "'"; ''' = "'"
        'â‚¬' = 'EUR'; 'Â£' = 'GBP'; 'Â¥' = 'JPY'
        'Â©' = '(c)'; 'Â®' = '(r)'; 'â„¢' = '(tm)'
        'Â°' = ' degrees'
        'Â±' = '+/-'
        'Ã—' = 'x'
        'Ã·' = '/'
        'â€¦' = '...'
        'â€¢' = '*'
        'Â·' = '-'
        'Â¿' = '?'
        'Â¡' = '!'
        'Â¼' = '1/4'; 'Â½' = '1/2'; 'Â¾' = '3/4'
    }
    
    # Remplacer les caractÃ¨res connus
    foreach ($key in $replacements.Keys) {
        $Text = $Text.Replace($key, $replacements[$key])
    }
    
    # Remplacer les caractÃ¨res restants non-ASCII par un point d'interrogation
    $result = ""
    foreach ($c in $Text.ToCharArray()) {
        if ([int]$c -lt 128) {
            $result += $c
        }
        else {
            $result += "?"
        }
    }
    
    return $result
}

function ConvertTo-Text {
    param (
        [string]$Text,
        [string]$NormForm,
        [bool]$RemoveDiacritics,
        [bool]$ReplaceNonAscii
    )
    
    # Normaliser selon la forme spÃ©cifiÃ©e
    $normalizationForm = [Text.NormalizationForm]::FormC
    switch ($NormForm) {
        "FormD" { $normalizationForm = [Text.NormalizationForm]::FormD }
        "FormC" { $normalizationForm = [Text.NormalizationForm]::FormC }
        "FormKD" { $normalizationForm = [Text.NormalizationForm]::FormKD }
        "FormKC" { $normalizationForm = [Text.NormalizationForm]::FormKC }
    }
    
    $normalizedText = $Text.Normalize($normalizationForm)
    
    # Supprimer les accents si demandÃ©
    if ($RemoveDiacritics) {
        $normalizedText = Remove-Diacritics -Text $normalizedText
    }
    
    # Remplacer les caractÃ¨res non-ASCII si demandÃ©
    if ($ReplaceNonAscii) {
        $normalizedText = Set-NonAsciiChars -Text $normalizedText
    }
    
    return $normalizedText
}

# Fonction principale
function ConvertTo-File {
    param (
        [string]$InputPath,
        [string]$OutputPath,
        [string]$NormForm,
        [bool]$RemoveDiacritics,
        [bool]$ReplaceNonAscii
    )
    
    if (-not (Test-FileExists -Path $InputPath)) {
        return $false
    }
    
    try {
        # DÃ©tecter l'encodage du fichier d'entrÃ©e
        $encodingName, $hasBOM = Get-FileEncoding -Path $InputPath
        $encoding = Get-EncodingObject -EncodingName $encodingName -HasBOM $hasBOM
        
        # Lire le contenu du fichier
        $content = [System.IO.File]::ReadAllText($InputPath, $encoding)
        
        # Normaliser le texte
        $normalizedContent = ConvertTo-Text -Text $content -NormForm $NormForm -RemoveDiacritics $RemoveDiacritics -ReplaceNonAscii $ReplaceNonAscii
        
        # DÃ©terminer le chemin de sortie
        $finalOutputPath = if ($OutputPath -eq "") { $InputPath } else { $OutputPath }
        
        # DÃ©terminer l'encodage de sortie (conserver l'encodage original)
        $outputEncoding = $encoding
        
        # Ã‰crire le contenu normalisÃ© dans le fichier de sortie
        [System.IO.File]::WriteAllText($finalOutputPath, $normalizedContent, $outputEncoding)
        
        Write-Host "Normalisation terminÃ©e. Fichier sauvegardÃ©: $finalOutputPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la normalisation du fichier: $_"
        return $false
    }
}

# ExÃ©cution principale
$result = ConvertTo-File -InputPath $FilePath -OutputPath $OutputPath -NormForm $NormalizationForm -RemoveDiacritics $RemoveAccents.IsPresent -ReplaceNonAscii $ReplaceNonAscii.IsPresent

# Retourner le rÃ©sultat
return $result


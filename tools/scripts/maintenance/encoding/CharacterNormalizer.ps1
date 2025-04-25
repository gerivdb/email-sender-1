<#
.SYNOPSIS
    Normalise les caractères spéciaux dans un fichier texte.

.DESCRIPTION
    Ce script normalise les caractères spéciaux (accents, caractères non-ASCII) dans un fichier texte
    pour éviter les problèmes d'encodage et de compatibilité entre différents systèmes.

.PARAMETER FilePath
    Chemin du fichier à normaliser.

.PARAMETER OutputPath
    Chemin du fichier de sortie. Si non spécifié, le fichier original sera remplacé.

.PARAMETER NormalizationForm
    Forme de normalisation Unicode à utiliser. Les valeurs possibles sont:
    - FormD: Décomposition canonique
    - FormC: Décomposition suivie d'une recomposition canonique (par défaut)
    - FormKD: Décomposition de compatibilité
    - FormKC: Décomposition de compatibilité suivie d'une recomposition canonique

.PARAMETER RemoveAccents
    Si spécifié, les accents seront supprimés des caractères (ex: é -> e).

.PARAMETER ReplaceNonAscii
    Si spécifié, les caractères non-ASCII seront remplacés par leurs équivalents ASCII ou par des caractères de substitution.

.EXAMPLE
    .\CharacterNormalizer.ps1 -FilePath "C:\path\to\file.txt" -RemoveAccents

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
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
    
    # Méthode de secours si EncodingDetector.ps1 n'est pas disponible
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        
        # Vérifier les différents BOM
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
        
        # Si aucun BOM n'est détecté, supposer UTF-8 sans BOM
        return "UTF-8 (no BOM)", $false
    }
    catch {
        Write-Error "Erreur lors de la détection de l'encodage: $_"
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
            # Par défaut, utiliser Windows-1252
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

function Replace-NonAsciiChars {
    param (
        [string]$Text
    )
    
    # Table de correspondance pour les caractères non-ASCII courants
    $replacements = @{
        'à' = 'a'; 'á' = 'a'; 'â' = 'a'; 'ã' = 'a'; 'ä' = 'a'; 'å' = 'a'; 'æ' = 'ae'
        'ç' = 'c'; 'č' = 'c'
        'è' = 'e'; 'é' = 'e'; 'ê' = 'e'; 'ë' = 'e'; 'ē' = 'e'; 'ė' = 'e'; 'ę' = 'e'
        'ì' = 'i'; 'í' = 'i'; 'î' = 'i'; 'ï' = 'i'; 'ī' = 'i'; 'į' = 'i'
        'ñ' = 'n'; 'ń' = 'n'
        'ò' = 'o'; 'ó' = 'o'; 'ô' = 'o'; 'õ' = 'o'; 'ö' = 'o'; 'ø' = 'o'; 'ō' = 'o'; 'œ' = 'oe'
        'ù' = 'u'; 'ú' = 'u'; 'û' = 'u'; 'ü' = 'u'; 'ū' = 'u'
        'ý' = 'y'; 'ÿ' = 'y'
        'ß' = 'ss'
        'Þ' = 'th'
        'À' = 'A'; 'Á' = 'A'; 'Â' = 'A'; 'Ã' = 'A'; 'Ä' = 'A'; 'Å' = 'A'; 'Æ' = 'AE'
        'Ç' = 'C'; 'Č' = 'C'
        'È' = 'E'; 'É' = 'E'; 'Ê' = 'E'; 'Ë' = 'E'; 'Ē' = 'E'; 'Ė' = 'E'; 'Ę' = 'E'
        'Ì' = 'I'; 'Í' = 'I'; 'Î' = 'I'; 'Ï' = 'I'; 'Ī' = 'I'; 'Į' = 'I'
        'Ñ' = 'N'; 'Ń' = 'N'
        'Ò' = 'O'; 'Ó' = 'O'; 'Ô' = 'O'; 'Õ' = 'O'; 'Ö' = 'O'; 'Ø' = 'O'; 'Ō' = 'O'; 'Œ' = 'OE'
        'Ù' = 'U'; 'Ú' = 'U'; 'Û' = 'U'; 'Ü' = 'U'; 'Ū' = 'U'
        'Ý' = 'Y'; 'Ÿ' = 'Y'
        '«' = '"'; '»' = '"'; '„' = '"'; '"' = '"'; '"' = '"'
        ''' = "'"; ''' = "'"
        '€' = 'EUR'; '£' = 'GBP'; '¥' = 'JPY'
        '©' = '(c)'; '®' = '(r)'; '™' = '(tm)'
        '°' = ' degrees'
        '±' = '+/-'
        '×' = 'x'
        '÷' = '/'
        '…' = '...'
        '•' = '*'
        '·' = '-'
        '¿' = '?'
        '¡' = '!'
        '¼' = '1/4'; '½' = '1/2'; '¾' = '3/4'
    }
    
    # Remplacer les caractères connus
    foreach ($key in $replacements.Keys) {
        $Text = $Text.Replace($key, $replacements[$key])
    }
    
    # Remplacer les caractères restants non-ASCII par un point d'interrogation
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

function Normalize-Text {
    param (
        [string]$Text,
        [string]$NormForm,
        [bool]$RemoveDiacritics,
        [bool]$ReplaceNonAscii
    )
    
    # Normaliser selon la forme spécifiée
    $normalizationForm = [Text.NormalizationForm]::FormC
    switch ($NormForm) {
        "FormD" { $normalizationForm = [Text.NormalizationForm]::FormD }
        "FormC" { $normalizationForm = [Text.NormalizationForm]::FormC }
        "FormKD" { $normalizationForm = [Text.NormalizationForm]::FormKD }
        "FormKC" { $normalizationForm = [Text.NormalizationForm]::FormKC }
    }
    
    $normalizedText = $Text.Normalize($normalizationForm)
    
    # Supprimer les accents si demandé
    if ($RemoveDiacritics) {
        $normalizedText = Remove-Diacritics -Text $normalizedText
    }
    
    # Remplacer les caractères non-ASCII si demandé
    if ($ReplaceNonAscii) {
        $normalizedText = Replace-NonAsciiChars -Text $normalizedText
    }
    
    return $normalizedText
}

# Fonction principale
function Normalize-File {
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
        # Détecter l'encodage du fichier d'entrée
        $encodingName, $hasBOM = Get-FileEncoding -Path $InputPath
        $encoding = Get-EncodingObject -EncodingName $encodingName -HasBOM $hasBOM
        
        # Lire le contenu du fichier
        $content = [System.IO.File]::ReadAllText($InputPath, $encoding)
        
        # Normaliser le texte
        $normalizedContent = Normalize-Text -Text $content -NormForm $NormForm -RemoveDiacritics $RemoveDiacritics -ReplaceNonAscii $ReplaceNonAscii
        
        # Déterminer le chemin de sortie
        $finalOutputPath = if ($OutputPath -eq "") { $InputPath } else { $OutputPath }
        
        # Déterminer l'encodage de sortie (conserver l'encodage original)
        $outputEncoding = $encoding
        
        # Écrire le contenu normalisé dans le fichier de sortie
        [System.IO.File]::WriteAllText($finalOutputPath, $normalizedContent, $outputEncoding)
        
        Write-Host "Normalisation terminée. Fichier sauvegardé: $finalOutputPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la normalisation du fichier: $_"
        return $false
    }
}

# Exécution principale
$result = Normalize-File -InputPath $FilePath -OutputPath $OutputPath -NormForm $NormalizationForm -RemoveDiacritics $RemoveAccents.IsPresent -ReplaceNonAscii $ReplaceNonAscii.IsPresent

# Retourner le résultat
return $result

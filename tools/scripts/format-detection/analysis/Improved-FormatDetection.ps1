#Requires -Version 5.1
<#
.SYNOPSIS
    Détection avancée de format de fichiers avec système de score.

.DESCRIPTION
    Ce script implémente une détection avancée de format de fichiers en utilisant
    un système de score basé sur plusieurs critères : extension, signatures binaires,
    motifs de contenu, et analyse de structure. Il permet également de détecter
    l'encodage des fichiers texte.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER CriteriaPath
    Le chemin vers le fichier JSON contenant les critères de détection.
    Par défaut, utilise 'FormatDetectionCriteria.json' dans le même répertoire.

.PARAMETER DetailedOutput
    Indique si le script doit retourner des informations détaillées sur la détection,
    incluant les scores pour chaque format et les critères correspondants.

.PARAMETER DetectEncoding
    Indique si le script doit tenter de détecter l'encodage des fichiers texte.

.EXAMPLE
    .\Improved-FormatDetection.ps1 -FilePath "C:\Temp\document.docx"

.EXAMPLE
    .\Improved-FormatDetection.ps1 -FilePath "C:\Temp\script.ps1" -DetailedOutput -DetectEncoding

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
    [string]$CriteriaPath = (Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionCriteria.json"),
    
    [Parameter()]
    [switch]$DetailedOutput,
    
    [Parameter()]
    [switch]$DetectEncoding
)

begin {
    # Vérifier si le module PSCacheManager est disponible
    if (-not (Get-Module -Name PSCacheManager -ListAvailable)) {
        Write-Verbose "Le module PSCacheManager n'est pas disponible. Les résultats ne seront pas mis en cache."
        $useCache = $false
    } else {
        Import-Module PSCacheManager
        $useCache = $true
    }
    
    # Charger les critères de détection
    if (Test-Path -Path $CriteriaPath -PathType Leaf) {
        try {
            $formatCriteria = Get-Content -Path $CriteriaPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            Write-Verbose "Critères de détection chargés depuis $CriteriaPath"
        } catch {
            Write-Error "Impossible de charger les critères de détection depuis $CriteriaPath : $_"
            return
        }
    } else {
        Write-Error "Le fichier de critères $CriteriaPath n'existe pas."
        return
    }
    
    # Fonction pour détecter l'encodage d'un fichier
    function Get-FileEncoding {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath
        )
        
        try {
            # Lire les premiers octets du fichier pour détecter les BOM
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)
            
            # Vérifier les BOM (Byte Order Mark)
            if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
                return "UTF-32BE"
            }
            if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                return "UTF-32LE"
            }
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                return "UTF-8-BOM"
            }
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
                return "UTF-16BE"
            }
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
                return "UTF-16LE"
            }
            
            # Si aucun BOM n'est détecté, essayer de déterminer l'encodage par analyse du contenu
            # Lire les premiers 4 Ko du fichier
            $sampleSize = [Math]::Min(4096, $bytes.Length)
            $sample = $bytes[0..($sampleSize - 1)]
            
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
                
                for ($i = 0; $i -lt $sample.Length - 1; $i += 2) {
                    if ($sample[$i] -eq 0 -and $sample[$i + 1] -ne 0) {
                        $utf16BEPattern = $false
                    }
                    if ($sample[$i] -ne 0 -and $sample[$i + 1] -eq 0) {
                        $utf16LEPattern = $false
                    }
                }
                
                if ($utf16LEPattern) {
                    return "UTF-16LE"
                }
                if ($utf16BEPattern) {
                    return "UTF-16BE"
                }
                
                # Si les motifs ne correspondent pas clairement, considérer comme binaire
                return "BINARY"
            }
            
            # Vérifier si le fichier est probablement UTF-8
            $isUtf8 = $true
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
                    $i += 2
                } elseif ($sample[$i] -ge 0xE0 -and $sample[$i] -le 0xEF -and $i + 2 -lt $sample.Length) {
                    # 3-byte sequence (1110xxxx 10xxxxxx 10xxxxxx)
                    if ($sample[$i + 1] -lt 0x80 -or $sample[$i + 1] -gt 0xBF -or
                        $sample[$i + 2] -lt 0x80 -or $sample[$i + 2] -gt 0xBF) {
                        $isUtf8 = $false
                        break
                    }
                    $i += 3
                } elseif ($sample[$i] -ge 0xF0 -and $sample[$i] -le 0xF7 -and $i + 3 -lt $sample.Length) {
                    # 4-byte sequence (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
                    if ($sample[$i + 1] -lt 0x80 -or $sample[$i + 1] -gt 0xBF -or
                        $sample[$i + 2] -lt 0x80 -or $sample[$i + 2] -gt 0xBF -or
                        $sample[$i + 3] -lt 0x80 -or $sample[$i + 3] -gt 0xBF) {
                        $isUtf8 = $false
                        break
                    }
                    $i += 4
                } else {
                    # Séquence invalide
                    $isUtf8 = $false
                    break
                }
            }
            
            if ($isUtf8) {
                return "UTF-8"
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
                return "ASCII"
            }
            
            # Si aucun encodage spécifique n'est détecté, supposer Windows-1252 (ou autre encodage 8 bits)
            return "Windows-1252"
        } catch {
            Write-Error "Erreur lors de la détection de l'encodage du fichier $FilePath : $_"
            return "UNKNOWN"
        }
    }
    
    # Fonction pour vérifier si un fichier est binaire
    function Test-BinaryFile {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter()]
            [double]$MaxBinaryRatio = 0.1,
            
            [Parameter()]
            [int[]]$ControlCharsAllowed = @(9, 10, 13)  # TAB, LF, CR
        )
        
        try {
            # Lire les premiers 4 Ko du fichier
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)
            $sampleSize = [Math]::Min(4096, $bytes.Length)
            $sample = $bytes[0..($sampleSize - 1)]
            
            # Compter les caractères de contrôle non autorisés
            $binaryCount = 0
            foreach ($byte in $sample) {
                if (($byte -lt 32 -and $ControlCharsAllowed -notcontains $byte) -or $byte -eq 0) {
                    $binaryCount++
                }
            }
            
            # Calculer le ratio de caractères binaires
            $binaryRatio = $binaryCount / $sampleSize
            
            # Retourner vrai si le ratio dépasse le seuil
            return $binaryRatio -gt $MaxBinaryRatio
        } catch {
            Write-Error "Erreur lors de la vérification du fichier binaire $FilePath : $_"
            return $true  # En cas d'erreur, considérer comme binaire par sécurité
        }
    }
    
    # Fonction pour vérifier les signatures binaires
    function Test-FileSignature {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $true)]
            [PSObject]$Signature
        )
        
        try {
            # Lire les premiers octets du fichier
            $fileStream = [System.IO.File]::OpenRead($FilePath)
            $buffer = New-Object byte[] 32  # Lire jusqu'à 32 octets pour les signatures
            $bytesRead = $fileStream.Read($buffer, 0, 32)
            $fileStream.Close()
            
            # Vérifier si la signature correspond
            $offset = $Signature.Offset
            
            if ($Signature.Type -eq "HEX") {
                # Signature en octets (HEX)
                $pattern = $Signature.Pattern
                
                # Vérifier si le pattern est un tableau d'octets ou une chaîne
                if ($pattern -is [string]) {
                    # Convertir la chaîne hexadécimale en tableau d'octets
                    $pattern = $pattern -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) }
                }
                
                # Vérifier si le buffer contient suffisamment d'octets
                if ($bytesRead -lt ($offset + $pattern.Length)) {
                    return $false
                }
                
                # Comparer les octets
                for ($i = 0; $i -lt $pattern.Length; $i++) {
                    if ($buffer[$offset + $i] -ne $pattern[$i]) {
                        return $false
                    }
                }
                
                return $true
            } elseif ($Signature.Type -eq "ASCII") {
                # Signature en ASCII
                $pattern = $Signature.Pattern
                
                # Vérifier si le buffer contient suffisamment d'octets
                if ($bytesRead -lt ($offset + $pattern.Length)) {
                    return $false
                }
                
                # Convertir les octets en chaîne ASCII
                $encoding = [System.Text.Encoding]::ASCII
                $text = $encoding.GetString($buffer, $offset, $pattern.Length)
                
                # Comparer les chaînes
                if ($Signature.IgnoreWhitespace) {
                    $text = $text.Trim()
                    $pattern = $pattern.Trim()
                }
                
                return $text -eq $pattern
            }
            
            return $false
        } catch {
            Write-Error "Erreur lors de la vérification de la signature du fichier $FilePath : $_"
            return $false
        }
    }
    
    # Fonction pour vérifier les motifs de contenu
    function Test-ContentPattern {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $true)]
            [PSObject]$ContentPattern
        )
        
        try {
            # Vérifier si le fichier est binaire
            if ($ContentPattern.BinaryTest) {
                if ($ContentPattern.BinaryTest.IsBinary) {
                    return Test-BinaryFile -FilePath $FilePath -MaxBinaryRatio 0
                } else {
                    $maxRatio = 0.1  # Valeur par défaut
                    if ($ContentPattern.BinaryTest.MaxBinaryRatio) {
                        $maxRatio = $ContentPattern.BinaryTest.MaxBinaryRatio
                    }
                    
                    $controlChars = @(9, 10, 13)  # Valeur par défaut
                    if ($ContentPattern.BinaryTest.ControlCharsAllowed) {
                        $controlChars = $ContentPattern.BinaryTest.ControlCharsAllowed
                    }
                    
                    $isBinary = Test-BinaryFile -FilePath $FilePath -MaxBinaryRatio $maxRatio -ControlCharsAllowed $controlChars
                    return -not $isBinary
                }
            }
            
            # Vérifier les expressions régulières
            if ($ContentPattern.Regex) {
                # Lire le contenu du fichier
                $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
                
                if ($null -eq $content) {
                    return $false
                }
                
                # Vérifier chaque expression régulière
                foreach ($regex in $ContentPattern.Regex) {
                    if ($content -match $regex) {
                        return $true
                    }
                }
            }
            
            return $false
        } catch {
            Write-Error "Erreur lors de la vérification des motifs de contenu du fichier $FilePath : $_"
            return $false
        }
    }
    
    # Fonction pour vérifier la structure du fichier
    function Test-FileStructure {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $true)]
            [PSObject]$StructureTest,
            
            [Parameter(Mandatory = $true)]
            [string]$FormatName
        )
        
        try {
            # Vérifier si le fichier est un ZIP
            if ($StructureTest.ZipStructure) {
                # Vérifier si le fichier est un ZIP valide
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
                    
                    # Vérifier les entrées spécifiques pour les formats Office
                    if ($FormatName -eq "WORD" -and $StructureTest.DocxContentTypes) {
                        $hasRequiredEntry = $zip.Entries | Where-Object { $_.FullName -eq $StructureTest.DocxContentTypes.Path }
                        $zip.Dispose()
                        return $null -ne $hasRequiredEntry
                    }
                    
                    if ($FormatName -eq "EXCEL" -and $StructureTest.XlsxContentTypes) {
                        $hasRequiredEntry = $zip.Entries | Where-Object { $_.FullName -eq $StructureTest.XlsxContentTypes.Path }
                        $zip.Dispose()
                        return $null -ne $hasRequiredEntry
                    }
                    
                    if ($FormatName -eq "POWERPOINT" -and $StructureTest.PptxContentTypes) {
                        $hasRequiredEntry = $zip.Entries | Where-Object { $_.FullName -eq $StructureTest.PptxContentTypes.Path }
                        $zip.Dispose()
                        return $null -ne $hasRequiredEntry
                    }
                    
                    $zip.Dispose()
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Vérifier si le fichier est un JSON valide
            if ($StructureTest.ValidJson) {
                try {
                    $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                    $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Vérifier si le fichier est un XML valide
            if ($StructureTest.WellFormed) {
                try {
                    $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                    $xml = New-Object System.Xml.XmlDocument
                    $xml.LoadXml($content)
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Vérifier si le fichier a des balises HTML requises
            if ($StructureTest.RequiredTags) {
                try {
                    $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                    
                    foreach ($tag in $StructureTest.RequiredTags) {
                        if ($content -notmatch "<$tag[>\s]") {
                            return $false
                        }
                    }
                    
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Vérifier si le fichier a un délimiteur cohérent (CSV, TSV)
            if ($StructureTest.ConsistentDelimiter) {
                try {
                    $content = Get-Content -Path $FilePath -ErrorAction Stop
                    
                    if ($content.Count -lt 2) {
                        return $false
                    }
                    
                    $delimiter = $StructureTest.ConsistentDelimiter
                    $firstLineCount = ($content[0] -split [regex]::Escape($delimiter)).Count
                    
                    # Vérifier si toutes les lignes ont le même nombre de champs
                    for ($i = 1; $i -lt [Math]::Min(10, $content.Count); $i++) {
                        $lineCount = ($content[$i] -split [regex]::Escape($delimiter)).Count
                        if ($lineCount -ne $firstLineCount) {
                            return $false
                        }
                    }
                    
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Vérifier si le fichier a une indentation cohérente (Python)
            if ($StructureTest.Indentation) {
                try {
                    $content = Get-Content -Path $FilePath -ErrorAction Stop
                    
                    if ($content.Count -lt 5) {
                        return $false
                    }
                    
                    $indentedLines = 0
                    $totalLines = 0
                    
                    foreach ($line in $content) {
                        if ($line.Trim().Length -gt 0) {
                            $totalLines++
                            if ($line -match '^\s+') {
                                $indentedLines++
                            }
                        }
                    }
                    
                    # Si au moins 20% des lignes sont indentées, c'est probablement du code indenté
                    return ($totalLines -gt 0) -and (($indentedLines / $totalLines) -gt 0.2)
                } catch {
                    return $false
                }
            }
            
            # Vérifier si le fichier a des sauts de ligne (TEXT)
            if ($StructureTest.LineBreaks) {
                try {
                    $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                    return $content -match '\r\n|\r|\n'
                } catch {
                    return $false
                }
            }
            
            # Si aucun test spécifique n'est défini, retourner vrai
            return $true
        } catch {
            Write-Error "Erreur lors de la vérification de la structure du fichier $FilePath : $_"
            return $false
        }
    }
    
    # Fonction pour calculer le score de détection
    function Get-FormatDetectionScore {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $true)]
            [string]$FormatName,
            
            [Parameter(Mandatory = $true)]
            [PSObject]$FormatCriteria
        )
        
        $score = 0
        $maxScore = 0
        $matchedCriteria = @()
        
        # Vérifier l'extension
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        if ($FormatCriteria.Extensions -contains $extension) {
            $score += 30
            $matchedCriteria += "Extension ($extension)"
        }
        $maxScore += 30
        
        # Vérifier les signatures
        if ($FormatCriteria.Signatures) {
            $signatureMatched = $false
            foreach ($signature in $FormatCriteria.Signatures) {
                if (Test-FileSignature -FilePath $FilePath -Signature $signature) {
                    $signatureMatched = $true
                    break
                }
            }
            
            if ($signatureMatched) {
                $score += 40
                $matchedCriteria += "Signature"
            }
            $maxScore += 40
        }
        
        # Vérifier les motifs de contenu
        if ($FormatCriteria.ContentPatterns) {
            if (Test-ContentPattern -FilePath $FilePath -ContentPattern $FormatCriteria.ContentPatterns) {
                $score += 20
                $matchedCriteria += "Contenu"
            }
            $maxScore += 20
        }
        
        # Vérifier la structure
        if ($FormatCriteria.StructureTests) {
            if (Test-FileStructure -FilePath $FilePath -StructureTest $FormatCriteria.StructureTests -FormatName $FormatName) {
                $score += 10
                $matchedCriteria += "Structure"
            }
            $maxScore += 10
        }
        
        # Calculer le score normalisé (0-100)
        $normalizedScore = 0
        if ($maxScore -gt 0) {
            $normalizedScore = [Math]::Round(($score / $maxScore) * 100)
        }
        
        # Retourner le résultat
        return [PSCustomObject]@{
            Format = $FormatName
            Score = $normalizedScore
            MatchedCriteria = $matchedCriteria
            Priority = $FormatCriteria.Priority
        }
    }
}

process {
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier $FilePath n'existe pas."
        return
    }
    
    # Utiliser le cache si disponible
    if ($useCache) {
        $fileInfo = Get-Item -Path $FilePath
        $cacheKey = "ImprovedFormatDetection_$($FilePath)_$($fileInfo.LastWriteTime.Ticks)"
        $cachedResult = Get-PSCacheItem -Key $cacheKey
        
        if ($null -ne $cachedResult) {
            Write-Verbose "Résultat récupéré du cache pour $FilePath"
            return $cachedResult
        }
    }
    
    # Calculer les scores pour chaque format
    $scores = @()
    foreach ($format in $formatCriteria.PSObject.Properties) {
        $formatName = $format.Name
        $formatCriteria = $format.Value
        
        $score = Get-FormatDetectionScore -FilePath $FilePath -FormatName $formatName -FormatCriteria $formatCriteria
        $scores += $score
    }
    
    # Trier les scores par score et priorité
    $sortedScores = $scores | Sort-Object -Property Score, Priority -Descending
    
    # Sélectionner le format le plus probable
    $bestMatch = $sortedScores | Select-Object -First 1
    
    # Détecter l'encodage si demandé
    $encoding = $null
    if ($DetectEncoding) {
        $category = ($formatCriteria.PSObject.Properties | Where-Object { $_.Name -eq $bestMatch.Format }).Value.Category
        
        if ($category -eq "TEXT") {
            $encoding = Get-FileEncoding -FilePath $FilePath
        }
    }
    
    # Créer le résultat
    $result = [PSCustomObject]@{
        FilePath = $FilePath
        FileName = [System.IO.Path]::GetFileName($FilePath)
        Extension = [System.IO.Path]::GetExtension($FilePath)
        DetectedFormat = $bestMatch.Format
        Category = ($formatCriteria.PSObject.Properties | Where-Object { $_.Name -eq $bestMatch.Format }).Value.Category
        ConfidenceScore = $bestMatch.Score
        MatchedCriteria = $bestMatch.MatchedCriteria -join ", "
    }
    
    # Ajouter l'encodage si détecté
    if ($encoding) {
        $result | Add-Member -MemberType NoteProperty -Name "Encoding" -Value $encoding
    }
    
    # Ajouter les détails si demandé
    if ($DetailedOutput) {
        $result | Add-Member -MemberType NoteProperty -Name "AllFormats" -Value $sortedScores
    }
    
    # Mettre en cache le résultat si le cache est disponible
    if ($useCache) {
        Set-PSCacheItem -Key $cacheKey -Value $result -TTL 3600
    }
    
    # Retourner le résultat
    return $result
}

end {
    # Rien à faire ici
}

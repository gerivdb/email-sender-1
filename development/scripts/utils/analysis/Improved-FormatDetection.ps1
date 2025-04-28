#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tection avancÃ©e de format de fichiers avec systÃ¨me de score.

.DESCRIPTION
    Ce script implÃ©mente une dÃ©tection avancÃ©e de format de fichiers en utilisant
    un systÃ¨me de score basÃ© sur plusieurs critÃ¨res : extension, signatures binaires,
    motifs de contenu, et analyse de structure. Il permet Ã©galement de dÃ©tecter
    l'encodage des fichiers texte.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER CriteriaPath
    Le chemin vers le fichier JSON contenant les critÃ¨res de dÃ©tection.
    Par dÃ©faut, utilise 'FormatDetectionCriteria.json' dans le mÃªme rÃ©pertoire.

.PARAMETER DetailedOutput
    Indique si le script doit retourner des informations dÃ©taillÃ©es sur la dÃ©tection,
    incluant les scores pour chaque format et les critÃ¨res correspondants.

.PARAMETER DetectEncoding
    Indique si le script doit tenter de dÃ©tecter l'encodage des fichiers texte.

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
    # VÃ©rifier si le module PSCacheManager est disponible
    if (-not (Get-Module -Name PSCacheManager -ListAvailable)) {
        Write-Verbose "Le module PSCacheManager n'est pas disponible. Les rÃ©sultats ne seront pas mis en cache."
        $useCache = $false
    } else {
        Import-Module PSCacheManager
        $useCache = $true
    }
    
    # Charger les critÃ¨res de dÃ©tection
    if (Test-Path -Path $CriteriaPath -PathType Leaf) {
        try {
            $formatCriteria = Get-Content -Path $CriteriaPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            Write-Verbose "CritÃ¨res de dÃ©tection chargÃ©s depuis $CriteriaPath"
        } catch {
            Write-Error "Impossible de charger les critÃ¨res de dÃ©tection depuis $CriteriaPath : $_"
            return
        }
    } else {
        Write-Error "Le fichier de critÃ¨res $CriteriaPath n'existe pas."
        return
    }
    
    # Fonction pour dÃ©tecter l'encodage d'un fichier
    function Get-FileEncoding {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath
        )
        
        try {
            # Lire les premiers octets du fichier pour dÃ©tecter les BOM
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)
            
            # VÃ©rifier les BOM (Byte Order Mark)
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
            
            # Si aucun BOM n'est dÃ©tectÃ©, essayer de dÃ©terminer l'encodage par analyse du contenu
            # Lire les premiers 4 Ko du fichier
            $sampleSize = [Math]::Min(4096, $bytes.Length)
            $sample = $bytes[0..($sampleSize - 1)]
            
            # VÃ©rifier si le fichier contient des octets nuls (caractÃ©ristique de UTF-16/UTF-32)
            $containsNulls = $false
            for ($i = 0; $i -lt $sample.Length; $i++) {
                if ($sample[$i] -eq 0) {
                    $containsNulls = $true
                    break
                }
            }
            
            if ($containsNulls) {
                # VÃ©rifier les motifs de nulls pour UTF-16/UTF-32
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
                
                # Si les motifs ne correspondent pas clairement, considÃ©rer comme binaire
                return "BINARY"
            }
            
            # VÃ©rifier si le fichier est probablement UTF-8
            $isUtf8 = $true
            $i = 0
            while ($i -lt $sample.Length) {
                # VÃ©rifier les sÃ©quences UTF-8 valides
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
                    # SÃ©quence invalide
                    $isUtf8 = $false
                    break
                }
            }
            
            if ($isUtf8) {
                return "UTF-8"
            }
            
            # VÃ©rifier si le fichier est probablement ASCII
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
            
            # Si aucun encodage spÃ©cifique n'est dÃ©tectÃ©, supposer Windows-1252 (ou autre encodage 8 bits)
            return "Windows-1252"
        } catch {
            Write-Error "Erreur lors de la dÃ©tection de l'encodage du fichier $FilePath : $_"
            return "UNKNOWN"
        }
    }
    
    # Fonction pour vÃ©rifier si un fichier est binaire
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
            
            # Compter les caractÃ¨res de contrÃ´le non autorisÃ©s
            $binaryCount = 0
            foreach ($byte in $sample) {
                if (($byte -lt 32 -and $ControlCharsAllowed -notcontains $byte) -or $byte -eq 0) {
                    $binaryCount++
                }
            }
            
            # Calculer le ratio de caractÃ¨res binaires
            $binaryRatio = $binaryCount / $sampleSize
            
            # Retourner vrai si le ratio dÃ©passe le seuil
            return $binaryRatio -gt $MaxBinaryRatio
        } catch {
            Write-Error "Erreur lors de la vÃ©rification du fichier binaire $FilePath : $_"
            return $true  # En cas d'erreur, considÃ©rer comme binaire par sÃ©curitÃ©
        }
    }
    
    # Fonction pour vÃ©rifier les signatures binaires
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
            $buffer = New-Object byte[] 32  # Lire jusqu'Ã  32 octets pour les signatures
            $bytesRead = $fileStream.Read($buffer, 0, 32)
            $fileStream.Close()
            
            # VÃ©rifier si la signature correspond
            $offset = $Signature.Offset
            
            if ($Signature.Type -eq "HEX") {
                # Signature en octets (HEX)
                $pattern = $Signature.Pattern
                
                # VÃ©rifier si le pattern est un tableau d'octets ou une chaÃ®ne
                if ($pattern -is [string]) {
                    # Convertir la chaÃ®ne hexadÃ©cimale en tableau d'octets
                    $pattern = $pattern -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) }
                }
                
                # VÃ©rifier si le buffer contient suffisamment d'octets
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
                
                # VÃ©rifier si le buffer contient suffisamment d'octets
                if ($bytesRead -lt ($offset + $pattern.Length)) {
                    return $false
                }
                
                # Convertir les octets en chaÃ®ne ASCII
                $encoding = [System.Text.Encoding]::ASCII
                $text = $encoding.GetString($buffer, $offset, $pattern.Length)
                
                # Comparer les chaÃ®nes
                if ($Signature.IgnoreWhitespace) {
                    $text = $text.Trim()
                    $pattern = $pattern.Trim()
                }
                
                return $text -eq $pattern
            }
            
            return $false
        } catch {
            Write-Error "Erreur lors de la vÃ©rification de la signature du fichier $FilePath : $_"
            return $false
        }
    }
    
    # Fonction pour vÃ©rifier les motifs de contenu
    function Test-ContentPattern {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $true)]
            [PSObject]$ContentPattern
        )
        
        try {
            # VÃ©rifier si le fichier est binaire
            if ($ContentPattern.BinaryTest) {
                if ($ContentPattern.BinaryTest.IsBinary) {
                    return Test-BinaryFile -FilePath $FilePath -MaxBinaryRatio 0
                } else {
                    $maxRatio = 0.1  # Valeur par dÃ©faut
                    if ($ContentPattern.BinaryTest.MaxBinaryRatio) {
                        $maxRatio = $ContentPattern.BinaryTest.MaxBinaryRatio
                    }
                    
                    $controlChars = @(9, 10, 13)  # Valeur par dÃ©faut
                    if ($ContentPattern.BinaryTest.ControlCharsAllowed) {
                        $controlChars = $ContentPattern.BinaryTest.ControlCharsAllowed
                    }
                    
                    $isBinary = Test-BinaryFile -FilePath $FilePath -MaxBinaryRatio $maxRatio -ControlCharsAllowed $controlChars
                    return -not $isBinary
                }
            }
            
            # VÃ©rifier les expressions rÃ©guliÃ¨res
            if ($ContentPattern.Regex) {
                # Lire le contenu du fichier
                $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
                
                if ($null -eq $content) {
                    return $false
                }
                
                # VÃ©rifier chaque expression rÃ©guliÃ¨re
                foreach ($regex in $ContentPattern.Regex) {
                    if ($content -match $regex) {
                        return $true
                    }
                }
            }
            
            return $false
        } catch {
            Write-Error "Erreur lors de la vÃ©rification des motifs de contenu du fichier $FilePath : $_"
            return $false
        }
    }
    
    # Fonction pour vÃ©rifier la structure du fichier
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
            # VÃ©rifier si le fichier est un ZIP
            if ($StructureTest.ZipStructure) {
                # VÃ©rifier si le fichier est un ZIP valide
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
                    
                    # VÃ©rifier les entrÃ©es spÃ©cifiques pour les formats Office
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
            
            # VÃ©rifier si le fichier est un JSON valide
            if ($StructureTest.ValidJson) {
                try {
                    $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                    $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
                    return $true
                } catch {
                    return $false
                }
            }
            
            # VÃ©rifier si le fichier est un XML valide
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
            
            # VÃ©rifier si le fichier a des balises HTML requises
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
            
            # VÃ©rifier si le fichier a un dÃ©limiteur cohÃ©rent (CSV, TSV)
            if ($StructureTest.ConsistentDelimiter) {
                try {
                    $content = Get-Content -Path $FilePath -ErrorAction Stop
                    
                    if ($content.Count -lt 2) {
                        return $false
                    }
                    
                    $delimiter = $StructureTest.ConsistentDelimiter
                    $firstLineCount = ($content[0] -split [regex]::Escape($delimiter)).Count
                    
                    # VÃ©rifier si toutes les lignes ont le mÃªme nombre de champs
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
            
            # VÃ©rifier si le fichier a une indentation cohÃ©rente (Python)
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
                    
                    # Si au moins 20% des lignes sont indentÃ©es, c'est probablement du code indentÃ©
                    return ($totalLines -gt 0) -and (($indentedLines / $totalLines) -gt 0.2)
                } catch {
                    return $false
                }
            }
            
            # VÃ©rifier si le fichier a des sauts de ligne (TEXT)
            if ($StructureTest.LineBreaks) {
                try {
                    $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                    return $content -match '\r\n|\r|\n'
                } catch {
                    return $false
                }
            }
            
            # Si aucun test spÃ©cifique n'est dÃ©fini, retourner vrai
            return $true
        } catch {
            Write-Error "Erreur lors de la vÃ©rification de la structure du fichier $FilePath : $_"
            return $false
        }
    }
    
    # Fonction pour calculer le score de dÃ©tection
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
        
        # VÃ©rifier l'extension
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        if ($FormatCriteria.Extensions -contains $extension) {
            $score += 30
            $matchedCriteria += "Extension ($extension)"
        }
        $maxScore += 30
        
        # VÃ©rifier les signatures
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
        
        # VÃ©rifier les motifs de contenu
        if ($FormatCriteria.ContentPatterns) {
            if (Test-ContentPattern -FilePath $FilePath -ContentPattern $FormatCriteria.ContentPatterns) {
                $score += 20
                $matchedCriteria += "Contenu"
            }
            $maxScore += 20
        }
        
        # VÃ©rifier la structure
        if ($FormatCriteria.StructureTests) {
            if (Test-FileStructure -FilePath $FilePath -StructureTest $FormatCriteria.StructureTests -FormatName $FormatName) {
                $score += 10
                $matchedCriteria += "Structure"
            }
            $maxScore += 10
        }
        
        # Calculer le score normalisÃ© (0-100)
        $normalizedScore = 0
        if ($maxScore -gt 0) {
            $normalizedScore = [Math]::Round(($score / $maxScore) * 100)
        }
        
        # Retourner le rÃ©sultat
        return [PSCustomObject]@{
            Format = $FormatName
            Score = $normalizedScore
            MatchedCriteria = $matchedCriteria
            Priority = $FormatCriteria.Priority
        }
    }
}

process {
    # VÃ©rifier si le fichier existe
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
            Write-Verbose "RÃ©sultat rÃ©cupÃ©rÃ© du cache pour $FilePath"
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
    
    # Trier les scores par score et prioritÃ©
    $sortedScores = $scores | Sort-Object -Property Score, Priority -Descending
    
    # SÃ©lectionner le format le plus probable
    $bestMatch = $sortedScores | Select-Object -First 1
    
    # DÃ©tecter l'encodage si demandÃ©
    $encoding = $null
    if ($DetectEncoding) {
        $category = ($formatCriteria.PSObject.Properties | Where-Object { $_.Name -eq $bestMatch.Format }).Value.Category
        
        if ($category -eq "TEXT") {
            $encoding = Get-FileEncoding -FilePath $FilePath
        }
    }
    
    # CrÃ©er le rÃ©sultat
    $result = [PSCustomObject]@{
        FilePath = $FilePath
        FileName = [System.IO.Path]::GetFileName($FilePath)
        Extension = [System.IO.Path]::GetExtension($FilePath)
        DetectedFormat = $bestMatch.Format
        Category = ($formatCriteria.PSObject.Properties | Where-Object { $_.Name -eq $bestMatch.Format }).Value.Category
        ConfidenceScore = $bestMatch.Score
        MatchedCriteria = $bestMatch.MatchedCriteria -join ", "
    }
    
    # Ajouter l'encodage si dÃ©tectÃ©
    if ($encoding) {
        $result | Add-Member -MemberType NoteProperty -Name "Encoding" -Value $encoding
    }
    
    # Ajouter les dÃ©tails si demandÃ©
    if ($DetailedOutput) {
        $result | Add-Member -MemberType NoteProperty -Name "AllFormats" -Value $sortedScores
    }
    
    # Mettre en cache le rÃ©sultat si le cache est disponible
    if ($useCache) {
        Set-PSCacheItem -Key $cacheKey -Value $result -TTL 3600
    }
    
    # Retourner le rÃ©sultat
    return $result
}

end {
    # Rien Ã  faire ici
}

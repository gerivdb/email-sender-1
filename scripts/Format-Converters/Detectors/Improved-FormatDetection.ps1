#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte le format d'un fichier en utilisant des critères avancés.

.DESCRIPTION
    Ce script détecte le format d'un fichier en utilisant des critères avancés tels que
    l'extension, les motifs d'en-tête, les motifs de contenu, les motifs de structure,
    et les signatures binaires. Il attribue un score de confiance à chaque format
    potentiel et retourne le format le plus probable.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER CriteriaPath
    Le chemin vers le fichier JSON contenant les critères de détection.
    Par défaut, utilise 'FormatDetectionCriteria.json' dans le même répertoire que ce script.

.PARAMETER IncludeAllFormats
    Indique si tous les formats détectés doivent être inclus dans le résultat.

.PARAMETER MinimumScore
    Le score minimum requis pour qu'un format soit considéré comme valide.
    Par défaut, la valeur est 50.

.EXAMPLE
    Detect-FileFormat -FilePath "C:\path\to\file.txt"
    Détecte le format du fichier spécifié.

.EXAMPLE
    Detect-FileFormat -FilePath "C:\path\to\file.txt" -IncludeAllFormats
    Détecte le format du fichier spécifié et inclut tous les formats détectés dans le résultat.

.NOTES
    Version: 2.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Detect-FileFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$CriteriaPath = (Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionCriteria.json"),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllFormats,
        
        [Parameter(Mandatory = $false)]
        [int]$MinimumScore = 50
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }
    
    # Vérifier si le fichier de critères existe
    if (-not (Test-Path -Path $CriteriaPath -PathType Leaf)) {
        throw "Le fichier de critères '$CriteriaPath' n'existe pas."
    }
    
    # Charger les critères de détection
    try {
        $criteria = Get-Content -Path $CriteriaPath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Erreur lors du chargement des critères de détection : $_"
    }
    
    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    $fileExtension = $fileInfo.Extension.ToLower()
    $fileSize = $fileInfo.Length
    
    # Lire le contenu du fichier
    $isBinary = Test-BinaryFile -FilePath $FilePath
    
    if ($isBinary) {
        $fileContent = Get-BinaryContent -FilePath $FilePath -MaxBytes 1024
    }
    else {
        try {
            $fileContent = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        }
        catch {
            Write-Warning "Erreur lors de la lecture du fichier comme texte. Traitement comme fichier binaire."
            $isBinary = $true
            $fileContent = Get-BinaryContent -FilePath $FilePath -MaxBytes 1024
        }
    }
    
    # Initialiser les résultats
    $formatScores = @{}
    
    # Évaluer chaque format
    foreach ($format in $criteria.PSObject.Properties) {
        $formatName = $format.Name
        $formatCriteria = $format.Value
        
        # Ignorer les formats qui ne correspondent pas à la taille minimale
        if ($fileSize -lt $formatCriteria.MinimumSize) {
            continue
        }
        
        # Initialiser le score et les critères correspondants
        $score = 0
        $matchedCriteria = @()
        
        # Vérifier l'extension
        $extensionScore = 0
        if ($formatCriteria.Extensions -and $formatCriteria.Extensions.Count -gt 0) {
            foreach ($extension in $formatCriteria.Extensions) {
                if ($fileExtension -eq $extension.ToLower()) {
                    $extensionScore = $formatCriteria.ExtensionWeight
                    $matchedCriteria += "Extension ($fileExtension)"
                    break
                }
            }
        }
        $score += $extensionScore
        
        # Vérifier les signatures binaires pour les fichiers binaires
        $binaryScore = 0
        if ($isBinary -and $formatCriteria.BinarySignatures -and $formatCriteria.BinarySignatures.Count -gt 0) {
            foreach ($signature in $formatCriteria.BinarySignatures) {
                $signatureBytes = [byte[]]::new($signature.Signature.Length / 2)
                for ($i = 0; $i -lt $signature.Signature.Length; $i += 2) {
                    $signatureBytes[$i / 2] = [Convert]::ToByte($signature.Signature.Substring($i, 2), 16)
                }
                
                $signatureMatches = $true
                for ($i = 0; $i -lt $signatureBytes.Length; $i++) {
                    if ($signature.Offset + $i -ge $fileContent.Length -or $fileContent[$signature.Offset + $i] -ne $signatureBytes[$i]) {
                        $signatureMatches = $false
                        break
                    }
                }
                
                if ($signatureMatches) {
                    $binaryScore = 100
                    $matchedCriteria += "Signature binaire ($($signature.Description))"
                    break
                }
            }
        }
        $score += $binaryScore
        
        # Pour les fichiers non binaires, vérifier les motifs d'en-tête, de contenu et de structure
        if (-not $isBinary) {
            # Vérifier les motifs d'en-tête
            $headerScore = 0
            if ($formatCriteria.HeaderPatterns -and $formatCriteria.HeaderPatterns.Count -gt 0) {
                foreach ($pattern in $formatCriteria.HeaderPatterns) {
                    if ($fileContent -match $pattern) {
                        $headerScore = $formatCriteria.HeaderWeight
                        $matchedCriteria += "En-tête ($pattern)"
                        break
                    }
                }
            }
            $score += $headerScore
            
            # Vérifier les motifs de contenu
            $contentScore = 0
            $contentMatches = 0
            if ($formatCriteria.ContentPatterns -and $formatCriteria.ContentPatterns.Count -gt 0) {
                foreach ($pattern in $formatCriteria.ContentPatterns) {
                    if ($fileContent -match $pattern) {
                        $contentMatches++
                        $matchedCriteria += "Contenu ($pattern)"
                    }
                }
                
                if ($contentMatches -ge $formatCriteria.RequiredPatternCount) {
                    $contentScore = $formatCriteria.ContentWeight * ($contentMatches / $formatCriteria.ContentPatterns.Count)
                }
            }
            $score += $contentScore
            
            # Vérifier les motifs de structure
            $structureScore = 0
            if ($formatCriteria.StructurePatterns -and $formatCriteria.StructurePatterns.Count -gt 0) {
                foreach ($pattern in $formatCriteria.StructurePatterns) {
                    if ($fileContent -match $pattern) {
                        $structureScore = $formatCriteria.StructureWeight
                        $matchedCriteria += "Structure ($pattern)"
                        break
                    }
                }
            }
            $score += $structureScore
            
            # Vérifier si l'en-tête est requis mais manquant
            if ($formatCriteria.RequireHeader -and $headerScore -eq 0) {
                $score = 0
            }
        }
        
        # Ajouter le format au résultat si le score est suffisant
        if ($score -ge $MinimumScore) {
            $formatScores[$formatName] = @{
                Format = $formatName
                Score = [Math]::Round($score)
                MatchedCriteria = $matchedCriteria
                Priority = $formatCriteria.Priority
            }
        }
    }
    
    # Déterminer le format le plus probable
    $bestFormat = $null
    $bestScore = 0
    $bestPriority = 0
    
    foreach ($format in $formatScores.Keys) {
        $currentScore = $formatScores[$format].Score
        $currentPriority = $formatScores[$format].Priority
        
        if ($currentScore -gt $bestScore -or ($currentScore -eq $bestScore -and $currentPriority -gt $bestPriority)) {
            $bestFormat = $format
            $bestScore = $currentScore
            $bestPriority = $currentPriority
        }
    }
    
    # Créer le résultat
    $result = [PSCustomObject]@{
        FilePath = $FilePath
        Size = $fileSize
        IsBinary = $isBinary
        DetectedFormat = $bestFormat
        ConfidenceScore = $bestScore
        MatchedCriteria = $formatScores[$bestFormat].MatchedCriteria -join ", "
    }
    
    # Ajouter tous les formats détectés si demandé
    if ($IncludeAllFormats) {
        $allFormats = @()
        
        foreach ($format in $formatScores.Keys) {
            $allFormats += [PSCustomObject]@{
                Format = $format
                Score = $formatScores[$format].Score
                MatchedCriteria = $formatScores[$format].MatchedCriteria
                Priority = $formatScores[$format].Priority
            }
        }
        
        $result | Add-Member -MemberType NoteProperty -Name "AllFormats" -Value $allFormats
    }
    
    return $result
}

# Fonction pour vérifier si un fichier est binaire
function Test-BinaryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Lire les premiers octets du fichier
        $stream = [System.IO.File]::OpenRead($FilePath)
        $buffer = [byte[]]::new(1024)
        $bytesRead = $stream.Read($buffer, 0, 1024)
        $stream.Close()
        
        # Vérifier si le fichier contient des caractères nuls ou non imprimables
        $nonPrintableCount = 0
        for ($i = 0; $i -lt $bytesRead; $i++) {
            if ($buffer[$i] -eq 0 -or ($buffer[$i] -lt 32 -and $buffer[$i] -ne 9 -and $buffer[$i] -ne 10 -and $buffer[$i] -ne 13)) {
                $nonPrintableCount++
            }
        }
        
        # Si plus de 10% des caractères sont non imprimables, considérer le fichier comme binaire
        return ($nonPrintableCount / $bytesRead) -gt 0.1
    }
    catch {
        Write-Warning "Erreur lors de la vérification du fichier binaire : $_"
        return $false
    }
}

# Fonction pour lire le contenu binaire d'un fichier
function Get-BinaryContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxBytes = 1024
    )
    
    try {
        # Lire les premiers octets du fichier
        $stream = [System.IO.File]::OpenRead($FilePath)
        $buffer = [byte[]]::new($MaxBytes)
        $bytesRead = $stream.Read($buffer, 0, $MaxBytes)
        $stream.Close()
        
        # Redimensionner le tableau si nécessaire
        if ($bytesRead -lt $MaxBytes) {
            $result = [byte[]]::new($bytesRead)
            [Array]::Copy($buffer, $result, $bytesRead)
            return $result
        }
        
        return $buffer
    }
    catch {
        Write-Warning "Erreur lors de la lecture du contenu binaire : $_"
        return [byte[]]::new(0)
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Detect-FileFormat

#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte le format d'un fichier.

.DESCRIPTION
    Ce script détecte le format d'un fichier en utilisant des critères avancés.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER CriteriaPath
    Le chemin du fichier de critères de détection.

.PARAMETER IncludeAllFormats
    Indique si tous les formats détectés doivent être inclus dans le résultat.

.PARAMETER MinimumScore
    Le score minimum pour qu'un format soit considéré comme détecté.

.EXAMPLE
    Test-FileFormat -FilePath "C:\path\to\file.txt"
    Détecte le format du fichier spécifié.

.EXAMPLE
    Test-FileFormat -FilePath "C:\path\to\file.txt" -IncludeAllFormats
    Détecte le format du fichier spécifié et inclut tous les formats détectés dans le résultat.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Test-FileFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$CriteriaPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllFormats,

        [Parameter(Mandatory = $false)]
        [int]$MinimumScore = 0
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Utiliser le chemin de critères par défaut si non spécifié
    if (-not $CriteriaPath) {
        $CriteriaPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Detectors\FormatDetectionCriteria.json"
    }

    # Vérifier si le fichier de critères existe
    if (-not (Test-Path -Path $CriteriaPath -PathType Leaf)) {
        throw "Le fichier de critères '$CriteriaPath' n'existe pas."
    }

    # Charger les critères de détection
    $criteria = Get-Content -Path $CriteriaPath -Raw | ConvertFrom-Json

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    $fileExtension = $fileInfo.Extension.ToLower()
    $fileSize = $fileInfo.Length

    # Déterminer si le fichier est binaire
    $isBinary = Test-BinaryFile -FilePath $FilePath

    # Initialiser les résultats
    $results = @()

    # Analyser le fichier pour chaque format
    foreach ($format in $criteria.PSObject.Properties.Name) {
        $formatCriteria = $criteria.$format

        # Vérifier la taille minimale
        if ($fileSize -lt $formatCriteria.MinimumSize) {
            continue
        }

        # Initialiser le score
        $score = 0
        $matchedCriteria = @()

        # Vérifier l'extension
        if ($formatCriteria.Extensions -contains $fileExtension) {
            $score += $formatCriteria.ExtensionWeight
            $matchedCriteria += "Extension ($fileExtension)"
        }

        # Si le fichier est binaire, vérifier les signatures binaires
        if ($isBinary) {
            # TODO: Implémenter la vérification des signatures binaires
        }
        else {
            # Lire le contenu du fichier
            $content = Get-Content -Path $FilePath -Raw

            # Vérifier les motifs d'en-tête
            foreach ($pattern in $formatCriteria.HeaderPatterns) {
                if ($content -match $pattern) {
                    $score += $formatCriteria.HeaderWeight / $formatCriteria.HeaderPatterns.Count
                    $matchedCriteria += "En-tête ($pattern)"
                    break
                }
            }

            # Vérifier les motifs de contenu
            foreach ($pattern in $formatCriteria.ContentPatterns) {
                if ($content -match $pattern) {
                    $score += $formatCriteria.ContentWeight / $formatCriteria.ContentPatterns.Count
                    $matchedCriteria += "Contenu ($pattern)"
                }
            }

            # Vérifier les motifs de structure
            foreach ($pattern in $formatCriteria.StructurePatterns) {
                if ($content -match $pattern) {
                    $score += $formatCriteria.StructureWeight / $formatCriteria.StructurePatterns.Count
                    $matchedCriteria += "Structure ($pattern)"
                }
            }
        }

        # Vérifier si le nombre de critères requis est atteint
        if ($matchedCriteria.Count -lt $formatCriteria.RequiredPatternCount) {
            continue
        }

        # Vérifier si l'en-tête est requis et présent
        if ($formatCriteria.RequireHeader -and -not ($matchedCriteria -like "En-tête*")) {
            continue
        }

        # Ajouter le résultat
        $results += [PSCustomObject]@{
            Format = $formatCriteria.Name
            Score = [Math]::Round($score)
            Priority = $formatCriteria.Priority
            MatchedCriteria = $matchedCriteria
        }
    }

    # Filtrer les résultats par score minimum
    $results = $results | Where-Object { $_.Score -ge $MinimumScore }

    # Trier les résultats par score et priorité
    $results = $results | Sort-Object -Property Score, Priority -Descending

    # Créer le résultat
    $result = [PSCustomObject]@{
        FilePath = $FilePath
        Size = $fileSize
        IsBinary = $isBinary
        DetectedFormat = if ($results.Count -gt 0) { $results[0].Format } else { $null }
        ConfidenceScore = if ($results.Count -gt 0) { $results[0].Score } else { 0 }
        MatchedCriteria = if ($results.Count -gt 0) { $results[0].MatchedCriteria -join ", " } else { "" }
    }

    # Ajouter tous les formats détectés si demandé
    if ($IncludeAllFormats) {
        $result | Add-Member -MemberType NoteProperty -Name "AllFormats" -Value $results
    }

    return $result
}

# Fonction pour déterminer si un fichier est binaire
function Test-BinaryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Lire les premiers octets du fichier
    $bytes = Get-Content -Path $FilePath -Encoding Byte -TotalCount 1000

    # Compter le nombre d'octets nuls
    $nullCount = ($bytes | Where-Object { $_ -eq 0 }).Count

    # Si plus de 10% des octets sont nuls, considérer le fichier comme binaire
    return ($nullCount / $bytes.Count) -gt 0.1
}

# Exporter les fonctions
Export-ModuleMember -Function Test-FileFormat

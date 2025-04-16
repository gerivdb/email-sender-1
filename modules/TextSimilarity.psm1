#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'algorithmes de similarité de texte avancés
.DESCRIPTION
    Ce module fournit des algorithmes avancés pour calculer la similarité entre des textes,
    notamment Levenshtein amélioré, similarité cosinus et TF-IDF.
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: similarité, texte, algorithmes, levenshtein, cosinus, tf-idf
#>

using namespace System.Collections.Generic

#region Fonctions privées

# Normalise un texte pour la comparaison
function ConvertTo-NormalizedText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    # Convertir en minuscules
    $normalizedText = $Text.ToLower()

    # Supprimer les commentaires (pour les scripts)
    $normalizedText = $normalizedText -replace '<#.*?#>', '' -replace '#.*?$', ''

    # Supprimer les espaces multiples
    $normalizedText = $normalizedText -replace '\s+', ' '

    # Supprimer les caractères spéciaux
    $normalizedText = $normalizedText -replace '[^\w\s]', ''

    # Supprimer les espaces en début et fin de chaîne
    $normalizedText = $normalizedText.Trim()

    return $normalizedText
}

# Divise un texte en tokens (mots)
function Get-TextTokens {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveStopWords
    )

    # Liste des mots vides (stop words) en anglais et français
    $stopWords = @(
        'a', 'an', 'the', 'and', 'or', 'but', 'if', 'then', 'else', 'when', 'at', 'from', 'by', 'for', 'with', 'about',
        'le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'mais', 'si', 'alors', 'quand', 'à', 'de', 'par', 'pour', 'avec'
    )

    # Normaliser le texte
    $normalizedText = ConvertTo-NormalizedText -Text $Text

    # Diviser en tokens
    $tokens = $normalizedText -split '\s+'

    # Supprimer les mots vides si demandé
    if ($RemoveStopWords) {
        $tokens = $tokens | Where-Object { $_ -notin $stopWords }
    }

    return $tokens
}

# Calcule la fréquence des termes dans un texte
function Get-TermFrequency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Tokens
    )

    $termFrequency = @{}
    $totalTerms = $Tokens.Count

    foreach ($token in $Tokens) {
        if (-not $termFrequency.ContainsKey($token)) {
            $termFrequency[$token] = 0
        }
        $termFrequency[$token]++
    }

    # Normaliser les fréquences
    $normalizedTF = @{}
    foreach ($term in $termFrequency.Keys) {
        $normalizedTF[$term] = $termFrequency[$term] / $totalTerms
    }

    return $normalizedTF
}

# Calcule l'IDF (Inverse Document Frequency) pour un ensemble de documents
function Get-InverseDocumentFrequency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Documents
    )

    $documentCount = $Documents.Count
    $termDocumentCount = @{}
    $idf = @{}

    # Compter le nombre de documents contenant chaque terme
    foreach ($document in $Documents) {
        $uniqueTerms = $document | Select-Object -Unique

        foreach ($term in $uniqueTerms) {
            if (-not $termDocumentCount.ContainsKey($term)) {
                $termDocumentCount[$term] = 0
            }
            $termDocumentCount[$term]++
        }
    }

    # Calculer l'IDF pour chaque terme
    foreach ($term in $termDocumentCount.Keys) {
        $idf[$term] = [Math]::Log($documentCount / $termDocumentCount[$term])
    }

    return $idf
}

# Calcule le vecteur TF-IDF pour un document
function Get-TfIdfVector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TermFrequency,

        [Parameter(Mandatory = $true)]
        [hashtable]$InverseDocumentFrequency
    )

    $tfIdfVector = @{}

    foreach ($term in $TermFrequency.Keys) {
        if ($InverseDocumentFrequency.ContainsKey($term)) {
            $tfIdfVector[$term] = $TermFrequency[$term] * $InverseDocumentFrequency[$term]
        }
    }

    return $tfIdfVector
}

# Calcule le produit scalaire de deux vecteurs
function Get-DotProduct {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$VectorA,

        [Parameter(Mandatory = $true)]
        [hashtable]$VectorB
    )

    $dotProduct = 0

    foreach ($term in $VectorA.Keys) {
        if ($VectorB.ContainsKey($term)) {
            $dotProduct += $VectorA[$term] * $VectorB[$term]
        }
    }

    return $dotProduct
}

# Calcule la norme d'un vecteur
function Get-VectorMagnitude {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Vector
    )

    $sumOfSquares = 0

    foreach ($value in $Vector.Values) {
        $sumOfSquares += [Math]::Pow($value, 2)
    }

    return [Math]::Sqrt($sumOfSquares)
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Calcule la distance de Levenshtein entre deux chaînes
.DESCRIPTION
    Calcule la distance de Levenshtein (nombre minimal d'opérations d'édition) entre deux chaînes
.PARAMETER StringA
    Première chaîne à comparer
.PARAMETER StringB
    Deuxième chaîne à comparer
.EXAMPLE
    Get-LevenshteinDistance -StringA "kitten" -StringB "sitting"
    # Retourne 3
#>
function Get-LevenshteinDistance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StringA,

        [Parameter(Mandatory = $true)]
        [string]$StringB
    )

    $lengthA = $StringA.Length
    $lengthB = $StringB.Length

    # Cas particuliers
    if ($lengthA -eq 0) { return $lengthB }
    if ($lengthB -eq 0) { return $lengthA }

    # Initialiser la matrice de distance
    $distance = New-Object 'int[,]' ($lengthA + 1), ($lengthB + 1)

    # Initialiser la première colonne et la première ligne
    for ($i = 0; $i -le $lengthA; $i++) {
        $distance[$i, 0] = $i
    }

    for ($j = 0; $j -le $lengthB; $j++) {
        $distance[0, $j] = $j
    }

    # Remplir la matrice
    for ($i = 1; $i -le $lengthA; $i++) {
        for ($j = 1; $j -le $lengthB; $j++) {
            $cost = if ($StringA[$i - 1] -eq $StringB[$j - 1]) { 0 } else { 1 }

            $deletion = $distance[$i - 1, $j] + 1
            $insertion = $distance[$i, $j - 1] + 1
            $substitution = $distance[$i - 1, $j - 1] + $cost

            $distance[$i, $j] = [Math]::Min($deletion, [Math]::Min($insertion, $substitution))
        }
    }

    return $distance[$lengthA, $lengthB]
}

<#
.SYNOPSIS
    Calcule la similarité de Levenshtein entre deux chaînes
.DESCRIPTION
    Calcule la similarité de Levenshtein (pourcentage de similarité) entre deux chaînes
.PARAMETER StringA
    Première chaîne à comparer
.PARAMETER StringB
    Deuxième chaîne à comparer
.EXAMPLE
    Get-LevenshteinSimilarity -StringA "kitten" -StringB "sitting"
    # Retourne un pourcentage de similarité
#>
function Get-LevenshteinSimilarity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StringA,

        [Parameter(Mandatory = $true)]
        [string]$StringB
    )

    $distance = Get-LevenshteinDistance -StringA $StringA -StringB $StringB
    $maxLength = [Math]::Max($StringA.Length, $StringB.Length)

    if ($maxLength -eq 0) {
        return 100  # Deux chaînes vides sont identiques
    }

    $similarity = (1 - ($distance / $maxLength)) * 100
    return [Math]::Round($similarity, 2)
}

<#
.SYNOPSIS
    Calcule la similarité cosinus entre deux textes
.DESCRIPTION
    Calcule la similarité cosinus entre deux textes en utilisant les vecteurs TF-IDF
.PARAMETER TextA
    Premier texte à comparer
.PARAMETER TextB
    Deuxième texte à comparer
.PARAMETER RemoveStopWords
    Indique s'il faut supprimer les mots vides (stop words)
.EXAMPLE
    Get-CosineSimilarity -TextA "Ceci est un test" -TextB "Ceci est un exemple"
    # Retourne un pourcentage de similarité
#>
function Get-CosineSimilarity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TextA,

        [Parameter(Mandatory = $true)]
        [string]$TextB,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveStopWords
    )

    # Tokeniser les textes
    $tokensA = Get-TextTokens -Text $TextA -RemoveStopWords:$RemoveStopWords
    $tokensB = Get-TextTokens -Text $TextB -RemoveStopWords:$RemoveStopWords

    # Si l'un des textes est vide après tokenisation, retourner 0
    if ($tokensA.Count -eq 0 -or $tokensB.Count -eq 0) {
        return 0
    }

    # Calculer les fréquences des termes
    $tfA = Get-TermFrequency -Tokens $tokensA
    $tfB = Get-TermFrequency -Tokens $tokensB

    # Calculer l'IDF
    $documents = @($tokensA, $tokensB)
    $idf = Get-InverseDocumentFrequency -Documents $documents

    # Calculer les vecteurs TF-IDF
    $tfIdfA = Get-TfIdfVector -TermFrequency $tfA -InverseDocumentFrequency $idf
    $tfIdfB = Get-TfIdfVector -TermFrequency $tfB -InverseDocumentFrequency $idf

    # Calculer la similarité cosinus
    $dotProduct = Get-DotProduct -VectorA $tfIdfA -VectorB $tfIdfB
    $magnitudeA = Get-VectorMagnitude -Vector $tfIdfA
    $magnitudeB = Get-VectorMagnitude -Vector $tfIdfB

    if ($magnitudeA -eq 0 -or $magnitudeB -eq 0) {
        return 0
    }

    $similarity = $dotProduct / ($magnitudeA * $magnitudeB)
    return [Math]::Round($similarity * 100, 2)
}

<#
.SYNOPSIS
    Calcule la similarité de contenu entre deux fichiers
.DESCRIPTION
    Calcule la similarité de contenu entre deux fichiers en utilisant différents algorithmes
.PARAMETER FilePathA
    Chemin du premier fichier
.PARAMETER FilePathB
    Chemin du deuxième fichier
.PARAMETER Algorithm
    Algorithme à utiliser (Levenshtein, Cosine, Combined)
.PARAMETER RemoveStopWords
    Indique s'il faut supprimer les mots vides (stop words)
.EXAMPLE
    Get-ContentSimilarity -FilePathA "file1.ps1" -FilePathB "file2.ps1" -Algorithm Cosine
    # Retourne un pourcentage de similarité
#>
function Get-ContentSimilarity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePathA,

        [Parameter(Mandatory = $true)]
        [string]$FilePathB,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Levenshtein", "Cosine", "Combined")]
        [string]$Algorithm = "Combined",

        [Parameter(Mandatory = $false)]
        [switch]$RemoveStopWords
    )

    # Vérifier que les fichiers existent
    if (-not (Test-Path $FilePathA) -or -not (Test-Path $FilePathB)) {
        Write-Error "Un ou plusieurs fichiers n'existent pas"
        return 0
    }

    # Lire le contenu des fichiers
    $contentA = Get-Content -Path $FilePathA -Raw
    $contentB = Get-Content -Path $FilePathB -Raw

    # Si l'un des fichiers est vide, retourner 0
    if ([string]::IsNullOrWhiteSpace($contentA) -or [string]::IsNullOrWhiteSpace($contentB)) {
        return 0
    }

    # Calculer la similarité selon l'algorithme choisi
    switch ($Algorithm) {
        "Levenshtein" {
            return Get-LevenshteinSimilarity -StringA $contentA -StringB $contentB
        }
        "Cosine" {
            return Get-CosineSimilarity -TextA $contentA -TextB $contentB -RemoveStopWords:$RemoveStopWords
        }
        "Combined" {
            $levenshteinSimilarity = Get-LevenshteinSimilarity -StringA $contentA -StringB $contentB
            $cosineSimilarity = Get-CosineSimilarity -TextA $contentA -TextB $contentB -RemoveStopWords:$RemoveStopWords

            # Moyenne pondérée (60% cosinus, 40% Levenshtein)
            return [Math]::Round(($cosineSimilarity * 0.6) + ($levenshteinSimilarity * 0.4), 2)
        }
    }
}

<#
.SYNOPSIS
    Trouve les fichiers similaires dans un répertoire
.DESCRIPTION
    Trouve les fichiers similaires dans un répertoire en utilisant différents algorithmes
.PARAMETER Path
    Chemin du répertoire à analyser
.PARAMETER Extensions
    Extensions de fichiers à inclure
.PARAMETER Algorithm
    Algorithme à utiliser (Levenshtein, Cosine, Combined)
.PARAMETER SimilarityThreshold
    Seuil de similarité (0-100) pour considérer deux fichiers comme similaires
.PARAMETER RemoveStopWords
    Indique s'il faut supprimer les mots vides (stop words)
.EXAMPLE
    Find-SimilarFiles -Path "C:\Scripts" -Extensions ".ps1",".psm1" -Algorithm Combined -SimilarityThreshold 80
    # Retourne une liste de fichiers similaires
#>
function Find-SimilarFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Extensions = @(".ps1", ".psm1", ".py", ".cmd", ".bat"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Levenshtein", "Cosine", "Combined")]
        [string]$Algorithm = "Combined",

        [Parameter(Mandatory = $false)]
        [int]$SimilarityThreshold = 80,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveStopWords
    )

    # Vérifier que le répertoire existe
    if (-not (Test-Path $Path -PathType Container)) {
        Write-Error "Le répertoire spécifié n'existe pas"
        return @()
    }

    # Récupérer tous les fichiers avec les extensions spécifiées
    $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object { $Extensions -contains $_.Extension }

    $results = @()
    $fileCount = $files.Count
    $processedPairs = 0
    $totalPairs = ($fileCount * ($fileCount - 1)) / 2

    # Comparer chaque paire de fichiers
    for ($i = 0; $i -lt $fileCount; $i++) {
        for ($j = $i + 1; $j -lt $fileCount; $j++) {
            $processedPairs++
            $percentComplete = [Math]::Round(($processedPairs / $totalPairs) * 100, 2)

            Write-Progress -Activity "Analyse de similarité" -Status "Comparaison $processedPairs/$totalPairs ($percentComplete%)" -PercentComplete $percentComplete

            $fileA = $files[$i]
            $fileB = $files[$j]

            # Calculer la similarité
            $similarity = Get-ContentSimilarity -FilePathA $fileA.FullName -FilePathB $fileB.FullName -Algorithm $Algorithm -RemoveStopWords:$RemoveStopWords

            # Si la similarité dépasse le seuil, ajouter à la liste des résultats
            if ($similarity -ge $SimilarityThreshold) {
                $results += [PSCustomObject]@{
                    FileA      = $fileA.FullName
                    FileB      = $fileB.FullName
                    Similarity = $similarity
                    Algorithm  = $Algorithm
                }
            }
        }
    }

    Write-Progress -Activity "Analyse de similarité" -Completed

    return $results | Sort-Object -Property Similarity -Descending
}

#endregion

# Exporter les fonctions
Export-ModuleMember -Function Get-LevenshteinDistance, Get-LevenshteinSimilarity, Get-CosineSimilarity, Get-ContentSimilarity, Find-SimilarFiles

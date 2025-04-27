<#
.SYNOPSIS
    Analyse et mesure un texte selon diffÃ©rents critÃ¨res.

.DESCRIPTION
    La fonction Measure-RoadmapText analyse et mesure un texte selon diffÃ©rents critÃ¨res.
    Elle prend en charge diffÃ©rents types de mesures et peut Ãªtre utilisÃ©e pour
    analyser les textes du module RoadmapParser.

.PARAMETER Text
    Le texte Ã  analyser.

.PARAMETER MeasureType
    Le type de mesure Ã  effectuer. Valeurs possibles :
    - Length : Mesure la longueur du texte
    - Words : Compte le nombre de mots dans le texte
    - Lines : Compte le nombre de lignes dans le texte
    - Characters : Compte le nombre de caractÃ¨res dans le texte
    - Paragraphs : Compte le nombre de paragraphes dans le texte
    - Sentences : Compte le nombre de phrases dans le texte
    - Frequency : Compte la frÃ©quence des mots dans le texte
    - ReadingTime : Estime le temps de lecture du texte
    - ReadingLevel : Estime le niveau de lecture du texte
    - Sentiment : Analyse le sentiment du texte
    - Keywords : Extrait les mots-clÃ©s du texte
    - Statistics : Calcule des statistiques sur le texte
    - Custom : Utilise une mesure personnalisÃ©e

.PARAMETER CustomMeasure
    La fonction de mesure personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque MeasureType est "Custom".

.PARAMETER IgnoreCase
    Indique si la casse doit Ãªtre ignorÃ©e lors de l'analyse.
    Par dÃ©faut, c'est $false.

.PARAMETER IncludeEmptyLines
    Indique si les lignes vides doivent Ãªtre incluses dans le comptage des lignes.
    Par dÃ©faut, c'est $false.

.PARAMETER WordsPerMinute
    Le nombre de mots par minute Ã  utiliser pour l'estimation du temps de lecture.
    Par dÃ©faut, c'est 200.

.PARAMETER IncludeSpecialCharacters
    Indique si les caractÃ¨res spÃ©ciaux doivent Ãªtre inclus dans le comptage des caractÃ¨res.
    Par dÃ©faut, c'est $true.

.PARAMETER IncludeWhitespace
    Indique si les espaces doivent Ãªtre inclus dans le comptage des caractÃ¨res.
    Par dÃ©faut, c'est $true.

.PARAMETER IncludePunctuation
    Indique si la ponctuation doit Ãªtre incluse dans le comptage des caractÃ¨res.
    Par dÃ©faut, c'est $true.

.PARAMETER TopCount
    Le nombre maximum d'Ã©lÃ©ments Ã  retourner pour les mesures qui produisent des listes.
    Par dÃ©faut, c'est 10.

.PARAMETER Culture
    La culture Ã  utiliser pour l'analyse.
    Par dÃ©faut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de l'analyse.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de l'analyse.

.EXAMPLE
    Measure-RoadmapText -Text "Hello World" -MeasureType Length
    Mesure la longueur du texte "Hello World".

.EXAMPLE
    Measure-RoadmapText -Text "Hello World" -MeasureType Words
    Compte le nombre de mots dans le texte "Hello World".

.OUTPUTS
    [object] Le rÃ©sultat de l'analyse.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Measure-RoadmapText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Length", "Words", "Lines", "Characters", "Paragraphs", "Sentences", "Frequency", "ReadingTime", "ReadingLevel", "Sentiment", "Keywords", "Statistics", "Custom")]
        [string]$MeasureType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomMeasure,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeEmptyLines,

        [Parameter(Mandatory = $false)]
        [int]$WordsPerMinute = 200,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSpecialCharacters = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeWhitespace = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePunctuation = $true,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 10,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de l'analyse
    $result = $null
    $measureSucceeded = $false

    # Effectuer l'analyse selon le type
    try {
        switch ($MeasureType) {
            "Length" {
                $result = $Text.Length
                $measureSucceeded = $true
            }
            "Words" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    $words = $Text -split '\s+' | Where-Object { $_ -ne "" }
                    $result = $words.Count
                }
                $measureSucceeded = $true
            }
            "Lines" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    $lines = $Text -split "`r`n|`r|`n"
                    
                    if (-not $IncludeEmptyLines) {
                        $lines = $lines | Where-Object { $_ -ne "" }
                    }
                    
                    $result = $lines.Count
                }
                $measureSucceeded = $true
            }
            "Characters" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    $chars = $Text.ToCharArray()
                    
                    if (-not $IncludeWhitespace) {
                        $chars = $chars | Where-Object { -not [char]::IsWhiteSpace($_) }
                    }
                    
                    if (-not $IncludePunctuation) {
                        $chars = $chars | Where-Object { -not [char]::IsPunctuation($_) }
                    }
                    
                    if (-not $IncludeSpecialCharacters) {
                        $chars = $chars | Where-Object { [char]::IsLetterOrDigit($_) -or [char]::IsWhiteSpace($_) -or [char]::IsPunctuation($_) }
                    }
                    
                    $result = $chars.Count
                }
                $measureSucceeded = $true
            }
            "Paragraphs" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    $paragraphs = $Text -split "`r`n`r`n|`r`r|`n`n"
                    
                    if (-not $IncludeEmptyLines) {
                        $paragraphs = $paragraphs | Where-Object { $_ -ne "" }
                    }
                    
                    $result = $paragraphs.Count
                }
                $measureSucceeded = $true
            }
            "Sentences" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    $sentences = $Text -split '(?<=[.!?])\s+'
                    
                    if (-not $IncludeEmptyLines) {
                        $sentences = $sentences | Where-Object { $_ -ne "" }
                    }
                    
                    $result = $sentences.Count
                }
                $measureSucceeded = $true
            }
            "Frequency" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = @{}
                } else {
                    $words = $Text -split '\s+' | Where-Object { $_ -ne "" }
                    
                    if ($IgnoreCase) {
                        $words = $words | ForEach-Object { $_.ToLower() }
                    }
                    
                    $frequency = @{}
                    foreach ($word in $words) {
                        if ($frequency.ContainsKey($word)) {
                            $frequency[$word]++
                        } else {
                            $frequency[$word] = 1
                        }
                    }
                    
                    $result = $frequency.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $TopCount
                }
                $measureSucceeded = $true
            }
            "ReadingTime" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    $words = $Text -split '\s+' | Where-Object { $_ -ne "" }
                    $wordCount = $words.Count
                    $minutes = $wordCount / $WordsPerMinute
                    $result = [math]::Ceiling($minutes * 60)  # Convertir en secondes et arrondir au supÃ©rieur
                }
                $measureSucceeded = $true
            }
            "ReadingLevel" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    # Calculer le niveau de lecture en utilisant l'indice de lisibilitÃ© de Flesch-Kincaid
                    $words = $Text -split '\s+' | Where-Object { $_ -ne "" }
                    $wordCount = $words.Count
                    
                    $sentences = $Text -split '(?<=[.!?])\s+'
                    $sentenceCount = $sentences.Count
                    
                    $syllableCount = 0
                    foreach ($word in $words) {
                        $syllableCount += Measure-Syllables $word
                    }
                    
                    if ($sentenceCount -eq 0 -or $wordCount -eq 0) {
                        $result = 0
                    } else {
                        $result = 206.835 - 1.015 * ($wordCount / $sentenceCount) - 84.6 * ($syllableCount / $wordCount)
                        $result = [math]::Round($result, 2)
                    }
                }
                $measureSucceeded = $true
            }
            "Sentiment" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    # Analyse de sentiment simplifiÃ©e
                    $positiveWords = @("good", "great", "excellent", "amazing", "wonderful", "fantastic", "happy", "joy", "love", "like", "best", "better", "positive", "success", "successful", "win", "winning", "won", "beautiful", "perfect")
                    $negativeWords = @("bad", "terrible", "horrible", "awful", "worst", "worse", "negative", "fail", "failure", "failed", "hate", "dislike", "sad", "unhappy", "angry", "mad", "upset", "disappointed", "disappointing", "poor")
                    
                    $words = $Text -split '\s+' | Where-Object { $_ -ne "" }
                    
                    if ($IgnoreCase) {
                        $words = $words | ForEach-Object { $_.ToLower() }
                        $positiveWords = $positiveWords | ForEach-Object { $_.ToLower() }
                        $negativeWords = $negativeWords | ForEach-Object { $_.ToLower() }
                    }
                    
                    $positiveCount = 0
                    $negativeCount = 0
                    
                    foreach ($word in $words) {
                        if ($positiveWords -contains $word) {
                            $positiveCount++
                        } elseif ($negativeWords -contains $word) {
                            $negativeCount++
                        }
                    }
                    
                    if ($positiveCount -eq 0 -and $negativeCount -eq 0) {
                        $result = 0  # Neutre
                    } else {
                        $total = $positiveCount + $negativeCount
                        $result = [math]::Round(($positiveCount - $negativeCount) / $total, 2)
                    }
                }
                $measureSucceeded = $true
            }
            "Keywords" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = @()
                } else {
                    # Extraire les mots-clÃ©s en utilisant la frÃ©quence des mots
                    $stopWords = @("a", "an", "the", "and", "or", "but", "is", "are", "was", "were", "be", "been", "being", "in", "on", "at", "to", "for", "with", "by", "about", "against", "between", "into", "through", "during", "before", "after", "above", "below", "from", "up", "down", "of", "off", "over", "under", "again", "further", "then", "once", "here", "there", "when", "where", "why", "how", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very", "s", "t", "can", "will", "just", "don", "should", "now")
                    
                    $words = $Text -split '\s+' | Where-Object { $_ -ne "" }
                    
                    if ($IgnoreCase) {
                        $words = $words | ForEach-Object { $_.ToLower() }
                        $stopWords = $stopWords | ForEach-Object { $_.ToLower() }
                    }
                    
                    $words = $words | Where-Object { $_ -notmatch '^\d+$' -and $_ -notmatch '^[^\w\s]+$' -and $stopWords -notcontains $_ }
                    
                    $frequency = @{}
                    foreach ($word in $words) {
                        if ($frequency.ContainsKey($word)) {
                            $frequency[$word]++
                        } else {
                            $frequency[$word] = 1
                        }
                    }
                    
                    $result = $frequency.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $TopCount | ForEach-Object { $_.Key }
                }
                $measureSucceeded = $true
            }
            "Statistics" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = [PSCustomObject]@{
                        Length = 0
                        WordCount = 0
                        LineCount = 0
                        CharacterCount = 0
                        ParagraphCount = 0
                        SentenceCount = 0
                        AverageWordLength = 0
                        AverageSentenceLength = 0
                        ReadingTime = 0
                        ReadingLevel = 0
                    }
                } else {
                    $words = $Text -split '\s+' | Where-Object { $_ -ne "" }
                    $wordCount = $words.Count
                    
                    $lines = $Text -split "`r`n|`r|`n"
                    if (-not $IncludeEmptyLines) {
                        $lines = $lines | Where-Object { $_ -ne "" }
                    }
                    $lineCount = $lines.Count
                    
                    $chars = $Text.ToCharArray()
                    if (-not $IncludeWhitespace) {
                        $chars = $chars | Where-Object { -not [char]::IsWhiteSpace($_) }
                    }
                    if (-not $IncludePunctuation) {
                        $chars = $chars | Where-Object { -not [char]::IsPunctuation($_) }
                    }
                    if (-not $IncludeSpecialCharacters) {
                        $chars = $chars | Where-Object { [char]::IsLetterOrDigit($_) -or [char]::IsWhiteSpace($_) -or [char]::IsPunctuation($_) }
                    }
                    $charCount = $chars.Count
                    
                    $paragraphs = $Text -split "`r`n`r`n|`r`r|`n`n"
                    if (-not $IncludeEmptyLines) {
                        $paragraphs = $paragraphs | Where-Object { $_ -ne "" }
                    }
                    $paragraphCount = $paragraphs.Count
                    
                    $sentences = $Text -split '(?<=[.!?])\s+'
                    if (-not $IncludeEmptyLines) {
                        $sentences = $sentences | Where-Object { $_ -ne "" }
                    }
                    $sentenceCount = $sentences.Count
                    
                    $averageWordLength = if ($wordCount -gt 0) { ($words | ForEach-Object { $_.Length } | Measure-Object -Average).Average } else { 0 }
                    $averageSentenceLength = if ($sentenceCount -gt 0) { $wordCount / $sentenceCount } else { 0 }
                    
                    $readingTime = if ($wordCount -gt 0) { [math]::Ceiling($wordCount / $WordsPerMinute * 60) } else { 0 }
                    
                    $syllableCount = 0
                    foreach ($word in $words) {
                        $syllableCount += Measure-Syllables $word
                    }
                    
                    $readingLevel = if ($sentenceCount -gt 0 -and $wordCount -gt 0) {
                        206.835 - 1.015 * ($wordCount / $sentenceCount) - 84.6 * ($syllableCount / $wordCount)
                    } else {
                        0
                    }
                    
                    $result = [PSCustomObject]@{
                        Length = $Text.Length
                        WordCount = $wordCount
                        LineCount = $lineCount
                        CharacterCount = $charCount
                        ParagraphCount = $paragraphCount
                        SentenceCount = $sentenceCount
                        AverageWordLength = [math]::Round($averageWordLength, 2)
                        AverageSentenceLength = [math]::Round($averageSentenceLength, 2)
                        ReadingTime = $readingTime
                        ReadingLevel = [math]::Round($readingLevel, 2)
                    }
                }
                $measureSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomMeasure) {
                    throw "Le paramÃ¨tre CustomMeasure est requis lorsque le type de mesure est Custom."
                } else {
                    $result = & $CustomMeasure $Text
                }
                $measureSucceeded = $true
            }
        }
    } catch {
        $measureSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible d'effectuer la mesure $MeasureType sur le texte : $_"
        }
    }

    # GÃ©rer l'Ã©chec de l'analyse
    if (-not $measureSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $null
        }
    }

    return $result
}

# Fonction auxiliaire pour compter les syllabes dans un mot
function Measure-Syllables {
    param (
        [string]$Word
    )
    
    if ([string]::IsNullOrEmpty($Word)) {
        return 0
    }
    
    $word = $Word.ToLower()
    
    # RÃ¨gles spÃ©ciales pour les mots se terminant par "e"
    if ($word -match 'e$' -and $word.Length -gt 2) {
        $word = $word.Substring(0, $word.Length - 1)
    }
    
    # Compter les voyelles
    $vowels = $word -split '' | Where-Object { $_ -match '[aeiouy]' }
    $count = $vowels.Count
    
    # Ajuster pour les diphtongues
    $diphtongs = $word | Select-String -Pattern 'ai|au|ay|ea|ee|ei|eu|ey|ie|oi|oo|ou|oy|ua|ue|ui|uy' -AllMatches
    $count -= $diphtongs.Matches.Count
    
    # Ajuster pour les voyelles consÃ©cutives
    $consecutiveVowels = $word | Select-String -Pattern '[aeiouy]{2,}' -AllMatches
    $count -= $consecutiveVowels.Matches.Count
    
    # Assurer un minimum d'une syllabe
    return [math]::Max(1, $count)
}

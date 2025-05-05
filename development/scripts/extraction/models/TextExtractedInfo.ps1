using namespace System.Collections.Generic

<#
.SYNOPSIS
    Classe pour les informations textuelles extraites.
.DESCRIPTION
    Ã‰tend la classe ValidatableExtractedInfo pour reprÃ©senter
    des informations textuelles extraites avec des propriÃ©tÃ©s spÃ©cifiques.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\ValidatableExtractedInfo.ps1"

class TextExtractedInfo : ValidatableExtractedInfo {
    # PropriÃ©tÃ©s spÃ©cifiques aux informations textuelles
    [string]$Text
    [string]$Language
    [int]$CharacterCount
    [int]$WordCount
    [hashtable]$TextStatistics
    [string[]]$Keywords
    [string]$Category
    [string]$Summary

    # Constructeur par dÃ©faut
    TextExtractedInfo() : base() {
        $this.InitializeTextInfo()
    }

    # Constructeur avec source
    TextExtractedInfo([string]$source) : base($source) {
        $this.InitializeTextInfo()
    }

    # Constructeur avec source et extracteur
    TextExtractedInfo([string]$source, [string]$extractorName) : base($source, $extractorName) {
        $this.InitializeTextInfo()
    }

    # Constructeur avec texte
    TextExtractedInfo([string]$source, [string]$extractorName, [string]$text) : base($source, $extractorName) {
        $this.InitializeTextInfo()
        $this.Text = $text
        $this.CalculateTextStatistics()
    }

    # MÃ©thode d'initialisation des informations textuelles
    hidden [void] InitializeTextInfo() {
        $this.Text = ""
        $this.Language = "fr"
        $this.CharacterCount = 0
        $this.WordCount = 0
        $this.TextStatistics = @{}
        $this.Keywords = @()
        $this.Category = ""
        $this.Summary = ""

        # Ajouter les rÃ¨gles de validation spÃ©cifiques au texte
        $this.AddTextValidationRules()
    }

    # MÃ©thode pour ajouter les rÃ¨gles de validation spÃ©cifiques au texte
    hidden [void] AddTextValidationRules() {
        # Validation du texte
        $this.AddValidationRule("Text", {
                param($target, $value)
                return -not [string]::IsNullOrEmpty($value)
            }, "Le texte ne peut pas Ãªtre vide")

        # Validation de la langue
        $this.AddValidationRule("Language", {
                param($target, $value)
                $validLanguages = @("fr", "en", "es", "de", "it")
                return -not [string]::IsNullOrEmpty($value) -and $validLanguages -contains $value
            }, "La langue doit Ãªtre l'une des valeurs suivantes: fr, en, es, de, it")
    }

    # MÃ©thode pour dÃ©finir le texte et calculer les statistiques
    [void] SetText([string]$text) {
        $this.Text = $text
        $this.CalculateTextStatistics()
    }

    # MÃ©thode pour calculer les statistiques du texte
    [void] CalculateTextStatistics() {
        if ([string]::IsNullOrEmpty($this.Text)) {
            $this.CharacterCount = 0
            $this.WordCount = 0
            $this.TextStatistics = @{
                CharacterCount        = 0
                WordCount             = 0
                LineCount             = 0
                AverageWordLength     = 0
                AverageSentenceLength = 0
            }
            return
        }

        # Calculer les statistiques de base
        $this.CharacterCount = $this.Text.Length
        $words = $this.Text -split '\s+' | Where-Object { $_ -ne "" }
        $this.WordCount = $words.Count

        # Calculer le nombre de lignes
        $lines = $this.Text -split '\r?\n' | Where-Object { $_ -ne "" }
        $lineCount = $lines.Count

        # Calculer la longueur moyenne des mots
        $totalWordLength = ($words | Measure-Object -Property Length -Sum).Sum
        $averageWordLength = if ($words.Count -gt 0) { $totalWordLength / $words.Count } else { 0 }

        # Calculer la longueur moyenne des phrases
        $sentences = $this.Text -split '[.!?]' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $sentenceCount = $sentences.Count
        $averageSentenceLength = if ($sentenceCount -gt 0) { $this.WordCount / $sentenceCount } else { 0 }

        # Stocker les statistiques
        $this.TextStatistics = @{
            CharacterCount        = $this.CharacterCount
            WordCount             = $this.WordCount
            LineCount             = $lineCount
            SentenceCount         = $sentenceCount
            AverageWordLength     = [math]::Round($averageWordLength, 2)
            AverageSentenceLength = [math]::Round($averageSentenceLength, 2)
        }
    }

    # MÃ©thode pour dÃ©finir les mots-clÃ©s
    [void] SetKeywords([string[]]$keywords) {
        $this.Keywords = $keywords
    }

    # MÃ©thode pour ajouter un mot-clÃ©
    [void] AddKeyword([string]$keyword) {
        if (-not [string]::IsNullOrWhiteSpace($keyword) -and -not $this.Keywords.Contains($keyword)) {
            $this.Keywords += $keyword
        }
    }

    # MÃ©thode pour dÃ©finir la catÃ©gorie
    [void] SetCategory([string]$category) {
        $this.Category = $category
    }

    # MÃ©thode pour dÃ©finir le rÃ©sumÃ©
    [void] SetSummary([string]$summary) {
        $this.Summary = $summary
    }

    # MÃ©thode pour gÃ©nÃ©rer un rÃ©sumÃ© automatique (implÃ©mentation simplifiÃ©e)
    [string] GenerateSummary([int]$maxLength = 200) {
        if ([string]::IsNullOrEmpty($this.Text)) {
            return ""
        }

        # ImplÃ©mentation simplifiÃ©e: prendre les premiers mots jusqu'Ã  maxLength
        $words = $this.Text -split '\s+'
        $localSummary = ""
        $currentLength = 0

        foreach ($word in $words) {
            if ($currentLength + $word.Length + 1 -gt $maxLength) {
                break
            }

            $localSummary += "$word "
            $currentLength += $word.Length + 1
        }

        $localSummary = $localSummary.Trim()

        # Ajouter des points de suspension si le rÃ©sumÃ© est plus court que le texte
        if ($localSummary.Length -lt $this.Text.Length) {
            $localSummary += "..."
        }

        $this.Summary = $localSummary
        return $localSummary
    }

    # MÃ©thode pour extraire les mots-clÃ©s (implÃ©mentation simplifiÃ©e)
    [string[]] ExtractKeywords([int]$count = 5) {
        if ([string]::IsNullOrEmpty($this.Text)) {
            return @()
        }

        # ImplÃ©mentation simplifiÃ©e: prendre les mots les plus frÃ©quents
        $words = $this.Text.ToLower() -split '\W+' | Where-Object { $_ -ne "" -and $_.Length -gt 3 }
        $wordCounts = @{}

        foreach ($word in $words) {
            if (-not $wordCounts.ContainsKey($word)) {
                $wordCounts[$word] = 0
            }
            $wordCounts[$word]++
        }

        # Exclure les mots vides (stop words)
        $stopWords = @("avec", "pour", "dans", "cette", "votre", "vous", "nous", "mais", "sont", "plus", "comme")
        foreach ($stopWord in $stopWords) {
            if ($wordCounts.ContainsKey($stopWord)) {
                $wordCounts.Remove($stopWord)
            }
        }

        # Trier par frÃ©quence et prendre les N premiers
        $localKeywords = $wordCounts.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First $count |
            ForEach-Object { $_.Key }

        $this.Keywords = $localKeywords
        return $localKeywords
    }

    # Surcharge de la mÃ©thode GetSummary
    [string] GetSummary() {
        $baseInfo = ([ValidatableExtractedInfo]$this).GetSummary()
        return "$baseInfo, Texte: $($this.CharacterCount) caractÃ¨res, $($this.WordCount) mots"
    }

    # Surcharge de la mÃ©thode Clone pour retourner un TextExtractedInfo
    [TextExtractedInfo] Clone() {
        $clone = [TextExtractedInfo]::new()

        # Cloner les propriÃ©tÃ©s de base
        $clone.Id = $this.Id
        $clone.Source = $this.Source
        $clone.ExtractedAt = $this.ExtractedAt
        $clone.ExtractorName = $this.ExtractorName
        $clone.ProcessingState = $this.ProcessingState
        $clone.ConfidenceScore = $this.ConfidenceScore
        $clone.IsValid = $this.IsValid

        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }

        # Cloner les rÃ¨gles de validation
        foreach ($propertyName in $this.ValidationRules.Keys) {
            $rules = $this.ValidationRules[$propertyName]

            foreach ($rule in $rules) {
                $clonedRule = $rule.Clone()

                if (-not $clone.ValidationRules.ContainsKey($propertyName)) {
                    $clone.ValidationRules[$propertyName] = [List[ValidationRule]]::new()
                }

                $clone.ValidationRules[$propertyName].Add($clonedRule)
            }
        }

        # Cloner les propriÃ©tÃ©s spÃ©cifiques
        $clone.Text = $this.Text
        $clone.Language = $this.Language
        $clone.CharacterCount = $this.CharacterCount
        $clone.WordCount = $this.WordCount
        $clone.Keywords = $this.Keywords.Clone()
        $clone.Category = $this.Category
        $clone.Summary = $this.Summary

        # Cloner les statistiques
        $clone.TextStatistics = @{}
        foreach ($key in $this.TextStatistics.Keys) {
            $clone.TextStatistics[$key] = $this.TextStatistics[$key]
        }

        return $clone
    }
}

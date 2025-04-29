# Définir l'encodage UTF-8 pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

<#
.SYNOPSIS
    Analyse la cohérence de la ponctuation entre les différents niveaux de titres dans un document markdown.

.DESCRIPTION
    Ce script analyse un document markdown et évalue la cohérence de l'utilisation de la ponctuation
    entre les différents niveaux de titres. Il identifie les marques de ponctuation utilisées à chaque niveau
    et compare leur utilisation entre les niveaux adjacents et non-adjacents.

.PARAMETER FilePath
    Chemin vers le fichier markdown à analyser.

.PARAMETER OutputPath
    Chemin où le rapport d'analyse sera enregistré.
    Par défaut : ".\title-punctuation-consistency-analysis.md"

.PARAMETER IncludeExamples
    Indique si des exemples de titres doivent être inclus dans le rapport.
    Par défaut : $true

.EXAMPLE
    .\analyze-title-punctuation-consistency.ps1 -FilePath ".\document.md" -OutputPath ".\rapport-analyse.md"
    Analyse le fichier document.md et génère un rapport dans rapport-analyse.md.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [bool]$IncludeExamples = $true
)

# Définir les valeurs par défaut si non spécifiées
if (-not $FilePath) {
    $FilePath = "..\..\data\planning\expertise-levels.md"
}

if (-not $OutputPath) {
    $OutputPath = "..\..\data\planning\title-punctuation-consistency-analysis.md"
}

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
    $FilePath = Join-Path -Path $PWD -ChildPath $FilePath
}

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path -Path $PWD -ChildPath $OutputPath
}

# Fonction pour extraire les titres d'un document markdown
function Get-MarkdownTitles {
    param(
        [string]$Content
    )

    $titles = @()

    # Extraire les titres avec la syntaxe #
    $hashTitleRegex = [regex]::new('(?m)^(#{1,6})\s+(.+)$')
    $hashMatches = $hashTitleRegex.Matches($Content)

    foreach ($match in $hashMatches) {
        $level = $match.Groups[1].Value.Length
        $title = $match.Groups[2].Value.Trim()

        $titles += [PSCustomObject]@{
            Title      = $title
            Level      = $level
            Type       = "Hash"
            LineNumber = [regex]::Match($Content.Substring(0, $match.Index), '(?m)^').Count + 1
        }
    }

    # Extraire les titres avec la syntaxe de soulignement
    $underlineTitleRegex = [regex]::new('(?m)^([^\n]+)\n(=+|-+)$')
    $underlineMatches = $underlineTitleRegex.Matches($Content)

    foreach ($match in $underlineMatches) {
        $title = $match.Groups[1].Value.Trim()
        $underlineChar = $match.Groups[2].Value[0]
        $level = if ($underlineChar -eq '=') { 1 } else { 2 }

        $titles += [PSCustomObject]@{
            Title      = $title
            Level      = $level
            Type       = "Underline"
            LineNumber = [regex]::Match($Content.Substring(0, $match.Index), '(?m)^').Count + 1
        }
    }

    # Trier les titres par numéro de ligne
    return $titles | Sort-Object -Property LineNumber
}

# Fonction pour analyser la ponctuation dans un titre
function Get-PunctuationAnalysis {
    param(
        [string]$Text
    )

    $analysis = @{
        HasPunctuation            = $false
        PunctuationMarks          = @{}
        StartsWith                = $null
        EndsWith                  = $null
        ContainsSpecialCharacters = $false
        SpecialCharacters         = @{}
    }

    # Définir les marques de ponctuation à rechercher
    $punctuationMarks = @('.', ',', ';', ':', '!', '?', '-', '_', '(', ')', '[', ']', '{', '}', '"', "'", '«', '»', '...', '–', '—')

    # Définir les caractères spéciaux à rechercher
    $specialCharacters = @('#', '@', '$', '%', '&', '*', '+', '=', '<', '>', '/', '\', '|', '~', '^')

    # Vérifier chaque marque de ponctuation
    foreach ($mark in $punctuationMarks) {
        if ($Text.Contains($mark)) {
            $analysis.HasPunctuation = $true
            $count = ($Text.ToCharArray() | Where-Object { $_ -eq $mark[0] }).Count
            $analysis.PunctuationMarks[$mark] = $count
        }
    }

    # Vérifier les caractères spéciaux
    foreach ($char in $specialCharacters) {
        if ($Text.Contains($char)) {
            $analysis.ContainsSpecialCharacters = $true
            $count = ($Text.ToCharArray() | Where-Object { $_ -eq $char[0] }).Count
            $analysis.SpecialCharacters[$char] = $count
        }
    }

    # Vérifier si le titre commence par une ponctuation
    foreach ($mark in $punctuationMarks) {
        if ($Text.StartsWith($mark)) {
            $analysis.StartsWith = $mark
            break
        }
    }

    # Vérifier si le titre se termine par une ponctuation
    foreach ($mark in $punctuationMarks) {
        if ($Text.EndsWith($mark)) {
            $analysis.EndsWith = $mark
            break
        }
    }

    return $analysis
}

# Fonction pour analyser la ponctuation dans les titres par niveau
function Get-TitlePunctuationByLevel {
    param(
        [array]$Titles
    )

    $analysis = @{
        TotalTitles   = $Titles.Count
        LevelAnalysis = @{}
        Examples      = @{}
    }

    # Analyser chaque niveau de titre
    $levels = $Titles | Select-Object -ExpandProperty Level -Unique | Sort-Object

    foreach ($level in $levels) {
        $levelTitles = $Titles | Where-Object { $_.Level -eq $level }
        $totalLevelTitles = $levelTitles.Count
        $titlesWithPunctuation = 0
        $punctuationByMark = @{}
        $startsWithPunctuation = 0
        $endsWithPunctuation = 0
        $startMarks = @{}
        $endMarks = @{}
        $examples = @{
            WithPunctuation    = @()
            WithoutPunctuation = @()
        }

        # Analyser chaque titre du niveau
        foreach ($title in $levelTitles) {
            $titleAnalysis = Get-PunctuationAnalysis -Text $title.Title

            # Compter les titres avec ponctuation
            if ($titleAnalysis.HasPunctuation) {
                $titlesWithPunctuation++

                # Ajouter un exemple si nécessaire
                if ($examples.WithPunctuation.Count -lt 3) {
                    $examples.WithPunctuation += $title.Title
                }

                # Compter les marques de ponctuation
                foreach ($mark in $titleAnalysis.PunctuationMarks.Keys) {
                    $count = $titleAnalysis.PunctuationMarks[$mark]
                    if (-not $punctuationByMark.ContainsKey($mark)) {
                        $punctuationByMark[$mark] = 0
                    }
                    $punctuationByMark[$mark] += $count
                }

                # Compter les titres commençant par une ponctuation
                if ($titleAnalysis.StartsWith) {
                    $startsWithPunctuation++
                    if (-not $startMarks.ContainsKey($titleAnalysis.StartsWith)) {
                        $startMarks[$titleAnalysis.StartsWith] = 0
                    }
                    $startMarks[$titleAnalysis.StartsWith]++
                }

                # Compter les titres se terminant par une ponctuation
                if ($titleAnalysis.EndsWith) {
                    $endsWithPunctuation++
                    if (-not $endMarks.ContainsKey($titleAnalysis.EndsWith)) {
                        $endMarks[$titleAnalysis.EndsWith] = 0
                    }
                    $endMarks[$titleAnalysis.EndsWith]++
                }
            } else {
                # Ajouter un exemple si nécessaire
                if ($examples.WithoutPunctuation.Count -lt 3) {
                    $examples.WithoutPunctuation += $title.Title
                }
            }
        }

        # Calculer les pourcentages
        $percentageWithPunctuation = if ($totalLevelTitles -gt 0) {
            [math]::Round(($titlesWithPunctuation / $totalLevelTitles) * 100, 2)
        } else {
            0
        }

        $percentageStartsWithPunctuation = if ($totalLevelTitles -gt 0) {
            [math]::Round(($startsWithPunctuation / $totalLevelTitles) * 100, 2)
        } else {
            0
        }

        $percentageEndsWithPunctuation = if ($totalLevelTitles -gt 0) {
            [math]::Round(($endsWithPunctuation / $totalLevelTitles) * 100, 2)
        } else {
            0
        }

        # Stocker l'analyse du niveau
        $analysis.LevelAnalysis[$level] = @{
            TotalTitles                     = $totalLevelTitles
            TitlesWithPunctuation           = $titlesWithPunctuation
            PercentageWithPunctuation       = $percentageWithPunctuation
            PunctuationByMark               = $punctuationByMark
            StartsWithPunctuation           = $startsWithPunctuation
            PercentageStartsWithPunctuation = $percentageStartsWithPunctuation
            StartMarks                      = $startMarks
            EndsWithPunctuation             = $endsWithPunctuation
            PercentageEndsWithPunctuation   = $percentageEndsWithPunctuation
            EndMarks                        = $endMarks
        }

        # Stocker les exemples
        $analysis.Examples[$level] = $examples
    }

    return $analysis
}

# Fonction pour analyser la cohérence de la ponctuation entre les niveaux
function Get-PunctuationConsistencyAnalysis {
    param(
        [hashtable]$LevelAnalysis
    )

    $consistency = @{
        Levels              = $LevelAnalysis.Keys | Sort-Object
        PairwiseConsistency = @{}
        OverallConsistency  = 0
        ConsistentPairs     = 0
        TotalPairs          = 0
        Recommendations     = @{}
    }

    $levels = $consistency.Levels

    # Analyser la cohérence entre chaque paire de niveaux
    for ($i = 0; $i -lt $levels.Count; $i++) {
        for ($j = $i + 1; $j -lt $levels.Count; $j++) {
            $level1 = $levels[$i]
            $level2 = $levels[$j]
            $pair = "$level1-$level2"

            $analysis1 = $LevelAnalysis[$level1]
            $analysis2 = $LevelAnalysis[$level2]

            # Comparer l'utilisation de la ponctuation
            $punctuationConsistency = @{
                OverallUsage    = ([math]::Abs($analysis1.PercentageWithPunctuation - $analysis2.PercentageWithPunctuation) -le 20)
                StartsWith      = ([math]::Abs($analysis1.PercentageStartsWithPunctuation - $analysis2.PercentageStartsWithPunctuation) -le 20)
                EndsWith        = ([math]::Abs($analysis1.PercentageEndsWithPunctuation - $analysis2.PercentageEndsWithPunctuation) -le 20)
                CommonMarks     = 0
                TotalMarks      = 0
                MarkConsistency = 0
            }

            # Comparer les marques de ponctuation utilisées
            $allMarks = @($analysis1.PunctuationByMark.Keys) + @($analysis2.PunctuationByMark.Keys) | Select-Object -Unique
            $commonMarks = 0

            foreach ($mark in $allMarks) {
                $punctuationConsistency.TotalMarks++

                $inLevel1 = $analysis1.PunctuationByMark.ContainsKey($mark)
                $inLevel2 = $analysis2.PunctuationByMark.ContainsKey($mark)

                if ($inLevel1 -and $inLevel2) {
                    $commonMarks++
                }
            }

            $punctuationConsistency.CommonMarks = $commonMarks
            $punctuationConsistency.MarkConsistency = if ($punctuationConsistency.TotalMarks -gt 0) {
                [math]::Round(($commonMarks / $punctuationConsistency.TotalMarks) * 100, 2)
            } else {
                100 # Si aucune marque de ponctuation, considérer comme cohérent
            }

            # Calculer la cohérence globale pour cette paire
            $consistencyScore = 0
            $consistencyScore += if ($punctuationConsistency.OverallUsage) { 1 } else { 0 }
            $consistencyScore += if ($punctuationConsistency.StartsWith) { 1 } else { 0 }
            $consistencyScore += if ($punctuationConsistency.EndsWith) { 1 } else { 0 }
            $consistencyScore += if ($punctuationConsistency.MarkConsistency -ge 70) { 1 } else { 0 }

            $pairConsistency = [math]::Round(($consistencyScore / 4) * 100, 2)

            # Stocker l'analyse de cohérence pour cette paire
            $consistency.PairwiseConsistency[$pair] = @{
                Level1                 = $level1
                Level2                 = $level2
                OverallUsageConsistent = $punctuationConsistency.OverallUsage
                StartsWithConsistent   = $punctuationConsistency.StartsWith
                EndsWithConsistent     = $punctuationConsistency.EndsWith
                CommonMarks            = $punctuationConsistency.CommonMarks
                TotalMarks             = $punctuationConsistency.TotalMarks
                MarkConsistency        = $punctuationConsistency.MarkConsistency
                ConsistencyScore       = $pairConsistency
                IsConsistent           = ($pairConsistency -ge 75)
            }

            # Mettre à jour les compteurs globaux
            if ($consistency.PairwiseConsistency[$pair].IsConsistent) {
                $consistency.ConsistentPairs++
            }
            $consistency.TotalPairs++
        }
    }

    # Calculer la cohérence globale
    $consistency.OverallConsistency = if ($consistency.TotalPairs -gt 0) {
        [math]::Round(($consistency.ConsistentPairs / $consistency.TotalPairs) * 100, 2)
    } else {
        100 # Si un seul niveau, considérer comme cohérent
    }

    # Générer des recommandations
    if ($consistency.OverallConsistency -lt 75) {
        # Identifier les paires incohérentes
        $inconsistentPairs = $consistency.PairwiseConsistency.GetEnumerator() |
            Where-Object { -not $_.Value.IsConsistent } |
            ForEach-Object { $_.Key }

        $consistency.Recommendations["InconsistentPairs"] = $inconsistentPairs

        # Recommandations spécifiques pour chaque niveau
        foreach ($level in $levels) {
            $levelAnalysis = $LevelAnalysis[$level]

            # Vérifier si ce niveau est impliqué dans des paires incohérentes
            $involvedInInconsistency = $inconsistentPairs | Where-Object { $_ -match "^$level-|-$level$" }

            if ($involvedInInconsistency.Count -gt 0) {
                # Recommandations basées sur l'utilisation de la ponctuation
                if ($levelAnalysis.PercentageWithPunctuation -gt 50) {
                    $consistency.Recommendations["Level$level"] = @{
                        CurrentUsage   = "Utilisation fréquente de la ponctuation ($($levelAnalysis.PercentageWithPunctuation)%)"
                        Recommendation = "Maintenir une utilisation cohérente de la ponctuation avec les autres niveaux"
                        SpecificMarks  = $levelAnalysis.PunctuationByMark.Keys | Where-Object { $levelAnalysis.PunctuationByMark[$_] -gt 0 }
                    }
                } else {
                    $consistency.Recommendations["Level$level"] = @{
                        CurrentUsage   = "Utilisation limitée de la ponctuation ($($levelAnalysis.PercentageWithPunctuation)%)"
                        Recommendation = "Éviter d'introduire de nouvelles marques de ponctuation pour maintenir la cohérence"
                        SpecificMarks  = $levelAnalysis.PunctuationByMark.Keys | Where-Object { $levelAnalysis.PunctuationByMark[$_] -gt 0 }
                    }
                }
            }
        }
    }

    return $consistency
}

# Fonction pour générer un rapport d'analyse de la cohérence de la ponctuation
function New-PunctuationConsistencyReport {
    param(
        [hashtable]$LevelAnalysis,
        [hashtable]$ConsistencyAnalysis,
        [bool]$IncludeExamples
    )

    $levels = $ConsistencyAnalysis.Levels

    $report = @"
# Analyse de la Cohérence de la Ponctuation entre Niveaux de Titres

## Résumé

- **Nombre total de niveaux de titres**: $($levels.Count)
- **Score de cohérence globale**: $($ConsistencyAnalysis.OverallConsistency)%
- **Paires de niveaux cohérentes**: $($ConsistencyAnalysis.ConsistentPairs)/$($ConsistencyAnalysis.TotalPairs)

## Analyse par Niveau de Titre

"@

    foreach ($level in $levels) {
        $levelData = $LevelAnalysis[$level]

        $report += @"

### Niveau $level (${'#' * $level})

- **Nombre total de titres**: $($levelData.TotalTitles)
- **Titres avec ponctuation**: $($levelData.TitlesWithPunctuation) ($($levelData.PercentageWithPunctuation)%)

"@

        if ($levelData.PunctuationByMark.Count -gt 0) {
            $report += @"
**Marques de ponctuation utilisées:**

"@
            foreach ($mark in $levelData.PunctuationByMark.Keys | Sort-Object) {
                $report += @"
- **$mark**: $($levelData.PunctuationByMark[$mark]) occurrences
"@
            }
        } else {
            $report += @"
**Aucune marque de ponctuation utilisée à ce niveau.**

"@
        }

        if ($IncludeExamples) {
            $examples = $LevelAnalysis.Examples[$level]

            $report += @"

**Exemples:**

"@
            if ($examples.WithPunctuation.Count -gt 0) {
                $report += @"
*Titres avec ponctuation:*
"@
                foreach ($example in $examples.WithPunctuation) {
                    $report += @"
- "$example"
"@
                }
            }

            if ($examples.WithoutPunctuation.Count -gt 0) {
                $report += @"

*Titres sans ponctuation:*
"@
                foreach ($example in $examples.WithoutPunctuation) {
                    $report += @"
- "$example"
"@
                }
            }
        }
    }

    $report += @"

## Analyse de Cohérence entre Niveaux

"@

    foreach ($pair in $ConsistencyAnalysis.PairwiseConsistency.Keys | Sort-Object) {
        $pairData = $ConsistencyAnalysis.PairwiseConsistency[$pair]
        $level1 = $pairData.Level1
        $level2 = $pairData.Level2

        $report += @"

### Niveaux $level1 et $level2

- **Score de cohérence**: $($pairData.ConsistencyScore)%
- **Cohérence d'utilisation globale**: $(if ($pairData.OverallUsageConsistent) { "Oui" } else { "Non" })
- **Cohérence des marques de ponctuation**: $($pairData.MarkConsistency)% ($($pairData.CommonMarks)/$($pairData.TotalMarks) marques communes)
- **Cohérence de ponctuation en début de titre**: $(if ($pairData.StartsWithConsistent) { "Oui" } else { "Non" })
- **Cohérence de ponctuation en fin de titre**: $(if ($pairData.EndsWithConsistent) { "Oui" } else { "Non" })
- **Verdict**: $(if ($pairData.IsConsistent) { "Cohérent" } else { "Incohérent" })

"@
    }

    $report += @"

## Recommandations

"@

    if ($ConsistencyAnalysis.OverallConsistency -ge 75) {
        $report += @"
La cohérence de la ponctuation entre les niveaux de titres est bonne (>= 75%). Continuer à maintenir cette cohérence dans les futurs ajouts au document.
"@
    } else {
        $report += @"
La cohérence de la ponctuation entre les niveaux de titres pourrait être améliorée (< 75%). Voici quelques recommandations:

1. **Paires de niveaux incohérentes**: $(
    if ($ConsistencyAnalysis.Recommendations.ContainsKey("InconsistentPairs")) {
        $ConsistencyAnalysis.Recommendations["InconsistentPairs"] -join ", "
    } else {
        "Aucune"
    }
)

"@

        foreach ($level in $levels) {
            $key = "Level$level"
            if ($ConsistencyAnalysis.Recommendations.ContainsKey($key)) {
                $rec = $ConsistencyAnalysis.Recommendations[$key]
                $report += @"
2. **Niveau $level**: $($rec.CurrentUsage)
   - Recommandation: $($rec.Recommendation)
   - Marques de ponctuation actuelles: $(if ($rec.SpecificMarks.Count -gt 0) { $rec.SpecificMarks -join ", " } else { "Aucune" })

"@
            }
        }

        $report += @"
3. **Recommandations générales**:
   - Standardiser l'utilisation de la ponctuation à travers tous les niveaux de titres
   - Éviter de mélanger différents styles de ponctuation entre les niveaux
   - Maintenir une cohérence dans l'utilisation des marques de ponctuation spécifiques
   - Considérer l'adoption d'un guide de style pour la ponctuation des titres
"@
    }

    return $report
}

# Vérifier si le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier '$FilePath' n'existe pas."
    exit 1
}

try {
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

    # Extraire les titres
    $titles = Get-MarkdownTitles -Content $content

    # Analyser la ponctuation par niveau
    $levelAnalysis = Get-TitlePunctuationByLevel -Titles $titles

    # Analyser la cohérence entre les niveaux
    $consistencyAnalysis = Get-PunctuationConsistencyAnalysis -LevelAnalysis $levelAnalysis.LevelAnalysis

    # Générer le rapport d'analyse
    $report = New-PunctuationConsistencyReport -LevelAnalysis $levelAnalysis -ConsistencyAnalysis $consistencyAnalysis -IncludeExamples $IncludeExamples

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer le rapport
    Set-Content -Path $OutputPath -Value $report -Encoding UTF8

    Write-Host "Analyse terminée. Rapport enregistré dans '$OutputPath'."

    # Retourner les résultats de l'analyse pour une utilisation dans d'autres scripts
    return @{
        LevelAnalysis       = $levelAnalysis
        ConsistencyAnalysis = $consistencyAnalysis
    }
} catch {
    Write-Error "Une erreur s'est produite lors de l'analyse: $_"
    exit 1
}

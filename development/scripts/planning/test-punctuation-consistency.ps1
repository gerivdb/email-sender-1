# CrÃ©er un fichier markdown temporaire pour les tests
$testContent = @"
# Titre Principal: Introduction

Contenu du titre principal.

## Sous-titre 1.1

Contenu du sous-titre 1.1.

### Sous-sous-titre 1.1.1: DÃ©tails

Contenu du sous-sous-titre 1.1.1.

## Sous-titre 1.2: Contexte

Contenu du sous-titre 1.2.

# Titre Principal 2

Contenu du titre principal 2.

## Sous-titre 2.1: Analyse

Contenu du sous-titre 2.1.

### Sous-sous-titre 2.1.1

Contenu du sous-sous-titre 2.1.1.

### Sous-sous-titre 2.1.2: RÃ©sultats

Contenu du sous-sous-titre 2.1.2.

## Sous-titre 2.2

Contenu du sous-titre 2.2.

### Sous-sous-titre 2.2.1: Conclusion

Contenu du sous-sous-titre 2.2.1.
"@

$testFilePath = Join-Path -Path $PSScriptRoot -ChildPath "test-document.md"
$testOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "test-output.md"

# Enregistrer le contenu de test dans un fichier
Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8

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

    # Trier les titres par numÃ©ro de ligne
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

    # DÃ©finir les marques de ponctuation Ã  rechercher
    $punctuationMarks = @('.', ',', ';', ':', '!', '?', '-', '_', '(', ')', '[', ']', '{', '}', '"', "'", 'Â«', 'Â»', '...', 'â€“', 'â€”')

    # DÃ©finir les caractÃ¨res spÃ©ciaux Ã  rechercher
    $specialCharacters = @('#', '@', '$', '%', '&', '*', '+', '=', '<', '>', '/', '\', '|', '~', '^')

    # VÃ©rifier chaque marque de ponctuation
    foreach ($mark in $punctuationMarks) {
        if ($Text.Contains($mark)) {
            $analysis.HasPunctuation = $true
            $count = ($Text.ToCharArray() | Where-Object { $_ -eq $mark[0] }).Count
            $analysis.PunctuationMarks[$mark] = $count
        }
    }

    # VÃ©rifier les caractÃ¨res spÃ©ciaux
    foreach ($char in $specialCharacters) {
        if ($Text.Contains($char)) {
            $analysis.ContainsSpecialCharacters = $true
            $count = ($Text.ToCharArray() | Where-Object { $_ -eq $char[0] }).Count
            $analysis.SpecialCharacters[$char] = $count
        }
    }

    # VÃ©rifier si le titre commence par une ponctuation
    foreach ($mark in $punctuationMarks) {
        if ($Text.StartsWith($mark)) {
            $analysis.StartsWith = $mark
            break
        }
    }

    # VÃ©rifier si le titre se termine par une ponctuation
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

                # Ajouter un exemple si nÃ©cessaire
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

                # Compter les titres commenÃ§ant par une ponctuation
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
                # Ajouter un exemple si nÃ©cessaire
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

# Fonction pour analyser la cohÃ©rence de la ponctuation entre les niveaux
function Get-PunctuationConsistencyAnalysis {
    param(
        [hashtable]$LevelAnalysis
    )

    Write-Host "DÃ©but de l'analyse de cohÃ©rence..."
    Write-Host "Niveaux reÃ§us: $($LevelAnalysis.Keys -join ', ')"

    $consistency = @{
        Levels              = $LevelAnalysis.Keys | Sort-Object
        PairwiseConsistency = @{}
        OverallConsistency  = 0
        ConsistentPairs     = 0
        TotalPairs          = 0
        Recommendations     = @{}
    }

    $levels = $consistency.Levels
    Write-Host "Niveaux triÃ©s: $($levels -join ', ')"

    # Analyser la cohÃ©rence entre chaque paire de niveaux
    Write-Host "Analyse des paires de niveaux..."
    Write-Host "Nombre de niveaux: $($levels.Count)"

    for ($i = 0; $i -lt $levels.Count; $i++) {
        for ($j = $i + 1; $j -lt $levels.Count; $j++) {
            $level1 = $levels[$i]
            $level2 = $levels[$j]
            $pair = "$level1-$level2"

            Write-Host "Analyse de la paire $pair..."

            Write-Host "VÃ©rification de l'existence du niveau $level1 dans LevelAnalysis..."
            if (-not $LevelAnalysis.ContainsKey($level1)) {
                Write-Host "ERREUR: Le niveau $level1 n'existe pas dans LevelAnalysis!"
                continue
            }

            Write-Host "VÃ©rification de l'existence du niveau $level2 dans LevelAnalysis..."
            if (-not $LevelAnalysis.ContainsKey($level2)) {
                Write-Host "ERREUR: Le niveau $level2 n'existe pas dans LevelAnalysis!"
                continue
            }

            $analysis1 = $LevelAnalysis[$level1]
            $analysis2 = $LevelAnalysis[$level2]

            Write-Host "Analyse1: $($analysis1 | ConvertTo-Json -Depth 1)"
            Write-Host "Analyse2: $($analysis2 | ConvertTo-Json -Depth 1)"

            # Comparer l'utilisation de la ponctuation
            $punctuationConsistency = @{
                OverallUsage    = ([math]::Abs($analysis1.PercentageWithPunctuation - $analysis2.PercentageWithPunctuation) -le 20)
                StartsWith      = ([math]::Abs($analysis1.PercentageStartsWithPunctuation - $analysis2.PercentageStartsWithPunctuation) -le 20)
                EndsWith        = ([math]::Abs($analysis1.PercentageEndsWithPunctuation - $analysis2.PercentageEndsWithPunctuation) -le 20)
                CommonMarks     = 0
                TotalMarks      = 0
                MarkConsistency = 0
            }

            # Comparer les marques de ponctuation utilisÃ©es
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
                100 # Si aucune marque de ponctuation, considÃ©rer comme cohÃ©rent
            }

            # Calculer la cohÃ©rence globale pour cette paire
            $consistencyScore = 0
            $consistencyScore += if ($punctuationConsistency.OverallUsage) { 1 } else { 0 }
            $consistencyScore += if ($punctuationConsistency.StartsWith) { 1 } else { 0 }
            $consistencyScore += if ($punctuationConsistency.EndsWith) { 1 } else { 0 }
            $consistencyScore += if ($punctuationConsistency.MarkConsistency -ge 70) { 1 } else { 0 }

            $pairConsistency = [math]::Round(($consistencyScore / 4) * 100, 2)

            # Stocker l'analyse de cohÃ©rence pour cette paire
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

            # Mettre Ã  jour les compteurs globaux
            if ($consistency.PairwiseConsistency[$pair].IsConsistent) {
                $consistency.ConsistentPairs++
            }
            $consistency.TotalPairs++
        }
    }

    # Calculer la cohÃ©rence globale
    $consistency.OverallConsistency = if ($consistency.TotalPairs -gt 0) {
        [math]::Round(($consistency.ConsistentPairs / $consistency.TotalPairs) * 100, 2)
    } else {
        100 # Si un seul niveau, considÃ©rer comme cohÃ©rent
    }

    # GÃ©nÃ©rer des recommandations
    Write-Host "GÃ©nÃ©ration des recommandations..."
    Write-Host "Score de cohÃ©rence globale: $($consistency.OverallConsistency)%"

    if ($consistency.OverallConsistency -lt 75) {
        Write-Host "Score de cohÃ©rence < 75%, gÃ©nÃ©ration de recommandations dÃ©taillÃ©es..."

        # Identifier les paires incohÃ©rentes
        Write-Host "Identification des paires incohÃ©rentes..."
        Write-Host "Paires disponibles: $($consistency.PairwiseConsistency.Keys -join ', ')"

        $inconsistentPairs = @()
        foreach ($pairKey in $consistency.PairwiseConsistency.Keys) {
            $pairValue = $consistency.PairwiseConsistency[$pairKey]
            Write-Host "Paire $pairKey - IsConsistent: $($pairValue.IsConsistent)"
            if (-not $pairValue.IsConsistent) {
                $inconsistentPairs += $pairKey
            }
        }

        Write-Host "Paires incohÃ©rentes identifiÃ©es: $($inconsistentPairs -join ', ')"
        $consistency.Recommendations["InconsistentPairs"] = $inconsistentPairs

        # Recommandations spÃ©cifiques pour chaque niveau
        Write-Host "GÃ©nÃ©ration de recommandations spÃ©cifiques pour chaque niveau..."

        foreach ($level in $levels) {
            Write-Host "Analyse du niveau $level..."

            Write-Host "VÃ©rification de l'existence du niveau $level dans LevelAnalysis..."
            if (-not $LevelAnalysis.ContainsKey($level)) {
                Write-Host "ERREUR: Le niveau $level n'existe pas dans LevelAnalysis!"
                continue
            }

            $levelAnalysis = $LevelAnalysis[$level]
            Write-Host "Analyse du niveau $level rÃ©cupÃ©rÃ©e avec succÃ¨s."

            # VÃ©rifier si ce niveau est impliquÃ© dans des paires incohÃ©rentes
            Write-Host "VÃ©rification de l'implication du niveau $level dans des paires incohÃ©rentes..."
            $involvedInInconsistency = @()

            if ($inconsistentPairs -and $inconsistentPairs.Count -gt 0) {
                $involvedInInconsistency = $inconsistentPairs | Where-Object { $_ -match "^$level-" -or $_ -match "-$level$" }
                Write-Host "Paires incohÃ©rentes impliquant le niveau $level : $($involvedInInconsistency -join ', ')"
            } else {
                Write-Host "Aucune paire incohÃ©rente trouvÃ©e."
            }

            if ($involvedInInconsistency -and $involvedInInconsistency.Count -gt 0) {
                # Recommandations basÃ©es sur l'utilisation de la ponctuation
                Write-Host "GÃ©nÃ©ration de recommandations pour le niveau $level..."

                if ($levelAnalysis.PercentageWithPunctuation -gt 50) {
                    Write-Host "Niveau $level - Utilisation frÃ©quente de la ponctuation ($($levelAnalysis.PercentageWithPunctuation)%)"

                    Write-Host "VÃ©rification des marques de ponctuation pour le niveau $level..."
                    $specificMarks = @()
                    if ($levelAnalysis.PunctuationByMark -and $levelAnalysis.PunctuationByMark.Keys) {
                        $specificMarks = $levelAnalysis.PunctuationByMark.Keys | Where-Object {
                            $levelAnalysis.PunctuationByMark[$_] -gt 0
                        }
                        Write-Host "Marques de ponctuation trouvÃ©es: $($specificMarks -join ', ')"
                    } else {
                        Write-Host "Aucune marque de ponctuation trouvÃ©e."
                    }

                    $consistency.Recommendations["Level$level"] = @{
                        CurrentUsage   = "Utilisation frÃ©quente de la ponctuation ($($levelAnalysis.PercentageWithPunctuation)%)"
                        Recommendation = "Maintenir une utilisation cohÃ©rente de la ponctuation avec les autres niveaux"
                        SpecificMarks  = $specificMarks
                    }
                } else {
                    Write-Host "Niveau $level - Utilisation limitÃ©e de la ponctuation ($($levelAnalysis.PercentageWithPunctuation)%)"

                    Write-Host "VÃ©rification des marques de ponctuation pour le niveau $level..."
                    $specificMarks = @()
                    if ($levelAnalysis.PunctuationByMark -and $levelAnalysis.PunctuationByMark.Keys) {
                        $specificMarks = $levelAnalysis.PunctuationByMark.Keys | Where-Object {
                            $levelAnalysis.PunctuationByMark[$_] -gt 0
                        }
                        Write-Host "Marques de ponctuation trouvÃ©es: $($specificMarks -join ', ')"
                    } else {
                        Write-Host "Aucune marque de ponctuation trouvÃ©e."
                    }

                    $consistency.Recommendations["Level$level"] = @{
                        CurrentUsage   = "Utilisation limitÃ©e de la ponctuation ($($levelAnalysis.PercentageWithPunctuation)%)"
                        Recommendation = "Ã‰viter d'introduire de nouvelles marques de ponctuation pour maintenir la cohÃ©rence"
                        SpecificMarks  = $specificMarks
                    }
                }
            }
        }
    }

    return $consistency
}

# Fonction pour gÃ©nÃ©rer un rapport d'analyse de la cohÃ©rence de la ponctuation
function New-PunctuationConsistencyReport {
    param(
        [hashtable]$LevelAnalysis,
        [hashtable]$ConsistencyAnalysis,
        [bool]$IncludeExamples = $true
    )

    Write-Host "DÃ©but de la gÃ©nÃ©ration du rapport..."
    Write-Host "Niveaux d'analyse reÃ§us: $($LevelAnalysis.LevelAnalysis.Keys -join ', ')"
    Write-Host "Niveaux de cohÃ©rence reÃ§us: $($ConsistencyAnalysis.Levels -join ', ')"

    $levels = $ConsistencyAnalysis.Levels

    $report = @"
# Analyse de la CohÃ©rence de la Ponctuation entre Niveaux de Titres

## RÃ©sumÃ©

- **Nombre total de niveaux de titres**: $($levels.Count)
- **Score de cohÃ©rence globale**: $($ConsistencyAnalysis.OverallConsistency)%
- **Paires de niveaux cohÃ©rentes**: $($ConsistencyAnalysis.ConsistentPairs)/$($ConsistencyAnalysis.TotalPairs)

## Analyse par Niveau de Titre

"@

    foreach ($level in $levels) {
        Write-Host "Traitement du niveau $level dans le rapport..."

        if (-not $LevelAnalysis.LevelAnalysis.ContainsKey($level)) {
            Write-Host "ERREUR: Le niveau $level n'existe pas dans LevelAnalysis.LevelAnalysis!"
            $levelData = @{
                TotalTitles               = 0
                TitlesWithPunctuation     = 0
                PercentageWithPunctuation = 0
                PunctuationByMark         = @{}
            }
        } else {
            $levelData = $LevelAnalysis.LevelAnalysis[$level]
        }

        $report += @"

### Niveau $level (${'#' * $level})

- **Nombre total de titres**: $($levelData.TotalTitles)
- **Titres avec ponctuation**: $($levelData.TitlesWithPunctuation) ($($levelData.PercentageWithPunctuation)%)

"@

        if ($levelData.PunctuationByMark.Count -gt 0) {
            $report += @"
**Marques de ponctuation utilisÃ©es:**

"@
            foreach ($mark in $levelData.PunctuationByMark.Keys | Sort-Object) {
                $report += @"
- **$mark**: $($levelData.PunctuationByMark[$mark]) occurrences
"@
            }
        } else {
            $report += @"
**Aucune marque de ponctuation utilisÃ©e Ã  ce niveau.**

"@
        }

        if ($IncludeExamples) {
            $examples = $null

            if ($LevelAnalysis.Examples -and $LevelAnalysis.Examples.ContainsKey($level)) {
                $examples = $LevelAnalysis.Examples[$level]
                Write-Host "Exemples trouvÃ©s pour le niveau $level."
            } else {
                Write-Host "Aucun exemple trouvÃ© pour le niveau $level."
                # CrÃ©er des exemples vides
                $examples = @{
                    WithPunctuation    = @()
                    WithoutPunctuation = @()
                }
            }

            $report += @"

**Exemples:**

"@
            if ($examples -and $examples.WithPunctuation -and $examples.WithPunctuation.Count -gt 0) {
                $report += @"
*Titres avec ponctuation:*
"@
                foreach ($example in $examples.WithPunctuation) {
                    $report += @"
- "$example"
"@
                }
            }

            if ($examples -and $examples.WithoutPunctuation -and $examples.WithoutPunctuation.Count -gt 0) {
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

## Analyse de CohÃ©rence entre Niveaux

"@

    foreach ($pair in $ConsistencyAnalysis.PairwiseConsistency.Keys | Sort-Object) {
        $pairData = $ConsistencyAnalysis.PairwiseConsistency[$pair]
        $level1 = $pairData.Level1
        $level2 = $pairData.Level2

        $report += @"

### Niveaux $level1 et $level2

- **Score de cohÃ©rence**: $($pairData.ConsistencyScore)%
- **CohÃ©rence d'utilisation globale**: $(if ($pairData.OverallUsageConsistent) { "Oui" } else { "Non" })
- **CohÃ©rence des marques de ponctuation**: $($pairData.MarkConsistency)% ($($pairData.CommonMarks)/$($pairData.TotalMarks) marques communes)
- **CohÃ©rence de ponctuation en dÃ©but de titre**: $(if ($pairData.StartsWithConsistent) { "Oui" } else { "Non" })
- **CohÃ©rence de ponctuation en fin de titre**: $(if ($pairData.EndsWithConsistent) { "Oui" } else { "Non" })
- **Verdict**: $(if ($pairData.IsConsistent) { "CohÃ©rent" } else { "IncohÃ©rent" })

"@
    }

    $report += @"

## Recommandations

"@

    if ($ConsistencyAnalysis.OverallConsistency -ge 75) {
        $report += @"
La cohÃ©rence de la ponctuation entre les niveaux de titres est bonne (>= 75%). Continuer Ã  maintenir cette cohÃ©rence dans les futurs ajouts au document.
"@
    } else {
        $report += @"
La cohÃ©rence de la ponctuation entre les niveaux de titres pourrait Ãªtre amÃ©liorÃ©e (< 75%). Voici quelques recommandations:

1. **Paires de niveaux incohÃ©rentes**: $(
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
3. **Recommandations gÃ©nÃ©rales**:
   - Standardiser l'utilisation de la ponctuation Ã  travers tous les niveaux de titres
   - Ã‰viter de mÃ©langer diffÃ©rents styles de ponctuation entre les niveaux
   - Maintenir une cohÃ©rence dans l'utilisation des marques de ponctuation spÃ©cifiques
   - ConsidÃ©rer l'adoption d'un guide de style pour la ponctuation des titres
"@
    }

    return $report
}

# ExÃ©cuter l'analyse
try {
    # Lire le contenu du fichier
    Write-Host "Lecture du fichier..."
    $content = Get-Content -Path $testFilePath -Raw -Encoding UTF8
    Write-Host "Contenu du fichier lu avec succÃ¨s."

    # Extraire les titres
    Write-Host "Extraction des titres..."
    $titles = Get-MarkdownTitles -Content $content
    Write-Host "Titres extraits: $($titles.Count)"

    # Afficher les titres extraits
    foreach ($title in $titles) {
        Write-Host "Titre: $($title.Title), Niveau: $($title.Level)"
    }

    # Analyser la ponctuation par niveau
    Write-Host "Analyse de la ponctuation par niveau..."
    $levelAnalysis = Get-TitlePunctuationByLevel -Titles $titles
    Write-Host "Analyse par niveau terminÃ©e."

    # Afficher les niveaux analysÃ©s
    Write-Host "Niveaux analysÃ©s: $($levelAnalysis.LevelAnalysis.Keys -join ', ')"

    # Analyser la cohÃ©rence entre les niveaux
    Write-Host "Analyse de la cohÃ©rence entre niveaux..."
    $consistencyAnalysis = Get-PunctuationConsistencyAnalysis -LevelAnalysis $levelAnalysis.LevelAnalysis
    Write-Host "Analyse de cohÃ©rence terminÃ©e."

    # Afficher les paires analysÃ©es
    Write-Host "Paires analysÃ©es: $($consistencyAnalysis.PairwiseConsistency.Keys -join ', ')"

    # GÃ©nÃ©rer le rapport d'analyse
    Write-Host "GÃ©nÃ©ration du rapport..."
    $report = New-PunctuationConsistencyReport -LevelAnalysis $levelAnalysis -ConsistencyAnalysis $consistencyAnalysis -IncludeExamples $true
    Write-Host "Rapport gÃ©nÃ©rÃ© avec succÃ¨s."

    # Enregistrer le rapport
    Set-Content -Path $testOutputPath -Value $report -Encoding UTF8

    Write-Host "Analyse terminÃ©e. Rapport enregistrÃ© dans '$testOutputPath'."

    # Afficher le rapport
    Write-Host "`n--- DÃ©but du rapport ---`n"
    Write-Host $report
    Write-Host "`n--- Fin du rapport ---`n"
} catch {
    Write-Error "Une erreur s'est produite lors de l'analyse: $_"
}

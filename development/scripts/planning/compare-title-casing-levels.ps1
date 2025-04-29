# Définir l'encodage UTF-8 pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Paramètres fixes
$FilePath = "..\..\data\planning\expertise-levels.md"
$OutputPath = "..\..\data\planning\title-casing-levels-comparison.md"
$IncludeExamples = $true

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

# Fonction pour déterminer le style de casse d'un titre
function Get-CasingStyle {
    param(
        [string]$Text
    )

    # Supprimer les caractères spéciaux et les nombres pour l'analyse de casse
    $cleanText = $Text -replace '[^a-zA-Z\s]', ''

    # Si le texte est vide après nettoyage, retourner "Unknown"
    if ([string]::IsNullOrWhiteSpace($cleanText)) {
        return "Unknown"
    }

    # Diviser le texte en mots
    $words = $cleanText -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    # Si aucun mot n'est trouvé, retourner "Unknown"
    if ($words.Count -eq 0) {
        return "Unknown"
    }

    # Vérifier si tous les mots commencent par une majuscule (Title Case)
    $allTitleCase = $true
    foreach ($word in $words) {
        if ($word.Length -gt 0 -and -not [char]::IsUpper($word[0])) {
            $allTitleCase = $false
            break
        }
    }

    # Vérifier si le premier mot commence par une majuscule et les autres par une minuscule (Sentence Case)
    $sentenceCase = $words.Count -gt 0 -and [char]::IsUpper($words[0][0])
    for ($i = 1; $i -lt $words.Count; $i++) {
        if ($words[$i].Length -gt 0 -and [char]::IsUpper($words[$i][0])) {
            $sentenceCase = $false
            break
        }
    }

    # Vérifier si tous les mots sont en majuscules (ALL CAPS)
    $allCaps = $true
    foreach ($word in $words) {
        if ($word -cne $word.ToUpper()) {
            $allCaps = $false
            break
        }
    }

    # Vérifier si tous les mots sont en minuscules (all lowercase)
    $allLowercase = $true
    foreach ($word in $words) {
        if ($word -cne $word.ToLower()) {
            $allLowercase = $false
            break
        }
    }

    # Vérifier si c'est du CamelCase (pas d'espaces, première lettre minuscule, autres mots commencent par majuscule)
    $camelCase = $cleanText -cmatch '^[a-z][a-zA-Z0-9]*$' -and $cleanText -cmatch '[a-z][A-Z]'

    # Vérifier si c'est du PascalCase (pas d'espaces, première lettre majuscule, autres mots commencent par majuscule)
    $pascalCase = $cleanText -cmatch '^[A-Z][a-zA-Z0-9]*$' -and $cleanText -cmatch '[a-z][A-Z]'

    # Déterminer le style de casse
    if ($allCaps) {
        return "ALL_CAPS"
    } elseif ($allLowercase) {
        return "all_lowercase"
    } elseif ($allTitleCase) {
        return "Title Case"
    } elseif ($sentenceCase) {
        return "Sentence case"
    } elseif ($camelCase) {
        return "camelCase"
    } elseif ($pascalCase) {
        return "PascalCase"
    } else {
        return "Mixed Case"
    }
}

# Fonction pour analyser les conventions de casse dans les titres
function Get-TitleCasingAnalysis {
    param(
        [array]$Titles
    )

    $analysis = @{
        TotalTitles  = $Titles.Count
        CasingStyles = @{}
        ByLevel      = @{}
        Examples     = @{}
        Consistency  = @{
            OverallConsistency      = 0
            ConsistencyByLevel      = @{}
            DominantStyle           = ""
            DominantStylePercentage = 0
        }
    }

    # Analyser chaque titre
    foreach ($title in $Titles) {
        $style = Get-CasingStyle -Text $title.Title
        $level = $title.Level

        # Compter les styles de casse
        if (-not $analysis.CasingStyles.ContainsKey($style)) {
            $analysis.CasingStyles[$style] = 0
            $analysis.Examples[$style] = @()
        }
        $analysis.CasingStyles[$style]++

        # Ajouter un exemple si nécessaire
        if ($analysis.Examples[$style].Count -lt 3) {
            $analysis.Examples[$style] += $title.Title
        }

        # Compter les styles par niveau
        if (-not $analysis.ByLevel.ContainsKey($level)) {
            $analysis.ByLevel[$level] = @{}
        }
        if (-not $analysis.ByLevel[$level].ContainsKey($style)) {
            $analysis.ByLevel[$level][$style] = 0
        }
        $analysis.ByLevel[$level][$style]++
    }

    # Déterminer le style dominant global
    $dominantStyle = ""
    $maxCount = 0
    foreach ($style in $analysis.CasingStyles.Keys) {
        $count = $analysis.CasingStyles[$style]
        if ($count -gt $maxCount) {
            $maxCount = $count
            $dominantStyle = $style
        }
    }
    $analysis.Consistency.DominantStyle = $dominantStyle
    $analysis.Consistency.DominantStylePercentage = if ($analysis.TotalTitles -gt 0) {
        [math]::Round(($maxCount / $analysis.TotalTitles) * 100, 2)
    } else {
        0
    }

    # Calculer la cohérence globale (pourcentage du style dominant)
    $analysis.Consistency.OverallConsistency = $analysis.Consistency.DominantStylePercentage

    # Calculer la cohérence par niveau
    foreach ($level in $analysis.ByLevel.Keys) {
        $levelTotal = 0
        $levelMax = 0
        $levelDominant = ""

        foreach ($style in $analysis.ByLevel[$level].Keys) {
            $count = $analysis.ByLevel[$level][$style]
            $levelTotal += $count
            if ($count -gt $levelMax) {
                $levelMax = $count
                $levelDominant = $style
            }
        }

        $levelConsistency = if ($levelTotal -gt 0) {
            [math]::Round(($levelMax / $levelTotal) * 100, 2)
        } else {
            0
        }

        $analysis.Consistency.ConsistencyByLevel[$level] = @{
            DominantStyle = $levelDominant
            Consistency   = $levelConsistency
            TotalTitles   = $levelTotal
        }
    }

    return $analysis
}

# Fonction pour comparer les conventions de casse entre les niveaux de titres
function Compare-TitleCasingLevels {
    param(
        [hashtable]$Analysis
    )

    $comparison = @{
        LevelCount        = $Analysis.ByLevel.Count
        Levels            = $Analysis.ByLevel.Keys | Sort-Object
        ConsistencyMatrix = @{}
        StyleTransitions  = @{}
        ConsistencyScore  = 0
        Recommendations   = @{}
    }

    # Créer une matrice de comparaison entre les niveaux
    foreach ($level1 in $comparison.Levels) {
        $comparison.ConsistencyMatrix[$level1] = @{}
        $dominantStyle1 = $Analysis.Consistency.ConsistencyByLevel[$level1].DominantStyle

        foreach ($level2 in $comparison.Levels) {
            if ($level1 -ne $level2) {
                $dominantStyle2 = $Analysis.Consistency.ConsistencyByLevel[$level2].DominantStyle
                $consistent = $dominantStyle1 -eq $dominantStyle2

                $comparison.ConsistencyMatrix[$level1][$level2] = @{
                    Consistent  = $consistent
                    Level1Style = $dominantStyle1
                    Level2Style = $dominantStyle2
                }
            }
        }
    }

    # Analyser les transitions de style entre niveaux adjacents
    for ($i = 1; $i -lt $comparison.Levels.Count; $i++) {
        $currentLevel = $comparison.Levels[$i]
        $previousLevel = $comparison.Levels[$i - 1]

        $currentStyle = $Analysis.Consistency.ConsistencyByLevel[$currentLevel].DominantStyle
        $previousStyle = $Analysis.Consistency.ConsistencyByLevel[$previousLevel].DominantStyle

        $comparison.StyleTransitions["$previousLevel->$currentLevel"] = @{
            FromStyle  = $previousStyle
            ToStyle    = $currentStyle
            Consistent = $previousStyle -eq $currentStyle
        }
    }

    # Calculer un score global de cohérence entre niveaux
    $consistentPairs = 0
    $totalPairs = 0

    foreach ($level1 in $comparison.ConsistencyMatrix.Keys) {
        foreach ($level2 in $comparison.ConsistencyMatrix[$level1].Keys) {
            $totalPairs++
            if ($comparison.ConsistencyMatrix[$level1][$level2].Consistent) {
                $consistentPairs++
            }
        }
    }

    $comparison.ConsistencyScore = if ($totalPairs -gt 0) {
        [math]::Round(($consistentPairs / $totalPairs) * 100, 2)
    } else {
        100  # Si aucune paire à comparer, considérer comme 100% cohérent
    }

    # Générer des recommandations pour améliorer la cohérence
    if ($comparison.ConsistencyScore -lt 100) {
        # Identifier le style le plus utilisé à travers tous les niveaux
        $styleCount = @{}
        foreach ($level in $comparison.Levels) {
            $style = $Analysis.Consistency.ConsistencyByLevel[$level].DominantStyle
            if (-not $styleCount.ContainsKey($style)) {
                $styleCount[$style] = 0
            }
            $styleCount[$style]++
        }

        $mostCommonStyle = $styleCount.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First 1 -ExpandProperty Key

        # Recommander d'utiliser le style le plus commun pour tous les niveaux
        $comparison.Recommendations["GlobalStyle"] = $mostCommonStyle

        # Recommandations spécifiques par niveau
        foreach ($level in $comparison.Levels) {
            $currentStyle = $Analysis.Consistency.ConsistencyByLevel[$level].DominantStyle
            if ($currentStyle -ne $mostCommonStyle) {
                $comparison.Recommendations[$level] = @{
                    CurrentStyle     = $currentStyle
                    RecommendedStyle = $mostCommonStyle
                    Examples         = $Analysis.Examples[$mostCommonStyle] | Select-Object -First 2
                }
            }
        }
    }

    return $comparison
}

# Fonction pour générer un rapport de comparaison des conventions de casse entre niveaux
function New-CasingLevelsComparisonReport {
    param(
        [hashtable]$Analysis,
        [hashtable]$Comparison,
        [bool]$IncludeExamples
    )

    $report = @"
# Comparaison des Conventions de Casse entre Niveaux de Titres

## Résumé

- **Nombre total de titres analysés**: $($Analysis.TotalTitles)
- **Nombre de niveaux de titres**: $($Comparison.LevelCount)
- **Score de cohérence entre niveaux**: $($Comparison.ConsistencyScore)%

## Styles Dominants par Niveau

"@

    # Ajouter les styles dominants par niveau
    foreach ($level in $Comparison.Levels) {
        $levelInfo = $Analysis.Consistency.ConsistencyByLevel[$level]
        $report += "`n- **Niveau $level**: $($levelInfo.DominantStyle) ($($levelInfo.Consistency)% de cohérence interne)"
    }

    # Ajouter la matrice de cohérence entre niveaux
    $report += "`n`n## Matrice de Cohérence entre Niveaux"

    $report += "`n`n| Niveau | " + ($Comparison.Levels -join " | ") + " |"
    $report += "`n|" + ("-" * 8) + "|" + (($Comparison.Levels | ForEach-Object { "-" * 10 }) -join "|") + "|"

    foreach ($level1 in $Comparison.Levels) {
        $row = "`n| **$level1** |"

        foreach ($level2 in $Comparison.Levels) {
            if ($level1 -eq $level2) {
                $row += " - |"
            } else {
                $consistent = $Comparison.ConsistencyMatrix[$level1][$level2].Consistent
                $symbol = if ($consistent) { "OK" } else { "NOK" }
                $row += " $symbol |"
            }
        }

        $report += $row
    }

    # Ajouter les transitions de style entre niveaux adjacents
    $report += "`n`n## Transitions de Style entre Niveaux Adjacents"

    if ($Comparison.StyleTransitions.Count -eq 0) {
        $report += "`n- Aucune transition entre niveaux adjacents détectée"
    } else {
        foreach ($transition in $Comparison.StyleTransitions.Keys | Sort-Object) {
            $info = $Comparison.StyleTransitions[$transition]
            $consistent = if ($info.Consistent) { "cohérente" } else { "incohérente" }
            $report += "`n- **$transition**: $($info.FromStyle) → $($info.ToStyle) (transition $consistent)"
        }
    }

    # Ajouter des exemples de styles si demandé
    if ($IncludeExamples) {
        $report += "`n`n## Exemples de Styles par Niveau"

        foreach ($level in $Comparison.Levels) {
            $dominantStyle = $Analysis.Consistency.ConsistencyByLevel[$level].DominantStyle
            $report += "`n`n### Niveau $level ($dominantStyle)"

            $levelTitles = $Analysis.Titles | Where-Object { $_.Level -eq $level }
            $examples = $levelTitles | Where-Object { (Get-CasingStyle -Text $_.Title) -eq $dominantStyle } | Select-Object -First 3 -ExpandProperty Title

            if ($examples.Count -eq 0) {
                $report += "`n- Aucun exemple disponible"
            } else {
                foreach ($example in $examples) {
                    $report += "`n- `"$example`""
                }
            }
        }
    }

    # Ajouter des recommandations
    $report += "`n`n## Recommandations pour Améliorer la Cohérence"

    if ($Comparison.ConsistencyScore -eq 100) {
        $report += "`n- Les conventions de casse sont parfaitement cohérentes entre tous les niveaux de titres."
        $report += "`n- Maintenir cette cohérence dans les futurs ajouts."
    } else {
        $report += "`n- **Style recommandé pour tous les niveaux**: $($Comparison.Recommendations.GlobalStyle)"
        $report += "`n- Niveaux nécessitant une standardisation:"

        $needsStandardization = $false
        foreach ($level in $Comparison.Levels) {
            if ($Comparison.Recommendations.ContainsKey($level)) {
                $needsStandardization = $true
                $info = $Comparison.Recommendations[$level]
                $report += "`n  - **Niveau $level**: Remplacer '$($info.CurrentStyle)' par '$($info.RecommendedStyle)'"

                if ($IncludeExamples -and $info.Examples.Count -gt 0) {
                    $report += "`n    *Exemples du style recommandé:*"
                    foreach ($example in $info.Examples) {
                        $report += "`n    - `"$example`""
                    }
                }
            }
        }

        if (-not $needsStandardization) {
            $report += "`n  - Aucun niveau spécifique ne nécessite de standardisation, mais la cohérence globale peut être améliorée."
        }

        $report += "`n`n- **Strategies de mise en oeuvre**:"
        $report += "`n  1. Standardiser d'abord les niveaux superieurs (1 et 2), puis les niveaux inferieurs."
        $report += "`n  2. Maintenir une cohérence stricte entre les niveaux adjacents."
        $report += "`n  3. Documenter les conventions de casse dans un guide de style pour référence future."
    }

    # Ajouter une conclusion
    $report += "`n`n## Conclusion"

    if ($Comparison.ConsistencyScore -ge 80) {
        $report += "`n- La cohérence des conventions de casse entre les niveaux est bonne (>= 80%)."
        $report += "`n- Les incohérences mineures peuvent être corrigées progressivement."
    } elseif ($Comparison.ConsistencyScore -ge 50) {
        $report += "`n- La cohérence des conventions de casse entre les niveaux est moyenne (>= 50%)."
        $report += "`n- Une révision systématique est recommandée pour améliorer la cohérence."
    } else {
        $report += "`n- La cohérence des conventions de casse entre les niveaux est faible (< 50%)."
        $report += "`n- Une refonte complète des conventions de casse est recommandée."
    }

    $report += "`n`n- L'adoption d'une convention de casse cohérente améliore la lisibilité et la navigation dans le document."
    $report += "`n- La cohérence visuelle renforce la structure hiérarchique du document."

    return $report
}

# Exécution principale
try {
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier à analyser n'existe pas : $FilePath"
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

    # Extraire les titres
    $titles = Get-MarkdownTitles -Content $content

    # Analyser les conventions de casse
    $analysis = Get-TitleCasingAnalysis -Titles $titles

    # Ajouter les titres à l'analyse pour les utiliser plus tard
    $analysis.Titles = $titles

    # Comparer les conventions de casse entre les niveaux
    $comparison = Compare-TitleCasingLevels -Analysis $analysis

    # Générer le rapport de comparaison
    $report = New-CasingLevelsComparisonReport -Analysis $analysis -Comparison $comparison -IncludeExamples $IncludeExamples

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer le rapport avec BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    # Afficher un résumé
    Write-Host "Comparaison des conventions de casse entre niveaux terminée."
    Write-Host "Nombre total de titres analysés : $($analysis.TotalTitles)"
    Write-Host "Nombre de niveaux de titres : $($comparison.LevelCount)"
    Write-Host "Score de cohérence entre niveaux : $($comparison.ConsistencyScore)%"
    Write-Host "Rapport généré à : $OutputPath"

    # Retourner la comparaison pour une utilisation ultérieure
    return @{
        Analysis   = $analysis
        Comparison = $comparison
    }
} catch {
    Write-Error "Erreur lors de la comparaison des conventions de casse entre niveaux : $_"

    # Afficher la pile d'appels pour faciliter le débogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}

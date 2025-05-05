# DÃ©finir l'encodage UTF-8 pour les caractÃ¨res accentuÃ©s
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ParamÃ¨tres fixes
$FilePath = "..\..\data\planning\expertise-levels.md"
$OutputPath = "..\..\data\planning\title-punctuation-analysis.md"
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
            Title = $title
            Level = $level
            Type = "Hash"
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
            Title = $title
            Level = $level
            Type = "Underline"
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
        HasPunctuation = $false
        PunctuationMarks = @{}
        StartsWith = $null
        EndsWith = $null
        ContainsSpecialCharacters = $false
        SpecialCharacters = @{}
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

# Fonction pour analyser la ponctuation dans les titres
function Get-TitlePunctuationAnalysis {
    param(
        [array]$Titles
    )

    $analysis = @{
        TotalTitles = $Titles.Count
        TitlesWithPunctuation = 0
        PunctuationByMark = @{}
        PunctuationByPosition = @{
            StartsWith = @{}
            EndsWith = @{}
        }
        PunctuationByLevel = @{}
        SpecialCharacters = @{}
        Examples = @{
            WithPunctuation = @()
            WithoutPunctuation = @()
            WithSpecialCharacters = @()
        }
    }

    # Analyser chaque titre
    foreach ($title in $Titles) {
        $titleAnalysis = Get-PunctuationAnalysis -Text $title.Title
        $level = $title.Level

        # Compter les titres avec ponctuation
        if ($titleAnalysis.HasPunctuation) {
            $analysis.TitlesWithPunctuation++
            
            # Ajouter un exemple si nÃ©cessaire
            if ($analysis.Examples.WithPunctuation.Count -lt 5) {
                $analysis.Examples.WithPunctuation += $title.Title
            }

            # Compter les marques de ponctuation
            foreach ($mark in $titleAnalysis.PunctuationMarks.Keys) {
                $count = $titleAnalysis.PunctuationMarks[$mark]
                if (-not $analysis.PunctuationByMark.ContainsKey($mark)) {
                    $analysis.PunctuationByMark[$mark] = 0
                }
                $analysis.PunctuationByMark[$mark] += $count
            }

            # Compter les positions de ponctuation
            if ($titleAnalysis.StartsWith) {
                $mark = $titleAnalysis.StartsWith
                if (-not $analysis.PunctuationByPosition.StartsWith.ContainsKey($mark)) {
                    $analysis.PunctuationByPosition.StartsWith[$mark] = 0
                }
                $analysis.PunctuationByPosition.StartsWith[$mark]++
            }

            if ($titleAnalysis.EndsWith) {
                $mark = $titleAnalysis.EndsWith
                if (-not $analysis.PunctuationByPosition.EndsWith.ContainsKey($mark)) {
                    $analysis.PunctuationByPosition.EndsWith[$mark] = 0
                }
                $analysis.PunctuationByPosition.EndsWith[$mark]++
            }
        } else {
            # Ajouter un exemple si nÃ©cessaire
            if ($analysis.Examples.WithoutPunctuation.Count -lt 5) {
                $analysis.Examples.WithoutPunctuation += $title.Title
            }
        }

        # Compter les caractÃ¨res spÃ©ciaux
        if ($titleAnalysis.ContainsSpecialCharacters) {
            # Ajouter un exemple si nÃ©cessaire
            if ($analysis.Examples.WithSpecialCharacters.Count -lt 5) {
                $analysis.Examples.WithSpecialCharacters += $title.Title
            }

            # Compter les caractÃ¨res spÃ©ciaux
            foreach ($char in $titleAnalysis.SpecialCharacters.Keys) {
                $count = $titleAnalysis.SpecialCharacters[$char]
                if (-not $analysis.SpecialCharacters.ContainsKey($char)) {
                    $analysis.SpecialCharacters[$char] = 0
                }
                $analysis.SpecialCharacters[$char] += $count
            }
        }

        # Compter par niveau
        if (-not $analysis.PunctuationByLevel.ContainsKey($level)) {
            $analysis.PunctuationByLevel[$level] = @{
                Total = 0
                WithPunctuation = 0
                Percentage = 0
                Marks = @{}
            }
        }
        $analysis.PunctuationByLevel[$level].Total++
        
        if ($titleAnalysis.HasPunctuation) {
            $analysis.PunctuationByLevel[$level].WithPunctuation++
            
            # Compter les marques par niveau
            foreach ($mark in $titleAnalysis.PunctuationMarks.Keys) {
                $count = $titleAnalysis.PunctuationMarks[$mark]
                if (-not $analysis.PunctuationByLevel[$level].Marks.ContainsKey($mark)) {
                    $analysis.PunctuationByLevel[$level].Marks[$mark] = 0
                }
                $analysis.PunctuationByLevel[$level].Marks[$mark] += $count
            }
        }
    }

    # Calculer les pourcentages par niveau
    foreach ($level in $analysis.PunctuationByLevel.Keys) {
        $total = $analysis.PunctuationByLevel[$level].Total
        $withPunctuation = $analysis.PunctuationByLevel[$level].WithPunctuation
        $percentage = if ($total -gt 0) { [math]::Round(($withPunctuation / $total) * 100, 2) } else { 0 }
        $analysis.PunctuationByLevel[$level].Percentage = $percentage
    }

    return $analysis
}

# Fonction pour gÃ©nÃ©rer un rapport d'analyse de la ponctuation
function New-PunctuationAnalysisReport {
    param(
        [hashtable]$Analysis,
        [bool]$IncludeExamples
    )

    $percentageWithPunctuation = if ($Analysis.TotalTitles -gt 0) { 
        [math]::Round(($Analysis.TitlesWithPunctuation / $Analysis.TotalTitles) * 100, 2) 
    } else { 
        0 
    }

    $report = @"
# Analyse de l'Utilisation de la Ponctuation dans les Titres

## RÃ©sumÃ©

- **Nombre total de titres analysÃ©s**: $($Analysis.TotalTitles)
- **Titres contenant de la ponctuation**: $($Analysis.TitlesWithPunctuation) ($percentageWithPunctuation%)

## Distribution des Marques de Ponctuation

"@

    # Ajouter la distribution des marques de ponctuation
    if ($Analysis.PunctuationByMark.Count -eq 0) {
        $report += "`n- Aucune marque de ponctuation dÃ©tectÃ©e dans les titres"
    } else {
        foreach ($mark in $Analysis.PunctuationByMark.Keys | Sort-Object) {
            $count = $Analysis.PunctuationByMark[$mark]
            $report += "`n- **$mark**: $count occurrences"
        }
    }

    # Ajouter la distribution des caractÃ¨res spÃ©ciaux
    $report += "`n`n## CaractÃ¨res SpÃ©ciaux"
    
    if ($Analysis.SpecialCharacters.Count -eq 0) {
        $report += "`n- Aucun caractÃ¨re spÃ©cial dÃ©tectÃ© dans les titres"
    } else {
        foreach ($char in $Analysis.SpecialCharacters.Keys | Sort-Object) {
            $count = $Analysis.SpecialCharacters[$char]
            $report += "`n- **$char**: $count occurrences"
        }
    }

    # Ajouter la distribution par position
    $report += "`n`n## Position des Marques de Ponctuation"
    
    $report += "`n`n### Titres CommenÃ§ant par une Ponctuation"
    if ($Analysis.PunctuationByPosition.StartsWith.Count -eq 0) {
        $report += "`n- Aucun titre ne commence par une ponctuation"
    } else {
        foreach ($mark in $Analysis.PunctuationByPosition.StartsWith.Keys | Sort-Object) {
            $count = $Analysis.PunctuationByPosition.StartsWith[$mark]
            $percentage = if ($Analysis.TotalTitles -gt 0) { 
                [math]::Round(($count / $Analysis.TotalTitles) * 100, 2) 
            } else { 
                0 
            }
            $report += "`n- **$mark**: $count titres ($percentage%)"
        }
    }
    
    $report += "`n`n### Titres Se Terminant par une Ponctuation"
    if ($Analysis.PunctuationByPosition.EndsWith.Count -eq 0) {
        $report += "`n- Aucun titre ne se termine par une ponctuation"
    } else {
        foreach ($mark in $Analysis.PunctuationByPosition.EndsWith.Keys | Sort-Object) {
            $count = $Analysis.PunctuationByPosition.EndsWith[$mark]
            $percentage = if ($Analysis.TotalTitles -gt 0) { 
                [math]::Round(($count / $Analysis.TotalTitles) * 100, 2) 
            } else { 
                0 
            }
            $report += "`n- **$mark**: $count titres ($percentage%)"
        }
    }

    # Ajouter l'analyse par niveau
    $report += "`n`n## Analyse par Niveau de Titre"
    
    foreach ($level in $Analysis.PunctuationByLevel.Keys | Sort-Object) {
        $levelInfo = $Analysis.PunctuationByLevel[$level]
        $report += "`n`n### Niveau $level (${level} #)"
        $report += "`n- **Nombre total de titres**: $($levelInfo.Total)"
        $report += "`n- **Titres avec ponctuation**: $($levelInfo.WithPunctuation) ($($levelInfo.Percentage)%)"
        
        if ($levelInfo.Marks.Count -gt 0) {
            $report += "`n`n**Marques de ponctuation utilisÃ©es:**"
            foreach ($mark in $levelInfo.Marks.Keys | Sort-Object) {
                $count = $levelInfo.Marks[$mark]
                $report += "`n- **$mark**: $count occurrences"
            }
        }
    }

    # Ajouter des exemples si demandÃ©
    if ($IncludeExamples) {
        $report += "`n`n## Exemples"
        
        $report += "`n`n### Titres avec Ponctuation"
        if ($Analysis.Examples.WithPunctuation.Count -eq 0) {
            $report += "`n- Aucun exemple disponible"
        } else {
            foreach ($example in $Analysis.Examples.WithPunctuation) {
                $report += "`n- `"$example`""
            }
        }
        
        $report += "`n`n### Titres sans Ponctuation"
        if ($Analysis.Examples.WithoutPunctuation.Count -eq 0) {
            $report += "`n- Aucun exemple disponible"
        } else {
            foreach ($example in $Analysis.Examples.WithoutPunctuation) {
                $report += "`n- `"$example`""
            }
        }
        
        $report += "`n`n### Titres avec CaractÃ¨res SpÃ©ciaux"
        if ($Analysis.Examples.WithSpecialCharacters.Count -eq 0) {
            $report += "`n- Aucun exemple disponible"
        } else {
            foreach ($example in $Analysis.Examples.WithSpecialCharacters) {
                $report += "`n- `"$example`""
            }
        }
    }

    # Ajouter des recommandations
    $report += @"

## Observations et Recommandations

1. **Utilisation globale de la ponctuation**: $(
    if ($percentageWithPunctuation -lt 10) {
        "La ponctuation est rarement utilisÃ©e dans les titres ($percentageWithPunctuation%), ce qui est gÃ©nÃ©ralement conforme aux bonnes pratiques de rÃ©daction technique."
    } elseif ($percentageWithPunctuation -lt 30) {
        "La ponctuation est modÃ©rÃ©ment utilisÃ©e dans les titres ($percentageWithPunctuation%). VÃ©rifier si cette utilisation est cohÃ©rente et justifiÃ©e."
    } else {
        "La ponctuation est frÃ©quemment utilisÃ©e dans les titres ($percentageWithPunctuation%), ce qui peut nuire Ã  la lisibilitÃ©. Envisager de rÃ©duire l'utilisation de la ponctuation."
    }
)

2. **CohÃ©rence par niveau**: $(
    $inconsistentLevels = @()
    foreach ($level in $Analysis.PunctuationByLevel.Keys) {
        $percentage = $Analysis.PunctuationByLevel[$level].Percentage
        if ($percentage -gt 0 -and $percentage -lt 100) {
            $inconsistentLevels += $level
        }
    }
    
    if ($inconsistentLevels.Count -eq 0) {
        "L'utilisation de la ponctuation est cohÃ©rente Ã  chaque niveau de titre."
    } else {
        "L'utilisation de la ponctuation est incohÃ©rente aux niveaux suivants : $($inconsistentLevels -join ", "). Envisager de standardiser l'utilisation de la ponctuation Ã  ces niveaux."
    }
)

3. **Ponctuation en fin de titre**: $(
    $endPercentage = 0
    $totalEndsWith = 0
    foreach ($mark in $Analysis.PunctuationByPosition.EndsWith.Keys) {
        $totalEndsWith += $Analysis.PunctuationByPosition.EndsWith[$mark]
    }
    
    if ($Analysis.TotalTitles -gt 0) {
        $endPercentage = [math]::Round(($totalEndsWith / $Analysis.TotalTitles) * 100, 2)
    }
    
    if ($endPercentage -lt 10) {
        "Peu de titres se terminent par une ponctuation ($endPercentage%), ce qui est gÃ©nÃ©ralement conforme aux bonnes pratiques."
    } elseif ($endPercentage -lt 30) {
        "Un nombre modÃ©rÃ© de titres se terminent par une ponctuation ($endPercentage%). VÃ©rifier si cette utilisation est cohÃ©rente et justifiÃ©e."
    } else {
        "Un nombre important de titres se terminent par une ponctuation ($endPercentage%). Envisager de standardiser cette pratique ou de la rÃ©duire."
    }
)

4. **CaractÃ¨res spÃ©ciaux**: $(
    if ($Analysis.SpecialCharacters.Count -eq 0) {
        "Aucun caractÃ¨re spÃ©cial n'est utilisÃ© dans les titres, ce qui est conforme aux bonnes pratiques."
    } else {
        "Des caractÃ¨res spÃ©ciaux sont utilisÃ©s dans les titres. Envisager de les remplacer par des alternatives plus standard pour amÃ©liorer la lisibilitÃ© et la compatibilitÃ©."
    }
)

5. **Recommandations gÃ©nÃ©rales**:
   - Ã‰viter la ponctuation Ã  la fin des titres, sauf pour les titres interrogatifs qui se terminent par un point d'interrogation.
   - Utiliser les deux-points (:) de maniÃ¨re cohÃ©rente pour introduire des listes ou des explications.
   - Ã‰viter les points (.) Ã  la fin des titres, car ils ne sont gÃ©nÃ©ralement pas nÃ©cessaires.
   - Maintenir une cohÃ©rence dans l'utilisation de la ponctuation Ã  travers les diffÃ©rents niveaux de titres.
   - Ã‰viter les caractÃ¨res spÃ©ciaux dans les titres pour garantir une meilleure compatibilitÃ© et lisibilitÃ©.
"@

    return $report
}

# ExÃ©cution principale
try {
    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier Ã  analyser n'existe pas : $FilePath"
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

    # Extraire les titres
    $titles = Get-MarkdownTitles -Content $content

    # Analyser la ponctuation dans les titres
    $analysis = Get-TitlePunctuationAnalysis -Titles $titles

    # GÃ©nÃ©rer le rapport d'analyse
    $report = New-PunctuationAnalysisReport -Analysis $analysis -IncludeExamples $IncludeExamples

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer le rapport avec BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    # Afficher un rÃ©sumÃ©
    Write-Host "Analyse de la ponctuation dans les titres terminÃ©e."
    Write-Host "Nombre total de titres analysÃ©s : $($analysis.TotalTitles)"
    Write-Host "Titres contenant de la ponctuation : $($analysis.TitlesWithPunctuation) ($(if ($analysis.TotalTitles -gt 0) { [math]::Round(($analysis.TitlesWithPunctuation / $analysis.TotalTitles) * 100, 2) } else { 0 })%)"
    Write-Host "Rapport gÃ©nÃ©rÃ© Ã  : $OutputPath"

    # Retourner l'analyse pour une utilisation ultÃ©rieure
    return $analysis
} catch {
    Write-Error "Erreur lors de l'analyse de la ponctuation dans les titres : $_"

    # Afficher la pile d'appels pour faciliter le dÃ©bogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}

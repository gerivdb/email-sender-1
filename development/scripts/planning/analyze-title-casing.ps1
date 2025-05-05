# DÃ©finir l'encodage UTF-8 pour les caractÃ¨res accentuÃ©s
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

<#
.SYNOPSIS
    Analyse les conventions de casse utilisÃ©es dans les titres d'un document markdown.

.DESCRIPTION
    Ce script analyse un document markdown et identifie les conventions de casse
    utilisÃ©es dans les titres (CamelCase, TitleCase, PascalCase, etc.). Il gÃ©nÃ¨re
    un rapport dÃ©taillÃ© sur les conventions de casse identifiÃ©es, leur frÃ©quence
    et leur cohÃ©rence Ã  travers les diffÃ©rents niveaux de titres.

.PARAMETER FilePath
    Chemin vers le fichier markdown Ã  analyser.
    Par dÃ©faut : ".\development\data\planning\expertise-levels.md"

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport d'analyse.
    Par dÃ©faut : ".\development\data\planning\title-casing-analysis.md"

.PARAMETER IncludeExamples
    Indique si des exemples de titres doivent Ãªtre inclus dans le rapport.
    Par dÃ©faut : $true

.EXAMPLE
    .\analyze-title-casing.ps1
    Analyse les conventions de casse des titres du document par dÃ©faut.

.EXAMPLE
    .\analyze-title-casing.ps1 -FilePath "path\to\document.md" -OutputPath "path\to\output.md" -IncludeExamples $false
    Analyse les conventions de casse des titres du document spÃ©cifiÃ© sans inclure d'exemples dans le rapport.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2023-09-21
#>

# ParamÃ¨tres
param(
    [string]$FilePath = ".\development\data\planning\expertise-levels.md",
    [string]$OutputPath = ".\development\data\planning\title-casing-analysis.md",
    [bool]$IncludeExamples = $true
)

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

    # Trier les titres par numÃ©ro de ligne
    return $titles | Sort-Object -Property LineNumber
}

# Fonction pour dÃ©terminer le style de casse d'un titre
function Get-CasingStyle {
    param(
        [string]$Text
    )

    # Supprimer les caractÃ¨res spÃ©ciaux et les nombres pour l'analyse de casse
    $cleanText = $Text -replace '[^a-zA-Z\s]', ''

    # Si le texte est vide aprÃ¨s nettoyage, retourner "Unknown"
    if ([string]::IsNullOrWhiteSpace($cleanText)) {
        return "Unknown"
    }

    # Diviser le texte en mots
    $words = $cleanText -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    # Si aucun mot n'est trouvÃ©, retourner "Unknown"
    if ($words.Count -eq 0) {
        return "Unknown"
    }

    # VÃ©rifier si tous les mots commencent par une majuscule (Title Case)
    $allTitleCase = $true
    foreach ($word in $words) {
        if ($word.Length -gt 0 -and -not [char]::IsUpper($word[0])) {
            $allTitleCase = $false
            break
        }
    }

    # VÃ©rifier si le premier mot commence par une majuscule et les autres par une minuscule (Sentence Case)
    $sentenceCase = $words.Count -gt 0 -and [char]::IsUpper($words[0][0])
    for ($i = 1; $i -lt $words.Count; $i++) {
        if ($words[$i].Length -gt 0 -and [char]::IsUpper($words[$i][0])) {
            $sentenceCase = $false
            break
        }
    }

    # VÃ©rifier si tous les mots sont en majuscules (ALL CAPS)
    $allCaps = $true
    foreach ($word in $words) {
        if ($word -cne $word.ToUpper()) {
            $allCaps = $false
            break
        }
    }

    # VÃ©rifier si tous les mots sont en minuscules (all lowercase)
    $allLowercase = $true
    foreach ($word in $words) {
        if ($word -cne $word.ToLower()) {
            $allLowercase = $false
            break
        }
    }

    # VÃ©rifier si c'est du CamelCase (pas d'espaces, premiÃ¨re lettre minuscule, autres mots commencent par majuscule)
    $camelCase = $cleanText -cmatch '^[a-z][a-zA-Z0-9]*$' -and $cleanText -cmatch '[a-z][A-Z]'

    # VÃ©rifier si c'est du PascalCase (pas d'espaces, premiÃ¨re lettre majuscule, autres mots commencent par majuscule)
    $pascalCase = $cleanText -cmatch '^[A-Z][a-zA-Z0-9]*$' -and $cleanText -cmatch '[a-z][A-Z]'

    # DÃ©terminer le style de casse
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

        # Ajouter un exemple si nÃ©cessaire
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

    # DÃ©terminer le style dominant global
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

    # Calculer la cohÃ©rence globale (pourcentage du style dominant)
    $analysis.Consistency.OverallConsistency = $analysis.Consistency.DominantStylePercentage

    # Calculer la cohÃ©rence par niveau
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

# Fonction pour gÃ©nÃ©rer un rapport d'analyse des conventions de casse
function New-CasingAnalysisReport {
    param(
        [hashtable]$Analysis,
        [bool]$IncludeExamples
    )

    $report = @"
# Analyse des Conventions de Casse dans les Titres

## RÃ©sumÃ©

- **Nombre total de titres analysÃ©s**: $($Analysis.TotalTitles)
- **Style de casse dominant**: $($Analysis.Consistency.DominantStyle) ($($Analysis.Consistency.DominantStylePercentage)%)
- **CohÃ©rence globale**: $($Analysis.Consistency.OverallConsistency)%

## Distribution des Styles de Casse

"@

    # Ajouter la distribution des styles de casse
    foreach ($style in $Analysis.CasingStyles.Keys | Sort-Object) {
        $count = $Analysis.CasingStyles[$style]
        $percentage = if ($Analysis.TotalTitles -gt 0) {
            [math]::Round(($count / $Analysis.TotalTitles) * 100, 2)
        } else {
            0
        }
        $report += "`n- **$style**: $count titres ($percentage%)"
    }

    # Ajouter des exemples si demandÃ©
    if ($IncludeExamples) {
        $report += "`n`n## Exemples par Style de Casse`n"

        foreach ($style in $Analysis.Examples.Keys | Sort-Object) {
            $examples = $Analysis.Examples[$style]
            $report += "`n### $style`n"

            if ($examples.Count -eq 0) {
                $report += "`n*Aucun exemple disponible*"
            } else {
                foreach ($example in $examples) {
                    $report += "`n- `"$example`""
                }
            }
        }
    }

    # Ajouter l'analyse par niveau
    $report += "`n`n## Analyse par Niveau de Titre`n"

    foreach ($level in $Analysis.ByLevel.Keys | Sort-Object) {
        $levelInfo = $Analysis.Consistency.ConsistencyByLevel[$level]
        $report += "`n### Niveau $level (${level} #)`n"
        $report += "`n- **Nombre de titres**: $($levelInfo.TotalTitles)"
        $report += "`n- **Style dominant**: $($levelInfo.DominantStyle)"
        $report += "`n- **CohÃ©rence**: $($levelInfo.Consistency)%`n"

        $report += "`n**Distribution des styles:**`n"
        foreach ($style in $Analysis.ByLevel[$level].Keys | Sort-Object) {
            $count = $Analysis.ByLevel[$level][$style]
            $percentage = if ($levelInfo.TotalTitles -gt 0) {
                [math]::Round(($count / $levelInfo.TotalTitles) * 100, 2)
            } else {
                0
            }
            $report += "`n- ${style}: $count titres ($percentage%)"
        }
    }

    # Ajouter des recommandations
    $report += @"

## Recommandations

1. **CohÃ©rence globale**: $(if ($Analysis.Consistency.OverallConsistency -ge 80) { "La cohÃ©rence globale est bonne (>= 80%). Maintenir cette cohÃ©rence dans les futurs ajouts." } else { "La cohÃ©rence globale est infÃ©rieure Ã  80%. Envisager de standardiser les conventions de casse." })

2. **Style recommandÃ©**: Le style dominant est **$($Analysis.Consistency.DominantStyle)**. $(if ($Analysis.Consistency.DominantStyle -eq "Title Case") { "Ce style est appropriÃ© pour les titres et est largement utilisÃ© dans la documentation technique." } elseif ($Analysis.Consistency.DominantStyle -eq "Sentence case") { "Ce style est clair et facile Ã  lire, mais moins formel que Title Case." } else { "Envisager d'adopter Title Case ou Sentence case pour une meilleure lisibilitÃ© des titres." })

3. **CohÃ©rence par niveau**: $(
    $inconsistentLevels = @($Analysis.Consistency.ConsistencyByLevel.Keys | Where-Object { $Analysis.Consistency.ConsistencyByLevel[$_].Consistency -lt 80 })
    if ($inconsistentLevels.Count -eq 0) {
        "Tous les niveaux de titre prÃ©sentent une bonne cohÃ©rence."
    } else {
        "Les niveaux de titre suivants prÃ©sentent une cohÃ©rence infÃ©rieure Ã  80% : $($inconsistentLevels -join ", "). Envisager de standardiser ces niveaux."
    }
)

4. **Standardisation**: $(
    if ($Analysis.Consistency.OverallConsistency -ge 80) {
        "Maintenir le style $($Analysis.Consistency.DominantStyle) pour tous les titres."
    } else {
        "Adopter une convention de casse unique pour chaque niveau de titre :"
        $recommendations = @()
        for ($i = 1; $i -le 6; $i++) {
            if ($Analysis.ByLevel.ContainsKey($i)) {
                $levelDominant = $Analysis.Consistency.ConsistencyByLevel[$i].DominantStyle
                $recommendations += "   - Niveau $i : $levelDominant"
            }
        }
        $recommendations -join "`n"
    }
)
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

    # Analyser les conventions de casse
    $analysis = Get-TitleCasingAnalysis -Titles $titles

    # GÃ©nÃ©rer le rapport d'analyse
    $report = New-CasingAnalysisReport -Analysis $analysis -IncludeExamples $IncludeExamples

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer le rapport avec BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    # Afficher un rÃ©sumÃ©
    Write-Host "Analyse des conventions de casse terminÃ©e."
    Write-Host "Nombre total de titres analysÃ©s : $($analysis.TotalTitles)"
    Write-Host "Style de casse dominant : $($analysis.Consistency.DominantStyle) ($($analysis.Consistency.DominantStylePercentage)%)"
    Write-Host "Rapport gÃ©nÃ©rÃ© Ã  : $OutputPath"

    # Retourner l'analyse pour une utilisation ultÃ©rieure
    return $analysis
} catch {
    Write-Error "Erreur lors de l'analyse des conventions de casse : $_"

    # Afficher la pile d'appels pour faciliter le dÃ©bogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}

# Définir l'encodage UTF-8 pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Paramètres fixes
$FilePath = "..\..\data\planning\expertise-levels.md"
$OutputPath = "..\..\data\planning\title-affixes-analysis.md"
$IncludeExamples = $true
$MinOccurrences = 2  # Nombre minimum d'occurrences pour considérer un préfixe/suffixe comme récurrent

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

    # Trier les titres par numéro de ligne
    return $titles | Sort-Object -Property LineNumber
}

# Fonction pour extraire les mots d'un titre
function Get-TitleWords {
    param(
        [string]$Title
    )

    # Nettoyer le titre et le diviser en mots
    $cleanTitle = $Title -replace '[^\p{L}\p{N}\s]', ' '  # Remplacer les caractères non alphanumériques par des espaces
    $words = $cleanTitle -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    
    return $words
}

# Fonction pour analyser les préfixes et suffixes dans les titres
function Get-TitleAffixesAnalysis {
    param(
        [array]$Titles,
        [int]$MinOccurrences = 2
    )

    $analysis = @{
        TotalTitles = $Titles.Count
        Prefixes = @{}
        Suffixes = @{}
        PrefixesByLevel = @{}
        SuffixesByLevel = @{}
        CommonPhrases = @{}
        Examples = @{}
    }

    # Extraire tous les mots des titres
    $allWords = @()
    $titleWords = @{}
    
    foreach ($title in $Titles) {
        $words = Get-TitleWords -Title $title.Title
        $titleWords[$title.Title] = $words
        $allWords += $words
    }

    # Compter les occurrences de chaque mot en position de préfixe
    foreach ($title in $Titles) {
        $words = $titleWords[$title.Title]
        $level = $title.Level
        
        if ($words.Count -gt 0) {
            $prefix = $words[0]
            
            # Compter les préfixes
            if (-not $analysis.Prefixes.ContainsKey($prefix)) {
                $analysis.Prefixes[$prefix] = @{
                    Count = 0
                    Titles = @()
                }
            }
            $analysis.Prefixes[$prefix].Count++
            $analysis.Prefixes[$prefix].Titles += $title.Title
            
            # Compter les préfixes par niveau
            if (-not $analysis.PrefixesByLevel.ContainsKey($level)) {
                $analysis.PrefixesByLevel[$level] = @{}
            }
            if (-not $analysis.PrefixesByLevel[$level].ContainsKey($prefix)) {
                $analysis.PrefixesByLevel[$level][$prefix] = 0
            }
            $analysis.PrefixesByLevel[$level][$prefix]++
        }
        
        if ($words.Count -gt 1) {
            $suffix = $words[-1]
            
            # Compter les suffixes
            if (-not $analysis.Suffixes.ContainsKey($suffix)) {
                $analysis.Suffixes[$suffix] = @{
                    Count = 0
                    Titles = @()
                }
            }
            $analysis.Suffixes[$suffix].Count++
            $analysis.Suffixes[$suffix].Titles += $title.Title
            
            # Compter les suffixes par niveau
            if (-not $analysis.SuffixesByLevel.ContainsKey($level)) {
                $analysis.SuffixesByLevel[$level] = @{}
            }
            if (-not $analysis.SuffixesByLevel[$level].ContainsKey($suffix)) {
                $analysis.SuffixesByLevel[$level][$suffix] = 0
            }
            $analysis.SuffixesByLevel[$level][$suffix]++
        }
    }

    # Détecter les phrases communes (2 mots ou plus)
    foreach ($title1 in $Titles) {
        $words1 = $titleWords[$title1.Title]
        
        if ($words1.Count -ge 2) {
            for ($i = 0; $i -lt $words1.Count - 1; $i++) {
                for ($length = 2; $length -le [Math]::Min(5, $words1.Count - $i); $length++) {
                    $phrase = $words1[$i..($i + $length - 1)] -join " "
                    
                    # Compter les occurrences de cette phrase dans tous les titres
                    $count = 0
                    $phraseTitles = @()
                    
                    foreach ($title2 in $Titles) {
                        $title2Text = $title2.Title
                        if ($title2Text -match [regex]::Escape($phrase)) {
                            $count++
                            $phraseTitles += $title2Text
                        }
                    }
                    
                    if ($count -ge $MinOccurrences) {
                        if (-not $analysis.CommonPhrases.ContainsKey($phrase)) {
                            $analysis.CommonPhrases[$phrase] = @{
                                Count = $count
                                Titles = $phraseTitles
                            }
                        }
                    }
                }
            }
        }
    }

    # Filtrer les préfixes et suffixes récurrents
    $analysis.Prefixes = $analysis.Prefixes.GetEnumerator() | 
                         Where-Object { $_.Value.Count -ge $MinOccurrences } | 
                         ForEach-Object { $_.Key, $_.Value } | 
                         Group-Object -Property { $_[0] } | 
                         ForEach-Object { 
                             $key = $_.Name
                             $value = $_.Group[1]
                             @{$key = $value}
                         } | 
                         ForEach-Object { $_ }
    
    $analysis.Suffixes = $analysis.Suffixes.GetEnumerator() | 
                         Where-Object { $_.Value.Count -ge $MinOccurrences } | 
                         ForEach-Object { $_.Key, $_.Value } | 
                         Group-Object -Property { $_[0] } | 
                         ForEach-Object { 
                             $key = $_.Name
                             $value = $_.Group[1]
                             @{$key = $value}
                         } | 
                         ForEach-Object { $_ }

    # Préparer des exemples pour chaque préfixe et suffixe récurrent
    foreach ($prefix in $analysis.Prefixes.Keys) {
        $analysis.Examples[$prefix] = $analysis.Prefixes[$prefix].Titles | Select-Object -First 3
    }
    
    foreach ($suffix in $analysis.Suffixes.Keys) {
        $analysis.Examples[$suffix] = $analysis.Suffixes[$suffix].Titles | Select-Object -First 3
    }
    
    foreach ($phrase in $analysis.CommonPhrases.Keys) {
        $analysis.Examples[$phrase] = $analysis.CommonPhrases[$phrase].Titles | Select-Object -First 3
    }

    return $analysis
}

# Fonction pour générer un rapport d'analyse des préfixes et suffixes
function New-AffixesAnalysisReport {
    param(
        [hashtable]$Analysis,
        [bool]$IncludeExamples,
        [int]$MinOccurrences
    )

    $report = @"
# Analyse des Préfixes et Suffixes Récurrents dans les Titres

## Résumé

- **Nombre total de titres analysés**: $($Analysis.TotalTitles)
- **Seuil minimum d'occurrences**: $MinOccurrences

## Préfixes Récurrents

"@

    # Ajouter les préfixes récurrents
    if ($Analysis.Prefixes.Count -eq 0) {
        $report += "`n- Aucun préfixe récurrent détecté (avec au moins $MinOccurrences occurrences)"
    } else {
        foreach ($prefix in $Analysis.Prefixes.Keys | Sort-Object) {
            $count = $Analysis.Prefixes[$prefix].Count
            $percentage = if ($Analysis.TotalTitles -gt 0) { 
                [math]::Round(($count / $Analysis.TotalTitles) * 100, 2) 
            } else { 
                0 
            }
            $report += "`n- **$prefix**: $count titres ($percentage%)"
            
            if ($IncludeExamples -and $Analysis.Examples.ContainsKey($prefix)) {
                $report += "`n  *Exemples:*"
                foreach ($example in $Analysis.Examples[$prefix]) {
                    $report += "`n  - `"$example`""
                }
            }
        }
    }

    # Ajouter les suffixes récurrents
    $report += "`n`n## Suffixes Récurrents"
    
    if ($Analysis.Suffixes.Count -eq 0) {
        $report += "`n- Aucun suffixe récurrent détecté (avec au moins $MinOccurrences occurrences)"
    } else {
        foreach ($suffix in $Analysis.Suffixes.Keys | Sort-Object) {
            $count = $Analysis.Suffixes[$suffix].Count
            $percentage = if ($Analysis.TotalTitles -gt 0) { 
                [math]::Round(($count / $Analysis.TotalTitles) * 100, 2) 
            } else { 
                0 
            }
            $report += "`n- **$suffix**: $count titres ($percentage%)"
            
            if ($IncludeExamples -and $Analysis.Examples.ContainsKey($suffix)) {
                $report += "`n  *Exemples:*"
                foreach ($example in $Analysis.Examples[$suffix]) {
                    $report += "`n  - `"$example`""
                }
            }
        }
    }

    # Ajouter les phrases communes
    $report += "`n`n## Phrases Communes"
    
    if ($Analysis.CommonPhrases.Count -eq 0) {
        $report += "`n- Aucune phrase commune détectée (avec au moins $MinOccurrences occurrences)"
    } else {
        foreach ($phrase in $Analysis.CommonPhrases.Keys | Sort-Object -Property { $Analysis.CommonPhrases[$_].Count } -Descending) {
            $count = $Analysis.CommonPhrases[$phrase].Count
            $percentage = if ($Analysis.TotalTitles -gt 0) { 
                [math]::Round(($count / $Analysis.TotalTitles) * 100, 2) 
            } else { 
                0 
            }
            $report += "`n- **`"$phrase`"**: $count titres ($percentage%)"
            
            if ($IncludeExamples -and $Analysis.Examples.ContainsKey($phrase)) {
                $report += "`n  *Exemples:*"
                foreach ($example in $Analysis.Examples[$phrase]) {
                    $report += "`n  - `"$example`""
                }
            }
        }
    }

    # Ajouter l'analyse par niveau
    $report += "`n`n## Analyse par Niveau de Titre"
    
    foreach ($level in ($Analysis.PrefixesByLevel.Keys + $Analysis.SuffixesByLevel.Keys | Sort-Object -Unique)) {
        $report += "`n`n### Niveau $level (${level} #)"
        
        # Préfixes par niveau
        $report += "`n`n#### Préfixes"
        if (-not $Analysis.PrefixesByLevel.ContainsKey($level) -or $Analysis.PrefixesByLevel[$level].Count -eq 0) {
            $report += "`n- Aucun préfixe récurrent détecté à ce niveau"
        } else {
            foreach ($prefix in $Analysis.PrefixesByLevel[$level].Keys | Sort-Object -Property { $Analysis.PrefixesByLevel[$level][$_] } -Descending) {
                $count = $Analysis.PrefixesByLevel[$level][$prefix]
                if ($count -ge $MinOccurrences) {
                    $levelTitles = ($Titles | Where-Object { $_.Level -eq $level }).Count
                    $percentage = if ($levelTitles -gt 0) { 
                        [math]::Round(($count / $levelTitles) * 100, 2) 
                    } else { 
                        0 
                    }
                    $report += "`n- **$prefix**: $count titres ($percentage%)"
                }
            }
        }
        
        # Suffixes par niveau
        $report += "`n`n#### Suffixes"
        if (-not $Analysis.SuffixesByLevel.ContainsKey($level) -or $Analysis.SuffixesByLevel[$level].Count -eq 0) {
            $report += "`n- Aucun suffixe récurrent détecté à ce niveau"
        } else {
            foreach ($suffix in $Analysis.SuffixesByLevel[$level].Keys | Sort-Object -Property { $Analysis.SuffixesByLevel[$level][$_] } -Descending) {
                $count = $Analysis.SuffixesByLevel[$level][$suffix]
                if ($count -ge $MinOccurrences) {
                    $levelTitles = ($Titles | Where-Object { $_.Level -eq $level }).Count
                    $percentage = if ($levelTitles -gt 0) { 
                        [math]::Round(($count / $levelTitles) * 100, 2) 
                    } else { 
                        0 
                    }
                    $report += "`n- **$suffix**: $count titres ($percentage%)"
                }
            }
        }
    }

    # Ajouter des recommandations
    $report += @"

## Observations et Recommandations

1. **Préfixes récurrents**: $(
    if ($Analysis.Prefixes.Count -eq 0) {
        "Aucun préfixe récurrent n'a été détecté, ce qui suggère une variété dans la formulation des titres."
    } else {
        $topPrefixes = $Analysis.Prefixes.GetEnumerator() | 
                      Sort-Object -Property { $_.Value.Count } -Descending | 
                      Select-Object -First 3 | 
                      ForEach-Object { "$($_.Key) ($($_.Value.Count) titres)" }
        "Les préfixes les plus courants sont : $($topPrefixes -join ", "). Cela indique une certaine cohérence dans la formulation des titres."
    }
)

2. **Suffixes récurrents**: $(
    if ($Analysis.Suffixes.Count -eq 0) {
        "Aucun suffixe récurrent n'a été détecté, ce qui suggère une variété dans la formulation des titres."
    } else {
        $topSuffixes = $Analysis.Suffixes.GetEnumerator() | 
                      Sort-Object -Property { $_.Value.Count } -Descending | 
                      Select-Object -First 3 | 
                      ForEach-Object { "$($_.Key) ($($_.Value.Count) titres)" }
        "Les suffixes les plus courants sont : $($topSuffixes -join ", "). Cela peut indiquer des catégories ou des types de contenu récurrents."
    }
)

3. **Phrases communes**: $(
    if ($Analysis.CommonPhrases.Count -eq 0) {
        "Aucune phrase commune n'a été détectée, ce qui suggère une variété dans la formulation des titres."
    } else {
        $topPhrases = $Analysis.CommonPhrases.GetEnumerator() | 
                     Sort-Object -Property { $_.Value.Count } -Descending | 
                     Select-Object -First 3 | 
                     ForEach-Object { "`"$($_.Key)`" ($($_.Value.Count) titres)" }
        "Les phrases les plus communes sont : $($topPhrases -join ", "). Ces motifs peuvent être utilisés pour standardiser la formulation des titres."
    }
)

4. **Cohérence par niveau**: $(
    $inconsistentLevels = @()
    foreach ($level in ($Analysis.PrefixesByLevel.Keys + $Analysis.SuffixesByLevel.Keys | Sort-Object -Unique)) {
        $prefixCount = if ($Analysis.PrefixesByLevel.ContainsKey($level)) { 
            ($Analysis.PrefixesByLevel[$level].GetEnumerator() | Where-Object { $_.Value -ge $MinOccurrences }).Count 
        } else { 
            0 
        }
        $suffixCount = if ($Analysis.SuffixesByLevel.ContainsKey($level)) { 
            ($Analysis.SuffixesByLevel[$level].GetEnumerator() | Where-Object { $_.Value -ge $MinOccurrences }).Count 
        } else { 
            0 
        }
        
        $levelTitles = ($Titles | Where-Object { $_.Level -eq $level }).Count
        if ($levelTitles -gt 1 -and ($prefixCount -eq 0 -or $suffixCount -eq 0)) {
            $inconsistentLevels += $level
        }
    }
    
    if ($inconsistentLevels.Count -eq 0) {
        "Tous les niveaux de titre présentent une certaine cohérence dans l'utilisation des préfixes et suffixes."
    } else {
        "Les niveaux de titre suivants manquent de cohérence dans l'utilisation des préfixes ou suffixes : $($inconsistentLevels -join ", "). Envisager de standardiser la formulation des titres à ces niveaux."
    }
)

5. **Recommandations générales**:
   - Standardiser l'utilisation des préfixes pour les titres de même niveau ou de même catégorie.
   - Utiliser des suffixes cohérents pour indiquer le type de contenu (ex: "Techniques", "Professionnelle", etc.).
   - Maintenir la cohérence des phrases communes pour faciliter la navigation et la compréhension.
   - Éviter les variations mineures dans la formulation des titres similaires.
   - Considérer l'adoption d'un modèle de nommage pour chaque niveau de titre.
"@

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
    $Titles = Get-MarkdownTitles -Content $content

    # Analyser les préfixes et suffixes dans les titres
    $analysis = Get-TitleAffixesAnalysis -Titles $Titles -MinOccurrences $MinOccurrences

    # Générer le rapport d'analyse
    $report = New-AffixesAnalysisReport -Analysis $analysis -IncludeExamples $IncludeExamples -MinOccurrences $MinOccurrences

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer le rapport avec BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    # Afficher un résumé
    Write-Host "Analyse des préfixes et suffixes terminée."
    Write-Host "Nombre total de titres analysés : $($analysis.TotalTitles)"
    Write-Host "Préfixes récurrents détectés : $($analysis.Prefixes.Count)"
    Write-Host "Suffixes récurrents détectés : $($analysis.Suffixes.Count)"
    Write-Host "Phrases communes détectées : $($analysis.CommonPhrases.Count)"
    Write-Host "Rapport généré à : $OutputPath"

    # Retourner l'analyse pour une utilisation ultérieure
    return $analysis
} catch {
    Write-Error "Erreur lors de l'analyse des préfixes et suffixes : $_"

    # Afficher la pile d'appels pour faciliter le débogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}

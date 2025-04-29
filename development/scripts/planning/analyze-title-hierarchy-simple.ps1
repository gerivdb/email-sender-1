# Définir l'encodage UTF-8 pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Paramètres
$FilePath = "..\..\data\planning\expertise-levels.md"
$OutputPath = "..\..\data\planning\title-hierarchy-analysis.md"
$IncludeFormatAnalysis = $true

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
    $FilePath = Join-Path -Path $PWD -ChildPath $FilePath
}

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path -Path $PWD -ChildPath $OutputPath
}

# Fonction pour extraire les sections d'un document markdown
function Get-DocumentSections {
    param(
        [string]$Content
    )

    # Structure pour stocker les sections
    $sections = @()

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Variables pour suivre la section actuelle
    $currentSection = $null
    $currentLevel = 0
    $currentContent = @()
    $currentLineNumber = 0

    # Parcourir chaque ligne
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Vérifier si la ligne est un titre avec la syntaxe #
        if ($line -match '^(#{1,6})\s+(.+)$') {
            # Si nous avons déjà une section en cours, l'ajouter à la liste
            if ($currentSection) {
                $sections += [PSCustomObject]@{
                    Title      = $currentSection
                    Level      = $currentLevel
                    Content    = $currentContent -join "`n"
                    LineNumber = $currentLineNumber
                    Type       = "Hash"
                }
            }

            # Extraire le niveau et le titre
            $level = $matches[1].Length
            $title = $matches[2]

            # Mettre à jour la section actuelle
            $currentSection = $title
            $currentLevel = $level
            $currentContent = @()
            $currentLineNumber = $i + 1
        }
        # Vérifier si la ligne est un titre avec la syntaxe de soulignement (= ou -)
        elseif (($i -lt ($lines.Count - 1)) -and ($line -match '^.+$') -and ($lines[$i + 1] -match '^(=+|-+)$')) {
            # Si nous avons déjà une section en cours, l'ajouter à la liste
            if ($currentSection) {
                $sections += [PSCustomObject]@{
                    Title      = $currentSection
                    Level      = $currentLevel
                    Content    = $currentContent -join "`n"
                    LineNumber = $currentLineNumber
                    Type       = "Hash"
                }
            }

            # Déterminer le niveau en fonction du caractère de soulignement
            $level = if ($lines[$i + 1] -match '^=+$') { 1 } else { 2 }
            $title = $line

            # Mettre à jour la section actuelle
            $currentSection = $title
            $currentLevel = $level
            $currentContent = @()
            $currentLineNumber = $i + 1
            
            # Sauter la ligne de soulignement
            $i++
        }
        else {
            # Ajouter la ligne au contenu de la section actuelle
            if ($currentSection) {
                $currentContent += $line
            }
        }
    }

    # Ajouter la dernière section
    if ($currentSection) {
        $sections += [PSCustomObject]@{
            Title      = $currentSection
            Level      = $currentLevel
            Content    = $currentContent -join "`n"
            LineNumber = $currentLineNumber
            Type       = "Hash"
        }
    }

    return $sections
}

# Fonction pour analyser la hiérarchie des titres et sous-titres
function Get-TitleHierarchy {
    param(
        [array]$Sections
    )

    # Structure pour stocker la hiérarchie
    $hierarchy = @{
        Levels                  = @{}
        ParentChildRelations    = @{}
        DepthDistribution       = @{}
        AverageChildrenPerLevel = @{}
        MaxDepth                = 0
        TitleFormats            = @{
            HashHeaders      = @{}  # Headers with # syntax
            UnderlineHeaders = @{} # Headers with underline syntax
        }
    }

    # Analyser les niveaux de titres
    foreach ($section in $Sections) {
        $level = $section.Level

        # Compter les sections par niveau
        if (-not $hierarchy.Levels.ContainsKey($level)) {
            $hierarchy.Levels[$level] = @()
        }
        $hierarchy.Levels[$level] += $section

        # Mettre à jour la profondeur maximale
        if ($level -gt $hierarchy.MaxDepth) {
            $hierarchy.MaxDepth = $level
        }
    }

    # Analyser les relations parent-enfant
    for ($i = 0; $i -lt $Sections.Count; $i++) {
        $currentSection = $Sections[$i]
        $currentLevel = $currentSection.Level

        # Trouver le parent (section précédente avec un niveau inférieur)
        $parentIndex = $i - 1
        while ($parentIndex -ge 0) {
            $potentialParent = $Sections[$parentIndex]
            if ($potentialParent.Level -lt $currentLevel) {
                # Ajouter la relation parent-enfant
                $parentId = "$($potentialParent.Level):$($potentialParent.Title)"
                $childId = "$($currentSection.Level):$($currentSection.Title)"

                if (-not $hierarchy.ParentChildRelations.ContainsKey($parentId)) {
                    $hierarchy.ParentChildRelations[$parentId] = @()
                }
                $hierarchy.ParentChildRelations[$parentId] += $childId

                break
            }
            $parentIndex--
        }
    }

    # Calculer la distribution de profondeur
    foreach ($section in $Sections) {
        $depth = 1
        $currentSection = $section
        $currentLevel = $currentSection.Level

        # Trouver la profondeur en remontant vers les parents
        for ($i = [array]::IndexOf($Sections, $currentSection) - 1; $i -ge 0; $i--) {
            $potentialParent = $Sections[$i]
            if ($potentialParent.Level -lt $currentLevel) {
                $depth++
                $currentLevel = $potentialParent.Level
                if ($currentLevel -eq 1) {
                    break
                }
            }
        }

        # Mettre à jour la distribution de profondeur
        if (-not $hierarchy.DepthDistribution.ContainsKey($depth)) {
            $hierarchy.DepthDistribution[$depth] = 0
        }
        $hierarchy.DepthDistribution[$depth]++
    }

    # Calculer le nombre moyen d'enfants par niveau
    foreach ($level in $hierarchy.Levels.Keys) {
        $childCount = 0
        $parentCount = 0

        foreach ($parentId in $hierarchy.ParentChildRelations.Keys) {
            $parentLevel = [int]($parentId -split ':')[0]
            if ($parentLevel -eq $level) {
                $childCount += $hierarchy.ParentChildRelations[$parentId].Count
                $parentCount++
            }
        }

        if ($parentCount -gt 0) {
            $hierarchy.AverageChildrenPerLevel[$level] = $childCount / $parentCount
        } else {
            $hierarchy.AverageChildrenPerLevel[$level] = 0
        }
    }

    return $hierarchy
}

# Fonction pour analyser les formats de titres utilisés dans le document
function Get-TitleFormats {
    param(
        [string]$Content
    )

    $formats = @{
        HashHeaders      = @{}  # Headers with # syntax
        UnderlineHeaders = @{} # Headers with underline syntax
        Conventions      = @{} # Naming conventions
    }

    # Rechercher les titres avec la syntaxe #
    for ($i = 1; $i -le 6; $i++) {
        $hashPattern = "(?m)^#{$i}\s+.+$"
        $regexMatches = [regex]::Matches($Content, $hashPattern)
        if ($null -ne $regexMatches -and $regexMatches.Count -gt 0) {
            $formats.HashHeaders[$i] = $regexMatches.Count
        }
    }

    # Rechercher les titres avec la syntaxe de soulignement
    $underlinePatterns = @{
        1 = "(?m)^[^\n]+\n=+$"  # Titre niveau 1 avec =
        2 = "(?m)^[^\n]+\n-+$"  # Titre niveau 2 avec -
    }

    foreach ($level in $underlinePatterns.Keys) {
        $pattern = $underlinePatterns[$level]
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($null -ne $regexMatches -and $regexMatches.Count -gt 0) {
            $formats.UnderlineHeaders[$level] = $regexMatches.Count
        }
    }

    # Analyser les conventions de nommage des titres
    $titlePatterns = @{
        "CamelCase"        = "(?m)^#+\s+[A-Z][a-z]+([A-Z][a-z]+)+$"
        "TitleCase"        = "(?m)^#+\s+([A-Z][a-z]+\s+)+[A-Z][a-z]+$"
        "SentenceCase"     = "(?m)^#+\s+[A-Z][a-z\s]+$"
        "NumberedPrefix"   = "(?m)^#+\s+\d+\.\s+.+$"
        "QuestionFormat"   = "(?m)^#+\s+.+\?$"
        "ColonSeparated"   = "(?m)^#+\s+.+:.+$"
    }

    foreach ($convention in $titlePatterns.Keys) {
        $pattern = $titlePatterns[$convention]
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($null -ne $regexMatches -and $regexMatches.Count -gt 0) {
            $formats.Conventions[$convention] = $regexMatches.Count
        }
    }

    return $formats
}

# Fonction pour générer un rapport d'analyse de la hiérarchie
function New-HierarchyAnalysisReport {
    param(
        [hashtable]$Hierarchy,
        [hashtable]$TitleFormats,
        [bool]$IncludeFormatAnalysis = $true
    )

    $report = @"
# Analyse de la Hiérarchie des Titres et Sous-titres

## Structure Hiérarchique

### Distribution par Niveau
"@

    # Ajouter la distribution par niveau
    foreach ($level in $Hierarchy.Levels.Keys | Sort-Object) {
        $sections = $Hierarchy.Levels[$level]
        $report += "`n- **Niveau $level**: $($sections.Count) sections"
    }

    $report += @"

### Profondeur Maximale
La profondeur maximale de la hiérarchie est de **$($Hierarchy.MaxDepth) niveaux**.

### Distribution de Profondeur
"@

    # Ajouter la distribution de profondeur
    foreach ($depth in $Hierarchy.DepthDistribution.Keys | Sort-Object) {
        $count = $Hierarchy.DepthDistribution[$depth]
        $report += "`n- **Profondeur $depth**: $count sections"
    }

    $report += @"

### Nombre Moyen d'Enfants par Niveau
"@

    # Ajouter le nombre moyen d'enfants par niveau
    foreach ($level in $Hierarchy.AverageChildrenPerLevel.Keys | Sort-Object) {
        $average = $Hierarchy.AverageChildrenPerLevel[$level]
        $report += "`n- **Niveau $level**: $([math]::Round($average, 2)) enfants en moyenne"
    }

    if ($IncludeFormatAnalysis) {
        $report += @"

## Analyse des Formats de Titres

### Syntaxe des Titres
"@

        # Ajouter les informations sur les titres avec #
        $report += "`n#### Titres avec Syntaxe #"
        if ($TitleFormats.HashHeaders.Count -eq 0) {
            $report += "`n- Aucun titre avec syntaxe # détecté"
        } else {
            foreach ($level in $TitleFormats.HashHeaders.Keys | Sort-Object) {
                $count = $TitleFormats.HashHeaders[$level]
                $report += "`n- **Niveau $level** (#{'#' * $level}): $count titres"
            }
        }

        # Ajouter les informations sur les titres avec soulignement
        $report += "`n`n#### Titres avec Syntaxe de Soulignement"
        if ($TitleFormats.UnderlineHeaders.Count -eq 0) {
            $report += "`n- Aucun titre avec syntaxe de soulignement détecté"
        } else {
            foreach ($level in $TitleFormats.UnderlineHeaders.Keys | Sort-Object) {
                $count = $TitleFormats.UnderlineHeaders[$level]
                $symbol = if ($level -eq 1) { "=" } else { "-" }
                $report += "`n- **Niveau $level** (souligné avec $symbol): $count titres"
            }
        }

        # Ajouter les informations sur les conventions de nommage
        $report += "`n`n### Conventions de Nommage des Titres"
        if ($TitleFormats.Conventions.Count -eq 0) {
            $report += "`n- Aucune convention de nommage spécifique détectée"
        } else {
            foreach ($convention in $TitleFormats.Conventions.Keys | Sort-Object) {
                $count = $TitleFormats.Conventions[$convention]
                $report += "`n- **$convention**: $count titres"
            }
        }
    }

    $report += @"

## Relations Parent-Enfant

### Sections de Niveau 1 et leurs Enfants Directs
"@

    # Ajouter les relations parent-enfant pour les sections de niveau 1
    $level1Parents = $Hierarchy.ParentChildRelations.Keys | Where-Object { [int]($_ -split ':')[0] -eq 1 } | Sort-Object
    
    if ($level1Parents.Count -eq 0) {
        $report += "`n- Aucune section de niveau 1 avec des enfants directs"
    } else {
        foreach ($parentId in $level1Parents) {
            $parentTitle = ($parentId -split ':', 2)[1]
            $report += "`n- **$parentTitle**"

            foreach ($childId in $Hierarchy.ParentChildRelations[$parentId]) {
                $childTitle = ($childId -split ':', 2)[1]
                $report += "`n  - $childTitle"
            }
        }
    }

    $report += @"

### Sections de Niveau 2 et leurs Enfants Directs
"@

    # Ajouter les relations parent-enfant pour les sections de niveau 2
    $level2Parents = $Hierarchy.ParentChildRelations.Keys | Where-Object { [int]($_ -split ':')[0] -eq 2 } | Sort-Object
    
    if ($level2Parents.Count -eq 0) {
        $report += "`n- Aucune section de niveau 2 avec des enfants directs"
    } else {
        foreach ($parentId in $level2Parents) {
            $parentTitle = ($parentId -split ':', 2)[1]
            $report += "`n- **$parentTitle**"

            foreach ($childId in $Hierarchy.ParentChildRelations[$parentId]) {
                $childTitle = ($childId -split ':', 2)[1]
                $report += "`n  - $childTitle"
            }
        }
    }

    $report += @"

## Observations et Recommandations

1. La structure du document présente **$($Hierarchy.MaxDepth) niveaux de profondeur**, ce qui est $(if ($Hierarchy.MaxDepth -le 4) { "approprié" } else { "potentiellement trop profond" }) pour un document technique.

2. Les sections de niveau 1 ont en moyenne **$([math]::Round($Hierarchy.AverageChildrenPerLevel[1], 2)) enfants directs**, ce qui indique une $(if ($Hierarchy.AverageChildrenPerLevel[1] -le 7) { "bonne" } else { "potentiellement excessive" }) organisation des informations principales.

3. Les sections de niveau 2 ont en moyenne **$([math]::Round($Hierarchy.AverageChildrenPerLevel[2], 2)) enfants directs**, ce qui montre une décomposition $(if ($Hierarchy.AverageChildrenPerLevel[2] -le 5) { "détaillée" } else { "potentiellement trop détaillée" }) des sujets.

4. La distribution des sections par niveau montre que le document est $(if ($Hierarchy.Levels.Count -le 4) { "bien structuré" } else { "potentiellement trop complexe" }), avec une hiérarchie $(if ($Hierarchy.Levels.Count -le 4) { "claire" } else { "qui pourrait être simplifiée" }).

5. Pour l'extraction des critères d'évaluation, il est recommandé de se concentrer sur les sections de niveau 2 et 3, qui contiennent généralement les informations détaillées sur les critères.

6. $(if ($TitleFormats.HashHeaders.Count -gt 0 -and $TitleFormats.UnderlineHeaders.Count -gt 0) { "Le document utilise un mélange de syntaxes de titres (# et soulignement), ce qui pourrait être standardisé pour plus de cohérence." } else { "Le document utilise une syntaxe de titres cohérente, ce qui facilite l'analyse automatique." })

7. $(if ($TitleFormats.Conventions.Count -gt 2) { "Plusieurs conventions de nommage différentes sont utilisées pour les titres, ce qui pourrait être standardisé." } else { "Les conventions de nommage des titres sont relativement cohérentes." })
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

    # Extraire les sections
    $sections = Get-DocumentSections -Content $content

    # Analyser la hiérarchie des titres
    $hierarchy = Get-TitleHierarchy -Sections $sections

    # Analyser les formats de titres si demandé
    $titleFormats = $null
    if ($IncludeFormatAnalysis) {
        $titleFormats = Get-TitleFormats -Content $content
    }

    # Générer le rapport d'analyse
    $report = New-HierarchyAnalysisReport -Hierarchy $hierarchy -TitleFormats $titleFormats -IncludeFormatAnalysis $IncludeFormatAnalysis

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer le rapport avec BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    # Afficher un résumé
    Write-Host "Analyse de la hiérarchie des titres terminée."
    Write-Host "Nombre total de sections identifiées : $($sections.Count)"
    Write-Host "Profondeur maximale de la hiérarchie : $($hierarchy.MaxDepth) niveaux"
    Write-Host "Rapport généré à : $OutputPath"

    # Retourner la hiérarchie pour une utilisation ultérieure
    return @{
        Sections = $sections
        Hierarchy = $hierarchy
        TitleFormats = $titleFormats
    }
} catch {
    Write-Error "Erreur lors de l'analyse de la hiérarchie des titres : $_"

    # Afficher la pile d'appels pour faciliter le débogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}

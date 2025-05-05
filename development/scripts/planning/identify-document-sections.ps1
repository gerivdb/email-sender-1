# DÃ©finir l'encodage UTF-8 pour les caractÃ¨res accentuÃ©s
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

<#
.SYNOPSIS
    Identifie les sections principales d'un document markdown de niveaux d'expertise.

.DESCRIPTION
    Ce script analyse un document markdown contenant la dÃ©finition des niveaux d'expertise
    et identifie les sections principales du document en se basant sur les titres.
    Il extrait la structure hiÃ©rarchique des titres et sous-titres pour faciliter
    l'extraction ultÃ©rieure des critÃ¨res d'Ã©valuation.

.PARAMETER FilePath
    Chemin vers le fichier markdown contenant la dÃ©finition des niveaux d'expertise.
    Par dÃ©faut : "..\..\..\data\planning\expertise-levels.md"

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport des sections identifiÃ©es.
    Par dÃ©faut : "..\..\..\data\planning\document-sections.md"

.PARAMETER IncludeContent
    Indique si le contenu des sections doit Ãªtre inclus dans le rapport.
    Par dÃ©faut : $false

.EXAMPLE
    .\identify-document-sections.ps1
    Identifie les sections principales du document par dÃ©faut.

.EXAMPLE
    .\identify-document-sections.ps1 -FilePath "path\to\expertise-levels.md" -OutputPath "path\to\output.md" -IncludeContent $true
    Identifie les sections principales du document spÃ©cifiÃ© et inclut le contenu des sections dans le rapport.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de crÃ©ation: 2023-05-15
#>

# ParamÃ¨tres
$FilePath = ".\development\data\planning\expertise-levels.md"
$OutputPath = ".\development\data\planning\document-sections.md"
$HierarchyOutputPath = ".\development\data\planning\title-hierarchy-analysis.md"
$IncludeContent = $false

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

    # Parcourir chaque ligne
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # VÃ©rifier si la ligne est un titre
        if ($line -match '^(#{1,6})\s+(.+)$') {
            # Si nous avons dÃ©jÃ  une section en cours, l'ajouter Ã  la liste
            if ($currentSection) {
                $sections += [PSCustomObject]@{
                    Title      = $currentSection
                    Level      = $currentLevel
                    Content    = $currentContent -join "`n"
                    LineNumber = $currentLineNumber
                }
            }

            # Extraire le niveau et le titre
            $level = $matches[1].Length
            $title = $matches[2]

            # Mettre Ã  jour la section actuelle
            $currentSection = $title
            $currentLevel = $level
            $currentContent = @()
            $currentLineNumber = $i + 1
        } else {
            # Ajouter la ligne au contenu de la section actuelle
            if ($currentSection) {
                $currentContent += $line
            }
        }
    }

    # Ajouter la derniÃ¨re section
    if ($currentSection) {
        $sections += [PSCustomObject]@{
            Title      = $currentSection
            Level      = $currentLevel
            Content    = $currentContent -join "`n"
            LineNumber = $currentLineNumber
        }
    }

    return $sections
}

# Fonction pour analyser la hiÃ©rarchie des titres et sous-titres
function Get-TitleHierarchy {
    param(
        [array]$Sections
    )

    # Structure pour stocker la hiÃ©rarchie
    $hierarchy = @{
        Levels                  = @{}
        ParentChildRelations    = @{}
        DepthDistribution       = @{}
        AverageChildrenPerLevel = @{}
        MaxDepth                = 0
    }

    # Analyser les niveaux de titres
    foreach ($section in $Sections) {
        $level = $section.Level

        # Compter les sections par niveau
        if (-not $hierarchy.Levels.ContainsKey($level)) {
            $hierarchy.Levels[$level] = @()
        }
        $hierarchy.Levels[$level] += $section

        # Mettre Ã  jour la profondeur maximale
        if ($level -gt $hierarchy.MaxDepth) {
            $hierarchy.MaxDepth = $level
        }
    }

    # Analyser les relations parent-enfant
    for ($i = 0; $i -lt $Sections.Count; $i++) {
        $currentSection = $Sections[$i]
        $currentLevel = $currentSection.Level

        # Trouver le parent (section prÃ©cÃ©dente avec un niveau infÃ©rieur)
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

        # Mettre Ã  jour la distribution de profondeur
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

# Fonction pour gÃ©nÃ©rer un rapport d'analyse de la hiÃ©rarchie
function New-HierarchyAnalysisReport {
    param(
        [hashtable]$Hierarchy
    )

    $report = @"
# Analyse de la HiÃ©rarchie des Titres et Sous-titres

## Structure HiÃ©rarchique

### Distribution par Niveau
"@

    # Ajouter la distribution par niveau
    foreach ($level in $Hierarchy.Levels.Keys | Sort-Object) {
        $sections = $Hierarchy.Levels[$level]
        $report += "`n- **Niveau $level**: $($sections.Count) sections"
    }

    $report += @"

### Profondeur Maximale
La profondeur maximale de la hiÃ©rarchie est de **$($Hierarchy.MaxDepth) niveaux**.

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

    $report += @"

## Relations Parent-Enfant

### Sections de Niveau 1 et leurs Enfants Directs
"@

    # Ajouter les relations parent-enfant pour les sections de niveau 1
    foreach ($parentId in $Hierarchy.ParentChildRelations.Keys | Sort-Object) {
        $parentLevel = [int]($parentId -split ':')[0]
        $parentTitle = ($parentId -split ':', 2)[1]

        if ($parentLevel -eq 1) {
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
    foreach ($parentId in $Hierarchy.ParentChildRelations.Keys | Sort-Object) {
        $parentLevel = [int]($parentId -split ':')[0]
        $parentTitle = ($parentId -split ':', 2)[1]

        if ($parentLevel -eq 2) {
            $report += "`n- **$parentTitle**"

            foreach ($childId in $Hierarchy.ParentChildRelations[$parentId]) {
                $childTitle = ($childId -split ':', 2)[1]
                $report += "`n  - $childTitle"
            }
        }
    }

    $report += @"

## Observations et Recommandations

1. La structure du document prÃ©sente **$($Hierarchy.MaxDepth) niveaux de profondeur**, ce qui est appropriÃ© pour un document technique.

2. Les sections de niveau 1 ont en moyenne **$([math]::Round($Hierarchy.AverageChildrenPerLevel[1], 2)) enfants directs**, ce qui indique une bonne organisation des informations principales.

3. Les sections de niveau 2 ont en moyenne **$([math]::Round($Hierarchy.AverageChildrenPerLevel[2], 2)) enfants directs**, ce qui montre une dÃ©composition dÃ©taillÃ©e des sujets.

4. La distribution des sections par niveau montre que le document est bien structurÃ©, avec une hiÃ©rarchie claire.

5. Pour l'extraction des critÃ¨res d'Ã©valuation, il est recommandÃ© de se concentrer sur les sections de niveau 2 et 3, qui contiennent les informations dÃ©taillÃ©es sur les critÃ¨res.
"@

    return $report
}

# Fonction pour gÃ©nÃ©rer un rapport des sections
function New-SectionsReport {
    param(
        [array]$Sections,
        [bool]$IncludeContent
    )

    $report = @"
# Rapport des Sections du Document

## Structure HiÃ©rarchique

"@

    # GÃ©nÃ©rer la structure hiÃ©rarchique
    foreach ($section in $Sections) {
        $indent = "  " * ($section.Level - 1)
        $report += "$indent- **$($section.Title)** (Niveau $($section.Level), Ligne $($section.LineNumber))`n"
    }

    # Ajouter les dÃ©tails des sections si demandÃ©
    if ($IncludeContent) {
        $report += @"

## DÃ©tails des Sections

"@

        foreach ($section in $Sections) {
            $report += @"

### $($section.Title)

**Niveau:** $($section.Level)
**Ligne:** $($section.LineNumber)

**Contenu:**
```
$($section.Content)
```

"@
        }
    }

    # Ajouter une analyse des sections
    $report += @"

## Analyse des Sections

### Distribution par Niveau
"@

    $levelDistribution = $Sections | Group-Object -Property Level | Sort-Object -Property Name

    foreach ($level in $levelDistribution) {
        $report += "- Niveau $($level.Name): $($level.Count) sections`n"
    }

    $report += @"

### Sections Principales
"@

    $mainSections = $Sections | Where-Object { $_.Level -eq 1 -or $_.Level -eq 2 }

    foreach ($section in $mainSections) {
        $report += "- **$($section.Title)** (Niveau $($section.Level), Ligne $($section.LineNumber))`n"
    }

    $report += @"

### Sections Potentiellement Importantes pour l'Ã‰valuation
"@

    $evaluationSections = $Sections | Where-Object {
        $_.Title -match "CritÃ¨res|Ã‰valuation|Matrice|Niveaux d'Expertise|Expertise"
    }

    foreach ($section in $evaluationSections) {
        $report += "- **$($section.Title)** (Niveau $($section.Level), Ligne $($section.LineNumber))`n"
    }

    return $report
}

# ExÃ©cution principale
try {
    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier des niveaux d'expertise n'existe pas : $FilePath"
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

    # Extraire les sections
    $sections = Get-DocumentSections -Content $content

    # GÃ©nÃ©rer le rapport
    $report = New-SectionsReport -Sections $sections -IncludeContent $IncludeContent

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer le rapport avec BOM pour assurer l'encodage UTF-8 correct
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $report, $utf8WithBom)

    # Afficher un rÃ©sumÃ©
    Write-Host "Analyse du document terminÃ©e."
    Write-Host "Nombre total de sections identifiÃ©es : $($sections.Count)"
    Write-Host "Rapport gÃ©nÃ©rÃ© Ã  : $OutputPath"

    # Retourner les sections pour une utilisation ultÃ©rieure
    return $sections
} catch {
    Write-Error "Erreur lors de l'identification des sections du document : $_"

    # Afficher la pile d'appels pour faciliter le dÃ©bogage
    Write-Host "Pile d'appels :"
    Write-Host $_.ScriptStackTrace

    # Retourner un code d'erreur
    exit 1
}

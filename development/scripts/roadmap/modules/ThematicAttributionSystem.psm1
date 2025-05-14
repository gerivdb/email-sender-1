#Requires -Version 5.1
<#
.SYNOPSIS
    Système d'attribution thématique automatique pour les roadmaps.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser le contenu des roadmaps
    et attribuer automatiquement des thèmes en fonction du contenu.
.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
#>

# Importer les modules requis
using namespace System.Collections.Generic
using namespace System.Text.RegularExpressions

# Variables globales
$script:ThematicCategories = @()
$script:ThematicKeywords = @{}
$script:ThematicPrefixes = @{}
$script:StopWords = @()
$script:MinimumConfidenceScore = 0.3
$script:DefaultMaxThemes = 3

function Initialize-ThematicSystem {
    <#
    .SYNOPSIS
        Initialise le système d'attribution thématique.
    .DESCRIPTION
        Configure le système avec les catégories thématiques, les mots-clés et les préfixes.
    .PARAMETER Categories
        Tableau de catégories thématiques avec leurs mots-clés et préfixes.
    .PARAMETER StopWordsPath
        Chemin vers un fichier de mots vides (stop words).
    .PARAMETER MinimumConfidenceScore
        Score de confiance minimum pour l'attribution thématique (0.0 à 1.0).
    .PARAMETER DefaultMaxThemes
        Nombre maximum de thèmes à attribuer par défaut.
    .EXAMPLE
        $categories = @(
            @{
                Name = "Frontend"
                Keywords = @("interface", "UI", "design", "responsive", "CSS", "HTML")
                Prefix = "FE"
            },
            @{
                Name = "Backend"
                Keywords = @("serveur", "API", "base de données", "SQL", "NoSQL")
                Prefix = "BE"
            }
        )
        Initialize-ThematicSystem -Categories $categories
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Array]$Categories,

        [Parameter(Mandatory = $false)]
        [string]$StopWordsPath = "$PSScriptRoot\data\stopwords.txt",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$MinimumConfidenceScore = 0.3,

        [Parameter(Mandatory = $false)]
        [int]$DefaultMaxThemes = 3
    )

    # Réinitialiser les variables globales
    $script:ThematicCategories = @()
    $script:ThematicKeywords = @{}
    $script:ThematicPrefixes = @{}

    # Configurer les catégories
    foreach ($category in $Categories) {
        if (-not $category.Name -or -not $category.Keywords -or -not $category.Prefix) {
            Write-Warning "Catégorie invalide: $($category | ConvertTo-Json -Compress)"
            continue
        }

        $script:ThematicCategories += $category.Name
        $script:ThematicKeywords[$category.Name] = $category.Keywords
        $script:ThematicPrefixes[$category.Name] = $category.Prefix
    }

    # Charger les mots vides si le fichier existe
    if (Test-Path -Path $StopWordsPath) {
        $script:StopWords = Get-Content -Path $StopWordsPath -ErrorAction SilentlyContinue
    } else {
        # Liste de mots vides par défaut (français)
        $script:StopWords = @("le", "la", "les", "un", "une", "des", "et", "ou", "de", "du", "au", "aux", "ce", "cette", "ces", "mon", "ma", "mes", "ton", "ta", "tes", "son", "sa", "ses", "notre", "nos", "votre", "vos", "leur", "leurs", "je", "tu", "il", "elle", "nous", "vous", "ils", "elles", "qui", "que", "quoi", "dont", "où", "pour", "par", "avec", "sans", "en", "dans", "sur", "sous", "entre", "vers", "chez", "avant", "après", "pendant", "depuis", "jusqu'à", "jusque", "durant", "selon", "suivant", "d'après", "car", "donc", "mais", "or", "ni", "si", "quand", "lorsque", "puisque", "parce", "comme", "ainsi", "alors", "cependant", "néanmoins", "toutefois", "pourtant", "malgré", "bien", "mal", "peu", "très", "trop", "assez", "plus", "moins", "autant", "aussi", "même", "tout", "tous", "toute", "toutes", "aucun", "aucune", "chaque", "plusieurs", "certain", "certaine", "certains", "certaines", "quelque", "quelques", "autre", "autres", "tel", "telle", "tels", "telles")
    }

    # Configurer les paramètres
    $script:MinimumConfidenceScore = $MinimumConfidenceScore
    $script:DefaultMaxThemes = $DefaultMaxThemes

    Write-Verbose "Système d'attribution thématique initialisé avec $(($script:ThematicCategories).Count) catégories"
}

function Get-ContentThemes {
    <#
    .SYNOPSIS
        Analyse le contenu pour extraire les thèmes.
    .DESCRIPTION
        Analyse le texte fourni pour identifier les thèmes les plus pertinents.
    .PARAMETER Content
        Contenu textuel à analyser.
    .PARAMETER Title
        Titre associé au contenu (facultatif, mais recommandé pour une meilleure précision).
    .PARAMETER MaxThemes
        Nombre maximum de thèmes à retourner.
    .EXAMPLE
        Get-ContentThemes -Content "Développer l'interface utilisateur responsive avec HTML et CSS" -Title "UI Frontend"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [int]$MaxThemes = $script:DefaultMaxThemes
    )

    # Vérifier que le système est initialisé
    if ($script:ThematicCategories.Count -eq 0) {
        throw "Le système d'attribution thématique n'est pas initialisé. Utilisez Initialize-ThematicSystem d'abord."
    }

    # Combiner le titre et le contenu, avec plus de poids pour le titre
    $textToAnalyze = "$Title $Title $Content"

    # Prétraiter le texte
    $processedText = $textToAnalyze.ToLower()

    # Supprimer la ponctuation
    $processedText = [Regex]::Replace($processedText, '[^\w\s]', ' ')

    # Diviser en mots
    $words = $processedText -split '\s+' | Where-Object { $_ -and $_ -notin $script:StopWords }

    # Calculer les scores pour chaque catégorie
    $scores = @{}
    foreach ($category in $script:ThematicCategories) {
        $keywords = $script:ThematicKeywords[$category]
        $score = 0
        $matchCount = 0

        foreach ($keyword in $keywords) {
            $keywordLower = $keyword.ToLower()

            # Vérifier les correspondances exactes (plus de poids)
            $exactMatches = $words | Where-Object { $_ -eq $keywordLower }
            $score += $exactMatches.Count * 2
            $matchCount += $exactMatches.Count

            # Vérifier les correspondances partielles
            $partialMatches = $words | Where-Object { $_ -ne $keywordLower -and $_ -like "*$keywordLower*" }
            $score += $partialMatches.Count
            $matchCount += $partialMatches.Count

            # Vérifier dans le titre (plus de poids)
            if ($Title -and $Title.ToLower() -like "*$keywordLower*") {
                $score += 3
                $matchCount += 1
            }
        }

        # Normaliser le score en fonction du nombre de mots-clés et de la longueur du texte
        if ($keywords.Count -gt 0 -and $words.Count -gt 0) {
            # Formule améliorée: (score / nombre de mots-clés) * (correspondances / nombre de mots)
            $keywordFactor = $score / $keywords.Count
            $textFactor = $matchCount / $words.Count
            $normalizedScore = $keywordFactor * (0.5 + $textFactor)
            $scores[$category] = $normalizedScore
        } else {
            $scores[$category] = 0
        }
    }

    # Filtrer les scores en dessous du seuil de confiance
    $filteredScores = $scores.GetEnumerator() | Where-Object { $_.Value -ge $script:MinimumConfidenceScore }

    # Trier par score décroissant et prendre les N premiers
    $topThemes = $filteredScores | Sort-Object -Property Value -Descending | Select-Object -First $MaxThemes

    # Formater les résultats
    $results = $topThemes | ForEach-Object {
        [PSCustomObject]@{
            Theme  = $_.Key
            Score  = $_.Value
            Prefix = $script:ThematicPrefixes[$_.Key]
        }
    }

    return $results
}

function Set-ItemThematicAttributes {
    <#
    .SYNOPSIS
        Attribue des thèmes à un élément de roadmap.
    .DESCRIPTION
        Analyse le contenu d'un élément de roadmap et lui attribue des thèmes.
    .PARAMETER Item
        Élément de roadmap à analyser.
    .PARAMETER TitleField
        Nom du champ contenant le titre.
    .PARAMETER DescriptionField
        Nom du champ contenant la description.
    .PARAMETER ThemeField
        Nom du champ où stocker les thèmes.
    .PARAMETER MaxThemes
        Nombre maximum de thèmes à attribuer.
    .EXAMPLE
        $task = [PSCustomObject]@{
            Title = "Développer l'interface utilisateur"
            Description = "Créer une interface responsive avec HTML et CSS"
            Themes = @()
        }
        Set-ItemThematicAttributes -Item $task -TitleField "Title" -DescriptionField "Description" -ThemeField "Themes"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Item,

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "title",

        [Parameter(Mandatory = $false)]
        [string]$DescriptionField = "description",

        [Parameter(Mandatory = $false)]
        [string]$ThemeField = "themes",

        [Parameter(Mandatory = $false)]
        [int]$MaxThemes = $script:DefaultMaxThemes
    )

    # Vérifier que le système est initialisé
    if ($script:ThematicCategories.Count -eq 0) {
        throw "Le système d'attribution thématique n'est pas initialisé. Utilisez Initialize-ThematicSystem d'abord."
    }

    # Extraire le titre et la description
    $title = if ($Item.$TitleField) { $Item.$TitleField } else { "" }
    $description = if ($Item.$DescriptionField) { $Item.$DescriptionField } else { "" }

    # Obtenir les thèmes
    $themes = Get-ContentThemes -Content $description -Title $title -MaxThemes $MaxThemes

    # Attribuer les thèmes à l'élément
    $Item.$ThemeField = $themes

    return $Item
}

function Test-ThematicAttribution {
    <#
    .SYNOPSIS
        Teste le système d'attribution thématique.
    .DESCRIPTION
        Exécute des tests sur le système d'attribution thématique avec des exemples prédéfinis.
    .PARAMETER Verbose
        Affiche des informations détaillées sur les tests.
    .EXAMPLE
        Test-ThematicAttribution -Verbose
    #>
    [CmdletBinding()]
    param()

    # Vérifier que le système est initialisé
    if ($script:ThematicCategories.Count -eq 0) {
        throw "Le système d'attribution thématique n'est pas initialisé. Utilisez Initialize-ThematicSystem d'abord."
    }

    # Exemples de test
    $testCases = @(
        @{
            Title          = "Développer l'interface utilisateur responsive"
            Description    = "Créer une interface utilisateur responsive avec HTML, CSS et JavaScript"
            ExpectedThemes = @("Frontend")
        },
        @{
            Title          = "Optimiser les requêtes SQL"
            Description    = "Améliorer les performances des requêtes SQL dans la base de données"
            ExpectedThemes = @("Backend")
        },
        @{
            Title          = "Configurer le déploiement CI/CD"
            Description    = "Mettre en place un pipeline CI/CD avec Docker et Kubernetes"
            ExpectedThemes = @("Infrastructure")
        }
    )

    $passedTests = 0
    $totalTests = $testCases.Count

    foreach ($test in $testCases) {
        Write-Verbose "Test: $($test.Title)"

        $themes = Get-ContentThemes -Content $test.Description -Title $test.Title
        $themeNames = $themes | Select-Object -ExpandProperty Theme

        $passed = $false
        foreach ($expectedTheme in $test.ExpectedThemes) {
            if ($themeNames -contains $expectedTheme) {
                $passed = $true
                break
            }
        }

        if ($passed) {
            $passedTests++
            Write-Verbose "  Résultat: Réussi"
        } else {
            Write-Verbose "  Résultat: Échoué"
            Write-Verbose "  Thèmes attendus: $($test.ExpectedThemes -join ', ')"
            Write-Verbose "  Thèmes détectés: $($themeNames -join ', ')"
        }
    }

    $successRate = ($passedTests / $totalTests) * 100
    Write-Output "Tests réussis: $passedTests/$totalTests ($successRate%)"

    return $successRate -ge 70  # Considérer comme réussi si au moins 70% des tests passent
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ThematicSystem, Get-ContentThemes, Set-ItemThematicAttributes, Test-ThematicAttribution

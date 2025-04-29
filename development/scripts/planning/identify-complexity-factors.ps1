[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown")]
    [string]$Format = "Markdown"
)

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Définir les catégories de facteurs de complexité
$complexityFactors = @{
    "TechnicalComplexity" = @{
        "Description" = "Facteurs liés à la complexité technique de l'amélioration"
        "Factors" = @(
            @{
                "Name" = "Complexité algorithmique"
                "Description" = "Complexité des algorithmes et des structures de données nécessaires"
                "Examples" = @(
                    "Algorithmes simples (boucles, conditions) = complexité faible",
                    "Algorithmes de tri ou de recherche = complexité moyenne",
                    "Algorithmes d'optimisation ou d'apprentissage = complexité élevée"
                )
                "Weight" = 0.20
            },
            @{
                "Name" = "Intégration avec des systèmes existants"
                "Description" = "Niveau d'intégration requis avec les systèmes existants"
                "Examples" = @(
                    "Aucune intégration = complexité faible",
                    "Intégration avec un système interne = complexité moyenne",
                    "Intégration avec plusieurs systèmes externes = complexité élevée"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "Dépendances techniques"
                "Description" = "Nombre et complexité des dépendances techniques"
                "Examples" = @(
                    "Aucune dépendance externe = complexité faible",
                    "Quelques dépendances bien documentées = complexité moyenne",
                    "Nombreuses dépendances ou dépendances complexes = complexité élevée"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "Nouveauté technologique"
                "Description" = "Degré de nouveauté des technologies utilisées"
                "Examples" = @(
                    "Technologies bien maîtrisées = complexité faible",
                    "Technologies partiellement maîtrisées = complexité moyenne",
                    "Technologies nouvelles ou peu maîtrisées = complexité élevée"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Sécurité"
                "Description" = "Exigences de sécurité associées à l'amélioration"
                "Examples" = @(
                    "Aucune exigence de sécurité particulière = complexité faible",
                    "Authentification et autorisation standard = complexité moyenne",
                    "Chiffrement, protection contre les attaques avancées = complexité élevée"
                )
                "Weight" = 0.10
            }
        )
    },
    "FunctionalComplexity" = @{
        "Description" = "Facteurs liés à la complexité fonctionnelle de l'amélioration"
        "Factors" = @(
            @{
                "Name" = "Nombre de fonctionnalités"
                "Description" = "Nombre de fonctionnalités à implémenter"
                "Examples" = @(
                    "Une seule fonctionnalité simple = complexité faible",
                    "Plusieurs fonctionnalités liées = complexité moyenne",
                    "Nombreuses fonctionnalités interdépendantes = complexité élevée"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "Complexité des règles métier"
                "Description" = "Complexité des règles métier à implémenter"
                "Examples" = @(
                    "Règles métier simples et directes = complexité faible",
                    "Règles métier avec quelques conditions = complexité moyenne",
                    "Règles métier complexes avec nombreuses exceptions = complexité élevée"
                )
                "Weight" = 0.15
            },
            @{
                "Name" = "Interface utilisateur"
                "Description" = "Complexité de l'interface utilisateur à développer"
                "Examples" = @(
                    "Pas d'interface utilisateur ou interface simple = complexité faible",
                    "Interface utilisateur avec quelques écrans = complexité moyenne",
                    "Interface utilisateur complexe avec nombreuses interactions = complexité élevée"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Gestion des données"
                "Description" = "Complexité de la gestion des données"
                "Examples" = @(
                    "Données simples sans persistance = complexité faible",
                    "Données structurées avec persistance simple = complexité moyenne",
                    "Données complexes avec relations multiples = complexité élevée"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Traitement asynchrone"
                "Description" = "Nécessité de traitement asynchrone ou parallèle"
                "Examples" = @(
                    "Traitement synchrone uniquement = complexité faible",
                    "Quelques opérations asynchrones simples = complexité moyenne",
                    "Traitement massivement parallèle ou distribué = complexité élevée"
                )
                "Weight" = 0.10
            }
        )
    },
    "ProjectComplexity" = @{
        "Description" = "Facteurs liés à la complexité du projet"
        "Factors" = @(
            @{
                "Name" = "Taille de l'équipe"
                "Description" = "Nombre de personnes impliquées dans le développement"
                "Examples" = @(
                    "Une seule personne = complexité faible",
                    "Petite équipe (2-5 personnes) = complexité moyenne",
                    "Grande équipe (plus de 5 personnes) = complexité élevée"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Distribution géographique"
                "Description" = "Distribution géographique de l'équipe"
                "Examples" = @(
                    "Équipe co-localisée = complexité faible",
                    "Équipe distribuée dans un même fuseau horaire = complexité moyenne",
                    "Équipe distribuée globalement = complexité élevée"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Contraintes de temps"
                "Description" = "Contraintes de temps pour la livraison"
                "Examples" = @(
                    "Pas de contrainte de temps stricte = complexité faible",
                    "Délai raisonnable mais fixe = complexité moyenne",
                    "Délai très court ou critique = complexité élevée"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Dépendances externes"
                "Description" = "Dépendances vis-à-vis d'équipes ou de fournisseurs externes"
                "Examples" = @(
                    "Aucune dépendance externe = complexité faible",
                    "Quelques dépendances externes bien définies = complexité moyenne",
                    "Nombreuses dépendances externes ou mal définies = complexité élevée"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Criticité"
                "Description" = "Niveau de criticité de l'amélioration pour l'entreprise"
                "Examples" = @(
                    "Faible impact en cas d'échec = complexité faible",
                    "Impact modéré en cas d'échec = complexité moyenne",
                    "Impact majeur en cas d'échec = complexité élevée"
                )
                "Weight" = 0.05
            }
        )
    },
    "QualityComplexity" = @{
        "Description" = "Facteurs liés aux exigences de qualité"
        "Factors" = @(
            @{
                "Name" = "Exigences de performance"
                "Description" = "Niveau d'exigence en termes de performance"
                "Examples" = @(
                    "Pas d'exigence particulière de performance = complexité faible",
                    "Exigences de performance modérées = complexité moyenne",
                    "Exigences de performance élevées ou critiques = complexité élevée"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Exigences de fiabilité"
                "Description" = "Niveau d'exigence en termes de fiabilité"
                "Examples" = @(
                    "Tolérance aux erreurs acceptable = complexité faible",
                    "Haute disponibilité requise = complexité moyenne",
                    "Zéro temps d'arrêt requis = complexité élevée"
                )
                "Weight" = 0.10
            },
            @{
                "Name" = "Exigences de testabilité"
                "Description" = "Facilité à tester l'amélioration"
                "Examples" = @(
                    "Tests simples et directs = complexité faible",
                    "Tests nécessitant des mocks ou des stubs = complexité moyenne",
                    "Tests nécessitant des environnements complexes = complexité élevée"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Exigences de maintenabilité"
                "Description" = "Niveau d'exigence en termes de maintenabilité"
                "Examples" = @(
                    "Code jetable ou à usage unique = complexité faible",
                    "Code devant être maintenu à moyen terme = complexité moyenne",
                    "Code critique devant être maintenu à long terme = complexité élevée"
                )
                "Weight" = 0.05
            },
            @{
                "Name" = "Exigences de documentation"
                "Description" = "Niveau d'exigence en termes de documentation"
                "Examples" = @(
                    "Documentation minimale requise = complexité faible",
                    "Documentation standard requise = complexité moyenne",
                    "Documentation exhaustive requise = complexité élevée"
                )
                "Weight" = 0.05
            }
        )
    }
}

# Fonction pour générer le document au format Markdown
function Generate-MarkdownDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ComplexityFactors
    )

    $markdown = "# Facteurs Influençant la Complexité des Améliorations`n`n"
    $markdown += "Ce document identifie et décrit les facteurs qui influencent la complexité des améliorations logicielles. "
    $markdown += "Ces facteurs servent de base pour l'estimation de l'effort requis pour implémenter les améliorations.`n`n"
    
    $markdown += "## Table des Matières`n`n"
    
    foreach ($category in $ComplexityFactors.Keys) {
        $markdown += "- [$($ComplexityFactors[$category].Description)](#$($category.ToLower()))`n"
    }
    
    $markdown += "`n## Utilisation`n`n"
    $markdown += "Pour chaque amélioration à estimer, évaluez sa complexité selon chacun des facteurs listés ci-dessous. "
    $markdown += "Attribuez un score de 1 (complexité faible) à 5 (complexité élevée) pour chaque facteur, puis calculez "
    $markdown += "un score pondéré en utilisant les poids indiqués.`n`n"
    
    $markdown += "La formule générale est :`n`n"
    $markdown += "````n"
    $markdown += "Score de complexité = Somme(Score du facteur * Poids du facteur)`n"
    $markdown += "````n`n"
    
    foreach ($category in $ComplexityFactors.Keys) {
        $markdown += "## <a name='$($category.ToLower())'></a>$($ComplexityFactors[$category].Description)`n`n"
        
        foreach ($factor in $ComplexityFactors[$category].Factors) {
            $markdown += "### $($factor.Name) (Poids: $($factor.Weight))`n`n"
            $markdown += "$($factor.Description)`n`n"
            
            $markdown += "**Exemples :**`n`n"
            foreach ($example in $factor.Examples) {
                $markdown += "- $example`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown += "## Matrice d'Évaluation`n`n"
    $markdown += "| Niveau | Description | Score |`n"
    $markdown += "|--------|-------------|-------|`n"
    $markdown += "| Très faible | Complexité minimale, solution directe | 1 |`n"
    $markdown += "| Faible | Complexité légèrement supérieure à la moyenne, quelques défis | 2 |`n"
    $markdown += "| Moyen | Complexité moyenne, défis modérés | 3 |`n"
    $markdown += "| Élevé | Complexité significative, défis importants | 4 |`n"
    $markdown += "| Très élevé | Complexité extrême, défis majeurs | 5 |`n"
    
    return $markdown
}

# Fonction pour générer le document au format JSON
function Generate-JsonDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ComplexityFactors
    )

    $jsonObject = @{
        Title = "Facteurs Influençant la Complexité des Améliorations"
        Description = "Ce document identifie et décrit les facteurs qui influencent la complexité des améliorations logicielles. Ces facteurs servent de base pour l'estimation de l'effort requis pour implémenter les améliorations."
        Categories = @{}
        EvaluationMatrix = @(
            @{
                Level = "Très faible"
                Description = "Complexité minimale, solution directe"
                Score = 1
            },
            @{
                Level = "Faible"
                Description = "Complexité légèrement supérieure à la moyenne, quelques défis"
                Score = 2
            },
            @{
                Level = "Moyen"
                Description = "Complexité moyenne, défis modérés"
                Score = 3
            },
            @{
                Level = "Élevé"
                Description = "Complexité significative, défis importants"
                Score = 4
            },
            @{
                Level = "Très élevé"
                Description = "Complexité extrême, défis majeurs"
                Score = 5
            }
        )
    }
    
    foreach ($category in $ComplexityFactors.Keys) {
        $jsonObject.Categories[$category] = @{
            Description = $ComplexityFactors[$category].Description
            Factors = $ComplexityFactors[$category].Factors
        }
    }
    
    return $jsonObject | ConvertTo-Json -Depth 10
}

# Générer le document dans le format spécifié
switch ($Format) {
    "Markdown" {
        $documentContent = Generate-MarkdownDocument -ComplexityFactors $complexityFactors
    }
    "JSON" {
        $documentContent = Generate-JsonDocument -ComplexityFactors $complexityFactors
    }
}

# Enregistrer le document
try {
    $documentContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Document des facteurs de complexité généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du document : $_"
    exit 1
}

# Afficher un résumé
Write-Host "`nRésumé des facteurs de complexité :"
Write-Host "--------------------------------"

$totalFactors = 0
foreach ($category in $complexityFactors.Keys) {
    $categoryFactors = $complexityFactors[$category].Factors.Count
    $totalFactors += $categoryFactors
    Write-Host "  $($complexityFactors[$category].Description) : $categoryFactors facteurs"
}

Write-Host "  Total : $totalFactors facteurs"

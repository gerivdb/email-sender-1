# AsymmetryRecommendations.psm1
# Module pour le système de recommandations basé sur l'analyse d'asymétrie

# Structure pour représenter une règle de recommandation
class RecommendationRule {
    [string]$Id
    [string]$Name
    [string]$Description
    [string]$Category
    [int]$Priority
    [scriptblock]$Condition
    [scriptblock]$Recommendation
    [scriptblock]$ScoreCalculator
    [hashtable]$Parameters
    [string[]]$Tags
    [string]$ApplicabilityLevel # "Always", "Contextual", "Specific"
    [double]$Relevance # Score de 0 à 1 indiquant la pertinence de la recommandation

    # Constructeur par défaut
    RecommendationRule() {
        $this.Id = ""
        $this.Name = ""
        $this.Description = ""
        $this.Category = ""
        $this.Priority = 0
        $this.Condition = { param($data, $params) $true }
        $this.Recommendation = { param($data, $params) "Pas de recommandation disponible." }
        $this.ScoreCalculator = { param($data, $params) 0.5 } # Score par défaut
        $this.Parameters = @{}
        $this.Tags = @()
        $this.ApplicabilityLevel = "Contextual"
        $this.Relevance = 0.5
    }

    # Constructeur avec tous les paramètres
    RecommendationRule(
        [string]$id,
        [string]$name,
        [string]$description,
        [string]$category,
        [int]$priority,
        [scriptblock]$condition,
        [scriptblock]$recommendation
    ) {
        $this.Id = $id
        $this.Name = $name
        $this.Description = $description
        $this.Category = $category
        $this.Priority = $priority
        $this.Condition = $condition
        $this.Recommendation = $recommendation
        $this.ScoreCalculator = { param($data, $params) 0.5 } # Score par défaut
        $this.Parameters = @{}
        $this.Tags = @()
        $this.ApplicabilityLevel = "Contextual"
        $this.Relevance = 0.5
    }

    # Constructeur avec tous les paramètres et les paramètres optionnels
    RecommendationRule(
        [string]$id,
        [string]$name,
        [string]$description,
        [string]$category,
        [int]$priority,
        [scriptblock]$condition,
        [scriptblock]$recommendation,
        [hashtable]$parameters
    ) {
        $this.Id = $id
        $this.Name = $name
        $this.Description = $description
        $this.Category = $category
        $this.Priority = $priority
        $this.Condition = $condition
        $this.Recommendation = $recommendation
        $this.ScoreCalculator = { param($data, $params) 0.5 } # Score par défaut
        $this.Parameters = $parameters
        $this.Tags = @()
        $this.ApplicabilityLevel = "Contextual"
        $this.Relevance = 0.5
    }

    # Constructeur complet avec tous les paramètres
    RecommendationRule(
        [string]$id,
        [string]$name,
        [string]$description,
        [string]$category,
        [int]$priority,
        [scriptblock]$condition,
        [scriptblock]$recommendation,
        [scriptblock]$scoreCalculator,
        [hashtable]$parameters,
        [string[]]$tags,
        [string]$applicabilityLevel
    ) {
        $this.Id = $id
        $this.Name = $name
        $this.Description = $description
        $this.Category = $category
        $this.Priority = $priority
        $this.Condition = $condition
        $this.Recommendation = $recommendation
        $this.ScoreCalculator = $scoreCalculator
        $this.Parameters = $parameters
        $this.Tags = $tags
        $this.ApplicabilityLevel = $applicabilityLevel
        $this.Relevance = 0.5
    }

    # Évalue si la règle s'applique aux données
    [bool] Evaluate([PSObject]$data) {
        try {
            return & $this.Condition $data $this.Parameters
        } catch {
            Write-Warning "Erreur lors de l'évaluation de la règle '$($this.Id)': $_"
            return $false
        }
    }

    # Génère la recommandation
    [string] GetRecommendation([PSObject]$data) {
        try {
            return & $this.Recommendation $data $this.Parameters
        } catch {
            Write-Warning "Erreur lors de la génération de la recommandation pour la règle '$($this.Id)': $_"
            return "Impossible de générer la recommandation pour la règle '$($this.Id)'."
        }
    }

    # Calcule le score de pertinence de la recommandation
    [double] CalculateScore([PSObject]$data) {
        try {
            $this.Relevance = & $this.ScoreCalculator $data $this.Parameters
            return $this.Relevance
        } catch {
            Write-Warning "Erreur lors du calcul du score pour la règle '$($this.Id)': $_"
            return 0.0
        }
    }

    # Vérifie si la règle est applicable dans un contexte spécifique
    [bool] IsApplicableInContext([string]$context) {
        if ($this.ApplicabilityLevel -eq "Always") {
            return $true
        }

        if ($this.ApplicabilityLevel -eq "Specific" -and $this.Tags -notcontains $context) {
            return $false
        }

        return $true
    }
}

# Gestionnaire de règles de recommandation
class RecommendationEngine {
    [System.Collections.Generic.List[RecommendationRule]]$Rules
    [hashtable]$Categories
    [hashtable]$TagIndex
    [int]$MaxRecommendations
    [double]$MinimumRelevanceScore
    [string]$CurrentContext
    [bool]$UseAdvancedScoring

    RecommendationEngine() {
        $this.Rules = [System.Collections.Generic.List[RecommendationRule]]::new()
        $this.Categories = @{}
        $this.TagIndex = @{}
        $this.MaxRecommendations = 10
        $this.MinimumRelevanceScore = 0.3
        $this.CurrentContext = "Default"
        $this.UseAdvancedScoring = $true
    }

    # Ajoute une règle au moteur
    [void] AddRule([RecommendationRule]$rule) {
        $this.Rules.Add($rule)

        # Ajouter la catégorie si elle n'existe pas
        if (-not $this.Categories.ContainsKey($rule.Category)) {
            $this.Categories[$rule.Category] = @()
        }

        # Ajouter la règle à sa catégorie
        $this.Categories[$rule.Category] += $rule

        # Indexer les tags de la règle
        foreach ($tag in $rule.Tags) {
            if (-not $this.TagIndex.ContainsKey($tag)) {
                $this.TagIndex[$tag] = @()
            }

            $this.TagIndex[$tag] += $rule
        }
    }

    # Supprime une règle du moteur
    [void] RemoveRule([string]$ruleId) {
        $ruleToRemove = $this.Rules | Where-Object { $_.Id -eq $ruleId } | Select-Object -First 1

        if ($ruleToRemove) {
            $this.Rules.Remove($ruleToRemove)

            # Mettre à jour la liste des règles dans la catégorie
            $category = $ruleToRemove.Category
            if ($this.Categories.ContainsKey($category)) {
                $this.Categories[$category] = $this.Categories[$category] | Where-Object { $_.Id -ne $ruleId }
            }

            # Mettre à jour l'index des tags
            foreach ($tag in $ruleToRemove.Tags) {
                if ($this.TagIndex.ContainsKey($tag)) {
                    $this.TagIndex[$tag] = $this.TagIndex[$tag] | Where-Object { $_.Id -ne $ruleId }
                }
            }
        }
    }

    # Définit le contexte actuel pour le filtrage des recommandations
    [void] SetContext([string]$context) {
        $this.CurrentContext = $context
    }

    # Évalue toutes les règles et retourne les recommandations applicables
    [PSObject[]] GetRecommendations([PSObject]$data) {
        # Filtrer les règles applicables dans le contexte actuel
        $contextFilteredRules = $this.Rules | Where-Object { $_.IsApplicableInContext($this.CurrentContext) }

        # Évaluer les règles
        $applicableRules = $contextFilteredRules | Where-Object { $_.Evaluate($data) }

        # Calculer les scores de pertinence si le scoring avancé est activé
        if ($this.UseAdvancedScoring) {
            foreach ($rule in $applicableRules) {
                $rule.CalculateScore($data)
            }

            # Filtrer par score minimum de pertinence
            $applicableRules = $applicableRules | Where-Object { $_.Relevance -ge $this.MinimumRelevanceScore }

            # Trier par pertinence et priorité
            $applicableRules = $applicableRules | Sort-Object -Property @{Expression = "Relevance"; Descending = $true }, @{Expression = "Priority"; Descending = $true }
        } else {
            # Trier uniquement par priorité
            $applicableRules = $applicableRules | Sort-Object -Property Priority -Descending
        }

        # Limiter le nombre de recommandations
        if ($applicableRules.Count -gt $this.MaxRecommendations) {
            $applicableRules = $applicableRules | Select-Object -First $this.MaxRecommendations
        }

        # Générer les recommandations
        $recommendations = @()
        foreach ($rule in $applicableRules) {
            $recommendations += [PSCustomObject]@{
                RuleId             = $rule.Id
                RuleName           = $rule.Name
                Category           = $rule.Category
                Priority           = $rule.Priority
                Relevance          = $rule.Relevance
                Tags               = $rule.Tags
                ApplicabilityLevel = $rule.ApplicabilityLevel
                Recommendation     = $rule.GetRecommendation($data)
            }
        }

        return $recommendations
    }

    # Retourne les recommandations par catégorie
    [hashtable] GetRecommendationsByCategory([PSObject]$data) {
        $recommendations = $this.GetRecommendations($data)
        $recommendationsByCategory = @{}

        foreach ($recommendation in $recommendations) {
            $category = $recommendation.Category

            if (-not $recommendationsByCategory.ContainsKey($category)) {
                $recommendationsByCategory[$category] = @()
            }

            $recommendationsByCategory[$category] += $recommendation
        }

        return $recommendationsByCategory
    }

    # Retourne les recommandations sous forme de texte
    [string[]] GetRecommendationsText([PSObject]$data) {
        $recommendations = $this.GetRecommendations($data)
        return $recommendations | ForEach-Object { $_.Recommendation }
    }

    # Retourne les recommandations filtrées par tags
    [PSObject[]] GetRecommendationsByTags([PSObject]$data, [string[]]$tags) {
        # Obtenir toutes les recommandations
        $allRecommendations = $this.GetRecommendations($data)

        # Filtrer par tags
        $filteredRecommendations = $allRecommendations | Where-Object {
            $recommendation = $_
            $hasTag = $false

            foreach ($tag in $tags) {
                if ($recommendation.Tags -contains $tag) {
                    $hasTag = $true
                    break
                }
            }

            return $hasTag
        }

        return $filteredRecommendations
    }

    # Retourne les recommandations avec un score de pertinence minimum
    [PSObject[]] GetRecommendationsByMinimumRelevance([PSObject]$data, [double]$minimumRelevance) {
        # Sauvegarder le score minimum actuel
        $currentMinimum = $this.MinimumRelevanceScore

        # Définir le nouveau score minimum
        $this.MinimumRelevanceScore = $minimumRelevance

        # Obtenir les recommandations
        $recommendations = $this.GetRecommendations($data)

        # Restaurer le score minimum
        $this.MinimumRelevanceScore = $currentMinimum

        return $recommendations
    }

    # Retourne les statistiques sur les recommandations
    [PSObject] GetRecommendationStatistics([PSObject]$data) {
        # Obtenir toutes les recommandations applicables (sans filtrage)
        $contextFilteredRules = $this.Rules | Where-Object { $_.IsApplicableInContext($this.CurrentContext) }
        $applicableRules = $contextFilteredRules | Where-Object { $_.Evaluate($data) }

        # Calculer les scores de pertinence
        foreach ($rule in $applicableRules) {
            $rule.CalculateScore($data)
        }

        # Calculer les statistiques
        $totalRules = $this.Rules.Count
        $applicableRulesCount = $applicableRules.Count
        $averageRelevance = if ($applicableRules.Count -gt 0) { ($applicableRules | Measure-Object -Property Relevance -Average).Average } else { 0 }
        $categoryCounts = @{}

        foreach ($category in $this.Categories.Keys) {
            $categoryCounts[$category] = ($applicableRules | Where-Object { $_.Category -eq $category }).Count
        }

        $tagCounts = @{}
        foreach ($tag in $this.TagIndex.Keys) {
            $tagCounts[$tag] = ($applicableRules | Where-Object { $_.Tags -contains $tag }).Count
        }

        # Créer l'objet de statistiques
        $statistics = [PSCustomObject]@{
            TotalRules            = $totalRules
            ApplicableRules       = $applicableRulesCount
            ApplicablePercentage  = if ($totalRules -gt 0) { [Math]::Round(($applicableRulesCount / $totalRules) * 100, 2) } else { 0 }
            AverageRelevance      = [Math]::Round($averageRelevance, 2)
            CategoryCounts        = $categoryCounts
            TagCounts             = $tagCounts
            Context               = $this.CurrentContext
            MinimumRelevanceScore = $this.MinimumRelevanceScore
            UseAdvancedScoring    = $this.UseAdvancedScoring
        }

        return $statistics
    }
}

# Fonction pour créer un moteur de recommandations avec des règles prédéfinies
function New-AsymmetryRecommendationEngine {
    [CmdletBinding()]
    [OutputType([RecommendationEngine])]
    param()

    $engine = [RecommendationEngine]::new()

    # Règle 1: Recommandation basée sur le score composite d'asymétrie
    $rule1 = [RecommendationRule]::new(
        "ASYM001",
        "Évaluation du score composite d'asymétrie",
        "Évalue le score composite d'asymétrie et fournit une recommandation générale.",
        "Général",
        100,
        {
            param($data, $params)
            return $true  # Cette règle s'applique toujours
        },
        {
            param($data, $params)
            $score = $data.CompositeScore
            $direction = $data.AsymmetryDirection
            $intensity = $data.AsymmetryIntensity

            $scoreRounded = [Math]::Round($score, 2)

            return "Le score composite d'asymétrie de $scoreRounded indique une distribution $($direction.ToLower()) avec une asymétrie de niveau '$($intensity.ToLower())'."
        },
        @{}
    )
    $engine.AddRule($rule1)

    # Règle 2: Recommandation pour les distributions fortement asymétriques
    $rule2 = [RecommendationRule]::new(
        "ASYM002",
        "Transformation pour asymétrie forte",
        "Recommande des transformations pour les distributions fortement asymétriques.",
        "Transformation",
        90,
        {
            param($data, $params)
            $intensity = $data.AsymmetryIntensity
            return $intensity -eq "Strong" -or $intensity -eq "VeryStrong" -or $intensity -eq "Extreme"
        },
        {
            param($data, $params)
            $direction = $data.AsymmetryDirection

            if ($direction -eq "Positive" -or $direction -eq "Queue droite plus longue") {
                return "Pour réduire l'asymétrie positive forte, envisagez d'appliquer une transformation logarithmique (log(x)) ou racine carrée (sqrt(x)) aux données."
            } elseif ($direction -eq "Negative" -or $direction -eq "Queue gauche plus longue") {
                return "Pour réduire l'asymétrie négative forte, envisagez d'appliquer une transformation exponentielle (exp(x)) ou carrée (x^2) aux données."
            } else {
                return "Malgré une intensité forte, la distribution est relativement symétrique. Vérifiez s'il y a des sous-groupes dans vos données."
            }
        },
        @{}
    )
    $engine.AddRule($rule2)

    # Règle 3: Recommandation pour les distributions modérément asymétriques
    $rule3 = [RecommendationRule]::new(
        "ASYM003",
        "Transformation pour asymétrie modérée",
        "Recommande des transformations pour les distributions modérément asymétriques.",
        "Transformation",
        80,
        {
            param($data, $params)
            return $data.AsymmetryIntensity -eq "Moderate"
        },
        {
            param($data, $params)
            $direction = $data.AsymmetryDirection

            if ($direction -eq "Positive" -or $direction -eq "Queue droite plus longue") {
                return "Pour réduire l'asymétrie positive modérée, envisagez d'appliquer une transformation douce comme log(x+1) ou une transformation Box-Cox avec λ entre 0 et 0.5."
            } elseif ($direction -eq "Negative" -or $direction -eq "Queue gauche plus longue") {
                return "Pour réduire l'asymétrie négative modérée, envisagez d'appliquer une transformation douce comme x^1.5 ou une transformation Box-Cox avec λ > 1."
            } else {
                return "Malgré une intensité modérée, la distribution est relativement symétrique. Vérifiez s'il y a des valeurs aberrantes."
            }
        },
        @{}
    )
    $engine.AddRule($rule3)

    # Règle 4: Recommandation pour les distributions faiblement asymétriques
    $rule4 = [RecommendationRule]::new(
        "ASYM004",
        "Gestion de l'asymétrie faible",
        "Recommande des approches pour les distributions faiblement asymétriques.",
        "Analyse",
        70,
        {
            param($data, $params)
            $intensity = $data.AsymmetryIntensity
            return $intensity -eq "Weak" -or $intensity -eq "VeryWeak"
        },
        {
            param($data, $params)
            return "L'asymétrie est faible, ce qui est généralement acceptable pour la plupart des analyses statistiques. Vous pouvez procéder avec des méthodes paramétriques standard, mais restez vigilant quant à l'impact potentiel sur les tests de significativité."
        },
        @{}
    )
    $engine.AddRule($rule4)

    # Règle 5: Recommandation pour les distributions symétriques
    $rule5 = [RecommendationRule]::new(
        "ASYM005",
        "Confirmation de symétrie",
        "Recommande des approches pour les distributions symétriques.",
        "Analyse",
        60,
        {
            param($data, $params)
            $intensity = $data.AsymmetryIntensity
            return $intensity -eq "Negligible"
        },
        {
            param($data, $params)
            return "La distribution est pratiquement symétrique. Vous pouvez utiliser des méthodes paramétriques standard avec confiance, à condition que les autres hypothèses (comme la normalité) soient satisfaites."
        },
        @{}
    )
    $engine.AddRule($rule5)

    # Règle 6: Recommandation basée sur la méthode optimale
    $rule6 = [RecommendationRule]::new(
        "ASYM006",
        "Méthode d'évaluation recommandée",
        "Recommande la méthode d'évaluation d'asymétrie la plus appropriée.",
        "Méthodologie",
        95,
        {
            param($data, $params)
            return $null -ne $data.RecommendedMethod
        },
        {
            param($data, $params)
            $method = $data.RecommendedMethod
            $consistency = [Math]::Round($data.ConsistencyScore, 2)

            $methodDescription = switch ($method) {
                "Slope" { "basée sur les pentes des queues" }
                "Moments" { "basée sur les moments statistiques" }
                "Quantiles" { "basée sur les quantiles" }
                "Density" { "basée sur la densité" }
                default { $method }
            }

            return "Pour cette distribution, la méthode d'évaluation d'asymétrie la plus appropriée est la méthode $methodDescription (score de cohérence: $consistency)."
        },
        @{}
    )
    $engine.AddRule($rule6)

    # Règle 7: Recommandation pour les tests statistiques
    $rule7 = [RecommendationRule]::new(
        "ASYM007",
        "Tests statistiques recommandés",
        "Recommande des tests statistiques appropriés en fonction de l'asymétrie.",
        "Tests statistiques",
        85,
        {
            param($data, $params)
            return $true  # Cette règle s'applique toujours
        },
        {
            param($data, $params)
            $intensity = $data.AsymmetryIntensity

            if ($intensity -eq "Negligible" -or $intensity -eq "VeryWeak") {
                return "Vous pouvez utiliser des tests paramétriques standard (t-test, ANOVA, etc.) car l'asymétrie est négligeable."
            } elseif ($intensity -eq "Weak" -or $intensity -eq "Moderate") {
                return "Envisagez d'utiliser des tests paramétriques robustes à l'asymétrie modérée, ou des tests non paramétriques (Mann-Whitney, Kruskal-Wallis) si la taille de l'échantillon est petite."
            } else {
                return "Utilisez des tests non paramétriques (Mann-Whitney, Kruskal-Wallis, etc.) ou transformez les données avant d'appliquer des tests paramétriques."
            }
        },
        @{}
    )
    $engine.AddRule($rule7)

    # Règle 8: Recommandation pour la détection des valeurs aberrantes
    $rule8 = [RecommendationRule]::new(
        "ASYM008",
        "Détection des valeurs aberrantes",
        "Recommande des approches pour la détection des valeurs aberrantes en fonction de l'asymétrie.",
        "Prétraitement",
        75,
        {
            param($data, $params)
            return $true  # Cette règle s'applique toujours
        },
        {
            param($data, $params)
            $direction = $data.AsymmetryDirection
            $intensity = $data.AsymmetryIntensity

            if ($intensity -eq "Negligible" -or $intensity -eq "VeryWeak") {
                return "Pour la détection des valeurs aberrantes, vous pouvez utiliser des méthodes basées sur l'écart-type (règle des 3 sigma) ou l'IQR (1.5 × IQR)."
            } elseif ($direction -eq "Positive" -or $direction -eq "Queue droite plus longue") {
                return "Pour la détection des valeurs aberrantes dans cette distribution asymétrique positive, utilisez des méthodes robustes comme l'IQR ajusté ou la méthode MAD, plutôt que des méthodes basées sur l'écart-type."
            } elseif ($direction -eq "Negative" -or $direction -eq "Queue gauche plus longue") {
                return "Pour la détection des valeurs aberrantes dans cette distribution asymétrique négative, utilisez des méthodes robustes comme l'IQR ajusté ou la méthode MAD, plutôt que des méthodes basées sur l'écart-type."
            } else {
                return "Pour la détection des valeurs aberrantes, utilisez des méthodes robustes comme l'IQR (1.5 × IQR) ou la méthode MAD."
            }
        },
        @{}
    )
    $engine.AddRule($rule8)

    return $engine
}

# Fonction pour obtenir des recommandations basées sur l'analyse d'asymétrie
function Get-AsymmetryRecommendations {
    [CmdletBinding(DefaultParameterSetName = "Standard")]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $true, ParameterSetName = "ByCategory")]
        [Parameter(Mandatory = $true, ParameterSetName = "ByTags")]
        [Parameter(Mandatory = $true, ParameterSetName = "ByRelevance")]
        [Parameter(Mandatory = $true, ParameterSetName = "Statistics")]
        [PSObject]$AsymmetryAnalysis,

        [Parameter(Mandatory = $false, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCategory")]
        [string[]]$Categories = @(),

        [Parameter(Mandatory = $false, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCategory")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByTags")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByRelevance")]
        [int]$MaxRecommendations = 10,

        [Parameter(Mandatory = $false, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCategory")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByTags")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByRelevance")]
        [switch]$IncludeRuleDetails,

        [Parameter(Mandatory = $true, ParameterSetName = "ByCategory")]
        [switch]$GroupByCategory,

        [Parameter(Mandatory = $true, ParameterSetName = "ByTags")]
        [string[]]$Tags,

        [Parameter(Mandatory = $true, ParameterSetName = "ByRelevance")]
        [ValidateRange(0.0, 1.0)]
        [double]$MinimumRelevance,

        [Parameter(Mandatory = $false, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCategory")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByTags")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByRelevance")]
        [string]$Context = "Default",

        [Parameter(Mandatory = $false, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCategory")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByTags")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByRelevance")]
        [switch]$DisableAdvancedScoring,

        [Parameter(Mandatory = $true, ParameterSetName = "Statistics")]
        [switch]$Statistics
    )

    # Créer un moteur de recommandations avec des règles prédéfinies
    $engine = New-AsymmetryRecommendationEngine
    $engine.MaxRecommendations = $MaxRecommendations
    $engine.SetContext($Context)
    $engine.UseAdvancedScoring = -not $DisableAdvancedScoring

    # Filtrer par catégories si spécifié
    if ($Categories.Count -gt 0) {
        $engine.Rules = $engine.Rules | Where-Object { $Categories -contains $_.Category }
    }

    # Retourner les statistiques si demandé
    if ($Statistics) {
        return $engine.GetRecommendationStatistics($AsymmetryAnalysis)
    }

    # Obtenir les recommandations selon le mode demandé
    $recommendations = switch ($PSCmdlet.ParameterSetName) {
        "ByCategory" {
            $engine.GetRecommendationsByCategory($AsymmetryAnalysis)
        }
        "ByTags" {
            $engine.GetRecommendationsByTags($AsymmetryAnalysis, $Tags)
        }
        "ByRelevance" {
            $engine.GetRecommendationsByMinimumRelevance($AsymmetryAnalysis, $MinimumRelevance)
        }
        default {
            $engine.GetRecommendations($AsymmetryAnalysis)
        }
    }

    # Retourner les recommandations avec ou sans détails des règles
    if ($IncludeRuleDetails) {
        return $recommendations
    } else {
        if ($PSCmdlet.ParameterSetName -eq "ByCategory") {
            $result = @{}
            foreach ($category in $recommendations.Keys) {
                $result[$category] = $recommendations[$category] | ForEach-Object { $_.Recommendation }
            }
            return $result
        } else {
            return $recommendations | ForEach-Object { $_.Recommendation }
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function New-AsymmetryRecommendationEngine, Get-AsymmetryRecommendations

# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour les recommandations de résolution minimale pour l'analyse exploratoire.

.DESCRIPTION
    Ce module fournit des fonctions pour déterminer les résolutions minimales
    pour différents types de visualisations dans l'analyse exploratoire des données.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-16
#>

#region Variables globales et constantes

# Règles de binning classiques
$script:BinningRules = @{
    "Sturges"           = @{
        "Formula"           = "k = ceiling(log2(n) + 1)"
        "Description"       = "Règle de Sturges, adaptée pour les distributions approximativement normales"
        "RecommendedFor"    = @("Normale", "Approximativement normale")
        "MinimumSampleSize" = 30
    }
    "Scott"             = @{
        "Formula"           = "h = 3.5 * std / (n^(1/3))"
        "Description"       = "Règle de Scott, basée sur l'écart-type, adaptée pour les distributions approximativement normales"
        "RecommendedFor"    = @("Normale", "Approximativement normale")
        "MinimumSampleSize" = 50
    }
    "Freedman-Diaconis" = @{
        "Formula"           = "h = 2 * IQR / (n^(1/3))"
        "Description"       = "Règle de Freedman-Diaconis, basée sur l'écart interquartile, robuste aux valeurs aberrantes"
        "RecommendedFor"    = @("Asymétrique", "Queue lourde", "Avec valeurs aberrantes")
        "MinimumSampleSize" = 50
    }
    "Rice"              = @{
        "Formula"           = "k = ceiling(2 * n^(1/3))"
        "Description"       = "Règle de Rice, simple et efficace pour de nombreuses distributions"
        "RecommendedFor"    = @("Générale", "Inconnue")
        "MinimumSampleSize" = 10
    }
    "Doane"             = @{
        "Formula"           = "k = 1 + log(n) + log(1 + |g1|/(sigma_g1))"
        "Description"       = "Règle de Doane, modification de Sturges pour les distributions non normales"
        "RecommendedFor"    = @("Asymétrique", "Non normale")
        "MinimumSampleSize" = 30
    }
    "Square-root"       = @{
        "Formula"           = "k = ceiling(sqrt(n))"
        "Description"       = "Règle de la racine carrée, simple mais moins précise"
        "RecommendedFor"    = @("Générale", "Petits échantillons")
        "MinimumSampleSize" = 5
    }
}

# Recommandations minimales par taille d'échantillon
$script:MinBinsBySize = @{
    "Très petit (< 30)"   = 5
    "Petit (30-100)"      = 7
    "Moyen (100-500)"     = 10
    "Grand (500-1000)"    = 15
    "Très grand (> 1000)" = 20
}

# Recommandations pour la densité de points dans les graphiques de dispersion
$script:ScatterPlotDensityRecommendations = @{
    # Nombre maximal de points recommandé par taille de graphique (en pixels)
    "MaxPointsByPlotSize"      = @{
        "Petit (300x300)"        = 100
        "Moyen (500x500)"        = 500
        "Grand (800x800)"        = 2000
        "Très grand (1200x1200)" = 5000
    }

    # Densité optimale de points par pouce carré (DPI)
    "OptimalDensityByDPI"      = @{
        "Basse (72 DPI)"       = 5
        "Moyenne (150 DPI)"    = 15
        "Haute (300 DPI)"      = 40
        "Très haute (600 DPI)" = 100
    }

    # Facteurs d'ajustement par type de distribution
    "DensityAdjustmentFactors" = @{
        "Normale"      = 1.0
        "Asymétrique"  = 0.8
        "Multimodale"  = 1.2
        "Queue lourde" = 0.7
        "Uniforme"     = 1.0
        "Groupée"      = 0.6
        "Dispersée"    = 1.5
        "Inconnue"     = 1.0
    }

    # Stratégies d'échantillonnage par taille d'échantillon
    "SamplingStrategies"       = @{
        "Très petit (< 30)"   = "Afficher tous les points"
        "Petit (30-100)"      = "Afficher tous les points"
        "Moyen (100-500)"     = "Échantillonnage aléatoire ou stratifié si nécessaire"
        "Grand (500-1000)"    = "Échantillonnage stratifié ou clustering"
        "Très grand (> 1000)" = "Échantillonnage, clustering ou heatmap"
    }

    # Recommandations pour éviter le chevauchement
    "OverlapStrategies"        = @{
        "Très petit (< 30)"   = "Aucune action nécessaire"
        "Petit (30-100)"      = "Jittering léger si nécessaire"
        "Moyen (100-500)"     = "Jittering ou transparence"
        "Grand (500-1000)"    = "Transparence et/ou réduction de taille des points"
        "Très grand (> 1000)" = "Transparence, heatmap ou contours de densité"
    }
}

# Recommandations pour le jittering dans les graphiques de dispersion
$script:JitteringRecommendations = @{
    # Amplitude de jittering recommandée par taille d'échantillon (en pourcentage de l'étendue des données)
    "JitterAmplitudeBySize"      = @{
        "Très petit (< 30)"   = 0.5  # 0.5% de l'étendue des données
        "Petit (30-100)"      = 1.0  # 1.0% de l'étendue des données
        "Moyen (100-500)"     = 2.0  # 2.0% de l'étendue des données
        "Grand (500-1000)"    = 2.5  # 2.5% de l'étendue des données
        "Très grand (> 1000)" = 3.0  # 3.0% de l'étendue des données
    }

    # Facteurs d'ajustement par type de distribution
    "JitterFactorByDistribution" = @{
        "Normale"      = 1.0
        "Asymétrique"  = 1.2  # Plus de jittering pour les distributions asymétriques
        "Multimodale"  = 1.3  # Plus de jittering pour les distributions multimodales
        "Queue lourde" = 1.5  # Plus de jittering pour les distributions à queue lourde
        "Uniforme"     = 0.8  # Moins de jittering pour les distributions uniformes
        "Groupée"      = 1.5  # Plus de jittering pour les données groupées
        "Dispersée"    = 0.7  # Moins de jittering pour les données dispersées
        "Inconnue"     = 1.0
    }

    # Type de distribution de jittering recommandé par type de distribution des données
    "JitterDistributionType"     = @{
        "Normale"      = "Normale"      # Distribution normale pour le jittering
        "Asymétrique"  = "Uniforme"     # Distribution uniforme pour le jittering
        "Multimodale"  = "Uniforme"     # Distribution uniforme pour le jittering
        "Queue lourde" = "Uniforme"     # Distribution uniforme pour le jittering
        "Uniforme"     = "Uniforme"     # Distribution uniforme pour le jittering
        "Groupée"      = "Normale"      # Distribution normale pour le jittering
        "Dispersée"    = "Uniforme"     # Distribution uniforme pour le jittering
        "Inconnue"     = "Uniforme"     # Distribution uniforme par défaut
    }

    # Directions de jittering recommandées par type de graphique
    "JitterDirections"           = @{
        "Nuage de points standard"   = "XY"      # Jittering dans les deux directions
        "Nuage de points catégoriel" = "Y"     # Jittering uniquement sur l'axe Y
        "Boîte à moustaches"         = "X"             # Jittering uniquement sur l'axe X
        "Graphique en bâtons"        = "X"            # Jittering uniquement sur l'axe X
        "Graphique temporel"         = "Y"             # Jittering uniquement sur l'axe Y
    }

    # Stratégies de jittering par densité de points
    "JitterStrategies"           = @{
        "Très faible (< 0.1 pts/px²)" = "Aucun jittering nécessaire"
        "Faible (0.1-0.2 pts/px²)"    = "Jittering minimal (±0.5-1%)"
        "Moyenne (0.2-0.5 pts/px²)"   = "Jittering modéré (±1-2%)"
        "Élevée (0.5-1.0 pts/px²)"    = "Jittering important (±2-3%)"
        "Très élevée (> 1.0 pts/px²)" = "Jittering maximal (±3-5%) + transparence"
    }

    # Combinaison avec d'autres techniques
    "ComplementaryTechniques"    = @{
        "Très petit (< 30)"   = @("Augmentation de la taille des points")
        "Petit (30-100)"      = @("Transparence légère (alpha = 0.8-0.9)")
        "Moyen (100-500)"     = @("Transparence modérée (alpha = 0.6-0.8)", "Réduction de la taille des points")
        "Grand (500-1000)"    = @("Transparence élevée (alpha = 0.4-0.6)", "Réduction importante de la taille des points")
        "Très grand (> 1000)" = @("Transparence très élevée (alpha = 0.2-0.4)", "Heatmap", "Contours de densité")
    }
}

# Facteurs d'ajustement par type de distribution
$script:DistributionAdjustmentFactors = @{
    "Normale"       = 1.0
    "Asymétrique"   = 1.2
    "Multimodale"   = 1.5
    "Queue lourde"  = 1.3
    "Uniforme"      = 0.8
    "Exponentielle" = 1.4
    "Inconnue"      = 1.0
}

# Recommandations pour la détection des modes dans les distributions
$script:ModeDetectionRecommendations = @{
    # Critères de hauteur relative pour l'identification des modes (en pourcentage de la hauteur maximale)
    "RelativeHeightThresholds"       = @{
        "Très faible (5%)" = 0.05  # 5% de la hauteur maximale
        "Faible (10%)"     = 0.10  # 10% de la hauteur maximale
        "Modéré (15%)"     = 0.15  # 15% de la hauteur maximale
        "Standard (20%)"   = 0.20  # 20% de la hauteur maximale
        "Élevé (25%)"      = 0.25  # 25% de la hauteur maximale
        "Très élevé (30%)" = 0.30  # 30% de la hauteur maximale
    }

    # Facteurs d'ajustement par type de distribution
    "HeightFactorByDistribution"     = @{
        "Normale"       = 1.0   # Seuil standard pour les distributions normales
        "Asymétrique"   = 0.8   # Seuil plus bas pour les distributions asymétriques
        "Multimodale"   = 0.7   # Seuil plus bas pour les distributions multimodales
        "Queue lourde"  = 0.9   # Seuil légèrement plus bas pour les distributions à queue lourde
        "Uniforme"      = 1.5   # Seuil plus élevé pour les distributions uniformes
        "Exponentielle" = 0.8   # Seuil plus bas pour les distributions exponentielles
        "Inconnue"      = 1.0   # Seuil standard par défaut
    }

    # Recommandations par taille d'échantillon
    "ThresholdBySampleSize"          = @{
        "Très petit (< 30)"   = "Élevé (25%)"      # Seuil plus élevé pour les petits échantillons
        "Petit (30-100)"      = "Standard (20%)"   # Seuil standard pour les échantillons moyens
        "Moyen (100-500)"     = "Modéré (15%)"     # Seuil modéré pour les échantillons moyens
        "Grand (500-1000)"    = "Faible (10%)"     # Seuil plus bas pour les grands échantillons
        "Très grand (> 1000)" = "Très faible (5%)" # Seuil très bas pour les très grands échantillons
    }

    # Recommandations par niveau de bruit
    "ThresholdByNoiseLevel"          = @{
        "Très faible" = "Très faible (5%)"  # Seuil très bas pour les données avec très peu de bruit
        "Faible"      = "Faible (10%)"      # Seuil bas pour les données avec peu de bruit
        "Modéré"      = "Modéré (15%)"      # Seuil modéré pour les données avec un niveau de bruit modéré
        "Élevé"       = "Standard (20%)"    # Seuil standard pour les données bruitées
        "Très élevé"  = "Élevé (25%)"       # Seuil élevé pour les données très bruitées
        "Extrême"     = "Très élevé (30%)"  # Seuil très élevé pour les données extrêmement bruitées
    }

    # Recommandations par méthode de lissage
    "ThresholdBySmoothingMethod"     = @{
        "Aucun"             = "Élevé (25%)"      # Seuil élevé sans lissage
        "Moyenne mobile"    = "Standard (20%)"   # Seuil standard avec moyenne mobile
        "Noyau gaussien"    = "Modéré (15%)"     # Seuil modéré avec noyau gaussien
        "Spline"            = "Faible (10%)"     # Seuil bas avec spline
        "Régression locale" = "Très faible (5%)" # Seuil très bas avec régression locale
    }

    # Recommandations pour les applications spécifiques
    "ThresholdByApplication"         = @{
        "Exploration de données" = "Très faible (5%)"  # Seuil très bas pour l'exploration
        "Analyse statistique"    = "Faible (10%)"      # Seuil bas pour l'analyse statistique
        "Contrôle qualité"       = "Modéré (15%)"      # Seuil modéré pour le contrôle qualité
        "Détection d'anomalies"  = "Standard (20%)"    # Seuil standard pour la détection d'anomalies
        "Classification"         = "Élevé (25%)"       # Seuil élevé pour la classification
        "Segmentation"           = "Très élevé (30%)"  # Seuil très élevé pour la segmentation
    }

    # Critères de séparation minimale entre les modes (en écarts-types)
    "ModeSeparationThresholds"       = @{
        "Très faible (0.5σ)" = 0.5   # 0.5 écart-type
        "Faible (1.0σ)"      = 1.0   # 1.0 écart-type
        "Modéré (1.5σ)"      = 1.5   # 1.5 écart-type
        "Standard (2.0σ)"    = 2.0   # 2.0 écarts-types
        "Élevé (2.5σ)"       = 2.5   # 2.5 écarts-types
        "Très élevé (3.0σ)"  = 3.0   # 3.0 écarts-types
    }

    # Facteurs d'ajustement de séparation par type de distribution
    "SeparationFactorByDistribution" = @{
        "Normale"       = 1.0   # Facteur standard pour les distributions normales
        "Asymétrique"   = 0.8   # Facteur plus bas pour les distributions asymétriques
        "Multimodale"   = 0.7   # Facteur plus bas pour les distributions multimodales
        "Queue lourde"  = 0.9   # Facteur légèrement plus bas pour les distributions à queue lourde
        "Uniforme"      = 1.2   # Facteur plus élevé pour les distributions uniformes
        "Exponentielle" = 0.8   # Facteur plus bas pour les distributions exponentielles
        "Inconnue"      = 1.0   # Facteur standard par défaut
    }

    # Recommandations de séparation par taille d'échantillon
    "SeparationBySampleSize"         = @{
        "Très petit (< 30)"   = "Faible (1.0σ)"      # Séparation plus faible pour les petits échantillons
        "Petit (30-100)"      = "Modéré (1.5σ)"      # Séparation modérée pour les échantillons petits
        "Moyen (100-500)"     = "Standard (2.0σ)"    # Séparation standard pour les échantillons moyens
        "Grand (500-1000)"    = "Élevé (2.5σ)"       # Séparation plus élevée pour les grands échantillons
        "Très grand (> 1000)" = "Très élevé (3.0σ)"  # Séparation très élevée pour les très grands échantillons
    }

    # Recommandations de séparation par niveau de bruit
    "SeparationByNoiseLevel"         = @{
        "Très faible" = "Modéré (1.5σ)"      # Séparation modérée pour les données avec très peu de bruit
        "Faible"      = "Standard (2.0σ)"    # Séparation standard pour les données avec peu de bruit
        "Modéré"      = "Élevé (2.5σ)"       # Séparation élevée pour les données avec un niveau de bruit modéré
        "Élevé"       = "Très élevé (3.0σ)"  # Séparation très élevée pour les données bruitées
        "Très élevé"  = "Très élevé (3.0σ)"  # Séparation très élevée pour les données très bruitées
        "Extrême"     = "Très élevé (3.0σ)"  # Séparation très élevée pour les données extrêmement bruitées
    }

    # Recommandations de séparation par méthode de lissage
    "SeparationBySmoothingMethod"    = @{
        "Aucun"             = "Très élevé (3.0σ)"  # Séparation très élevée sans lissage
        "Moyenne mobile"    = "Élevé (2.5σ)"       # Séparation élevée avec moyenne mobile
        "Noyau gaussien"    = "Standard (2.0σ)"    # Séparation standard avec noyau gaussien
        "Spline"            = "Modéré (1.5σ)"      # Séparation modérée avec spline
        "Régression locale" = "Faible (1.0σ)"      # Séparation faible avec régression locale
    }

    # Recommandations de séparation pour les applications spécifiques
    "SeparationByApplication"        = @{
        "Exploration de données" = "Faible (1.0σ)"       # Séparation faible pour l'exploration
        "Analyse statistique"    = "Standard (2.0σ)"     # Séparation standard pour l'analyse statistique
        "Contrôle qualité"       = "Élevé (2.5σ)"        # Séparation élevée pour le contrôle qualité
        "Détection d'anomalies"  = "Très élevé (3.0σ)"   # Séparation très élevée pour la détection d'anomalies
        "Classification"         = "Élevé (2.5σ)"        # Séparation élevée pour la classification
        "Segmentation"           = "Standard (2.0σ)"     # Séparation standard pour la segmentation
    }
}

# Recommandations pour la détection de l'asymétrie dans les distributions
$script:AsymmetryDetectionRecommendations = @{
    # Valeurs critiques pour le coefficient d'asymétrie (skewness)
    "SkewnessThresholds"         = @{
        "Symétrie parfaite"      = 0.0    # Distribution parfaitement symétrique
        "Quasi-symétrique"       = 0.2    # Distribution quasi-symétrique
        "Légèrement asymétrique" = 0.5    # Distribution légèrement asymétrique
        "Modérément asymétrique" = 1.0    # Distribution modérément asymétrique
        "Fortement asymétrique"  = 2.0    # Distribution fortement asymétrique
        "Très asymétrique"       = 3.0    # Distribution très asymétrique
    }

    # Facteurs d'ajustement par taille d'échantillon
    "SkewnessFactorBySampleSize" = @{
        "Très petit (< 30)"   = 1.5   # Facteur plus élevé pour les petits échantillons
        "Petit (30-100)"      = 1.2   # Facteur légèrement plus élevé pour les échantillons petits
        "Moyen (100-500)"     = 1.0   # Facteur standard pour les échantillons moyens
        "Grand (500-1000)"    = 0.8   # Facteur légèrement plus bas pour les grands échantillons
        "Très grand (> 1000)" = 0.6   # Facteur plus bas pour les très grands échantillons
    }

    # Recommandations par niveau de confiance
    "SkewnessBySampleSize"       = @{
        "Très petit (< 30)"   = "Modérément asymétrique"  # Seuil plus élevé pour les petits échantillons
        "Petit (30-100)"      = "Légèrement asymétrique"  # Seuil modéré pour les échantillons petits
        "Moyen (100-500)"     = "Légèrement asymétrique"  # Seuil modéré pour les échantillons moyens
        "Grand (500-1000)"    = "Quasi-symétrique"        # Seuil plus bas pour les grands échantillons
        "Très grand (> 1000)" = "Quasi-symétrique"        # Seuil plus bas pour les très grands échantillons
    }

    # Recommandations par niveau de confiance
    "SkewnessByConfidenceLevel"  = @{
        "90%" = "Légèrement asymétrique"  # Seuil modéré pour un niveau de confiance de 90%
        "95%" = "Modérément asymétrique"  # Seuil plus élevé pour un niveau de confiance de 95%
        "99%" = "Fortement asymétrique"   # Seuil très élevé pour un niveau de confiance de 99%
    }

    # Recommandations par domaine d'application
    "SkewnessByApplication"      = @{
        "Exploration de données" = "Quasi-symétrique"       # Seuil bas pour l'exploration
        "Analyse statistique"    = "Légèrement asymétrique" # Seuil modéré pour l'analyse statistique
        "Contrôle qualité"       = "Modérément asymétrique" # Seuil plus élevé pour le contrôle qualité
        "Détection d'anomalies"  = "Fortement asymétrique"  # Seuil très élevé pour la détection d'anomalies
        "Classification"         = "Modérément asymétrique" # Seuil plus élevé pour la classification
        "Segmentation"           = "Légèrement asymétrique" # Seuil modéré pour la segmentation
    }

    # Valeurs critiques pour le test de normalité (p-value)
    "NormalityTestThresholds"    = @{
        "Très significatif"       = 0.001  # Rejet très fort de l'hypothèse de normalité
        "Significatif"            = 0.01   # Rejet fort de l'hypothèse de normalité
        "Modérément significatif" = 0.05  # Rejet modéré de l'hypothèse de normalité
        "Peu significatif"        = 0.1    # Rejet faible de l'hypothèse de normalité
        "Non significatif"        = 0.2    # Pas de rejet de l'hypothèse de normalité
    }

    # Critères visuels pour l'identification de l'asymétrie
    "VisualAsymmetryIndicators"  = @{
        "Position médiane"   = "Écart entre moyenne et médiane > 0.1 * écart-type"
        "Queue"              = "Longueur de queue droite/gauche > 1.5"
        "Densité"            = "Ratio de densité max gauche/droite > 1.2"
        "QQ-plot"            = "Déviation systématique de la ligne droite"
        "Histogramme"        = "Pente visible dans la distribution"
        "Boîte à moustaches" = "Moustache plus longue d'un côté"
    }
}

# Recommandations pour les boîtes à moustaches
$script:BoxplotRecommendations = @{
    # Largeur minimale des boîtes (en pixels) par taille d'écran
    "MinBoxWidthByScreenSize"   = @{
        "Petit (800x600)"        = 20
        "Moyen (1280x720)"       = 30
        "Grand (1920x1080)"      = 40
        "Très grand (2560x1440)" = 50
    }

    # Largeur minimale des boîtes (en pourcentage de la largeur du graphique) par nombre de groupes
    "MinBoxWidthByGroupCount"   = @{
        "Très peu (1-3)"      = 15  # 15% de la largeur du graphique
        "Peu (4-7)"           = 10  # 10% de la largeur du graphique
        "Moyen (8-15)"        = 7   # 7% de la largeur du graphique
        "Nombreux (16-30)"    = 5   # 5% de la largeur du graphique
        "Très nombreux (>30)" = 3   # 3% de la largeur du graphique
    }

    # Facteurs d'ajustement par type de distribution
    "BoxWidthAdjustmentFactors" = @{
        "Normale"      = 1.0
        "Asymétrique"  = 1.2  # Boîtes plus larges pour les distributions asymétriques
        "Multimodale"  = 1.3  # Boîtes plus larges pour les distributions multimodales
        "Queue lourde" = 1.5  # Boîtes plus larges pour les distributions à queue lourde
        "Uniforme"     = 0.9  # Boîtes légèrement plus étroites pour les distributions uniformes
        "Inconnue"     = 1.0
    }

    # Largeur minimale des moustaches (en pourcentage de la largeur de la boîte)
    "WhiskerWidthRatio"         = @{
        "Très étroites" = 0.3   # 30% de la largeur de la boîte
        "Étroites"      = 0.5   # 50% de la largeur de la boîte
        "Standard"      = 0.7   # 70% de la largeur de la boîte
        "Larges"        = 0.9   # 90% de la largeur de la boîte
        "Très larges"   = 1.0   # 100% de la largeur de la boîte
    }

    # Épaisseur minimale des lignes (en pixels) par résolution
    "MinLineThicknessByDPI"     = @{
        "Basse (72 DPI)"       = 1
        "Moyenne (150 DPI)"    = 1.5
        "Haute (300 DPI)"      = 2
        "Très haute (600 DPI)" = 3
    }

    # Recommandations pour la lisibilité des outliers
    "OutlierRecommendations"    = @{
        "Très peu (<5)"        = "Points individuels de grande taille (6-8px)"
        "Peu (5-15)"           = "Points individuels de taille moyenne (4-6px)"
        "Moyen (16-50)"        = "Points individuels de petite taille (3-4px) avec transparence"
        "Nombreux (51-200)"    = "Points avec transparence élevée ou regroupement par densité"
        "Très nombreux (>200)" = "Heatmap ou contours de densité au lieu de points individuels"
    }

    # Recommandations pour l'espacement entre les boîtes (en pourcentage de la largeur des boîtes)
    "BoxSpacingRatio"           = @{
        "Très serré" = 0.2   # 20% de la largeur des boîtes
        "Serré"      = 0.5   # 50% de la largeur des boîtes
        "Standard"   = 0.8   # 80% de la largeur des boîtes
        "Large"      = 1.2   # 120% de la largeur des boîtes
        "Très large" = 2.0   # 200% de la largeur des boîtes
    }
}

# Recommandations spécifiques pour la largeur de bin par type de distribution
$script:BinWidthRecommendations = @{
    "Normale"       = @{
        "Description"           = "Distribution symétrique en forme de cloche"
        "OptimalMethod"         = "Scott"
        "Formula"               = "h = 3.5 * std / (n^(1/3))"
        "Recommendations"       = @{
            "Très petit (< 30)"   = "Utiliser la règle de Sturges avec un facteur d'ajustement de 0.9"
            "Petit (30-100)"      = "Utiliser la règle de Scott si l'écart-type est connu, sinon Sturges"
            "Moyen (100-500)"     = "La règle de Scott est optimale"
            "Grand (500-1000)"    = "La règle de Scott est optimale"
            "Très grand (> 1000)" = "La règle de Scott est optimale, mais peut être coûteuse en calcul"
        }
        "SpecialConsiderations" = @(
            "Pour les distributions parfaitement normales, la règle de Scott est optimale",
            "Si la distribution est approximativement normale, un léger ajustement peut être nécessaire",
            "Pour les petits échantillons, privilégier la lisibilité à la précision statistique"
        )
    }
    "Asymétrique"   = @{
        "Description"           = "Distribution avec une queue plus longue d'un côté"
        "OptimalMethod"         = "Freedman-Diaconis"
        "Formula"               = "h = 2 * IQR / (n^(1/3))"
        "Recommendations"       = @{
            "Très petit (< 30)"   = "Utiliser la règle de Doane, qui tient compte de l'asymétrie"
            "Petit (30-100)"      = "Utiliser la règle de Freedman-Diaconis si l'IQR est connu, sinon Doane"
            "Moyen (100-500)"     = "La règle de Freedman-Diaconis est optimale"
            "Grand (500-1000)"    = "La règle de Freedman-Diaconis est optimale"
            "Très grand (> 1000)" = "La règle de Freedman-Diaconis est optimale"
        }
        "SpecialConsiderations" = @(
            "Pour les distributions fortement asymétriques, envisager une transformation logarithmique",
            "L'IQR est plus robuste que l'écart-type pour les distributions asymétriques",
            "Considérer des bins de largeur variable pour les distributions très asymétriques"
        )
    }
    "Multimodale"   = @{
        "Description"           = "Distribution avec plusieurs pics"
        "OptimalMethod"         = "Freedman-Diaconis"
        "Formula"               = "h = 2 * IQR / (n^(1/3))"
        "Recommendations"       = @{
            "Très petit (< 30)"   = "Utiliser la règle de Rice avec un facteur d'ajustement de 1.2"
            "Petit (30-100)"      = "Utiliser la règle de Freedman-Diaconis avec un facteur d'ajustement de 1.2"
            "Moyen (100-500)"     = "La règle de Freedman-Diaconis avec un facteur d'ajustement de 1.3"
            "Grand (500-1000)"    = "La règle de Freedman-Diaconis avec un facteur d'ajustement de 1.4"
            "Très grand (> 1000)" = "La règle de Freedman-Diaconis avec un facteur d'ajustement de 1.5"
        }
        "SpecialConsiderations" = @(
            "Augmenter le nombre de bins pour mieux distinguer les modes",
            "Envisager des méthodes de décomposition pour identifier les sous-distributions",
            "Pour les distributions avec des modes très séparés, envisager des histogrammes séparés"
        )
    }
    "Queue lourde"  = @{
        "Description"           = "Distribution avec des queues plus épaisses qu'une distribution normale"
        "OptimalMethod"         = "Freedman-Diaconis"
        "Formula"               = "h = 2 * IQR / (n^(1/3))"
        "Recommendations"       = @{
            "Très petit (< 30)"   = "Utiliser la règle de Doane avec un facteur d'ajustement de 1.1"
            "Petit (30-100)"      = "Utiliser la règle de Freedman-Diaconis si l'IQR est connu, sinon Doane"
            "Moyen (100-500)"     = "La règle de Freedman-Diaconis est optimale"
            "Grand (500-1000)"    = "La règle de Freedman-Diaconis est optimale"
            "Très grand (> 1000)" = "La règle de Freedman-Diaconis est optimale"
        }
        "SpecialConsiderations" = @(
            "L'IQR est plus robuste que l'écart-type pour les distributions à queue lourde",
            "Envisager une échelle logarithmique pour les valeurs extrêmes",
            "Pour les distributions avec des valeurs aberrantes, utiliser des méthodes robustes"
        )
    }
    "Uniforme"      = @{
        "Description"           = "Distribution où toutes les valeurs ont la même probabilité"
        "OptimalMethod"         = "Square-root"
        "Formula"               = "k = ceiling(sqrt(n))"
        "Recommendations"       = @{
            "Très petit (< 30)"   = "Utiliser la règle de la racine carrée"
            "Petit (30-100)"      = "Utiliser la règle de la racine carrée"
            "Moyen (100-500)"     = "Utiliser la règle de la racine carrée avec un facteur d'ajustement de 0.9"
            "Grand (500-1000)"    = "Utiliser la règle de la racine carrée avec un facteur d'ajustement de 0.8"
            "Très grand (> 1000)" = "Utiliser la règle de la racine carrée avec un facteur d'ajustement de 0.7"
        }
        "SpecialConsiderations" = @(
            "Pour les distributions uniformes, des bins de largeur égale sont optimaux",
            "Moins de bins sont généralement nécessaires pour les distributions uniformes",
            "Vérifier si la distribution est réellement uniforme avant d'appliquer ces recommandations"
        )
    }
    "Exponentielle" = @{
        "Description"           = "Distribution avec une décroissance exponentielle"
        "OptimalMethod"         = "Freedman-Diaconis"
        "Formula"               = "h = 2 * IQR / (n^(1/3))"
        "Recommendations"       = @{
            "Très petit (< 30)"   = "Utiliser la règle de Rice avec un facteur d'ajustement de 1.2"
            "Petit (30-100)"      = "Utiliser la règle de Freedman-Diaconis si l'IQR est connu, sinon Rice"
            "Moyen (100-500)"     = "La règle de Freedman-Diaconis est optimale"
            "Grand (500-1000)"    = "La règle de Freedman-Diaconis est optimale"
            "Très grand (> 1000)" = "La règle de Freedman-Diaconis est optimale"
        }
        "SpecialConsiderations" = @(
            "Envisager une échelle logarithmique ou des bins de largeur variable",
            "Pour les distributions exponentielles, les petites valeurs sont plus fréquentes",
            "Considérer des bins plus étroits pour les petites valeurs et plus larges pour les grandes valeurs"
        )
    }
    "Inconnue"      = @{
        "Description"           = "Distribution dont le type n'est pas connu a priori"
        "OptimalMethod"         = "Sturges"
        "Formula"               = "k = ceiling(log2(n) + 1)"
        "Recommendations"       = @{
            "Très petit (< 30)"   = "Utiliser la règle de la racine carrée"
            "Petit (30-100)"      = "Utiliser la règle de Sturges"
            "Moyen (100-500)"     = "Utiliser la règle de Freedman-Diaconis si l'IQR est connu, sinon Sturges"
            "Grand (500-1000)"    = "Utiliser la règle de Freedman-Diaconis si l'IQR est connu, sinon Rice"
            "Très grand (> 1000)" = "Utiliser la règle de Freedman-Diaconis si l'IQR est connu, sinon Rice"
        }
        "SpecialConsiderations" = @(
            "Commencer par explorer la distribution avec différentes largeurs de bin",
            "Ajuster en fonction des caractéristiques observées",
            "Privilégier les méthodes robustes en l'absence d'information sur la distribution"
        )
    }
}

#endregion

#region Fonctions principales

<#
.SYNOPSIS
    Détermine le nombre minimal de bins pour un histogramme en fonction de la taille d'échantillon.

.DESCRIPTION
    Cette fonction calcule le nombre minimal recommandé de bins (classes) pour un histogramme
    en fonction de la taille d'échantillon, du type de distribution et d'autres paramètres.
    Elle implémente plusieurs règles classiques de binning et fournit des recommandations adaptées.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER Method
    La méthode de calcul à utiliser (par défaut "Auto").

.PARAMETER StandardDeviation
    L'écart-type de l'échantillon (requis pour certaines méthodes).

.PARAMETER IQR
    L'écart interquartile de l'échantillon (requis pour certaines méthodes).

.PARAMETER Skewness
    Le coefficient d'asymétrie de l'échantillon (requis pour certaines méthodes).

.PARAMETER MinimumBins
    Le nombre minimal de bins à considérer, quelle que soit la méthode (par défaut 5).

.PARAMETER MaximumBins
    Le nombre maximal de bins à considérer, quelle que soit la méthode (par défaut 100).

.EXAMPLE
    Get-HistogramBinCount -SampleSize 100 -DataDistribution "Normale"
    Calcule le nombre recommandé de bins pour un échantillon de 100 observations avec une distribution normale.

.EXAMPLE
    Get-HistogramBinCount -SampleSize 500 -DataDistribution "Asymétrique" -Method "Freedman-Diaconis" -IQR 15.2
    Calcule le nombre de bins en utilisant la règle de Freedman-Diaconis pour un échantillon asymétrique.

.OUTPUTS
    System.Int32
#>
function Get-HistogramBinCount {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Sturges", "Scott", "Freedman-Diaconis", "Rice", "Doane", "Square-root")]
        [string]$Method = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$StandardDeviation = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$IQR = 0,

        [Parameter(Mandatory = $false)]
        [double]$Skewness = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$MinimumBins = 5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(5, [int]::MaxValue)]
        [int]$MaximumBins = 100
    )

    # Déterminer la méthode appropriée si "Auto" est spécifié
    if ($Method -eq "Auto") {
        $Method = switch ($DataDistribution) {
            "Normale" {
                if ($SampleSize -ge 50) { "Scott" } else { "Sturges" }
            }
            "Asymétrique" {
                if ($SampleSize -ge 50 -and $IQR -gt 0) { "Freedman-Diaconis" } else { "Doane" }
            }
            "Multimodale" {
                if ($SampleSize -ge 100) { "Freedman-Diaconis" } else { "Rice" }
            }
            "Queue lourde" {
                if ($IQR -gt 0) { "Freedman-Diaconis" } else { "Doane" }
            }
            "Uniforme" { "Square-root" }
            "Exponentielle" {
                if ($SampleSize -ge 50) { "Freedman-Diaconis" } else { "Rice" }
            }
            default {
                if ($SampleSize -lt 30) { "Square-root" } else { "Sturges" }
            }
        }
    }

    # Vérifier si les paramètres requis sont fournis pour la méthode choisie
    if ($Method -eq "Scott" -and $StandardDeviation -eq 0) {
        Write-Warning "La méthode de Scott nécessite l'écart-type. Utilisation de la méthode de Sturges à la place."
        $Method = "Sturges"
    } elseif ($Method -eq "Freedman-Diaconis" -and $IQR -eq 0) {
        Write-Warning "La méthode de Freedman-Diaconis nécessite l'écart interquartile. Utilisation de la méthode de Rice à la place."
        $Method = "Rice"
    } elseif ($Method -eq "Doane" -and $Skewness -eq 0) {
        Write-Warning "La méthode de Doane nécessite le coefficient d'asymétrie. Utilisation de la méthode de Sturges à la place."
        $Method = "Sturges"
    }

    # Calculer le nombre de bins selon la méthode choisie
    $binCount = switch ($Method) {
        "Sturges" {
            [Math]::Ceiling([Math]::Log($SampleSize, 2) + 1)
        }
        "Scott" {
            $binWidth = 3.5 * $StandardDeviation / [Math]::Pow($SampleSize, 1 / 3)
            # Supposons que les données s'étendent sur 4 écarts-types de chaque côté de la moyenne
            $range = 8 * $StandardDeviation
            [Math]::Ceiling($range / $binWidth)
        }
        "Freedman-Diaconis" {
            $binWidth = 2 * $IQR / [Math]::Pow($SampleSize, 1 / 3)
            # Supposons que les données s'étendent sur 1.5 IQR de chaque côté des quartiles
            $range = $IQR + 3 * $IQR
            [Math]::Ceiling($range / $binWidth)
        }
        "Rice" {
            [Math]::Ceiling(2 * [Math]::Pow($SampleSize, 1 / 3))
        }
        "Doane" {
            $sigmaG1 = [Math]::Sqrt(6 * ($SampleSize - 2) / (($SampleSize + 1) * ($SampleSize + 3)))
            [Math]::Ceiling(1 + [Math]::Log($SampleSize, [Math]::E) + [Math]::Log(1 + [Math]::Abs($Skewness) / $sigmaG1, [Math]::E))
        }
        "Square-root" {
            [Math]::Ceiling([Math]::Sqrt($SampleSize))
        }
    }

    # Appliquer le facteur d'ajustement selon le type de distribution
    $adjustmentFactor = $script:DistributionAdjustmentFactors[$DataDistribution]
    $adjustedBinCount = [Math]::Ceiling($binCount * $adjustmentFactor)

    # Appliquer les limites minimales et maximales
    $finalBinCount = [Math]::Max($MinimumBins, [Math]::Min($adjustedBinCount, $MaximumBins))

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Vérifier si le nombre de bins est inférieur au minimum recommandé pour cette taille d'échantillon
    $minRecommendedBins = $script:MinBinsBySize[$sizeCategory]
    if ($finalBinCount -lt $minRecommendedBins) {
        Write-Verbose "Le nombre calculé de bins ($finalBinCount) est inférieur au minimum recommandé pour un échantillon de taille $sizeCategory ($minRecommendedBins). Ajustement à la valeur minimale recommandée."
        $finalBinCount = $minRecommendedBins
    }

    return $finalBinCount
}

<#
.SYNOPSIS
    Détermine la largeur optimale des bins pour un histogramme.

.DESCRIPTION
    Cette fonction calcule la largeur optimale des bins pour un histogramme
    en fonction de la taille d'échantillon, de l'étendue des données et d'autres paramètres.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER DataRange
    L'étendue des données (valeur maximale - valeur minimale).

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER Method
    La méthode de calcul à utiliser (par défaut "Auto").

.PARAMETER StandardDeviation
    L'écart-type de l'échantillon (requis pour certaines méthodes).

.PARAMETER IQR
    L'écart interquartile de l'échantillon (requis pour certaines méthodes).

.PARAMETER BinCount
    Le nombre de bins souhaité (si spécifié, la largeur sera calculée en conséquence).

.EXAMPLE
    Get-HistogramBinWidth -SampleSize 100 -DataRange 50 -DataDistribution "Normale" -StandardDeviation 10
    Calcule la largeur optimale des bins pour un échantillon de 100 observations avec une étendue de 50.

.OUTPUTS
    System.Double
#>
function Get-HistogramBinWidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$DataRange,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Sturges", "Scott", "Freedman-Diaconis", "Rice", "Doane", "Square-root")]
        [string]$Method = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$StandardDeviation = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$IQR = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$BinCount = 0
    )

    # Si un nombre de bins est spécifié, calculer directement la largeur
    if ($BinCount -gt 0) {
        return $DataRange / $BinCount
    }

    # Sinon, calculer d'abord le nombre de bins recommandé
    $recommendedBinCount = Get-HistogramBinCount -SampleSize $SampleSize -DataDistribution $DataDistribution -Method $Method -StandardDeviation $StandardDeviation -IQR $IQR

    # Puis calculer la largeur correspondante
    $binWidth = $DataRange / $recommendedBinCount

    return $binWidth
}

#endregion

<#
.SYNOPSIS
    Obtient les recommandations de largeur de bin optimale selon la distribution.

.DESCRIPTION
    Cette fonction fournit des recommandations détaillées pour la largeur de bin optimale
    en fonction du type de distribution et de la taille d'échantillon.

.PARAMETER DataDistribution
    Le type de distribution des données.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER IncludeSpecialConsiderations
    Indique si les considérations spéciales doivent être incluses dans les résultats (par défaut $true).

.EXAMPLE
    Get-OptimalBinWidthRecommendation -DataDistribution "Normale" -SampleSize 200
    Obtient les recommandations pour une distribution normale avec un échantillon de 200 observations.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-OptimalBinWidthRecommendation {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")]
        [string]$DataDistribution,

        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeSpecialConsiderations = $true
    )

    # Vérifier si la distribution est supportée
    if (-not $script:BinWidthRecommendations.ContainsKey($DataDistribution)) {
        Write-Warning "La distribution '$DataDistribution' n'est pas supportée. Utilisation de 'Inconnue' à la place."
        $DataDistribution = "Inconnue"
    }

    # Obtenir les recommandations pour cette distribution
    $distributionRecommendations = $script:BinWidthRecommendations[$DataDistribution]

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Obtenir la recommandation spécifique pour cette taille d'échantillon
    $specificRecommendation = $distributionRecommendations.Recommendations[$sizeCategory]

    # Créer l'objet de résultat
    $result = @{
        Distribution   = $DataDistribution
        Description    = $distributionRecommendations.Description
        SampleSize     = $SampleSize
        SizeCategory   = $sizeCategory
        OptimalMethod  = $distributionRecommendations.OptimalMethod
        Formula        = $distributionRecommendations.Formula
        Recommendation = $specificRecommendation
    }

    # Ajouter les considérations spéciales si demandé
    if ($IncludeSpecialConsiderations) {
        $result.SpecialConsiderations = $distributionRecommendations.SpecialConsiderations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations de largeur de bin pour différentes distributions.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations de largeur de bin
    pour différentes distributions, en fonction de la taille d'échantillon spécifiée.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.PARAMETER IncludeSpecialConsiderations
    Indique si les considérations spéciales doivent être incluses dans le rapport (par défaut $true).

.EXAMPLE
    Get-BinWidthRecommendationReport -SampleSize 200 -Format "Text"
    Génère un rapport textuel des recommandations pour un échantillon de 200 observations.

.OUTPUTS
    System.String
#>
function Get-BinWidthRecommendationReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text",

        [Parameter(Mandatory = $false)]
        [bool]$IncludeSpecialConsiderations = $true
    )

    # Obtenir les recommandations pour chaque type de distribution
    $distributions = @("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")
    $recommendations = @{}

    foreach ($distribution in $distributions) {
        $recommendations[$distribution] = Get-OptimalBinWidthRecommendation -DataDistribution $distribution -SampleSize $SampleSize -IncludeSpecialConsiderations $IncludeSpecialConsiderations
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations de largeur de bin pour un échantillon de taille $SampleSize ===`n`n"

            foreach ($distribution in $distributions) {
                $rec = $recommendations[$distribution]
                $result += "## $distribution`n"
                $result += "Description: $($rec.Description)`n"
                $result += "Méthode optimale: $($rec.OptimalMethod)`n"
                $result += "Formule: $($rec.Formula)`n"
                $result += "Catégorie de taille: $($rec.SizeCategory)`n"
                $result += "Recommandation: $($rec.Recommendation)`n"

                if ($IncludeSpecialConsiderations) {
                    $result += "`nConsidérations spéciales:`n"
                    foreach ($consideration in $rec.SpecialConsiderations) {
                        $result += "- $consideration`n"
                    }
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "Distribution,Description,SampleSize,SizeCategory,OptimalMethod,Formula,Recommendation`n"

            foreach ($distribution in $distributions) {
                $rec = $recommendations[$distribution]
                $result += "$distribution,""$($rec.Description)"",$($rec.SampleSize),$($rec.SizeCategory),$($rec.OptimalMethod),""$($rec.Formula)"",""$($rec.Recommendation)""`n"
            }

            if ($IncludeSpecialConsiderations) {
                $result += "`nDistribution,SpecialConsideration`n"
                foreach ($distribution in $distributions) {
                    $rec = $recommendations[$distribution]
                    foreach ($consideration in $rec.SpecialConsiderations) {
                        $result += "$distribution,""$consideration""`n"
                    }
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations de largeur de bin</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".considerations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations de largeur de bin pour un échantillon de taille $SampleSize</h1>`n"

            $result += "<table>`n"
            $result += "<tr><th>Distribution</th><th>Description</th><th>Méthode optimale</th><th>Formule</th><th>Catégorie de taille</th><th>Recommandation</th></tr>`n"

            foreach ($distribution in $distributions) {
                $rec = $recommendations[$distribution]
                $result += "<tr><td>$distribution</td><td>$($rec.Description)</td><td>$($rec.OptimalMethod)</td><td>$($rec.Formula)</td><td>$($rec.SizeCategory)</td><td>$($rec.Recommendation)</td></tr>`n"
            }

            $result += "</table>`n"

            if ($IncludeSpecialConsiderations) {
                $result += "<h2>Considérations spéciales</h2>`n"

                foreach ($distribution in $distributions) {
                    $rec = $recommendations[$distribution]
                    $result += "<h3>$distribution</h3>`n"
                    $result += "<div class='considerations'>`n<ul>`n"

                    foreach ($consideration in $rec.SpecialConsiderations) {
                        $result += "<li>$consideration</li>`n"
                    }

                    $result += "</ul>`n</div>`n"
                }
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "SampleSize"      = $SampleSize
                "Recommendations" = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détermine la densité de points optimale pour les graphiques de dispersion.

.DESCRIPTION
    Cette fonction calcule la densité de points optimale pour un graphique de dispersion
    en fonction de la taille d'échantillon, de la taille du graphique, de la résolution
    et du type de distribution des données.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER PlotSize
    La taille du graphique en pixels (par défaut "Moyen (500x500)").

.PARAMETER DPI
    La résolution du graphique en points par pouce (par défaut "Moyenne (150 DPI)").

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER MaxPoints
    Le nombre maximal de points à afficher, quelle que soit la densité calculée (par défaut 0, pas de limite).

.EXAMPLE
    Get-ScatterPlotPointDensity -SampleSize 1000 -PlotSize "Grand (800x800)" -DPI "Haute (300 DPI)" -DataDistribution "Normale"
    Calcule la densité de points optimale pour un échantillon de 1000 observations avec une distribution normale.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ScatterPlotPointDensity {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Petit (300x300)", "Moyen (500x500)", "Grand (800x800)", "Très grand (1200x1200)")]
        [string]$PlotSize = "Moyen (500x500)",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Basse (72 DPI)", "Moyenne (150 DPI)", "Haute (300 DPI)", "Très haute (600 DPI)")]
        [string]$DPI = "Moyenne (150 DPI)",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Groupée", "Dispersée", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaxPoints = 0
    )

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Obtenir le nombre maximal de points recommandé pour cette taille de graphique
    $maxPointsForPlotSize = $script:ScatterPlotDensityRecommendations.MaxPointsByPlotSize[$PlotSize]

    # Obtenir la densité optimale de points par pouce carré pour cette résolution
    $optimalDensityPerSquareInch = $script:ScatterPlotDensityRecommendations.OptimalDensityByDPI[$DPI]

    # Obtenir le facteur d'ajustement pour ce type de distribution
    $distributionFactor = $script:ScatterPlotDensityRecommendations.DensityAdjustmentFactors[$DataDistribution]

    # Obtenir la stratégie d'échantillonnage pour cette taille d'échantillon
    $samplingStrategy = $script:ScatterPlotDensityRecommendations.SamplingStrategies[$sizeCategory]

    # Obtenir la stratégie pour éviter le chevauchement pour cette taille d'échantillon
    $overlapStrategy = $script:ScatterPlotDensityRecommendations.OverlapStrategies[$sizeCategory]

    # Calculer la taille du graphique en pouces
    $dpiValue = switch ($DPI) {
        "Basse (72 DPI)" { 72 }
        "Moyenne (150 DPI)" { 150 }
        "Haute (300 DPI)" { 300 }
        "Très haute (600 DPI)" { 600 }
        default { 150 }
    }

    $plotSizePixels = switch ($PlotSize) {
        "Petit (300x300)" { @(300, 300) }
        "Moyen (500x500)" { @(500, 500) }
        "Grand (800x800)" { @(800, 800) }
        "Très grand (1200x1200)" { @(1200, 1200) }
        default { @(500, 500) }
    }

    $plotWidthInches = $plotSizePixels[0] / $dpiValue
    $plotHeightInches = $plotSizePixels[1] / $dpiValue
    $plotAreaSquareInches = $plotWidthInches * $plotHeightInches

    # Calculer le nombre optimal de points basé sur la densité
    $optimalPointCount = [Math]::Ceiling($optimalDensityPerSquareInch * $plotAreaSquareInches * $distributionFactor)

    # Limiter le nombre de points au maximum recommandé pour cette taille de graphique
    $recommendedPointCount = [Math]::Min($optimalPointCount, $maxPointsForPlotSize)

    # Limiter le nombre de points au maximum spécifié par l'utilisateur (si > 0)
    if ($MaxPoints -gt 0) {
        $recommendedPointCount = [Math]::Min($recommendedPointCount, $MaxPoints)
    }

    # Limiter le nombre de points à la taille de l'échantillon
    $finalPointCount = [Math]::Min($recommendedPointCount, $SampleSize)

    # Calculer le pourcentage de l'échantillon à afficher
    $samplePercentage = if ($SampleSize -gt 0) {
        [Math]::Round(($finalPointCount / $SampleSize) * 100, 2)
    } else {
        0
    }

    # Calculer la densité finale de points par pouce carré
    $finalDensity = if ($plotAreaSquareInches -gt 0) {
        [Math]::Round($finalPointCount / $plotAreaSquareInches, 2)
    } else {
        0
    }

    # Déterminer si un échantillonnage est nécessaire
    $samplingRequired = $finalPointCount -lt $SampleSize

    # Générer des recommandations spécifiques
    $recommendations = @()

    if ($samplingRequired) {
        $recommendations += "Échantillonnage recommandé: afficher $finalPointCount points sur $SampleSize ($samplePercentage%)."

        if ($sizeCategory -eq "Moyen (100-500)") {
            $recommendations += "Utiliser un échantillonnage aléatoire simple pour préserver la distribution."
        } elseif ($sizeCategory -eq "Grand (500-1000)") {
            $recommendations += "Utiliser un échantillonnage stratifié pour préserver les caractéristiques importantes."
        } elseif ($sizeCategory -eq "Très grand (> 1000)") {
            $recommendations += "Envisager une heatmap ou des contours de densité au lieu d'un nuage de points."
            $recommendations += "Si un nuage de points est nécessaire, utiliser un échantillonnage stratifié ou clustering."
        }
    } else {
        $recommendations += "Afficher tous les points ($SampleSize)."
    }

    # Recommandations pour éviter le chevauchement
    if ($sizeCategory -eq "Petit (30-100)") {
        $recommendations += "Si des chevauchements sont observés, appliquer un jittering léger (±1-2%)."
    } elseif ($sizeCategory -eq "Moyen (100-500)") {
        $recommendations += "Appliquer un jittering modéré (±2-3%) et/ou une transparence (alpha = 0.6-0.8)."
    } elseif ($sizeCategory -eq "Grand (500-1000)") {
        $recommendations += "Utiliser une transparence élevée (alpha = 0.4-0.6) et réduire la taille des points."
    } elseif ($sizeCategory -eq "Très grand (> 1000)") {
        $recommendations += "Utiliser une transparence très élevée (alpha = 0.2-0.4) ou passer à une heatmap."
    }

    # Recommandations spécifiques au type de distribution
    if ($DataDistribution -eq "Groupée") {
        $recommendations += "Pour les données groupées, augmenter la transparence et réduire davantage la taille des points dans les zones denses."
    } elseif ($DataDistribution -eq "Dispersée") {
        $recommendations += "Pour les données dispersées, conserver une taille de point plus grande pour améliorer la visibilité."
    } elseif ($DataDistribution -eq "Multimodale") {
        $recommendations += "Pour les distributions multimodales, envisager un codage couleur par groupe ou cluster."
    }

    # Créer l'objet de résultat
    $result = @{
        SampleSize                  = $SampleSize
        SizeCategory                = $sizeCategory
        PlotSize                    = $PlotSize
        PlotDimensions              = @{
            WidthPixels      = $plotSizePixels[0]
            HeightPixels     = $plotSizePixels[1]
            WidthInches      = $plotWidthInches
            HeightInches     = $plotHeightInches
            AreaSquareInches = $plotAreaSquareInches
        }
        DPI                         = $DPI
        DPIValue                    = $dpiValue
        DataDistribution            = $DataDistribution
        DistributionFactor          = $distributionFactor
        OptimalDensityPerSquareInch = $optimalDensityPerSquareInch
        OptimalPointCount           = $optimalPointCount
        MaxPointsForPlotSize        = $maxPointsForPlotSize
        UserMaxPoints               = $MaxPoints
        RecommendedPointCount       = $finalPointCount
        SamplePercentage            = $samplePercentage
        FinalDensity                = $finalDensity
        SamplingRequired            = $samplingRequired
        SamplingStrategy            = $samplingStrategy
        OverlapStrategy             = $overlapStrategy
        Recommendations             = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations de densité de points pour différentes tailles d'échantillon.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations de densité de points
    pour différentes tailles d'échantillon, en fonction de la taille du graphique,
    de la résolution et du type de distribution des données.

.PARAMETER PlotSize
    La taille du graphique en pixels (par défaut "Moyen (500x500)").

.PARAMETER DPI
    La résolution du graphique en points par pouce (par défaut "Moyenne (150 DPI)").

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-ScatterPlotDensityReport -PlotSize "Grand (800x800)" -DPI "Haute (300 DPI)" -DataDistribution "Normale" -Format "Text"
    Génère un rapport textuel des recommandations de densité de points pour différentes tailles d'échantillon.

.OUTPUTS
    System.String
#>
function Get-ScatterPlotDensityReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Petit (300x300)", "Moyen (500x500)", "Grand (800x800)", "Très grand (1200x1200)")]
        [string]$PlotSize = "Moyen (500x500)",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Basse (72 DPI)", "Moyenne (150 DPI)", "Haute (300 DPI)", "Très haute (600 DPI)")]
        [string]$DPI = "Moyenne (150 DPI)",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Groupée", "Dispersée", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les tailles d'échantillon à analyser
    $sampleSizes = @(20, 50, 100, 200, 500, 1000, 5000, 10000)
    $recommendations = @{}

    # Obtenir les recommandations pour chaque taille d'échantillon
    foreach ($sampleSize in $sampleSizes) {
        $recommendations["$sampleSize"] = Get-ScatterPlotPointDensity -SampleSize $sampleSize -PlotSize $PlotSize -DPI $DPI -DataDistribution $DataDistribution
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations de densité de points pour graphiques de dispersion ===`n`n"
            $result += "Taille du graphique: $PlotSize`n"
            $result += "Résolution: $DPI`n"
            $result += "Type de distribution: $DataDistribution`n`n"

            $result += "| Taille d'échantillon | Catégorie | Points recommandés | % de l'échantillon | Densité (pts/in²) | Échantillonnage |`n"
            $result += "|---------------------|-----------|-------------------|-------------------|-----------------|----------------|`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $samplingRequiredText = if ($rec.SamplingRequired -eq $true) { 'Oui' } else { 'Non' }
                $result += "| $($rec.SampleSize) | $($rec.SizeCategory) | $($rec.RecommendedPointCount) | $($rec.SamplePercentage)% | $($rec.FinalDensity) | $samplingRequiredText |`n"
            }

            $result += "`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "## Taille d'échantillon: $($rec.SampleSize)`n"
                $result += "Stratégie d'échantillonnage: $($rec.SamplingStrategy)`n"
                $result += "Stratégie anti-chevauchement: $($rec.OverlapStrategy)`n"

                $result += "Recommandations:`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "- $recommendation`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "SampleSize,Category,RecommendedPoints,SamplePercentage,Density,SamplingRequired,SamplingStrategy,OverlapStrategy`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "$($rec.SampleSize),$($rec.SizeCategory),$($rec.RecommendedPointCount),$($rec.SamplePercentage),$($rec.FinalDensity),$($rec.SamplingRequired),$($rec.SamplingStrategy),$($rec.OverlapStrategy)`n"
            }

            $result += "`nSampleSize,Recommendation`n"
            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "$($rec.SampleSize),""$recommendation""`n"
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations de densité de points</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations de densité de points pour graphiques de dispersion</h1>`n"
            $result += "<p><strong>Taille du graphique:</strong> $PlotSize</p>`n"
            $result += "<p><strong>Résolution:</strong> $DPI</p>`n"
            $result += "<p><strong>Type de distribution:</strong> $DataDistribution</p>`n"

            $result += "<table>`n"
            $result += "<tr><th>Taille d'échantillon</th><th>Catégorie</th><th>Points recommandés</th><th>% de l'échantillon</th><th>Densité (pts/in²)</th><th>Échantillonnage</th></tr>`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $samplingRequiredText = if ($rec.SamplingRequired -eq $true) { 'Oui' } else { 'Non' }
                $result += "<tr><td>$($rec.SampleSize)</td><td>$($rec.SizeCategory)</td><td>$($rec.RecommendedPointCount)</td><td>$($rec.SamplePercentage)%</td><td>$($rec.FinalDensity)</td><td>$samplingRequiredText</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "<h2>Taille d'échantillon: $($rec.SampleSize)</h2>`n"
                $result += "<p><strong>Stratégie d'échantillonnage:</strong> $($rec.SamplingStrategy)</p>`n"
                $result += "<p><strong>Stratégie anti-chevauchement:</strong> $($rec.OverlapStrategy)</p>`n"

                $result += "<div class='recommendations'>`n<h3>Recommandations:</h3>`n<ul>`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "<li>$recommendation</li>`n"
                }
                $result += "</ul>`n</div>`n"
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "PlotSize"         = $PlotSize
                "DPI"              = $DPI
                "DataDistribution" = $DataDistribution
                "Recommendations"  = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détermine les paramètres de jittering optimaux pour éviter le chevauchement des points.

.DESCRIPTION
    Cette fonction calcule les paramètres de jittering optimaux pour éviter le chevauchement
    des points dans un graphique de dispersion, en fonction de la taille d'échantillon,
    de la densité de points, du type de distribution et du type de graphique.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER PlotType
    Le type de graphique (par défaut "Nuage de points standard").

.PARAMETER DataRange
    L'étendue des données (valeur maximale - valeur minimale) pour chaque axe.
    Tableau de deux valeurs [étendue X, étendue Y].

.PARAMETER PointDensity
    La densité de points par pixel carré (par défaut 0, calculée automatiquement).

.PARAMETER PlotSize
    La taille du graphique en pixels (par défaut "Moyen (500x500)").

.EXAMPLE
    Get-JitteringParameters -SampleSize 500 -DataDistribution "Normale" -PlotType "Nuage de points standard" -DataRange @(100, 50)
    Calcule les paramètres de jittering optimaux pour un échantillon de 500 observations avec une distribution normale.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-JitteringParameters {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Groupée", "Dispersée", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Nuage de points standard", "Nuage de points catégoriel", "Boîte à moustaches", "Graphique en bâtons", "Graphique temporel")]
        [string]$PlotType = "Nuage de points standard",

        [Parameter(Mandatory = $true)]
        [ValidateCount(2, 2)]
        [double[]]$DataRange,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [double]::MaxValue)]
        [double]$PointDensity = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Petit (300x300)", "Moyen (500x500)", "Grand (800x800)", "Très grand (1200x1200)")]
        [string]$PlotSize = "Moyen (500x500)"
    )

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Obtenir l'amplitude de jittering recommandée pour cette taille d'échantillon
    $baseJitterAmplitude = $script:JitteringRecommendations.JitterAmplitudeBySize[$sizeCategory]

    # Obtenir le facteur d'ajustement pour ce type de distribution
    $distributionFactor = $script:JitteringRecommendations.JitterFactorByDistribution[$DataDistribution]

    # Obtenir le type de distribution de jittering recommandé
    $jitterDistribution = $script:JitteringRecommendations.JitterDistributionType[$DataDistribution]

    # Obtenir les directions de jittering recommandées
    $jitterDirections = $script:JitteringRecommendations.JitterDirections[$PlotType]

    # Calculer la taille du graphique en pixels
    $plotSizePixels = switch ($PlotSize) {
        "Petit (300x300)" { @(300, 300) }
        "Moyen (500x500)" { @(500, 500) }
        "Grand (800x800)" { @(800, 800) }
        "Très grand (1200x1200)" { @(1200, 1200) }
        default { @(500, 500) }
    }

    # Calculer la densité de points si elle n'est pas spécifiée
    if ($PointDensity -eq 0) {
        $plotArea = $plotSizePixels[0] * $plotSizePixels[1]
        $PointDensity = $SampleSize / $plotArea
    }

    # Déterminer la catégorie de densité de points
    $densityCategory = switch ($PointDensity) {
        { $_ -lt 0.1 } { "Très faible (< 0.1 pts/px²)" }
        { $_ -ge 0.1 -and $_ -lt 0.2 } { "Faible (0.1-0.2 pts/px²)" }
        { $_ -ge 0.2 -and $_ -lt 0.5 } { "Moyenne (0.2-0.5 pts/px²)" }
        { $_ -ge 0.5 -and $_ -lt 1.0 } { "Élevée (0.5-1.0 pts/px²)" }
        default { "Très élevée (> 1.0 pts/px²)" }
    }

    # Obtenir la stratégie de jittering pour cette densité de points
    $jitterStrategy = $script:JitteringRecommendations.JitterStrategies[$densityCategory]

    # Obtenir les techniques complémentaires recommandées
    $complementaryTechniques = $script:JitteringRecommendations.ComplementaryTechniques[$sizeCategory]

    # Calculer l'amplitude de jittering finale (en pourcentage de l'étendue des données)
    $finalJitterAmplitude = $baseJitterAmplitude * $distributionFactor

    # Calculer les valeurs absolues de jittering pour chaque axe
    $jitterX = if ($jitterDirections -contains "X" -or $jitterDirections -eq "XY") {
        $DataRange[0] * $finalJitterAmplitude / 100
    } else {
        0
    }

    $jitterY = if ($jitterDirections -contains "Y" -or $jitterDirections -eq "XY") {
        $DataRange[1] * $finalJitterAmplitude / 100
    } else {
        0
    }

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur la densité de points
    $recommendations += "Stratégie de jittering: $jitterStrategy"

    # Recommandations basées sur le type de distribution
    if ($jitterDistribution -eq "Normale") {
        $recommendations += "Utiliser une distribution normale pour le jittering (plus de points près du centre, moins aux extrémités)"
    } else {
        $recommendations += "Utiliser une distribution uniforme pour le jittering (répartition égale dans toute la plage)"
    }

    # Recommandations basées sur les directions
    if ($jitterDirections -eq "XY") {
        $recommendations += "Appliquer le jittering dans les deux directions (X et Y)"
    } elseif ($jitterDirections -eq "X") {
        $recommendations += "Appliquer le jittering uniquement sur l'axe X"
    } elseif ($jitterDirections -eq "Y") {
        $recommendations += "Appliquer le jittering uniquement sur l'axe Y"
    }

    # Recommandations pour les techniques complémentaires
    $recommendations += "Techniques complémentaires recommandées:"
    foreach ($technique in $complementaryTechniques) {
        $recommendations += "- $technique"
    }

    # Créer l'objet de résultat
    $result = @{
        SampleSize              = $SampleSize
        SizeCategory            = $sizeCategory
        DataDistribution        = $DataDistribution
        PlotType                = $PlotType
        PlotSize                = $PlotSize
        DataRange               = $DataRange
        PointDensity            = $PointDensity
        DensityCategory         = $densityCategory
        JitterDistribution      = $jitterDistribution
        JitterDirections        = $jitterDirections
        BaseJitterAmplitude     = $baseJitterAmplitude
        DistributionFactor      = $distributionFactor
        FinalJitterAmplitude    = $finalJitterAmplitude
        JitterX                 = $jitterX
        JitterY                 = $jitterY
        JitterStrategy          = $jitterStrategy
        ComplementaryTechniques = $complementaryTechniques
        Recommendations         = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations de jittering pour différentes densités de points.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations de jittering
    pour différentes densités de points, en fonction du type de distribution et du type de graphique.

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER PlotType
    Le type de graphique (par défaut "Nuage de points standard").

.PARAMETER DataRange
    L'étendue des données (valeur maximale - valeur minimale) pour chaque axe.
    Tableau de deux valeurs [étendue X, étendue Y].

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-JitteringRecommendationReport -DataDistribution "Normale" -PlotType "Nuage de points standard" -DataRange @(100, 50) -Format "Text"
    Génère un rapport textuel des recommandations de jittering pour différentes densités de points.

.OUTPUTS
    System.String
#>
function Get-JitteringRecommendationReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Groupée", "Dispersée", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Nuage de points standard", "Nuage de points catégoriel", "Boîte à moustaches", "Graphique en bâtons", "Graphique temporel")]
        [string]$PlotType = "Nuage de points standard",

        [Parameter(Mandatory = $true)]
        [ValidateCount(2, 2)]
        [double[]]$DataRange,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les tailles d'échantillon à analyser
    $sampleSizes = @(20, 50, 100, 200, 500, 1000, 5000)
    $recommendations = @{}

    # Obtenir les recommandations pour chaque taille d'échantillon
    foreach ($sampleSize in $sampleSizes) {
        $recommendations["$sampleSize"] = Get-JitteringParameters -SampleSize $sampleSize -DataDistribution $DataDistribution -PlotType $PlotType -DataRange $DataRange
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations de jittering pour éviter le chevauchement des points ===`n`n"
            $result += "Type de distribution: $DataDistribution`n"
            $result += "Type de graphique: $PlotType`n"
            $result += "Étendue des données: X=$($DataRange[0]), Y=$($DataRange[1])`n`n"

            $result += "| Taille d'échantillon | Catégorie | Densité (pts/px²) | Amplitude | Jitter X | Jitter Y | Distribution |`n"
            $result += "|---------------------|-----------|-------------------|-----------|----------|----------|--------------|`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "| $($rec.SampleSize) | $($rec.SizeCategory) | $([Math]::Round($rec.PointDensity, 4)) | $($rec.FinalJitterAmplitude)% | $([Math]::Round($rec.JitterX, 2)) | $([Math]::Round($rec.JitterY, 2)) | $($rec.JitterDistribution) |`n"
            }

            $result += "`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "## Taille d'échantillon: $($rec.SampleSize)`n"
                $result += "Catégorie de densité: $($rec.DensityCategory)`n"
                $result += "Directions de jittering: $($rec.JitterDirections)`n"
                $result += "Stratégie: $($rec.JitterStrategy)`n"

                $result += "Recommandations:`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "- $recommendation`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "SampleSize,SizeCategory,PointDensity,DensityCategory,JitterAmplitude,JitterX,JitterY,JitterDistribution,JitterDirections,JitterStrategy`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "$($rec.SampleSize),$($rec.SizeCategory),$($rec.PointDensity),$($rec.DensityCategory),$($rec.FinalJitterAmplitude),$($rec.JitterX),$($rec.JitterY),$($rec.JitterDistribution),$($rec.JitterDirections),$($rec.JitterStrategy)`n"
            }

            $result += "`nSampleSize,Recommendation`n"
            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "$($rec.SampleSize),""$recommendation""`n"
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations de jittering</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations de jittering pour éviter le chevauchement des points</h1>`n"
            $result += "<p><strong>Type de distribution:</strong> $DataDistribution</p>`n"
            $result += "<p><strong>Type de graphique:</strong> $PlotType</p>`n"
            $result += "<p><strong>Étendue des données:</strong> X=$($DataRange[0]), Y=$($DataRange[1])</p>`n"

            $result += "<table>`n"
            $result += "<tr><th>Taille d'échantillon</th><th>Catégorie</th><th>Densité (pts/px²)</th><th>Amplitude</th><th>Jitter X</th><th>Jitter Y</th><th>Distribution</th></tr>`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "<tr><td>$($rec.SampleSize)</td><td>$($rec.SizeCategory)</td><td>$([Math]::Round($rec.PointDensity, 4))</td><td>$($rec.FinalJitterAmplitude)%</td><td>$([Math]::Round($rec.JitterX, 2))</td><td>$([Math]::Round($rec.JitterY, 2))</td><td>$($rec.JitterDistribution)</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($sampleSize in $sampleSizes) {
                $rec = $recommendations["$sampleSize"]
                $result += "<h2>Taille d'échantillon: $($rec.SampleSize)</h2>`n"
                $result += "<p><strong>Catégorie de densité:</strong> $($rec.DensityCategory)</p>`n"
                $result += "<p><strong>Directions de jittering:</strong> $($rec.JitterDirections)</p>`n"
                $result += "<p><strong>Stratégie:</strong> $($rec.JitterStrategy)</p>`n"

                $result += "<div class='recommendations'>`n<h3>Recommandations:</h3>`n<ul>`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "<li>$recommendation</li>`n"
                }
                $result += "</ul>`n</div>`n"
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "DataDistribution" = $DataDistribution
                "PlotType"         = $PlotType
                "DataRange"        = $DataRange
                "Recommendations"  = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détermine la largeur minimale des boîtes pour les boîtes à moustaches.

.DESCRIPTION
    Cette fonction calcule la largeur minimale recommandée pour les boîtes à moustaches
    en fonction de la taille d'écran, du nombre de groupes, du type de distribution et d'autres paramètres.

.PARAMETER ScreenSize
    La taille d'écran (par défaut "Moyen (1280x720)").

.PARAMETER GroupCount
    Le nombre de groupes à comparer (par défaut 1).

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER PlotWidth
    La largeur du graphique en pixels (par défaut 0, calculée automatiquement).

.PARAMETER DPI
    La résolution du graphique en points par pouce (par défaut "Moyenne (150 DPI)").

.PARAMETER WhiskerStyle
    Le style des moustaches (par défaut "Standard").

.EXAMPLE
    Get-BoxplotMinWidth -ScreenSize "Moyen (1280x720)" -GroupCount 5 -DataDistribution "Normale"
    Calcule la largeur minimale recommandée pour les boîtes à moustaches pour 5 groupes avec une distribution normale.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-BoxplotMinWidth {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Petit (800x600)", "Moyen (1280x720)", "Grand (1920x1080)", "Très grand (2560x1440)")]
        [string]$ScreenSize = "Moyen (1280x720)",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$GroupCount = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$PlotWidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Basse (72 DPI)", "Moyenne (150 DPI)", "Haute (300 DPI)", "Très haute (600 DPI)")]
        [string]$DPI = "Moyenne (150 DPI)",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Très étroites", "Étroites", "Standard", "Larges", "Très larges")]
        [string]$WhiskerStyle = "Standard"
    )

    # Obtenir la largeur minimale des boîtes pour cette taille d'écran
    $minBoxWidthByScreen = $script:BoxplotRecommendations.MinBoxWidthByScreenSize[$ScreenSize]

    # Déterminer la catégorie de nombre de groupes
    $groupCategory = switch ($GroupCount) {
        { $_ -le 3 } { "Très peu (1-3)" }
        { $_ -ge 4 -and $_ -le 7 } { "Peu (4-7)" }
        { $_ -ge 8 -and $_ -le 15 } { "Moyen (8-15)" }
        { $_ -ge 16 -and $_ -le 30 } { "Nombreux (16-30)" }
        default { "Très nombreux (>30)" }
    }

    # Obtenir le pourcentage minimal de largeur pour ce nombre de groupes
    $minWidthPercentage = $script:BoxplotRecommendations.MinBoxWidthByGroupCount[$groupCategory]

    # Obtenir le facteur d'ajustement pour ce type de distribution
    $distributionFactor = $script:BoxplotRecommendations.BoxWidthAdjustmentFactors[$DataDistribution]

    # Obtenir le ratio de largeur des moustaches
    $whiskerWidthRatio = $script:BoxplotRecommendations.WhiskerWidthRatio[$WhiskerStyle]

    # Obtenir l'épaisseur minimale des lignes pour cette résolution
    $minLineThickness = $script:BoxplotRecommendations.MinLineThicknessByDPI[$DPI]

    # Calculer la largeur du graphique si elle n'est pas spécifiée
    if ($PlotWidth -eq 0) {
        $screenSizePixels = switch ($ScreenSize) {
            "Petit (800x600)" { 800 }
            "Moyen (1280x720)" { 1280 }
            "Grand (1920x1080)" { 1920 }
            "Très grand (2560x1440)" { 2560 }
            default { 1280 }
        }

        # Supposons que le graphique occupe 80% de la largeur de l'écran
        $PlotWidth = [Math]::Floor($screenSizePixels * 0.8)
    }

    # Calculer la largeur minimale des boîtes basée sur le pourcentage de la largeur du graphique
    $minBoxWidthByPercentage = [Math]::Floor($PlotWidth * $minWidthPercentage / 100)

    # Prendre la valeur maximale entre la largeur minimale par taille d'écran et par pourcentage
    $baseMinBoxWidth = [Math]::Max($minBoxWidthByScreen, $minBoxWidthByPercentage)

    # Appliquer le facteur d'ajustement pour le type de distribution
    $adjustedMinBoxWidth = [Math]::Ceiling($baseMinBoxWidth * $distributionFactor)

    # Calculer la largeur minimale des moustaches
    $minWhiskerWidth = [Math]::Ceiling($adjustedMinBoxWidth * $whiskerWidthRatio)

    # Calculer l'espacement recommandé entre les boîtes (standard)
    $recommendedSpacing = [Math]::Ceiling($adjustedMinBoxWidth * $script:BoxplotRecommendations.BoxSpacingRatio["Standard"])

    # Calculer la largeur totale nécessaire pour toutes les boîtes
    $totalWidth = ($adjustedMinBoxWidth * $GroupCount) + ($recommendedSpacing * ($GroupCount - 1))

    # Vérifier si la largeur totale dépasse la largeur du graphique
    $exceedsPlotWidth = $totalWidth -gt $PlotWidth

    # Générer des recommandations spécifiques
    $recommendations = @()

    if ($exceedsPlotWidth) {
        $maxPossibleBoxWidth = [Math]::Floor(($PlotWidth - ($recommendedSpacing * ($GroupCount - 1))) / $GroupCount)
        $recommendations += "ATTENTION: La largeur totale ($totalWidth px) dépasse la largeur du graphique ($PlotWidth px)."
        $recommendations += "Largeur maximale possible par boîte: $maxPossibleBoxWidth px (inférieure au minimum recommandé)."
        $recommendations += "Considérer: augmenter la taille du graphique, réduire l'espacement, ou diviser en plusieurs graphiques."
    } else {
        $recommendations += "Largeur de boîte recommandée: $adjustedMinBoxWidth px."
        $recommendations += "Largeur de moustache recommandée: $minWhiskerWidth px."
        $recommendations += "Espacement recommandé entre les boîtes: $recommendedSpacing px."
        $recommendations += "Épaisseur de ligne minimale recommandée: $minLineThickness px."
    }

    # Recommandations pour les outliers
    $outlierRecommendation = "Utiliser les paramètres par défaut pour les outliers."
    $recommendations += "Outliers: $outlierRecommendation"

    # Créer l'objet de résultat
    $result = @{
        ScreenSize              = $ScreenSize
        GroupCount              = $GroupCount
        GroupCategory           = $groupCategory
        DataDistribution        = $DataDistribution
        DistributionFactor      = $distributionFactor
        PlotWidth               = $PlotWidth
        DPI                     = $DPI
        MinLineThickness        = $minLineThickness
        WhiskerStyle            = $WhiskerStyle
        WhiskerWidthRatio       = $whiskerWidthRatio
        MinBoxWidthByScreen     = $minBoxWidthByScreen
        MinWidthPercentage      = $minWidthPercentage
        MinBoxWidthByPercentage = $minBoxWidthByPercentage
        BaseMinBoxWidth         = $baseMinBoxWidth
        AdjustedMinBoxWidth     = $adjustedMinBoxWidth
        MinWhiskerWidth         = $minWhiskerWidth
        RecommendedSpacing      = $recommendedSpacing
        TotalWidth              = $totalWidth
        ExceedsPlotWidth        = $exceedsPlotWidth
        Recommendations         = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations de largeur minimale pour les boîtes à moustaches.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations de largeur minimale
    pour les boîtes à moustaches en fonction du nombre de groupes et du type de distribution.

.PARAMETER ScreenSize
    La taille d'écran (par défaut "Moyen (1280x720)").

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER PlotWidth
    La largeur du graphique en pixels (par défaut 0, calculée automatiquement).

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-BoxplotWidthReport -ScreenSize "Moyen (1280x720)" -DataDistribution "Normale" -Format "Text"
    Génère un rapport textuel des recommandations de largeur minimale pour les boîtes à moustaches.

.OUTPUTS
    System.String
#>
function Get-BoxplotWidthReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Petit (800x600)", "Moyen (1280x720)", "Grand (1920x1080)", "Très grand (2560x1440)")]
        [string]$ScreenSize = "Moyen (1280x720)",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$PlotWidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les nombres de groupes à analyser
    $groupCounts = @(1, 3, 5, 10, 20, 50)
    $recommendations = @{}

    # Obtenir les recommandations pour chaque nombre de groupes
    foreach ($groupCount in $groupCounts) {
        $recommendations["$groupCount"] = Get-BoxplotMinWidth -ScreenSize $ScreenSize -GroupCount $groupCount -DataDistribution $DataDistribution -PlotWidth $PlotWidth
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations de largeur minimale pour les boîtes à moustaches ===`n`n"
            $result += "Taille d'écran: $ScreenSize`n"
            $result += "Type de distribution: $DataDistribution`n"
            if ($PlotWidth -gt 0) {
                $result += "Largeur du graphique: $PlotWidth px`n"
            } else {
                $result += "Largeur du graphique: calculée automatiquement`n"
            }
            $result += "`n"

            $result += "| Nombre de groupes | Catégorie | Largeur min. (px) | Largeur moustaches (px) | Espacement (px) | Largeur totale (px) | Dépasse |`n"
            $result += "|------------------|-----------|-------------------|-------------------------|-----------------|---------------------|---------|`n"

            foreach ($groupCount in $groupCounts) {
                $rec = $recommendations["$groupCount"]
                $exceedsText = if ($rec.ExceedsPlotWidth -eq $true) { 'Oui' } else { 'Non' }
                $result += "| $($rec.GroupCount) | $($rec.GroupCategory) | $($rec.AdjustedMinBoxWidth) | $($rec.MinWhiskerWidth) | $($rec.RecommendedSpacing) | $($rec.TotalWidth) | $exceedsText |`n"
            }

            $result += "`n"

            foreach ($groupCount in $groupCounts) {
                $rec = $recommendations["$groupCount"]
                $result += "## Nombre de groupes: $($rec.GroupCount)`n"
                $result += "Catégorie: $($rec.GroupCategory)`n"
                $result += "Facteur d'ajustement pour distribution $($rec.DataDistribution): $($rec.DistributionFactor)`n"

                $result += "Recommandations:`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "- $recommendation`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "GroupCount,GroupCategory,DataDistribution,DistributionFactor,MinBoxWidth,MinWhiskerWidth,RecommendedSpacing,TotalWidth,ExceedsPlotWidth`n"

            foreach ($groupCount in $groupCounts) {
                $rec = $recommendations["$groupCount"]
                $result += "$($rec.GroupCount),$($rec.GroupCategory),$($rec.DataDistribution),$($rec.DistributionFactor),$($rec.AdjustedMinBoxWidth),$($rec.MinWhiskerWidth),$($rec.RecommendedSpacing),$($rec.TotalWidth),$($rec.ExceedsPlotWidth)`n"
            }

            $result += "`nGroupCount,Recommendation`n"
            foreach ($groupCount in $groupCounts) {
                $rec = $recommendations["$groupCount"]
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "$($rec.GroupCount),""$recommendation""`n"
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations de largeur minimale pour les boîtes à moustaches</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations de largeur minimale pour les boîtes à moustaches</h1>`n"
            $result += "<p><strong>Taille d'écran:</strong> $ScreenSize</p>`n"
            $result += "<p><strong>Type de distribution:</strong> $DataDistribution</p>`n"
            if ($PlotWidth -gt 0) {
                $result += "<p><strong>Largeur du graphique:</strong> $PlotWidth px</p>`n"
            } else {
                $result += "<p><strong>Largeur du graphique:</strong> calculée automatiquement</p>`n"
            }

            $result += "<table>`n"
            $result += "<tr><th>Nombre de groupes</th><th>Catégorie</th><th>Largeur min. (px)</th><th>Largeur moustaches (px)</th><th>Espacement (px)</th><th>Largeur totale (px)</th><th>Dépasse</th></tr>`n"

            foreach ($groupCount in $groupCounts) {
                $rec = $recommendations["$groupCount"]
                $exceedsText = if ($rec.ExceedsPlotWidth) { "Oui" } else { "Non" }
                $result += "<tr><td>$($rec.GroupCount)</td><td>$($rec.GroupCategory)</td><td>$($rec.AdjustedMinBoxWidth)</td><td>$($rec.MinWhiskerWidth)</td><td>$($rec.RecommendedSpacing)</td><td>$($rec.TotalWidth)</td><td>$exceedsText</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($groupCount in $groupCounts) {
                $rec = $recommendations["$groupCount"]
                $result += "<h2>Nombre de groupes: $($rec.GroupCount)</h2>`n"
                $result += "<p><strong>Catégorie:</strong> $($rec.GroupCategory)</p>`n"
                $result += "<p><strong>Facteur d'ajustement pour distribution $($rec.DataDistribution):</strong> $($rec.DistributionFactor)</p>`n"

                $result += "<div class='recommendations'>`n<h3>Recommandations:</h3>`n<ul>`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "<li>$recommendation</li>`n"
                }
                $result += "</ul>`n</div>`n"
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "ScreenSize"       = $ScreenSize
                "DataDistribution" = $DataDistribution
                "PlotWidth"        = $PlotWidth
                "Recommendations"  = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détermine l'espacement optimal entre les boîtes pour les comparaisons multiples.

.DESCRIPTION
    Cette fonction calcule l'espacement optimal entre les boîtes à moustaches
    pour faciliter les comparaisons visuelles, en fonction du nombre de groupes,
    du type de comparaison et d'autres paramètres.

.PARAMETER GroupCount
    Le nombre de groupes à comparer (par défaut 2).

.PARAMETER BoxWidth
    La largeur des boîtes en pixels (par défaut 0, calculée automatiquement).

.PARAMETER ComparisonType
    Le type de comparaison à effectuer (par défaut "Standard").

.PARAMETER PlotWidth
    La largeur du graphique en pixels (par défaut 0, calculée automatiquement).

.PARAMETER ScreenSize
    La taille d'écran (par défaut "Moyen (1280x720)").

.EXAMPLE
    Get-BoxplotSpacing -GroupCount 5 -BoxWidth 100 -ComparisonType "Précis"
    Calcule l'espacement optimal entre les boîtes pour 5 groupes avec une largeur de boîte de 100 pixels.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-BoxplotSpacing {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$GroupCount = 2,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$BoxWidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Compact", "Standard", "Précis", "Détaillé")]
        [string]$ComparisonType = "Standard",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$PlotWidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Petit (800x600)", "Moyen (1280x720)", "Grand (1920x1080)", "Très grand (2560x1440)")]
        [string]$ScreenSize = "Moyen (1280x720)"
    )

    # Déterminer la catégorie de nombre de groupes
    $groupCategory = switch ($GroupCount) {
        { $_ -le 3 } { "Très peu (1-3)" }
        { $_ -ge 4 -and $_ -le 7 } { "Peu (4-7)" }
        { $_ -ge 8 -and $_ -le 15 } { "Moyen (8-15)" }
        { $_ -ge 16 -and $_ -le 30 } { "Nombreux (16-30)" }
        default { "Très nombreux (>30)" }
    }

    # Calculer la largeur du graphique si elle n'est pas spécifiée
    if ($PlotWidth -eq 0) {
        $screenSizePixels = switch ($ScreenSize) {
            "Petit (800x600)" { 800 }
            "Moyen (1280x720)" { 1280 }
            "Grand (1920x1080)" { 1920 }
            "Très grand (2560x1440)" { 2560 }
            default { 1280 }
        }

        # Supposons que le graphique occupe 80% de la largeur de l'écran
        $PlotWidth = [Math]::Floor($screenSizePixels * 0.8)
    }

    # Calculer la largeur des boîtes si elle n'est pas spécifiée
    if ($BoxWidth -eq 0) {
        # Obtenir la largeur minimale des boîtes pour cette taille d'écran
        $boxplotParams = @{
            ScreenSize = $ScreenSize
            GroupCount = $GroupCount
            PlotWidth  = $PlotWidth
        }
        $boxWidthRecommendation = Get-BoxplotMinWidth @boxplotParams
        $BoxWidth = $boxWidthRecommendation.AdjustedMinBoxWidth
    }

    # Définir les ratios d'espacement par type de comparaison
    $spacingRatios = @{
        "Compact"  = 0.5   # 50% de la largeur des boîtes
        "Standard" = 0.8  # 80% de la largeur des boîtes
        "Précis"   = 1.2    # 120% de la largeur des boîtes
        "Détaillé" = 2.0  # 200% de la largeur des boîtes
    }

    # Obtenir le ratio d'espacement pour ce type de comparaison
    $spacingRatio = $spacingRatios[$ComparisonType]

    # Calculer l'espacement recommandé
    $recommendedSpacing = [Math]::Ceiling($BoxWidth * $spacingRatio)

    # Calculer la largeur totale nécessaire pour toutes les boîtes
    $totalWidth = ($BoxWidth * $GroupCount) + ($recommendedSpacing * ($GroupCount - 1))

    # Vérifier si la largeur totale dépasse la largeur du graphique
    $exceedsPlotWidth = $totalWidth -gt $PlotWidth

    # Calculer l'espacement maximal possible si la largeur totale dépasse la largeur du graphique
    $maxPossibleSpacing = 0
    if ($exceedsPlotWidth) {
        $availableSpaceForSpacing = $PlotWidth - ($BoxWidth * $GroupCount)
        if ($GroupCount -gt 1) {
            $maxPossibleSpacing = [Math]::Floor($availableSpaceForSpacing / ($GroupCount - 1))
        }
    }

    # Ajuster l'espacement si nécessaire
    $adjustedSpacing = if ($exceedsPlotWidth -and $maxPossibleSpacing -ge 0) {
        $maxPossibleSpacing
    } else {
        $recommendedSpacing
    }

    # Calculer la largeur totale ajustée
    $adjustedTotalWidth = ($BoxWidth * $GroupCount) + ($adjustedSpacing * ($GroupCount - 1))

    # Générer des recommandations spécifiques
    $recommendations = @()

    if ($exceedsPlotWidth) {
        if ($maxPossibleSpacing -lt 0) {
            $recommendations += "ATTENTION: Impossible d'afficher tous les groupes avec la largeur de boîte spécifiée."
            $recommendations += "Considérer: réduire la largeur des boîtes, diviser en plusieurs graphiques, ou augmenter la taille du graphique."
        } elseif ($maxPossibleSpacing -lt ($BoxWidth * 0.3)) {
            $recommendations += "ATTENTION: L'espacement est très réduit, ce qui peut rendre les comparaisons difficiles."
            $recommendations += "Espacement ajusté: $adjustedSpacing px (inférieur au minimum recommandé de $([Math]::Ceiling($BoxWidth * 0.3)) px)."
            $recommendations += "Considérer: réduire la largeur des boîtes, diviser en plusieurs graphiques, ou augmenter la taille du graphique."
        } else {
            $recommendations += "Espacement ajusté: $adjustedSpacing px (réduit par rapport à la recommandation de $recommendedSpacing px)."
            $recommendations += "La largeur totale ajustée ($adjustedTotalWidth px) s'adapte à la largeur du graphique ($PlotWidth px)."
        }
    } else {
        $recommendations += "Espacement recommandé: $recommendedSpacing px ($spacingRatio fois la largeur des boîtes)."
        $recommendations += "La largeur totale ($totalWidth px) s'adapte bien à la largeur du graphique ($PlotWidth px)."
    }

    # Recommandations spécifiques par type de comparaison
    switch ($ComparisonType) {
        "Compact" {
            $recommendations += "Type de comparaison 'Compact': privilégie l'affichage de nombreux groupes dans un espace limité."
            $recommendations += "Avantage: permet d'afficher plus de groupes."
            $recommendations += "Inconvénient: peut rendre les comparaisons précises plus difficiles."
        }
        "Standard" {
            $recommendations += "Type de comparaison 'Standard': équilibre entre l'espace utilisé et la facilité de comparaison."
            $recommendations += "Recommandé pour la plupart des cas d'utilisation."
        }
        "Précis" {
            $recommendations += "Type de comparaison 'Précis': facilite les comparaisons visuelles précises entre les groupes."
            $recommendations += "Recommandé pour les analyses statistiques détaillées."
        }
        "Détaillé" {
            $recommendations += "Type de comparaison 'Détaillé': maximise la séparation visuelle entre les groupes."
            $recommendations += "Recommandé pour les présentations et les publications scientifiques."
            $recommendations += "Considérer l'ajout d'annotations entre les groupes pour faciliter l'interprétation."
        }
    }

    # Recommandations pour les comparaisons multiples
    if ($GroupCount -gt 5) {
        $recommendations += "Pour faciliter les comparaisons entre de nombreux groupes:"
        $recommendations += "- Considérer un code couleur pour regrouper les catégories similaires."
        $recommendations += "- Ajouter des lignes de référence horizontales pour faciliter les comparaisons de médiane."
        $recommendations += "- Envisager de réorganiser les groupes par ordre croissant/décroissant de médiane."
    }

    # Créer l'objet de résultat
    $result = @{
        GroupCount         = $GroupCount
        GroupCategory      = $groupCategory
        BoxWidth           = $BoxWidth
        ComparisonType     = $ComparisonType
        SpacingRatio       = $spacingRatio
        RecommendedSpacing = $recommendedSpacing
        PlotWidth          = $PlotWidth
        TotalWidth         = $totalWidth
        ExceedsPlotWidth   = $exceedsPlotWidth
        MaxPossibleSpacing = $maxPossibleSpacing
        AdjustedSpacing    = $adjustedSpacing
        AdjustedTotalWidth = $adjustedTotalWidth
        Recommendations    = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations d'espacement entre les boîtes pour différents types de comparaison.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations d'espacement
    entre les boîtes à moustaches pour différents types de comparaison.

.PARAMETER GroupCount
    Le nombre de groupes à comparer (par défaut 5).

.PARAMETER BoxWidth
    La largeur des boîtes en pixels (par défaut 100).

.PARAMETER PlotWidth
    La largeur du graphique en pixels (par défaut 0, calculée automatiquement).

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-BoxplotSpacingReport -GroupCount 5 -BoxWidth 100 -Format "Text"
    Génère un rapport textuel des recommandations d'espacement pour 5 groupes avec une largeur de boîte de 100 pixels.

.OUTPUTS
    System.String
#>
function Get-BoxplotSpacingReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$GroupCount = 5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$BoxWidth = 100,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$PlotWidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les types de comparaison à analyser
    $comparisonTypes = @("Compact", "Standard", "Précis", "Détaillé")
    $recommendations = @{}

    # Obtenir les recommandations pour chaque type de comparaison
    foreach ($comparisonType in $comparisonTypes) {
        $recommendations[$comparisonType] = Get-BoxplotSpacing -GroupCount $GroupCount -BoxWidth $BoxWidth -ComparisonType $comparisonType -PlotWidth $PlotWidth
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations d'espacement entre les boîtes à moustaches ===`n`n"
            $result += "Nombre de groupes: $GroupCount`n"
            $result += "Largeur des boîtes: $BoxWidth px`n"
            if ($PlotWidth -gt 0) {
                $result += "Largeur du graphique: $PlotWidth px`n"
            } else {
                $result += "Largeur du graphique: calculée automatiquement`n"
            }
            $result += "`n"

            $result += "| Type de comparaison | Ratio d'espacement | Espacement (px) | Largeur totale (px) | Dépasse | Espacement ajusté (px) |`n"
            $result += "|-------------------|-------------------|----------------|---------------------|---------|------------------------|`n"

            foreach ($comparisonType in $comparisonTypes) {
                $rec = $recommendations[$comparisonType]
                $exceedsText = if ($rec.ExceedsPlotWidth) { "Oui" } else { "Non" }
                $adjustedSpacingText = if ($rec.ExceedsPlotWidth) { $rec.AdjustedSpacing } else { "N/A" }
                $result += "| $($rec.ComparisonType) | $($rec.SpacingRatio) | $($rec.RecommendedSpacing) | $($rec.TotalWidth) | $exceedsText | $adjustedSpacingText |`n"
            }

            $result += "`n"

            foreach ($comparisonType in $comparisonTypes) {
                $rec = $recommendations[$comparisonType]
                $result += "## Type de comparaison: $($rec.ComparisonType)`n"
                $result += "Ratio d'espacement: $($rec.SpacingRatio) fois la largeur des boîtes`n"
                $result += "Espacement recommandé: $($rec.RecommendedSpacing) px`n"
                $result += "Largeur totale: $($rec.TotalWidth) px`n"
                $result += "Dépasse la largeur du graphique: $($rec.ExceedsPlotWidth)`n"
                if ($rec.ExceedsPlotWidth) {
                    $result += "Espacement maximal possible: $($rec.MaxPossibleSpacing) px`n"
                    $result += "Espacement ajusté: $($rec.AdjustedSpacing) px`n"
                    $result += "Largeur totale ajustée: $($rec.AdjustedTotalWidth) px`n"
                }

                $result += "`nRecommandations:`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "- $recommendation`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "ComparisonType,SpacingRatio,RecommendedSpacing,TotalWidth,ExceedsPlotWidth,MaxPossibleSpacing,AdjustedSpacing,AdjustedTotalWidth`n"

            foreach ($comparisonType in $comparisonTypes) {
                $rec = $recommendations[$comparisonType]
                $result += "$($rec.ComparisonType),$($rec.SpacingRatio),$($rec.RecommendedSpacing),$($rec.TotalWidth),$($rec.ExceedsPlotWidth),$($rec.MaxPossibleSpacing),$($rec.AdjustedSpacing),$($rec.AdjustedTotalWidth)`n"
            }

            $result += "`nComparisonType,Recommendation`n"
            foreach ($comparisonType in $comparisonTypes) {
                $rec = $recommendations[$comparisonType]
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "$($rec.ComparisonType),""$recommendation""`n"
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations d'espacement entre les boîtes à moustaches</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations d'espacement entre les boîtes à moustaches</h1>`n"
            $result += "<p><strong>Nombre de groupes:</strong> $GroupCount</p>`n"
            $result += "<p><strong>Largeur des boîtes:</strong> $BoxWidth px</p>`n"
            if ($PlotWidth -gt 0) {
                $result += "<p><strong>Largeur du graphique:</strong> $PlotWidth px</p>`n"
            } else {
                $result += "<p><strong>Largeur du graphique:</strong> calculée automatiquement</p>`n"
            }

            $result += "<table>`n"
            $result += "<tr><th>Type de comparaison</th><th>Ratio d'espacement</th><th>Espacement (px)</th><th>Largeur totale (px)</th><th>Dépasse</th><th>Espacement ajusté (px)</th></tr>`n"

            foreach ($comparisonType in $comparisonTypes) {
                $rec = $recommendations[$comparisonType]
                $exceedsText = if ($rec.ExceedsPlotWidth) { "Oui" } else { "Non" }
                $adjustedSpacingText = if ($rec.ExceedsPlotWidth) { $rec.AdjustedSpacing } else { "N/A" }
                $result += "<tr><td>$($rec.ComparisonType)</td><td>$($rec.SpacingRatio)</td><td>$($rec.RecommendedSpacing)</td><td>$($rec.TotalWidth)</td><td>$exceedsText</td><td>$adjustedSpacingText</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($comparisonType in $comparisonTypes) {
                $rec = $recommendations[$comparisonType]
                $result += "<h2>Type de comparaison: $($rec.ComparisonType)</h2>`n"
                $result += "<p><strong>Ratio d'espacement:</strong> $($rec.SpacingRatio) fois la largeur des boîtes</p>`n"
                $result += "<p><strong>Espacement recommandé:</strong> $($rec.RecommendedSpacing) px</p>`n"
                $result += "<p><strong>Largeur totale:</strong> $($rec.TotalWidth) px</p>`n"
                $result += "<p><strong>Dépasse la largeur du graphique:</strong> $($rec.ExceedsPlotWidth)</p>`n"
                if ($rec.ExceedsPlotWidth) {
                    $result += "<p><strong>Espacement maximal possible:</strong> $($rec.MaxPossibleSpacing) px</p>`n"
                    $result += "<p><strong>Espacement ajusté:</strong> $($rec.AdjustedSpacing) px</p>`n"
                    $result += "<p><strong>Largeur totale ajustée:</strong> $($rec.AdjustedTotalWidth) px</p>`n"
                }

                $result += "<div class='recommendations'>`n<h3>Recommandations:</h3>`n<ul>`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "<li>$recommendation</li>`n"
                }
                $result += "</ul>`n</div>`n"
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "GroupCount"      = $GroupCount
                "BoxWidth"        = $BoxWidth
                "PlotWidth"       = $PlotWidth
                "Recommendations" = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détermine les critères de hauteur relative pour l'identification des modes dans les distributions.

.DESCRIPTION
    Cette fonction calcule le seuil de hauteur relative optimal pour identifier les modes
    dans une distribution, en fonction de la taille d'échantillon, du type de distribution,
    du niveau de bruit et d'autres paramètres.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER NoiseLevel
    Le niveau de bruit dans les données (par défaut "Modéré").

.PARAMETER SmoothingMethod
    La méthode de lissage utilisée (par défaut "Aucun").

.PARAMETER Application
    L'application spécifique pour laquelle les modes sont identifiés (par défaut "Analyse statistique").

.EXAMPLE
    Get-ModeHeightThreshold -SampleSize 200 -DataDistribution "Multimodale" -NoiseLevel "Faible"
    Calcule le seuil de hauteur relative optimal pour identifier les modes dans une distribution multimodale
    avec un échantillon de 200 observations et un niveau de bruit faible.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ModeHeightThreshold {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Très faible", "Faible", "Modéré", "Élevé", "Très élevé", "Extrême")]
        [string]$NoiseLevel = "Modéré",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Aucun", "Moyenne mobile", "Noyau gaussien", "Spline", "Régression locale")]
        [string]$SmoothingMethod = "Aucun",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Exploration de données", "Analyse statistique", "Contrôle qualité", "Détection d'anomalies", "Classification", "Segmentation")]
        [string]$Application = "Analyse statistique"
    )

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Obtenir le seuil de base par taille d'échantillon
    $baseThresholdCategory = $script:ModeDetectionRecommendations.ThresholdBySampleSize[$sizeCategory]
    $baseThreshold = $script:ModeDetectionRecommendations.RelativeHeightThresholds[$baseThresholdCategory]

    # Obtenir le facteur d'ajustement pour ce type de distribution
    $distributionFactor = $script:ModeDetectionRecommendations.HeightFactorByDistribution[$DataDistribution]

    # Obtenir le seuil recommandé par niveau de bruit
    $noiseThresholdCategory = $script:ModeDetectionRecommendations.ThresholdByNoiseLevel[$NoiseLevel]
    $noiseThreshold = $script:ModeDetectionRecommendations.RelativeHeightThresholds[$noiseThresholdCategory]

    # Obtenir le seuil recommandé par méthode de lissage
    $smoothingThresholdCategory = $script:ModeDetectionRecommendations.ThresholdBySmoothingMethod[$SmoothingMethod]
    $smoothingThreshold = $script:ModeDetectionRecommendations.RelativeHeightThresholds[$smoothingThresholdCategory]

    # Obtenir le seuil recommandé par application
    $applicationThresholdCategory = $script:ModeDetectionRecommendations.ThresholdByApplication[$Application]
    $applicationThreshold = $script:ModeDetectionRecommendations.RelativeHeightThresholds[$applicationThresholdCategory]

    # Calculer le seuil final en combinant les différents facteurs
    # Nous donnons plus de poids à la taille d'échantillon et au type de distribution
    $finalThreshold = $baseThreshold * $distributionFactor * 0.4 +
    $noiseThreshold * 0.2 +
    $smoothingThreshold * 0.2 +
    $applicationThreshold * 0.2

    # Arrondir le seuil à 2 décimales
    $finalThreshold = [Math]::Round($finalThreshold, 2)

    # Déterminer la catégorie du seuil final
    $finalThresholdCategory = switch ($finalThreshold) {
        { $_ -le 0.075 } { "Très faible (5%)" }
        { $_ -gt 0.075 -and $_ -le 0.125 } { "Faible (10%)" }
        { $_ -gt 0.125 -and $_ -le 0.175 } { "Modéré (15%)" }
        { $_ -gt 0.175 -and $_ -le 0.225 } { "Standard (20%)" }
        { $_ -gt 0.225 -and $_ -le 0.275 } { "Élevé (25%)" }
        default { "Très élevé (30%)" }
    }

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur la taille d'échantillon
    $recommendations += "Taille d'échantillon ($SampleSize observations, catégorie: $sizeCategory): seuil de base $baseThresholdCategory."

    # Recommandations basées sur le type de distribution
    if ($DataDistribution -eq "Normale") {
        $recommendations += "Distribution normale: utiliser un seuil standard pour éviter la détection de faux modes."
    } elseif ($DataDistribution -eq "Multimodale") {
        $recommendations += "Distribution multimodale: utiliser un seuil plus bas pour détecter tous les modes potentiels."
    } elseif ($DataDistribution -eq "Asymétrique") {
        $recommendations += "Distribution asymétrique: utiliser un seuil plus bas pour détecter les modes secondaires."
    } elseif ($DataDistribution -eq "Queue lourde") {
        $recommendations += "Distribution à queue lourde: utiliser un seuil légèrement plus bas pour détecter les modes dans les queues."
    } elseif ($DataDistribution -eq "Uniforme") {
        $recommendations += "Distribution uniforme: utiliser un seuil plus élevé pour éviter la détection de faux modes dus au bruit."
    } elseif ($DataDistribution -eq "Exponentielle") {
        $recommendations += "Distribution exponentielle: utiliser un seuil plus bas pour détecter les modes secondaires."
    }

    # Recommandations basées sur le niveau de bruit
    if ($NoiseLevel -eq "Très faible" -or $NoiseLevel -eq "Faible") {
        $recommendations += "Niveau de bruit $($NoiseLevel) - un seuil plus bas peut être utilisé sans risque de faux positifs."
    } elseif ($NoiseLevel -eq "Élevé" -or $NoiseLevel -eq "Très élevé" -or $NoiseLevel -eq "Extrême") {
        $recommendations += "Niveau de bruit $($NoiseLevel) - un seuil plus élevé est nécessaire pour éviter les faux positifs."
    }

    # Recommandations basées sur la méthode de lissage
    if ($SmoothingMethod -eq "Aucun") {
        $recommendations += "Sans lissage: un seuil plus élevé est recommandé pour éviter les faux positifs dus au bruit."
    } else {
        $recommendations += "Méthode de lissage '$SmoothingMethod': permet d'utiliser un seuil plus bas."
    }

    # Recommandations basées sur l'application
    if ($Application -eq "Exploration de données") {
        $recommendations += "Application '$Application': un seuil très bas est recommandé pour détecter tous les modes potentiels."
    } elseif ($Application -eq "Détection d'anomalies") {
        $recommendations += "Application '$Application': un seuil standard est recommandé pour équilibrer sensibilité et spécificité."
    } elseif ($Application -eq "Segmentation") {
        $recommendations += "Application '$Application': un seuil élevé est recommandé pour ne détecter que les modes principaux."
    }

    # Recommandation finale
    $recommendations += "Seuil final recommandé: $finalThreshold ($finalThresholdCategory)."

    # Créer l'objet de résultat
    $result = @{
        SampleSize                   = $SampleSize
        SizeCategory                 = $sizeCategory
        DataDistribution             = $DataDistribution
        DistributionFactor           = $distributionFactor
        NoiseLevel                   = $NoiseLevel
        SmoothingMethod              = $SmoothingMethod
        Application                  = $Application
        BaseThresholdCategory        = $baseThresholdCategory
        BaseThreshold                = $baseThreshold
        NoiseThresholdCategory       = $noiseThresholdCategory
        NoiseThreshold               = $noiseThreshold
        SmoothingThresholdCategory   = $smoothingThresholdCategory
        SmoothingThreshold           = $smoothingThreshold
        ApplicationThresholdCategory = $applicationThresholdCategory
        ApplicationThreshold         = $applicationThreshold
        FinalThreshold               = $finalThreshold
        FinalThresholdCategory       = $finalThresholdCategory
        Recommendations              = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations de seuils de hauteur relative pour l'identification des modes.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations de seuils de hauteur relative
    pour l'identification des modes dans différentes distributions.

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER NoiseLevel
    Le niveau de bruit dans les données (par défaut "Modéré").

.PARAMETER SmoothingMethod
    La méthode de lissage utilisée (par défaut "Aucun").

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-ModeHeightThresholdReport -DataDistribution "Multimodale" -NoiseLevel "Faible" -Format "Text"
    Génère un rapport textuel des recommandations de seuils de hauteur relative pour une distribution multimodale
    avec un niveau de bruit faible.

.OUTPUTS
    System.String
#>
function Get-ModeHeightThresholdReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Très faible", "Faible", "Modéré", "Élevé", "Très élevé", "Extrême")]
        [string]$NoiseLevel = "Modéré",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Aucun", "Moyenne mobile", "Noyau gaussien", "Spline", "Régression locale")]
        [string]$SmoothingMethod = "Aucun",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les tailles d'échantillon à analyser
    $sampleSizes = @(20, 50, 100, 200, 500, 1000, 5000)
    $applications = @("Exploration de données", "Analyse statistique", "Contrôle qualité", "Détection d'anomalies", "Classification", "Segmentation")
    $recommendations = @{}

    # Obtenir les recommandations pour chaque taille d'échantillon et application
    foreach ($sampleSize in $sampleSizes) {
        $recommendations["$sampleSize"] = @{}
        foreach ($application in $applications) {
            $recommendations["$sampleSize"][$application] = Get-ModeHeightThreshold -SampleSize $sampleSize -DataDistribution $DataDistribution -NoiseLevel $NoiseLevel -SmoothingMethod $SmoothingMethod -Application $application
        }
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations de seuils de hauteur relative pour l'identification des modes ===`n`n"
            $result += "Type de distribution: $DataDistribution`n"
            $result += "Niveau de bruit: $NoiseLevel`n"
            $result += "Méthode de lissage: $SmoothingMethod`n`n"

            $result += "| Taille d'échantillon | Catégorie | Exploration | Analyse | Contrôle | Détection | Classification | Segmentation |`n"
            $result += "|---------------------|-----------|------------|---------|----------|-----------|----------------|--------------|`n"

            foreach ($sampleSize in $sampleSizes) {
                $sizeCategory = $recommendations["$sampleSize"]["Analyse statistique"].SizeCategory
                $explorationThreshold = $recommendations["$sampleSize"]["Exploration de données"].FinalThreshold
                $analysisThreshold = $recommendations["$sampleSize"]["Analyse statistique"].FinalThreshold
                $qualityThreshold = $recommendations["$sampleSize"]["Contrôle qualité"].FinalThreshold
                $detectionThreshold = $recommendations["$sampleSize"]["Détection d'anomalies"].FinalThreshold
                $classificationThreshold = $recommendations["$sampleSize"]["Classification"].FinalThreshold
                $segmentationThreshold = $recommendations["$sampleSize"]["Segmentation"].FinalThreshold

                $result += "| $sampleSize | $sizeCategory | $explorationThreshold | $analysisThreshold | $qualityThreshold | $detectionThreshold | $classificationThreshold | $segmentationThreshold |`n"
            }

            $result += "`n"

            foreach ($sampleSize in $sampleSizes) {
                $result += "## Taille d'échantillon: $sampleSize`n"
                $result += "Catégorie: $($recommendations["$sampleSize"]["Analyse statistique"].SizeCategory)`n"
                $result += "Facteur d'ajustement pour distribution $($DataDistribution): $($recommendations["$sampleSize"]["Analyse statistique"].DistributionFactor)`n"

                $result += "`nRecommandations par application:`n"
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "### $application`n"
                    $result += "Seuil recommandé: $($rec.FinalThreshold) ($($rec.FinalThresholdCategory))`n"
                    $result += "Recommandations spécifiques:`n"
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "- $recommendation`n"
                    }
                    $result += "`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "SampleSize,SizeCategory,Application,DataDistribution,NoiseLevel,SmoothingMethod,BaseThreshold,FinalThreshold,FinalThresholdCategory`n"

            foreach ($sampleSize in $sampleSizes) {
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "$($rec.SampleSize),$($rec.SizeCategory),$($rec.Application),$($rec.DataDistribution),$($rec.NoiseLevel),$($rec.SmoothingMethod),$($rec.BaseThreshold),$($rec.FinalThreshold),$($rec.FinalThresholdCategory)`n"
                }
            }

            $result += "`nSampleSize,Application,Recommendation`n"
            foreach ($sampleSize in $sampleSizes) {
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "$($rec.SampleSize),$($rec.Application),""$recommendation""`n"
                    }
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations de seuils de hauteur relative pour l'identification des modes</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2, h3 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations de seuils de hauteur relative pour l'identification des modes</h1>`n"
            $result += "<p><strong>Type de distribution:</strong> $DataDistribution</p>`n"
            $result += "<p><strong>Niveau de bruit:</strong> $NoiseLevel</p>`n"
            $result += "<p><strong>Méthode de lissage:</strong> $SmoothingMethod</p>`n"

            $result += "<table>`n"
            $result += "<tr><th>Taille d'échantillon</th><th>Catégorie</th><th>Exploration</th><th>Analyse</th><th>Contrôle</th><th>Détection</th><th>Classification</th><th>Segmentation</th></tr>`n"

            foreach ($sampleSize in $sampleSizes) {
                $sizeCategory = $recommendations["$sampleSize"]["Analyse statistique"].SizeCategory
                $explorationThreshold = $recommendations["$sampleSize"]["Exploration de données"].FinalThreshold
                $analysisThreshold = $recommendations["$sampleSize"]["Analyse statistique"].FinalThreshold
                $qualityThreshold = $recommendations["$sampleSize"]["Contrôle qualité"].FinalThreshold
                $detectionThreshold = $recommendations["$sampleSize"]["Détection d'anomalies"].FinalThreshold
                $classificationThreshold = $recommendations["$sampleSize"]["Classification"].FinalThreshold
                $segmentationThreshold = $recommendations["$sampleSize"]["Segmentation"].FinalThreshold

                $result += "<tr><td>$sampleSize</td><td>$sizeCategory</td><td>$explorationThreshold</td><td>$analysisThreshold</td><td>$qualityThreshold</td><td>$detectionThreshold</td><td>$classificationThreshold</td><td>$segmentationThreshold</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($sampleSize in $sampleSizes) {
                $result += "<h2>Taille d'échantillon: $sampleSize</h2>`n"
                $result += "<p><strong>Catégorie:</strong> $($recommendations["$sampleSize"]["Analyse statistique"].SizeCategory)</p>`n"
                $result += "<p><strong>Facteur d'ajustement pour distribution $($DataDistribution):</strong> $($recommendations["$sampleSize"]["Analyse statistique"].DistributionFactor)</p>`n"

                $result += "<h3>Recommandations par application:</h3>`n"
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "<h4>$application</h4>`n"
                    $result += "<p><strong>Seuil recommandé:</strong> $($rec.FinalThreshold) ($($rec.FinalThresholdCategory))</p>`n"
                    $result += "<div class='recommendations'>`n<h5>Recommandations spécifiques:</h5>`n<ul>`n"
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "<li>$recommendation</li>`n"
                    }
                    $result += "</ul>`n</div>`n"
                }
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "DataDistribution" = $DataDistribution
                "NoiseLevel"       = $NoiseLevel
                "SmoothingMethod"  = $SmoothingMethod
                "Recommendations"  = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détermine les critères de séparation minimale entre les modes dans les distributions.

.DESCRIPTION
    Cette fonction calcule la séparation minimale recommandée entre les modes
    dans une distribution, en fonction de la taille d'échantillon, du type de distribution,
    du niveau de bruit et d'autres paramètres.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER NoiseLevel
    Le niveau de bruit dans les données (par défaut "Modéré").

.PARAMETER SmoothingMethod
    La méthode de lissage utilisée (par défaut "Aucun").

.PARAMETER Application
    L'application spécifique pour laquelle les modes sont identifiés (par défaut "Analyse statistique").

.PARAMETER StandardDeviation
    L'écart-type estimé de la distribution (par défaut 1.0).

.EXAMPLE
    Get-ModeSeparationThreshold -SampleSize 200 -DataDistribution "Multimodale" -NoiseLevel "Faible"
    Calcule la séparation minimale recommandée entre les modes dans une distribution multimodale
    avec un échantillon de 200 observations et un niveau de bruit faible.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ModeSeparationThreshold {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Très faible", "Faible", "Modéré", "Élevé", "Très élevé", "Extrême")]
        [string]$NoiseLevel = "Modéré",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Aucun", "Moyenne mobile", "Noyau gaussien", "Spline", "Régression locale")]
        [string]$SmoothingMethod = "Aucun",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Exploration de données", "Analyse statistique", "Contrôle qualité", "Détection d'anomalies", "Classification", "Segmentation")]
        [string]$Application = "Analyse statistique",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, [double]::MaxValue)]
        [double]$StandardDeviation = 1.0
    )

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Obtenir la séparation de base par taille d'échantillon
    $baseSeparationCategory = $script:ModeDetectionRecommendations.SeparationBySampleSize[$sizeCategory]
    $baseSeparation = $script:ModeDetectionRecommendations.ModeSeparationThresholds[$baseSeparationCategory]

    # Obtenir le facteur d'ajustement pour ce type de distribution
    $distributionFactor = $script:ModeDetectionRecommendations.SeparationFactorByDistribution[$DataDistribution]

    # Obtenir la séparation recommandée par niveau de bruit
    $noiseSeparationCategory = $script:ModeDetectionRecommendations.SeparationByNoiseLevel[$NoiseLevel]
    $noiseSeparation = $script:ModeDetectionRecommendations.ModeSeparationThresholds[$noiseSeparationCategory]

    # Obtenir la séparation recommandée par méthode de lissage
    $smoothingSeparationCategory = $script:ModeDetectionRecommendations.SeparationBySmoothingMethod[$SmoothingMethod]
    $smoothingSeparation = $script:ModeDetectionRecommendations.ModeSeparationThresholds[$smoothingSeparationCategory]

    # Obtenir la séparation recommandée par application
    $applicationSeparationCategory = $script:ModeDetectionRecommendations.SeparationByApplication[$Application]
    $applicationSeparation = $script:ModeDetectionRecommendations.ModeSeparationThresholds[$applicationSeparationCategory]

    # Calculer la séparation finale en combinant les différents facteurs
    # Nous donnons plus de poids à la taille d'échantillon et au type de distribution
    $finalSeparation = $baseSeparation * $distributionFactor * 0.4 +
    $noiseSeparation * 0.2 +
    $smoothingSeparation * 0.2 +
    $applicationSeparation * 0.2

    # Arrondir la séparation à 2 décimales
    $finalSeparation = [Math]::Round($finalSeparation, 2)

    # Déterminer la catégorie de la séparation finale
    $finalSeparationCategory = switch ($finalSeparation) {
        { $_ -le 0.75 } { "Très faible (0.5σ)" }
        { $_ -gt 0.75 -and $_ -le 1.25 } { "Faible (1.0σ)" }
        { $_ -gt 1.25 -and $_ -le 1.75 } { "Modéré (1.5σ)" }
        { $_ -gt 1.75 -and $_ -le 2.25 } { "Standard (2.0σ)" }
        { $_ -gt 2.25 -and $_ -le 2.75 } { "Élevé (2.5σ)" }
        default { "Très élevé (3.0σ)" }
    }

    # Calculer la séparation en unités originales (en multipliant par l'écart-type)
    $separationInOriginalUnits = $finalSeparation * $StandardDeviation

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur la taille d'échantillon
    $recommendations += "Taille d'échantillon ($SampleSize observations, catégorie: $sizeCategory): séparation de base $baseSeparationCategory."

    # Recommandations basées sur le type de distribution
    if ($DataDistribution -eq "Normale") {
        $recommendations += "Distribution normale: utiliser une séparation standard pour distinguer les modes significatifs."
    } elseif ($DataDistribution -eq "Multimodale") {
        $recommendations += "Distribution multimodale: utiliser une séparation plus faible pour détecter tous les modes potentiels."
    } elseif ($DataDistribution -eq "Asymétrique") {
        $recommendations += "Distribution asymétrique: utiliser une séparation plus faible pour détecter les modes secondaires."
    } elseif ($DataDistribution -eq "Queue lourde") {
        $recommendations += "Distribution à queue lourde: utiliser une séparation légèrement plus faible pour détecter les modes dans les queues."
    } elseif ($DataDistribution -eq "Uniforme") {
        $recommendations += "Distribution uniforme: utiliser une séparation plus élevée pour éviter la détection de faux modes dus au bruit."
    } elseif ($DataDistribution -eq "Exponentielle") {
        $recommendations += "Distribution exponentielle: utiliser une séparation plus faible pour détecter les modes secondaires."
    }

    # Recommandations basées sur le niveau de bruit
    if ($NoiseLevel -eq "Très faible" -or $NoiseLevel -eq "Faible") {
        $recommendations += "Niveau de bruit $($NoiseLevel): une séparation plus faible peut être utilisée sans risque de faux positifs."
    } elseif ($NoiseLevel -eq "Élevé" -or $NoiseLevel -eq "Très élevé" -or $NoiseLevel -eq "Extrême") {
        $recommendations += "Niveau de bruit $($NoiseLevel): une séparation plus élevée est nécessaire pour éviter les faux positifs."
    }

    # Recommandations basées sur la méthode de lissage
    if ($SmoothingMethod -eq "Aucun") {
        $recommendations += "Sans lissage: une séparation plus élevée est recommandée pour éviter les faux positifs dus au bruit."
    } else {
        $recommendations += "Méthode de lissage '$SmoothingMethod': permet d'utiliser une séparation plus faible."
    }

    # Recommandations basées sur l'application
    if ($Application -eq "Exploration de données") {
        $recommendations += "Application '$Application': une séparation faible est recommandée pour détecter tous les modes potentiels."
    } elseif ($Application -eq "Détection d'anomalies") {
        $recommendations += "Application '$Application': une séparation très élevée est recommandée pour ne détecter que les modes significatifs."
    } elseif ($Application -eq "Segmentation") {
        $recommendations += "Application '$Application': une séparation standard est recommandée pour équilibrer sensibilité et spécificité."
    }

    # Recommandation finale
    $recommendations += "Séparation finale recommandée: $finalSeparation écarts-types ($finalSeparationCategory)."
    $recommendations += "Séparation en unités originales: $separationInOriginalUnits."

    # Créer l'objet de résultat
    $result = @{
        SampleSize                    = $SampleSize
        SizeCategory                  = $sizeCategory
        DataDistribution              = $DataDistribution
        DistributionFactor            = $distributionFactor
        NoiseLevel                    = $NoiseLevel
        SmoothingMethod               = $SmoothingMethod
        Application                   = $Application
        StandardDeviation             = $StandardDeviation
        BaseSeparationCategory        = $baseSeparationCategory
        BaseSeparation                = $baseSeparation
        NoiseSeparationCategory       = $noiseSeparationCategory
        NoiseSeparation               = $noiseSeparation
        SmoothingSeparationCategory   = $smoothingSeparationCategory
        SmoothingSeparation           = $smoothingSeparation
        ApplicationSeparationCategory = $applicationSeparationCategory
        ApplicationSeparation         = $applicationSeparation
        FinalSeparation               = $finalSeparation
        FinalSeparationCategory       = $finalSeparationCategory
        SeparationInOriginalUnits     = $separationInOriginalUnits
        Recommendations               = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations de séparation minimale entre les modes.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations de séparation minimale
    entre les modes dans différentes distributions.

.PARAMETER DataDistribution
    Le type de distribution des données (par défaut "Inconnue").

.PARAMETER NoiseLevel
    Le niveau de bruit dans les données (par défaut "Modéré").

.PARAMETER SmoothingMethod
    La méthode de lissage utilisée (par défaut "Aucun").

.PARAMETER StandardDeviation
    L'écart-type estimé de la distribution (par défaut 1.0).

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-ModeSeparationReport -DataDistribution "Multimodale" -NoiseLevel "Faible" -Format "Text"
    Génère un rapport textuel des recommandations de séparation minimale pour une distribution multimodale
    avec un niveau de bruit faible.

.OUTPUTS
    System.String
#>
function Get-ModeSeparationReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Uniforme", "Exponentielle", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Très faible", "Faible", "Modéré", "Élevé", "Très élevé", "Extrême")]
        [string]$NoiseLevel = "Modéré",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Aucun", "Moyenne mobile", "Noyau gaussien", "Spline", "Régression locale")]
        [string]$SmoothingMethod = "Aucun",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, [double]::MaxValue)]
        [double]$StandardDeviation = 1.0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les tailles d'échantillon à analyser
    $sampleSizes = @(20, 50, 100, 200, 500, 1000, 5000)
    $applications = @("Exploration de données", "Analyse statistique", "Contrôle qualité", "Détection d'anomalies", "Classification", "Segmentation")
    $recommendations = @{}

    # Obtenir les recommandations pour chaque taille d'échantillon et application
    foreach ($sampleSize in $sampleSizes) {
        $recommendations["$sampleSize"] = @{}
        foreach ($application in $applications) {
            $recommendations["$sampleSize"][$application] = Get-ModeSeparationThreshold -SampleSize $sampleSize -DataDistribution $DataDistribution -NoiseLevel $NoiseLevel -SmoothingMethod $SmoothingMethod -Application $application -StandardDeviation $StandardDeviation
        }
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations de séparation minimale entre les modes ===`n`n"
            $result += "Type de distribution: $DataDistribution`n"
            $result += "Niveau de bruit: $NoiseLevel`n"
            $result += "Méthode de lissage: $SmoothingMethod`n"
            $result += "Écart-type: $StandardDeviation`n`n"

            $result += "| Taille d'échantillon | Catégorie | Exploration | Analyse | Contrôle | Détection | Classification | Segmentation |`n"
            $result += "|---------------------|-----------|------------|---------|----------|-----------|----------------|--------------|`n"

            foreach ($sampleSize in $sampleSizes) {
                $sizeCategory = $recommendations["$sampleSize"]["Analyse statistique"].SizeCategory
                $explorationSeparation = $recommendations["$sampleSize"]["Exploration de données"].FinalSeparation
                $analysisSeparation = $recommendations["$sampleSize"]["Analyse statistique"].FinalSeparation
                $qualitySeparation = $recommendations["$sampleSize"]["Contrôle qualité"].FinalSeparation
                $detectionSeparation = $recommendations["$sampleSize"]["Détection d'anomalies"].FinalSeparation
                $classificationSeparation = $recommendations["$sampleSize"]["Classification"].FinalSeparation
                $segmentationSeparation = $recommendations["$sampleSize"]["Segmentation"].FinalSeparation

                $result += "| $sampleSize | $sizeCategory | $explorationSeparation | $analysisSeparation | $qualitySeparation | $detectionSeparation | $classificationSeparation | $segmentationSeparation |`n"
            }

            $result += "`n"

            foreach ($sampleSize in $sampleSizes) {
                $result += "## Taille d'échantillon: $sampleSize`n"
                $result += "Catégorie: $($recommendations["$sampleSize"]["Analyse statistique"].SizeCategory)`n"
                $result += "Facteur d'ajustement pour distribution $($DataDistribution): $($recommendations["$sampleSize"]["Analyse statistique"].DistributionFactor)`n"

                $result += "`nRecommandations par application:`n"
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "### $application`n"
                    $result += "Séparation recommandée: $($rec.FinalSeparation) écarts-types ($($rec.FinalSeparationCategory))`n"
                    $result += "Séparation en unités originales: $($rec.SeparationInOriginalUnits)`n"
                    $result += "Recommandations spécifiques:`n"
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "- $recommendation`n"
                    }
                    $result += "`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "SampleSize,SizeCategory,Application,DataDistribution,NoiseLevel,SmoothingMethod,BaseSeparation,FinalSeparation,FinalSeparationCategory,SeparationInOriginalUnits`n"

            foreach ($sampleSize in $sampleSizes) {
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "$($rec.SampleSize),$($rec.SizeCategory),$($rec.Application),$($rec.DataDistribution),$($rec.NoiseLevel),$($rec.SmoothingMethod),$($rec.BaseSeparation),$($rec.FinalSeparation),$($rec.FinalSeparationCategory),$($rec.SeparationInOriginalUnits)`n"
                }
            }

            $result += "`nSampleSize,Application,Recommendation`n"
            foreach ($sampleSize in $sampleSizes) {
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "$($rec.SampleSize),$($rec.Application),""$recommendation""`n"
                    }
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations de séparation minimale entre les modes</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2, h3 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations de séparation minimale entre les modes</h1>`n"
            $result += "<p><strong>Type de distribution:</strong> $DataDistribution</p>`n"
            $result += "<p><strong>Niveau de bruit:</strong> $NoiseLevel</p>`n"
            $result += "<p><strong>Méthode de lissage:</strong> $SmoothingMethod</p>`n"
            $result += "<p><strong>Écart-type:</strong> $StandardDeviation</p>`n"

            $result += "<table>`n"
            $result += "<tr><th>Taille d'échantillon</th><th>Catégorie</th><th>Exploration</th><th>Analyse</th><th>Contrôle</th><th>Détection</th><th>Classification</th><th>Segmentation</th></tr>`n"

            foreach ($sampleSize in $sampleSizes) {
                $sizeCategory = $recommendations["$sampleSize"]["Analyse statistique"].SizeCategory
                $explorationSeparation = $recommendations["$sampleSize"]["Exploration de données"].FinalSeparation
                $analysisSeparation = $recommendations["$sampleSize"]["Analyse statistique"].FinalSeparation
                $qualitySeparation = $recommendations["$sampleSize"]["Contrôle qualité"].FinalSeparation
                $detectionSeparation = $recommendations["$sampleSize"]["Détection d'anomalies"].FinalSeparation
                $classificationSeparation = $recommendations["$sampleSize"]["Classification"].FinalSeparation
                $segmentationSeparation = $recommendations["$sampleSize"]["Segmentation"].FinalSeparation

                $result += "<tr><td>$sampleSize</td><td>$sizeCategory</td><td>$explorationSeparation</td><td>$analysisSeparation</td><td>$qualitySeparation</td><td>$detectionSeparation</td><td>$classificationSeparation</td><td>$segmentationSeparation</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($sampleSize in $sampleSizes) {
                $result += "<h2>Taille d'échantillon: $sampleSize</h2>`n"
                $result += "<p><strong>Catégorie:</strong> $($recommendations["$sampleSize"]["Analyse statistique"].SizeCategory)</p>`n"
                $result += "<p><strong>Facteur d'ajustement pour distribution $($DataDistribution):</strong> $($recommendations["$sampleSize"]["Analyse statistique"].DistributionFactor)</p>`n"

                $result += "<h3>Recommandations par application:</h3>`n"
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "<h4>$application</h4>`n"
                    $result += "<p><strong>Séparation recommandée:</strong> $($rec.FinalSeparation) écarts-types ($($rec.FinalSeparationCategory))</p>`n"
                    $result += "<p><strong>Séparation en unités originales:</strong> $($rec.SeparationInOriginalUnits)</p>`n"
                    $result += "<div class='recommendations'>`n<h5>Recommandations spécifiques:</h5>`n<ul>`n"
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "<li>$recommendation</li>`n"
                    }
                    $result += "</ul>`n</div>`n"
                }
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "DataDistribution"  = $DataDistribution
                "NoiseLevel"        = $NoiseLevel
                "SmoothingMethod"   = $SmoothingMethod
                "StandardDeviation" = $StandardDeviation
                "Recommendations"   = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détermine les valeurs critiques pour le coefficient d'asymétrie (skewness).

.DESCRIPTION
    Cette fonction calcule les valeurs critiques pour le coefficient d'asymétrie
    en fonction de la taille d'échantillon, du niveau de confiance et d'autres paramètres.

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour la détection de l'asymétrie (par défaut "95%").

.PARAMETER Application
    L'application spécifique pour laquelle l'asymétrie est évaluée (par défaut "Analyse statistique").

.PARAMETER Direction
    La direction de l'asymétrie à détecter ("Positive", "Négative" ou "Bidirectionnelle", par défaut "Bidirectionnelle").

.EXAMPLE
    Get-SkewnessThreshold -SampleSize 200 -ConfidenceLevel "95%" -Application "Analyse statistique"
    Calcule les valeurs critiques pour le coefficient d'asymétrie pour un échantillon de 200 observations
    avec un niveau de confiance de 95% pour une application d'analyse statistique.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-SkewnessThreshold {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Exploration de données", "Analyse statistique", "Contrôle qualité", "Détection d'anomalies", "Classification", "Segmentation")]
        [string]$Application = "Analyse statistique",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Positive", "Négative", "Bidirectionnelle")]
        [string]$Direction = "Bidirectionnelle"
    )

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Obtenir le facteur d'ajustement pour cette taille d'échantillon
    $sizeAdjustmentFactor = $script:AsymmetryDetectionRecommendations.SkewnessFactorBySampleSize[$sizeCategory]

    # Obtenir le seuil de base par taille d'échantillon
    $baseThresholdCategory = $script:AsymmetryDetectionRecommendations.SkewnessBySampleSize[$sizeCategory]
    $baseThreshold = $script:AsymmetryDetectionRecommendations.SkewnessThresholds[$baseThresholdCategory]

    # Obtenir le seuil recommandé par niveau de confiance
    $confidenceThresholdCategory = $script:AsymmetryDetectionRecommendations.SkewnessByConfidenceLevel[$ConfidenceLevel]
    $confidenceThreshold = $script:AsymmetryDetectionRecommendations.SkewnessThresholds[$confidenceThresholdCategory]

    # Obtenir le seuil recommandé par application
    $applicationThresholdCategory = $script:AsymmetryDetectionRecommendations.SkewnessByApplication[$Application]
    $applicationThreshold = $script:AsymmetryDetectionRecommendations.SkewnessThresholds[$applicationThresholdCategory]

    # Calculer le seuil final en combinant les différents facteurs
    # Nous donnons plus de poids à la taille d'échantillon et au niveau de confiance
    $finalThreshold = $baseThreshold * $sizeAdjustmentFactor * 0.4 +
    $confidenceThreshold * 0.4 +
    $applicationThreshold * 0.2

    # Arrondir le seuil à 2 décimales
    $finalThreshold = [Math]::Round($finalThreshold, 2)

    # Déterminer la catégorie du seuil final
    $finalThresholdCategory = switch ($finalThreshold) {
        { $_ -le 0.1 } { "Symétrie parfaite" }
        { $_ -gt 0.1 -and $_ -le 0.35 } { "Quasi-symétrique" }
        { $_ -gt 0.35 -and $_ -le 0.75 } { "Légèrement asymétrique" }
        { $_ -gt 0.75 -and $_ -le 1.5 } { "Modérément asymétrique" }
        { $_ -gt 1.5 -and $_ -le 2.5 } { "Fortement asymétrique" }
        default { "Très asymétrique" }
    }

    # Ajuster les seuils en fonction de la direction
    $positiveThreshold = $finalThreshold
    $negativeThreshold = - $finalThreshold

    if ($Direction -eq "Positive") {
        # Pour la détection d'asymétrie positive uniquement, on peut être plus sensible
        $positiveThreshold = $finalThreshold * 0.8
        $negativeThreshold = -999  # Valeur impossible à atteindre
    } elseif ($Direction -eq "Négative") {
        # Pour la détection d'asymétrie négative uniquement, on peut être plus sensible
        $positiveThreshold = 999   # Valeur impossible à atteindre
        $negativeThreshold = - $finalThreshold * 0.8
    }

    # Calculer l'erreur standard du coefficient d'asymétrie
    # Formule: SE = sqrt(6/n) pour les grands échantillons
    $standardError = [Math]::Sqrt(6.0 / $SampleSize)

    # Calculer les intervalles de confiance
    $z90 = 1.645  # Valeur z pour un niveau de confiance de 90%
    $z95 = 1.96   # Valeur z pour un niveau de confiance de 95%
    $z99 = 2.576  # Valeur z pour un niveau de confiance de 99%

    $ci90 = $z90 * $standardError
    $ci95 = $z95 * $standardError
    $ci99 = $z99 * $standardError

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur la taille d'échantillon
    $recommendations += "Taille d'échantillon ($SampleSize observations, catégorie: $sizeCategory): seuil de base $baseThresholdCategory."
    $recommendations += "Facteur d'ajustement pour cette taille d'échantillon: $sizeAdjustmentFactor."

    # Recommandations basées sur le niveau de confiance
    $recommendations += "Niveau de confiance $($ConfidenceLevel): seuil recommandé $confidenceThresholdCategory."

    # Recommandations basées sur l'application
    if ($Application -eq "Exploration de données") {
        $recommendations += "Application '$Application': un seuil bas est recommandé pour détecter même les légères asymétries."
    } elseif ($Application -eq "Détection d'anomalies") {
        $recommendations += "Application '$Application': un seuil élevé est recommandé pour ne détecter que les fortes asymétries."
    } elseif ($Application -eq "Contrôle qualité") {
        $recommendations += "Application '$Application': un seuil modéré est recommandé pour détecter les asymétries significatives."
    }

    # Recommandations basées sur la direction
    if ($Direction -eq "Positive") {
        $recommendations += "Direction 'Positive': détection uniquement des asymétries positives (queue à droite)."
    } elseif ($Direction -eq "Négative") {
        $recommendations += "Direction 'Négative': détection uniquement des asymétries négatives (queue à gauche)."
    } else {
        $recommendations += "Direction 'Bidirectionnelle': détection des asymétries dans les deux directions."
    }

    # Recommandations sur l'interprétation
    $recommendations += "Erreur standard du coefficient d'asymétrie: $([Math]::Round($standardError, 3))."
    $recommendations += "Intervalle de confiance à 95%: ±$([Math]::Round($ci95, 2))."
    $recommendations += "Un coefficient d'asymétrie est statistiquement significatif s'il est supérieur à $([Math]::Round($ci95, 2)) en valeur absolue."

    # Recommandation finale
    if ($Direction -eq "Bidirectionnelle") {
        $recommendations += "Seuil final recommandé: ±$finalThreshold ($finalThresholdCategory)."
    } elseif ($Direction -eq "Positive") {
        $recommendations += "Seuil final recommandé: >$positiveThreshold ($finalThresholdCategory)."
    } else {
        $recommendations += "Seuil final recommandé: <$negativeThreshold ($finalThresholdCategory)."
    }

    # Créer l'objet de résultat
    $result = @{
        SampleSize                   = $SampleSize
        SizeCategory                 = $sizeCategory
        SizeAdjustmentFactor         = $sizeAdjustmentFactor
        ConfidenceLevel              = $ConfidenceLevel
        Application                  = $Application
        Direction                    = $Direction
        BaseThresholdCategory        = $baseThresholdCategory
        BaseThreshold                = $baseThreshold
        ConfidenceThresholdCategory  = $confidenceThresholdCategory
        ConfidenceThreshold          = $confidenceThreshold
        ApplicationThresholdCategory = $applicationThresholdCategory
        ApplicationThreshold         = $applicationThreshold
        FinalThreshold               = $finalThreshold
        FinalThresholdCategory       = $finalThresholdCategory
        PositiveThreshold            = $positiveThreshold
        NegativeThreshold            = $negativeThreshold
        StandardError                = $standardError
        ConfidenceInterval90         = $ci90
        ConfidenceInterval95         = $ci95
        ConfidenceInterval99         = $ci99
        Recommendations              = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport de recommandations de valeurs critiques pour le coefficient d'asymétrie.

.DESCRIPTION
    Cette fonction génère un rapport détaillé des recommandations de valeurs critiques
    pour le coefficient d'asymétrie pour différentes tailles d'échantillon et applications.

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour la détection de l'asymétrie (par défaut "95%").

.PARAMETER Direction
    La direction de l'asymétrie à détecter ("Positive", "Négative" ou "Bidirectionnelle", par défaut "Bidirectionnelle").

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-SkewnessThresholdReport -ConfidenceLevel "95%" -Direction "Bidirectionnelle" -Format "Text"
    Génère un rapport textuel des recommandations de valeurs critiques pour le coefficient d'asymétrie
    avec un niveau de confiance de 95% pour une détection bidirectionnelle.

.OUTPUTS
    System.String
#>
function Get-SkewnessThresholdReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Positive", "Négative", "Bidirectionnelle")]
        [string]$Direction = "Bidirectionnelle",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les tailles d'échantillon à analyser
    $sampleSizes = @(20, 50, 100, 200, 500, 1000, 5000)
    $applications = @("Exploration de données", "Analyse statistique", "Contrôle qualité", "Détection d'anomalies", "Classification", "Segmentation")
    $recommendations = @{}

    # Obtenir les recommandations pour chaque taille d'échantillon et application
    foreach ($sampleSize in $sampleSizes) {
        $recommendations["$sampleSize"] = @{}
        foreach ($application in $applications) {
            $recommendations["$sampleSize"][$application] = Get-SkewnessThreshold -SampleSize $sampleSize -ConfidenceLevel $ConfidenceLevel -Application $application -Direction $Direction
        }
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport de recommandations de valeurs critiques pour le coefficient d'asymétrie ===`n`n"
            $result += "Niveau de confiance: $ConfidenceLevel`n"
            $result += "Direction: $Direction`n`n"

            $result += "| Taille d'échantillon | Catégorie | Exploration | Analyse | Contrôle | Détection | Classification | Segmentation |`n"
            $result += "|---------------------|-----------|------------|---------|----------|-----------|----------------|--------------|`n"

            foreach ($sampleSize in $sampleSizes) {
                $sizeCategory = $recommendations["$sampleSize"]["Analyse statistique"].SizeCategory
                $explorationThreshold = $recommendations["$sampleSize"]["Exploration de données"].FinalThreshold
                $analysisThreshold = $recommendations["$sampleSize"]["Analyse statistique"].FinalThreshold
                $qualityThreshold = $recommendations["$sampleSize"]["Contrôle qualité"].FinalThreshold
                $detectionThreshold = $recommendations["$sampleSize"]["Détection d'anomalies"].FinalThreshold
                $classificationThreshold = $recommendations["$sampleSize"]["Classification"].FinalThreshold
                $segmentationThreshold = $recommendations["$sampleSize"]["Segmentation"].FinalThreshold

                $result += "| $sampleSize | $sizeCategory | $explorationThreshold | $analysisThreshold | $qualityThreshold | $detectionThreshold | $classificationThreshold | $segmentationThreshold |`n"
            }

            $result += "`n"

            foreach ($sampleSize in $sampleSizes) {
                $result += "## Taille d'échantillon: $sampleSize`n"
                $result += "Catégorie: $($recommendations["$sampleSize"]["Analyse statistique"].SizeCategory)`n"
                $result += "Facteur d'ajustement: $($recommendations["$sampleSize"]["Analyse statistique"].SizeAdjustmentFactor)`n"
                $result += "Erreur standard: $([Math]::Round($recommendations["$sampleSize"]["Analyse statistique"].StandardError, 3))`n"
                $result += "Intervalle de confiance à 95%: ±$([Math]::Round($recommendations["$sampleSize"]["Analyse statistique"].ConfidenceInterval95, 2))`n"

                $result += "`nRecommandations par application:`n"
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "### $application`n"
                    if ($Direction -eq "Bidirectionnelle") {
                        $result += "Seuil recommandé: ±$($rec.FinalThreshold) ($($rec.FinalThresholdCategory))`n"
                    } elseif ($Direction -eq "Positive") {
                        $result += "Seuil recommandé: >$($rec.PositiveThreshold) ($($rec.FinalThresholdCategory))`n"
                    } else {
                        $result += "Seuil recommandé: <$($rec.NegativeThreshold) ($($rec.FinalThresholdCategory))`n"
                    }
                    $result += "Recommandations spécifiques:`n"
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "- $recommendation`n"
                    }
                    $result += "`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "SampleSize,SizeCategory,Application,ConfidenceLevel,Direction,BaseThreshold,FinalThreshold,FinalThresholdCategory,PositiveThreshold,NegativeThreshold,StandardError,ConfidenceInterval95`n"

            foreach ($sampleSize in $sampleSizes) {
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "$($rec.SampleSize),$($rec.SizeCategory),$($rec.Application),$($rec.ConfidenceLevel),$($rec.Direction),$($rec.BaseThreshold),$($rec.FinalThreshold),$($rec.FinalThresholdCategory),$($rec.PositiveThreshold),$($rec.NegativeThreshold),$([Math]::Round($rec.StandardError, 3)),$([Math]::Round($rec.ConfidenceInterval95, 2))`n"
                }
            }

            $result += "`nSampleSize,Application,Recommendation`n"
            foreach ($sampleSize in $sampleSizes) {
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "$($rec.SampleSize),$($rec.Application),""$recommendation""`n"
                    }
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport de recommandations de valeurs critiques pour le coefficient d'asymétrie</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2, h3 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport de recommandations de valeurs critiques pour le coefficient d'asymétrie</h1>`n"
            $result += "<p><strong>Niveau de confiance:</strong> $ConfidenceLevel</p>`n"
            $result += "<p><strong>Direction:</strong> $Direction</p>`n"

            $result += "<table>`n"
            $result += "<tr><th>Taille d'échantillon</th><th>Catégorie</th><th>Exploration</th><th>Analyse</th><th>Contrôle</th><th>Détection</th><th>Classification</th><th>Segmentation</th></tr>`n"

            foreach ($sampleSize in $sampleSizes) {
                $sizeCategory = $recommendations["$sampleSize"]["Analyse statistique"].SizeCategory
                $explorationThreshold = $recommendations["$sampleSize"]["Exploration de données"].FinalThreshold
                $analysisThreshold = $recommendations["$sampleSize"]["Analyse statistique"].FinalThreshold
                $qualityThreshold = $recommendations["$sampleSize"]["Contrôle qualité"].FinalThreshold
                $detectionThreshold = $recommendations["$sampleSize"]["Détection d'anomalies"].FinalThreshold
                $classificationThreshold = $recommendations["$sampleSize"]["Classification"].FinalThreshold
                $segmentationThreshold = $recommendations["$sampleSize"]["Segmentation"].FinalThreshold

                $result += "<tr><td>$sampleSize</td><td>$sizeCategory</td><td>$explorationThreshold</td><td>$analysisThreshold</td><td>$qualityThreshold</td><td>$detectionThreshold</td><td>$classificationThreshold</td><td>$segmentationThreshold</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($sampleSize in $sampleSizes) {
                $result += "<h2>Taille d'échantillon: $sampleSize</h2>`n"
                $result += "<p><strong>Catégorie:</strong> $($recommendations["$sampleSize"]["Analyse statistique"].SizeCategory)</p>`n"
                $result += "<p><strong>Facteur d'ajustement:</strong> $($recommendations["$sampleSize"]["Analyse statistique"].SizeAdjustmentFactor)</p>`n"
                $result += "<p><strong>Erreur standard:</strong> $([Math]::Round($recommendations["$sampleSize"]["Analyse statistique"].StandardError, 3))</p>`n"
                $result += "<p><strong>Intervalle de confiance à 95%:</strong> ±$([Math]::Round($recommendations["$sampleSize"]["Analyse statistique"].ConfidenceInterval95, 2))</p>`n"

                $result += "<h3>Recommandations par application:</h3>`n"
                foreach ($application in $applications) {
                    $rec = $recommendations["$sampleSize"][$application]
                    $result += "<h4>$application</h4>`n"
                    if ($Direction -eq "Bidirectionnelle") {
                        $result += "<p><strong>Seuil recommandé:</strong> ±$($rec.FinalThreshold) ($($rec.FinalThresholdCategory))</p>`n"
                    } elseif ($Direction -eq "Positive") {
                        $result += "<p><strong>Seuil recommandé:</strong> >$($rec.PositiveThreshold) ($($rec.FinalThresholdCategory))</p>`n"
                    } else {
                        $result += "<p><strong>Seuil recommandé:</strong> <$($rec.NegativeThreshold) ($($rec.FinalThresholdCategory))</p>`n"
                    }
                    $result += "<div class='recommendations'>`n<h5>Recommandations spécifiques:</h5>`n<ul>`n"
                    foreach ($recommendation in $rec.Recommendations) {
                        $result += "<li>$recommendation</li>`n"
                    }
                    $result += "</ul>`n</div>`n"
                }
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "ConfidenceLevel" = $ConfidenceLevel
                "Direction"       = $Direction
                "Recommendations" = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Évalue l'asymétrie d'une distribution en utilisant des indicateurs basés sur la position centrale.

.DESCRIPTION
    Cette fonction évalue l'asymétrie d'une distribution en comparant la moyenne et la médiane,
    ainsi que d'autres indicateurs basés sur la position centrale.

.PARAMETER Mean
    La moyenne de la distribution.

.PARAMETER Median
    La médiane de la distribution.

.PARAMETER StandardDeviation
    L'écart-type de la distribution (par défaut 1.0).

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour l'évaluation de l'asymétrie (par défaut "95%").

.EXAMPLE
    Get-AsymmetryCentralIndicators -Mean 10.5 -Median 9.8 -StandardDeviation 2.5 -SampleSize 200
    Évalue l'asymétrie d'une distribution avec une moyenne de 10.5, une médiane de 9.8, un écart-type de 2.5
    et un échantillon de 200 observations.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-AsymmetryCentralIndicators {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double]$Mean,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double]$Median,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0001, [double]::MaxValue)]
        [double]$StandardDeviation = 1.0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%"
    )

    # Calculer la différence entre la moyenne et la médiane
    $meanMedianDifference = $Mean - $Median

    # Calculer la différence normalisée (en unités d'écart-type)
    $normalizedDifference = $meanMedianDifference / $StandardDeviation

    # Calculer le coefficient de Pearson (première mesure d'asymétrie)
    $pearsonCoefficient = 3 * ($Mean - $Median) / $StandardDeviation

    # Calculer l'erreur standard de la moyenne
    $standardErrorMean = $StandardDeviation / [Math]::Sqrt($SampleSize)

    # Calculer l'erreur standard de la médiane
    # Formule approximative: SE(médiane) ≈ 1.253 * SE(moyenne) pour les distributions normales
    $standardErrorMedian = 1.253 * $standardErrorMean

    # Calculer l'erreur standard de la différence
    $standardErrorDifference = [Math]::Sqrt([Math]::Pow($standardErrorMean, 2) + [Math]::Pow($standardErrorMedian, 2))

    # Calculer le z-score de la différence
    $zScore = $meanMedianDifference / $standardErrorDifference

    # Déterminer les valeurs critiques pour le z-score selon le niveau de confiance
    $criticalValue = switch ($ConfidenceLevel) {
        "90%" { 1.645 }
        "95%" { 1.96 }
        "99%" { 2.576 }
        default { 1.96 }
    }

    # Déterminer si la différence est statistiquement significative
    $isSignificant = [Math]::Abs($zScore) -gt $criticalValue

    # Déterminer la direction de l'asymétrie
    $skewnessDirection = if ($meanMedianDifference -gt 0) {
        "Positive (queue à droite)"
    } elseif ($meanMedianDifference -lt 0) {
        "Négative (queue à gauche)"
    } else {
        "Aucune (symétrique)"
    }

    # Déterminer l'intensité de l'asymétrie basée sur la différence normalisée
    $skewnessIntensity = switch ([Math]::Abs($normalizedDifference)) {
        { $_ -lt 0.1 } { "Négligeable" }
        { $_ -ge 0.1 -and $_ -lt 0.2 } { "Faible" }
        { $_ -ge 0.2 -and $_ -lt 0.5 } { "Modérée" }
        { $_ -ge 0.5 -and $_ -lt 1.0 } { "Forte" }
        default { "Très forte" }
    }

    # Calculer l'intervalle de confiance pour la différence
    $confidenceIntervalLower = $meanMedianDifference - $criticalValue * $standardErrorDifference
    $confidenceIntervalUpper = $meanMedianDifference + $criticalValue * $standardErrorDifference

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur la significativité statistique
    if ($isSignificant) {
        $recommendations += "La différence entre la moyenne ($Mean) et la médiane ($Median) est statistiquement significative (z = $([Math]::Round($zScore, 2)), p < $(switch ($ConfidenceLevel) { "90%" { "0.10" } "95%" { "0.05" } "99%" { "0.01" } default { "0.05" } }))."
        $recommendations += "Cette différence indique une asymétrie $skewnessDirection d'intensité $skewnessIntensity."

        if ($skewnessDirection -eq "Positive (queue à droite)") {
            $recommendations += "L'asymétrie positive suggère la présence de valeurs extrêmes élevées qui tirent la moyenne vers le haut."
        } elseif ($skewnessDirection -eq "Négative (queue à gauche)") {
            $recommendations += "L'asymétrie négative suggère la présence de valeurs extrêmes basses qui tirent la moyenne vers le bas."
        }
    } else {
        $recommendations += "La différence entre la moyenne ($Mean) et la médiane ($Median) n'est pas statistiquement significative (z = $([Math]::Round($zScore, 2)), p > $(switch ($ConfidenceLevel) { "90%" { "0.10" } "95%" { "0.05" } "99%" { "0.01" } default { "0.05" } }))."
        $recommendations += "Cette distribution peut être considérée comme approximativement symétrique selon ce critère."
    }

    # Recommandations basées sur l'intensité de l'asymétrie
    if ($skewnessIntensity -eq "Négligeable" -or $skewnessIntensity -eq "Faible") {
        $recommendations += "L'asymétrie est $skewnessIntensity (différence normalisée = $([Math]::Round($normalizedDifference, 3)) écarts-types). Les méthodes statistiques paramétriques peuvent généralement être utilisées."
    } elseif ($skewnessIntensity -eq "Modérée") {
        $recommendations += "L'asymétrie est $skewnessIntensity (différence normalisée = $([Math]::Round($normalizedDifference, 3)) écarts-types). Considérer des transformations de données ou des méthodes non paramétriques."
    } else {
        $recommendations += "L'asymétrie est $skewnessIntensity (différence normalisée = $([Math]::Round($normalizedDifference, 3)) écarts-types). Utiliser des méthodes non paramétriques ou appliquer des transformations appropriées."

        if ($skewnessDirection -eq "Positive (queue à droite)") {
            $recommendations += "Pour une asymétrie positive, considérer une transformation logarithmique, racine carrée ou Box-Cox."
        } elseif ($skewnessDirection -eq "Négative (queue à gauche)") {
            $recommendations += "Pour une asymétrie négative, considérer une transformation exponentielle ou Box-Cox."
        }
    }

    # Recommandations basées sur la taille de l'échantillon
    if ($SampleSize -lt 30) {
        $recommendations += "Attention: La taille d'échantillon est petite ($SampleSize < 30). Les estimations d'asymétrie peuvent être moins fiables."
    } elseif ($SampleSize -ge 30 -and $SampleSize -lt 100) {
        $recommendations += "La taille d'échantillon est modérée ($SampleSize). Les estimations d'asymétrie sont raisonnablement fiables."
    } else {
        $recommendations += "La taille d'échantillon est grande ($SampleSize). Les estimations d'asymétrie sont très fiables."
    }

    # Créer l'objet de résultat
    $result = @{
        Mean                    = $Mean
        Median                  = $Median
        StandardDeviation       = $StandardDeviation
        SampleSize              = $SampleSize
        ConfidenceLevel         = $ConfidenceLevel
        MeanMedianDifference    = $meanMedianDifference
        NormalizedDifference    = $normalizedDifference
        PearsonCoefficient      = $pearsonCoefficient
        StandardErrorMean       = $standardErrorMean
        StandardErrorMedian     = $standardErrorMedian
        StandardErrorDifference = $standardErrorDifference
        ZScore                  = $zScore
        CriticalValue           = $criticalValue
        IsSignificant           = $isSignificant
        SkewnessDirection       = $skewnessDirection
        SkewnessIntensity       = $skewnessIntensity
        ConfidenceIntervalLower = $confidenceIntervalLower
        ConfidenceIntervalUpper = $confidenceIntervalUpper
        Recommendations         = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport d'évaluation de l'asymétrie basé sur les indicateurs de position centrale.

.DESCRIPTION
    Cette fonction génère un rapport détaillé d'évaluation de l'asymétrie basé sur les indicateurs
    de position centrale pour différentes combinaisons de moyenne et médiane.

.PARAMETER StandardDeviation
    L'écart-type de la distribution (par défaut 1.0).

.PARAMETER SampleSize
    La taille de l'échantillon (nombre d'observations).

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour l'évaluation de l'asymétrie (par défaut "95%").

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-AsymmetryCentralIndicatorsReport -StandardDeviation 2.5 -SampleSize 200 -Format "Text"
    Génère un rapport textuel d'évaluation de l'asymétrie pour un écart-type de 2.5 et un échantillon de 200 observations.

.OUTPUTS
    System.String
#>
function Get-AsymmetryCentralIndicatorsReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0001, [double]::MaxValue)]
        [double]$StandardDeviation = 1.0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Définir les différences entre moyenne et médiane à analyser (en unités d'écart-type)
    $normalizedDifferences = @(-1.0, -0.5, -0.2, -0.1, 0, 0.1, 0.2, 0.5, 1.0)
    $recommendations = @{}

    # Calculer la moyenne de référence (arbitraire)
    $referenceMean = 100.0

    # Obtenir les recommandations pour chaque différence normalisée
    foreach ($diff in $normalizedDifferences) {
        # Calculer la médiane correspondante
        $median = $referenceMean - ($diff * $StandardDeviation)

        # Obtenir les indicateurs d'asymétrie
        $recommendations["$diff"] = Get-AsymmetryCentralIndicators -Mean $referenceMean -Median $median -StandardDeviation $StandardDeviation -SampleSize $SampleSize -ConfidenceLevel $ConfidenceLevel
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport d'évaluation de l'asymétrie basé sur les indicateurs de position centrale ===`n`n"
            $result += "Écart-type: $StandardDeviation`n"
            $result += "Taille d'échantillon: $SampleSize`n"
            $result += "Niveau de confiance: $ConfidenceLevel`n`n"

            $result += "| Différence normalisée | Moyenne | Médiane | Différence | Z-score | Significatif | Direction | Intensité |`n"
            $result += "|----------------------|---------|---------|------------|---------|--------------|-----------|-----------|`n"

            foreach ($diff in $normalizedDifferences) {
                $rec = $recommendations["$diff"]
                $significatif = if ($rec.IsSignificant) { "Oui" } else { "Non" }
                $result += "| $diff | $($rec.Mean) | $($rec.Median) | $([Math]::Round($rec.MeanMedianDifference, 2)) | $([Math]::Round($rec.ZScore, 2)) | $significatif | $($rec.SkewnessDirection) | $($rec.SkewnessIntensity) |`n"
            }

            $result += "`n"

            foreach ($diff in $normalizedDifferences) {
                $rec = $recommendations["$diff"]
                $result += "## Différence normalisée: $diff`n"
                $result += "Moyenne: $($rec.Mean)`n"
                $result += "Médiane: $($rec.Median)`n"
                $result += "Différence: $([Math]::Round($rec.MeanMedianDifference, 2))`n"
                $result += "Z-score: $([Math]::Round($rec.ZScore, 2))`n"
                $result += "Statistiquement significatif: $($rec.IsSignificant)`n"
                $result += "Direction de l'asymétrie: $($rec.SkewnessDirection)`n"
                $result += "Intensité de l'asymétrie: $($rec.SkewnessIntensity)`n"
                $result += "Intervalle de confiance: [$([Math]::Round($rec.ConfidenceIntervalLower, 2)), $([Math]::Round($rec.ConfidenceIntervalUpper, 2))]`n"

                $result += "`nRecommandations:`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "- $recommendation`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "DifferenceNormalisee,Moyenne,Mediane,Difference,ZScore,Significatif,Direction,Intensite`n"

            foreach ($diff in $normalizedDifferences) {
                $rec = $recommendations["$diff"]
                $significatif = if ($rec.IsSignificant) { "Oui" } else { "Non" }
                $result += "$diff,$($rec.Mean),$($rec.Median),$([Math]::Round($rec.MeanMedianDifference, 2)),$([Math]::Round($rec.ZScore, 2)),$significatif,""$($rec.SkewnessDirection)"",""$($rec.SkewnessIntensity)""`n"
            }

            $result += "`nDifferenceNormalisee,Recommendation`n"
            foreach ($diff in $normalizedDifferences) {
                $rec = $recommendations["$diff"]
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "$diff,""$recommendation""`n"
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport d'évaluation de l'asymétrie basé sur les indicateurs de position centrale</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport d'évaluation de l'asymétrie basé sur les indicateurs de position centrale</h1>`n"
            $result += "<p><strong>Écart-type:</strong> $StandardDeviation</p>`n"
            $result += "<p><strong>Taille d'échantillon:</strong> $SampleSize</p>`n"
            $result += "<p><strong>Niveau de confiance:</strong> $ConfidenceLevel</p>`n"

            $result += "<table>`n"
            $result += "<tr><th>Différence normalisée</th><th>Moyenne</th><th>Médiane</th><th>Différence</th><th>Z-score</th><th>Significatif</th><th>Direction</th><th>Intensité</th></tr>`n"

            foreach ($diff in $normalizedDifferences) {
                $rec = $recommendations["$diff"]
                $significatif = if ($rec.IsSignificant) { "Oui" } else { "Non" }
                $result += "<tr><td>$diff</td><td>$($rec.Mean)</td><td>$($rec.Median)</td><td>$([Math]::Round($rec.MeanMedianDifference, 2))</td><td>$([Math]::Round($rec.ZScore, 2))</td><td>$significatif</td><td>$($rec.SkewnessDirection)</td><td>$($rec.SkewnessIntensity)</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($diff in $normalizedDifferences) {
                $rec = $recommendations["$diff"]
                $result += "<h2>Différence normalisée: $diff</h2>`n"
                $result += "<p><strong>Moyenne:</strong> $($rec.Mean)</p>`n"
                $result += "<p><strong>Médiane:</strong> $($rec.Median)</p>`n"
                $result += "<p><strong>Différence:</strong> $([Math]::Round($rec.MeanMedianDifference, 2))</p>`n"
                $result += "<p><strong>Z-score:</strong> $([Math]::Round($rec.ZScore, 2))</p>`n"
                $result += "<p><strong>Statistiquement significatif:</strong> $($rec.IsSignificant)</p>`n"
                $result += "<p><strong>Direction de l'asymétrie:</strong> $($rec.SkewnessDirection)</p>`n"
                $result += "<p><strong>Intensité de l'asymétrie:</strong> $($rec.SkewnessIntensity)</p>`n"
                $result += "<p><strong>Intervalle de confiance:</strong> [$([Math]::Round($rec.ConfidenceIntervalLower, 2)), $([Math]::Round($rec.ConfidenceIntervalUpper, 2))]</p>`n"

                $result += "<div class='recommendations'>`n<h3>Recommandations:</h3>`n<ul>`n"
                foreach ($recommendation in $rec.Recommendations) {
                    $result += "<li>$recommendation</li>`n"
                }
                $result += "</ul>`n</div>`n"
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "StandardDeviation" = $StandardDeviation
                "SampleSize"        = $SampleSize
                "ConfidenceLevel"   = $ConfidenceLevel
                "Recommendations"   = $recommendations
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Calcule le ratio des longueurs de queue d'une distribution.

.DESCRIPTION
    Cette fonction calcule le ratio des longueurs de queue d'une distribution
    en utilisant différentes méthodes (percentiles, écarts-types, etc.).

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Method
    La méthode à utiliser pour calculer les longueurs de queue (par défaut "Percentile").

.PARAMETER PercentileThreshold
    Le seuil de percentile à utiliser pour définir les queues (par défaut 10).

.PARAMETER StdDevMultiplier
    Le multiplicateur d'écart-type à utiliser pour définir les queues (par défaut 1.5).

.PARAMETER Center
    La valeur centrale de la distribution (par défaut $null, calculée automatiquement).

.EXAMPLE
    Get-TailLengthRatio -Data $data -Method "Percentile" -PercentileThreshold 10
    Calcule le ratio des longueurs de queue en utilisant la méthode des percentiles avec un seuil de 10%.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-TailLengthRatio {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Percentile", "StdDev", "IQR")]
        [string]$Method = "Percentile",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 49)]
        [int]$PercentileThreshold = 10,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.1, 10.0)]
        [double]$StdDevMultiplier = 1.5,

        [Parameter(Mandatory = $false)]
        [double]$Center = $null
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour calculer le ratio des longueurs de queue."
    }

    # Trier les données
    $sortedData = $Data | Sort-Object

    # Calculer les statistiques de base
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

    # Calculer les quartiles
    $q1Index = [Math]::Floor($sortedData.Count * 0.25)
    $q3Index = [Math]::Floor($sortedData.Count * 0.75)
    $q1 = $sortedData[$q1Index]
    $q3 = $sortedData[$q3Index]
    $iqr = $q3 - $q1

    # Déterminer la valeur centrale
    if ($null -eq $Center) {
        # Par défaut, utiliser la médiane comme centre
        $Center = $median
    }

    # Variables pour stocker les résultats
    $leftTailLength = 0
    $rightTailLength = 0
    $leftTailPoints = 0
    $rightTailPoints = 0
    $tailRatio = 0
    $asymmetryDirection = "Aucune"
    $asymmetryIntensity = "Négligeable"

    # Calculer les longueurs de queue selon la méthode choisie
    switch ($Method) {
        "Percentile" {
            # Calculer les seuils de percentile
            $lowerPercentile = $PercentileThreshold
            $upperPercentile = 100 - $PercentileThreshold

            $lowerIndex = [Math]::Floor($sortedData.Count * ($lowerPercentile / 100))
            $upperIndex = [Math]::Floor($sortedData.Count * ($upperPercentile / 100))

            $lowerThreshold = $sortedData[$lowerIndex]
            $upperThreshold = $sortedData[$upperIndex]

            # Calculer les longueurs de queue
            $leftTailLength = [Math]::Abs($Center - $lowerThreshold)
            $rightTailLength = [Math]::Abs($upperThreshold - $Center)

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerThreshold }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperThreshold }).Count
        }
        "StdDev" {
            # Calculer les seuils basés sur l'écart-type
            $lowerThreshold = $Center - ($stdDev * $StdDevMultiplier)
            $upperThreshold = $Center + ($stdDev * $StdDevMultiplier)

            # Calculer les longueurs de queue
            $leftTailLength = [Math]::Abs($Center - $lowerThreshold)
            $rightTailLength = [Math]::Abs($upperThreshold - $Center)

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerThreshold }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperThreshold }).Count
        }
        "IQR" {
            # Calculer les seuils basés sur l'IQR
            $lowerThreshold = $q1 - ($iqr * $StdDevMultiplier)
            $upperThreshold = $q3 + ($iqr * $StdDevMultiplier)

            # Calculer les longueurs de queue
            $leftTailLength = [Math]::Abs($Center - $lowerThreshold)
            $rightTailLength = [Math]::Abs($upperThreshold - $Center)

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerThreshold }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperThreshold }).Count
        }
    }

    # Calculer le ratio des longueurs de queue (droite/gauche)
    if ($leftTailLength -ne 0) {
        $tailRatio = $rightTailLength / $leftTailLength
    } else {
        $tailRatio = [double]::PositiveInfinity
    }

    # Calculer le ratio des points dans les queues (droite/gauche)
    $pointsRatio = if ($leftTailPoints -ne 0) {
        $rightTailPoints / $leftTailPoints
    } else {
        [double]::PositiveInfinity
    }

    # Déterminer la direction de l'asymétrie
    if ($tailRatio -gt 1.1) {
        $asymmetryDirection = "Positive (queue à droite)"
    } elseif ($tailRatio -lt 0.9) {
        $asymmetryDirection = "Négative (queue à gauche)"
    } else {
        $asymmetryDirection = "Aucune (symétrique)"
    }

    # Déterminer l'intensité de l'asymétrie
    $asymmetryIntensity = switch ($tailRatio) {
        { $_ -gt 0.9 -and $_ -lt 1.1 } { "Négligeable" }
        { ($_ -ge 1.1 -and $_ -lt 1.5) -or ($_ -gt 0.67 -and $_ -le 0.9) } { "Faible" }
        { ($_ -ge 1.5 -and $_ -lt 2.0) -or ($_ -gt 0.5 -and $_ -le 0.67) } { "Modérée" }
        { ($_ -ge 2.0 -and $_ -lt 3.0) -or ($_ -gt 0.33 -and $_ -le 0.5) } { "Forte" }
        default { "Très forte" }
    }

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur la direction et l'intensité de l'asymétrie
    if ($asymmetryDirection -eq "Positive (queue à droite)") {
        $recommendations += "La distribution présente une asymétrie positive (queue à droite) d'intensité $asymmetryIntensity."
        $recommendations += "Le ratio des longueurs de queue (droite/gauche) est de $([Math]::Round($tailRatio, 2))."

        if ($asymmetryIntensity -eq "Négligeable" -or $asymmetryIntensity -eq "Faible") {
            $recommendations += "Cette asymétrie est $asymmetryIntensity et peut généralement être ignorée pour la plupart des analyses statistiques."
        } elseif ($asymmetryIntensity -eq "Modérée") {
            $recommendations += "Cette asymétrie est $asymmetryIntensity. Considérer des transformations de données (logarithmique, racine carrée) ou des méthodes non paramétriques."
        } else {
            $recommendations += "Cette asymétrie est $asymmetryIntensity. Utiliser des méthodes non paramétriques ou appliquer des transformations appropriées (logarithmique, racine carrée, Box-Cox)."
        }
    } elseif ($asymmetryDirection -eq "Négative (queue à gauche)") {
        $recommendations += "La distribution présente une asymétrie négative (queue à gauche) d'intensité $asymmetryIntensity."
        $recommendations += "Le ratio des longueurs de queue (droite/gauche) est de $([Math]::Round($tailRatio, 2))."

        if ($asymmetryIntensity -eq "Négligeable" -or $asymmetryIntensity -eq "Faible") {
            $recommendations += "Cette asymétrie est $asymmetryIntensity et peut généralement être ignorée pour la plupart des analyses statistiques."
        } elseif ($asymmetryIntensity -eq "Modérée") {
            $recommendations += "Cette asymétrie est $asymmetryIntensity. Considérer des transformations de données (exponentielle, élévation au carré) ou des méthodes non paramétriques."
        } else {
            $recommendations += "Cette asymétrie est $asymmetryIntensity. Utiliser des méthodes non paramétriques ou appliquer des transformations appropriées (exponentielle, élévation au carré, Box-Cox)."
        }
    } else {
        $recommendations += "La distribution est approximativement symétrique selon le ratio des longueurs de queue."
        $recommendations += "Le ratio des longueurs de queue (droite/gauche) est de $([Math]::Round($tailRatio, 2))."
        $recommendations += "Les méthodes statistiques paramétriques peuvent généralement être utilisées."
    }

    # Recommandations basées sur la méthode utilisée
    $recommendations += "Méthode utilisée pour calculer les longueurs de queue: $Method."

    if ($Method -eq "Percentile") {
        $recommendations += "Seuil de percentile utilisé: $PercentileThreshold%."
    } elseif ($Method -eq "StdDev") {
        $recommendations += "Multiplicateur d'écart-type utilisé: $StdDevMultiplier."
    } elseif ($Method -eq "IQR") {
        $recommendations += "Multiplicateur d'IQR utilisé: $StdDevMultiplier."
    }

    # Recommandations basées sur le nombre de points dans les queues
    $recommendations += "Nombre de points dans la queue gauche: $leftTailPoints."
    $recommendations += "Nombre de points dans la queue droite: $rightTailPoints."
    $recommendations += "Ratio des points dans les queues (droite/gauche): $([Math]::Round($pointsRatio, 2))."

    if ($leftTailPoints -lt 5 -or $rightTailPoints -lt 5) {
        $recommendations += "Attention: Une ou les deux queues contiennent moins de 5 points, ce qui peut rendre l'estimation de l'asymétrie moins fiable."
    }

    # Créer l'objet de résultat
    $result = @{
        Data                = $Data
        Method              = $Method
        PercentileThreshold = $PercentileThreshold
        StdDevMultiplier    = $StdDevMultiplier
        Center              = $Center
        Mean                = $mean
        Median              = $median
        StdDev              = $stdDev
        Q1                  = $q1
        Q3                  = $q3
        IQR                 = $iqr
        LeftTailLength      = $leftTailLength
        RightTailLength     = $rightTailLength
        TailRatio           = $tailRatio
        LeftTailPoints      = $leftTailPoints
        RightTailPoints     = $rightTailPoints
        PointsRatio         = $pointsRatio
        AsymmetryDirection  = $asymmetryDirection
        AsymmetryIntensity  = $asymmetryIntensity
        Recommendations     = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Génère un rapport d'évaluation de l'asymétrie basé sur les ratios de longueur de queue.

.DESCRIPTION
    Cette fonction génère un rapport détaillé d'évaluation de l'asymétrie basé sur les ratios
    de longueur de queue pour différentes distributions.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Methods
    Les méthodes à utiliser pour calculer les longueurs de queue (par défaut toutes).

.PARAMETER Format
    Le format de sortie du rapport (par défaut "Text").

.EXAMPLE
    Get-TailLengthRatioReport -Data $data -Format "Text"
    Génère un rapport textuel d'évaluation de l'asymétrie basé sur les ratios de longueur de queue.

.OUTPUTS
    System.String
#>
function Get-TailLengthRatioReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Percentile", "StdDev", "IQR", "All")]
        [string]$Methods = "All",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    # Déterminer les méthodes à utiliser
    $methodsToUse = @()
    if ($Methods -eq "All") {
        $methodsToUse = @("Percentile", "StdDev", "IQR")
    } else {
        $methodsToUse = @($Methods)
    }

    # Calculer les ratios de longueur de queue pour chaque méthode
    $results = @{}
    foreach ($method in $methodsToUse) {
        $results[$method] = Get-TailLengthRatio -Data $Data -Method $method
    }

    # Générer le rapport au format demandé
    switch ($Format) {
        "Text" {
            $result = "=== Rapport d'évaluation de l'asymétrie basé sur les ratios de longueur de queue ===`n`n"
            $result += "Nombre d'observations: $($Data.Count)`n"
            $result += "Moyenne: $([Math]::Round($results[$methodsToUse[0]].Mean, 2))`n"
            $result += "Médiane: $([Math]::Round($results[$methodsToUse[0]].Median, 2))`n"
            $result += "Écart-type: $([Math]::Round($results[$methodsToUse[0]].StdDev, 2))`n"
            $result += "Q1: $([Math]::Round($results[$methodsToUse[0]].Q1, 2))`n"
            $result += "Q3: $([Math]::Round($results[$methodsToUse[0]].Q3, 2))`n"
            $result += "IQR: $([Math]::Round($results[$methodsToUse[0]].IQR, 2))`n`n"

            $result += "| Méthode | Queue gauche | Queue droite | Ratio | Direction | Intensité |`n"
            $result += "|---------|-------------|--------------|-------|-----------|-----------|`n"

            foreach ($method in $methodsToUse) {
                $res = $results[$method]
                $result += "| $method | $([Math]::Round($res.LeftTailLength, 2)) | $([Math]::Round($res.RightTailLength, 2)) | $([Math]::Round($res.TailRatio, 2)) | $($res.AsymmetryDirection) | $($res.AsymmetryIntensity) |`n"
            }

            $result += "`n"

            foreach ($method in $methodsToUse) {
                $res = $results[$method]
                $result += "## Méthode: $method`n"
                $result += "Longueur de la queue gauche: $([Math]::Round($res.LeftTailLength, 2))`n"
                $result += "Longueur de la queue droite: $([Math]::Round($res.RightTailLength, 2))`n"
                $result += "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($res.TailRatio, 2))`n"
                $result += "Nombre de points dans la queue gauche: $($res.LeftTailPoints)`n"
                $result += "Nombre de points dans la queue droite: $($res.RightTailPoints)`n"
                $result += "Ratio des points dans les queues (droite/gauche): $([Math]::Round($res.PointsRatio, 2))`n"
                $result += "Direction de l'asymétrie: $($res.AsymmetryDirection)`n"
                $result += "Intensité de l'asymétrie: $($res.AsymmetryIntensity)`n"

                $result += "`nRecommandations:`n"
                foreach ($recommendation in $res.Recommendations) {
                    $result += "- $recommendation`n"
                }

                $result += "`n"
            }

            $result += "=== Fin du rapport ===`n"
        }
        "CSV" {
            $result = "Method,LeftTailLength,RightTailLength,TailRatio,LeftTailPoints,RightTailPoints,PointsRatio,AsymmetryDirection,AsymmetryIntensity`n"

            foreach ($method in $methodsToUse) {
                $res = $results[$method]
                $result += "$method,$([Math]::Round($res.LeftTailLength, 2)),$([Math]::Round($res.RightTailLength, 2)),$([Math]::Round($res.TailRatio, 2)),$($res.LeftTailPoints),$($res.RightTailPoints),$([Math]::Round($res.PointsRatio, 2)),""$($res.AsymmetryDirection)"",""$($res.AsymmetryIntensity)""`n"
            }

            $result += "`nMethod,Recommendation`n"
            foreach ($method in $methodsToUse) {
                $res = $results[$method]
                foreach ($recommendation in $res.Recommendations) {
                    $result += "$method,""$recommendation""`n"
                }
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Rapport d'évaluation de l'asymétrie basé sur les ratios de longueur de queue</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".recommendations { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Rapport d'évaluation de l'asymétrie basé sur les ratios de longueur de queue</h1>`n"
            $result += "<p><strong>Nombre d'observations:</strong> $($Data.Count)</p>`n"
            $result += "<p><strong>Moyenne:</strong> $([Math]::Round($results[$methodsToUse[0]].Mean, 2))</p>`n"
            $result += "<p><strong>Médiane:</strong> $([Math]::Round($results[$methodsToUse[0]].Median, 2))</p>`n"
            $result += "<p><strong>Écart-type:</strong> $([Math]::Round($results[$methodsToUse[0]].StdDev, 2))</p>`n"
            $result += "<p><strong>Q1:</strong> $([Math]::Round($results[$methodsToUse[0]].Q1, 2))</p>`n"
            $result += "<p><strong>Q3:</strong> $([Math]::Round($results[$methodsToUse[0]].Q3, 2))</p>`n"
            $result += "<p><strong>IQR:</strong> $([Math]::Round($results[$methodsToUse[0]].IQR, 2))</p>`n"

            $result += "<table>`n"
            $result += "<tr><th>Méthode</th><th>Queue gauche</th><th>Queue droite</th><th>Ratio</th><th>Direction</th><th>Intensité</th></tr>`n"

            foreach ($method in $methodsToUse) {
                $res = $results[$method]
                $result += "<tr><td>$method</td><td>$([Math]::Round($res.LeftTailLength, 2))</td><td>$([Math]::Round($res.RightTailLength, 2))</td><td>$([Math]::Round($res.TailRatio, 2))</td><td>$($res.AsymmetryDirection)</td><td>$($res.AsymmetryIntensity)</td></tr>`n"
            }

            $result += "</table>`n"

            foreach ($method in $methodsToUse) {
                $res = $results[$method]
                $result += "<h2>Méthode: $method</h2>`n"
                $result += "<p><strong>Longueur de la queue gauche:</strong> $([Math]::Round($res.LeftTailLength, 2))</p>`n"
                $result += "<p><strong>Longueur de la queue droite:</strong> $([Math]::Round($res.RightTailLength, 2))</p>`n"
                $result += "<p><strong>Ratio des longueurs de queue (droite/gauche):</strong> $([Math]::Round($res.TailRatio, 2))</p>`n"
                $result += "<p><strong>Nombre de points dans la queue gauche:</strong> $($res.LeftTailPoints)</p>`n"
                $result += "<p><strong>Nombre de points dans la queue droite:</strong> $($res.RightTailPoints)</p>`n"
                $result += "<p><strong>Ratio des points dans les queues (droite/gauche):</strong> $([Math]::Round($res.PointsRatio, 2))</p>`n"
                $result += "<p><strong>Direction de l'asymétrie:</strong> $($res.AsymmetryDirection)</p>`n"
                $result += "<p><strong>Intensité de l'asymétrie:</strong> $($res.AsymmetryIntensity)</p>`n"

                $result += "<div class='recommendations'>`n<h3>Recommandations:</h3>`n<ul>`n"
                foreach ($recommendation in $res.Recommendations) {
                    $result += "<li>$recommendation</li>`n"
                }
                $result += "</ul>`n</div>`n"
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "DataSummary" = @{
                    "Count"  = $Data.Count
                    "Mean"   = $results[$methodsToUse[0]].Mean
                    "Median" = $results[$methodsToUse[0]].Median
                    "StdDev" = $results[$methodsToUse[0]].StdDev
                    "Q1"     = $results[$methodsToUse[0]].Q1
                    "Q3"     = $results[$methodsToUse[0]].Q3
                    "IQR"    = $results[$methodsToUse[0]].IQR
                }
                "Results"     = $results
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détecte les limites des queues d'une distribution par différentes méthodes.

.DESCRIPTION
    Cette fonction détecte les limites des queues d'une distribution en utilisant
    différentes méthodes (percentiles, écarts-types, IQR, etc.).

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Method
    La méthode à utiliser pour détecter les limites des queues (par défaut "Percentile").

.PARAMETER PercentileThreshold
    Le seuil de percentile à utiliser pour définir les queues (par défaut 10).

.PARAMETER StdDevMultiplier
    Le multiplicateur d'écart-type à utiliser pour définir les queues (par défaut 1.5).

.PARAMETER IQRMultiplier
    Le multiplicateur d'IQR à utiliser pour définir les queues (par défaut 1.5).

.PARAMETER Center
    La valeur centrale de la distribution (par défaut $null, calculée automatiquement).

.EXAMPLE
    Get-DistributionTailBoundaries -Data $data -Method "Percentile" -PercentileThreshold 10
    Détecte les limites des queues en utilisant la méthode des percentiles avec un seuil de 10%.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-DistributionTailBoundaries {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Percentile", "StdDev", "IQR", "MAD", "Adaptive")]
        [string]$Method = "Percentile",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 49)]
        [int]$PercentileThreshold = 10,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.1, 10.0)]
        [double]$StdDevMultiplier = 1.5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.1, 10.0)]
        [double]$IQRMultiplier = 1.5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.1, 10.0)]
        [double]$MADMultiplier = 2.0,

        [Parameter(Mandatory = $false)]
        [double]$Center = $null
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour détecter les limites des queues."
    }

    # Trier les données
    $sortedData = $Data | Sort-Object

    # Calculer les statistiques de base
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

    # Calculer les quartiles
    $q1Index = [Math]::Floor($sortedData.Count * 0.25)
    $q3Index = [Math]::Floor($sortedData.Count * 0.75)
    $q1 = $sortedData[$q1Index]
    $q3 = $sortedData[$q3Index]
    $iqr = $q3 - $q1

    # Calculer la déviation absolue médiane (MAD)
    $deviations = $sortedData | ForEach-Object { [Math]::Abs($_ - $median) }
    $sortedDeviations = $deviations | Sort-Object
    $mad = if ($sortedDeviations.Count % 2 -eq 0) {
        ($sortedDeviations[$sortedDeviations.Count / 2 - 1] + $sortedDeviations[$sortedDeviations.Count / 2]) / 2
    } else {
        $sortedDeviations[[Math]::Floor($sortedDeviations.Count / 2)]
    }
    # Facteur de normalisation pour que MAD soit comparable à l'écart-type pour une distribution normale
    $madNormalized = $mad * 1.4826

    # Déterminer la valeur centrale
    if ($null -eq $Center) {
        # Par défaut, utiliser la médiane comme centre
        $Center = $median
    }

    # Variables pour stocker les résultats
    $lowerBound = 0
    $upperBound = 0
    $leftTailPoints = 0
    $rightTailPoints = 0
    $methodDescription = ""

    # Détecter les limites des queues selon la méthode choisie
    switch ($Method) {
        "Percentile" {
            # Calculer les seuils de percentile
            $lowerPercentile = $PercentileThreshold
            $upperPercentile = 100 - $PercentileThreshold

            $lowerIndex = [Math]::Floor($sortedData.Count * ($lowerPercentile / 100))
            $upperIndex = [Math]::Floor($sortedData.Count * ($upperPercentile / 100))

            $lowerBound = $sortedData[$lowerIndex]
            $upperBound = $sortedData[$upperIndex]

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerBound }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperBound }).Count

            $methodDescription = "Méthode des percentiles avec un seuil de $PercentileThreshold%"
        }
        "StdDev" {
            # Calculer les seuils basés sur l'écart-type
            $lowerBound = $Center - ($stdDev * $StdDevMultiplier)
            $upperBound = $Center + ($stdDev * $StdDevMultiplier)

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerBound }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperBound }).Count

            $methodDescription = "Méthode de l'écart-type avec un multiplicateur de $StdDevMultiplier"
        }
        "IQR" {
            # Calculer les seuils basés sur l'IQR
            $lowerBound = $q1 - ($iqr * $IQRMultiplier)
            $upperBound = $q3 + ($iqr * $IQRMultiplier)

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerBound }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperBound }).Count

            $methodDescription = "Méthode de l'IQR avec un multiplicateur de $IQRMultiplier"
        }
        "MAD" {
            # Calculer les seuils basés sur la MAD
            $lowerBound = $median - ($madNormalized * $MADMultiplier)
            $upperBound = $median + ($madNormalized * $MADMultiplier)

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerBound }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperBound }).Count

            $methodDescription = "Méthode de la MAD avec un multiplicateur de $MADMultiplier"
        }
        "Adaptive" {
            # Méthode adaptative qui choisit la méthode la plus appropriée en fonction des caractéristiques des données

            # Calculer le coefficient d'asymétrie (skewness)
            $skewness = 0
            $n = $sortedData.Count
            if ($n -gt 2) {
                $sumCubed = 0
                foreach ($value in $sortedData) {
                    $sumCubed += [Math]::Pow(($value - $mean) / $stdDev, 3)
                }
                $skewness = $n * $sumCubed / (($n - 1) * ($n - 2))
            }

            # Calculer le coefficient d'aplatissement (kurtosis)
            $kurtosis = 0
            if ($n -gt 3) {
                $sumPow4 = 0
                foreach ($value in $sortedData) {
                    $sumPow4 += [Math]::Pow(($value - $mean) / $stdDev, 4)
                }
                $kurtosis = $n * ($n + 1) * $sumPow4 / (($n - 1) * ($n - 2) * ($n - 3)) - 3 * [Math]::Pow($n - 1, 2) / (($n - 2) * ($n - 3))
            }

            # Choisir la méthode en fonction des caractéristiques des données
            if ([Math]::Abs($skewness) -gt 1.0 -or $kurtosis -gt 3.0) {
                # Distribution asymétrique ou à queue lourde, utiliser la méthode IQR
                $lowerBound = $q1 - ($iqr * $IQRMultiplier)
                $upperBound = $q3 + ($iqr * $IQRMultiplier)
                $methodDescription = "Méthode adaptative: IQR (asymétrie=$([Math]::Round($skewness, 2)), kurtosis=$([Math]::Round($kurtosis, 2)))"
            } elseif ($n -lt 30) {
                # Petit échantillon, utiliser la méthode MAD
                $lowerBound = $median - ($madNormalized * $MADMultiplier)
                $upperBound = $median + ($madNormalized * $MADMultiplier)
                $methodDescription = "Méthode adaptative: MAD (petit échantillon, n=$n)"
            } else {
                # Distribution proche de la normale, utiliser la méthode de l'écart-type
                $lowerBound = $mean - ($stdDev * $StdDevMultiplier)
                $upperBound = $mean + ($stdDev * $StdDevMultiplier)
                $methodDescription = "Méthode adaptative: Écart-type (distribution proche de la normale)"
            }

            # Compter les points dans chaque queue
            $leftTailPoints = ($sortedData | Where-Object { $_ -lt $lowerBound }).Count
            $rightTailPoints = ($sortedData | Where-Object { $_ -gt $upperBound }).Count
        }
    }

    # Calculer les longueurs des queues
    $leftTailLength = [Math]::Abs($Center - $lowerBound)
    $rightTailLength = [Math]::Abs($upperBound - $Center)

    # Calculer le ratio des longueurs de queue (droite/gauche)
    $tailRatio = if ($leftTailLength -ne 0) {
        $rightTailLength / $leftTailLength
    } else {
        [double]::PositiveInfinity
    }

    # Calculer le ratio des points dans les queues (droite/gauche)
    $pointsRatio = if ($leftTailPoints -ne 0) {
        $rightTailPoints / $leftTailPoints
    } else {
        [double]::PositiveInfinity
    }

    # Déterminer la direction de l'asymétrie
    $asymmetryDirection = if ($tailRatio -gt 1.1) {
        "Positive (queue à droite)"
    } elseif ($tailRatio -lt 0.9) {
        "Négative (queue à gauche)"
    } else {
        "Aucune (symétrique)"
    }

    # Déterminer l'intensité de l'asymétrie
    $asymmetryIntensity = switch ($tailRatio) {
        { $_ -gt 0.9 -and $_ -lt 1.1 } { "Négligeable" }
        { ($_ -ge 1.1 -and $_ -lt 1.5) -or ($_ -gt 0.67 -and $_ -le 0.9) } { "Faible" }
        { ($_ -ge 1.5 -and $_ -lt 2.0) -or ($_ -gt 0.5 -and $_ -le 0.67) } { "Modérée" }
        { ($_ -ge 2.0 -and $_ -lt 3.0) -or ($_ -gt 0.33 -and $_ -le 0.5) } { "Forte" }
        default { "Très forte" }
    }

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur la méthode utilisée
    $recommendations += "Méthode utilisée: $methodDescription."

    # Recommandations basées sur les limites des queues
    $recommendations += "Limite inférieure (queue gauche): $([Math]::Round($lowerBound, 2))."
    $recommendations += "Limite supérieure (queue droite): $([Math]::Round($upperBound, 2))."
    $recommendations += "Longueur de la queue gauche: $([Math]::Round($leftTailLength, 2))."
    $recommendations += "Longueur de la queue droite: $([Math]::Round($rightTailLength, 2))."
    $recommendations += "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($tailRatio, 2))."

    # Recommandations basées sur le nombre de points dans les queues
    $recommendations += "Nombre de points dans la queue gauche: $leftTailPoints."
    $recommendations += "Nombre de points dans la queue droite: $rightTailPoints."
    $recommendations += "Ratio des points dans les queues (droite/gauche): $([Math]::Round($pointsRatio, 2))."

    if ($leftTailPoints -lt 5 -or $rightTailPoints -lt 5) {
        $recommendations += "Attention: Une ou les deux queues contiennent moins de 5 points, ce qui peut rendre l'estimation de l'asymétrie moins fiable."
    }

    # Recommandations basées sur la direction et l'intensité de l'asymétrie
    $recommendations += "Direction de l'asymétrie: $asymmetryDirection."
    $recommendations += "Intensité de l'asymétrie: $asymmetryIntensity."

    if ($asymmetryDirection -eq "Positive (queue à droite)" -and $asymmetryIntensity -ne "Négligeable") {
        $recommendations += "Cette distribution présente une asymétrie positive, ce qui suggère la présence de valeurs extrêmes élevées qui tirent la moyenne vers le haut."
    } elseif ($asymmetryDirection -eq "Négative (queue à gauche)" -and $asymmetryIntensity -ne "Négligeable") {
        $recommendations += "Cette distribution présente une asymétrie négative, ce qui suggère la présence de valeurs extrêmes basses qui tirent la moyenne vers le bas."
    }

    # Créer l'objet de résultat
    $result = @{
        Data                = $Data
        Method              = $Method
        MethodDescription   = $methodDescription
        PercentileThreshold = $PercentileThreshold
        StdDevMultiplier    = $StdDevMultiplier
        IQRMultiplier       = $IQRMultiplier
        MADMultiplier       = $MADMultiplier
        Center              = $Center
        Mean                = $mean
        Median              = $median
        StdDev              = $stdDev
        Q1                  = $q1
        Q3                  = $q3
        IQR                 = $iqr
        MAD                 = $mad
        MADNormalized       = $madNormalized
        LowerBound          = $lowerBound
        UpperBound          = $upperBound
        LeftTailLength      = $leftTailLength
        RightTailLength     = $rightTailLength
        TailRatio           = $tailRatio
        LeftTailPoints      = $leftTailPoints
        RightTailPoints     = $rightTailPoints
        PointsRatio         = $pointsRatio
        AsymmetryDirection  = $asymmetryDirection
        AsymmetryIntensity  = $asymmetryIntensity
        Recommendations     = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Compare les limites des queues d'une distribution détectées par différentes méthodes.

.DESCRIPTION
    Cette fonction compare les limites des queues d'une distribution détectées par
    différentes méthodes et recommande la méthode la plus appropriée.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Methods
    Les méthodes à comparer (par défaut toutes).

.PARAMETER Center
    La valeur centrale de la distribution (par défaut $null, calculée automatiquement).

.EXAMPLE
    Compare-TailBoundaryMethods -Data $data
    Compare les limites des queues détectées par différentes méthodes.

.OUTPUTS
    System.Collections.Hashtable
#>
function Compare-TailBoundaryMethods {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Percentile", "StdDev", "IQR", "MAD", "Adaptive", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [double]$Center = $null
    )

    # Déterminer les méthodes à comparer
    $methodsToCompare = @()
    if ($Methods -contains "All") {
        $methodsToCompare = @("Percentile", "StdDev", "IQR", "MAD", "Adaptive")
    } else {
        $methodsToCompare = $Methods
    }

    # Calculer les limites des queues pour chaque méthode
    $results = @{}
    foreach ($method in $methodsToCompare) {
        $results[$method] = Get-DistributionTailBoundaries -Data $Data -Method $method -Center $Center
    }

    # Calculer les statistiques de base
    $mean = ($Data | Measure-Object -Average).Average
    $median = if ($Data.Count % 2 -eq 0) {
        ($Data[$Data.Count / 2 - 1] + $Data[$Data.Count / 2]) / 2
    } else {
        $Data[[Math]::Floor($Data.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

    # Calculer le coefficient d'asymétrie (skewness)
    $skewness = 0
    $n = $Data.Count
    if ($n -gt 2) {
        $sumCubed = 0
        foreach ($value in $Data) {
            $sumCubed += [Math]::Pow(($value - $mean) / $stdDev, 3)
        }
        $skewness = $n * $sumCubed / (($n - 1) * ($n - 2))
    }

    # Calculer le coefficient d'aplatissement (kurtosis)
    $kurtosis = 0
    if ($n -gt 3) {
        $sumPow4 = 0
        foreach ($value in $Data) {
            $sumPow4 += [Math]::Pow(($value - $mean) / $stdDev, 4)
        }
        $kurtosis = $n * ($n + 1) * $sumPow4 / (($n - 1) * ($n - 2) * ($n - 3)) - 3 * [Math]::Pow($n - 1, 2) / (($n - 2) * ($n - 3))
    }

    # Déterminer la méthode recommandée en fonction des caractéristiques des données
    $recommendedMethod = ""
    $recommendationReason = ""

    if ([Math]::Abs($skewness) -gt 1.0 -or $kurtosis -gt 3.0) {
        # Distribution asymétrique ou à queue lourde, recommander la méthode IQR
        $recommendedMethod = "IQR"
        $recommendationReason = "Distribution asymétrique (skewness=$([Math]::Round($skewness, 2))) ou à queue lourde (kurtosis=$([Math]::Round($kurtosis, 2)))"
    } elseif ($n -lt 30) {
        # Petit échantillon, recommander la méthode MAD
        $recommendedMethod = "MAD"
        $recommendationReason = "Petit échantillon (n=$n)"
    } else {
        # Distribution proche de la normale, recommander la méthode de l'écart-type
        $recommendedMethod = "StdDev"
        $recommendationReason = "Distribution proche de la normale (skewness=$([Math]::Round($skewness, 2)), kurtosis=$([Math]::Round($kurtosis, 2)))"
    }

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur les caractéristiques des données
    $recommendations += "Taille de l'échantillon: $n observations."
    $recommendations += "Moyenne: $([Math]::Round($mean, 2))."
    $recommendations += "Médiane: $([Math]::Round($median, 2))."
    $recommendations += "Écart-type: $([Math]::Round($stdDev, 2))."
    $recommendations += "Coefficient d'asymétrie (skewness): $([Math]::Round($skewness, 2))."
    $recommendations += "Coefficient d'aplatissement (kurtosis): $([Math]::Round($kurtosis, 2))."

    # Recommandations basées sur la méthode recommandée
    $recommendations += "Méthode recommandée: $recommendedMethod."
    $recommendations += "Raison: $recommendationReason."

    # Recommandations basées sur la comparaison des méthodes
    $recommendations += "Comparaison des limites des queues détectées par différentes méthodes:"
    foreach ($method in $methodsToCompare) {
        $result = $results[$method]
        $recommendations += "- $($result.MethodDescription): Limite inférieure = $([Math]::Round($result.LowerBound, 2)), Limite supérieure = $([Math]::Round($result.UpperBound, 2)), Points dans les queues: $($result.LeftTailPoints) (gauche), $($result.RightTailPoints) (droite)."
    }

    # Créer l'objet de résultat
    $result = @{
        Data                 = $Data
        Methods              = $methodsToCompare
        Results              = $results
        Mean                 = $mean
        Median               = $median
        StdDev               = $stdDev
        Skewness             = $skewness
        Kurtosis             = $kurtosis
        RecommendedMethod    = $recommendedMethod
        RecommendationReason = $recommendationReason
        Recommendations      = $recommendations
    }

    return $result
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-HistogramBinCount, Get-HistogramBinWidth, Get-OptimalBinWidthRecommendation, Get-BinWidthRecommendationReport, Get-ScatterPlotPointDensity, Get-ScatterPlotDensityReport, Get-JitteringParameters, Get-JitteringRecommendationReport, Get-BoxplotMinWidth, Get-BoxplotWidthReport, Get-BoxplotSpacing, Get-BoxplotSpacingReport, Get-ModeHeightThreshold, Get-ModeHeightThresholdReport, Get-ModeSeparationThreshold, Get-ModeSeparationReport, Get-SkewnessThreshold, Get-SkewnessThresholdReport, Get-AsymmetryCentralIndicators, Get-AsymmetryCentralIndicatorsReport, Get-TailLengthRatio, Get-TailLengthRatioReport, Get-DistributionTailBoundaries, Compare-TailBoundaryMethods

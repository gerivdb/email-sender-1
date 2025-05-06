# Implémentation de l'algorithme de calcul de l'indice global de conservation des moments

## 1. Introduction

Ce document décrit l'implémentation de l'algorithme de calcul de l'indice global de conservation des moments (IGCM) pour les histogrammes de latence. Cet algorithme permet d'évaluer, par une métrique unique et interprétable, la fidélité avec laquelle un histogramme préserve l'ensemble des caractéristiques statistiques importantes d'une distribution de latence. L'implémentation fournit également des outils pour déterminer le niveau de qualité correspondant à l'indice calculé et pour optimiser les configurations d'histogrammes afin d'atteindre un niveau de qualité cible.

## 2. Architecture de l'implémentation

### 2.1 Structure des modules

L'implémentation est organisée en un module Python principal `global_moment_conservation_index.py` qui contient les fonctions suivantes :

1. **Fonctions de calcul d'erreur** : Calculent les erreurs relatives pour chaque moment statistique
   - `calculate_mean_relative_error`
   - `calculate_variance_relative_error`
   - `calculate_skewness_relative_error`
   - `calculate_kurtosis_relative_error`

2. **Fonction principale de calcul de l'IGCM** : Calcule l'indice global à partir des erreurs
   - `calculate_global_moment_conservation_index`

3. **Fonctions d'interprétation** : Déterminent le niveau de qualité correspondant à l'IGCM
   - `get_quality_level`

4. **Fonctions utilitaires** : Génèrent et évaluent des histogrammes
   - `generate_histogram`
   - `evaluate_histogram_quality`
   - `optimize_histogram_config`

### 2.2 Dépendances

L'implémentation dépend des bibliothèques Python suivantes :
- `numpy` : Pour les calculs numériques
- `scipy.stats` : Pour les calculs statistiques avancés
- `math` : Pour les fonctions mathématiques de base
- `matplotlib` (optionnel) : Pour la visualisation des histogrammes

## 3. Implémentation des fonctions principales

### 3.1 Calcul des erreurs relatives

#### 3.1.1 Erreur relative de la moyenne

```python
def calculate_mean_relative_error(real_data, bin_edges, bin_counts):
    """
    Calcule l'erreur relative de la moyenne.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        
    Returns:
        relative_error: Erreur relative en pourcentage
    """
    real_mean = np.mean(real_data)
    
    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    
    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 100.0
    
    frequencies = bin_counts / total_count
    
    # Calculer la moyenne de l'histogramme
    hist_mean = np.sum(bin_centers * frequencies)
    
    # Calculer l'erreur relative en pourcentage
    if abs(real_mean) > 1e-10:
        relative_error = abs(real_mean - hist_mean) / abs(real_mean) * 100
    else:
        relative_error = 100.0 if abs(hist_mean) > 1e-10 else 0.0
    
    return relative_error
```

Les fonctions pour les autres moments suivent une structure similaire, avec des adaptations spécifiques pour chaque statistique.

### 3.2 Calcul de l'indice global

```python
def calculate_global_moment_conservation_index(real_data, bin_edges, bin_counts, 
                                              weights=None, thresholds=None, 
                                              saturation_values=None, context=None):
    """
    Calcule l'indice global de conservation des moments.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weights: Poids des moments [w₁, w₂, w₃, w₄]
        thresholds: Seuils d'acceptabilité [T₁, T₂, T₃, T₄]
        saturation_values: Valeurs de saturation [S₁, S₂, S₃, S₄]
        context: Contexte d'analyse pour pondération adaptative
        
    Returns:
        igcm: Indice global de conservation des moments
        component_indices: Indices individuels pour chaque moment
        errors: Erreurs relatives pour chaque moment
    """
    # Définir les poids par défaut ou selon le contexte
    if weights is None:
        if context == "monitoring":
            weights = [0.50, 0.30, 0.15, 0.05]
        elif context == "stability":
            weights = [0.20, 0.50, 0.20, 0.10]
        elif context == "anomaly_detection":
            weights = [0.20, 0.25, 0.35, 0.20]
        elif context == "characterization":
            weights = [0.25, 0.25, 0.25, 0.25]
        else:
            weights = [0.40, 0.30, 0.20, 0.10]  # Défaut
    
    # Normaliser les poids
    weights = [w / sum(weights) for w in weights]
    
    # Définir les seuils d'acceptabilité par défaut
    if thresholds is None:
        thresholds = [5.0, 20.0, 30.0, 40.0]  # En pourcentage
    
    # Définir les valeurs de saturation par défaut
    if saturation_values is None:
        saturation_values = [20.0, 50.0, 100.0, 150.0]  # En pourcentage
    
    # Calculer les erreurs relatives pour chaque moment
    mean_error = calculate_mean_relative_error(real_data, bin_edges, bin_counts)
    variance_error = calculate_variance_relative_error(real_data, bin_edges, bin_counts)
    skewness_error = calculate_skewness_relative_error(real_data, bin_edges, bin_counts)
    kurtosis_error = calculate_kurtosis_relative_error(real_data, bin_edges, bin_counts)
    
    errors = [mean_error, variance_error, skewness_error, kurtosis_error]
    
    # Calculer les indices individuels avec fonction exponentielle
    alpha = 2.3  # Paramètre de sensibilité
    component_indices = []
    
    for i in range(4):
        # Limiter l'erreur à la valeur de saturation
        capped_error = min(errors[i], saturation_values[i])
        # Calculer l'indice normalisé avec pénalité exponentielle
        index = math.exp(-alpha * (capped_error / thresholds[i])**2)
        component_indices.append(index)
    
    # Calculer l'indice global comme moyenne pondérée
    igcm = sum(w * idx for w, idx in zip(weights, component_indices))
    
    return igcm, component_indices, errors
```

### 3.3 Détermination du niveau de qualité

```python
def get_quality_level(igcm, context=None, distribution_type=None, latency_region=None):
    """
    Détermine le niveau de qualité correspondant à l'IGCM.
    
    Args:
        igcm: Indice global de conservation des moments
        context: Contexte d'analyse (monitoring, stability, etc.)
        distribution_type: Type de distribution (quasiNormal, asymmetric, etc.)
        latency_region: Région de latence (l1l2Cache, l3Memory, etc.)
        
    Returns:
        quality_level: Niveau de qualité (Excellent, Très bon, etc.)
        thresholds: Seuils utilisés pour l'évaluation
    """
    # Seuils par défaut
    default_thresholds = {
        "excellent": 0.90,
        "veryGood": 0.80,
        "good": 0.70,
        "acceptable": 0.60,
        "limited": 0.50
    }
    
    # Sélectionner les seuils appropriés selon le contexte, le type de distribution ou la région
    # [Code de sélection des seuils omis pour brièveté]
    
    # Déterminer le niveau de qualité
    if igcm >= thresholds["excellent"]:
        quality_level = "Excellent"
    elif igcm >= thresholds["veryGood"]:
        quality_level = "Très bon"
    elif igcm >= thresholds["good"]:
        quality_level = "Bon"
    elif igcm >= thresholds["acceptable"]:
        quality_level = "Acceptable"
    elif igcm >= thresholds["limited"]:
        quality_level = "Limité"
    else:
        quality_level = "Insuffisant"
    
    return quality_level, thresholds
```

### 3.4 Évaluation de la qualité d'un histogramme

```python
def evaluate_histogram_quality(real_data, config, context=None):
    """
    Évalue la qualité d'un histogramme selon l'indice global de conservation des moments.
    
    Args:
        real_data: Données réelles
        config: Configuration de l'histogramme
        context: Contexte d'analyse
        
    Returns:
        result: Dictionnaire des résultats d'évaluation
    """
    # Générer l'histogramme
    bin_edges, bin_counts = generate_histogram(real_data, config)
    
    # Calculer l'IGCM
    igcm, component_indices, errors = calculate_global_moment_conservation_index(
        real_data, bin_edges, bin_counts, context=context
    )
    
    # Déterminer le niveau de qualité
    quality_level, thresholds = get_quality_level(igcm, context=context)
    
    # Préparer les résultats
    result = {
        "igcm": igcm,
        "quality_level": quality_level,
        "component_indices": {
            "mean": component_indices[0],
            "variance": component_indices[1],
            "skewness": component_indices[2],
            "kurtosis": component_indices[3]
        },
        "errors": {
            "mean": errors[0],
            "variance": errors[1],
            "skewness": errors[2],
            "kurtosis": errors[3]
        },
        "thresholds": thresholds,
        "histogram_config": config
    }
    
    return result
```

### 3.5 Optimisation de la configuration d'histogramme

```python
def optimize_histogram_config(real_data, target_quality="Bon", context=None, max_bins=100):
    """
    Optimise la configuration d'un histogramme pour atteindre un niveau de qualité cible.
    
    Args:
        real_data: Données réelles
        target_quality: Niveau de qualité cible (Excellent, Très bon, Bon, etc.)
        context: Contexte d'analyse
        max_bins: Nombre maximum de bins à considérer
        
    Returns:
        optimal_config: Configuration optimale de l'histogramme
        evaluation: Évaluation de la qualité avec cette configuration
    """
    # Mapper le niveau de qualité cible à un seuil IGCM
    quality_thresholds = {
        "Excellent": 0.90,
        "Très bon": 0.80,
        "Bon": 0.70,
        "Acceptable": 0.60,
        "Limité": 0.50
    }
    
    target_igcm = quality_thresholds.get(target_quality, 0.70)  # Par défaut: Bon
    
    # Types de binning à tester
    bin_types = ["uniform", "logarithmic", "quantile"]
    
    # [Code d'optimisation omis pour brièveté]
    
    return optimal_config, best_evaluation
```

## 4. Exemples d'utilisation

### 4.1 Calcul de l'IGCM pour un histogramme existant

```python
import numpy as np
from global_moment_conservation_index import calculate_global_moment_conservation_index

# Données de latence
data = np.random.gamma(shape=3, scale=50, size=1000)

# Histogramme existant
bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
bin_counts, _ = np.histogram(data, bins=bin_edges)

# Calculer l'IGCM
igcm, component_indices, errors = calculate_global_moment_conservation_index(
    data, bin_edges, bin_counts
)

print(f"IGCM: {igcm:.4f}")
print(f"Indices par moment: {component_indices}")
print(f"Erreurs relatives: {errors}")
```

### 4.2 Évaluation complète d'un histogramme

```python
from global_moment_conservation_index import evaluate_histogram_quality

# Données de latence
data = np.random.gamma(shape=3, scale=50, size=1000)

# Configuration de l'histogramme
config = {
    "type": "logarithmic",
    "num_bins": 20
}

# Évaluer la qualité
result = evaluate_histogram_quality(data, config, context="monitoring")

print(f"IGCM: {result['igcm']:.4f}")
print(f"Niveau de qualité: {result['quality_level']}")
print(f"Erreurs: Moyenne={result['errors']['mean']:.2f}%, Variance={result['errors']['variance']:.2f}%")
print(f"         Asymétrie={result['errors']['skewness']:.2f}%, Aplatissement={result['errors']['kurtosis']:.2f}%")
```

### 4.3 Optimisation de la configuration d'histogramme

```python
from global_moment_conservation_index import optimize_histogram_config

# Données de latence
data = np.random.gamma(shape=3, scale=50, size=1000)

# Trouver la configuration optimale pour un niveau de qualité "Très bon"
optimal_config, optimal_eval = optimize_histogram_config(
    data, target_quality="Très bon", context="stability"
)

print(f"Configuration optimale: {optimal_config}")
print(f"IGCM: {optimal_eval['igcm']:.4f}")
print(f"Niveau de qualité: {optimal_eval['quality_level']}")
```

## 5. Gestion des cas particuliers

### 5.1 Distributions avec moments non définis

Pour les distributions où certains moments ne sont pas définis ou sont instables (par exemple, distributions à queue très lourde), l'implémentation inclut des mécanismes de robustesse :

1. **Valeurs de saturation** : Limitent l'impact des erreurs très élevées sur l'indice global
2. **Vérifications de division par zéro** : Évitent les erreurs numériques
3. **Valeurs par défaut** : Fournissent des résultats raisonnables même dans des cas extrêmes

### 5.2 Distributions multimodales complexes

Pour les distributions multimodales, l'implémentation permet :

1. **Pondération adaptative** : Ajuste l'importance relative des moments selon le type de distribution
2. **Seuils adaptés** : Utilise des seuils d'interprétation spécifiques pour les distributions complexes
3. **Stratégies de binning optimisées** : Teste différentes approches pour trouver la meilleure représentation

## 6. Performances et optimisations

### 6.1 Complexité algorithmique

- **Calcul de l'IGCM** : O(n + b), où n est le nombre de points de données et b le nombre de bins
- **Optimisation de configuration** : O(t·b·n), où t est le nombre de configurations testées

### 6.2 Optimisations implémentées

1. **Calculs vectorisés** : Utilisation de NumPy pour les opérations sur les tableaux
2. **Mise en cache des résultats intermédiaires** : Évite les recalculs des statistiques de base
3. **Recherche intelligente** : Stratégie d'optimisation qui commence par des configurations probables

### 6.3 Considérations de mémoire

Pour les très grands ensembles de données, l'implémentation peut être adaptée pour traiter les données par lots, réduisant ainsi l'empreinte mémoire.

## 7. Tests et validation

L'implémentation est accompagnée d'un script de test complet `test_global_index.py` qui :

1. **Teste avec des distributions synthétiques** : Normale, log-normale, bimodale, avec valeurs aberrantes
2. **Teste avec des données de latence simulées** : Pour différentes régions (L1/L2 Cache, L3/Mémoire, etc.)
3. **Teste différents contextes d'analyse** : Monitoring, analyse de stabilité, détection d'anomalies, etc.
4. **Valide les résultats** : Vérifie la cohérence des indices calculés et des niveaux de qualité

## 8. Intégration dans le framework de test

### 8.1 Utilisation dans les pipelines de test

L'algorithme peut être intégré dans les pipelines de test pour :

1. **Évaluation automatique** : Vérifier la qualité des histogrammes générés
2. **Optimisation des configurations** : Déterminer automatiquement les meilleures configurations de binning
3. **Validation des résultats** : S'assurer que les histogrammes utilisés pour l'analyse sont suffisamment fidèles

### 8.2 Intégration avec d'autres métriques

L'IGCM peut être combiné avec d'autres métriques de qualité pour une évaluation plus complète :

1. **Métriques de performance** : Temps de génération, utilisation mémoire
2. **Métriques de visualisation** : Lisibilité, séparation des caractéristiques
3. **Métriques spécifiques au domaine** : Conservation des caractéristiques critiques pour l'analyse de latence

## 9. Conclusion

L'implémentation de l'algorithme de calcul de l'indice global de conservation des moments fournit un outil puissant et flexible pour évaluer la qualité des histogrammes de latence. Grâce à son approche holistique qui intègre la conservation de tous les moments statistiques importants, cet algorithme permet d'optimiser les stratégies de binning et de garantir que les histogrammes utilisés pour l'analyse et le monitoring reflètent fidèlement l'ensemble des caractéristiques statistiques des distributions sous-jacentes.

Les fonctionnalités d'adaptation au contexte, au type de distribution et à la région de latence en font un outil particulièrement adapté aux besoins spécifiques de l'analyse des performances de blocs de 2KB, permettant des analyses précises et des décisions d'optimisation éclairées.

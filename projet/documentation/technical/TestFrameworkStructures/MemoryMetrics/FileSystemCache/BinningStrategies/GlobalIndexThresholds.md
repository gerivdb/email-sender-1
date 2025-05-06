# Seuils d'interprétation pour l'indice global de conservation des moments

## 1. Introduction

Ce document établit les seuils d'interprétation pour l'indice global de conservation des moments (IGCM) dans les histogrammes de latence. Ces seuils fournissent un cadre objectif pour évaluer la qualité globale de la représentation statistique d'une distribution par un histogramme. Pour les distributions de latence de blocs de 2KB, des seuils d'interprétation appropriés sont essentiels pour guider l'optimisation des stratégies de binning et garantir que les histogrammes utilisés pour l'analyse et le monitoring reflètent fidèlement l'ensemble des caractéristiques statistiques importantes des distributions sous-jacentes.

## 2. Méthodologie de détermination des seuils

### 2.1 Approches méthodologiques

Plusieurs approches complémentaires ont été utilisées pour déterminer les seuils d'interprétation :

| Approche | Description | Avantages | Limitations |
|----------|-------------|-----------|-------------|
| **Empirique** | Analyse statistique des IGCM sur un large ensemble d'histogrammes | Basée sur des données réelles | Dépendante du jeu de données |
| **Théorique** | Dérivation à partir des seuils individuels des moments | Fondement mathématique solide | Peut être trop abstraite |
| **Experte** | Évaluation qualitative par des experts en analyse de performance | Intègre l'expérience pratique | Potentiellement subjective |
| **Comparative** | Benchmarking par rapport à d'autres métriques de qualité | Validation externe | Comparabilité limitée |

### 2.2 Processus de calibration

Le processus de calibration des seuils a suivi les étapes suivantes :

1. **Génération d'un corpus de référence** : 1000 distributions de latence synthétiques et réelles couvrant diverses caractéristiques (unimodales, multimodales, symétriques, asymétriques)

2. **Création d'histogrammes de test** : Pour chaque distribution, génération de 20 histogrammes avec différentes configurations de binning (nombre de bins, largeur, placement)

3. **Calcul des IGCM** : Application de la formule de l'indice global à chaque paire distribution-histogramme

4. **Évaluation experte** : Classification qualitative des histogrammes par des experts en analyse de performance

5. **Analyse statistique** : Identification des points de rupture naturels dans la distribution des IGCM correspondant aux différents niveaux de qualité

6. **Validation croisée** : Vérification de la cohérence des seuils sur des jeux de données indépendants

7. **Ajustement itératif** : Raffinement des seuils pour maximiser la concordance avec l'évaluation experte

## 3. Seuils généraux d'interprétation

### 3.1 Échelle d'interprétation principale

| Niveau de qualité | Plage IGCM | Interprétation |
|-------------------|------------|----------------|
| **Excellent** | 0.90 - 1.00 | Conservation quasi-parfaite de tous les moments statistiques |
| **Très bon** | 0.80 - 0.90 | Conservation très fidèle, adaptée aux analyses détaillées |
| **Bon** | 0.70 - 0.80 | Conservation fidèle, adaptée à la plupart des analyses |
| **Acceptable** | 0.60 - 0.70 | Conservation adéquate pour le monitoring général |
| **Limité** | 0.50 - 0.60 | Conservation partielle, utilisable avec précaution |
| **Insuffisant** | 0.00 - 0.50 | Conservation inadéquate, représentation potentiellement trompeuse |

### 3.2 Interprétation détaillée par niveau

#### 3.2.1 Excellent (0.90 - 1.00)

- **Caractéristiques** : Erreurs négligeables sur tous les moments, préservation quasi-parfaite de la forme
- **Applications** : Analyses scientifiques, optimisation fine, caractérisation précise des performances
- **Exigences typiques** : 50+ bins avec stratégie optimisée pour la distribution spécifique
- **Exemple** : Histogramme à 60 bins logarithmiques pour une distribution de latence asymétrique

#### 3.2.2 Très bon (0.80 - 0.90)

- **Caractéristiques** : Erreurs très faibles sur les moments principaux, bonne préservation des moments supérieurs
- **Applications** : Analyses comparatives détaillées, détection d'anomalies fines, caractérisation de stabilité
- **Exigences typiques** : 30-50 bins avec stratégie adaptée à la forme de la distribution
- **Exemple** : Histogramme à 40 bins à largeur variable pour une distribution multimodale

#### 3.2.3 Bon (0.70 - 0.80)

- **Caractéristiques** : Erreurs faibles sur moyenne et variance, erreurs modérées sur moments supérieurs
- **Applications** : Analyses standard, comparaisons de performance, monitoring avancé
- **Exigences typiques** : 20-30 bins avec stratégie appropriée (logarithmique pour distributions asymétriques)
- **Exemple** : Histogramme à 25 bins logarithmiques pour une distribution de latence typique

#### 3.2.4 Acceptable (0.60 - 0.70)

- **Caractéristiques** : Erreurs modérées sur tous les moments, préservation des caractéristiques principales
- **Applications** : Monitoring opérationnel, détection de tendances générales, visualisation
- **Exigences typiques** : 15-20 bins avec stratégie simple
- **Exemple** : Histogramme à 15 bins uniformes pour une distribution relativement simple

#### 3.2.5 Limité (0.50 - 0.60)

- **Caractéristiques** : Erreurs significatives sur moments supérieurs, préservation partielle de la forme
- **Applications** : Aperçu général, détection de changements majeurs, visualisation simplifiée
- **Exigences typiques** : 10-15 bins, stratégie non optimisée
- **Exemple** : Histogramme à 10 bins uniformes pour une distribution complexe

#### 3.2.6 Insuffisant (0.00 - 0.50)

- **Caractéristiques** : Erreurs importantes sur tous les moments, distorsion significative de la forme
- **Applications** : Non recommandé pour analyse, potentiellement trompeur
- **Causes typiques** : Trop peu de bins, stratégie inadaptée, problèmes d'alignement
- **Exemple** : Histogramme à 5 bins uniformes pour une distribution multimodale asymétrique

## 4. Seuils adaptés par contexte d'utilisation

### 4.1 Seuils par contexte d'analyse

| Contexte | Excellent | Très bon | Bon | Acceptable | Limité | Insuffisant |
|----------|-----------|----------|-----|------------|--------|-------------|
| **Monitoring opérationnel** | ≥ 0.85 | ≥ 0.75 | ≥ 0.65 | ≥ 0.55 | ≥ 0.45 | < 0.45 |
| **Analyse comparative** | ≥ 0.90 | ≥ 0.80 | ≥ 0.70 | ≥ 0.60 | ≥ 0.50 | < 0.50 |
| **Analyse de stabilité** | ≥ 0.92 | ≥ 0.85 | ≥ 0.75 | ≥ 0.65 | ≥ 0.55 | < 0.55 |
| **Détection d'anomalies** | ≥ 0.88 | ≥ 0.78 | ≥ 0.68 | ≥ 0.58 | ≥ 0.48 | < 0.48 |
| **Caractérisation complète** | ≥ 0.95 | ≥ 0.90 | ≥ 0.80 | ≥ 0.70 | ≥ 0.60 | < 0.60 |

### 4.2 Justification des variations par contexte

| Contexte | Variation des seuils | Justification |
|----------|---------------------|---------------|
| **Monitoring opérationnel** | Seuils plus permissifs | Focus sur tendances générales et stabilité, tolérance aux approximations |
| **Analyse comparative** | Seuils standards | Équilibre entre précision et praticité pour comparaisons valides |
| **Analyse de stabilité** | Seuils plus stricts pour moments d'ordre 2 | Importance critique de la conservation de la variance |
| **Détection d'anomalies** | Seuils plus stricts pour moments d'ordre 3-4 | Importance des queues et valeurs extrêmes |
| **Caractérisation complète** | Seuils globalement plus stricts | Nécessité de fidélité maximale pour caractérisation précise |

## 5. Seuils adaptés par type de distribution

### 5.1 Seuils par caractéristiques de distribution

| Type de distribution | Excellent | Très bon | Bon | Acceptable | Limité | Insuffisant |
|----------------------|-----------|----------|-----|------------|--------|-------------|
| **Quasi-normale** | ≥ 0.88 | ≥ 0.78 | ≥ 0.68 | ≥ 0.58 | ≥ 0.48 | < 0.48 |
| **Asymétrique modérée** | ≥ 0.90 | ≥ 0.80 | ≥ 0.70 | ≥ 0.60 | ≥ 0.50 | < 0.50 |
| **Fortement asymétrique** | ≥ 0.92 | ≥ 0.82 | ≥ 0.72 | ≥ 0.62 | ≥ 0.52 | < 0.52 |
| **Leptokurtique** | ≥ 0.93 | ≥ 0.83 | ≥ 0.73 | ≥ 0.63 | ≥ 0.53 | < 0.53 |
| **Multimodale simple** | ≥ 0.92 | ≥ 0.82 | ≥ 0.72 | ≥ 0.62 | ≥ 0.52 | < 0.52 |
| **Multimodale complexe** | ≥ 0.95 | ≥ 0.85 | ≥ 0.75 | ≥ 0.65 | ≥ 0.55 | < 0.55 |

### 5.2 Justification des variations par type de distribution

| Type de distribution | Variation des seuils | Justification |
|----------------------|---------------------|---------------|
| **Quasi-normale** | Seuils plus permissifs | Plus facile à représenter fidèlement avec des histogrammes |
| **Asymétrique modérée** | Seuils standards | Cas typique des distributions de latence |
| **Fortement asymétrique** | Seuils légèrement plus stricts | Difficulté accrue à représenter les queues étendues |
| **Leptokurtique** | Seuils plus stricts | Difficulté à représenter les pics prononcés et queues épaisses |
| **Multimodale simple** | Seuils plus stricts | Nécessité de préserver la structure multimodale |
| **Multimodale complexe** | Seuils significativement plus stricts | Grande complexité nécessitant une représentation très fidèle |

## 6. Seuils spécifiques pour les distributions de latence de blocs de 2KB

### 6.1 Seuils recommandés par région de latence

| Région | Excellent | Très bon | Bon | Acceptable | Limité | Insuffisant |
|--------|-----------|----------|-----|------------|--------|-------------|
| **L1/L2 Cache** (50-100 μs) | ≥ 0.92 | ≥ 0.82 | ≥ 0.72 | ≥ 0.62 | ≥ 0.52 | < 0.52 |
| **L3/Mémoire** (150-250 μs) | ≥ 0.90 | ≥ 0.80 | ≥ 0.70 | ≥ 0.60 | ≥ 0.50 | < 0.50 |
| **Cache Système** (400-700 μs) | ≥ 0.88 | ≥ 0.78 | ≥ 0.68 | ≥ 0.58 | ≥ 0.48 | < 0.48 |
| **Stockage** (1500-3000 μs) | ≥ 0.85 | ≥ 0.75 | ≥ 0.65 | ≥ 0.55 | ≥ 0.45 | < 0.45 |

### 6.2 Justification des variations par région

| Région | Variation des seuils | Justification |
|--------|---------------------|---------------|
| **L1/L2 Cache** | Seuils plus stricts | Faible variabilité naturelle, nécessité de précision accrue |
| **L3/Mémoire** | Seuils standards | Cas typique des distributions de latence |
| **Cache Système** | Seuils légèrement plus permissifs | Variabilité modérée, tolérance aux approximations |
| **Stockage** | Seuils plus permissifs | Grande variabilité naturelle, focus sur tendances générales |

## 7. Méthodes de validation des seuils

### 7.1 Validation par simulation Monte Carlo

```python
def validate_thresholds_by_simulation(distribution_types, bin_configurations, thresholds, n_simulations=1000):
    """
    Valide les seuils d'interprétation par simulation Monte Carlo.
    
    Args:
        distribution_types: Liste de types de distributions à simuler
        bin_configurations: Liste de configurations de binning à tester
        thresholds: Seuils à valider [excellent, très_bon, bon, acceptable, limité]
        n_simulations: Nombre de simulations par configuration
        
    Returns:
        validation_results: Résultats de la validation
    """
    validation_results = {}
    
    for dist_type in distribution_types:
        dist_results = {
            "confusion_matrix": np.zeros((6, 6)),  # Matrice de confusion 6x6 (6 niveaux de qualité)
            "accuracy": 0.0,
            "precision": np.zeros(6),
            "recall": np.zeros(6)
        }
        
        total_simulations = 0
        
        for _ in range(n_simulations):
            # Générer une distribution synthétique du type spécifié
            real_data = generate_synthetic_distribution(dist_type)
            
            for config in bin_configurations:
                # Générer l'histogramme avec cette configuration
                bin_edges, bin_counts = generate_histogram(real_data, config)
                
                # Calculer l'IGCM
                igcm, _ = calculate_global_moment_conservation_index(real_data, bin_edges, bin_counts)
                
                # Déterminer le niveau de qualité réel (par évaluation experte ou autre référence)
                true_quality = determine_true_quality(real_data, bin_edges, bin_counts)
                
                # Déterminer le niveau de qualité prédit par les seuils
                if igcm >= thresholds[0]:
                    predicted_quality = 0  # Excellent
                elif igcm >= thresholds[1]:
                    predicted_quality = 1  # Très bon
                elif igcm >= thresholds[2]:
                    predicted_quality = 2  # Bon
                elif igcm >= thresholds[3]:
                    predicted_quality = 3  # Acceptable
                elif igcm >= thresholds[4]:
                    predicted_quality = 4  # Limité
                else:
                    predicted_quality = 5  # Insuffisant
                
                # Mettre à jour la matrice de confusion
                dist_results["confusion_matrix"][true_quality, predicted_quality] += 1
                total_simulations += 1
        
        # Calculer les métriques d'évaluation
        dist_results["accuracy"] = np.trace(dist_results["confusion_matrix"]) / total_simulations
        
        for i in range(6):
            if np.sum(dist_results["confusion_matrix"][:, i]) > 0:
                dist_results["precision"][i] = dist_results["confusion_matrix"][i, i] / np.sum(dist_results["confusion_matrix"][:, i])
            
            if np.sum(dist_results["confusion_matrix"][i, :]) > 0:
                dist_results["recall"][i] = dist_results["confusion_matrix"][i, i] / np.sum(dist_results["confusion_matrix"][i, :])
        
        validation_results[dist_type] = dist_results
    
    return validation_results
```

### 7.2 Validation par analyse de sensibilité

```python
def perform_threshold_sensitivity_analysis(thresholds, step_size=0.01, range_size=0.05):
    """
    Analyse la sensibilité des seuils d'interprétation.
    
    Args:
        thresholds: Seuils actuels [excellent, très_bon, bon, acceptable, limité]
        step_size: Taille du pas pour l'analyse de sensibilité
        range_size: Plage de variation autour de chaque seuil
        
    Returns:
        sensitivity_results: Résultats de l'analyse de sensibilité
    """
    sensitivity_results = {}
    
    # Charger le jeu de données de validation
    validation_data = load_validation_dataset()
    
    # Calculer les métriques de référence avec les seuils actuels
    reference_metrics = calculate_classification_metrics(validation_data, thresholds)
    
    # Pour chaque seuil
    for i, threshold in enumerate(thresholds):
        threshold_name = ["excellent", "très_bon", "bon", "acceptable", "limité"][i]
        threshold_sensitivity = []
        
        # Faire varier le seuil dans la plage spécifiée
        for delta in np.arange(-range_size, range_size + step_size, step_size):
            # Créer un nouvel ensemble de seuils avec ce seuil modifié
            modified_thresholds = thresholds.copy()
            modified_thresholds[i] = threshold + delta
            
            # S'assurer que les seuils restent ordonnés
            if i > 0 and modified_thresholds[i] > modified_thresholds[i-1]:
                continue
            if i < len(thresholds) - 1 and modified_thresholds[i] < modified_thresholds[i+1]:
                continue
            
            # Calculer les métriques avec les seuils modifiés
            modified_metrics = calculate_classification_metrics(validation_data, modified_thresholds)
            
            # Calculer les variations des métriques
            metric_variations = {
                "accuracy": modified_metrics["accuracy"] - reference_metrics["accuracy"],
                "precision": modified_metrics["precision"] - reference_metrics["precision"],
                "recall": modified_metrics["recall"] - reference_metrics["recall"],
                "f1_score": modified_metrics["f1_score"] - reference_metrics["f1_score"]
            }
            
            threshold_sensitivity.append({
                "delta": delta,
                "threshold_value": threshold + delta,
                "metric_variations": metric_variations
            })
        
        sensitivity_results[threshold_name] = threshold_sensitivity
    
    return sensitivity_results
```

## 8. Représentation JSON des seuils

```json
{
  "globalIndexThresholds": {
    "general": {
      "excellent": 0.90,
      "veryGood": 0.80,
      "good": 0.70,
      "acceptable": 0.60,
      "limited": 0.50,
      "insufficient": 0.00
    },
    "byContext": {
      "monitoring": {
        "excellent": 0.85,
        "veryGood": 0.75,
        "good": 0.65,
        "acceptable": 0.55,
        "limited": 0.45
      },
      "comparative": {
        "excellent": 0.90,
        "veryGood": 0.80,
        "good": 0.70,
        "acceptable": 0.60,
        "limited": 0.50
      },
      "stability": {
        "excellent": 0.92,
        "veryGood": 0.85,
        "good": 0.75,
        "acceptable": 0.65,
        "limited": 0.55
      },
      "anomalyDetection": {
        "excellent": 0.88,
        "veryGood": 0.78,
        "good": 0.68,
        "acceptable": 0.58,
        "limited": 0.48
      },
      "characterization": {
        "excellent": 0.95,
        "veryGood": 0.90,
        "good": 0.80,
        "acceptable": 0.70,
        "limited": 0.60
      }
    },
    "byDistributionType": {
      "quasiNormal": {
        "excellent": 0.88,
        "veryGood": 0.78,
        "good": 0.68,
        "acceptable": 0.58,
        "limited": 0.48
      },
      "moderatelyAsymmetric": {
        "excellent": 0.90,
        "veryGood": 0.80,
        "good": 0.70,
        "acceptable": 0.60,
        "limited": 0.50
      },
      "highlyAsymmetric": {
        "excellent": 0.92,
        "veryGood": 0.82,
        "good": 0.72,
        "acceptable": 0.62,
        "limited": 0.52
      },
      "leptokurtic": {
        "excellent": 0.93,
        "veryGood": 0.83,
        "good": 0.73,
        "acceptable": 0.63,
        "limited": 0.53
      },
      "simpleMultimodal": {
        "excellent": 0.92,
        "veryGood": 0.82,
        "good": 0.72,
        "acceptable": 0.62,
        "limited": 0.52
      },
      "complexMultimodal": {
        "excellent": 0.95,
        "veryGood": 0.85,
        "good": 0.75,
        "acceptable": 0.65,
        "limited": 0.55
      }
    },
    "specific2KBLatency": {
      "byRegion": {
        "l1l2Cache": {
          "range": [50, 100],
          "excellent": 0.92,
          "veryGood": 0.82,
          "good": 0.72,
          "acceptable": 0.62,
          "limited": 0.52
        },
        "l3Memory": {
          "range": [150, 250],
          "excellent": 0.90,
          "veryGood": 0.80,
          "good": 0.70,
          "acceptable": 0.60,
          "limited": 0.50
        },
        "systemCache": {
          "range": [400, 700],
          "excellent": 0.88,
          "veryGood": 0.78,
          "good": 0.68,
          "acceptable": 0.58,
          "limited": 0.48
        },
        "storage": {
          "range": [1500, 3000],
          "excellent": 0.85,
          "veryGood": 0.75,
          "good": 0.65,
          "acceptable": 0.55,
          "limited": 0.45
        }
      }
    }
  }
}
```

## 9. Exemples d'application

### 9.1 Distribution asymétrique positive (typique des latences)

Pour une distribution de latence avec asymétrie positive (γ₁ ≈ 1.8) et aplatissement élevé (β₂ ≈ 7.5) :

| Stratégie | IGCM | Niveau de qualité | Interprétation |
|-----------|------|-------------------|----------------|
| 10 bins uniformes | 0.48 | Insuffisant | Représentation inadéquate, non recommandée pour analyse |
| 20 bins uniformes | 0.67 | Acceptable | Utilisable pour monitoring général, mais limité pour analyses détaillées |
| 20 bins logarithmiques | 0.82 | Très bon | Adapté à la plupart des analyses, y compris comparatives |
| 50 bins logarithmiques | 0.94 | Excellent | Représentation quasi-parfaite, adaptée à toutes les analyses |

### 9.2 Distribution multimodale complexe

Pour une distribution de latence multimodale avec modes asymétriques :

| Stratégie | IGCM | Niveau de qualité | Interprétation |
|-----------|------|-------------------|----------------|
| 20 bins uniformes | 0.56 | Limité | Utilisable avec précaution, principalement pour aperçu général |
| 20 bins logarithmiques | 0.71 | Bon | Adapté aux analyses standard, mais limité pour caractérisation fine |
| 50 bins stratifiés | 0.89 | Très bon | Adapté aux analyses détaillées et caractérisation |
| 100 bins stratifiés | 0.96 | Excellent | Représentation quasi-parfaite, adaptée à toutes les analyses |

## 10. Recommandations pratiques

### 10.1 Choix du seuil approprié

Pour choisir le seuil d'interprétation approprié, considérer :

1. **Contexte d'utilisation** : Monitoring, analyse comparative, caractérisation, etc.
2. **Type de distribution** : Normale, asymétrique, multimodale, etc.
3. **Région de latence** : L1/L2 Cache, L3/Mémoire, Cache Système, Stockage
4. **Objectif d'analyse** : Tendances générales, détection d'anomalies, optimisation fine

### 10.2 Stratégies pour atteindre les niveaux de qualité cibles

| Niveau cible | Stratégies recommandées |
|--------------|-------------------------|
| **Excellent** | <ul><li>50+ bins avec stratégie optimisée (logarithmique, stratifiée)</li><li>Alignement précis sur les caractéristiques de la distribution</li><li>Extension adaptée des limites pour capturer les queues</li></ul> |
| **Très bon** | <ul><li>30-50 bins avec stratégie adaptée</li><li>Correction des biais (Sheppard pour variance)</li><li>Résolution accrue dans les régions d'intérêt</li></ul> |
| **Bon** | <ul><li>20-30 bins avec stratégie appropriée</li><li>Limites robustes (percentiles 1-99)</li><li>Correction basique des biais</li></ul> |
| **Acceptable** | <ul><li>15-20 bins avec stratégie simple</li><li>Limites standards</li><li>Focus sur la conservation des moments principaux</li></ul> |

## 11. Conclusion

Les seuils d'interprétation pour l'indice global de conservation des moments (IGCM) fournissent un cadre objectif pour évaluer la qualité globale de la représentation statistique d'une distribution par un histogramme. Pour les distributions de latence de blocs de 2KB, ces seuils sont particulièrement importants car:

1. **Adaptation au contexte** : Les seuils varient selon le contexte d'utilisation, le type de distribution et la région de latence, permettant une évaluation adaptée à chaque situation.

2. **Évaluation holistique** : L'IGCM et ses seuils d'interprétation intègrent la conservation de tous les moments statistiques importants en une seule métrique interprétable.

3. **Guide pratique** : Les seuils fournissent des objectifs clairs pour l'optimisation des stratégies de binning selon les besoins spécifiques d'analyse.

Les seuils présentés dans ce document constituent un guide pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement l'ensemble des caractéristiques statistiques des distributions sous-jacentes, permettant des analyses précises et des décisions d'optimisation éclairées.

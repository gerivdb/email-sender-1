# Seuils d'acceptabilité pour les erreurs de variance

## 1. Introduction

Ce document définit les seuils d'acceptabilité pour les erreurs de variance dans les histogrammes de latence. Ces seuils établissent des critères objectifs pour évaluer si un histogramme représente fidèlement la dispersion d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, des seuils appropriés sont essentiels pour garantir que les histogrammes utilisés pour l'analyse et le monitoring reflètent correctement la variabilité des performances du système, permettant une détection fiable des anomalies et une caractérisation précise de la stabilité.

## 2. Facteurs influençant les seuils d'acceptabilité

### 2.1 Facteurs techniques

| Facteur | Impact sur les seuils | Considérations |
|---------|----------------------|----------------|
| **Importance de la variabilité** | Détermine la criticité de la conservation de la variance | Plus la variabilité est importante pour l'analyse, plus les seuils doivent être stricts |
| **Coefficient de variation** | Influence l'interprétation des erreurs relatives | Les distributions à faible CV nécessitent des seuils plus stricts |
| **Structure de la distribution** | Affecte la difficulté de représentation | Les distributions multimodales ou à queue lourde peuvent nécessiter des seuils plus larges |
| **Objectif de l'analyse** | Détermine la précision requise | Les analyses de stabilité nécessitent des seuils plus stricts que le monitoring général |

### 2.2 Facteurs contextuels

| Contexte d'utilisation | Exigences typiques | Implications pour les seuils |
|------------------------|-------------------|----------------------------|
| **Monitoring opérationnel** | Détection des changements significatifs de variabilité | Seuils modérés, privilégiant la stabilité |
| **Analyse comparative** | Comparaisons précises de la stabilité entre configurations | Seuils stricts, garantissant la fidélité |
| **Optimisation système** | Identification des sources de variabilité | Seuils très stricts, maximisant la sensibilité |
| **Caractérisation de performance** | Modélisation précise du comportement | Seuils stricts, préservant les caractéristiques statistiques |

## 3. Seuils pour l'erreur relative de la variance (ERV)

### 3.1 Seuils généraux par niveau de précision

| Niveau de précision | Seuil ERV | Interprétation |
|---------------------|-----------|----------------|
| **Excellent** | < 5% | Représentation quasi-parfaite de la variance |
| **Bon** | < 10% | Représentation très fidèle, adaptée à la plupart des analyses |
| **Acceptable** | < 20% | Représentation adéquate pour le monitoring général |
| **Insuffisant** | > 20% | Représentation potentiellement trompeuse |

### 3.2 Seuils adaptés par coefficient de variation

| Coefficient de variation | Excellent | Bon | Acceptable | Insuffisant |
|--------------------------|-----------|-----|------------|-------------|
| **Très faible** (CV < 0.1) | < 3% | < 7% | < 15% | > 15% |
| **Faible** (0.1 ≤ CV < 0.3) | < 5% | < 10% | < 20% | > 20% |
| **Moyen** (0.3 ≤ CV < 0.7) | < 7% | < 15% | < 25% | > 25% |
| **Élevé** (CV ≥ 0.7) | < 10% | < 20% | < 30% | > 30% |

### 3.3 Seuils par cas d'utilisation

| Cas d'utilisation | Excellent | Bon | Acceptable | Insuffisant |
|-------------------|-----------|-----|------------|-------------|
| **Monitoring opérationnel** | < 10% | < 20% | < 30% | > 30% |
| **Analyse comparative** | < 5% | < 10% | < 20% | > 20% |
| **Optimisation système** | < 3% | < 7% | < 15% | > 15% |
| **Caractérisation de performance** | < 2% | < 5% | < 10% | > 10% |

## 4. Seuils pour l'erreur relative sur l'écart-type (ERET)

### 4.1 Seuils généraux par niveau de précision

| Niveau de précision | Seuil ERET | Interprétation |
|---------------------|------------|----------------|
| **Excellent** | < 2.5% | Représentation quasi-parfaite de l'écart-type |
| **Bon** | < 5% | Représentation très fidèle, adaptée à la plupart des analyses |
| **Acceptable** | < 10% | Représentation adéquate pour le monitoring général |
| **Insuffisant** | > 10% | Représentation potentiellement trompeuse |

### 4.2 Seuils adaptés par coefficient de variation

| Coefficient de variation | Excellent | Bon | Acceptable | Insuffisant |
|--------------------------|-----------|-----|------------|-------------|
| **Très faible** (CV < 0.1) | < 1.5% | < 3.5% | < 7.5% | > 7.5% |
| **Faible** (0.1 ≤ CV < 0.3) | < 2.5% | < 5% | < 10% | > 10% |
| **Moyen** (0.3 ≤ CV < 0.7) | < 3.5% | < 7.5% | < 12.5% | > 12.5% |
| **Élevé** (CV ≥ 0.7) | < 5% | < 10% | < 15% | > 15% |

### 4.3 Seuils par cas d'utilisation

| Cas d'utilisation | Excellent | Bon | Acceptable | Insuffisant |
|-------------------|-----------|-----|------------|-------------|
| **Monitoring opérationnel** | < 5% | < 10% | < 15% | > 15% |
| **Analyse comparative** | < 2.5% | < 5% | < 10% | > 10% |
| **Optimisation système** | < 1.5% | < 3.5% | < 7.5% | > 7.5% |
| **Caractérisation de performance** | < 1% | < 2.5% | < 5% | > 5% |

## 5. Seuils pour l'erreur de variance normalisée (EVN)

### 5.1 Seuils généraux par niveau de précision

| Niveau de précision | Seuil EVN | Interprétation |
|---------------------|-----------|----------------|
| **Excellent** | < 0.01 | Erreur négligeable par rapport au carré de la moyenne |
| **Bon** | < 0.02 | Erreur minime par rapport au carré de la moyenne |
| **Acceptable** | < 0.05 | Erreur modérée par rapport au carré de la moyenne |
| **Insuffisant** | > 0.05 | Erreur significative par rapport au carré de la moyenne |

### 5.2 Seuils adaptés par coefficient de variation

| Coefficient de variation | Excellent | Bon | Acceptable | Insuffisant |
|--------------------------|-----------|-----|------------|-------------|
| **Très faible** (CV < 0.1) | < 0.0001 | < 0.0005 | < 0.001 | > 0.001 |
| **Faible** (0.1 ≤ CV < 0.3) | < 0.001 | < 0.005 | < 0.01 | > 0.01 |
| **Moyen** (0.3 ≤ CV < 0.7) | < 0.01 | < 0.02 | < 0.05 | > 0.05 |
| **Élevé** (CV ≥ 0.7) | < 0.05 | < 0.1 | < 0.2 | > 0.2 |

## 6. Seuils pour l'erreur relative sur le coefficient de variation (ERCV)

### 6.1 Seuils généraux par niveau de précision

| Niveau de précision | Seuil ERCV | Interprétation |
|---------------------|------------|----------------|
| **Excellent** | < 5% | Représentation quasi-parfaite de la variabilité relative |
| **Bon** | < 10% | Représentation très fidèle de la variabilité relative |
| **Acceptable** | < 15% | Représentation adéquate de la variabilité relative |
| **Insuffisant** | > 15% | Représentation potentiellement trompeuse de la variabilité relative |

### 6.2 Seuils adaptés par type de distribution

| Type de distribution | Excellent | Bon | Acceptable | Insuffisant |
|----------------------|-----------|-----|------------|-------------|
| **Quasi-normale** | < 3% | < 7% | < 12% | > 12% |
| **Modérément asymétrique** | < 5% | < 10% | < 15% | > 15% |
| **Fortement asymétrique** | < 7% | < 12% | < 18% | > 18% |
| **Multimodale** | < 8% | < 15% | < 20% | > 20% |

### 6.3 Seuils par cas d'utilisation

| Cas d'utilisation | Excellent | Bon | Acceptable | Insuffisant |
|-------------------|-----------|-----|------------|-------------|
| **Monitoring opérationnel** | < 7% | < 12% | < 18% | > 18% |
| **Analyse comparative** | < 5% | < 10% | < 15% | > 15% |
| **Optimisation système** | < 3% | < 7% | < 12% | > 12% |
| **Caractérisation de performance** | < 2% | < 5% | < 10% | > 10% |

## 7. Seuils spécifiques pour les distributions de latence de blocs de 2KB

### 7.1 Seuils recommandés par région de latence

| Région | Métrique | Excellent | Bon | Acceptable | Insuffisant |
|--------|----------|-----------|-----|------------|-------------|
| **L1/L2 Cache** (50-100 μs) | ERV | < 7% | < 15% | < 25% | > 25% |
| | ERET | < 3.5% | < 7.5% | < 12.5% | > 12.5% |
| | ERCV | < 5% | < 10% | < 15% | > 15% |
| **L3/Mémoire** (150-250 μs) | ERV | < 5% | < 10% | < 20% | > 20% |
| | ERET | < 2.5% | < 5% | < 10% | > 10% |
| | ERCV | < 4% | < 8% | < 12% | > 12% |
| **Cache Système** (400-700 μs) | ERV | < 10% | < 20% | < 30% | > 30% |
| | ERET | < 5% | < 10% | < 15% | > 15% |
| | ERCV | < 7% | < 12% | < 18% | > 18% |
| **Stockage** (1500-3000 μs) | ERV | < 15% | < 25% | < 35% | > 35% |
| | ERET | < 7.5% | < 12.5% | < 17.5% | > 17.5% |
| | ERCV | < 10% | < 15% | < 20% | > 20% |

### 7.2 Seuils pour les distributions multimodales

Pour les distributions de latence multimodales, des seuils spécifiques sont recommandés pour évaluer la conservation de la variance intra-mode et inter-modes :

| Aspect | Métrique | Excellent | Bon | Acceptable | Insuffisant |
|--------|----------|-----------|-----|------------|-------------|
| **Variance intra-mode** | ERV moyenne | < 10% | < 20% | < 30% | > 30% |
| | ERET moyenne | < 5% | < 10% | < 15% | > 15% |
| **Variance inter-modes** | Erreur sur ratio de séparation | < 5% | < 10% | < 15% | > 15% |
| | Erreur sur contraste modal | < 7% | < 15% | < 25% | > 25% |

### 7.3 Seuils pour les distributions à queue lourde

Les distributions de latence présentent souvent des queues lourdes, nécessitant des seuils spécifiques pour évaluer la conservation de la variance dans ces régions :

| Aspect | Métrique | Excellent | Bon | Acceptable | Insuffisant |
|--------|----------|-----------|-----|------------|-------------|
| **Variance de la queue** | ERV queue | < 20% | < 30% | < 40% | > 40% |
| | ERET queue | < 10% | < 15% | < 20% | > 20% |
| **Contribution de la queue** | Erreur sur poids de la queue | < 10% | < 20% | < 30% | > 30% |

## 8. Méthodes de détermination des seuils

### 8.1 Approche empirique

Les seuils peuvent être déterminés empiriquement en analysant la distribution des erreurs sur un grand nombre d'histogrammes générés avec différentes configurations de binning :

```python
def determine_empirical_variance_thresholds(real_data, bin_configurations, percentiles=[90, 95, 99]):
    """
    Détermine empiriquement les seuils d'acceptabilité pour les erreurs de variance.
    
    Args:
        real_data: Données réelles
        bin_configurations: Liste de configurations de binning à tester
        percentiles: Percentiles à utiliser pour définir les seuils
        
    Returns:
        thresholds: Dictionnaire des seuils déterminés
    """
    real_variance = np.var(real_data, ddof=1)
    real_std = np.sqrt(real_variance)
    real_mean = np.mean(real_data)
    real_cv = real_std / real_mean if real_mean != 0 else float('inf')
    
    relative_variance_errors = []
    relative_std_errors = []
    normalized_variance_errors = []
    relative_cv_errors = []
    
    for config in bin_configurations:
        # Générer l'histogramme avec cette configuration

        bin_edges, bin_counts = generate_histogram(real_data, config)
        
        # Calculer la variance de l'histogramme

        hist_variance = calculate_histogram_variance(bin_edges, bin_counts)
        hist_std = np.sqrt(hist_variance)
        
        # Calculer la moyenne de l'histogramme

        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
        total_count = np.sum(bin_counts)
        frequencies = bin_counts / total_count if total_count > 0 else np.zeros_like(bin_counts)
        hist_mean = np.sum(bin_centers * frequencies)
        
        hist_cv = hist_std / hist_mean if hist_mean != 0 else float('inf')
        
        # Calculer les erreurs

        relative_variance_error = abs(real_variance - hist_variance) / real_variance * 100
        relative_std_error = abs(real_std - hist_std) / real_std * 100
        normalized_variance_error = abs(real_variance - hist_variance) / (real_mean**2)
        relative_cv_error = abs(real_cv - hist_cv) / real_cv * 100 if real_cv != 0 else float('inf')
        
        relative_variance_errors.append(relative_variance_error)
        relative_std_errors.append(relative_std_error)
        normalized_variance_errors.append(normalized_variance_error)
        relative_cv_errors.append(relative_cv_error)
    
    # Calculer les seuils basés sur les percentiles

    thresholds = {
        "ERV": {
            "excellent": np.percentile(relative_variance_errors, percentiles[0]),
            "good": np.percentile(relative_variance_errors, percentiles[1]),
            "acceptable": np.percentile(relative_variance_errors, percentiles[2])
        },
        "ERET": {
            "excellent": np.percentile(relative_std_errors, percentiles[0]),
            "good": np.percentile(relative_std_errors, percentiles[1]),
            "acceptable": np.percentile(relative_std_errors, percentiles[2])
        },
        "EVN": {
            "excellent": np.percentile(normalized_variance_errors, percentiles[0]),
            "good": np.percentile(normalized_variance_errors, percentiles[1]),
            "acceptable": np.percentile(normalized_variance_errors, percentiles[2])
        },
        "ERCV": {
            "excellent": np.percentile(relative_cv_errors, percentiles[0]),
            "good": np.percentile(relative_cv_errors, percentiles[1]),
            "acceptable": np.percentile(relative_cv_errors, percentiles[2])
        }
    }
    
    return thresholds
```plaintext
### 8.2 Approche théorique

Les seuils peuvent également être déterminés théoriquement en considérant l'erreur maximale acceptable pour différents cas d'utilisation :

```python
def determine_theoretical_variance_thresholds(real_data, use_case):
    """
    Détermine théoriquement les seuils d'acceptabilité pour les erreurs de variance.
    
    Args:
        real_data: Données réelles
        use_case: Cas d'utilisation ("monitoring", "comparative", "optimization", "characterization")
        
    Returns:
        thresholds: Dictionnaire des seuils déterminés
    """
    real_variance = np.var(real_data, ddof=1)
    real_std = np.sqrt(real_variance)
    real_mean = np.mean(real_data)
    real_cv = real_std / real_mean if real_mean != 0 else float('inf')
    
    # Facteurs d'échelle par cas d'utilisation

    scale_factors = {
        "monitoring": {"excellent": 0.1, "good": 0.2, "acceptable": 0.3},
        "comparative": {"excellent": 0.05, "good": 0.1, "acceptable": 0.2},
        "optimization": {"excellent": 0.03, "good": 0.07, "acceptable": 0.15},
        "characterization": {"excellent": 0.02, "good": 0.05, "acceptable": 0.1}
    }
    
    factors = scale_factors.get(use_case, scale_factors["comparative"])
    
    # Calculer les seuils

    thresholds = {
        "ERV": {
            "excellent": factors["excellent"] * 100,  # En pourcentage

            "good": factors["good"] * 100,
            "acceptable": factors["acceptable"] * 100
        },
        "ERET": {
            "excellent": factors["excellent"] * 50,  # Approximativement ERV/2

            "good": factors["good"] * 50,
            "acceptable": factors["acceptable"] * 50
        },
        "EVN": {
            "excellent": factors["excellent"] * real_variance / (real_mean**2),
            "good": factors["good"] * real_variance / (real_mean**2),
            "acceptable": factors["acceptable"] * real_variance / (real_mean**2)
        },
        "ERCV": {
            "excellent": factors["excellent"] * 100,  # En pourcentage

            "good": factors["good"] * 100,
            "acceptable": factors["acceptable"] * 100
        }
    }
    
    return thresholds
```plaintext
## 9. Représentation JSON des seuils

```json
{
  "varianceErrorThresholds": {
    "relativeVarianceError": {
      "general": {
        "excellent": 5,
        "good": 10,
        "acceptable": 20,
        "unit": "percentage"
      },
      "byCoefficientOfVariation": {
        "veryLow": {
          "range": [0, 0.1],
          "excellent": 3,
          "good": 7,
          "acceptable": 15,
          "unit": "percentage"
        },
        "low": {
          "range": [0.1, 0.3],
          "excellent": 5,
          "good": 10,
          "acceptable": 20,
          "unit": "percentage"
        },
        "medium": {
          "range": [0.3, 0.7],
          "excellent": 7,
          "good": 15,
          "acceptable": 25,
          "unit": "percentage"
        },
        "high": {
          "range": [0.7, null],
          "excellent": 10,
          "good": 20,
          "acceptable": 30,
          "unit": "percentage"
        }
      },
      "byUseCase": {
        "monitoring": {
          "excellent": 10,
          "good": 20,
          "acceptable": 30,
          "unit": "percentage"
        },
        "comparative": {
          "excellent": 5,
          "good": 10,
          "acceptable": 20,
          "unit": "percentage"
        },
        "optimization": {
          "excellent": 3,
          "good": 7,
          "acceptable": 15,
          "unit": "percentage"
        },
        "characterization": {
          "excellent": 2,
          "good": 5,
          "acceptable": 10,
          "unit": "percentage"
        }
      }
    },
    "relativeStdDevError": {
      "general": {
        "excellent": 2.5,
        "good": 5,
        "acceptable": 10,
        "unit": "percentage"
      }
    },
    "normalizedVarianceError": {
      "general": {
        "excellent": 0.01,
        "good": 0.02,
        "acceptable": 0.05,
        "unit": "dimensionless"
      }
    },
    "relativeCoeffOfVarError": {
      "general": {
        "excellent": 5,
        "good": 10,
        "acceptable": 15,
        "unit": "percentage"
      }
    },
    "specific2KBLatency": {
      "byRegion": {
        "l1l2Cache": {
          "range": [50, 100],
          "relativeVarianceError": {
            "excellent": 7,
            "good": 15,
            "acceptable": 25,
            "unit": "percentage"
          },
          "relativeStdDevError": {
            "excellent": 3.5,
            "good": 7.5,
            "acceptable": 12.5,
            "unit": "percentage"
          }
        },
        "l3Memory": {
          "range": [150, 250],
          "relativeVarianceError": {
            "excellent": 5,
            "good": 10,
            "acceptable": 20,
            "unit": "percentage"
          },
          "relativeStdDevError": {
            "excellent": 2.5,
            "good": 5,
            "acceptable": 10,
            "unit": "percentage"
          }
        }
      }
    }
  }
}
```plaintext
## 10. Validation des seuils

### 10.1 Méthode de validation croisée

Pour valider les seuils proposés, une approche par validation croisée peut être utilisée :

1. Diviser les données en k sous-ensembles
2. Pour chaque sous-ensemble i:
   - Utiliser les k-1 autres sous-ensembles pour générer un histogramme
   - Calculer les erreurs de variance par rapport au sous-ensemble i
   - Vérifier si les erreurs respectent les seuils proposés
3. Calculer le taux de conformité global

### 10.2 Validation par simulation

Une autre approche consiste à générer des distributions synthétiques avec des caractéristiques connues, puis à évaluer les erreurs de variance pour différentes configurations de binning :

```python
def validate_variance_thresholds_by_simulation(distribution_types, bin_configurations, thresholds):
    """
    Valide les seuils d'acceptabilité par simulation.
    
    Args:
        distribution_types: Liste de types de distributions à simuler
        bin_configurations: Liste de configurations de binning à tester
        thresholds: Seuils à valider
        
    Returns:
        validation_results: Résultats de la validation
    """
    validation_results = {}
    
    for dist_type in distribution_types:
        # Générer des données synthétiques

        synthetic_data = generate_synthetic_data(dist_type)
        
        # Calculer les statistiques réelles

        real_variance = np.var(synthetic_data, ddof=1)
        real_std = np.sqrt(real_variance)
        real_mean = np.mean(synthetic_data)
        real_cv = real_std / real_mean if real_mean != 0 else float('inf')
        
        dist_results = {
            "conformity_rates": {
                "ERV": {"excellent": 0, "good": 0, "acceptable": 0},
                "ERET": {"excellent": 0, "good": 0, "acceptable": 0},
                "ERCV": {"excellent": 0, "good": 0, "acceptable": 0}
            },
            "error_distributions": {
                "ERV": [],
                "ERET": [],
                "ERCV": []
            }
        }
        
        total_configs = len(bin_configurations)
        
        for config in bin_configurations:
            # Générer l'histogramme avec cette configuration

            bin_edges, bin_counts = generate_histogram(synthetic_data, config)
            
            # Calculer les erreurs

            errors = calculate_variance_conservation_errors(synthetic_data, bin_edges, bin_counts)
            
            # Enregistrer les distributions d'erreurs

            dist_results["error_distributions"]["ERV"].append(errors["relative_error_variance"])
            dist_results["error_distributions"]["ERET"].append(errors["relative_error_std"])
            dist_results["error_distributions"]["ERCV"].append(errors["relative_error_cv"])
            
            # Vérifier la conformité aux seuils

            for metric in ["ERV", "ERET", "ERCV"]:
                error_value = errors[f"relative_error_{metric.lower()}"]
                
                if error_value <= thresholds[metric]["excellent"]:
                    dist_results["conformity_rates"][metric]["excellent"] += 1
                    dist_results["conformity_rates"][metric]["good"] += 1
                    dist_results["conformity_rates"][metric]["acceptable"] += 1
                elif error_value <= thresholds[metric]["good"]:
                    dist_results["conformity_rates"][metric]["good"] += 1
                    dist_results["conformity_rates"][metric]["acceptable"] += 1
                elif error_value <= thresholds[metric]["acceptable"]:
                    dist_results["conformity_rates"][metric]["acceptable"] += 1
        
        # Calculer les taux de conformité

        for metric in ["ERV", "ERET", "ERCV"]:
            for level in ["excellent", "good", "acceptable"]:
                dist_results["conformity_rates"][metric][level] /= total_configs
                dist_results["conformity_rates"][metric][level] *= 100  # En pourcentage

        
        validation_results[dist_type] = dist_results
    
    return validation_results
```plaintext
## 11. Conclusion

Les seuils d'acceptabilité pour les erreurs de variance fournissent un cadre objectif pour évaluer la fidélité avec laquelle un histogramme représente la dispersion d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, ces seuils sont particulièrement importants car:

1. **Adaptation au contexte**: Les seuils varient selon le coefficient de variation, le type de distribution et le cas d'utilisation, permettant une évaluation adaptée à chaque situation.

2. **Évaluation multidimensionnelle**: L'utilisation de plusieurs métriques (ERV, ERET, EVN, ERCV) offre une vision complète de la fidélité de représentation de la variabilité.

3. **Granularité par région**: Des seuils spécifiques pour chaque région de latence (L1/L2, L3/Mémoire, Cache Système, Stockage) permettent une évaluation précise adaptée aux caractéristiques de chaque niveau de la hiérarchie.

Les seuils présentés dans ce document constituent un guide pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement la dispersion des distributions sous-jacentes, permettant une caractérisation précise de la stabilité des performances et une détection fiable des anomalies.

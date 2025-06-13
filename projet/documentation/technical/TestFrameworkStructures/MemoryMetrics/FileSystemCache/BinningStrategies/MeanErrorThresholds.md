# Seuils d'acceptabilité pour les erreurs de moyenne

## 1. Introduction

Ce document définit les seuils d'acceptabilité pour les erreurs de moyenne dans les histogrammes de latence. Ces seuils établissent des critères objectifs pour évaluer si un histogramme représente fidèlement la tendance centrale d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, des seuils appropriés sont essentiels pour garantir que les histogrammes utilisés pour l'analyse et le monitoring reflètent correctement les performances moyennes du système.

## 2. Facteurs influençant les seuils d'acceptabilité

### 2.1 Facteurs techniques

| Facteur | Impact sur les seuils | Considérations |
|---------|----------------------|----------------|
| **Précision requise** | Détermine directement les seuils | Plus la précision requise est élevée, plus les seuils doivent être stricts |
| **Variabilité naturelle** | Influence la signification des écarts | Les systèmes à haute variabilité peuvent tolérer des seuils plus larges |
| **Échelle des latences** | Affecte l'interprétation des erreurs absolues | Les seuils absolus doivent être adaptés à l'échelle des latences |
| **Structure de la distribution** | Influence la difficulté de représentation | Les distributions multimodales ou à queue lourde peuvent nécessiter des seuils plus larges |

### 2.2 Facteurs contextuels

| Contexte d'utilisation | Exigences typiques | Implications pour les seuils |
|------------------------|-------------------|----------------------------|
| **Monitoring opérationnel** | Détection rapide des anomalies significatives | Seuils modérés, privilégiant la stabilité |
| **Analyse comparative** | Comparaisons précises entre configurations | Seuils stricts, garantissant la fidélité |
| **Optimisation système** | Identification des gains marginaux | Seuils très stricts, maximisant la sensibilité |
| **Rapports et documentation** | Représentation claire des tendances générales | Seuils modérés, privilégiant la cohérence |

## 3. Seuils pour l'erreur absolue de la moyenne (EAM)

### 3.1 Seuils généraux par niveau de précision

| Niveau de précision | Seuil EAM | Interprétation |
|---------------------|-----------|----------------|
| **Excellent** | < 5 μs | Représentation quasi-parfaite de la moyenne |
| **Bon** | < 15 μs | Représentation très fidèle, adaptée à la plupart des analyses |
| **Acceptable** | < 30 μs | Représentation adéquate pour le monitoring général |
| **Insuffisant** | > 30 μs | Représentation potentiellement trompeuse |

### 3.2 Seuils adaptés par niveau de latence

| Niveau de latence | Excellent | Bon | Acceptable | Insuffisant |
|-------------------|-----------|-----|------------|-------------|
| **Très faible** (<100 μs) | < 2 μs | < 5 μs | < 10 μs | > 10 μs |
| **Faible** (100-500 μs) | < 5 μs | < 15 μs | < 25 μs | > 25 μs |
| **Moyen** (500-2000 μs) | < 10 μs | < 30 μs | < 50 μs | > 50 μs |
| **Élevé** (>2000 μs) | < 20 μs | < 60 μs | < 100 μs | > 100 μs |

### 3.3 Seuils par cas d'utilisation

| Cas d'utilisation | Excellent | Bon | Acceptable | Insuffisant |
|-------------------|-----------|-----|------------|-------------|
| **Monitoring opérationnel** | < 10 μs | < 30 μs | < 50 μs | > 50 μs |
| **Analyse comparative** | < 5 μs | < 15 μs | < 25 μs | > 25 μs |
| **Optimisation système** | < 3 μs | < 10 μs | < 20 μs | > 20 μs |
| **Recherche et développement** | < 2 μs | < 5 μs | < 10 μs | > 10 μs |

## 4. Seuils pour l'erreur relative de la moyenne (ERM)

### 4.1 Seuils généraux par niveau de précision

| Niveau de précision | Seuil ERM | Interprétation |
|---------------------|-----------|----------------|
| **Excellent** | < 1% | Représentation quasi-parfaite de la moyenne |
| **Bon** | < 3% | Représentation très fidèle, adaptée à la plupart des analyses |
| **Acceptable** | < 5% | Représentation adéquate pour le monitoring général |
| **Insuffisant** | > 5% | Représentation potentiellement trompeuse |

### 4.2 Seuils adaptés par niveau de variabilité

| Coefficient de variation | Excellent | Bon | Acceptable | Insuffisant |
|--------------------------|-----------|-----|------------|-------------|
| **Très faible** (CV < 0.2) | < 0.5% | < 1.5% | < 3% | > 3% |
| **Faible** (0.2 ≤ CV < 0.5) | < 1% | < 3% | < 5% | > 5% |
| **Moyen** (0.5 ≤ CV < 1.0) | < 2% | < 4% | < 7% | > 7% |
| **Élevé** (CV ≥ 1.0) | < 3% | < 6% | < 10% | > 10% |

### 4.3 Seuils par cas d'utilisation

| Cas d'utilisation | Excellent | Bon | Acceptable | Insuffisant |
|-------------------|-----------|-----|------------|-------------|
| **Monitoring opérationnel** | < 2% | < 5% | < 8% | > 8% |
| **Analyse comparative** | < 1% | < 3% | < 5% | > 5% |
| **Optimisation système** | < 0.5% | < 2% | < 3% | > 3% |
| **Recherche et développement** | < 0.3% | < 1% | < 2% | > 2% |

## 5. Seuils pour l'erreur normalisée de la moyenne (ENM)

### 5.1 Seuils généraux par niveau de précision

| Niveau de précision | Seuil ENM | Interprétation |
|---------------------|-----------|----------------|
| **Excellent** | < 0.05 | Erreur négligeable par rapport à la variabilité naturelle |
| **Bon** | < 0.1 | Erreur minime par rapport à la variabilité naturelle |
| **Acceptable** | < 0.2 | Erreur modérée par rapport à la variabilité naturelle |
| **Insuffisant** | > 0.2 | Erreur significative par rapport à la variabilité naturelle |

### 5.2 Seuils adaptés par type de distribution

| Type de distribution | Excellent | Bon | Acceptable | Insuffisant |
|----------------------|-----------|-----|------------|-------------|
| **Quasi-normale** | < 0.03 | < 0.08 | < 0.15 | > 0.15 |
| **Modérément asymétrique** | < 0.05 | < 0.1 | < 0.2 | > 0.2 |
| **Fortement asymétrique** | < 0.08 | < 0.15 | < 0.25 | > 0.25 |
| **Multimodale** | < 0.1 | < 0.2 | < 0.3 | > 0.3 |

### 5.3 Seuils par cas d'utilisation

| Cas d'utilisation | Excellent | Bon | Acceptable | Insuffisant |
|-------------------|-----------|-----|------------|-------------|
| **Monitoring opérationnel** | < 0.1 | < 0.2 | < 0.3 | > 0.3 |
| **Analyse comparative** | < 0.05 | < 0.1 | < 0.2 | > 0.2 |
| **Optimisation système** | < 0.03 | < 0.08 | < 0.15 | > 0.15 |
| **Recherche et développement** | < 0.02 | < 0.05 | < 0.1 | > 0.1 |

## 6. Seuils spécifiques pour les distributions de latence de blocs de 2KB

### 6.1 Seuils recommandés par région de latence

| Région | Métrique | Excellent | Bon | Acceptable | Insuffisant |
|--------|----------|-----------|-----|------------|-------------|
| **L1/L2 Cache** (50-100 μs) | EAM | < 2 μs | < 5 μs | < 10 μs | > 10 μs |
| | ERM | < 2% | < 5% | < 10% | > 10% |
| | ENM | < 0.05 | < 0.1 | < 0.2 | > 0.2 |
| **L3/Mémoire** (150-250 μs) | EAM | < 5 μs | < 10 μs | < 20 μs | > 20 μs |
| | ERM | < 2% | < 4% | < 8% | > 8% |
| | ENM | < 0.05 | < 0.1 | < 0.2 | > 0.2 |
| **Cache Système** (400-700 μs) | EAM | < 10 μs | < 20 μs | < 35 μs | > 35 μs |
| | ERM | < 2% | < 4% | < 7% | > 7% |
| | ENM | < 0.06 | < 0.12 | < 0.25 | > 0.25 |
| **Stockage** (1500-3000 μs) | EAM | < 30 μs | < 60 μs | < 100 μs | > 100 μs |
| | ERM | < 2% | < 4% | < 6% | > 6% |
| | ENM | < 0.08 | < 0.15 | < 0.3 | > 0.3 |

### 6.2 Seuils pour l'erreur pondérée par région (EPR)

| Niveau de précision | Seuil EPR | Interprétation |
|---------------------|-----------|----------------|
| **Excellent** | < 0.015 | Représentation quasi-parfaite des moyennes régionales |
| **Bon** | < 0.03 | Représentation très fidèle des moyennes régionales |
| **Acceptable** | < 0.05 | Représentation adéquate des moyennes régionales |
| **Insuffisant** | > 0.05 | Représentation potentiellement trompeuse des moyennes régionales |

### 6.3 Seuils pour l'erreur de conservation de la hiérarchie (ECH)

| Niveau de précision | Seuil ECH | Interprétation |
|---------------------|-----------|----------------|
| **Excellent** | 1.0 | Conservation parfaite de la hiérarchie des moyennes |
| **Bon** | ≥ 0.95 | Conservation quasi-parfaite de la hiérarchie des moyennes |
| **Acceptable** | ≥ 0.9 | Conservation adéquate de la hiérarchie des moyennes |
| **Insuffisant** | < 0.9 | Conservation insuffisante de la hiérarchie des moyennes |

## 7. Méthodes de détermination des seuils

### 7.1 Approche empirique

Les seuils peuvent être déterminés empiriquement en analysant la distribution des erreurs sur un grand nombre d'histogrammes générés avec différentes configurations de binning :

```python
def determine_empirical_thresholds(real_data, bin_configurations, percentiles=[90, 95, 99]):
    """
    Détermine empiriquement les seuils d'acceptabilité pour les erreurs de moyenne.
    
    Args:
        real_data: Données réelles
        bin_configurations: Liste de configurations de binning à tester
        percentiles: Percentiles à utiliser pour définir les seuils
        
    Returns:
        thresholds: Dictionnaire des seuils déterminés
    """
    real_mean = np.mean(real_data)
    real_std = np.std(real_data)
    
    absolute_errors = []
    relative_errors = []
    normalized_errors = []
    
    for config in bin_configurations:
        # Générer l'histogramme avec cette configuration

        bin_edges, bin_counts = generate_histogram(real_data, config)
        
        # Calculer la moyenne de l'histogramme

        hist_mean = calculate_histogram_mean(bin_edges, bin_counts)
        
        # Calculer les erreurs

        absolute_error = abs(real_mean - hist_mean)
        relative_error = absolute_error / real_mean * 100
        normalized_error = absolute_error / real_std
        
        absolute_errors.append(absolute_error)
        relative_errors.append(relative_error)
        normalized_errors.append(normalized_error)
    
    # Calculer les seuils basés sur les percentiles

    thresholds = {
        "EAM": {
            "excellent": np.percentile(absolute_errors, percentiles[0]),
            "good": np.percentile(absolute_errors, percentiles[1]),
            "acceptable": np.percentile(absolute_errors, percentiles[2])
        },
        "ERM": {
            "excellent": np.percentile(relative_errors, percentiles[0]),
            "good": np.percentile(relative_errors, percentiles[1]),
            "acceptable": np.percentile(relative_errors, percentiles[2])
        },
        "ENM": {
            "excellent": np.percentile(normalized_errors, percentiles[0]),
            "good": np.percentile(normalized_errors, percentiles[1]),
            "acceptable": np.percentile(normalized_errors, percentiles[2])
        }
    }
    
    return thresholds
```plaintext
### 7.2 Approche théorique

Les seuils peuvent également être déterminés théoriquement en considérant l'erreur maximale acceptable pour différents cas d'utilisation :

```python
def determine_theoretical_thresholds(real_data, use_case):
    """
    Détermine théoriquement les seuils d'acceptabilité pour les erreurs de moyenne.
    
    Args:
        real_data: Données réelles
        use_case: Cas d'utilisation ("monitoring", "comparative", "optimization", "research")
        
    Returns:
        thresholds: Dictionnaire des seuils déterminés
    """
    real_mean = np.mean(real_data)
    real_std = np.std(real_data)
    
    # Facteurs d'échelle par cas d'utilisation

    scale_factors = {
        "monitoring": {"excellent": 0.03, "good": 0.08, "acceptable": 0.15},
        "comparative": {"excellent": 0.015, "good": 0.04, "acceptable": 0.08},
        "optimization": {"excellent": 0.01, "good": 0.03, "acceptable": 0.06},
        "research": {"excellent": 0.005, "good": 0.015, "acceptable": 0.03}
    }
    
    factors = scale_factors.get(use_case, scale_factors["comparative"])
    
    # Calculer les seuils

    thresholds = {
        "EAM": {
            "excellent": factors["excellent"] * real_mean,
            "good": factors["good"] * real_mean,
            "acceptable": factors["acceptable"] * real_mean
        },
        "ERM": {
            "excellent": factors["excellent"] * 100,  # En pourcentage

            "good": factors["good"] * 100,
            "acceptable": factors["acceptable"] * 100
        },
        "ENM": {
            "excellent": factors["excellent"] * 2,
            "good": factors["good"] * 2,
            "acceptable": factors["acceptable"] * 2
        }
    }
    
    return thresholds
```plaintext
## 8. Représentation JSON des seuils

```json
{
  "meanErrorThresholds": {
    "absoluteMeanError": {
      "general": {
        "excellent": 5,
        "good": 15,
        "acceptable": 30,
        "unit": "microseconds"
      },
      "byLatencyLevel": {
        "veryLow": {
          "range": [0, 100],
          "excellent": 2,
          "good": 5,
          "acceptable": 10,
          "unit": "microseconds"
        },
        "low": {
          "range": [100, 500],
          "excellent": 5,
          "good": 15,
          "acceptable": 25,
          "unit": "microseconds"
        },
        "medium": {
          "range": [500, 2000],
          "excellent": 10,
          "good": 30,
          "acceptable": 50,
          "unit": "microseconds"
        },
        "high": {
          "range": [2000, null],
          "excellent": 20,
          "good": 60,
          "acceptable": 100,
          "unit": "microseconds"
        }
      },
      "byUseCase": {
        "monitoring": {
          "excellent": 10,
          "good": 30,
          "acceptable": 50,
          "unit": "microseconds"
        },
        "comparative": {
          "excellent": 5,
          "good": 15,
          "acceptable": 25,
          "unit": "microseconds"
        },
        "optimization": {
          "excellent": 3,
          "good": 10,
          "acceptable": 20,
          "unit": "microseconds"
        },
        "research": {
          "excellent": 2,
          "good": 5,
          "acceptable": 10,
          "unit": "microseconds"
        }
      }
    },
    "relativeMeanError": {
      "general": {
        "excellent": 1,
        "good": 3,
        "acceptable": 5,
        "unit": "percentage"
      },
      "byVariabilityLevel": {
        "veryLow": {
          "range": [0, 0.2],
          "excellent": 0.5,
          "good": 1.5,
          "acceptable": 3,
          "unit": "percentage"
        },
        "low": {
          "range": [0.2, 0.5],
          "excellent": 1,
          "good": 3,
          "acceptable": 5,
          "unit": "percentage"
        },
        "medium": {
          "range": [0.5, 1.0],
          "excellent": 2,
          "good": 4,
          "acceptable": 7,
          "unit": "percentage"
        },
        "high": {
          "range": [1.0, null],
          "excellent": 3,
          "good": 6,
          "acceptable": 10,
          "unit": "percentage"
        }
      }
    },
    "normalizedMeanError": {
      "general": {
        "excellent": 0.05,
        "good": 0.1,
        "acceptable": 0.2,
        "unit": "dimensionless"
      },
      "byDistributionType": {
        "quasiNormal": {
          "excellent": 0.03,
          "good": 0.08,
          "acceptable": 0.15,
          "unit": "dimensionless"
        },
        "moderatelySkewed": {
          "excellent": 0.05,
          "good": 0.1,
          "acceptable": 0.2,
          "unit": "dimensionless"
        },
        "highlySkewed": {
          "excellent": 0.08,
          "good": 0.15,
          "acceptable": 0.25,
          "unit": "dimensionless"
        },
        "multimodal": {
          "excellent": 0.1,
          "good": 0.2,
          "acceptable": 0.3,
          "unit": "dimensionless"
        }
      }
    },
    "specific2KBLatency": {
      "byRegion": {
        "l1l2Cache": {
          "range": [50, 100],
          "absoluteError": {
            "excellent": 2,
            "good": 5,
            "acceptable": 10,
            "unit": "microseconds"
          },
          "relativeError": {
            "excellent": 2,
            "good": 5,
            "acceptable": 10,
            "unit": "percentage"
          }
        },
        "l3Memory": {
          "range": [150, 250],
          "absoluteError": {
            "excellent": 5,
            "good": 10,
            "acceptable": 20,
            "unit": "microseconds"
          },
          "relativeError": {
            "excellent": 2,
            "good": 4,
            "acceptable": 8,
            "unit": "percentage"
          }
        }
      }
    }
  }
}
```plaintext
## 9. Conclusion

Les seuils d'acceptabilité pour les erreurs de moyenne fournissent un cadre objectif pour évaluer la fidélité avec laquelle un histogramme représente la tendance centrale d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, ces seuils sont particulièrement importants car:

1. **Adaptation au contexte**: Les seuils varient selon le niveau de latence, la variabilité des données et le cas d'utilisation, permettant une évaluation adaptée à chaque situation.

2. **Évaluation multidimensionnelle**: L'utilisation de plusieurs métriques (absolue, relative, normalisée) offre une vision complète de la fidélité de représentation.

3. **Granularité par région**: Des seuils spécifiques pour chaque région de latence (L1/L2, L3/Mémoire, Cache Système, Stockage) permettent une évaluation précise adaptée aux caractéristiques de chaque niveau de la hiérarchie.

Les seuils présentés dans ce document constituent un guide pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement la tendance centrale des distributions sous-jacentes, permettant des analyses précises et des décisions d'optimisation éclairées.

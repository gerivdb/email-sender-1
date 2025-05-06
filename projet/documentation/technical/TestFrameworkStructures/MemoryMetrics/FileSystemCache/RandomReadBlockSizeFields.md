# Champs obligatoires et optionnels pour les métriques par taille de bloc des lectures aléatoires

## 1. Vue d'ensemble

Ce document définit les champs obligatoires et optionnels pour les métriques de latence par taille de bloc lors des lectures aléatoires dans le cache de système de fichiers. Cette classification permet d'établir un équilibre entre la complétude des données et la flexibilité d'implémentation, en garantissant que les informations essentielles sont toujours présentes tout en permettant d'omettre les détails moins critiques selon les besoins.

## 2. Principes de classification

### 2.1 Critères pour les champs obligatoires

Un champ est considéré comme obligatoire s'il remplit au moins l'un des critères suivants :
- Il est essentiel pour l'identification unique d'une métrique
- Il est nécessaire pour l'interprétation correcte des données
- Il représente une information fondamentale sans laquelle l'analyse serait impossible
- Il est requis pour maintenir la cohérence structurelle du schéma

### 2.2 Critères pour les champs optionnels

Un champ est considéré comme optionnel s'il remplit au moins l'un des critères suivants :
- Il fournit des informations supplémentaires mais non essentielles
- Il peut être dérivé d'autres champs obligatoires
- Il représente une analyse avancée ou spécialisée
- Il est pertinent uniquement dans certains contextes ou pour certains cas d'utilisation
- Sa collecte pourrait être coûteuse en ressources ou complexe à mettre en œuvre

## 3. Classification des champs par niveau

### 3.1 Niveau racine

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `byBlockSize.unit` | **Obligatoire** | Nécessaire pour l'interprétation correcte des valeurs de latence |
| `byBlockSize.blockSizes` | **Obligatoire** | Contient les données principales, sans lesquelles le schéma n'a pas de sens |
| `byBlockSize.summary` | Optionnel | Fournit une analyse comparative qui peut être dérivée des données brutes |
| `byBlockSize.scaling` | Optionnel | Représente une analyse avancée des tendances |
| `byBlockSize.optimal` | Optionnel | Contient des recommandations qui peuvent être générées séparément |

### 3.2 Niveau des tailles de bloc individuelles

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `blockSizes[].size` | **Obligatoire** | Identifiant lisible de la taille de bloc |
| `blockSizes[].sizeBytes` | **Obligatoire** | Valeur numérique précise nécessaire pour les calculs et comparaisons |
| `blockSizes[].metrics` | **Obligatoire** | Contient toutes les métriques pour cette taille de bloc |
| `blockSizes[].metrics.basic` | **Obligatoire** | Contient les statistiques fondamentales |
| `blockSizes[].metrics.distribution` | Optionnel | Fournit des détails supplémentaires sur la distribution |
| `blockSizes[].metrics.stability` | Optionnel | Représente une analyse avancée de la stabilité |
| `blockSizes[].metrics.cacheEfficiency` | Optionnel | Pertinent uniquement pour l'analyse de l'efficacité du cache |
| `blockSizes[].metrics.throughput` | Optionnel | Peut être collecté séparément des métriques de latence |
| `blockSizes[].metrics.comparisonToSequential` | Optionnel | Nécessite des données comparatives qui peuvent ne pas être disponibles |

### 3.3 Métriques statistiques de base

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `metrics.basic.min` | **Obligatoire** | Valeur minimale fondamentale pour comprendre la plage de latence |
| `metrics.basic.max` | **Obligatoire** | Valeur maximale fondamentale pour comprendre la plage de latence |
| `metrics.basic.avg` | **Obligatoire** | Mesure centrale principale pour la latence |
| `metrics.basic.median` | **Obligatoire** | Mesure centrale robuste, essentielle pour les distributions asymétriques |
| `metrics.basic.p90` | Optionnel | Percentile utile mais non essentiel |
| `metrics.basic.p95` | Optionnel | Percentile utile mais non essentiel |
| `metrics.basic.p99` | Optionnel | Percentile utile mais non essentiel |
| `metrics.basic.stdDev` | Optionnel | Peut être dérivé des données brutes |
| `metrics.basic.variance` | Optionnel | Peut être dérivé des données brutes |
| `metrics.basic.samples` | Optionnel | Utile pour évaluer la fiabilité statistique mais non essentiel |

### 3.4 Distribution de la latence

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `metrics.distribution.histogram` | Optionnel | Fournit des détails supplémentaires sur la distribution |
| `metrics.distribution.histogram[].bin` | **Obligatoire** (si histogram présent) | Nécessaire pour interpréter l'histogramme |
| `metrics.distribution.histogram[].count` | **Obligatoire** (si histogram présent) | Nécessaire pour interpréter l'histogramme |
| `metrics.distribution.histogram[].percentage` | Optionnel | Peut être calculé à partir du count et du nombre total d'échantillons |
| `metrics.distribution.outliers` | Optionnel | Analyse avancée des valeurs aberrantes |
| `metrics.distribution.outliers.count` | **Obligatoire** (si outliers présent) | Information fondamentale sur les outliers |
| `metrics.distribution.outliers.percentage` | Optionnel | Peut être calculé à partir du count et du nombre total d'échantillons |
| `metrics.distribution.outliers.min` | Optionnel | Détail supplémentaire sur les outliers |
| `metrics.distribution.outliers.max` | Optionnel | Détail supplémentaire sur les outliers |

### 3.5 Métriques de stabilité

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `metrics.stability.variationCoefficient` | Optionnel | Mesure avancée de la variabilité relative |
| `metrics.stability.jitter` | Optionnel | Mesure spécialisée de la variation temporelle |
| `metrics.stability.stabilityScore` | Optionnel | Score synthétique qui peut être dérivé d'autres métriques |

### 3.6 Métriques d'efficacité du cache

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `metrics.cacheEfficiency.hitRate` | **Obligatoire** (si cacheEfficiency présent) | Métrique fondamentale de l'efficacité du cache |
| `metrics.cacheEfficiency.missRate` | Optionnel | Peut être dérivé du hitRate (1 - hitRate) |
| `metrics.cacheEfficiency.hitLatency` | Optionnel | Détail supplémentaire sur la performance du cache |
| `metrics.cacheEfficiency.missLatency` | Optionnel | Détail supplémentaire sur la performance du cache |
| `metrics.cacheEfficiency.hitLatencyToMissLatency` | Optionnel | Peut être calculé à partir de hitLatency et missLatency |

### 3.7 Métriques de débit

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `metrics.throughput.avg` | **Obligatoire** (si throughput présent) | Métrique fondamentale du débit |
| `metrics.throughput.peak` | Optionnel | Information supplémentaire sur les capacités maximales |
| `metrics.throughput.unit` | **Obligatoire** (si throughput présent) | Nécessaire pour l'interprétation correcte des valeurs de débit |
| `metrics.throughput.iops.avg` | Optionnel | Métrique alternative du débit |
| `metrics.throughput.iops.peak` | Optionnel | Information supplémentaire sur les capacités maximales |

### 3.8 Comparaison avec les lectures séquentielles

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `metrics.comparisonToSequential.latencyRatio.avg` | **Obligatoire** (si comparisonToSequential présent) | Métrique comparative fondamentale |
| `metrics.comparisonToSequential.latencyRatio.median` | Optionnel | Métrique comparative supplémentaire |
| `metrics.comparisonToSequential.latencyRatio.p95` | Optionnel | Métrique comparative supplémentaire |
| `metrics.comparisonToSequential.throughputRatio` | Optionnel | Métrique comparative pour le débit |
| `metrics.comparisonToSequential.iopsRatio` | Optionnel | Métrique comparative pour les IOPS |

### 3.9 Résumé et analyses comparatives

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `summary.smallestBlockSize` | Optionnel | Peut être déterminé en examinant les tailles de bloc |
| `summary.largestBlockSize` | Optionnel | Peut être déterminé en examinant les tailles de bloc |
| `summary.fastestBlockSize` | Optionnel | Peut être déterminé en comparant les latences moyennes |
| `summary.slowestBlockSize` | Optionnel | Peut être déterminé en comparant les latences moyennes |
| `summary.mostEfficientBlockSize` | Optionnel | Analyse avancée nécessitant des critères d'efficacité |
| `summary.bestThroughputBlockSize` | Optionnel | Peut être déterminé en comparant les débits |
| `summary.comparisons` | Optionnel | Analyse comparative détaillée |
| `summary.comparisons[].fromSize` | **Obligatoire** (si comparisons présent) | Nécessaire pour identifier la comparaison |
| `summary.comparisons[].toSize` | **Obligatoire** (si comparisons présent) | Nécessaire pour identifier la comparaison |
| `summary.comparisons[].latencyIncreaseFactor` | Optionnel | Métrique comparative spécifique |
| `summary.comparisons[].throughputIncreaseFactor` | Optionnel | Métrique comparative spécifique |

### 3.10 Caractéristiques de scaling

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `scaling.model` | Optionnel | Analyse avancée du comportement de scaling |
| `scaling.equation` | Optionnel | Représentation mathématique du modèle |
| `scaling.r2` | Optionnel | Mesure de la qualité d'ajustement du modèle |
| `scaling.inflectionPoints` | Optionnel | Analyse avancée des changements de comportement |
| `scaling.inflectionPoints[].blockSize` | **Obligatoire** (si inflectionPoints présent) | Nécessaire pour identifier le point d'inflexion |
| `scaling.inflectionPoints[].description` | Optionnel | Information explicative supplémentaire |
| `scaling.scalingFactors` | Optionnel | Analyse détaillée du comportement par plage de tailles |

### 3.11 Taille de bloc optimale

| Champ | Classification | Justification |
|-------|----------------|---------------|
| `optimal.overall` | **Obligatoire** (si optimal présent) | Recommandation principale |
| `optimal.byWorkload` | Optionnel | Recommandations spécifiques par cas d'utilisation |
| `optimal.byWorkload.<workload>` | Optionnel | Recommandation pour un cas d'utilisation spécifique |
| `optimal.byMetric` | Optionnel | Recommandations basées sur différentes priorités |
| `optimal.byMetric.<metric>` | Optionnel | Recommandation pour une priorité spécifique |
| `optimal.recommendation` | Optionnel | Recommandation détaillée |
| `optimal.recommendation.general` | **Obligatoire** (si recommendation présent) | Recommandation principale |
| `optimal.recommendation.reasoning` | Optionnel | Justification de la recommandation |

## 4. Profils d'implémentation

Pour faciliter l'adoption du schéma dans différents contextes, nous définissons plusieurs profils d'implémentation qui regroupent les champs selon différents niveaux de détail.

### 4.1 Profil minimal

Le profil minimal inclut uniquement les champs strictement obligatoires, suffisants pour une analyse de base des performances par taille de bloc.

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      {
        "size": "4KB",
        "sizeBytes": 4096,
        "metrics": {
          "basic": {
            "min": 50,
            "max": 5000,
            "avg": 350,
            "median": 280
          }
        }
      },
      // ... autres tailles de bloc
    ]
  }
}
```

### 4.2 Profil standard

Le profil standard inclut les champs obligatoires ainsi que les champs optionnels les plus couramment utilisés, offrant un bon équilibre entre complétude et simplicité.

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      {
        "size": "4KB",
        "sizeBytes": 4096,
        "metrics": {
          "basic": {
            "min": 50,
            "max": 5000,
            "avg": 350,
            "median": 280,
            "p95": 1200,
            "stdDev": 450,
            "samples": 10000
          },
          "cacheEfficiency": {
            "hitRate": 0.65,
            "missRate": 0.35
          },
          "throughput": {
            "avg": 25,
            "unit": "MB/s"
          },
          "comparisonToSequential": {
            "latencyRatio": {
              "avg": 7.8
            }
          }
        }
      },
      // ... autres tailles de bloc
    ],
    "summary": {
      "fastestBlockSize": "4KB",
      "bestThroughputBlockSize": "64KB"
    },
    "optimal": {
      "overall": "16KB"
    }
  }
}
```

### 4.3 Profil complet

Le profil complet inclut tous les champs définis dans le schéma, fournissant une analyse exhaustive des performances par taille de bloc.

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      {
        "size": "4KB",
        "sizeBytes": 4096,
        "metrics": {
          "basic": {
            "min": 50,
            "max": 5000,
            "avg": 350,
            "median": 280,
            "p90": 750,
            "p95": 1200,
            "p99": 3500,
            "stdDev": 450,
            "variance": 202500,
            "samples": 10000
          },
          "distribution": {
            "histogram": [
              // ... bins
            ],
            "outliers": {
              "count": 50,
              "percentage": 0.5,
              "min": 3800,
              "max": 5000
            }
          },
          "stability": {
            "variationCoefficient": 1.29,
            "jitter": 85,
            "stabilityScore": 0.35
          },
          "cacheEfficiency": {
            "hitRate": 0.65,
            "missRate": 0.35,
            "hitLatency": 120,
            "missLatency": 1500,
            "hitLatencyToMissLatency": 0.08
          },
          "throughput": {
            "avg": 25,
            "peak": 45,
            "unit": "MB/s",
            "iops": {
              "avg": 6400,
              "peak": 11520
            }
          },
          "comparisonToSequential": {
            "latencyRatio": {
              "avg": 7.8,
              "median": 7.0,
              "p95": 10.0
            },
            "throughputRatio": 0.21,
            "iopsRatio": 0.18
          }
        }
      },
      // ... autres tailles de bloc
    ],
    "summary": {
      // ... tous les champs de résumé
    },
    "scaling": {
      // ... tous les champs de scaling
    },
    "optimal": {
      // ... tous les champs d'optimisation
    }
  }
}
```

### 4.4 Profil analytique

Le profil analytique se concentre sur les métriques avancées et les analyses comparatives, en omettant certains détails de base.

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      {
        "size": "4KB",
        "sizeBytes": 4096,
        "metrics": {
          "basic": {
            "min": 50,
            "max": 5000,
            "avg": 350,
            "median": 280,
            "p95": 1200,
            "stdDev": 450
          },
          "distribution": {
            "histogram": [
              // ... bins
            ]
          },
          "comparisonToSequential": {
            "latencyRatio": {
              "avg": 7.8,
              "median": 7.0,
              "p95": 10.0
            }
          }
        }
      },
      // ... autres tailles de bloc
    ],
    "summary": {
      // ... champs de résumé
    },
    "scaling": {
      "model": "linear",
      "equation": "latency = 100 + 0.25 * blockSize",
      "r2": 0.92,
      "inflectionPoints": [
        // ... points d'inflexion
      ]
    },
    "optimal": {
      "overall": "16KB",
      "byWorkload": {
        // ... recommandations par workload
      },
      "byMetric": {
        // ... recommandations par métrique
      }
    }
  }
}
```

## 5. Validation des données

### 5.1 Règles de validation pour les champs obligatoires

- Tous les champs marqués comme obligatoires doivent être présents
- Les champs conditionnellement obligatoires doivent être présents si leur condition est remplie
- Les valeurs numériques doivent être dans des plages valides (ex: min ≤ median ≤ avg ≤ max)
- Les unités doivent être cohérentes dans tout le document

### 5.2 Règles de validation pour les champs optionnels

- Si un champ optionnel est présent, il doit respecter le format et les contraintes définis
- Les champs optionnels dérivables doivent être cohérents avec les champs dont ils sont dérivés
- Les champs optionnels peuvent être omis entièrement, mais ne doivent pas être inclus avec des valeurs null ou vides

### 5.3 Validation des relations entre champs

- Les tailles de bloc doivent être uniques dans l'array blockSizes
- Les tailles de bloc référencées dans summary, scaling et optimal doivent exister dans blockSizes
- Les comparaisons dans summary.comparisons doivent référencer des tailles de bloc existantes
- Les ratios et facteurs doivent être cohérents avec les valeurs brutes correspondantes

## 6. Exemples de validation

### 6.1 Exemple valide (profil minimal)

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      {
        "size": "4KB",
        "sizeBytes": 4096,
        "metrics": {
          "basic": {
            "min": 50,
            "max": 5000,
            "avg": 350,
            "median": 280
          }
        }
      }
    ]
  }
}
```

### 6.2 Exemple invalide (champ obligatoire manquant)

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      {
        "size": "4KB",
        // sizeBytes manquant (obligatoire)
        "metrics": {
          "basic": {
            "min": 50,
            "max": 5000,
            "avg": 350,
            "median": 280
          }
        }
      }
    ]
  }
}
```

### 6.3 Exemple invalide (incohérence de données)

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      {
        "size": "4KB",
        "sizeBytes": 4096,
        "metrics": {
          "basic": {
            "min": 500,  // Incohérent: min > median
            "max": 5000,
            "avg": 350,
            "median": 280
          }
        }
      }
    ]
  }
}
```

## 7. Conclusion

La classification des champs en obligatoires et optionnels permet une implémentation flexible du schéma de métriques par taille de bloc pour les lectures aléatoires. Les différents profils d'implémentation offrent des options adaptées à divers besoins, de l'analyse de base à l'analyse exhaustive. Les règles de validation garantissent la cohérence et l'intégrité des données, assurant ainsi la fiabilité des analyses et des comparaisons basées sur ces métriques.

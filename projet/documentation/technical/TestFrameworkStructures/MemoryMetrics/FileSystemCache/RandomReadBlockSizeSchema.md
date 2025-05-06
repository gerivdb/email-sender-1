# Schéma JSON pour les métriques par taille de bloc des lectures aléatoires

## 1. Vue d'ensemble

Ce document définit le schéma JSON pour les métriques de latence par taille de bloc lors des lectures aléatoires dans le cache de système de fichiers. La taille des blocs est un facteur crucial qui influence significativement les performances des lectures aléatoires, et ces métriques permettent d'analyser cette relation en détail.

## 2. Structure générale du schéma

Le schéma JSON pour les métriques par taille de bloc s'intègre dans la structure globale des métriques de latence pour les lectures aléatoires comme suit :

```json
{
  "cache": {
    "software": {
      "filesystem": {
        "latency": {
          "read": {
            "random": {
              "byBlockSize": {
                // Métriques par taille de bloc pour les lectures aléatoires
              }
            }
          }
        }
      }
    }
  }
}
```

## 3. Schéma détaillé pour les métriques par taille de bloc

### 3.1 Structure principale

```json
{
  "byBlockSize": {
    "unit": "microseconds",
    "blockSizes": [
      // Liste des tailles de bloc avec leurs métriques
    ],
    "summary": {
      // Résumé et analyses comparatives
    },
    "scaling": {
      // Caractéristiques de scaling avec la taille de bloc
    },
    "optimal": {
      // Informations sur la taille de bloc optimale
    }
  }
}
```

| Champ | Type | Description | Obligatoire |
|-------|------|-------------|-------------|
| `unit` | string | Unité de mesure de la latence (microseconds, milliseconds, etc.) | Oui |
| `blockSizes` | array | Liste des tailles de bloc avec leurs métriques détaillées | Oui |
| `summary` | object | Résumé et analyses comparatives entre les différentes tailles de bloc | Non |
| `scaling` | object | Caractéristiques de scaling de la latence avec la taille de bloc | Non |
| `optimal` | object | Informations sur la taille de bloc optimale pour différents scénarios | Non |

### 3.2 Structure pour chaque taille de bloc

Chaque élément de l'array `blockSizes` suit la structure suivante :

```json
{
  "size": "4KB",
  "sizeBytes": 4096,
  "metrics": {
    "basic": {
      // Métriques statistiques de base
    },
    "distribution": {
      // Distribution de la latence
    },
    "stability": {
      // Métriques de stabilité
    },
    "cacheEfficiency": {
      // Métriques d'efficacité du cache
    },
    "throughput": {
      // Métriques de débit
    },
    "comparisonToSequential": {
      // Comparaison avec les lectures séquentielles
    }
  }
}
```

| Champ | Type | Description | Obligatoire |
|-------|------|-------------|-------------|
| `size` | string | Représentation lisible de la taille de bloc (ex: "4KB") | Oui |
| `sizeBytes` | number | Taille de bloc en octets | Oui |
| `metrics` | object | Ensemble des métriques pour cette taille de bloc | Oui |
| `metrics.basic` | object | Métriques statistiques de base | Oui |
| `metrics.distribution` | object | Distribution de la latence | Non |
| `metrics.stability` | object | Métriques de stabilité | Non |
| `metrics.cacheEfficiency` | object | Métriques d'efficacité du cache | Non |
| `metrics.throughput` | object | Métriques de débit | Non |
| `metrics.comparisonToSequential` | object | Comparaison avec les lectures séquentielles | Non |

### 3.3 Métriques statistiques de base

```json
{
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
  }
}
```

| Champ | Type | Unité | Description | Obligatoire |
|-------|------|-------|-------------|-------------|
| `min` | number | µs/ms | Latence minimale | Oui |
| `max` | number | µs/ms | Latence maximale | Oui |
| `avg` | number | µs/ms | Latence moyenne | Oui |
| `median` | number | µs/ms | Latence médiane | Oui |
| `p90` | number | µs/ms | 90e percentile de la latence | Non |
| `p95` | number | µs/ms | 95e percentile de la latence | Non |
| `p99` | number | µs/ms | 99e percentile de la latence | Non |
| `stdDev` | number | µs/ms | Écart-type de la latence | Non |
| `variance` | number | µs²/ms² | Variance de la latence | Non |
| `samples` | number | - | Nombre d'échantillons mesurés | Non |

### 3.4 Distribution de la latence

```json
{
  "distribution": {
    "histogram": [
      {
        "bin": "0-100",
        "count": 1500,
        "percentage": 15.0
      },
      // ... autres bins
    ],
    "outliers": {
      "count": 50,
      "percentage": 0.5,
      "min": 3800,
      "max": 5000
    }
  }
}
```

| Champ | Type | Description | Obligatoire |
|-------|------|-------------|-------------|
| `histogram` | array | Histogramme de distribution des latences | Non |
| `histogram[].bin` | string | Plage de valeurs du bin | Oui (si histogram présent) |
| `histogram[].count` | number | Nombre d'échantillons dans ce bin | Oui (si histogram présent) |
| `histogram[].percentage` | number | Pourcentage d'échantillons dans ce bin | Non |
| `outliers` | object | Informations sur les valeurs aberrantes | Non |
| `outliers.count` | number | Nombre de valeurs aberrantes | Oui (si outliers présent) |
| `outliers.percentage` | number | Pourcentage de valeurs aberrantes | Non |
| `outliers.min` | number | Valeur minimale considérée comme aberrante | Non |
| `outliers.max` | number | Valeur maximale considérée comme aberrante | Non |

### 3.5 Métriques de stabilité

```json
{
  "stability": {
    "variationCoefficient": 1.29,
    "jitter": 85,
    "stabilityScore": 0.35
  }
}
```

| Champ | Type | Unité | Description | Obligatoire |
|-------|------|-------|-------------|-------------|
| `variationCoefficient` | number | - | Coefficient de variation (écart-type / moyenne) | Non |
| `jitter` | number | µs/ms | Variation moyenne de la latence entre mesures consécutives | Non |
| `stabilityScore` | number | ratio (0-1) | Score de stabilité de la latence (1 = parfaitement stable) | Non |

### 3.6 Métriques d'efficacité du cache

```json
{
  "cacheEfficiency": {
    "hitRate": 0.65,
    "missRate": 0.35,
    "hitLatency": 120,
    "missLatency": 1500,
    "hitLatencyToMissLatency": 0.08
  }
}
```

| Champ | Type | Unité | Description | Obligatoire |
|-------|------|-------|-------------|-------------|
| `hitRate` | number | ratio (0-1) | Taux de succès du cache | Non |
| `missRate` | number | ratio (0-1) | Taux d'échec du cache | Non |
| `hitLatency` | number | µs/ms | Latence moyenne en cas de succès | Non |
| `missLatency` | number | µs/ms | Latence moyenne en cas d'échec | Non |
| `hitLatencyToMissLatency` | number | ratio | Rapport entre la latence en cas de succès et la latence en cas d'échec | Non |

### 3.7 Métriques de débit

```json
{
  "throughput": {
    "avg": 25,
    "peak": 45,
    "unit": "MB/s",
    "iops": {
      "avg": 6400,
      "peak": 11520
    }
  }
}
```

| Champ | Type | Unité | Description | Obligatoire |
|-------|------|-------|-------------|-------------|
| `avg` | number | MB/s | Débit moyen | Oui (si throughput présent) |
| `peak` | number | MB/s | Débit maximal | Non |
| `unit` | string | - | Unité de mesure du débit | Oui (si throughput présent) |
| `iops.avg` | number | IOPS | IOPS moyen | Non |
| `iops.peak` | number | IOPS | IOPS maximal | Non |

### 3.8 Comparaison avec les lectures séquentielles

```json
{
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
```

| Champ | Type | Unité | Description | Obligatoire |
|-------|------|-------|-------------|-------------|
| `latencyRatio.avg` | number | ratio | Rapport entre la latence moyenne aléatoire et séquentielle | Non |
| `latencyRatio.median` | number | ratio | Rapport entre la latence médiane aléatoire et séquentielle | Non |
| `latencyRatio.p95` | number | ratio | Rapport entre le 95e percentile aléatoire et séquentiel | Non |
| `throughputRatio` | number | ratio | Rapport entre le débit aléatoire et séquentiel | Non |
| `iopsRatio` | number | ratio | Rapport entre les IOPS aléatoires et séquentiels | Non |

### 3.9 Résumé et analyses comparatives

```json
{
  "summary": {
    "smallestBlockSize": "512B",
    "largestBlockSize": "1MB",
    "fastestBlockSize": "4KB",
    "slowestBlockSize": "1MB",
    "mostEfficientBlockSize": "16KB",
    "bestThroughputBlockSize": "64KB",
    "comparisons": [
      {
        "fromSize": "4KB",
        "toSize": "8KB",
        "latencyIncreaseFactor": 1.2,
        "throughputIncreaseFactor": 1.8
      },
      // ... autres comparaisons
    ]
  }
}
```

| Champ | Type | Description | Obligatoire |
|-------|------|-------------|-------------|
| `smallestBlockSize` | string | Plus petite taille de bloc mesurée | Non |
| `largestBlockSize` | string | Plus grande taille de bloc mesurée | Non |
| `fastestBlockSize` | string | Taille de bloc avec la latence moyenne la plus basse | Non |
| `slowestBlockSize` | string | Taille de bloc avec la latence moyenne la plus élevée | Non |
| `mostEfficientBlockSize` | string | Taille de bloc avec le meilleur rapport performance/ressources | Non |
| `bestThroughputBlockSize` | string | Taille de bloc avec le meilleur débit | Non |
| `comparisons` | array | Comparaisons directes entre différentes tailles de bloc | Non |
| `comparisons[].fromSize` | string | Taille de bloc de référence | Oui (si comparisons présent) |
| `comparisons[].toSize` | string | Taille de bloc comparée | Oui (si comparisons présent) |
| `comparisons[].latencyIncreaseFactor` | number | Facteur d'augmentation de la latence | Non |
| `comparisons[].throughputIncreaseFactor` | number | Facteur d'augmentation du débit | Non |

### 3.10 Caractéristiques de scaling

```json
{
  "scaling": {
    "model": "linear",
    "equation": "latency = 100 + 0.25 * blockSize",
    "r2": 0.92,
    "inflectionPoints": [
      {
        "blockSize": "64KB",
        "description": "Cache line size boundary"
      },
      // ... autres points d'inflexion
    ],
    "scalingFactors": {
      "smallBlocks": 0.2,
      "mediumBlocks": 0.5,
      "largeBlocks": 1.2
    }
  }
}
```

| Champ | Type | Description | Obligatoire |
|-------|------|-------------|-------------|
| `model` | string | Modèle mathématique de scaling (linear, logarithmic, etc.) | Non |
| `equation` | string | Équation représentant la relation entre taille de bloc et latence | Non |
| `r2` | number | Coefficient de détermination du modèle (0-1) | Non |
| `inflectionPoints` | array | Points d'inflexion dans la courbe de scaling | Non |
| `inflectionPoints[].blockSize` | string | Taille de bloc au point d'inflexion | Oui (si inflectionPoints présent) |
| `inflectionPoints[].description` | string | Description de la cause du point d'inflexion | Non |
| `scalingFactors` | object | Facteurs de scaling pour différentes plages de tailles de bloc | Non |

### 3.11 Taille de bloc optimale

```json
{
  "optimal": {
    "overall": "16KB",
    "byWorkload": {
      "smallFiles": "4KB",
      "largeFiles": "64KB",
      "mixedIO": "16KB",
      "highConcurrency": "8KB"
    },
    "byMetric": {
      "lowestLatency": "4KB",
      "highestThroughput": "64KB",
      "bestCacheEfficiency": "16KB",
      "lowestVariability": "8KB"
    },
    "recommendation": {
      "general": "16KB",
      "reasoning": "Best balance between latency and throughput for most workloads"
    }
  }
}
```

| Champ | Type | Description | Obligatoire |
|-------|------|-------------|-------------|
| `overall` | string | Taille de bloc globalement optimale | Non |
| `byWorkload` | object | Taille de bloc optimale par type de charge de travail | Non |
| `byWorkload.<workload>` | string | Taille de bloc optimale pour une charge de travail spécifique | Non |
| `byMetric` | object | Taille de bloc optimale par métrique de performance | Non |
| `byMetric.<metric>` | string | Taille de bloc optimale pour une métrique spécifique | Non |
| `recommendation` | object | Recommandation générale | Non |
| `recommendation.general` | string | Taille de bloc recommandée | Oui (si recommendation présent) |
| `recommendation.reasoning` | string | Justification de la recommandation | Non |

## 4. Exemples

### 4.1 Exemple minimal

```json
{
  "cache": {
    "software": {
      "filesystem": {
        "latency": {
          "read": {
            "random": {
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
                  {
                    "size": "64KB",
                    "sizeBytes": 65536,
                    "metrics": {
                      "basic": {
                        "min": 80,
                        "max": 8000,
                        "avg": 550,
                        "median": 480
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  }
}
```

### 4.2 Exemple complet (partiel)

```json
{
  "cache": {
    "software": {
      "filesystem": {
        "latency": {
          "read": {
            "random": {
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
                          {
                            "bin": "0-100",
                            "count": 1500,
                            "percentage": 15.0
                          },
                          {
                            "bin": "101-200",
                            "count": 2500,
                            "percentage": 25.0
                          },
                          {
                            "bin": "201-500",
                            "count": 4000,
                            "percentage": 40.0
                          },
                          {
                            "bin": "501-1000",
                            "count": 1000,
                            "percentage": 10.0
                          },
                          {
                            "bin": "1001-5000",
                            "count": 1000,
                            "percentage": 10.0
                          }
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
                  "smallestBlockSize": "512B",
                  "largestBlockSize": "1MB",
                  "fastestBlockSize": "4KB",
                  "slowestBlockSize": "1MB",
                  "mostEfficientBlockSize": "16KB",
                  "bestThroughputBlockSize": "64KB",
                  "comparisons": [
                    {
                      "fromSize": "4KB",
                      "toSize": "8KB",
                      "latencyIncreaseFactor": 1.2,
                      "throughputIncreaseFactor": 1.8
                    },
                    {
                      "fromSize": "8KB",
                      "toSize": "16KB",
                      "latencyIncreaseFactor": 1.3,
                      "throughputIncreaseFactor": 1.6
                    }
                  ]
                },
                "scaling": {
                  "model": "linear",
                  "equation": "latency = 100 + 0.25 * blockSize",
                  "r2": 0.92,
                  "inflectionPoints": [
                    {
                      "blockSize": "64KB",
                      "description": "Cache line size boundary"
                    }
                  ],
                  "scalingFactors": {
                    "smallBlocks": 0.2,
                    "mediumBlocks": 0.5,
                    "largeBlocks": 1.2
                  }
                },
                "optimal": {
                  "overall": "16KB",
                  "byWorkload": {
                    "smallFiles": "4KB",
                    "largeFiles": "64KB",
                    "mixedIO": "16KB",
                    "highConcurrency": "8KB"
                  },
                  "byMetric": {
                    "lowestLatency": "4KB",
                    "highestThroughput": "64KB",
                    "bestCacheEfficiency": "16KB",
                    "lowestVariability": "8KB"
                  },
                  "recommendation": {
                    "general": "16KB",
                    "reasoning": "Best balance between latency and throughput for most workloads"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

## 5. Bonnes pratiques

### 5.1 Implémentation du schéma

- Inclure au minimum les métriques de base (min, max, avg, median) pour chaque taille de bloc
- Utiliser des tailles de bloc standard (puissances de 2) pour faciliter les comparaisons
- Mesurer au moins trois tailles de bloc différentes pour permettre l'analyse de scaling
- Inclure les métriques de comparaison avec les lectures séquentielles lorsque c'est possible
- Fournir des recommandations basées sur des données empiriques

### 5.2 Extension du schéma

- Le schéma peut être étendu avec des métriques spécifiques à certains systèmes de fichiers
- Des métriques supplémentaires peuvent être ajoutées pour des cas d'utilisation particuliers
- Les champs optionnels peuvent être omis pour réduire la taille des résultats
- Des métriques personnalisées peuvent être ajoutées dans des sections dédiées

### 5.3 Validation du schéma

- Vérifier que toutes les tailles de bloc standard sont mesurées
- S'assurer que les unités sont cohérentes dans tout le schéma
- Valider que les métriques obligatoires sont présentes
- Vérifier la cohérence des données (ex: min ≤ median ≤ avg ≤ max)

## 6. Conclusion

Ce schéma JSON fournit une structure complète et flexible pour représenter les métriques de latence par taille de bloc pour les lectures aléatoires dans le cache de système de fichiers. Il permet de capturer les caractéristiques de performance essentielles tout en offrant la possibilité d'inclure des analyses détaillées et des recommandations.

# Métriques de latence pour les lectures aléatoires de blocs de 1KB

## 1. Vue d'ensemble

Ce document définit les métriques de latence spécifiques aux lectures aléatoires de blocs de 1 kilooctet (1KB) dans le cache de système de fichiers. Les blocs de 1KB représentent une taille intermédiaire entre les très petits blocs (512B) et la taille de page standard (4KB), ce qui leur confère des caractéristiques de performance particulières. Ces métriques sont importantes pour comprendre les performances des opérations sur les petits fichiers, certaines bases de données et applications utilisant des E/S de taille réduite.

## 2. Caractéristiques spécifiques des lectures aléatoires de 1KB

Les lectures aléatoires de blocs de 1KB présentent plusieurs caractéristiques distinctives :

1. **Équilibre overhead/transfert** : Le coût fixe par opération reste significatif mais moins dominant que pour les blocs de 512B
2. **Sensibilité modérée à l'alignement** : L'alignement reste important mais moins critique que pour 512B
3. **Bonne efficacité du cache** : Taille suffisamment petite pour bénéficier d'un taux de succès élevé
4. **Variabilité moyenne** : Moins variable que 512B mais plus que les grands blocs
5. **Débit modéré** : Meilleur équilibre entre nombre d'opérations et volume de données

## 3. Structure des métriques pour les blocs de 1KB

### 3.1 Intégration dans le schéma global

```json
{
  "byBlockSize": {
    "blockSizes": [
      {
        "size": "1KB",
        "sizeBytes": 1024,
        "metrics": {
          // Métriques spécifiques aux blocs de 1KB
        }
      }
    ]
  }
}
```

### 3.2 Métriques de base

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 40,
    "max": 3500,
    "avg": 220,
    "median": 150,
    "p90": 450,
    "p95": 750,
    "p99": 2000,
    "stdDev": 300,
    "variance": 90000,
    "samples": 15000,
    "confidence": {
      "level": 0.95,
      "interval": [215, 225],
      "marginOfError": 5
    }
  }
}
```

| Champ | Type | Unité | Description | Valeur typique |
|-------|------|-------|-------------|----------------|
| `unit` | string | - | Unité de mesure de la latence | "microseconds" |
| `min` | number | µs | Latence minimale | 40-60 |
| `max` | number | µs | Latence maximale | 3000-6000 |
| `avg` | number | µs | Latence moyenne | 200-300 |
| `median` | number | µs | Latence médiane | 140-180 |
| `p90` | number | µs | 90e percentile | 400-600 |
| `p95` | number | µs | 95e percentile | 600-900 |
| `p99` | number | µs | 99e percentile | 1500-2500 |
| `stdDev` | number | µs | Écart-type | 250-350 |
| `variance` | number | µs² | Variance | 60000-120000 |
| `samples` | number | - | Nombre d'échantillons | 10000+ |
| `confidence.level` | number | - | Niveau de confiance | 0.95 |
| `confidence.interval` | array | µs | Intervalle de confiance | [avg-5, avg+5] |
| `confidence.marginOfError` | number | µs | Marge d'erreur | 3-10 |

### 3.3 Distribution spécifique aux blocs de 1KB

```json
{
  "distribution": {
    "histogram": [
      {
        "bin": "0-75",
        "count": 1200,
        "percentage": 8.0
      },
      {
        "bin": "76-150",
        "count": 6300,
        "percentage": 42.0
      },
      {
        "bin": "151-300",
        "count": 4500,
        "percentage": 30.0
      },
      {
        "bin": "301-750",
        "count": 2250,
        "percentage": 15.0
      },
      {
        "bin": "751-3500",
        "count": 750,
        "percentage": 5.0
      }
    ],
    "multimodal": true,
    "modes": [
      {
        "value": 120,
        "description": "Cache hits"
      },
      {
        "value": 450,
        "description": "Cache misses with buffer cache hit"
      }
    ],
    "skewness": 2.8,
    "kurtosis": 10.2
  }
}
```

| Champ | Type | Description | Particularité pour 1KB |
|-------|------|-------------|------------------------|
| `histogram` | array | Histogramme de distribution | Bins adaptés à la distribution |
| `multimodal` | boolean | Indique si la distribution a plusieurs modes | Généralement vrai pour 1KB |
| `modes` | array | Liste des modes de la distribution | Typiquement 2 modes distincts |
| `modes[].value` | number | Valeur du mode | Correspond aux différents niveaux de cache |
| `modes[].description` | string | Description du mode | Explication de la cause du mode |
| `skewness` | number | Asymétrie de la distribution | Généralement élevée (2-3) |
| `kurtosis` | number | Aplatissement de la distribution | Généralement élevé (8-12) |

### 3.4 Métriques d'alignement spécifiques aux blocs de 1KB

```json
{
  "alignment": {
    "sectorAligned": {
      "percentage": 98.0,
      "latency": {
        "avg": 210,
        "median": 145
      }
    },
    "sectorUnaligned": {
      "percentage": 2.0,
      "latency": {
        "avg": 520,
        "median": 430
      }
    },
    "pageAligned": {
      "percentage": 30.0,
      "latency": {
        "avg": 180,
        "median": 130
      }
    },
    "pageUnaligned": {
      "percentage": 70.0,
      "latency": {
        "avg": 240,
        "median": 160
      }
    },
    "cacheLineAligned": {
      "percentage": 15.0,
      "latency": {
        "avg": 160,
        "median": 120
      }
    },
    "cacheLineUnaligned": {
      "percentage": 85.0,
      "latency": {
        "avg": 230,
        "median": 155
      }
    },
    "alignmentImpact": {
      "sector": 2.48,
      "page": 1.33,
      "cacheLine": 1.44
    }
  }
}
```

| Champ | Type | Unité | Description | Particularité pour 1KB |
|-------|------|-------|-------------|------------------------|
| `alignment` | object | - | Métriques liées à l'alignement | Important mais moins que pour 512B |
| `alignment.sectorAligned` | object | - | Métriques pour les accès alignés sur les secteurs | Généralement 95%+ |
| `alignment.sectorAligned.percentage` | number | % | Pourcentage d'accès alignés sur les secteurs | 95-99% |
| `alignment.sectorAligned.latency` | object | - | Latence pour les accès alignés sur les secteurs | Significativement plus basse |
| `alignment.sectorUnaligned` | object | - | Métriques pour les accès non alignés sur les secteurs | Généralement <5% |
| `alignment.pageAligned` | object | - | Métriques pour les accès alignés sur les pages | Plus fréquent que pour 512B |
| `alignment.pageUnaligned` | object | - | Métriques pour les accès non alignés sur les pages | Majoritaires |
| `alignment.cacheLineAligned` | object | - | Métriques pour les accès alignés sur les lignes de cache | Plus fréquent que pour 512B |
| `alignment.cacheLineUnaligned` | object | - | Métriques pour les accès non alignés sur les lignes de cache | Majoritaires |
| `alignment.alignmentImpact` | object | - | Impact de l'alignement sur la latence | Facteurs multiplicatifs |
| `alignment.alignmentImpact.sector` | number | ratio | Impact de l'alignement secteur | Typiquement 2-3x |
| `alignment.alignmentImpact.page` | number | ratio | Impact de l'alignement page | Typiquement 1.2-1.5x |
| `alignment.alignmentImpact.cacheLine` | number | ratio | Impact de l'alignement ligne de cache | Typiquement 1.3-1.6x |

### 3.5 Métriques d'efficacité du cache pour les blocs de 1KB

```json
{
  "cacheEfficiency": {
    "hitRate": 0.82,
    "missRate": 0.18,
    "hitLatency": 90,
    "missLatency": 950,
    "hitLatencyToMissLatency": 0.09,
    "byLevel": {
      "l1": {
        "hitRate": 0.35,
        "latency": 60
      },
      "l2": {
        "hitRate": 0.28,
        "latency": 100
      },
      "l3": {
        "hitRate": 0.19,
        "latency": 150
      },
      "memory": {
        "hitRate": 0.12,
        "latency": 450
      },
      "disk": {
        "hitRate": 0.06,
        "latency": 2800
      }
    },
    "smallBlockAdvantage": 1.15,
    "cacheEvictionPriority": "medium-low",
    "cacheResidenceTime": {
      "avg": 90000,
      "unit": "ms"
    }
  }
}
```

| Champ | Type | Unité | Description | Particularité pour 1KB |
|-------|------|-------|-------------|------------------------|
| `cacheEfficiency` | object | - | Métriques d'efficacité du cache | Généralement favorable pour 1KB |
| `cacheEfficiency.hitRate` | number | ratio | Taux de succès global du cache | Typiquement élevé (0.75-0.9) |
| `cacheEfficiency.missRate` | number | ratio | Taux d'échec global du cache | Typiquement bas (0.1-0.25) |
| `cacheEfficiency.hitLatency` | number | µs | Latence moyenne en cas de succès | Typiquement 70-110 µs |
| `cacheEfficiency.missLatency` | number | µs | Latence moyenne en cas d'échec | Typiquement 800-1200 µs |
| `cacheEfficiency.byLevel` | object | - | Métriques par niveau de cache | Distribution à travers les niveaux |
| `cacheEfficiency.byLevel.<level>.hitRate` | number | ratio | Taux de succès pour ce niveau | Varie selon le niveau |
| `cacheEfficiency.byLevel.<level>.latency` | number | µs | Latence moyenne pour ce niveau | Varie selon le niveau |
| `cacheEfficiency.smallBlockAdvantage` | number | ratio | Avantage relatif des petits blocs pour le cache | Typiquement 1.1-1.2 |
| `cacheEfficiency.cacheEvictionPriority` | string | - | Priorité d'éviction du cache | Généralement "medium-low" |
| `cacheEfficiency.cacheResidenceTime` | object | - | Temps de résidence dans le cache | Généralement long pour 1KB |
| `cacheEfficiency.cacheResidenceTime.avg` | number | ms | Temps moyen de résidence | Typiquement 60000-120000 ms |

### 3.6 Métriques de débit pour les blocs de 1KB

```json
{
  "throughput": {
    "avg": 4.8,
    "peak": 9.5,
    "sustained": 4.2,
    "unit": "MB/s",
    "iops": {
      "avg": 4800,
      "peak": 9500,
      "sustained": 4200
    },
    "bandwidthLimited": false,
    "iopsLimited": true,
    "limitingFactor": "cpu_overhead",
    "overheadRatio": 0.75,
    "dataTransferRatio": 0.25
  }
}
```

| Champ | Type | Unité | Description | Particularité pour 1KB |
|-------|------|-------|-------------|------------------------|
| `throughput` | object | - | Métriques de débit | Meilleur équilibre IOPS/débit que 512B |
| `throughput.avg` | number | MB/s | Débit moyen | Typiquement modéré (3-6 MB/s) |
| `throughput.peak` | number | MB/s | Débit maximal | Typiquement 2x la moyenne |
| `throughput.sustained` | number | MB/s | Débit soutenu | Légèrement inférieur à la moyenne |
| `throughput.iops` | object | - | Opérations par seconde | Élevé mais moins que 512B |
| `throughput.iops.avg` | number | IOPS | IOPS moyen | Typiquement 3000-6000 |
| `throughput.iops.peak` | number | IOPS | IOPS maximal | Typiquement 2x la moyenne |
| `throughput.bandwidthLimited` | boolean | - | Indique si limité par la bande passante | Généralement false pour 1KB |
| `throughput.iopsLimited` | boolean | - | Indique si limité par les IOPS | Généralement true pour 1KB |
| `throughput.limitingFactor` | string | - | Facteur limitant principal | Typiquement "cpu_overhead" |
| `throughput.overheadRatio` | number | ratio | Proportion du temps passé en overhead | Élevé (0.7-0.8) |
| `throughput.dataTransferRatio` | number | ratio | Proportion du temps passé en transfert de données | Bas (0.2-0.3) |

### 3.7 Métriques d'overhead spécifiques aux blocs de 1KB

```json
{
  "overhead": {
    "total": 165,
    "breakdown": {
      "systemCall": 25,
      "fileSystemTraversal": 35,
      "lockingOverhead": 15,
      "bufferManagement": 35,
      "cacheManagement": 25,
      "ioScheduling": 15,
      "contextSwitching": 15
    },
    "dataTransferTime": 55,
    "overheadToTransferRatio": 3.0,
    "fixedCost": 120,
    "variableCost": 45,
    "fixedToVariableRatio": 2.67
  }
}
```

| Champ | Type | Unité | Description | Particularité pour 1KB |
|-------|------|-------|-------------|------------------------|
| `overhead` | object | - | Métriques d'overhead | Important mais moins dominant que pour 512B |
| `overhead.total` | number | µs | Overhead total | Typiquement 150-180 µs |
| `overhead.breakdown` | object | - | Décomposition de l'overhead | Détail des sources d'overhead |
| `overhead.breakdown.<source>` | number | µs | Overhead pour une source spécifique | Varie selon la source |
| `overhead.dataTransferTime` | number | µs | Temps de transfert effectif des données | Plus significatif que pour 512B (40-70 µs) |
| `overhead.overheadToTransferRatio` | number | ratio | Rapport overhead/transfert | Élevé mais moins que 512B (2.5-3.5) |
| `overhead.fixedCost` | number | µs | Coût fixe par opération | Similaire à 512B |
| `overhead.variableCost` | number | µs | Coût variable selon la taille | Plus significatif que pour 512B |
| `overhead.fixedToVariableRatio` | number | ratio | Rapport coût fixe/variable | Élevé mais moins que 512B (2.5-3.5) |

### 3.8 Métriques de comparaison avec d'autres tailles de bloc

```json
{
  "sizeComparison": {
    "vs512B": {
      "latencyRatio": 1.22,
      "throughputRatio": 1.92,
      "iopsRatio": 0.96,
      "hitRateRatio": 0.96,
      "overheadImpact": 0.85
    },
    "vs4KB": {
      "latencyRatio": 0.73,
      "throughputRatio": 0.29,
      "iopsRatio": 1.2,
      "hitRateRatio": 1.08,
      "overheadImpact": 1.5
    },
    "vs64KB": {
      "latencyRatio": 0.37,
      "throughputRatio": 0.08,
      "iopsRatio": 5.0,
      "hitRateRatio": 1.17,
      "overheadImpact": 2.8
    },
    "efficiencyBreakpoint": {
      "vsSequential": "8KB",
      "vsRandom": "2KB",
      "description": "Taille à partir de laquelle l'efficacité relative diminue"
    }
  }
}
```

| Champ | Type | Unité | Description | Particularité pour 1KB |
|-------|------|-------|-------------|------------------------|
| `sizeComparison` | object | - | Comparaison avec d'autres tailles | Position intermédiaire |
| `sizeComparison.vs512B` | object | - | Comparaison avec les blocs de 512B | Référence vers le bas |
| `sizeComparison.vs512B.latencyRatio` | number | ratio | Rapport de latence (1KB/512B) | Typiquement 1.1-1.3 |
| `sizeComparison.vs512B.throughputRatio` | number | ratio | Rapport de débit (1KB/512B) | Typiquement 1.8-2.2 |
| `sizeComparison.vs512B.iopsRatio` | number | ratio | Rapport d'IOPS (1KB/512B) | Typiquement 0.9-1.1 |
| `sizeComparison.vs512B.hitRateRatio` | number | ratio | Rapport de taux de succès (1KB/512B) | Typiquement 0.95-0.98 |
| `sizeComparison.vs512B.overheadImpact` | number | ratio | Impact relatif de l'overhead | Typiquement 0.8-0.9 |
| `sizeComparison.vs4KB` | object | - | Comparaison avec les blocs de 4KB | Référence standard |
| `sizeComparison.vs64KB` | object | - | Comparaison avec les blocs de 64KB | Référence pour débit |
| `sizeComparison.efficiencyBreakpoint` | object | - | Points de rupture d'efficacité | Tailles critiques |

### 3.9 Métriques de cas d'utilisation spécifiques

```json
{
  "useCases": {
    "smallFiles": {
      "relevance": "high",
      "performance": {
        "latency": 200,
        "iops": 4800,
        "efficiency": 0.85
      }
    },
    "databaseTransactions": {
      "relevance": "high",
      "performance": {
        "latency": 230,
        "iops": 4300,
        "efficiency": 0.82
      }
    },
    "logging": {
      "relevance": "medium",
      "performance": {
        "latency": 250,
        "iops": 4000,
        "efficiency": 0.78
      }
    },
    "metadata": {
      "relevance": "medium-low",
      "performance": {
        "latency": 180,
        "iops": 5500,
        "efficiency": 0.75
      }
    }
  }
}
```

| Champ | Type | Description | Particularité pour 1KB |
|-------|------|-------------|------------------------|
| `useCases` | object | - | Métriques par cas d'utilisation | Cas d'utilisation spécifiques à 1KB |
| `useCases.<useCase>` | object | - | Métriques pour un cas d'utilisation spécifique | Varie selon le cas |
| `useCases.<useCase>.relevance` | string | - | Pertinence de cette taille pour ce cas | "high" pour petits fichiers et BDD |
| `useCases.<useCase>.performance` | object | - | Performances pour ce cas d'utilisation | Métriques spécifiques au cas |
| `useCases.<useCase>.performance.latency` | number | µs | Latence moyenne pour ce cas | Varie selon le cas |
| `useCases.<useCase>.performance.iops` | number | IOPS | IOPS moyen pour ce cas | Varie selon le cas |
| `useCases.<useCase>.performance.efficiency` | number | ratio | Efficacité pour ce cas | Varie selon le cas |

## 4. Exemples complets

### 4.1 Exemple minimal

```json
{
  "byBlockSize": {
    "blockSizes": [
      {
        "size": "1KB",
        "sizeBytes": 1024,
        "metrics": {
          "basic": {
            "unit": "microseconds",
            "min": 40,
            "max": 3500,
            "avg": 220,
            "median": 150
          },
          "cacheEfficiency": {
            "hitRate": 0.82,
            "missRate": 0.18
          },
          "throughput": {
            "avg": 4.8,
            "unit": "MB/s",
            "iops": {
              "avg": 4800
            }
          }
        }
      }
    ]
  }
}
```

### 4.2 Exemple complet (partiel)

```json
{
  "byBlockSize": {
    "blockSizes": [
      {
        "size": "1KB",
        "sizeBytes": 1024,
        "metrics": {
          "basic": {
            "unit": "microseconds",
            "min": 40,
            "max": 3500,
            "avg": 220,
            "median": 150,
            "p90": 450,
            "p95": 750,
            "p99": 2000,
            "stdDev": 300,
            "variance": 90000,
            "samples": 15000,
            "confidence": {
              "level": 0.95,
              "interval": [215, 225],
              "marginOfError": 5
            }
          },
          "distribution": {
            "histogram": [
              {
                "bin": "0-75",
                "count": 1200,
                "percentage": 8.0
              },
              {
                "bin": "76-150",
                "count": 6300,
                "percentage": 42.0
              },
              {
                "bin": "151-300",
                "count": 4500,
                "percentage": 30.0
              },
              {
                "bin": "301-750",
                "count": 2250,
                "percentage": 15.0
              },
              {
                "bin": "751-3500",
                "count": 750,
                "percentage": 5.0
              }
            ],
            "multimodal": true,
            "modes": [
              {
                "value": 120,
                "description": "Cache hits"
              },
              {
                "value": 450,
                "description": "Cache misses with buffer cache hit"
              }
            ],
            "skewness": 2.8,
            "kurtosis": 10.2
          },
          "alignment": {
            "sectorAligned": {
              "percentage": 98.0,
              "latency": {
                "avg": 210,
                "median": 145
              }
            },
            "sectorUnaligned": {
              "percentage": 2.0,
              "latency": {
                "avg": 520,
                "median": 430
              }
            },
            "alignmentImpact": {
              "sector": 2.48,
              "page": 1.33,
              "cacheLine": 1.44
            }
          },
          "cacheEfficiency": {
            "hitRate": 0.82,
            "missRate": 0.18,
            "hitLatency": 90,
            "missLatency": 950,
            "hitLatencyToMissLatency": 0.09,
            "byLevel": {
              "l1": {
                "hitRate": 0.35,
                "latency": 60
              },
              "l2": {
                "hitRate": 0.28,
                "latency": 100
              },
              "l3": {
                "hitRate": 0.19,
                "latency": 150
              }
            }
          },
          "throughput": {
            "avg": 4.8,
            "peak": 9.5,
            "sustained": 4.2,
            "unit": "MB/s",
            "iops": {
              "avg": 4800,
              "peak": 9500,
              "sustained": 4200
            },
            "overheadRatio": 0.75,
            "dataTransferRatio": 0.25
          },
          "overhead": {
            "total": 165,
            "breakdown": {
              "systemCall": 25,
              "fileSystemTraversal": 35,
              "lockingOverhead": 15,
              "bufferManagement": 35,
              "cacheManagement": 25,
              "ioScheduling": 15,
              "contextSwitching": 15
            },
            "dataTransferTime": 55,
            "overheadToTransferRatio": 3.0
          },
          "sizeComparison": {
            "vs512B": {
              "latencyRatio": 1.22,
              "throughputRatio": 1.92,
              "iopsRatio": 0.96,
              "hitRateRatio": 0.96
            },
            "vs4KB": {
              "latencyRatio": 0.73,
              "throughputRatio": 0.29,
              "iopsRatio": 1.2,
              "hitRateRatio": 1.08
            }
          },
          "useCases": {
            "smallFiles": {
              "relevance": "high",
              "performance": {
                "latency": 200,
                "iops": 4800,
                "efficiency": 0.85
              }
            },
            "databaseTransactions": {
              "relevance": "high",
              "performance": {
                "latency": 230,
                "iops": 4300,
                "efficiency": 0.82
              }
            }
          }
        }
      }
    ]
  }
}
```

## 5. Bonnes pratiques pour les métriques de blocs de 1KB

### 5.1 Collecte des métriques

- Utiliser un échantillonnage suffisamment large (>10000 échantillons)
- Mesurer séparément les accès alignés et non alignés sur les secteurs
- Collecter des histogrammes adaptés à la distribution bimodale typique
- Mesurer l'équilibre entre overhead et temps de transfert
- Comparer systématiquement avec les blocs de 512B et 4KB comme références

### 5.2 Analyse des métriques

- Examiner la distribution complète, pas seulement les moyennes
- Identifier les différents modes et leurs causes
- Analyser l'impact de l'alignement sur les performances
- Évaluer le rapport overhead/transfert pour comprendre les limitations
- Comparer les performances avec différents cas d'utilisation

### 5.3 Optimisation

- Privilégier l'alignement sur les secteurs
- Optimiser les structures de données pour équilibrer overhead et transfert
- Considérer le regroupement (batching) pour les opérations fréquentes
- Utiliser des techniques de préchargement adaptées aux petits blocs
- Ajuster les paramètres du cache pour favoriser la rétention des blocs de 1KB

### 5.4 Reporting

- Mettre en évidence l'équilibre overhead/transfert
- Comparer avec les blocs de 512B et 4KB pour contextualiser
- Fournir des recommandations spécifiques aux cas d'utilisation
- Documenter les configurations optimales pour les petits fichiers et bases de données
- Proposer des stratégies d'alignement et de regroupement

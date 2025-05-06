# Métriques de taux de succès du cache

## 1. Vue d'ensemble

Les métriques de taux de succès du cache (cache hit rate) sont essentielles pour évaluer l'efficacité des différents niveaux de cache dans un système. Un taux de succès élevé indique une utilisation efficace du cache, tandis qu'un taux faible peut signaler des problèmes de dimensionnement, de configuration ou d'accès aux données. Ce document définit les métriques de taux de succès pour les différents types de cache identifiés précédemment.

## 2. Définitions fondamentales

### 2.1 Terminologie de base

- **Accès au cache** : Toute tentative de lecture ou d'écriture dans le cache.
- **Succès (Hit)** : Un accès au cache qui trouve les données recherchées dans le cache.
- **Échec (Miss)** : Un accès au cache qui ne trouve pas les données recherchées, nécessitant un accès à un niveau de mémoire plus lent.
- **Taux de succès (Hit Rate)** : Proportion des accès au cache qui sont des succès.
- **Taux d'échec (Miss Rate)** : Proportion des accès au cache qui sont des échecs.

### 2.2 Formules de calcul

```
Taux de succès = Nombre de succès / Nombre total d'accès
Taux d'échec = Nombre d'échecs / Nombre total d'accès
Taux d'échec = 1 - Taux de succès
```

### 2.3 Types d'accès

- **Accès en lecture** : Tentative de lecture de données depuis le cache.
- **Accès en écriture** : Tentative d'écriture de données dans le cache.
- **Accès en instruction** : Accès spécifique aux instructions (code exécutable).
- **Accès en données** : Accès spécifique aux données.

## 3. Structure des métriques de taux de succès

### 3.1 Structure générale

```json
{
  "hitRate": {
    "overall": 0.85,
    "read": 0.90,
    "write": 0.75,
    "byType": {
      // Détails par type d'accès
    },
    "timeSeries": {
      // Évolution temporelle
    },
    "distribution": {
      // Distribution statistique
    }
  }
}
```

### 3.2 Métriques globales

```json
{
  "hitRate": {
    "overall": 0.85,
    "read": 0.90,
    "write": 0.75,
    "instruction": 0.95,
    "data": 0.82
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `overall` | number | ratio (0-1) | Taux de succès global pour tous les types d'accès |
| `read` | number | ratio (0-1) | Taux de succès pour les accès en lecture |
| `write` | number | ratio (0-1) | Taux de succès pour les accès en écriture |
| `instruction` | number | ratio (0-1) | Taux de succès pour les accès aux instructions |
| `data` | number | ratio (0-1) | Taux de succès pour les accès aux données |

### 3.3 Métriques par type d'accès

```json
{
  "hitRate": {
    "byType": {
      "sequential": 0.95,
      "random": 0.70,
      "strided": 0.85,
      "spatial": 0.92,
      "temporal": 0.88
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `sequential` | number | ratio (0-1) | Taux de succès pour les accès séquentiels |
| `random` | number | ratio (0-1) | Taux de succès pour les accès aléatoires |
| `strided` | number | ratio (0-1) | Taux de succès pour les accès à pas régulier |
| `spatial` | number | ratio (0-1) | Taux de succès lié à la localité spatiale |
| `temporal` | number | ratio (0-1) | Taux de succès lié à la localité temporelle |

### 3.4 Série temporelle

```json
{
  "hitRate": {
    "timeSeries": {
      "interval": 1000,
      "unit": "ms",
      "samples": [
        {
          "timestamp": "2025-05-15T10:00:10.000Z",
          "overall": 0.82,
          "read": 0.88,
          "write": 0.72
        },
        {
          "timestamp": "2025-05-15T10:00:11.000Z",
          "overall": 0.84,
          "read": 0.89,
          "write": 0.74
        },
        // ... autres échantillons
      ]
    }
  }
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `interval` | number | Intervalle d'échantillonnage en millisecondes |
| `unit` | string | Unité de l'intervalle d'échantillonnage (ms, s, etc.) |
| `samples` | array | Liste des échantillons de taux de succès |
| `samples[].timestamp` | string | Horodatage de l'échantillon (ISO 8601) |
| `samples[].overall` | number | Taux de succès global à cet instant |
| `samples[].read` | number | Taux de succès en lecture à cet instant |
| `samples[].write` | number | Taux de succès en écriture à cet instant |

### 3.5 Distribution statistique

```json
{
  "hitRate": {
    "distribution": {
      "min": 0.65,
      "max": 0.98,
      "avg": 0.85,
      "median": 0.87,
      "stdDev": 0.08,
      "p10": 0.72,
      "p25": 0.78,
      "p75": 0.92,
      "p90": 0.95,
      "p99": 0.97,
      "histogram": [
        {
          "bin": "0.60-0.65",
          "count": 5
        },
        {
          "bin": "0.65-0.70",
          "count": 15
        },
        // ... autres bins
      ]
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `min` | number | ratio (0-1) | Valeur minimale du taux de succès observée |
| `max` | number | ratio (0-1) | Valeur maximale du taux de succès observée |
| `avg` | number | ratio (0-1) | Valeur moyenne du taux de succès |
| `median` | number | ratio (0-1) | Valeur médiane du taux de succès |
| `stdDev` | number | - | Écart-type du taux de succès |
| `p10`, `p25`, etc. | number | ratio (0-1) | Percentiles du taux de succès |
| `histogram` | array | - | Histogramme de distribution du taux de succès |
| `histogram[].bin` | string | - | Plage de valeurs du bin |
| `histogram[].count` | number | - | Nombre d'échantillons dans ce bin |

## 4. Métriques spécifiques par type de cache

### 4.1 Caches matériels (CPU)

#### 4.1.1 Cache L1

```json
{
  "cache": {
    "hardware": {
      "l1": {
        "hitRate": {
          "overall": 0.95,
          "instruction": 0.98,
          "data": 0.92,
          "byCore": [
            {
              "coreId": 0,
              "overall": 0.96,
              "instruction": 0.99,
              "data": 0.93
            },
            // ... autres cœurs
          ]
        }
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `overall` | number | ratio (0-1) | Taux de succès global du cache L1 |
| `instruction` | number | ratio (0-1) | Taux de succès du cache d'instructions L1 |
| `data` | number | ratio (0-1) | Taux de succès du cache de données L1 |
| `byCore` | array | - | Taux de succès par cœur de processeur |
| `byCore[].coreId` | number | - | Identifiant du cœur |
| `byCore[].overall` | number | ratio (0-1) | Taux de succès global pour ce cœur |
| `byCore[].instruction` | number | ratio (0-1) | Taux de succès d'instructions pour ce cœur |
| `byCore[].data` | number | ratio (0-1) | Taux de succès de données pour ce cœur |

#### 4.1.2 Cache L2 et L3

Structure similaire à celle du cache L1, avec des métriques supplémentaires pour les caches partagés :

```json
{
  "cache": {
    "hardware": {
      "l2": {
        "hitRate": {
          "overall": 0.85,
          "byCore": [ /* ... */ ],
          "sharedHits": 0.25,
          "exclusiveHits": 0.60
        }
      },
      "l3": {
        "hitRate": {
          "overall": 0.75,
          "byCore": [ /* ... */ ],
          "byThread": [ /* ... */ ],
          "sharedHits": 0.45,
          "exclusiveHits": 0.30
        }
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `sharedHits` | number | ratio (0-1) | Taux de succès pour les données partagées entre cœurs |
| `exclusiveHits` | number | ratio (0-1) | Taux de succès pour les données exclusives à un cœur |
| `byThread` | array | - | Taux de succès par thread (pour les caches partagés) |

#### 4.1.3 TLB (Translation Lookaside Buffer)

```json
{
  "cache": {
    "hardware": {
      "tlb": {
        "hitRate": {
          "overall": 0.99,
          "instruction": 0.995,
          "data": 0.985,
          "l1": 0.99,
          "l2": 0.80,
          "byPageSize": {
            "4KB": 0.98,
            "2MB": 0.995,
            "1GB": 0.999
          }
        }
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `overall` | number | ratio (0-1) | Taux de succès global du TLB |
| `instruction` | number | ratio (0-1) | Taux de succès du TLB d'instructions |
| `data` | number | ratio (0-1) | Taux de succès du TLB de données |
| `l1` | number | ratio (0-1) | Taux de succès du TLB de premier niveau |
| `l2` | number | ratio (0-1) | Taux de succès du TLB de second niveau |
| `byPageSize` | object | - | Taux de succès par taille de page |
| `byPageSize.<size>` | number | ratio (0-1) | Taux de succès pour une taille de page spécifique |

### 4.2 Caches logiciels

#### 4.2.1 Cache de système de fichiers

```json
{
  "cache": {
    "software": {
      "filesystem": {
        "hitRate": {
          "overall": 0.80,
          "read": 0.85,
          "write": 0.75,
          "metadata": 0.90,
          "byFileType": {
            "executable": 0.95,
            "library": 0.90,
            "data": 0.75,
            "config": 0.85
          },
          "byAccessPattern": {
            "sequential": 0.90,
            "random": 0.65
          }
        }
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `metadata` | number | ratio (0-1) | Taux de succès pour les accès aux métadonnées |
| `byFileType` | object | - | Taux de succès par type de fichier |
| `byFileType.<type>` | number | ratio (0-1) | Taux de succès pour un type de fichier spécifique |
| `byAccessPattern` | object | - | Taux de succès par pattern d'accès |
| `byAccessPattern.<pattern>` | number | ratio (0-1) | Taux de succès pour un pattern d'accès spécifique |

#### 4.2.2 Cache d'application

```json
{
  "cache": {
    "software": {
      "application": {
        "hitRate": {
          "overall": 0.85,
          "byComponent": {
            "dataCache": 0.80,
            "queryCache": 0.90,
            "templateCache": 0.95
          },
          "byOperation": {
            "read": 0.88,
            "write": 0.75,
            "compute": 0.92
          },
          "byDataSize": {
            "small": 0.95,
            "medium": 0.85,
            "large": 0.70
          }
        }
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `byComponent` | object | - | Taux de succès par composant de l'application |
| `byComponent.<component>` | number | ratio (0-1) | Taux de succès pour un composant spécifique |
| `byOperation` | object | - | Taux de succès par type d'opération |
| `byOperation.<operation>` | number | ratio (0-1) | Taux de succès pour un type d'opération spécifique |
| `byDataSize` | object | - | Taux de succès par taille de données |
| `byDataSize.<size>` | number | ratio (0-1) | Taux de succès pour une taille de données spécifique |

### 4.3 Caches distribués

```json
{
  "cache": {
    "distributed": {
      "hitRate": {
        "overall": 0.75,
        "local": 0.90,
        "remote": 0.60,
        "byNode": [
          {
            "nodeId": "node1",
            "hitRate": 0.78
          },
          {
            "nodeId": "node2",
            "hitRate": 0.72
          }
        ],
        "byPartition": {
          "partition1": 0.80,
          "partition2": 0.70
        },
        "byReplication": {
          "primary": 0.85,
          "replica": 0.65
        }
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `local` | number | ratio (0-1) | Taux de succès pour les accès au cache local |
| `remote` | number | ratio (0-1) | Taux de succès pour les accès au cache distant |
| `byNode` | array | - | Taux de succès par nœud du système distribué |
| `byNode[].nodeId` | string | - | Identifiant du nœud |
| `byNode[].hitRate` | number | ratio (0-1) | Taux de succès pour ce nœud |
| `byPartition` | object | - | Taux de succès par partition |
| `byPartition.<partition>` | number | ratio (0-1) | Taux de succès pour une partition spécifique |
| `byReplication` | object | - | Taux de succès par type de réplication |
| `byReplication.<type>` | number | ratio (0-1) | Taux de succès pour un type de réplication spécifique |

## 5. Métriques dérivées

### 5.1 Ratio de succès entre niveaux de cache

```json
{
  "cache": {
    "hardware": {
      "hitRateRatios": {
        "l1ToL2": 5.0,
        "l2ToL3": 3.0,
        "l3ToMemory": 10.0
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `l1ToL2` | number | ratio | Rapport entre le taux de succès L1 et L2 |
| `l2ToL3` | number | ratio | Rapport entre le taux de succès L2 et L3 |
| `l3ToMemory` | number | ratio | Rapport entre le taux de succès L3 et les accès mémoire |

### 5.2 Efficacité du cache

```json
{
  "cache": {
    "efficiency": {
      "overall": 0.75,
      "costBenefit": 0.85,
      "spaceUtilization": 0.80,
      "timeUtilization": 0.70
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `overall` | number | ratio (0-1) | Efficacité globale du cache |
| `costBenefit` | number | ratio (0-1) | Rapport coût/bénéfice du cache |
| `spaceUtilization` | number | ratio (0-1) | Utilisation efficace de l'espace du cache |
| `timeUtilization` | number | ratio (0-1) | Utilisation efficace du cache dans le temps |

### 5.3 Impact sur les performances

```json
{
  "cache": {
    "performanceImpact": {
      "latencyReduction": 0.85,
      "throughputImprovement": 3.5,
      "energyEfficiency": 0.70
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `latencyReduction` | number | ratio (0-1) | Réduction de latence due au cache |
| `throughputImprovement` | number | facteur | Amélioration du débit due au cache |
| `energyEfficiency` | number | ratio (0-1) | Efficacité énergétique du cache |

## 6. Exemples complets

### 6.1 Exemple minimal

```json
{
  "memory": {
    "cache": {
      "hardware": {
        "l1": {
          "hitRate": {
            "overall": 0.95
          }
        },
        "l2": {
          "hitRate": {
            "overall": 0.85
          }
        },
        "l3": {
          "hitRate": {
            "overall": 0.75
          }
        }
      },
      "software": {
        "filesystem": {
          "hitRate": {
            "overall": 0.80
          }
        }
      }
    }
  }
}
```

### 6.2 Exemple complet

```json
{
  "memory": {
    "cache": {
      "hardware": {
        "l1": {
          "hitRate": {
            "overall": 0.95,
            "instruction": 0.98,
            "data": 0.92,
            "read": 0.94,
            "write": 0.90,
            "byCore": [
              {
                "coreId": 0,
                "overall": 0.96,
                "instruction": 0.99,
                "data": 0.93
              },
              {
                "coreId": 1,
                "overall": 0.94,
                "instruction": 0.97,
                "data": 0.91
              }
            ],
            "byType": {
              "sequential": 0.98,
              "random": 0.85,
              "spatial": 0.96,
              "temporal": 0.94
            },
            "timeSeries": {
              "interval": 1000,
              "unit": "ms",
              "samples": [
                {
                  "timestamp": "2025-05-15T10:00:10.000Z",
                  "overall": 0.94,
                  "instruction": 0.97,
                  "data": 0.91
                },
                {
                  "timestamp": "2025-05-15T10:00:11.000Z",
                  "overall": 0.95,
                  "instruction": 0.98,
                  "data": 0.92
                }
              ]
            },
            "distribution": {
              "min": 0.90,
              "max": 0.99,
              "avg": 0.95,
              "median": 0.96,
              "stdDev": 0.02,
              "p90": 0.98,
              "p99": 0.99
            }
          }
        },
        "l2": {
          "hitRate": {
            "overall": 0.85,
            "byCore": [
              {
                "coreId": 0,
                "overall": 0.86
              },
              {
                "coreId": 1,
                "overall": 0.84
              }
            ],
            "sharedHits": 0.25,
            "exclusiveHits": 0.60
          }
        },
        "l3": {
          "hitRate": {
            "overall": 0.75,
            "byCore": [
              {
                "coreId": 0,
                "overall": 0.76
              },
              {
                "coreId": 1,
                "overall": 0.74
              }
            ],
            "sharedHits": 0.45,
            "exclusiveHits": 0.30
          }
        },
        "tlb": {
          "hitRate": {
            "overall": 0.99,
            "instruction": 0.995,
            "data": 0.985,
            "l1": 0.99,
            "l2": 0.80,
            "byPageSize": {
              "4KB": 0.98,
              "2MB": 0.995,
              "1GB": 0.999
            }
          }
        },
        "hitRateRatios": {
          "l1ToL2": 5.0,
          "l2ToL3": 3.0,
          "l3ToMemory": 10.0
        }
      },
      "software": {
        "filesystem": {
          "hitRate": {
            "overall": 0.80,
            "read": 0.85,
            "write": 0.75,
            "metadata": 0.90,
            "byFileType": {
              "executable": 0.95,
              "library": 0.90,
              "data": 0.75,
              "config": 0.85
            },
            "byAccessPattern": {
              "sequential": 0.90,
              "random": 0.65
            }
          }
        },
        "application": {
          "hitRate": {
            "overall": 0.85,
            "byComponent": {
              "dataCache": 0.80,
              "queryCache": 0.90,
              "templateCache": 0.95
            },
            "byOperation": {
              "read": 0.88,
              "write": 0.75,
              "compute": 0.92
            }
          }
        }
      },
      "distributed": {
        "hitRate": {
          "overall": 0.75,
          "local": 0.90,
          "remote": 0.60,
          "byNode": [
            {
              "nodeId": "node1",
              "hitRate": 0.78
            },
            {
              "nodeId": "node2",
              "hitRate": 0.72
            }
          ]
        }
      },
      "efficiency": {
        "overall": 0.75,
        "costBenefit": 0.85,
        "spaceUtilization": 0.80,
        "timeUtilization": 0.70
      },
      "performanceImpact": {
        "latencyReduction": 0.85,
        "throughputImprovement": 3.5,
        "energyEfficiency": 0.70
      }
    }
  }
}
```

## 7. Bonnes pratiques

### 7.1 Collecte des métriques

- Collecter les taux de succès à différents niveaux de cache simultanément
- Adapter la fréquence d'échantillonnage à la dynamique du cache
- Utiliser des compteurs matériels (PMC) pour les caches CPU
- Corréler les taux de succès avec les phases d'exécution du programme
- Mesurer les taux de succès avant et après les optimisations

### 7.2 Analyse des métriques

- Comparer les taux de succès avec des références établies
- Analyser les tendances des taux de succès au fil du temps
- Identifier les patterns d'accès qui causent des taux d'échec élevés
- Corréler les taux de succès entre différents niveaux de cache
- Examiner l'impact des taux de succès sur les performances globales

### 7.3 Optimisation

- Optimiser la localité spatiale et temporelle des accès
- Ajuster la taille et la configuration des caches logiciels
- Adapter les structures de données pour maximiser les taux de succès
- Utiliser des techniques de préchargement pour les accès prévisibles
- Optimiser la distribution des données dans les caches distribués

### 7.4 Reporting

- Inclure des graphiques de taux de succès dans les rapports
- Mettre en évidence les anomalies et les tendances importantes
- Comparer les taux de succès avec d'autres métriques de performance
- Fournir des recommandations basées sur l'analyse des taux de succès
- Documenter les configurations optimales pour différents scénarios

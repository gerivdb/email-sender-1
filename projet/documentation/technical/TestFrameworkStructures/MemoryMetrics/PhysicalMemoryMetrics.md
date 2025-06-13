# Métriques de mémoire physique

## 1. Vue d'ensemble

Les métriques de mémoire physique représentent les mesures liées à l'utilisation de la mémoire RAM physique par le système et les processus testés. Ces métriques sont essentielles pour évaluer l'efficacité de l'utilisation des ressources mémoire et pour identifier les problèmes potentiels tels que les fuites de mémoire ou la fragmentation.

## 2. Structure de base

Les métriques de mémoire physique sont organisées dans une structure hiérarchique qui permet de capturer différents aspects de l'utilisation de la mémoire physique. La structure de base est la suivante :

```json
{
  "memory": {
    "physical": {
      // Métriques de mémoire physique
    }
  }
}
```plaintext
## 3. Métriques principales

### 3.1 Utilisation globale

```json
{
  "physical": {
    "total": 16777216000,
    "available": 8589934592,
    "used": 8187281408,
    "usedByProcess": 512000000,
    "percentUsed": 48.8,
    "percentUsedByProcess": 3.05
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `total` | number | octets | Quantité totale de mémoire physique disponible sur le système |
| `available` | number | octets | Quantité de mémoire physique disponible pour allocation |
| `used` | number | octets | Quantité totale de mémoire physique utilisée par le système |
| `usedByProcess` | number | octets | Quantité de mémoire physique utilisée par le processus testé |
| `percentUsed` | number | pourcentage | Pourcentage de mémoire physique utilisée par le système |
| `percentUsedByProcess` | number | pourcentage | Pourcentage de mémoire physique utilisée par le processus testé |

### 3.2 Mesures statistiques

```json
{
  "physical": {
    "statistics": {
      "min": 256000000,
      "max": 512000000,
      "avg": 384000000,
      "median": 375000000,
      "stdDev": 75000000,
      "p90": 450000000,
      "p95": 480000000,
      "p99": 500000000
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `min` | number | octets | Utilisation minimale de mémoire physique pendant le test |
| `max` | number | octets | Utilisation maximale de mémoire physique pendant le test |
| `avg` | number | octets | Utilisation moyenne de mémoire physique pendant le test |
| `median` | number | octets | Médiane de l'utilisation de mémoire physique pendant le test |
| `stdDev` | number | octets | Écart-type de l'utilisation de mémoire physique |
| `p90` | number | octets | 90e percentile de l'utilisation de mémoire physique |
| `p95` | number | octets | 95e percentile de l'utilisation de mémoire physique |
| `p99` | number | octets | 99e percentile de l'utilisation de mémoire physique |

### 3.3 Série temporelle

```json
{
  "physical": {
    "timeSeries": {
      "interval": 1000,
      "unit": "ms",
      "samples": [
        {
          "timestamp": "2025-05-15T10:00:10.000Z",
          "value": 260000000
        },
        {
          "timestamp": "2025-05-15T10:00:11.000Z",
          "value": 280000000
        },
        {
          "timestamp": "2025-05-15T10:00:12.000Z",
          "value": 320000000
        },
        // ... autres échantillons
      ]
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `interval` | number | Intervalle d'échantillonnage en millisecondes |
| `unit` | string | Unité de l'intervalle d'échantillonnage (ms, s, etc.) |
| `samples` | array | Liste des échantillons de mémoire physique |
| `samples[].timestamp` | string | Horodatage de l'échantillon (ISO 8601) |
| `samples[].value` | number | Valeur de l'utilisation de mémoire physique en octets |

### 3.4 Allocation et libération

```json
{
  "physical": {
    "allocation": {
      "total": 750000000,
      "count": 1250,
      "avgSize": 600000,
      "maxSize": 50000000,
      "rate": {
        "avg": 125,
        "peak": 500
      }
    },
    "deallocation": {
      "total": 500000000,
      "count": 1000,
      "avgSize": 500000,
      "rate": {
        "avg": 100,
        "peak": 400
      }
    },
    "net": {
      "growth": 250000000,
      "growthRate": 25000
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `allocation.total` | number | octets | Quantité totale de mémoire physique allouée pendant le test |
| `allocation.count` | number | - | Nombre total d'allocations de mémoire physique |
| `allocation.avgSize` | number | octets | Taille moyenne des allocations de mémoire physique |
| `allocation.maxSize` | number | octets | Taille maximale d'une allocation de mémoire physique |
| `allocation.rate.avg` | number | allocations/s | Taux moyen d'allocations par seconde |
| `allocation.rate.peak` | number | allocations/s | Taux maximal d'allocations par seconde |
| `deallocation.total` | number | octets | Quantité totale de mémoire physique libérée pendant le test |
| `deallocation.count` | number | - | Nombre total de libérations de mémoire physique |
| `deallocation.avgSize` | number | octets | Taille moyenne des libérations de mémoire physique |
| `deallocation.rate.avg` | number | libérations/s | Taux moyen de libérations par seconde |
| `deallocation.rate.peak` | number | libérations/s | Taux maximal de libérations par seconde |
| `net.growth` | number | octets | Croissance nette de l'utilisation de mémoire physique |
| `net.growthRate` | number | octets/s | Taux de croissance de l'utilisation de mémoire physique |

### 3.5 Utilisation par composant

```json
{
  "physical": {
    "byComponent": {
      "dataLoading": {
        "peak": 150000000,
        "avg": 100000000,
        "percentOfTotal": 26.0
      },
      "indexCreation": {
        "peak": 350000000,
        "avg": 250000000,
        "percentOfTotal": 65.1
      },
      "querying": {
        "peak": 50000000,
        "avg": 30000000,
        "percentOfTotal": 7.8
      },
      "other": {
        "peak": 5000000,
        "avg": 4000000,
        "percentOfTotal": 1.1
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `byComponent.<component>.peak` | number | octets | Utilisation maximale de mémoire physique par le composant |
| `byComponent.<component>.avg` | number | octets | Utilisation moyenne de mémoire physique par le composant |
| `byComponent.<component>.percentOfTotal` | number | pourcentage | Pourcentage de l'utilisation totale de mémoire physique par le composant |

### 3.6 Métriques de pression mémoire

```json
{
  "physical": {
    "pressure": {
      "swapUsage": {
        "total": 100000000,
        "peak": 50000000,
        "avg": 25000000
      },
      "pageSwaps": {
        "in": 5000,
        "out": 3000,
        "rate": {
          "avg": 80,
          "peak": 200
        }
      },
      "compressionRatio": 1.8,
      "thresholds": {
        "warning": 0.8,
        "critical": 0.95
      },
      "pressureLevel": "normal"
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `pressure.swapUsage.total` | number | octets | Taille totale de l'espace d'échange utilisé |
| `pressure.swapUsage.peak` | number | octets | Utilisation maximale de l'espace d'échange |
| `pressure.swapUsage.avg` | number | octets | Utilisation moyenne de l'espace d'échange |
| `pressure.pageSwaps.in` | number | - | Nombre de pages chargées depuis l'espace d'échange |
| `pressure.pageSwaps.out` | number | - | Nombre de pages déchargées vers l'espace d'échange |
| `pressure.pageSwaps.rate.avg` | number | pages/s | Taux moyen d'échanges de pages |
| `pressure.pageSwaps.rate.peak` | number | pages/s | Taux maximal d'échanges de pages |
| `pressure.compressionRatio` | number | - | Ratio de compression de la mémoire (si applicable) |
| `pressure.thresholds.warning` | number | - | Seuil d'avertissement pour la pression mémoire |
| `pressure.thresholds.critical` | number | - | Seuil critique pour la pression mémoire |
| `pressure.pressureLevel` | string | - | Niveau de pression mémoire (normal, warning, critical) |

## 4. Métriques avancées

### 4.1 Fragmentation

```json
{
  "physical": {
    "fragmentation": {
      "index": 0.25,
      "largestFreeBlock": 100000000,
      "freeBlocksCount": 150,
      "avgFreeBlockSize": 20000000,
      "allocFailuresDueToFragmentation": 5
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `fragmentation.index` | number | - | Indice de fragmentation (0-1, où 1 est très fragmenté) |
| `fragmentation.largestFreeBlock` | number | octets | Taille du plus grand bloc de mémoire libre |
| `fragmentation.freeBlocksCount` | number | - | Nombre de blocs de mémoire libre |
| `fragmentation.avgFreeBlockSize` | number | octets | Taille moyenne des blocs de mémoire libre |
| `fragmentation.allocFailuresDueToFragmentation` | number | - | Nombre d'échecs d'allocation dus à la fragmentation |

### 4.2 Localité

```json
{
  "physical": {
    "locality": {
      "cacheHitRate": 0.85,
      "tlbHitRate": 0.92,
      "pageLocalityScore": 0.78,
      "memoryAccessPattern": "sequential"
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `locality.cacheHitRate` | number | - | Taux de succès du cache (0-1) |
| `locality.tlbHitRate` | number | - | Taux de succès du TLB (Translation Lookaside Buffer) (0-1) |
| `locality.pageLocalityScore` | number | - | Score de localité des pages (0-1, où 1 est optimal) |
| `locality.memoryAccessPattern` | string | - | Modèle d'accès à la mémoire (sequential, random, mixed) |

### 4.3 NUMA (Non-Uniform Memory Access)

```json
{
  "physical": {
    "numa": {
      "enabled": true,
      "nodeCount": 2,
      "byNode": [
        {
          "nodeId": 0,
          "total": 8589934592,
          "used": 4294967296,
          "localAccesses": 80000000,
          "remoteAccesses": 20000000,
          "localAccessRatio": 0.8
        },
        {
          "nodeId": 1,
          "total": 8589934592,
          "used": 3892314112,
          "localAccesses": 70000000,
          "remoteAccesses": 30000000,
          "localAccessRatio": 0.7
        }
      ],
      "interNodeTraffic": 50000000,
      "numaOptimizationScore": 0.75
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `numa.enabled` | boolean | - | Indique si NUMA est activé |
| `numa.nodeCount` | number | - | Nombre de nœuds NUMA |
| `numa.byNode[].nodeId` | number | - | Identifiant du nœud NUMA |
| `numa.byNode[].total` | number | octets | Quantité totale de mémoire physique sur le nœud |
| `numa.byNode[].used` | number | octets | Quantité de mémoire physique utilisée sur le nœud |
| `numa.byNode[].localAccesses` | number | - | Nombre d'accès mémoire locaux au nœud |
| `numa.byNode[].remoteAccesses` | number | - | Nombre d'accès mémoire distants au nœud |
| `numa.byNode[].localAccessRatio` | number | - | Ratio d'accès locaux (0-1, où 1 est optimal) |
| `numa.interNodeTraffic` | number | octets | Quantité de données transférées entre les nœuds |
| `numa.numaOptimizationScore` | number | - | Score d'optimisation NUMA (0-1, où 1 est optimal) |

## 5. Exemples

### 5.1 Exemple minimal

```json
{
  "memory": {
    "physical": {
      "total": 16777216000,
      "available": 8589934592,
      "used": 8187281408,
      "usedByProcess": 512000000,
      "percentUsed": 48.8,
      "percentUsedByProcess": 3.05,
      "statistics": {
        "min": 256000000,
        "max": 512000000,
        "avg": 384000000
      }
    }
  }
}
```plaintext
### 5.2 Exemple complet

```json
{
  "memory": {
    "physical": {
      "total": 16777216000,
      "available": 8589934592,
      "used": 8187281408,
      "usedByProcess": 512000000,
      "percentUsed": 48.8,
      "percentUsedByProcess": 3.05,
      
      "statistics": {
        "min": 256000000,
        "max": 512000000,
        "avg": 384000000,
        "median": 375000000,
        "stdDev": 75000000,
        "p90": 450000000,
        "p95": 480000000,
        "p99": 500000000
      },
      
      "timeSeries": {
        "interval": 1000,
        "unit": "ms",
        "samples": [
          {
            "timestamp": "2025-05-15T10:00:10.000Z",
            "value": 260000000
          },
          {
            "timestamp": "2025-05-15T10:00:11.000Z",
            "value": 280000000
          },
          {
            "timestamp": "2025-05-15T10:00:12.000Z",
            "value": 320000000
          },
          {
            "timestamp": "2025-05-15T10:00:13.000Z",
            "value": 350000000
          },
          {
            "timestamp": "2025-05-15T10:00:14.000Z",
            "value": 400000000
          }
        ]
      },
      
      "allocation": {
        "total": 750000000,
        "count": 1250,
        "avgSize": 600000,
        "maxSize": 50000000,
        "rate": {
          "avg": 125,
          "peak": 500
        }
      },
      
      "deallocation": {
        "total": 500000000,
        "count": 1000,
        "avgSize": 500000,
        "rate": {
          "avg": 100,
          "peak": 400
        }
      },
      
      "net": {
        "growth": 250000000,
        "growthRate": 25000
      },
      
      "byComponent": {
        "dataLoading": {
          "peak": 150000000,
          "avg": 100000000,
          "percentOfTotal": 26.0
        },
        "indexCreation": {
          "peak": 350000000,
          "avg": 250000000,
          "percentOfTotal": 65.1
        },
        "querying": {
          "peak": 50000000,
          "avg": 30000000,
          "percentOfTotal": 7.8
        },
        "other": {
          "peak": 5000000,
          "avg": 4000000,
          "percentOfTotal": 1.1
        }
      },
      
      "pressure": {
        "swapUsage": {
          "total": 100000000,
          "peak": 50000000,
          "avg": 25000000
        },
        "pageSwaps": {
          "in": 5000,
          "out": 3000,
          "rate": {
            "avg": 80,
            "peak": 200
          }
        },
        "compressionRatio": 1.8,
        "thresholds": {
          "warning": 0.8,
          "critical": 0.95
        },
        "pressureLevel": "normal"
      },
      
      "fragmentation": {
        "index": 0.25,
        "largestFreeBlock": 100000000,
        "freeBlocksCount": 150,
        "avgFreeBlockSize": 20000000,
        "allocFailuresDueToFragmentation": 5
      },
      
      "locality": {
        "cacheHitRate": 0.85,
        "tlbHitRate": 0.92,
        "pageLocalityScore": 0.78,
        "memoryAccessPattern": "sequential"
      },
      
      "numa": {
        "enabled": true,
        "nodeCount": 2,
        "byNode": [
          {
            "nodeId": 0,
            "total": 8589934592,
            "used": 4294967296,
            "localAccesses": 80000000,
            "remoteAccesses": 20000000,
            "localAccessRatio": 0.8
          },
          {
            "nodeId": 1,
            "total": 8589934592,
            "used": 3892314112,
            "localAccesses": 70000000,
            "remoteAccesses": 30000000,
            "localAccessRatio": 0.7
          }
        ],
        "interNodeTraffic": 50000000,
        "numaOptimizationScore": 0.75
      }
    }
  }
}
```plaintext
## 6. Bonnes pratiques

### 6.1 Collecte des métriques

- Collecter les métriques de mémoire physique à intervalles réguliers
- Adapter la fréquence d'échantillonnage à la durée du test
- Utiliser des outils de profilage mémoire pour les mesures détaillées
- Capturer les pics d'utilisation mémoire même entre les intervalles d'échantillonnage
- Mesurer l'utilisation mémoire avant et après chaque phase importante du test

### 6.2 Analyse des métriques

- Comparer l'utilisation mémoire avec les références établies
- Analyser les tendances d'utilisation mémoire au fil du temps
- Identifier les fuites de mémoire potentielles en surveillant la croissance nette
- Corréler les pics d'utilisation mémoire avec les activités spécifiques du test
- Examiner la fragmentation pour les tests de longue durée

### 6.3 Optimisation

- Utiliser les métriques de localité pour optimiser les accès mémoire
- Optimiser l'allocation mémoire en fonction des patterns d'utilisation
- Réduire la fragmentation en regroupant les allocations de taille similaire
- Optimiser les accès NUMA pour les systèmes multi-processeurs
- Ajuster les seuils d'alerte en fonction des caractéristiques du système

### 6.4 Reporting

- Inclure des graphiques d'utilisation mémoire dans les rapports
- Mettre en évidence les anomalies et les tendances importantes
- Comparer les métriques de mémoire physique avec d'autres métriques (CPU, E/S)
- Fournir des recommandations basées sur l'analyse des métriques
- Documenter les configurations optimales pour différents scénarios de test
